// =============================================================================
// FILE: routine_blueprint_page.dart
//
// WHAT THIS FILE IS:
//   This file defines the "Routine Blueprint" screen — a personalized list of
//   recommended habits generated from the user's brain profile quiz results.
//   The user can review, deselect any habits they don't want, then tap a button
//   to activate their chosen habits and officially start their routine.
//
// ROLE IN APP ARCHITECTURE:
//   This page is shown right after the onboarding quiz. It reads the user's
//   brain profile from the global Riverpod state (neuroProvider), runs it
//   through the blueprint engine to pick suitable habits from the habit library,
//   then writes the user's selections back into global state when they confirm.
//   After confirmation the app navigates away and never shows this page again.
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   - Flutter widgets: Everything you see on screen is a "Widget" — a Dart class
//     that describes a piece of UI. Widgets can contain other widgets (like HTML
//     nesting). Flutter re-runs the build() method whenever data changes.
//   - StatefulWidget vs StatelessWidget: A StatelessWidget's appearance is fixed
//     once built. A StatefulWidget has mutable "state" — internal data that can
//     change and trigger a visual rebuild via setState().
//   - ConsumerWidget / ConsumerStatefulWidget: Riverpod adds these variants so
//     widgets can "watch" or "read" global state providers. When a watched
//     provider value changes, the widget automatically rebuilds.
//   - Riverpod providers: Think of them as global reactive variables. Any widget
//     can subscribe to them and automatically re-render when they change.
//   - Dart null-safety: The ? symbol after a type means the value might be null
//     (absent). The ?? operator provides a fallback: (a ?? b) returns a if not
//     null, otherwise b. The ?. "null-safe dot" only calls a method if the object
//     is not null.
// =============================================================================

// Brings in Flutter's core UI toolkit — Material Design widgets, colors, icons,
// layout primitives (Column, Row, Container, etc.) and the base Widget class.
import 'package:flutter/material.dart';

// flutter_animate provides the .animate(), .fadeIn(), .slideY() extension
// methods that add smooth entry/exit animations to any widget with minimal code.
import 'package:flutter_animate/flutter_animate.dart';

// flutter_riverpod is the state-management library for this app. It supplies
// ConsumerStatefulWidget, ConsumerState, ref.watch, and ref.read — the main
// tools for reading and reacting to global application state.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// uuid generates universally-unique IDs (random strings like "a3f2…"). We use
// it to give every new NeuroStack a unique ID so records never collide.
import 'package:uuid/uuid.dart';

// neuro_provider.dart holds the global Riverpod provider (neuroProvider) and
// the notifier (NeuroNotifier) that owns all app state mutations — it is the
// single source of truth for habit data, brain profile, and progress.
import '../providers/neuro_provider.dart';

// models.dart defines the Dart data classes used throughout the app:
// NeuroStack (an active habit), HabitTemplate (a blueprint suggestion),
// HabitCategory (focus / wellness / mindset / fitness), etc.
import '../models/models.dart';

// habit_library.dart exports `habitLibrary`, a hardcoded list of HabitTemplate
// objects — the full catalogue of habits the app knows about.
import '../data/habit_library.dart';

// blueprint_engine.dart exports `buildBlueprint()`, the algorithm that selects
// and orders habits from the library based on the user's brain profile.
import '../utils/blueprint_engine.dart';

// app_theme.dart exports design tokens: colour constants (focusColor, etc.) and
// BuildContext extension helpers (context.cardBg, context.textSecondary, etc.)
// so we can write theme-aware code without hard-coding colours everywhere.
import '../theme/app_theme.dart';

// A single shared Uuid instance. Creating it once at the top level is more
// efficient than creating a new Uuid() object inside every loop iteration.
const _uuid = Uuid();

/// RoutineBlueprintPage — the full-screen page that shows the AI-generated
/// habit blueprint for the user to review and activate.
///
/// It extends [ConsumerStatefulWidget] because:
///   1. It needs **state** (which habits are selected) that changes when the
///      user taps cards — hence "Stateful".
///   2. It needs to **read from the global Riverpod provider** (neuroProvider)
///      to get the brain profile — hence "Consumer".
///
/// Usage: pushed onto the navigation stack after the quiz completes.
class RoutineBlueprintPage extends ConsumerStatefulWidget {
  // The `const` constructor tells Flutter this widget's configuration is fixed
  // at compile time. `super.key` passes an optional identity key up to Flutter's
  // widget framework so it can track the widget across rebuilds.
  const RoutineBlueprintPage({super.key});

