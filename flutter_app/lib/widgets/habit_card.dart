// =============================================================================
// FILE: habit_card.dart
//
// This file defines the HabitCard widget — a single card displayed in the
// habit list that shows all information about one habit (its category, title,
// cue, streak, myelination progress, weekly completion grid, and a button to
// mark it done today).
//
// ROLE IN APP ARCHITECTURE:
//   - This is a "leaf" UI widget: it receives data from its parent (the screen)
//     and fires callbacks back up when the user taps "Complete" or "Archive".
//   - It does NOT manage its own state (no setState, no Riverpod providers here).
//     The parent screen owns the data and passes it down as constructor arguments.
//   - It calls into `stats_helpers.dart` to compute the weekly grid data, and
//     renders a child widget `WeeklyGrid` (from weekly_grid.dart).
//
// KEY CONCEPTS FOR LEARNERS:
//   - StatelessWidget: a widget that shows data but never changes it internally.
//   - "Props-down, events-up" pattern: data flows IN via constructor parameters;
//     user actions flow OUT via VoidCallback functions the parent provides.
//   - Map literals used as lookup tables (const maps for colors and labels).
//   - Conditional rendering with `if (...) ...[]` spread syntax inside widget lists.
//   - RichText / TextSpan for mixed-style text within one paragraph.
//   - showDialog() to pop up an info overlay without navigating to a new screen.
// =============================================================================

// Brings in Flutter's core UI toolkit: widgets, colors, icons, Material Design
// components (Card, ElevatedButton, AlertDialog, etc.). Almost every Flutter
// file needs this import.
import 'package:flutter/material.dart';

// flutter_animate is a third-party package that lets you add entrance/exit
// animations to any widget using a fluent `.animate()` API. It is imported here
// so the card (or children) could be animated in future without new imports.
import 'package:flutter_animate/flutter_animate.dart';

// Our own data model file. Importing this gives us access to the `NeuroStack`
// (a habit), `ComebackRecord`, and `HabitCategory` types defined in models.dart.
import '../models/models.dart';

// Utility functions for computing stats. We use `getWeekGrid()` from here to
// turn a NeuroStack + comeback history into a simple list of booleans (was each
// day of the current week completed?).
import '../utils/neuro_helpers.dart';
import '../utils/stats_helpers.dart';

// The app's central theme file. Brings in named Color constants (focusColor,
// wellnessColor, etc.) and BuildContext extension getters like `context.cardBg`
// and `context.borderColor` that read the current theme's values.
import '../theme/app_theme.dart';

// The WeeklyGrid widget — a small row of 7 colored squares showing which days
// of the current week this habit was completed.
import 'weekly_grid.dart';

/// HabitCard is the main card UI for a single habit.
///
/// It is a [StatelessWidget], which means it has NO internal mutable state of
/// its own. Every time its parent rebuilds and passes new values, this widget
/// re-renders from scratch using those values. Think of it like a pure function:
/// same inputs → same output.
///
/// Usage: the habit list screen creates one HabitCard per habit, passing in the
/// habit data and callback functions for the "Complete" and "Archive" actions.
class HabitCard extends StatelessWidget {
  // -------------------------------------------------------------------------
  // FIELDS (constructor parameters stored on the widget)
  // In Flutter, StatelessWidget fields must be `final` — once set they never
  // change. If you need mutable local state, you would use StatefulWidget instead.
  // -------------------------------------------------------------------------

  /// The habit (NeuroStack) this card represents.
  /// Contains title, category, streak, myelination level, cue, etc.
  final NeuroStack stack;

  /// A list of "comeback" records for this habit — each record marks a day the
  /// user recovered after missing a streak. Used to build the weekly grid and
  /// detect missed-but-recovered days.
  final List<ComebackRecord> comebacks;

  /// Whether the user has already marked this habit complete today.
  /// Controls whether we show the green "Completed Today" badge or the
  /// active "Complete" button.
  final bool completedToday;

