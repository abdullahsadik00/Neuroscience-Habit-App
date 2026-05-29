// =============================================================================
// FILE: add_habit_sheet.dart
//
// What this file is:
//   A bottom sheet UI that lets the user add a new habit to the app — either by
//   picking one from a pre-built library, or by filling in a custom form.
//
// Role in the app architecture:
//   This widget is launched from the main habits screen (home_screen.dart) when
//   the user taps the "+" button. Once the user confirms a habit, it writes the
//   new habit into the global app state via neuroProvider (defined in
//   providers/neuro_provider.dart). The habit data types it works with live in
//   models/models.dart, and the pre-built habit list comes from
//   data/habit_library.dart.
//
// Key concepts a learner needs to know:
//   - StatefulWidget vs ConsumerStatefulWidget: A StatefulWidget is the standard
//     Flutter widget that can hold local mutable state (things that change on
//     screen). A ConsumerStatefulWidget is the Riverpod extension of that — it
//     gives you "ref", a handle to read and write global app state providers.
//   - Bottom sheets: In Flutter, a "bottom sheet" slides up from the bottom of
//     the screen. This one is "draggable" — the user can drag it taller or shorter.
//   - TextEditingController: Flutter's way of reading/writing text that the user
//     types into a TextField. You create one per text input, then dispose it when
//     the widget is removed to avoid memory leaks.
//   - Riverpod state management: Riverpod is a library for managing shared app
//     state. Instead of passing data down through dozens of widgets, any widget
//     can reach out to a "provider" to get or change the global state.
// =============================================================================

// Brings in Flutter's core UI toolkit — widgets, colors, text styles, icons, etc.
import 'package:flutter/material.dart';

// Brings in Riverpod, the state management library.
// ConsumerStatefulWidget, ConsumerState, and "ref" all come from here.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Our app's global state provider. neuroProvider holds all habits and exposes
// methods (like addNeuroStack) to mutate that state.
import '../providers/neuro_provider.dart';

// Our app's data model definitions — HabitCategory, HabitTemplate, etc.
import '../models/models.dart';

// A static list of pre-built HabitTemplate objects grouped by category.
// The "library" tab shows these to the user.
import '../data/habit_library.dart';

// Custom color constants and theme helpers (e.g., focusColor, context.bgColor).
import '../theme/app_theme.dart';

// -----------------------------------------------------------------------------
// ENUM: _AddMode
//
// An enum is a fixed set of named values — like a multiple-choice variable.
// Here it represents which tab the user has selected in the sheet.
// The leading underscore makes it private to this file (Dart convention).
// -----------------------------------------------------------------------------
enum _AddMode {
  custom,  // The user wants to type in a completely custom habit from scratch.
  library, // The user wants to pick a ready-made habit from the built-in library.
}

// -----------------------------------------------------------------------------
// CLASS: AddHabitSheet
//
// This is the widget that represents the entire "Add Habit" bottom sheet.
//
// It extends ConsumerStatefulWidget, which is Riverpod's version of
// StatefulWidget. The difference: ConsumerStatefulWidget injects "ref" into its
// State object, giving us access to Riverpod providers (global app state).
//
// StatefulWidget (and ConsumerStatefulWidget) split into TWO classes:
//   1. The widget class itself (AddHabitSheet) — holds configuration, is
//      immutable (fields are final).
//   2. The state class (_AddHabitSheetState) — holds mutable data and the
//      build() method that draws the UI.
//
// Where it is used: showModalBottomSheet() in home_screen.dart passes this
// as the child to display.
// -----------------------------------------------------------------------------
class AddHabitSheet extends ConsumerStatefulWidget {
  /// Standard Flutter constructor. `super.key` passes an optional identity key
  /// to the parent class so Flutter can tell widgets apart in the tree.
  const AddHabitSheet({super.key});

  /// createState() is required by StatefulWidget. Flutter calls this once to
  /// create the mutable State object that lives alongside this widget.
  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

// -----------------------------------------------------------------------------
// CLASS: _AddHabitSheetState
//
// The mutable "brain" of AddHabitSheet. All local variables that can change
// (and trigger a UI redraw) live here. The leading underscore makes it private.
//
// Extends ConsumerState<AddHabitSheet>, which means:
//   - It has access to `ref` (the Riverpod handle to global providers).
//   - It has a `setState()` method: call this whenever you change a local
//     variable and want Flutter to redraw the widget.
//   - It has lifecycle methods: initState(), dispose(), build().
// -----------------------------------------------------------------------------
class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {

