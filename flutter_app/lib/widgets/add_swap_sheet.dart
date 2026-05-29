// =============================================================================
// FILE: add_swap_sheet.dart
//
// What this file is:
//   A bottom sheet form that lets the user create a new "Neuro Swap" — a
//   neuroscience-based habit replacement strategy (cue → bad response →
//   intercept action + friction barriers).
//
// Role in the app architecture:
//   - Displayed by other screens (e.g. the habit list screen) by calling
//     showModalBottomSheet(), which slides this sheet up from the bottom of
//     the display.
//   - On save, it calls neuroProvider (defined in providers/neuro_provider.dart)
//     to persist the new swap into app state.
//   - Uses AppTheme extensions from theme/app_theme.dart for colours so the
//     sheet automatically respects light/dark mode.
//
// Key concepts to understand this file:
//   1. Bottom Sheet  — a panel that slides up from the bottom of the screen,
//      like a drawer but coming from below.
//   2. ConsumerStatefulWidget — a Flutter widget that (a) can hold mutable
//      local state AND (b) can read from Riverpod providers (global state).
//   3. TextEditingController — an object that tracks what a user has typed
//      into a TextField input box.
//   4. Riverpod — the state management library used in this app. It stores
//      data (providers) that any widget can subscribe to.
//   5. DraggableScrollableSheet — a Flutter widget that lets the user drag the
//      bottom sheet up or down to resize it.
// =============================================================================

// Brings in Flutter's core UI toolkit: widgets, colours, layout, etc.
// Almost every Flutter file starts with this import.
import 'package:flutter/material.dart';

// Brings in the Riverpod state management library.
// Specifically imports ConsumerStatefulWidget, ConsumerState, and ref.read/watch.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports our app's global state provider (neuroProvider) and the
// addNeuroSwap() method that persists a new swap to shared state.
import '../providers/neuro_provider.dart';

// Imports custom colour helpers (context.bgColor, context.borderColor) that
// come from extension methods defined on BuildContext in app_theme.dart.
import '../theme/app_theme.dart';

/// AddSwapSheet is the form sheet for creating a new Neuro Swap.
///
/// It extends [ConsumerStatefulWidget], which is a Riverpod-aware version of
/// Flutter's [StatefulWidget]. Use this base class whenever your widget needs
/// BOTH local mutable state (e.g. what the user typed) AND access to Riverpod
/// providers (e.g. saving to global app state).
///
/// This widget is meant to be shown as a modal bottom sheet — the calling code
/// typically does:
///   showModalBottomSheet(context: context, builder: (_) => AddSwapSheet());
class AddSwapSheet extends ConsumerStatefulWidget {
  // const constructor — Dart keyword meaning this widget's configuration is
  // compile-time constant, which lets Flutter optimize rebuilds.
  // {super.key} passes an optional identity key to the parent class so Flutter
  // can track this widget across rebuilds.
  const AddSwapSheet({super.key});

  /// createState() is required by StatefulWidget. Flutter calls this once to
  /// create the mutable state object that lives alongside this widget.
  /// The underscore prefix on _AddSwapSheetState marks it as private to this
  /// file — other files cannot access it directly.
  @override
  ConsumerState<AddSwapSheet> createState() => _AddSwapSheetState();
}

/// _AddSwapSheetState holds ALL the mutable data for the AddSwapSheet form.
///
/// It extends [ConsumerState], which is Riverpod's version of Flutter's State.
/// ConsumerState gives us access to `ref` — an object that lets us read and
/// watch Riverpod providers from inside the state class.
///
/// Naming convention: state classes are usually prefixed with underscore and
/// the word "State", e.g. _AddSwapSheetState for AddSwapSheet.
class _AddSwapSheetState extends ConsumerState<AddSwapSheet> {

  // ── Text input controllers ─────────────────────────────────────────────────
  // TextEditingController is an object that links to a TextField widget.
  // It lets us read what the user typed (via .text) and also programmatically
  // set or clear the field. Each field in our form gets its own controller.

  /// Stores the name the user gives to the bad habit (e.g. "Mindless Scrolling").
  final _titleCtrl = TextEditingController();

  /// Stores the trigger/cue that precedes the bad habit (e.g. "I feel bored").
  final _cueCtrl = TextEditingController();

  /// Stores a description of the unwanted habitual response (e.g. "I reach for my phone").
  final _badCtrl = TextEditingController();

