// =============================================================================
// brain_profile_card.dart
//
// What this file is:
//   A reusable Flutter widget that displays a user's "Brain Profile" — the
//   result of a neuroscience-based onboarding quiz that categorises how a
//   person builds (and breaks) habits.
//
// Role in the app architecture:
//   - Receives a fully-built NeuroBrainProfile object (defined in
//     lib/models/models.dart) and renders it as a card.
//   - Used on the home/dashboard screen wherever the profile summary needs to
//     be shown.
//   - Pure "display" widget: it holds NO state and makes NO network calls.
//     All data comes in from the outside through constructor parameters.
//
// Key concepts a learner needs to understand this file:
//   1. StatelessWidget — a widget that never changes after it is first drawn.
//      Use it when the visual output depends only on the data passed in.
//   2. Named parameters & `required` — Flutter widgets use named parameters
//      (e.g. `required this.profile`) to make call-sites readable.
//   3. Enums — Dart enums are fixed sets of named values (e.g. FailureStyle
//      has four possible values). The `switch` expression maps each enum value
//      to a human-readable string.
//   4. `const` constructors — when every value inside a widget is known at
//      compile time, mark it `const` so Flutter can reuse the same object
//      rather than rebuilding it on every frame (a free performance win).
//   5. Flutter widget tree — UIs are built by nesting widgets inside widgets.
//      Row/Column arrange children horizontally/vertically; Container adds
//      padding, colour, and rounded corners; Text renders a string.
// =============================================================================

// Brings in the core Flutter UI toolkit: Text, Container, Row, Column,
// Icon, TextButton, Spacer, Wrap, BoxDecoration, etc.
import 'package:flutter/material.dart';

// flutter_animate adds the .animate().fadeIn() helper used below — it lets
// any widget smoothly fade in when first rendered, without writing animation
// code manually.
import 'package:flutter_animate/flutter_animate.dart';

// Our own data model file. Provides NeuroBrainProfile and all of its enum
// types (FailureStyle, PeakEnergyWindow, etc.).
import '../models/models.dart';

// Our own theme file. Provides helper extension getters like context.cardBg,
// context.borderColor, and context.textSecondary so colours stay consistent
// across the app without hard-coding hex values everywhere.
import '../theme/app_theme.dart';

/// BrainProfileCard displays a summary card of the user's neuroscience-based
/// habit profile, including their archetype name, failure style badge, and six
/// personality dimensions.
///
/// This is a [StatelessWidget], which means it has no internal state: it simply
/// takes data in through its constructor, renders it, and never mutates itself.
/// Flutter will rebuild this widget only if its parent passes different data.
///
/// Typical usage (inside a parent widget's build method):
/// ```dart
/// BrainProfileCard(
///   profile: myProfile,
///   onRetake: () => Navigator.push(...),
/// )
/// ```
class BrainProfileCard extends StatelessWidget {
  /// The full brain-profile object to display.
  /// Every visual element on the card (archetype name, dimension chips, etc.)
  /// is derived from the data stored in this object.
  final NeuroBrainProfile profile;

  /// A callback that fires when the user taps the "Retake" button.
  /// `VoidCallback` is a Dart typedef meaning "a function that takes no
  /// arguments and returns nothing": `void Function()`.
  /// The parent widget decides what actually happens (e.g. navigate to the
  /// quiz screen).
  final VoidCallback onRetake;

  /// The `const` constructor lets Flutter reuse this widget object across
  /// redraws when neither `profile` nor `onRetake` have changed.
  ///
  /// `super.key` passes the optional `key` parameter up to [StatelessWidget].
  /// Keys help Flutter identify and match widgets across rebuilds — mostly
  /// important in lists. Beginners can ignore keys initially.
  ///
  /// `required` means the caller MUST supply these arguments; omitting them
  /// is a compile-time error.
  const BrainProfileCard({super.key, required this.profile, required this.onRetake});