  // Which tab is currently visible: the library picker or the custom form.
  // Initialized to library so the library tab shows first.
  _AddMode _mode = _AddMode.library;

  // The category filter chip that is currently selected in the library tab.
  // Defaults to "focus" so users land on focus habits first.
  HabitCategory _filterCat = HabitCategory.focus;

  // --- Text controllers for the custom-habit form ---
  // Each TextEditingController is bound to one TextField. Reading .text gives
  // you whatever the user typed. Must be disposed to free memory.

  final _titleCtrl = TextEditingController();  // Habit title, e.g. "Morning Deep Work"
  final _cueCtrl = TextEditingController();    // Anchor cue, e.g. "After I wake up"
  final _actionCtrl = TextEditingController(); // The action to take, e.g. "I will meditate"
  final _rewardCtrl = TextEditingController(); // The reward, e.g. "Enjoy a coffee"
  final _whenCtrl = TextEditingController();   // Implementation intention: when condition
  final _thenCtrl = TextEditingController();   // Implementation intention: then action

  // The category the user picks for their custom habit (defaults to focus).
  HabitCategory _customCat = HabitCategory.focus;

  // ---------------------------------------------------------------------------
  /// dispose() is a Flutter lifecycle method called when this widget is removed
  /// from the screen permanently (e.g., sheet is dismissed).
  ///
  /// We MUST call .dispose() on every TextEditingController we created.
  /// If we skip this, the controllers keep listening in the background and leak
  /// memory — the app slows down over time.
  ///
  /// super.dispose() must be called LAST to let the parent class clean up too.
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _titleCtrl.dispose();  // Free memory held by the title text input.
    _cueCtrl.dispose();    // Free memory held by the cue text input.
    _actionCtrl.dispose(); // Free memory held by the action text input.
    _rewardCtrl.dispose(); // Free memory held by the reward text input.
    _whenCtrl.dispose();   // Free memory held by the when text input.
    _thenCtrl.dispose();   // Free memory held by the then text input.
    super.dispose();       // Always call super.dispose() at the end.
  }