  /// Stores the replacement intercept action (e.g. "I will take 5 deep breaths").
  final _interceptCtrl = TextEditingController();

  // ── Friction fields ────────────────────────────────────────────────────────

  /// The overall friction intensity level, from 1 (easy) to 5 (very hard).
  /// Starts at 2. Updated when the user moves the Slider widget.
  int _frictionLevel = 2;

  /// A dynamic list of text controllers, one per friction barrier step.
  /// Starts with one empty controller. The user can add up to 5 steps by
  /// pressing the "Add" button. Each controller tracks one barrier text field.
  final List<TextEditingController> _frictionCtrls = [TextEditingController()];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// dispose() is called by Flutter when this widget is permanently removed
  /// from the screen. It is the correct place to free resources that would
  /// otherwise keep living in memory and cause memory leaks.
  ///
  /// TextEditingControllers hold onto system resources, so we must call
  /// .dispose() on each one when we are done with them.
  @override
  void dispose() {
    _titleCtrl.dispose();     // Release memory held by the habit name field.
    _cueCtrl.dispose();       // Release memory held by the cue/trigger field.
    _badCtrl.dispose();       // Release memory held by the old response field.
    _interceptCtrl.dispose(); // Release memory held by the intercept action field.

    // Loop over every dynamically created friction step controller and dispose
    // each one. `for (final c in _frictionCtrls)` iterates the list; `final`
    // means the variable c cannot be reassigned inside the loop body.
    for (final c in _frictionCtrls) c.dispose();

    // Always call super.dispose() last — it lets the parent class clean up too.
    super.dispose();
  }

  // ── Event handlers ─────────────────────────────────────────────────────────

  /// _addFrictionStep() adds a new blank friction barrier input field,
  /// up to a maximum of 5 fields.
  ///
  /// It is called when the user taps the "Add" button in the Friction Barriers
  /// row. It does nothing if there are already 5 steps.
  void _addFrictionStep() {
    // Guard: only allow up to 5 friction steps.
    if (_frictionCtrls.length < 5) {
      // setState() is the Flutter mechanism for signalling that local state has
      // changed and the widget should redraw. The function passed to setState
      // is where you mutate the state. Flutter will call build() again after.
      setState(() => _frictionCtrls.add(TextEditingController()));
      // ^ Adds a fresh TextEditingController to the list. The spread operator
      //   (...) in build() will automatically create a new TextField for it.
    }
  }