  /// createState() is called once by Flutter to create the mutable state object
  /// paired with this widget. It must return a ConsumerState subclass.
  @override
  ConsumerState<RoutineBlueprintPage> createState() => _RoutineBlueprintPageState();
}

/// _RoutineBlueprintPageState holds all mutable data for RoutineBlueprintPage.
///
/// The leading underscore (_) is Dart's convention for "private to this file".
/// ConsumerState gives us `ref` — a handle to the Riverpod container — so we
/// can read or watch providers anywhere inside this class.
class _RoutineBlueprintPageState extends ConsumerState<RoutineBlueprintPage> {
  /// The full ordered list of habit templates to display on this page.
  /// `late` means "I promise to initialise this before it is first read."
  /// It is populated in initState() so it is ready before the first build().
  late List<HabitTemplate> _habits;

  /// The IDs of habits the user has currently selected (checked). Starts as all
  /// habits selected, then toggled by the user. A Set is used (not a List)
  /// because Set membership checks (.contains) are O(1) — instant regardless of
  /// how many items are in it, whereas List.contains is O(n).
  late Set<String> _selectedIds;

  /// initState() is Flutter's lifecycle hook called once right after the state
  /// object is inserted into the widget tree. It is the right place to do
  /// one-time setup that needs the BuildContext or Riverpod ref.
  ///
  /// We use `ref.read` here (not `ref.watch`) because we only want the value
  /// once at startup — we don't want to subscribe to future changes.
  @override
  void initState() {
    super.initState(); // Always call super first — Flutter requires it.

    // ref.read() fetches the current value of neuroProvider without subscribing
    // to future updates. This is appropriate in initState because we just need
    // a snapshot to build the initial list.
    final state = ref.read(neuroProvider);

    // Decide which habits to show:
    // - If the user completed the quiz, state.brainProfile is non-null, so we
    //   call buildBlueprint() to get a personalized selection.
    // - If somehow there is no profile (e.g. deep-link edge case), we fall back
    //   to the first 5 habits from the full library using .take(5).toList().
    _habits = state.brainProfile != null
        ? buildBlueprint(state.brainProfile!, state.neurochemistry)
        // The ! after brainProfile asserts "I know this is not null" — safe
        // here because we just checked it in the condition above.
        : habitLibrary.take(5).toList();

    // Pre-select every habit: map each template to its id, then collect into a
    // Set with .toSet(). The user can deselect individual ones via the UI.
    _selectedIds = _habits.map((h) => h.id).toSet();
    // .map((h) => h.id) transforms each HabitTemplate h into its String id.
    // .toSet() collects those strings into a Set<String>.
  }

  /// _accept() is called when the user taps the "Activate" button.
  ///
  /// It converts the selected HabitTemplates into full NeuroStack records,
  /// persists them into the global Riverpod state, and marks the blueprint as
  /// accepted so the app transitions to the main habit-tracking screen.
  ///
  /// Side effects:
  ///   - Calls ref.read(neuroProvider.notifier).addBlueprintHabits() — writes
  ///     the new stacks into global state (and presumably persists to storage).
  ///   - Calls ref.read(neuroProvider.notifier).acceptBlueprint() — sets a flag
  ///     that causes the router to navigate away from this page.
  void _accept() {
    // Filter _habits to only those whose IDs are in _selectedIds.
    // .where() is like JavaScript's Array.filter() — it keeps elements for
    // which the callback returns true.
    final selected = _habits.where((h) => _selectedIds.contains(h.id)).toList();

    // Transform each selected HabitTemplate into a NeuroStack (a live habit).
    // .map() is like Array.map() — it converts each element to something else.
    final stacks = selected.map((h) => NeuroStack(
      // _uuid.v4() generates a random UUID string like "f47ac10b-58cc-...".
      // Prefixing with 'stack-' makes the ID's purpose obvious when debugging.
      id: 'stack-${_uuid.v4()}',
      title: h.title,           // Human-readable name copied from the template.
      anchorCue: h.anchorCue,   // The "trigger" event that precedes the habit.
      action: h.action,         // The specific behaviour to perform.
      reward: h.reward,         // The reinforcement linked to the action.
      category: h.category,     // focus / wellness / mindset / fitness enum value.
      acetylcholineDuration: 10, // Minutes of focus-chemical effect; default 10.
      myelinationLevel: 0,       // Neurological "groove" depth; starts at 0.
      streak: 0,                 // Consecutive-day completion count; starts at 0.
      completions: const [],     // No completions yet — empty immutable list.
      // DateTime.now() gets the current timestamp; .toIso8601String() formats it
      // as "2026-05-29T14:32:00.000" — a standard, storable date string.
      createdAt: DateTime.now().toIso8601String(),
      isActive: true,            // Habit is active immediately upon creation.
    )).toList(); // Materialise the lazy map into an actual List<NeuroStack>.

    // ref.read(neuroProvider.notifier) accesses the NeuroNotifier — the class
    // that owns all mutation methods for the global state. We use .read (not
    // .watch) in callbacks because we don't need to rebuild here, just act.
    ref.read(neuroProvider.notifier).addBlueprintHabits(stacks);

    // Mark blueprint as accepted. The app's router or parent widget watches this
    // flag and will navigate the user to the main dashboard automatically.
    ref.read(neuroProvider.notifier).acceptBlueprint();
  }