  // ---------------------------------------------------------------------------
  /// _addFromLibrary — Called when the user taps a habit card in the library tab.
  ///
  /// Parameters:
  ///   [t] — A HabitTemplate object from the library containing pre-filled
  ///          fields (title, cue, action, reward, etc.).
  ///
  /// What it does:
  ///   1. Reads the neuroProvider notifier (the object that can MUTATE global state).
  ///   2. Calls addNeuroStack() to add the chosen habit to the global list.
  ///   3. Closes the bottom sheet with Navigator.pop().
  ///
  /// Side effect: The habits list in neuroProvider is updated, so any widget
  /// watching neuroProvider will rebuild and show the new habit.
  // ---------------------------------------------------------------------------
  void _addFromLibrary(HabitTemplate t) {
    // ref.read() is the Riverpod way to access a provider WITHOUT subscribing
    // (i.e., without causing this widget to rebuild when the provider changes).
    // .notifier gives us the NeuroNotifier object, which has mutation methods.
    // This is the correct pattern for one-off writes inside event handlers.
    ref.read(neuroProvider.notifier).addNeuroStack(
      title: t.title,                   // Pre-filled name from the template.
      anchorCue: t.anchorCue,           // The environmental cue from the template.
      action: t.action,                 // The specific action from the template.
      reward: t.reward,                 // The reward from the template.
      category: t.category,             // Which category this habit belongs to.
      acetylcholineDuration: 10,        // Hardcoded focus window (10 min). Acetylcholine
                                        // is a neurotransmitter tied to focused attention.
      whenCondition: t.anchorCue,       // Reuse anchorCue as the "when" condition for
                                        // implementation intention.
      thenAction: t.action,             // Reuse action as the "then" action.
    );
    // Navigator.pop(context) closes the bottom sheet and returns to the previous screen.
    // `context` is the BuildContext — Flutter's handle to where this widget lives in
    // the widget tree.
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  /// _addCustom — Called when the user taps "Add Habit" on the custom form.
  ///
  /// What it does:
  ///   1. Validates that the title is not empty (returns early if it is).
  ///   2. Reads user-typed values from each TextEditingController.
  ///   3. Calls addNeuroStack() on the provider to save the habit.
  ///   4. Closes the bottom sheet.
  ///
  /// Side effect: The habits list in neuroProvider is updated.
  // ---------------------------------------------------------------------------
  void _addCustom() {
    // .trim() removes leading/trailing whitespace. .isEmpty checks if the result
    // is an empty string. If the title is blank, we bail out early — no habit added.
    if (_titleCtrl.text.trim().isEmpty) return;

    // ref.read() gets the notifier without subscribing — same pattern as above.
    ref.read(neuroProvider.notifier).addNeuroStack(
      title: _titleCtrl.text.trim(),    // User-typed habit title.
      anchorCue: _cueCtrl.text.trim(),  // User-typed anchor cue.
      action: _actionCtrl.text.trim(),  // User-typed action.
      reward: _rewardCtrl.text.trim(),  // User-typed reward.
      category: _customCat,             // Category chosen via FilterChips.
      acetylcholineDuration: 10,        // Hardcoded 10-minute focus window.

      // The ?. operator is "null-safe access" — only call .trim() if the value
      // is not null (controllers always have a value, so .trim() is safe here).
      // The ternary "condition ? a : b" returns `a` if condition is true, else `b`.
      // Here: if the field is blank after trimming, pass null (optional field),
      // otherwise pass the trimmed string.
      whenCondition: _whenCtrl.text.trim().isEmpty ? null : _whenCtrl.text.trim(),
      thenAction: _thenCtrl.text.trim().isEmpty ? null : _thenCtrl.text.trim(),
    );

    Navigator.pop(context); // Close the sheet after saving.
  }

  // ---------------------------------------------------------------------------
  /// build() — Flutter calls this every time the widget needs to draw itself.
  /// It returns a tree of widgets describing the UI.
  ///
  /// Parameters:
  ///   [context] — BuildContext: Flutter's pointer to this widget's position
  ///               in the widget tree. Used to read themes, navigate, etc.
  ///
  /// Returns: A Widget tree describing the entire bottom sheet UI.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet is a special bottom sheet container that the user
    // can drag up and down. It does NOT scroll its content automatically — you
    // must pass the provided `controller` to any scrollable child inside.
    return DraggableScrollableSheet(
      initialChildSize: 0.9,  // On open, the sheet covers 90% of the screen height.
      maxChildSize: 0.95,     // User can drag it up to 95% of the screen height.
      minChildSize: 0.5,      // User can drag it down to 50% of the screen height.
      expand: false,          // false = the sheet does not expand to fill its parent.
                              // This is required when used inside showModalBottomSheet.

      // The builder gives us `controller` (a ScrollController) that we MUST pass
      // to our scrollable children so that the drag gesture works correctly.
      builder: (context, controller) => Container(
        // Container is a generic box widget. Here we use it to set background
        // color and rounded top corners for the sheet.
        decoration: BoxDecoration(
          color: context.bgColor, // context.bgColor is a helper from app_theme.dart
                                  // that reads the background color from the current theme.
          // BorderRadius.vertical applies rounded corners only on the top side.
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          // Column stacks children vertically from top to bottom.
          children: [
            const SizedBox(height: 12), // Invisible spacer widget, 12 logical pixels tall.

            // The small horizontal "drag handle" pill at the top of the sheet.
            // Container with a fixed width/height and a rounded rectangle shape.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor, // Subtle color from the theme.
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16), // Spacer between drag handle and header row.

            // Padding wraps its child with empty space on all specified sides.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24), // 24px on left and right.
              child: Row(
                // Row lays out children side by side horizontally.
                children: [
                  // Title text on the left.
                  // ?. is "null-safe member access" — only call .copyWith() if textTheme
                  // .titleMedium is not null. copyWith() creates a copy of the text style
                  // with specific fields overridden (here we override fontWeight).
                  Text(
                    'Add Habit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(), // Spacer() fills all remaining horizontal space,
                                  // pushing the SegmentedButton to the far right.

                  // SegmentedButton is a Material 3 widget — a row of toggle buttons
                  // where only ONE can be selected at a time (like radio buttons but
                  // styled as a connected bar).
                  SegmentedButton<_AddMode>(
                    // segments defines the two tabs: Library and Custom.
                    segments: const [
                      ButtonSegment(value: _AddMode.library, label: Text('Library')),
                      ButtonSegment(value: _AddMode.custom, label: Text('Custom')),
                    ],

                    // `selected` must be a Set<_AddMode>. We wrap _mode in curly braces
                    // {_mode} to create a Set literal containing just the current mode.
                    selected: {_mode},

                    // onSelectionChanged fires when the user taps a segment.
                    // `s` is the new Set of selected values. We call setState() so
                    // Flutter knows to redraw the widget with the new mode.
                    // setState(() { ... }) is the standard Flutter pattern for
                    // updating local state — always wrap mutations in setState.
                    onSelectionChanged: (s) => setState(() => _mode = s.first),

                    // VisualDensity.compact makes the button shorter/smaller.
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Expanded fills the remaining vertical space in the Column.
            // Without Expanded, the inner ListView would have infinite height
            // and Flutter would throw an error.
            Expanded(
              // Ternary: if library mode is selected, show _buildLibrary(),
              // otherwise show _buildCustom(). We pass `controller` so the
              // inner scroll views connect to the DraggableScrollableSheet drag.
              child: _mode == _AddMode.library
                  ? _buildLibrary(controller)
                  : _buildCustom(controller),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  /// _buildLibrary — Builds the UI for the "Library" tab.
  ///
  /// Parameters:
  ///   [controller] — The ScrollController from DraggableScrollableSheet. Must
  ///                  be passed to the inner ListView so dragging works.
  ///
  /// Returns: A Column containing category filter chips and a list of habit cards.
  // ---------------------------------------------------------------------------
  Widget _buildLibrary(ScrollController controller) {
    // .where() filters the list, keeping only items where the condition is true.
    // Here we only keep habits whose category matches the selected filter chip.
    // .toList() converts the lazy Iterable result back into a concrete List.
    final filtered = habitLibrary.where((h) => h.category == _filterCat).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          // SingleChildScrollView makes its single child scrollable.
          // scrollDirection: Axis.horizontal means it scrolls left-right
          // (so the category chips don't overflow on narrow screens).
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // HabitCategory.values is the auto-generated list of all enum values.
              // .map() transforms each value (cat) into a new widget (Padding+FilterChip).
              // The => arrow is shorthand for a one-expression function body.
              children: HabitCategory.values.map((cat) {
                // Is this chip currently the active filter? true or false.
                final selected = cat == _filterCat;

                // Map each category to its theme color. These constants come from app_theme.dart.
                final colors = {
                  HabitCategory.focus: focusColor,
                  HabitCategory.wellness: wellnessColor,
                  HabitCategory.mindset: mindsetColor,
                  HabitCategory.fitness: fitnessColor,
                };

                // Map each category to its display label string.
                final labels = {
                  HabitCategory.focus: 'Focus',
                  HabitCategory.wellness: 'Wellness',
                  HabitCategory.mindset: 'Mindset',
                  HabitCategory.fitness: 'Fitness',
                };

                // The ! after colors[cat] asserts "this value is NOT null".
                // Dart maps return a nullable type (Color?) but we know every
                // category has an entry, so ! tells the compiler to trust us.
                final color = colors[cat]!;

                // Wrap each chip in Padding to add space between chips.
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labels[cat]!),  // Display label for this chip.
                    selected: selected,          // Whether this chip is highlighted/active.

                    // onSelected fires when the user taps the chip.
                    // The underscore `_` is a convention for ignoring the bool
                    // parameter we don't need. setState triggers a UI redraw.
                    onSelected: (_) => setState(() => _filterCat = cat),

                    // .withOpacity(0.2) makes the color 80% transparent (20% opaque).
                    selectedColor: color.withOpacity(0.2), // Tinted background when selected.
                    checkmarkColor: color,                  // Color of the checkmark icon.

                    labelStyle: TextStyle(
                      // Only apply colored/bold text when this chip is selected.
                      // null means "use the default style" — Dart ignores null style props.
                      color: selected ? color : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                );
              }).toList(), // .toList() converts the .map() Iterable into a List<Widget>.
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Expanded fills remaining vertical space so the list doesn't shrink.
        Expanded(
          child: ListView.separated(
            controller: controller, // IMPORTANT: connects drag gestures to the sheet.
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filtered.length, // How many habit cards to render.

            // separatorBuilder draws a widget BETWEEN items (not before/after).
            // The underscores (_,__) ignore the context and index parameters.
            separatorBuilder: (_, __) => const SizedBox(height: 10),

            // itemBuilder is called once per item, returning the widget for that row.
            // `i` is the index (0-based).
            itemBuilder: (context, i) {
              final h = filtered[i]; // Get the HabitTemplate at position i.

              // GestureDetector wraps any widget to detect touch events.
              // onTap fires when the user taps anywhere on this card.
              return GestureDetector(
                onTap: () => _addFromLibrary(h), // Tap => add this template as a habit.
                child: Container(
                  padding: const EdgeInsets.all(14), // 14px padding on all sides inside the card.
                  decoration: BoxDecoration(
                    color: context.cardBg,                  // Card background from theme.
                    borderRadius: BorderRadius.circular(12), // Rounded card corners.
                    border: Border.all(color: context.borderColor), // Thin outline border.
                  ),
                  child: Column(
                    // crossAxisAlignment controls alignment on the CROSS axis.
                    // For a vertical Column, the cross axis is horizontal.
                    // .start means children align to the left edge.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Expanded here fills remaining width so the title doesn't
                          // overlap the duration badge on the right.
                          Expanded(
                            child: Text(
                              h.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Duration badge — a small pill-shaped container with text.
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.borderColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              h.duration, // e.g. "5 min"
                              style: TextStyle(fontSize: 11, color: context.textSecondary),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Short description of the habit.
                      Text(
                        h.description,
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),

                      const SizedBox(height: 6),

                      // Shows the anchor cue with a "Cue:" prefix.
                      // maxLines: 1 prevents this from wrapping onto a second line.
                      // overflow: TextOverflow.ellipsis adds "..." if text is too long.
                      Text(
                        'Cue: ${h.anchorCue}', // ${} is string interpolation — embeds the value.
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  /// _buildCustom — Builds the UI for the "Custom" tab (the manual entry form).
  ///
  /// Parameters:
  ///   [controller] — The ScrollController from DraggableScrollableSheet.
  ///                  Passed to SingleChildScrollView so the sheet can be dragged.
  ///
  /// Returns: A scrollable form with labeled text fields, an Implementation
  ///          Intention section, category chips, and an "Add Habit" button.
  // ---------------------------------------------------------------------------
  Widget _buildCustom(ScrollController controller) {
    // SingleChildScrollView makes its one child scrollable when it's taller than
    // the available space. Unlike ListView, it renders all children at once.
    return SingleChildScrollView(
      controller: controller, // Connects scroll to the DraggableScrollableSheet.
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left.
        children: [
          // _Field is our private helper widget (defined at the bottom of this file).
          // Each _Field renders a label + a TextField.
          _Field(label: 'Habit Title', controller: _titleCtrl, hint: 'e.g. Morning Deep Work'),
          _Field(label: 'Anchor Cue', controller: _cueCtrl, hint: 'After I...'),
          _Field(label: 'Action', controller: _actionCtrl, hint: 'I will...'),
          _Field(label: 'Reward', controller: _rewardCtrl, hint: 'I will reward myself with...'),

          const SizedBox(height: 20),

          // --- Implementation Intention Section ---
          // Research by Gollwitzer (1999) shows that writing "When X, I will do Y"
          // triples the likelihood of following through on an intention.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // Color(0xFF6366F1) is an indigo/purple color specified as a hex code.
              // 0xFF is the alpha channel (fully opaque); 6366F1 is the RGB value.
              // .withOpacity(0.07) makes it very faint — just a slight tint.
              color: const Color(0xFF6366F1).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: lightbulb icon + "Implementation Intention" label.
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline, // Outline-style lightbulb icon.
                      color: Color(0xFF6366F1),
                      size: 16, // Icon size in logical pixels.
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Implementation Intention',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Explanatory subtext referencing the research basis.
                Text(
                  'Triples follow-through (Gollwitzer, 1999). Specify exactly when and what.',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),

                const SizedBox(height: 12),

                // Two optional fields for the if-then plan.
                _Field(
                  label: 'When…',
                  controller: _whenCtrl,
                  hint: 'e.g. I sit down at my desk at 9am',
                ),
                _Field(
                  label: 'I will…',
                  controller: _thenCtrl,
                  hint: 'e.g. open my task list and work for 25 min',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Category picker label.
          Text('Category', style: Theme.of(context).textTheme.labelLarge),

          const SizedBox(height: 8),

          // Wrap is like Row but wraps onto the next line when it runs out of space.
          // spacing: 8 adds 8px of horizontal space between chips.
          Wrap(
            spacing: 8,
            // Same pattern as the library filter chips above: map each category
            // to a FilterChip, then convert to a List<Widget>.
            children: HabitCategory.values.map((cat) {
              final colors = {
                HabitCategory.focus: focusColor,
                HabitCategory.wellness: wellnessColor,
                HabitCategory.mindset: mindsetColor,
                HabitCategory.fitness: fitnessColor,
              };
              final labels = {
                HabitCategory.focus: 'Focus',
                HabitCategory.wellness: 'Wellness',
                HabitCategory.mindset: 'Mindset',
                HabitCategory.fitness: 'Fitness',
              };

              final selected = _customCat == cat; // Is this the currently chosen category?
              final color = colors[cat]!;         // The ! asserts non-null (safe here).

              return FilterChip(
                label: Text(labels[cat]!),
                selected: selected,
                // Tapping a chip updates _customCat, setState triggers a redraw.
                onSelected: (_) => setState(() => _customCat = cat),
                selectedColor: color.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected ? color : null, // Apply category color only when selected.
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // "Add Habit" submit button — spans the full width of the screen.
          SizedBox(
            width: double.infinity, // double.infinity means "as wide as possible".
            child: ElevatedButton(
              onPressed: _addCustom, // Call _addCustom when tapped.
              child: const Text('Add Habit'),
            ),
          ),

          const SizedBox(height: 32), // Bottom padding so the button isn't flush with the edge.
        ],
      ),
    );
  }
}

// =============================================================================
// CLASS: _Field (private helper widget)
//
// A simple reusable widget that combines a text label with a text input field
// below it. The leading underscore makes it private to this file.
//
// Extends StatelessWidget — the simplest type of Flutter widget. It has NO
// mutable state of its own; it just builds a fixed UI based on its input
// properties. It does NOT need ConsumerWidget because it doesn't touch Riverpod.
//
// Where it is used: only inside _AddHabitSheetState._buildCustom() above.
// =============================================================================
class _Field extends StatelessWidget {
  final String label;                   // The text shown above the input box, e.g. "Habit Title".
  final TextEditingController controller; // The controller that reads/writes the input value.
  final String hint;                    // Placeholder text shown inside the input when empty.

  /// Constructor. `required` means callers MUST provide these arguments.
  /// All fields are `final` because StatelessWidget properties never change.
  const _Field({required this.label, required this.controller, required this.hint});

  // ---------------------------------------------------------------------------
  /// build() draws this widget's UI tree.
  ///
  /// Parameters:
  ///   [context] — BuildContext for reading the current theme.
  ///
  /// Returns: A Column with a label text, a small gap, and a TextField.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align label and input to the left.
      children: [
        const SizedBox(height: 16), // Space above this field to separate it from the previous one.

        // The field label, styled using the app's labelLarge text theme.
        Text(label, style: Theme.of(context).textTheme.labelLarge),

        const SizedBox(height: 6), // Small gap between label and the text box.

        // TextField is Flutter's text input widget.
        // `controller` links it to the TextEditingController so we can read
        // what the user typed from outside this widget.
        // `decoration` customizes the visual appearance of the input box.
        // InputDecoration(hintText: hint) shows placeholder text when empty.
        TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