  /// _save() validates and persists the form data, then closes the sheet.
  ///
  /// Side effects:
  ///   - Calls neuroProvider.notifier.addNeuroSwap() to add the swap to
  ///     global app state (which triggers UI rebuilds elsewhere in the app).
  ///   - Calls Navigator.pop(context) to dismiss (close) this bottom sheet.
  void _save() {
    // Validation: if the habit title is blank (after stripping whitespace),
    // do nothing and return early. .trim() removes leading/trailing spaces.
    if (_titleCtrl.text.trim().isEmpty) return;

    // ref.read() accesses a Riverpod provider *without* subscribing to it.
    // Use ref.read() inside event handlers (button presses) when you just
    // want to call a method — you don't need to rebuild when the value changes.
    //
    // neuroProvider.notifier gives us the NeuroNotifier class (defined in
    // neuro_provider.dart) so we can call mutation methods like addNeuroSwap().
    ref.read(neuroProvider.notifier).addNeuroSwap(
      title: _titleCtrl.text.trim(),           // The name of the bad habit.
      cue: _cueCtrl.text.trim(),               // The trigger/cue text.
      badResponse: _badCtrl.text.trim(),        // The old unwanted response.
      interceptAction: _interceptCtrl.text.trim(), // The replacement action.
      frictionLevel: _frictionLevel,           // The slider value (1–5).

      // Build a clean list of friction step strings:
      //   .map((c) => c.text.trim())  — convert each controller to its trimmed text string
      //   .where((s) => s.isNotEmpty) — filter out any blank strings (skipped steps)
      //   .toList()                   — convert the lazy iterable back to a concrete List
      frictionSteps: _frictionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
    );

    // Navigator.pop() closes the current route (this bottom sheet) and returns
    // to whatever was underneath it. `context` is the BuildContext that
    // identifies where in the widget tree this widget lives.
    Navigator.pop(context);
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  /// build() is called by Flutter every time this widget needs to draw itself.
  /// It returns a tree of widgets that describe what should appear on screen.
  ///
  /// Parameters:
  ///   [context] — A BuildContext that gives access to the widget tree,
  ///   theme data, navigator, etc. Think of it as "where am I in the app?".
  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet creates a bottom panel the user can drag up/down.
    // It is typically used as the direct child of showModalBottomSheet().
    return DraggableScrollableSheet(
      initialChildSize: 0.9,  // Starts at 90% of screen height when opened.
      maxChildSize: 0.95,     // Can be dragged up to 95% of screen height.
      minChildSize: 0.5,      // Can be dragged down to 50% of screen height.
      expand: false, // false = the sheet does not automatically fill all space;
                     // it respects the sizes above instead.

      // builder provides a ScrollController that the inner scrollable widget
      // must use so that dragging the sheet and scrolling its content work
      // together without conflicting. `context` here shadows the outer context
      // but refers to the same widget position.
      builder: (context, controller) => Container(
        // BoxDecoration lets us style the container beyond what a plain
        // Container can do — here we set background colour and rounded top corners.
        decoration: BoxDecoration(
          color: context.bgColor, // Extension method from app_theme.dart — returns
                                  // the correct background colour for light/dark mode.
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20), // Round ONLY the top-left and top-right corners
                                      // (vertical means top/bottom, but we only set top).
          ),
        ),
        child: Column(
          // Column stacks its children vertically from top to bottom.
          children: [
            const SizedBox(height: 12), // Invisible spacer widget — 12 logical pixels tall.

            // The small grey "drag handle" pill at the top of the sheet.
            // It is purely decorative — a visual hint that the sheet is draggable.
            Container(
              width: 40,   // 40 logical pixels wide.
              height: 4,   // 4 logical pixels tall — a thin pill shape.
              decoration: BoxDecoration(
                color: context.borderColor, // Subtle colour from theme extension.
                borderRadius: BorderRadius.circular(2), // Fully rounded ends.
              ),
            ),

            const SizedBox(height: 16), // Spacer below the drag handle.

            // Sheet title text, horizontally padded.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24), // 24px left & right.
              child: Text(
                'Add Neuro Swap',
                // Theme.of(context) retrieves the active ThemeData for this app.
                // .textTheme.titleMedium is a predefined text style for medium-sized titles.
                // ?.copyWith(...) — the ?. is Dart's null-safe access: if titleMedium is
                // null, the whole expression evaluates to null rather than throwing.
                // copyWith() returns a copy of the style with only the specified fields changed.
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8), // Small spacer below the title.

            // Expanded makes this child fill all remaining vertical space in the Column.
            // Without Expanded, the scrollable area would have no defined height and crash.
            Expanded(
              child: SingleChildScrollView(
                // Pass the DraggableScrollableSheet's controller here so Flutter
                // knows to hand off scroll events to the sheet when the list
                // is scrolled to the top (enabling the drag-to-dismiss gesture).
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24), // Side padding for all content.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left edge.
                  children: [

                    // ── Text input fields ────────────────────────────────────
                    // _Field is a private helper widget (defined below) that
                    // wraps a label + TextField into a reusable component.

                    // Field for the habit's display name.
                    _Field(label: 'Bad Habit Name', controller: _titleCtrl, hint: 'e.g. Mindless Phone Checking'),

                    // Field for describing the trigger that starts the habit loop.
                    _Field(label: 'Trigger / Cue', controller: _cueCtrl, hint: 'When I feel...'),

                    // Field for describing what the user currently does (the bad response).
                    _Field(label: 'Old Response', controller: _badCtrl, hint: 'I reach for my phone...'),

                    // Field for the replacement behaviour the user wants to adopt.
                    _Field(label: 'Intercept Action', controller: _interceptCtrl, hint: 'Instead I will...'),

                    const SizedBox(height: 16),

                    // ── Friction Level Slider ────────────────────────────────
                    // Displays the current friction level number next to the label.
                    // String interpolation: '$_frictionLevel' embeds the variable
                    // value directly inside the string.
                    Text('Friction Level: $_frictionLevel/5', style: Theme.of(context).textTheme.labelLarge),

                    // Slider widget — a draggable thumb on a horizontal track.
                    Slider(
                      value: _frictionLevel.toDouble(), // Slider works with doubles, so convert int → double.
                      min: 1,        // Minimum selectable value.
                      max: 5,        // Maximum selectable value.
                      divisions: 4,  // Snap to 4 evenly spaced positions: 1, 2, 3, 4, 5.
                      // onChanged fires every time the user moves the thumb.
                      // `v` is the new double value. We call setState() so the
                      // label above re-renders with the updated number.
                      onChanged: (v) => setState(() => _frictionLevel = v.round()),
                      // ^ .round() converts the double back to the nearest int.
                    ),

                    const SizedBox(height: 8),

                    // ── Friction Barriers header row ─────────────────────────
                    Row(
                      // Row lays out its children horizontally.
                      children: [
                        Text('Friction Barriers', style: Theme.of(context).textTheme.labelLarge),

                        // Spacer() expands to fill all available horizontal space,
                        // pushing the button to the far right of the Row.
                        const Spacer(),

                        // TextButton.icon is a flat button with both an icon and a text label.
                        TextButton.icon(
                          onPressed: _addFrictionStep, // Call our method when tapped.
                          icon: const Icon(Icons.add, size: 14), // Small "+" icon.
                          label: const Text('Add'),
                        ),
                      ],
                    ),

                    // ── Dynamic friction step text fields ────────────────────
                    // The spread operator `...` expands an iterable inline into
                    // the surrounding list. Here it inserts one Padding widget
                    // per friction step directly into the Column's children list.
                    //
                    // .asMap() converts the List to a Map<int, T> so we get both
                    //   the index (e.key) and the controller (e.value) in each entry.
                    // .entries gives us an Iterable of MapEntry objects.
                    // .map((e) => ...) transforms each entry into a Padding widget.
                    ..._frictionCtrls.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8), // Space below each field.
                      child: TextField(
                        controller: e.value, // e.value is the TextEditingController for this step.
                        decoration: InputDecoration(
                          hintText: 'Friction step ${e.key + 1}...', // e.key is 0-based index; +1 for display.
                          prefixText: '${e.key + 1}. ',              // Shows "1. ", "2. " etc. before the input.
                          isDense: true, // Reduces vertical padding inside the field for a more compact look.
                        ),
                      ),
                    )),

                    const SizedBox(height: 24),

                    // ── Save button ──────────────────────────────────────────
                    // SizedBox with width: double.infinity makes the button
                    // stretch to fill the full available width.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save, // Call _save() when the button is tapped.
                        child: const Text('Add Swap'),
                      ),
                    ),

