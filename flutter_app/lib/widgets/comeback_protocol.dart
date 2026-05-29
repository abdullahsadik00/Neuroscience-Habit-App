// =============================================================================
// File: comeback_protocol.dart
//
// What this file is:
//   This file defines the UI widgets that display the "Comeback Protocol" —
//   a neuroscience-informed re-entry plan shown to users when they have missed
//   one or more habit stacks (groups of habits) for one or more days.
//
// Role in app architecture:
//   - This is a "presentational widget" file — its only job is to display data
//     and forward user actions to the state layer.
//   - It reads habit data from `neuro_provider.dart` (the central state store)
//     via Riverpod, and calls `acknowledgeComeback()` on that provider when
//     the user presses a button.
//   - It uses helper functions from `comeback_helpers.dart` to compute how many
//     days were missed and to generate motivational messages and micro-actions.
//   - It is rendered inside the main habit dashboard screen, conditionally
//     whenever the user has missed stacks.
//
// Key concepts to understand this file:
//   1. Widgets — In Flutter, everything on screen is a "widget". Widgets are
//      Dart classes that describe how a piece of UI should look.
//   2. ConsumerWidget — A special widget from the Riverpod library that can
//      "watch" (subscribe to) providers. When provider state changes, only
//      widgets that watch that provider rebuild — efficient and targeted.
//   3. Riverpod — The state management library used in this app. It separates
//      app data (state) from UI, so widgets stay simple.
//   4. build() method — Flutter calls this method whenever it needs to draw
//      (or redraw) the widget. You return a widget tree describing what to show.
//   5. Spread operator (...) — Dart's `...list` syntax "spreads" a list of
//      widgets inline into another list, so you can dynamically add children.
// =============================================================================

// Brings in Flutter's core UI toolkit — widgets like Container, Row, Column,
// Text, Icon, ElevatedButton, OutlinedButton, etc. live here.
import 'package:flutter/material.dart';

// flutter_animate provides chainable animation helpers (.animate(), .fadeIn(),
// .slideY(), etc.) that let us animate any widget with minimal boilerplate.
import 'package:flutter_animate/flutter_animate.dart';

// flutter_riverpod is the state-management library. We need ConsumerWidget
// and WidgetRef so our widgets can read and react to app-wide state.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Our own data models — specifically NeuroStack, which represents a named
// group of habits (a "stack") the user has configured.
import '../models/models.dart';

// The central Riverpod provider for all neuroscience/habit state in the app.
// We use it to call `acknowledgeComeback()` when the user taps a button.
import '../providers/neuro_provider.dart';

// Pure helper functions for the comeback feature:
//   getDaysMissed(stack) — calculates how many days a stack was skipped.
//   getComebackMessage(daysMissed) — returns a motivational headline + body.
//   generateMicroActions(stack) — returns a list of small re-entry action strings.
import '../utils/comeback_helpers.dart';

// Our app's design tokens (colours, text styles, border colours, etc.)
// exposed as Dart extension getters on BuildContext, e.g. `context.cardBg`.
import '../theme/app_theme.dart';

// -----------------------------------------------------------------------------
// ComebackProtocolBanner
// -----------------------------------------------------------------------------

/// The top-level banner widget for the Comeback Protocol feature.
///
/// This widget receives the list of habit stacks the user has missed and
/// renders a styled amber-coloured panel. If there are no missed stacks
/// it renders nothing (an invisible zero-size box).
///
/// Extends [ConsumerWidget] (from Riverpod) rather than plain [StatelessWidget]
/// because its child widgets need access to `ref` (the Riverpod reference
/// object) to call provider methods when buttons are pressed.
///
/// Used in: the main habit dashboard screen, passed the missed stacks list
/// computed from today's schedule vs. the user's completion history.
class ComebackProtocolBanner extends ConsumerWidget {
  /// The list of [NeuroStack] objects the user has not completed recently.
  /// Each stack in this list will produce one [_MissedStackItem] card below.
  final List<NeuroStack> missedStacks;

  /// Constructor — `super.key` passes Flutter's internal widget identity key
  /// up to the parent class so Flutter can efficiently reconcile widget trees.
  /// `required this.missedStacks` means the caller MUST provide this list.
  const ComebackProtocolBanner({super.key, required this.missedStacks});

  /// Flutter calls build() to get the visual representation of this widget.
  ///
  /// Parameters:
  ///   [context] — Gives access to theme data, screen size, and other
  ///               inherited information from the widget tree above us.
  ///   [ref]     — The Riverpod "reference". Lets us watch/read providers.
  ///               We receive this because we extend ConsumerWidget.
  ///
  /// Returns: a [Widget] describing the UI to render.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Early-return guard: if no stacks were missed, render an invisible,
    // zero-size widget so this banner takes up no space at all.
    // SizedBox.shrink() is the Flutter idiom for "render nothing".
    if (missedStacks.isEmpty) return const SizedBox.shrink();