  /// A callback function (no arguments, no return value) that the parent
  /// provides. When the user taps "Complete", we call this so the parent can
  /// update its state / persist to storage.
  /// `VoidCallback` is Flutter's shorthand for `void Function()`.
  final VoidCallback onComplete;

  /// A callback function the parent provides. When the user selects "Archive"
  /// from the popup menu, we call this so the parent can move the habit to the
  /// archive list.
  final VoidCallback onArchive;

  /// Optional callback invoked when the user selects "Lite Mode today" from the
  /// overflow menu. When null, the menu item is hidden (e.g., already active or
  /// habit already completed today).
  final VoidCallback? onLiteMode;

  /// The `const` constructor allows Flutter to cache and reuse this widget
  /// instance when its inputs haven't changed, improving performance.
  /// `super.key` forwards the optional `key` parameter to the parent class —
  /// Flutter uses keys internally to match widgets across rebuilds.
  /// `required` means the caller MUST supply this argument; omitting it is a
  /// compile-time error.
  const HabitCard({
    super.key,
    required this.stack,
    required this.comebacks,
    required this.completedToday,
    required this.onComplete,
    required this.onArchive,
    this.onLiteMode,
  });

  // -------------------------------------------------------------------------
  // STATIC LOOKUP TABLES
  // `static` means these belong to the class itself, not to any instance.
  // `const` means they are compile-time constants — Flutter never re-creates them.
  // Using a Map (dictionary) here avoids a long if/else or switch chain when we
  // need to convert a HabitCategory enum value into a Color or a label string.
  // -------------------------------------------------------------------------

  /// Maps each HabitCategory enum value to its brand Color.
  /// `focusColor`, `wellnessColor`, etc. are Color constants from app_theme.dart.
  static const _catColors = {
    HabitCategory.focus: focusColor,       // Blue-ish color for Focus habits
    HabitCategory.wellness: wellnessColor, // Green-ish color for Wellness habits
    HabitCategory.mindset: mindsetColor,   // Purple-ish color for Mindset habits
    HabitCategory.fitness: fitnessColor,   // Orange-ish color for Fitness habits
  };

  /// Maps each HabitCategory enum value to the human-readable label shown in
  /// the category badge pill at the top of the card.
  static const _catLabels = {
    HabitCategory.focus: 'Focus',
    HabitCategory.wellness: 'Wellness',
    HabitCategory.mindset: 'Mindset',
    HabitCategory.fitness: 'Fitness',
  };

  // -------------------------------------------------------------------------
  // METHODS
  // -------------------------------------------------------------------------