                    const SizedBox(height: 32), // Bottom breathing room above the sheet edge.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// _Field is a private, reusable helper widget that renders a labelled text input.
///
/// It extends [StatelessWidget] — the simpler Flutter base class for widgets
/// that have NO mutable state of their own. Everything it needs is passed in
/// via constructor parameters (label, controller, hint). Use StatelessWidget
/// when the widget just displays data and does not need to remember anything.
///
/// The underscore prefix makes _Field private to this file. It is only used
/// inside AddSwapSheet and should not be imported elsewhere.
class _Field extends StatelessWidget {

  /// The text shown above the input box (e.g. "Bad Habit Name").
  final String label;

  /// The TextEditingController provided by the parent (_AddSwapSheetState).
  /// This is how the parent reads whatever the user typed into this field.
  /// `final` means this reference cannot be swapped for a different controller
  /// after the widget is created.
  final TextEditingController controller;

  /// Placeholder text shown inside the input box when it is empty.
  final String hint;

  /// Constructor — `required` means the caller MUST provide these arguments;
  /// omitting any of them is a compile-time error.
  const _Field({required this.label, required this.controller, required this.hint});

  /// build() describes the UI structure for this widget.
  ///
  /// Returns a [Column] containing a spacing gap, a label text, another gap,
  /// and a [TextField] input box.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align label text to the left.
      children: [
        const SizedBox(height: 16), // Vertical spacing above each field group.

        // Label text styled with the app's labelLarge theme style.
        Text(label, style: Theme.of(context).textTheme.labelLarge),

        const SizedBox(height: 6), // Small gap between label and input box.

        // TextField is the standard Flutter single-line text input widget.
        // `controller` links it to the parent's TextEditingController so the
        // parent can read the typed value at any time.
        // InputDecoration.hintText shows greyed-out placeholder text.
        TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