  // ---------------------------------------------------------------------------
  // STATIC HELPER METHODS
  //
  // These are `static` because they do not need access to `this` (the widget
  // instance). They are pure functions: given the same input they always return
  // the same output. Marking them static also makes it clear they hold no state.
  // ---------------------------------------------------------------------------

  /// Returns a human-readable archetype name by combining the user's
  /// [FailureStyle] and [CoreDriver] into a single key, then looking that key
  /// up in a predefined map.
  ///
  /// There are 4 failure styles × 4 core drivers = 16 possible archetypes.
  ///
  /// Parameters:
  ///   [p] — the full NeuroBrainProfile to read from.
  ///
  /// Returns a [String] such as "The Exhausted Achiever".
  static String _archetypeName(NeuroBrainProfile p) {
    // `.name` is a built-in Dart property on every enum value that returns its
    // identifier as a lowercase String. e.g. FailureStyle.perfectionist.name
    // evaluates to the String 'perfectionist'.
    final fs = p.failureStyle.name; // e.g. 'perfectionist'
    final cd = p.coreDriver.name;   // e.g. 'feelBetter'

    // A `const` Map literal — because all keys and values are compile-time
    // constants, Dart can build this map once and reuse it forever.
    // Map<String, String> maps a composite key like 'perfectionist-feelBetter'
    // to an archetype display name.
    const names = {
      'perfectionist-feelBetter': 'The Exhausted Achiever',
      'perfectionist-performBetter': 'The Precision Driver',
      'perfectionist-becomeSomeone': 'The Identity Builder',
      'perfectionist-survive': 'The Cornered Perfectionist',
      'avoider-feelBetter': 'The Comfort Seeker',
      'avoider-performBetter': 'The Quiet Competitor',
      'avoider-becomeSomeone': 'The Reluctant Transformer',
      'avoider-survive': 'The Minimal Risk-Taker',
      'analyst-feelBetter': 'The Thoughtful Healer',
      'analyst-performBetter': 'The Systems Optimizer',
      'analyst-becomeSomeone': 'The Deliberate Builder',
      'analyst-survive': 'The Calculated Survivor',
      'drifter-feelBetter': 'The Restless Dreamer',
      'drifter-performBetter': 'The Inconsistent Sprinter',
      'drifter-becomeSomeone': 'The Aspiring Self',
      'drifter-survive': 'The Day-to-Day Navigator',
    };

    // String interpolation: '$fs-$cd' builds a composite key at runtime,
    // e.g. 'analyst-survive'. We look it up in the map.
    // The `??` operator is the "null-coalescing" operator: if the map returns
    // null (key not found), use the fallback string on the right instead.
    return names['$fs-$cd'] ?? 'The Recovery Builder';
  }

  /// Converts a [FailureStyle] enum value into a display-friendly label.
  ///
  /// Uses a Dart *switch expression* (introduced in Dart 3). Unlike a
  /// traditional switch statement, a switch expression returns a value and
  /// every case must be handled (the compiler enforces exhaustiveness).
  ///
  /// Parameters:
  ///   [s] — the FailureStyle enum value to convert.
  ///
  /// Returns a capitalised [String] for display in the UI.
  static String _failureLabel(FailureStyle s) {
    return switch (s) {
      FailureStyle.perfectionist => 'Perfectionist', // User fails by aiming too high
      FailureStyle.avoider       => 'Avoider',        // User fails by avoiding discomfort
      FailureStyle.analyst       => 'Analyst',         // User fails by over-thinking
      FailureStyle.drifter       => 'Drifter',         // User fails by losing momentum
    };
  }