  /// build() is called by Flutter every time this widget needs to render.
  /// It describes the full UI tree to display. Flutter diffs it against the
  /// previous tree and applies only the changes — you don't manually update DOM.
  ///
  /// [context] gives access to theme, media query, navigator, and other
  /// ambient information about where this widget sits in the tree.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the standard Material page structure: background colour,
    // optional AppBar at top, optional BottomNavigationBar, floating buttons, etc.
    // We omit the appBar here to get a fully custom header.
    return Scaffold(
      // SafeArea pads its child so content doesn't overlap the status bar at the
      // top (camera notch, time) or the home indicator at the bottom.
      body: SafeArea(
        // CustomScrollView allows mixing different kinds of scrollable content
        // (called "slivers") in one scroll. Regular ListView only supports one
        // content type. We need slivers because we want a header, a lazy list,
        // and a footer button all scrolling together.
        child: CustomScrollView(
          // slivers is a list of "sliver" widgets — special scroll-aware pieces.
          slivers: [
            // SliverPadding wraps a sliver with edge padding.
            // fromLTRB means Left=24, Top=48, Right=24, Bottom=0.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              // SliverToBoxAdapter lets you put a regular (non-sliver) widget
              // inside a CustomScrollView. Think of it as the adapter plug.
              sliver: SliverToBoxAdapter(
                child: Column(
                  // CrossAxisAlignment.start aligns children to the LEFT edge
                  // (in a Column the cross-axis is horizontal).
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small pill badge above the title — uses a Container with
                    // padding, rounded corners, and a semi-transparent purple bg.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        // withOpacity(0.15) makes the colour 85% transparent —
                        // gives a light tint rather than a solid background.
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        // BorderRadius.circular(20) rounds all four corners to
                        // a pill shape. 20 logical pixels of radius.
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Your Personalized Blueprint',
                        // Theme.of(context) retrieves the active MaterialTheme.
                        // textTheme.labelSmall is the smallest preset text style.
                        // .copyWith() creates a copy with specific properties overridden.
                        // The ?. is null-safe access — if labelSmall is null, the whole
                        // expression returns null instead of crashing.
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF6366F1)),
                      ),
                    ),
                    // SizedBox is an invisible box used to add fixed whitespace
                    // between widgets. height: 12 = 12 logical pixels of gap.
                    const SizedBox(height: 12),
                    // Main title. .animate() from flutter_animate starts an
                    // animation chain. .fadeIn() makes it fade in from opacity 0.
                    Text(
                      'Your Starter Routine',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ).animate().fadeIn(), // Fades in on first render.
                    const SizedBox(height: 8),
                    Text(
                      // The backslash before ' escapes the apostrophe so Dart
                      // doesn't think it ends the string literal.
                      'Based on your brain profile. Deselect any that don\'t fit — you can always add more later.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // context.textSecondary is an extension on BuildContext
                        // defined in app_theme.dart — returns a muted grey colour
                        // that adapts to light/dark mode automatically.
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Second sliver: the scrollable list of habit cards.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              // SliverList renders a scrollable list. It is more efficient than
              // wrapping a Column in SliverToBoxAdapter because it only builds
              // widgets that are currently visible on screen (lazy rendering).
              sliver: SliverList(
                // SliverChildBuilderDelegate tells SliverList how to build each
                // item on demand. The builder callback receives (context, index i)
                // and must return the widget for that position.
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final h = _habits[i]; // The HabitTemplate at position i.
                    // Check if this habit is currently selected by looking up
                    // its ID in the Set. Set.contains is O(1) — very fast.
                    final selected = _selectedIds.contains(h.id);
                    return Padding(
                      // Only add bottom padding (12px gap below each card).
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BlueprintCard(
                        habit: h,
                        selected: selected,
                        // onToggle is a callback (a function passed as a value).
                        // When the card is tapped it calls this closure, which
                        // calls setState() to toggle the selection and rebuild.
                        onToggle: () {
                          // setState() tells Flutter "my data changed, rebuild
                          // this widget." Everything inside the callback runs
                          // first, then Flutter re-calls build().
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(h.id); // Deselect the habit.
                            } else {
                              _selectedIds.add(h.id);    // Select the habit.
                            }
                          });
                        },
                        // Staggered entrance animation: each card fades in and
                        // slides up, but with a delay that increases per item
                        // so cards appear one after another, not all at once.
                        // (i * 80).ms converts the int to a Duration in milliseconds.
                        // .slideY(begin: 0.1) slides from 10% below its final position.
                      ).animate(delay: (i * 80).ms).fadeIn().slideY(begin: 0.1),
                    );
                  },
                  childCount: _habits.length, // Total number of list items.
                ),
              ),
            ),

            // Third sliver: the sticky-bottom "Activate" button.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              sliver: SliverToBoxAdapter(
                child: ElevatedButton(
                  // If nothing is selected, onPressed = null which disables the
                  // button (it turns grey and ignores taps). Otherwise use _accept.
                  // The ternary syntax is: condition ? valueIfTrue : valueIfFalse.
                  onPressed: _selectedIds.isEmpty ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    // double.infinity means "take the full available width".
                    // 52 logical pixels tall gives a comfortable tap target.
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  // Dynamic label: shows the count and correctly pluralises "Habit".
                  // The inner ternary adds 's' only when count != 1.
                  // String interpolation: ${expression} embeds the result inline.
                  child: Text('Activate ${_selectedIds.length} Habit${_selectedIds.length != 1 ? 's' : ''}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// _BlueprintCard renders a single selectable habit card in the blueprint list.
///
/// It extends [StatelessWidget] because it has NO internal mutable state —
/// everything it needs is passed in via constructor parameters. The parent
/// (_RoutineBlueprintPageState) owns the selection state and passes it down.
///
/// This is the "dumb component" pattern: the card only displays and fires
/// callbacks; it doesn't decide what happens when toggled.
class _BlueprintCard extends StatelessWidget {
  /// The habit data to display (title, description, category, cue, action…).
  final HabitTemplate habit;

  /// Whether this card is currently checked/selected by the user.
  final bool selected;

  /// Callback invoked when the user taps the card to toggle its selection.
  /// VoidCallback is a Dart typedef for `void Function()` — a function that
  /// takes no arguments and returns nothing.
  final VoidCallback onToggle;

  /// Constructor. All three fields are required (annotated `required`).
  /// There is no `super.key` here because this is a private widget — it won't
  /// be used in widget trees that need stable keys.
  const _BlueprintCard({required this.habit, required this.selected, required this.onToggle});

  /// Maps each HabitCategory enum value to its display colour.
  /// `static` means the map belongs to the class itself, not each instance —
  /// it is created once and shared. `const` means it is a compile-time constant.
  static const _catColors = {
    HabitCategory.focus: focusColor,       // Purple/indigo accent for focus habits.
    HabitCategory.wellness: wellnessColor, // Green accent for wellness habits.
    HabitCategory.mindset: mindsetColor,   // Orange accent for mindset habits.
    HabitCategory.fitness: fitnessColor,   // Blue accent for fitness habits.
  };

  /// Maps each HabitCategory to the human-readable label shown on the pill badge.
  static const _catLabels = {
    HabitCategory.focus: 'Focus',
    HabitCategory.wellness: 'Wellness',
    HabitCategory.mindset: 'Mindset',
    HabitCategory.fitness: 'Fitness',
  };

  /// build() describes the visual tree for a single card.
  ///
  /// [context] carries ambient data like the current theme and screen size.
  @override
  Widget build(BuildContext context) {
    // Look up colour and label for this card's category.
    // The ?? operator provides a fallback: if the key is missing from the map
    // (shouldn't happen, but Dart's type system requires a fallback), use
    // focusColor / an empty string.
    final color = _catColors[habit.category] ?? focusColor;
    final label = _catLabels[habit.category] ?? '';

    // GestureDetector wraps its child and listens for user touch gestures.
    // onTap fires when the user briefly touches and lifts their finger.
    return GestureDetector(
      onTap: onToggle, // Delegate the tap handling to the parent's callback.
      // AnimatedContainer smoothly transitions its visual properties over
      // `duration` whenever they change — here the border colour/width animates
      // when `selected` toggles between true and false.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // 200ms transition speed.
        padding: const EdgeInsets.all(16), // 16px padding on all four sides.
        decoration: BoxDecoration(
          // context.cardBg is a theme extension from app_theme.dart — it
          // returns the correct card background colour for light or dark mode.
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16), // Rounded card corners.
          // The border changes thickness and colour based on selection state.
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : context.borderColor,
            // Selected = 2px indigo border; deselected = 1px subtle border.
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Left-align all children.
          children: [
            // TOP ROW: category badge, duration badge, and selection checkbox.
            Row(
              children: [
                // Category colour pill (e.g. "Focus" in purple).
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15), // Light tint of the category colour.
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600, // Semi-bold (600 on the 100-900 scale).
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Gap between the two badges.
                // Duration pill (e.g. "5 min").
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.borderColor, // Neutral tint for the duration badge.
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    habit.duration,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textSecondary),
                  ),
                ),
                // Spacer() expands to fill all remaining horizontal space in the
                // Row, pushing everything after it to the far right.
                const Spacer(),
                // Circular checkbox indicator — animates between filled (selected)
                // and hollow (deselected) states.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,  // Fixed 24x24 logical pixel square.
                  height: 24,
                  decoration: BoxDecoration(
                    // Filled indigo when selected; transparent when not.
                    color: selected ? const Color(0xFF6366F1) : Colors.transparent,
                    shape: BoxShape.circle, // Clip to a perfect circle.
                    border: Border.all(
                      // Border colour matches fill colour when selected.
                      color: selected ? const Color(0xFF6366F1) : context.textSecondary,
                    ),
                  ),
                  // Show a white checkmark icon only when selected.
                  // The null after : means "render nothing" when deselected.
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Habit title in bold.
            Text(
              habit.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Short description in muted secondary text colour.
            Text(
              habit.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            // Inset panel showing the habit's Cue and Action in a subtle box.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // context.isDark checks if dark mode is active (extension from
                // app_theme.dart). We pick a slightly different background tint
                // for dark vs light mode to keep contrast comfortable.
                color: context.isDark ? const Color(0xFF1E2A45) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _InfoRow is the small reusable widget defined below this class.
                  // It renders "icon  Label: value" on one line.
                  _InfoRow(icon: Icons.link, label: 'Cue', value: habit.anchorCue),
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.bolt, label: 'Action', value: habit.action),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// _InfoRow renders a single labelled line inside the habit card's info panel.
///
/// Example output:  🔗  Cue: After morning coffee
///
/// It is [StatelessWidget] because it only displays data — no state needed.
/// Extracted into its own widget to avoid repeating the same icon+label+value
/// layout pattern twice (for Cue and Action rows) — DRY principle.
class _InfoRow extends StatelessWidget {
  /// The icon to show on the left side (from the Material Icons font).
  /// IconData is the type Flutter uses for icon identifiers like Icons.link.
  final IconData icon;

  /// The short label shown in bold before the colon (e.g. "Cue", "Action").
  final String label;

  /// The content text shown after the label (e.g. "After morning coffee").
  final String value;

  /// All three fields are required — there is no sensible default for any of them.
  const _InfoRow({required this.icon, required this.label, required this.value});

  /// build() returns a Row that lays out: Icon | gap | "Label: " | value text.
  @override
  Widget build(BuildContext context) {
    return Row(
      // CrossAxisAlignment.start aligns all children to the TOP of the row.
      // This matters if the value wraps to multiple lines — the icon stays
      // at the top rather than vertically centred against a tall text block.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small icon using the secondary text colour so it doesn't overwhelm.
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 6), // Small gap between icon and text.
        // Bold label with a colon — NOT expanded so it takes only its natural width.
        Text(
          '$label: ', // String interpolation: embeds label variable into the string.
          style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600),
        ),
        // Expanded wraps a widget and tells it to fill the remaining horizontal
        // space in the Row. This makes the value text wrap onto new lines if it
        // is too long, rather than overflowing off screen.
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 12, color: context.textSecondary)),
        ),
      ],
    );
  }
}