    // Container is a general-purpose box widget. We use it here to apply
    // padding (inner spacing), a background colour, rounded corners, and
    // a border around the whole banner.
    return Container(
      // EdgeInsets.all(16) adds 16 logical pixels of padding on ALL four sides
      // (top, right, bottom, left) inside the container.
      padding: const EdgeInsets.all(16),

      // BoxDecoration lets us style the container's background and border.
      decoration: BoxDecoration(
        // Amber colour (#F59E0B in hex) at 10% opacity — a subtle tint.
        // withOpacity() takes a value 0.0 (invisible) to 1.0 (fully opaque).
        color: const Color(0xFFF59E0B).withOpacity(0.1),

        // BorderRadius.circular(16) rounds ALL four corners to a 16px radius,
        // giving the card a pill-like softness.
        borderRadius: BorderRadius.circular(16),

        // Border.all() draws a uniform border on all sides; we set it to the
        // same amber at 30% opacity so it's visible but not overpowering.
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),

      // Column lays its children out vertically (top to bottom).
      child: Column(
        // CrossAxisAlignment.start aligns children to the LEFT edge of the
        // column (the "cross axis" for a vertical Column is horizontal).
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Header row: back-arrow icon + "Comeback Protocol" label side by side.
          Row(
            children: [
              // A small amber arrow icon serving as a visual anchor for the section.
              const Icon(Icons.arrow_back_ios, color: Color(0xFFF59E0B), size: 16),

              // SizedBox with only a width adds horizontal whitespace between siblings.
              const SizedBox(width: 8),

              // Section title text. We pull the app's pre-set titleSmall style from
              // the theme, then override just the colour and weight with copyWith().
              // The `?.` is Dart's null-safe call — if textTheme.titleSmall is null,
              // the whole expression returns null and Text falls back to defaults.
              Text(
                'Comeback Protocol',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Vertical gap of 12px between the header row and the stack cards below.
          const SizedBox(height: 12),

          // Spread operator (...) — turns a List<Widget> into individual items
          // that are inlined into the parent `children` list.
          //
          // missedStacks.map((stack) => ...) iterates over every missed stack
          // and transforms it into a _MissedStackItem widget. The result is an
          // Iterable<Widget>; the `...` spreads each item into the Column.
          ...missedStacks.map((stack) => _MissedStackItem(stack: stack)),
        ],
      ),

      // .animate() wraps the Container in flutter_animate's animation engine.
      // .fadeIn() plays a fade-from-transparent animation when first shown.
      // .slideY(begin: -0.05) simultaneously slides the widget from 5% above
      // its final position downward — a subtle entrance motion.
    ).animate().fadeIn().slideY(begin: -0.05);
  }
}

// -----------------------------------------------------------------------------
// _MissedStackItem  (private — the leading underscore means it can only be
//                    used inside this file)
// -----------------------------------------------------------------------------

/// A single card representing one missed habit stack inside the banner.
///
/// Displays:
///   - The stack's title and how many days it was missed.
///   - A motivational message (headline + body) scaled to days missed.
///   - A bullet list of small "micro-actions" to ease back in.
///   - Two action buttons: "Just acknowledge" or "Done micro-actions".
///
/// Extends [ConsumerWidget] because it calls `ref.read(neuroProvider.notifier)`
/// when a button is pressed — that requires the Riverpod `ref` object which
/// only ConsumerWidget provides through its build signature.
///
/// Used inside: [ComebackProtocolBanner]'s Column children list.
class _MissedStackItem extends ConsumerWidget {
  /// The [NeuroStack] model this card is visualising.
  /// Contains the stack's id, title, habits, last-completed date, etc.
  final NeuroStack stack;

  /// Constructor. No `key` parameter because this is a private widget that
  /// is never reordered in a list by Flutter's diff algorithm.
  const _MissedStackItem({required this.stack});

  /// Builds the card UI for one missed stack.
  ///
  /// Parameters:
  ///   [context] — Theme and screen context from the widget tree.
  ///   [ref]     — Riverpod reference; used to fire the acknowledgeComeback action.
  ///
  /// Returns: a [Widget] (a styled Container with nested Column content).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate how many calendar days this stack has been missed.
    // getDaysMissed() is a pure helper from comeback_helpers.dart that compares
    // the stack's lastCompletedDate to today's date and returns an int.
    final daysMissed = getDaysMissed(stack);

    // Get the motivational copy based on the streak gap.
    // getComebackMessage() returns an object with `.headline` and `.body` strings
    // — the wording scales with severity (e.g. 1 day vs. 7+ days missed).
    final message = getComebackMessage(daysMissed);

    // Generate a list of short, actionable micro-task strings (e.g. "Do 2 push-ups").
    // These are intentionally tiny so returning feels achievable, not daunting.
    final microActions = generateMicroActions(stack);