  /// Converts a [PeakEnergyWindow] enum value into a display label.
  ///
  /// Parameters:
  ///   [w] — when during the day the user has the most mental energy.
  ///
  /// Returns a [String] such as 'Morning'.
  static String _energyLabel(PeakEnergyWindow w) {
    return switch (w) {
      PeakEnergyWindow.morning   => 'Morning',   // Best energy before midday
      PeakEnergyWindow.afternoon => 'Afternoon', // Best energy in the middle of the day
      PeakEnergyWindow.evening   => 'Evening',   // Best energy after work hours
      PeakEnergyWindow.variable  => 'Variable',  // Energy fluctuates — no fixed window
    };
  }

  /// Converts a [PrimaryBlocker] enum value into a display label.
  ///
  /// A "blocker" is the main reason this user tends to miss habits.
  ///
  /// Parameters:
  ///   [b] — the primary obstacle the user faces.
  ///
  /// Returns a [String] such as 'Low Energy'.
  static String _blockerLabel(PrimaryBlocker b) {
    return switch (b) {
      PrimaryBlocker.energy      => 'Low Energy',  // User runs out of physical/mental fuel
      PrimaryBlocker.overwhelm   => 'Overwhelm',   // User is blocked by too many tasks
      PrimaryBlocker.distraction => 'Distraction', // User gets pulled away by other things
      PrimaryBlocker.life        => 'Life Events', // Unexpected events derail the user
    };
  }

  /// Converts a [RecoverySpeed] enum value into a display label.
  ///
  /// Recovery speed measures how quickly the user bounces back after missing
  /// several days of a habit.
  ///
  /// Parameters:
  ///   [s] — the user's typical recovery speed.
  ///
  /// Returns a [String] such as 'Fast'.
  static String _recoveryLabel(RecoverySpeed s) {
    return switch (s) {
      RecoverySpeed.fast     => 'Fast',     // Gets back on track within a day or two
      RecoverySpeed.medium   => 'Medium',   // Takes about a week to rebuild momentum
      RecoverySpeed.slow     => 'Slow',     // May take weeks to restart
      RecoverySpeed.variable => 'Variable', // Recovery time depends heavily on context
    };
  }

  /// Converts a [MotivationSource] enum value into a display label.
  ///
  /// What psychologically drives this user to stick with habits.
  ///
  /// Parameters:
  ///   [m] — the user's primary motivation source.
  ///
  /// Returns a [String] such as 'Identity'.
  static String _motivationLabel(MotivationSource m) {
    return switch (m) {
      MotivationSource.identity => 'Identity', // Motivated by "who I want to be"
      MotivationSource.outcome  => 'Outcome',  // Motivated by measurable end results
      MotivationSource.process  => 'Process',  // Motivated by enjoying the daily routine itself
      MotivationSource.survival => 'Survival', // Motivated by avoiding negative consequences
    };
  }

  /// Converts a [CoreDriver] enum value into a display label.
  ///
  /// The core driver is the deeper goal behind building habits at all.
  ///
  /// Parameters:
  ///   [d] — the user's core psychological driver.
  ///
  /// Returns a [String] such as 'Feel Better'.
  static String _driverLabel(CoreDriver d) {
    return switch (d) {
      CoreDriver.feelBetter    => 'Feel Better',    // Building habits to improve mood/wellbeing
      CoreDriver.performBetter => 'Perform Better', // Building habits to boost productivity
      CoreDriver.becomeSomeone => 'Become Someone', // Building habits to grow into a new identity
      CoreDriver.survive       => 'Survive',         // Building habits to cope with hardship
    };
  }

  /// Converts an [AccountabilityStyle] enum value into a display label.
  ///
  /// How the user prefers to hold themselves accountable.
  ///
  /// Parameters:
  ///   [a] — the user's preferred accountability mechanism.
  ///
  /// Returns a [String] such as 'Self-Tracking'.
  static String _accountabilityLabel(AccountabilityStyle a) {
    return switch (a) {
      AccountabilityStyle.tracking => 'Self-Tracking', // Relies on personal logs/streaks
      AccountabilityStyle.external => 'External',       // Relies on another person or coach
      AccountabilityStyle.systems  => 'Systems',         // Relies on automated reminders/tools
      AccountabilityStyle.none     => 'None',             // No accountability preference
    };
  }