  /// Shows a modal dialog explaining the neuroscience behind myelination.
  ///
  /// [context] is the BuildContext — Flutter's handle to where this widget
  /// lives in the widget tree. It is required by `showDialog` so Flutter knows
  /// which Navigator (screen stack) to place the dialog on top of.
  ///
  /// This method has no return value (void). Its side effect is opening an
  /// overlay dialog on screen. The dialog is purely informational — tapping
  /// "Got it" closes it via `Navigator.pop(context)`.
  void _showMyelinationInfo(BuildContext context) {
    // `showDialog` is a Flutter built-in that slides an overlay (AlertDialog)
    // over the current screen without replacing it in the navigation stack.
    showDialog(
      context: context, // tells Flutter which screen to show the dialog on
      // `builder` is a function that returns the widget to display as the dialog.
      // The `_` parameter (BuildContext) is provided by Flutter but we don't need
      // it here, so we name it `_` as a convention meaning "intentionally unused".
      builder: (_) => AlertDialog(
        title: const Text('Neural Pathway Strength'), // dialog heading
        content: Column(
          // `MainAxisSize.min` makes the Column only as tall as its children,
          // rather than stretching to fill the dialog's maximum height.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // left-align all text
          children: const [
            Text(
              'Myelination is the process by which your brain wraps repeated behaviors in a fatty sheath that makes them faster, more automatic, and less effortful.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12), // invisible spacer widget — adds 12 logical pixels of vertical gap
            Text(
              '"How long does habit formation take? Answering this question: a study of automaticity development" — Lally et al. (2010), European Journal of Social Psychology',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic), // italic citation style
            ),
            SizedBox(height: 12),
            Text(
              'The research shows automaticity takes 18–254 days (median ~66). This bar measures your pathway\'s strength based on consistency and streak length.',
              // The backslash before the apostrophe (\') is an escape sequence —
              // it lets us include a literal ' inside a string that is also delimited by '.
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          // TextButton at the bottom of the dialog. Tapping it calls
          // Navigator.pop(context) which removes the top-most route (the dialog)
          // from the navigation stack, effectively closing it.
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  /// The `build` method is the heart of every Flutter widget.
  /// Flutter calls it whenever it needs to (re)draw this widget on screen.
  /// It must return a Widget — the complete UI tree for this card.
  ///
  /// [context] gives access to theme data, screen dimensions, and navigation.
  @override
  Widget build(BuildContext context) {
    // Look up the accent color for this habit's category.
    // `_catColors[stack.category]` returns null if the key is missing (though
    // it shouldn't be). The `??` operator ("null coalescing") provides a fallback:
    // if the left side is null, use the right side (focusColor) instead.
    final color = _catColors[stack.category] ?? focusColor;

    // Look up the display label for this category, defaulting to empty string.
    final label = _catLabels[stack.category] ?? '';

    // Determine if Lite Mode is active for today.
    final today = getLocalDateString(DateTime.now());
    final isLiteModeToday = stack.liteModeDates.contains(today);

    // Call our utility function to compute which days of the current week
    // this habit was completed (returns a List of day-status objects).
    final weekDays = getWeekGrid(stack, comebacks);

    // Check whether an Implementation Intention (II) was set for this habit.
    // An II is a "When X, I will Y" mental plan — backed by psychology research.
    // `stack.whenCondition` is a nullable String (String?) — the `!= null` check
    // tells us it exists, and `isNotEmpty` confirms it's not just whitespace.
    // The `&&` means BOTH conditions must be true.
    final hasII = stack.whenCondition != null && stack.whenCondition!.isNotEmpty;
    // The `!` after `stack.whenCondition` is a "null assertion operator" — it
    // tells Dart "I promise this is not null right now; trust me." Without it,
    // Dart's null-safety system would refuse to call `.isNotEmpty` on a nullable.

    // Container is a general-purpose box widget. Here it is the outer card shell,
    // providing background color, rounded corners, and a border.
    return Container(
      padding: const EdgeInsets.all(16), // 16px of inner spacing on all four sides
      decoration: BoxDecoration(
        color: context.cardBg, // card background from the active theme (light/dark)
        borderRadius: BorderRadius.circular(16), // rounds all four corners by 16px radius
        border: Border.all(color: context.borderColor), // thin 1px border using theme color
      ),
      // Column stacks its children vertically, one on top of the next.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // left-align all children horizontally
        children: [

          // ------------------------------------------------------------------
          // SECTION: HEADER ROW — category badge, streak counter, overflow menu
          // ------------------------------------------------------------------

          // Row lays out its children horizontally (left to right).
          Row(
            children: [
              // Category badge pill (e.g., "Focus", "Wellness")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 8px left/right, 4px top/bottom
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15), // very faint tint of the accent color as background
                  borderRadius: BorderRadius.circular(6), // slightly rounded pill shape
                ),
                child: Text(
                  label, // e.g. "Focus"
                  style: TextStyle(
                    color: color,               // accent color text
                    fontSize: 11,
                    fontWeight: FontWeight.w600, // semi-bold
                  ),
                ),
              ),

              // Lite Mode badge — shown when the user has activated lite mode today.
              if (isLiteModeToday) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Lite Mode',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Spacer pushes everything after it to the far right of the Row,
              // acting like a flexible gap that expands to fill available space.
              const Spacer(),

              // `if (stack.streak > 0) ...[...]` is conditional rendering inside
              // a widget list. The `if` is built into Dart's collection literals.
              // `...` is the spread operator — it "unpacks" the list items into the
              // parent list rather than nesting another list inside.
              // The whole block only renders if there is an active streak.
              if (stack.streak > 0) ...[
                // Fire emoji icon to represent an active streak
                const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 14),
                // `Color(0xFFF59E0B)` — Flutter colors use ARGB hex. 0xFF = fully opaque,
                // F59E0B is the amber/orange hex value. This is equivalent to
                // CSS color #F59E0B but with the opacity byte prepended.
                const SizedBox(width: 4), // tiny horizontal gap between icon and text
                // `'${stack.streak}d'` is string interpolation — `${}` injects the
                // value of `stack.streak` into the string, so e.g. "7d" for a 7-day streak.
                Text('${stack.streak}d', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12), // gap before the overflow menu icon
              ],

              // PopupMenuButton shows a "three-dot" overflow menu when tapped.
              // The generic type <String> means each menu item's value is a String.
              PopupMenuButton<String>(
                iconSize: 18, // size of the three-dot icon
                // `onSelected` is called when the user picks a menu item.
                // `v` is the String `value` of the chosen PopupMenuItem.
                onSelected: (v) {
                  if (v == 'archive') onArchive();
                  if (v == 'liteMode') onLiteMode?.call();
                },
                // `itemBuilder` builds the menu items list dynamically so we can
                // hide the "Lite Mode today" option when it's not applicable.
                itemBuilder: (_) => [
                  // "Lite Mode today" — only shown when:
                  //   - not already in lite mode today
                  //   - not already completed today
                  //   - the onLiteMode callback is wired up
                  if (!isLiteModeToday && !completedToday && onLiteMode != null)
                    const PopupMenuItem(
                      value: 'liteMode',
                      child: Row(
                        children: [
                          Icon(Icons.tune, size: 16, color: Color(0xFF38BDF8)),
                          SizedBox(width: 8),
                          Text('Lite Mode today'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Archive habit'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10), // vertical gap after header row

          // ------------------------------------------------------------------
          // SECTION: TITLE AND ANCHOR CUE
          // ------------------------------------------------------------------

          // Habit title in bold. `Theme.of(context)` reads the current app theme,
          // `.textTheme.titleSmall` picks the "titleSmall" text style defined there,
          // and `?.copyWith(...)` creates a copy of that style with bold weight added.
          // The `?.` is "null-safe method call" — if `titleSmall` were null, this
          // whole expression returns null instead of crashing, and Text treats null
          // style as "use defaults."
          Text(stack.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),

          // Anchor cue subtitle (the environmental trigger for this habit, e.g. "After morning coffee")
          Text(
            stack.anchorCue,
            style: TextStyle(fontSize: 12, color: context.textSecondary), // muted/secondary color from theme
            maxLines: 2,            // cap at 2 lines to keep the card compact
            overflow: TextOverflow.ellipsis, // show "..." if the text is too long to fit
          ),

          // ------------------------------------------------------------------
          // SECTION: IMPLEMENTATION INTENTION PANEL (only shown if one was set)
          // ------------------------------------------------------------------

          // The `if (hasII) ...[]` pattern again — this entire panel is omitted
          // from the widget tree when the user has not set a "When/Then" plan.
          if (hasII) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),       // very subtle tint background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)), // faint accent border
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // align icon to the top of the text block
                children: [
                  Icon(Icons.lightbulb_outline, color: color, size: 14), // small lightbulb icon
                  const SizedBox(width: 8),
                  // Expanded makes this child fill all remaining horizontal space
                  // in the Row — without it the text could overflow the card edge.
                  Expanded(
                    // RichText lets us mix multiple text styles within one paragraph.
                    // It takes a tree of TextSpan objects rather than a plain String.
                    child: RichText(
                      // The root TextSpan sets the default style for all children.
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                        children: [
                          // Bold "When " keyword
                          const TextSpan(text: 'When ', style: TextStyle(fontWeight: FontWeight.bold)),
                          // The user's whenCondition text. `stack.whenCondition!` — the
                          // `!` null assertion is safe here because we already checked
                          // `hasII` is true, which verifies whenCondition is non-null.
                          TextSpan(text: stack.whenCondition!),
                          // Bold ", I will " connector phrase
                          const TextSpan(text: ', I will ', style: TextStyle(fontWeight: FontWeight.bold)),
                          // Prefer the thenAction if set; otherwise fall back to the general action.
                          // The `??` null coalescing operator: if thenAction is null, use stack.action.
                          TextSpan(text: stack.thenAction ?? stack.action),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // SECTION: MYELINATION PROGRESS BAR WITH HELP ICON
          // ------------------------------------------------------------------

          Row(
            children: [
              Text('Neural Pathway', style: TextStyle(fontSize: 11, color: context.textSecondary)),
              const SizedBox(width: 4),
              // GestureDetector wraps any widget to make it tappable. Here it makes
              // the small "?" help icon tap-able to open the info dialog.
              GestureDetector(
                onTap: () => _showMyelinationInfo(context), // open the myelination explainer dialog
                child: Icon(Icons.help_outline, size: 13, color: context.textSecondary),
              ),
              const Spacer(), // push the percentage label to the right
              // `.round()` rounds a double (e.g. 66.7) to the nearest int (67),
              // because myelinationLevel is stored as a double 0–100.
              Text('${stack.myelinationLevel.round()}%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),

          // ClipRRect clips its child to a rounded rectangle shape.
          // Without this wrapper, LinearProgressIndicator's ends would be square.
          ClipRRect(
            borderRadius: BorderRadius.circular(4), // slightly rounded bar ends
            child: LinearProgressIndicator(
              value: stack.myelinationLevel / 100, // LinearProgressIndicator expects a value 0.0–1.0, so divide by 100
              minHeight: 6,                         // 6px tall bar (Flutter default is 4px)
              backgroundColor: color.withOpacity(0.15),         // unfilled portion: faint accent tint
              // AlwaysStoppedAnimation is how you pass a static (non-animating) Color
              // to `valueColor`. Flutter's API expects an Animation<Color> here, but
              // AlwaysStoppedAnimation wraps a plain value to satisfy that requirement.
              valueColor: AlwaysStoppedAnimation<Color>(color), // filled portion: full accent color
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // SECTION: WEEKLY COMPLETION GRID
          // ------------------------------------------------------------------

          // WeeklyGrid is our own widget (weekly_grid.dart). We pass it the
          // computed list of day-status objects so it can draw the 7 colored squares.
          WeeklyGrid(days: weekDays),

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // SECTION: COMPLETE BUTTON (or "Completed Today" badge)
          // ------------------------------------------------------------------

          // SizedBox with `width: double.infinity` forces its child to be as wide
          // as the parent container (full card width). This ensures the button
          // stretches edge-to-edge regardless of its intrinsic size.
          SizedBox(
            width: double.infinity,
            // Ternary operator: `condition ? valueIfTrue : valueIfFalse`
            // If already completed today → show the green "done" badge.
            // If not yet completed → show the active "Complete" button.
            child: completedToday
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15), // faint green tint (Tailwind emerald-500)
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)), // subtle green border
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center, // center the icon + text horizontally
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16), // green checkmark icon
                        SizedBox(width: 8),
                        Text(
                          'Completed Today',
                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onComplete, // fire the parent-supplied callback when tapped
                    icon: const Icon(Icons.check, size: 16), // small checkmark icon inside the button
                    label: Text(isLiteModeToday ? 'Complete Lite Version' : 'Complete'),
                    style: ElevatedButton.styleFrom(
                      // Lite mode uses sky blue instead of the category accent color
                      // to reinforce that this is a downscaled version of the habit.
                      backgroundColor: isLiteModeToday ? const Color(0xFF0284C7) : color,
                      minimumSize: const Size(double.infinity, 40), // full width, 40px tall
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