    // The outer Container provides the card background, rounded corners, and border.
    return Container(
      // Bottom margin so consecutive cards don't touch each other.
      margin: const EdgeInsets.only(bottom: 12),

      // Inner padding so content doesn't butt up against the card edges.
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        // context.cardBg is a custom getter defined in app_theme.dart that
        // returns the correct card background colour for the current theme
        // (light or dark mode). Extension getters on BuildContext are a
        // Flutter pattern to avoid passing theme objects around manually.
        color: context.cardBg,

        // Slightly rounder corners (12px) than the outer banner (16px).
        borderRadius: BorderRadius.circular(12),

        // context.borderColor is another theme token — the appropriate subtle
        // border colour for the active theme.
        border: Border.all(color: context.borderColor),
      ),

      // Column lays all card content vertically.
      child: Column(
        // Start-align all text to the left.
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Stack title in bold titleSmall style.
          Text(
            stack.title, // e.g. "Morning Focus Stack"
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          // Small vertical gap before the "days missed" badge.
          const SizedBox(height: 4),

          // Shows how many days were missed in amber to signal urgency.
          // String interpolation: `${daysMissed}d missed` inserts the int
          // variable's value into the string at runtime.
          Text(
            '${daysMissed}d missed',
            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
          ),

          const SizedBox(height: 8),

          // Motivational headline — slightly heavier weight to stand out.
          Text(
            message.headline,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),

          const SizedBox(height: 4),

          // Supporting body copy in the secondary text colour (lower contrast).
          // context.textSecondary is a theme extension getter from app_theme.dart.
          Text(
            message.body,
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),

          const SizedBox(height: 12),

          // Label for the micro-actions bullet list.
          Text(
            'Re-entry actions:',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // Spread all micro-action strings as bullet-point rows.
          // microActions is a List<String>; .map() converts each string `a`
          // into a Padding widget containing a Row with a bullet + text.
          ...microActions.map((a) => Padding(
            // Bottom padding separates consecutive bullet items.
            padding: const EdgeInsets.only(bottom: 4),

            child: Row(
              // CrossAxisAlignment.start aligns the bullet to the top of the
              // text even when the text wraps to multiple lines.
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // A tiny filled circle (5px) acting as a bullet point.
                const Icon(Icons.circle, size: 5, color: Color(0xFFF59E0B)),

                // 8px gap between bullet and text.
                const SizedBox(width: 8),

                // Expanded makes the Text take all remaining horizontal space,
                // allowing it to wrap onto the next line without overflowing.
                Expanded(
                  child: Text(
                    a, // the micro-action string, e.g. "Do 5 minutes of the habit"
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 12),

          // Action buttons row — two buttons side-by-side, each taking half the width.
          Row(
            children: [
              // Expanded makes this button fill exactly half the available row width.
              Expanded(
                child: OutlinedButton(
                  // onPressed callback — called when the user taps this button.
                  // We use an anonymous function `() { ... }` (a "closure") here.
                  onPressed: () {
                    // ref.read() fetches the current value of a provider ONCE
                    // without subscribing (no rebuild). We use it here because
                    // we just want to call a method, not watch for changes.
                    //
                    // neuroProvider.notifier gives us the NeuroNotifier class
                    // (the business-logic object), not the state snapshot.
                    //
                    // acknowledgeComeback() records that the user saw the
                    // comeback prompt but did NOT complete micro-actions.
                    ref.read(neuroProvider.notifier).acknowledgeComeback(
                      stack.id,    // which stack is being acknowledged
                      stack.title, // human-readable name, used in logging/events
                      microActionsCompleted: false, // user skipped the micro-tasks
                    );
                  },

                  // OutlinedButton.styleFrom() creates a ButtonStyle from simple
                  // named parameters — easier than constructing ButtonStyle manually.
                  style: OutlinedButton.styleFrom(
                    // side sets the visible border stroke colour and width.
                    side: const BorderSide(color: Color(0xFFF59E0B)),

                    // foregroundColor sets the text (and ripple) colour.
                    foregroundColor: const Color(0xFFF59E0B),

                    // Vertical-only padding to keep the button compact.
                    padding: const EdgeInsets.symmetric(vertical: 10),

                    // Override the default button text size.
                    textStyle: const TextStyle(fontSize: 12),
                  ),

                  // The label shown inside the button.
                  child: const Text('Just acknowledge'),
                ),
              ),

              // 8px gap between the two buttons.
              const SizedBox(width: 8),

              // Second button — filled (ElevatedButton) to indicate the
              // "recommended" / primary action.
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Same provider call, but microActionsCompleted: true —
                    // signals the user actually completed the micro-tasks,
                    // which triggers a larger streak-recovery credit in the state.
                    ref.read(neuroProvider.notifier).acknowledgeComeback(
                      stack.id,
                      stack.title,
                      microActionsCompleted: true, // user completed the micro-tasks
                    );
                  },

                  // ElevatedButton.styleFrom() works like OutlinedButton.styleFrom()
                  // but for filled buttons.
                  style: ElevatedButton.styleFrom(
                    // Solid amber fill to make this the visually dominant action.
                    backgroundColor: const Color(0xFFF59E0B),

                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 12),
                  ),

                  child: const Text('Done micro-actions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