  // ---------------------------------------------------------------------------
  // build() — The heart of every Flutter widget.
  //
  // Flutter calls build() whenever it needs to draw (or redraw) this widget.
  // It must return a widget tree. For a StatelessWidget it is called once per
  // parent rebuild; there is no internal state that could trigger an extra call.
  // ---------------------------------------------------------------------------

  /// Constructs the widget tree for the brain profile card.
  ///
  /// Parameters:
  ///   [context] — a [BuildContext] that carries information about where in the
  ///   widget tree this widget lives. It is used to access the app theme
  ///   (colours, text styles) and custom extension getters from app_theme.dart.
  ///
  /// Returns the root [Widget] of the visual hierarchy.
  @override
  Widget build(BuildContext context) {
    // Compute derived display strings once, up here, to keep the widget tree
    // below readable. These are plain local variables — they do not affect
    // state or trigger rebuilds.
    final archetype = _archetypeName(profile);         // e.g. "The Exhausted Achiever"
    final failureLabel = _failureLabel(profile.failureStyle); // e.g. "Perfectionist"

    // Container is Flutter's all-purpose layout box. It wraps a single child
    // widget and lets you control size, padding, margin, colour, border,
    // and border-radius around it.
    return Container(
      padding: const EdgeInsets.all(16), // 16 logical pixels of space on all sides
      decoration: BoxDecoration(
        color: context.cardBg, // Background colour pulled from our app theme extension
        borderRadius: BorderRadius.circular(16), // Rounds all four corners by 16 px
        // Draws a 1-pixel border around the card.
        // withOpacity(0.4) makes the indigo colour 40% opaque (semi-transparent).
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
      ),

      // Column stacks its children vertically, top to bottom.
      child: Column(
        // Aligns children to the LEFT edge of the column (instead of centring).
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ---- Header row: icon + title + "Retake" button ----
          // Row lays out its children horizontally, left to right.
          Row(
            children: [
              // psychology icon from the Material icon font (brain silhouette).
              // size: 20 is logical pixels (device-independent, so it looks
              // the same size on different screen densities).
              const Icon(Icons.psychology, color: Color(0xFF6366F1), size: 20),

              // SizedBox with only a width creates a horizontal gap between widgets.
              const SizedBox(width: 8),

              // Theme.of(context) retrieves the app-wide ThemeData object.
              // .textTheme.titleSmall gives us a pre-defined small title TextStyle.
              // ?.copyWith(...) — the `?.` is the null-safe call operator; if
              // textTheme.titleSmall is null we skip copyWith instead of crashing.
              // copyWith() creates a *copy* of the style with only certain fields
              // overridden (here we only make the font bold).
              Text('Your Brain Profile', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),

              // Spacer() expands to fill ALL remaining horizontal space,
              // pushing everything after it to the far right of the Row.
              const Spacer(),

              // TextButton — a flat button with no background or border.
              // onPressed receives our VoidCallback so tapping delegates back
              // to the parent widget that created this card.
              TextButton(
                onPressed: onRetake, // Calls the function the parent passed in
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Tighter padding than the default
                  minimumSize: Size.zero, // Allow the button to shrink to fit its label
                  // shrinkWrap reduces the invisible tap-target to match the
                  // visible button size (default Material tap targets are larger
                  // for accessibility; we override here for compact layout).
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Retake', style: TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
              ),
            ],
          ),

          // Vertical gap between the header row and the archetype name text.
          const SizedBox(height: 12),

          // ---- Archetype name (e.g. "The Exhausted Achiever") ----
          // .animate() is provided by the flutter_animate package.
          // .fadeIn() causes the widget to fade from transparent to fully visible
          // when it first appears, giving a polished entrance animation.
          Text(
            archetype, // The computed archetype string from _archetypeName()
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF6366F1), // Indigo colour to make the name stand out
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(), // Chain the fade-in animation onto this Text widget

          const SizedBox(height: 6), // Small gap before the badge

          // ---- Failure style badge (e.g. "Failure style: Perfectionist") ----
          // A pill-shaped badge built with a Container that has rounded corners
          // and a translucent red background.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Padding inside the badge
            decoration: BoxDecoration(
              // withOpacity(0.12) = 12% opacity, giving a very light red tint.
              color: const Color(0xFFEF4444).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20), // High radius = pill / capsule shape
            ),
            // String interpolation: '$failureLabel' inserts the variable value
            // directly into the string at runtime.
            child: Text(
              'Failure style: $failureLabel',
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 14), // Gap before the dimension chips

          // ---- Six personality dimension chips ----
          // Wrap is like Row, but when children run out of horizontal space it
          // automatically wraps onto the next line (like words in a paragraph).
          // This is better than Row here because the screen might be too narrow
          // to fit all six chips on one line.
          Wrap(
            spacing: 8,    // Horizontal gap between chips on the same line
            runSpacing: 8, // Vertical gap between lines of chips
            children: [
              // Each _Dimension widget renders a small labelled chip.
              // The static helper methods convert enum values to readable strings.
              _Dimension(label: 'Peak Energy',    value: _energyLabel(profile.peakEnergyWindow)),
              _Dimension(label: 'Recovery',        value: _recoveryLabel(profile.recoverySpeed)),
              _Dimension(label: 'Blocker',         value: _blockerLabel(profile.primaryBlocker)),
              _Dimension(label: 'Motivation',      value: _motivationLabel(profile.motivationSource)),
              _Dimension(label: 'Core Driver',     value: _driverLabel(profile.coreDriver)),
              _Dimension(label: 'Accountability',  value: _accountabilityLabel(profile.accountabilityStyle)),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _Dimension — private helper widget for rendering a single profile chip
//
// The leading underscore (_) in Dart makes this class library-private: it is
// only visible within this file. This is intentional — _Dimension is a
// small implementation detail of BrainProfileCard, not a public API.
// =============================================================================

/// A small two-line chip widget that shows a dimension label (e.g. "Recovery")
/// above a dimension value (e.g. "Fast").
///
/// Extends [StatelessWidget] because it has no state: it just renders the two
/// strings it receives.
///
/// Only used inside [BrainProfileCard]'s Wrap — not exported for use elsewhere.
class _Dimension extends StatelessWidget {
  /// The short category label shown in smaller text above the value.
  /// Example: 'Peak Energy'
  final String label;

  /// The human-readable value shown in larger, bolder text below the label.
  /// Example: 'Morning'
  final String value;

  /// Constructor. Neither field has a default, so both are `required`.
  /// No `const` on `super.key` here because the parent does not pass keys
  /// to these private chips (they are not in a dynamic list that Flutter needs
  /// to track individually).
  const _Dimension({required this.label, required this.value});

  /// Renders the chip as a small rounded rectangle containing a Column of
  /// two Text widgets (label on top, value below).
  ///
  /// Parameters:
  ///   [context] — provides access to theme colours via the app_theme extension.
  @override
  Widget build(BuildContext context) {
    // Container wraps the chip and gives it background colour and rounded corners.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Inner breathing room
      decoration: BoxDecoration(
        // context.borderColor is a custom getter from app_theme.dart that
        // returns the appropriate border colour for the current light/dark mode.
        // withOpacity(0.5) makes it semi-transparent for a subtle background tint.
        color: context.borderColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8), // Slightly rounded corners
      ),

      // Column stacks the label and value vertically.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left-align both text lines
        children: [
          // Category label — small and muted (uses the secondary text colour
          // from our theme, which is typically a grey shade).
          Text(label, style: TextStyle(fontSize: 9, color: context.textSecondary, fontWeight: FontWeight.w500)),

          // Dimension value — slightly larger and bolder to stand out.
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
