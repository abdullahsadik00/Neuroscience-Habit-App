// =============================================================================
// FILE: brain_assessment_page.dart
//
// This file defines the "Brain Assessment" onboarding flow — an 8-question quiz
// that builds a personalized NeuroBrainProfile for the user.
//
// ROLE IN APP ARCHITECTURE:
//   - This page is shown once during onboarding (before the main habit dashboard).
//   - It reads nothing from Riverpod state (no existing data needed) but WRITES
//     to the global neuroProvider once the user completes the quiz.
//   - After writing, the app's router (in main.dart or router.dart) detects that
//     brainProfile is no longer null and automatically navigates to the next screen.
//   - Data models used here (NeuroBrainProfile, FailureStyle, etc.) come from
//     ../models/models.dart.
//
// KEY CONCEPTS A LEARNER NEEDS:
//   1. StatefulWidget vs StatelessWidget — some widgets need to remember and
//      change local data (like "which question are we on?"). StatefulWidget does
//      that. StatelessWidget cannot store mutable state.
//   2. ConsumerStatefulWidget — a Riverpod-enhanced StatefulWidget that also
//      gives access to `ref`, allowing reading/writing global app state.
//   3. setState() — tells Flutter "my local data changed, please redraw the UI".
//   4. Enums — named constants (e.g. FailureStyle.perfectionist) used instead of
//      raw strings to avoid typos and get IDE autocomplete.
//   5. Null safety — Dart requires you to say explicitly whether a variable can
//      be null (Type?) or never null (Type). The `!` operator asserts "I promise
//      this is not null right now."
//   6. Switch expressions — Dart's modern way to return a value based on which
//      enum variant is matched. Used heavily in this file to build labels/text.
// =============================================================================

// Flutter's core UI toolkit — gives us Material Design widgets like Scaffold,
// Column, Text, ElevatedButton, LinearProgressIndicator, etc.
import 'package:flutter/material.dart';

// A third-party package that adds easy animated transitions to any widget
// via the .animate() extension method (e.g. .fadeIn(), .slideX()).
import 'package:flutter_animate/flutter_animate.dart';

// Riverpod — the state management library used throughout this app.
// It provides ConsumerStatefulWidget, ConsumerState, and the `ref` object
// that lets widgets read and write global providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The global Riverpod provider that holds the app's neuroscience data
// (brain profile, habits, streaks, etc.). We write to it after the quiz.
import '../providers/neuro_provider.dart';

// The data model classes — NeuroBrainProfile and all the enum types
// (FailureStyle, PeakEnergyWindow, RecoverySpeed, etc.) live here.
import '../models/models.dart';

// App-wide theming helpers, including extension getters like
// context.textSecondary and context.cardBg that return the right color
// for the current light/dark theme.
import '../theme/app_theme.dart';

// =============================================================================
// BrainAssessmentPage — the PUBLIC entry point widget for this screen
// =============================================================================

/// The top-level widget for the Brain Assessment onboarding quiz.
///
/// Extends [ConsumerStatefulWidget], which is Riverpod's version of Flutter's
/// [StatefulWidget]. This means:
///   - It has mutable LOCAL state (which question we're on, the user's answers).
///   - It also has access to GLOBAL state via `ref` (so it can write the
///     completed profile to the neuroProvider when done).
///
/// This widget is placed on the navigation stack by the app router when the
/// user has not yet completed their brain profile.
class BrainAssessmentPage extends ConsumerStatefulWidget {
  // `const` constructor means Flutter can cache and reuse this widget object
  // when the parent rebuilds, which is a performance optimization.
  // `super.key` passes a unique identifier up to Flutter's widget system so it
  // can efficiently track this widget in the widget tree.
  const BrainAssessmentPage({super.key});

  /// Flutter requires StatefulWidgets to implement createState(), which
  /// returns the companion State object that actually holds the mutable data
  /// and builds the UI. The underscore prefix (_) makes it private to this file.
  @override
  ConsumerState<BrainAssessmentPage> createState() => _BrainAssessmentPageState();
}

// =============================================================================
// _BrainAssessmentPageState — the STATE class that holds all mutable data
// and builds the UI for BrainAssessmentPage
// =============================================================================

/// The State companion to [BrainAssessmentPage].
///
/// In Flutter, a StatefulWidget is split into two classes:
///   1. The widget class (BrainAssessmentPage) — immutable, holds config only.
///   2. The state class (_BrainAssessmentPageState) — mutable, holds data and
///      contains the build() method that draws the UI.
///
/// [ConsumerState] is Riverpod's version of Flutter's [State]. It provides
/// the `ref` object, which is how this state class reads/writes global providers.
class _BrainAssessmentPageState extends ConsumerState<BrainAssessmentPage> {

  // ---------------------------------------------------------------------------
  // LOCAL STATE FIELDS — these track quiz progress within this screen only
  // ---------------------------------------------------------------------------

  /// The index (0-based) of the question currently displayed.
  /// Starts at 0 (first question). Incremented by _next().
  int _step = 0;

  /// Whether to show the "reveal" screen (brain profile summary) instead of
  /// the quiz. Set to true after the user answers all 8 questions.
  bool _showReveal = false;

  // ---------------------------------------------------------------------------
  // ANSWER FIELDS — one per quiz question, nullable because they start unset
  // The `?` after the type means "this can be null". They begin as null and
  // are filled in as the user taps answers.
  // ---------------------------------------------------------------------------

  /// The user's answer to Q1: how they typically fail to follow through.
  FailureStyle? _failureStyle;

  /// The user's answer to Q2: when they feel mentally sharpest during the day.
  PeakEnergyWindow? _peakEnergy;

  /// The user's answer to Q3: how quickly they bounce back after a bad week.
  RecoverySpeed? _recoverySpeed;

  /// The user's answer to Q4: what most often stops their habits from sticking.
  PrimaryBlocker? _primaryBlocker;

  /// The user's answer to Q5: the inner voice pattern when they miss a habit.
  SelfTalkPattern? _selfTalk;

  /// The user's answer to Q6: the core motivation behind wanting better habits.
  MotivationSource? _motivation;

  /// The user's answer to Q7: what accountability method works best for them.
  AccountabilityStyle? _accountability;

  /// The user's answer to Q8: the deepest reason they want better habits.
  CoreDriver? _coreDriver;

  // ---------------------------------------------------------------------------
  // METHODS
  // ---------------------------------------------------------------------------

  /// Advances the quiz to the next question, or shows the reveal screen
  /// when the user has answered the final question.
  ///
  /// Called when the user taps the "Next" / "See my Brain Profile" button.
  /// Uses setState() to update _step or _showReveal, which triggers a UI rebuild.
  void _next() {
    if (_step < _questions.length - 1) {
      // There are more questions — move to the next one.
      // setState() is Flutter's way of saying "my data changed, redraw the UI".
      // The arrow function `() => _step++` is shorthand for a one-liner lambda.
      setState(() => _step++);
    } else {
      // All questions answered — switch to the reveal/summary screen.
      // Setting _showReveal = true causes build() to render _RevealPage instead
      // of the question UI.
      setState(() => _showReveal = true);
    }
  }

  /// Commits the completed brain profile to global Riverpod state and
  /// triggers navigation away from this screen.
  ///
  /// Called when the user taps "Continue to your Blueprint" on the reveal page.
  ///
  /// SIDE EFFECT: Writes a [NeuroBrainProfile] to [neuroProvider]. The app
  /// router watches neuroProvider and will automatically redirect to the main
  /// dashboard once brainProfile becomes non-null.
  void _confirm() {
    // Guard: if any answer is still null (shouldn't happen, but safety check),
    // do nothing. The `==` checks all 8 fields against null.
    if (_failureStyle == null ||
        _peakEnergy == null ||
        _recoverySpeed == null ||
        _primaryBlocker == null ||
        _selfTalk == null ||
        _motivation == null ||
        _accountability == null ||
        _coreDriver == null) return;

    // RIVERPOD PATTERN: ref.read(provider.notifier) accesses the Notifier
    // (the controller object) for a StateNotifierProvider or NotifierProvider.
    // Unlike ref.watch(), ref.read() does NOT subscribe to updates — it just
    // reads the current value once. This is correct inside event handlers
    // (like button taps) where we want to trigger an action, not listen.
    ref.read(neuroProvider.notifier).setBrainProfile(NeuroBrainProfile(
      failureStyle: _failureStyle!,       // The `!` asserts "not null" — safe here because we checked above
      peakEnergyWindow: _peakEnergy!,
      recoverySpeed: _recoverySpeed!,
      primaryBlocker: _primaryBlocker!,
      selfTalkPattern: _selfTalk!,
      motivationSource: _motivation!,
      accountabilityStyle: _accountability!,
      coreDriver: _coreDriver!,
      // DateTime.now() gets the current timestamp; toIso8601String() converts it
      // to a standard text format like "2026-05-29T14:30:00.000" for easy storage.
      completedAt: DateTime.now().toIso8601String(),
    ));
    // Router transitions automatically when brainProfile becomes non-null
  }

  // ---------------------------------------------------------------------------
  // QUESTIONS DATA
  // The `late` keyword means "I promise this will be set before it's first used,
  // but I don't need to set it in the constructor". Here it's initialized inline
  // with `late final`, meaning it's set once (lazily) and never changed.
  // `final` means the list reference itself can't be reassigned after init.
  // ---------------------------------------------------------------------------

  /// The full list of quiz questions. Each [_Question] holds the question text
  /// and a list of [_Answer] objects (label + callback to store the answer).
  ///
  /// The callbacks inside use setState() to update the corresponding answer
  /// field when an answer button is tapped.
  late final _questions = [
    // Q1: Failure style
    _Question(
      question: 'When you fail to follow through on a goal, what usually happens?',
      answers: [
        // Each _Answer takes: a display label, and a VoidCallback (a function
        // that takes no arguments and returns nothing) to run when tapped.
        // `() => setState(() => _failureStyle = FailureStyle.perfectionist)` means:
        // "when tapped, call setState with a mini-function that sets _failureStyle."
        _Answer('I do it perfectly or not at all', () => setState(() => _failureStyle = FailureStyle.perfectionist)),
        _Answer('I avoid it until it feels impossible', () => setState(() => _failureStyle = FailureStyle.avoider)),
        _Answer('I overthink and never start', () => setState(() => _failureStyle = FailureStyle.analyst)),
        _Answer('I just drift — no clear reason', () => setState(() => _failureStyle = FailureStyle.drifter)),
      ],
    ),
    // Q2: Peak energy window
    _Question(
      question: 'When do you feel mentally sharpest?',
      answers: [
        _Answer('Morning (before 12pm)', () => setState(() => _peakEnergy = PeakEnergyWindow.morning)),
        _Answer('Afternoon (12pm–5pm)', () => setState(() => _peakEnergy = PeakEnergyWindow.afternoon)),
        _Answer('Evening (after 5pm)', () => setState(() => _peakEnergy = PeakEnergyWindow.evening)),
        _Answer('It varies day to day', () => setState(() => _peakEnergy = PeakEnergyWindow.variable)),
      ],
    ),
    // Q3: Recovery speed after setbacks
    _Question(
      question: 'After a bad week, how quickly do you bounce back?',
      answers: [
        _Answer('Within a day or two', () => setState(() => _recoverySpeed = RecoverySpeed.fast)),
        _Answer('About a week', () => setState(() => _recoverySpeed = RecoverySpeed.medium)),
        _Answer('Several weeks or more', () => setState(() => _recoverySpeed = RecoverySpeed.slow)),
        _Answer('It changes a lot', () => setState(() => _recoverySpeed = RecoverySpeed.variable)),
      ],
    ),
    // Q4: Primary blocker
    _Question(
      question: 'What most often stops your habits from sticking?',
      answers: [
        _Answer('Low energy or fatigue', () => setState(() => _primaryBlocker = PrimaryBlocker.energy)),
        _Answer('Feeling overwhelmed', () => setState(() => _primaryBlocker = PrimaryBlocker.overwhelm)),
        _Answer('Distraction or phone use', () => setState(() => _primaryBlocker = PrimaryBlocker.distraction)),
        _Answer('Life events, travel, stress', () => setState(() => _primaryBlocker = PrimaryBlocker.life)),
      ],
    ),
    // Q5: Self-talk pattern when missing a habit
    _Question(
      question: 'When you miss a habit, what goes through your head?',
      answers: [
        _Answer('"I always fail at this"', () => setState(() => _selfTalk = SelfTalkPattern.selfCritical)),
        _Answer('I avoid thinking about it', () => setState(() => _selfTalk = SelfTalkPattern.avoidant)),
        _Answer('I analyze what went wrong', () => setState(() => _selfTalk = SelfTalkPattern.rational)),
        _Answer('"What\'s the point anyway?"', () => setState(() => _selfTalk = SelfTalkPattern.hopeless)),
      ],
    ),
    // Q6: Motivation source
    _Question(
      question: 'What drives you to build better habits?',
      answers: [
        _Answer('Becoming a specific type of person', () => setState(() => _motivation = MotivationSource.identity)),
        _Answer('Achieving a specific outcome', () => setState(() => _motivation = MotivationSource.outcome)),
        _Answer('Enjoying the process itself', () => setState(() => _motivation = MotivationSource.process)),
        _Answer('Avoiding negative consequences', () => setState(() => _motivation = MotivationSource.survival)),
      ],
    ),
    // Q7: Accountability style
    _Question(
      question: 'What keeps you most accountable?',
      answers: [
        _Answer('Tracking streaks and data', () => setState(() => _accountability = AccountabilityStyle.tracking)),
        _Answer('Someone checking in on me', () => setState(() => _accountability = AccountabilityStyle.external)),
        _Answer('Good systems and reminders', () => setState(() => _accountability = AccountabilityStyle.systems)),
        _Answer('Honestly, nothing works long-term', () => setState(() => _accountability = AccountabilityStyle.none)),
      ],
    ),
    // Q8: Core driver — the deepest "why"
    _Question(
      question: 'At your core, why do you want better habits?',
      answers: [
        _Answer('To feel better day-to-day', () => setState(() => _coreDriver = CoreDriver.feelBetter)),
        _Answer('To perform at a higher level', () => setState(() => _coreDriver = CoreDriver.performBetter)),
        _Answer('To become a specific person', () => setState(() => _coreDriver = CoreDriver.becomeSomeone)),
        _Answer("I'm barely keeping it together", () => setState(() => _coreDriver = CoreDriver.survive)),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // COMPUTED GETTER: _canProceed
  // ---------------------------------------------------------------------------

  /// Returns true when the user has selected an answer for the current question.
  ///
  /// This is a Dart "getter" — accessed like a property (_canProceed) but
  /// computed dynamically each time it's read. The `get` keyword defines it.
  ///
  /// Uses a Dart switch EXPRESSION (not statement) — it evaluates to a value.
  /// `_ => false` is the catch-all / default case (like `default:` in other languages).
  /// The result (true or false) is used to enable/disable the Next button.
  bool get _canProceed => switch (_step) {
        0 => _failureStyle != null,       // Q1 answered?
        1 => _peakEnergy != null,         // Q2 answered?
        2 => _recoverySpeed != null,      // Q3 answered?
        3 => _primaryBlocker != null,     // Q4 answered?
        4 => _selfTalk != null,           // Q5 answered?
        5 => _motivation != null,         // Q6 answered?
        6 => _accountability != null,     // Q7 answered?
        7 => _coreDriver != null,         // Q8 answered?
        _ => false,                       // Fallback (should never happen)
      };

  // ---------------------------------------------------------------------------
  // build() — THE MAIN UI METHOD
  // Flutter calls this every time setState() is triggered. It must return a
  // Widget tree describing what to display right now.
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // If the user has answered all questions, show the reveal screen instead
    // of the question UI. _RevealPage is a completely different widget defined
    // later in this file.
    if (_showReveal) {
      return _RevealPage(
        failureStyle: _failureStyle!,       // Pass completed answers to the reveal page
        peakEnergy: _peakEnergy!,
        primaryBlocker: _primaryBlocker!,
        recoverySpeed: _recoverySpeed!,
        coreDriver: _coreDriver!,
        onContinue: _confirm,               // The button on reveal calls _confirm()
      );
    }

    // Get the current question object from the list using the step index.
    final q = _questions[_step];

    // Calculate what fraction of the quiz is complete (0.0 to 1.0).
    // e.g., step=3 out of 8 total = 4/8 = 0.5 (50%). Used by the progress bar.
    final progress = (_step + 1) / _questions.length;

    return Scaffold(
      // Scaffold is the basic full-screen layout widget. It provides the
      // background color, and slots for AppBar, body, FloatingActionButton, etc.
      body: SafeArea(
        // SafeArea insets the child to avoid the device's status bar, notch,
        // and home indicator (the areas that aren't usable screen space).
        child: Padding(
          // Adds 24 logical pixels of space on all four sides.
          padding: const EdgeInsets.all(24),
          child: Column(
            // Column stacks children vertically (top to bottom).
            // crossAxisAlignment.start means: align children to the LEFT edge
            // (the "cross axis" of a vertical column is horizontal).
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---- TOP ROW: "Brain Assessment" label + question counter ----
              Row(
                // Row lays children out horizontally (left to right).
                children: [
                  Text(
                    'Brain Assessment',
                    // Theme.of(context) retrieves the current app theme.
                    // textTheme.titleSmall is a predefined text style.
                    // copyWith() creates a copy of that style with overrides —
                    // here we override the color to be the secondary text color.
                    // The `?.` is null-safe chaining: if textTheme.titleSmall is
                    // null, the whole expression returns null instead of crashing.
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondary),
                  ),
                  // Spacer() is an invisible widget that expands to fill all
                  // remaining horizontal space, pushing the next sibling to the right.
                  const Spacer(),
                  Text(
                    // String interpolation: `${}` inserts a variable's value into a string.
                    '${_step + 1}/${_questions.length}', // e.g. "3/8"
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 12), // Adds 12px of vertical blank space

              // ---- PROGRESS BAR ----
              ClipRRect(
                // ClipRRect clips its child to a rounded rectangle shape.
                // Without this, LinearProgressIndicator has square corners.
                borderRadius: BorderRadius.circular(4), // 4px corner radius
                child: LinearProgressIndicator(
                  value: progress,                        // 0.0 = empty, 1.0 = full
                  minHeight: 4,                           // Height of the bar in pixels
                  backgroundColor: context.borderColor,  // Unfilled track color (from theme)
                  color: const Color(0xFF6366F1),         // Filled portion color (indigo)
                  // Color values are written as 0xFFRRGGBB hex.
                  // FF = fully opaque, 63 = red channel, 66 = green, F1 = blue.
                ),
              ),

              const SizedBox(height: 40), // Extra space before the question text

              // ---- QUESTION TEXT ----
              Text(
                q.question, // The question string for the current step
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.4, // Line-height multiplier (1.4x font size between lines)
                ),
              )
                // .animate() enters the flutter_animate system. Every call after
                // it adds an animation layer.
                .animate(
                  // key: ValueKey(_step) tells Flutter this is a NEW widget when
                  // _step changes, so the animation plays fresh on each question.
                  key: ValueKey(_step),
                )
                .fadeIn()         // Animate opacity from 0 to 1
                .slideX(begin: 0.05), // Simultaneously slide in 5% from the right

              const SizedBox(height: 32),

              // ---- ANSWER BUTTONS ----
              // `...` is the "spread operator" — it inserts all elements of the
              // list into the surrounding list (the Column's children list).
              // `.asMap()` converts a List to a Map<int, T> (index → value).
              // `.entries` gives the key-value pairs as Iterable<MapEntry<int, T>>.
              // `.map((e) { ... })` transforms each entry into a widget.
              ...q.answers.asMap().entries.map((e) {
                final idx = e.key;   // The answer's position (0, 1, 2, 3)
                final a = e.value;   // The _Answer object (label + callback)
                return Padding(
                  // Add 12px space below each answer button (but not the last — the
                  // `only` constructor lets you specify individual sides).
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnswerButton(
                    label: a.label,     // Display text for this answer option
                    onTap: a.onSelect,  // Store the answer when tapped
                  )
                    .animate(
                      // ValueKey with both step and index ensures each answer
                      // button is treated as a fresh widget when the question changes.
                      key: ValueKey('$_step-$idx'),
                      // Stagger the animation: each answer appears slightly after
                      // the previous one. `idx * 60` gives 0ms, 60ms, 120ms, 180ms.
                      // `.ms` is a Dart extension on int that creates a Duration.
                      delay: (idx * 60).ms,
                    )
                    .fadeIn()
                    .slideX(begin: 0.1), // Slide in 10% from the right
                );
              }),

              // Spacer pushes the button below to the bottom of the screen,
              // regardless of how many answer options are shown above.
              const Spacer(),

              // ---- NEXT / FINISH BUTTON ----
              SizedBox(
                width: double.infinity, // Make the button stretch full width
                child: ElevatedButton(
                  // `_canProceed ? _next : null` is a ternary expression:
                  //   if _canProceed is true → onPressed = _next (button is active)
                  //   if _canProceed is false → onPressed = null (button is disabled)
                  // Flutter automatically styles a null-onPressed button as greyed out.
                  onPressed: _canProceed ? _next : null,
                  // Change the label on the last question to "See my Brain Profile"
                  child: Text(_step == _questions.length - 1 ? 'See my Brain Profile' : 'Next'),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _RevealPage — shown after all 8 answers, before data is committed
// =============================================================================
//
// This screen summarizes the user's brain archetype (derived from their answers)
// and explains what the app will do differently for them. The user reads it and
// then taps "Continue" to officially save the profile and enter the main app.
//
// It is a PRIVATE class (underscore prefix) — it's only used within this file.
// It's a StatelessWidget because it has no changing local data of its own;
// everything it needs is passed in via constructor parameters.
// =============================================================================

/// A full-screen summary widget that reveals the user's brain archetype after
/// completing the quiz. Shown before the profile is committed to global state.
///
/// Extends [StatelessWidget] — this widget has no mutable local state.
/// It receives all its data through constructor parameters and just renders them.
class _RevealPage extends StatelessWidget {

  // ---------------------------------------------------------------------------
  // FINAL FIELDS — immutable data passed in by the parent widget (_BrainAssessmentPageState)
  // `final` means these can only be assigned once (in the constructor) and
  // never changed afterward. This is required for StatelessWidget fields.
  // ---------------------------------------------------------------------------

  /// How this user typically fails at goals. Determines part of their archetype name.
  final FailureStyle failureStyle;

  /// When this user is mentally sharpest. Used to personalize the protocol insight.
  final PeakEnergyWindow peakEnergy;

  /// What most often blocks this user's habits. Used to personalize an insight.
  final PrimaryBlocker primaryBlocker;

  /// How fast this user recovers after setbacks. Used to personalize an insight.
  final RecoverySpeed recoverySpeed;

  /// The user's deepest motivation. Combined with failureStyle to pick archetype.
  final CoreDriver coreDriver;

  /// Callback invoked when the user taps "Continue to your Blueprint".
  /// VoidCallback is a Dart typedef for `void Function()` — a function that
  /// takes no arguments and returns nothing.
  final VoidCallback onContinue;

  /// Constructor requiring all fields. `required` means the caller MUST provide
  /// each named argument — Dart will give a compile error if any are missing.
  const _RevealPage({
    required this.failureStyle,
    required this.peakEnergy,
    required this.primaryBlocker,
    required this.recoverySpeed,
    required this.coreDriver,
    required this.onContinue,
  });

  // ---------------------------------------------------------------------------
  // STATIC LOOKUP TABLES
  // `static` means these belong to the CLASS, not any particular instance.
  // `const` means these are compile-time constants — the map is built once and
  // never changes. `static const` together = most efficient possible constant data.
  //
  // The keys are strings in the format "failureStyle-coreDriver", e.g.
  // "perfectionist-feelBetter". This creates a 4×4 = 16-slot lookup table
  // covering every combination of failure style and core driver.
  // ---------------------------------------------------------------------------

  /// Maps "failureStyle-coreDriver" keys to human-readable archetype names.
  static const _archetypeNames = {
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

  /// Maps the same "failureStyle-coreDriver" keys to multi-sentence archetype
  /// descriptions that explain the user's pattern and recovery approach.
  static const _archetypeDescriptions = {
    'perfectionist-feelBetter': 'You hold yourself to a high standard but pay for it in exhaustion. Your recovery protocol focuses on self-compassion over self-discipline.',
    'perfectionist-performBetter': 'You want precision results. You succeed when you have clear metrics and fail when things feel fuzzy. Your protocol is built around specificity.',
    'perfectionist-becomeSomeone': 'Identity is your fuel. You\'re not building habits — you\'re building a person. Missing a day feels like a betrayal of who you\'re becoming.',
    'perfectionist-survive': 'You\'re under pressure and holding the bar high anyway. Your recovery protocol reduces friction before anything else.',
    'avoider-feelBetter': 'Comfort is your compass. You avoid discomfort so well that you sometimes avoid the habits you actually want. Your protocol removes the activation energy.',
    'avoider-performBetter': 'You have the talent but your effort is inconsistent. Your protocol surfaces small wins quickly to build momentum.',
    'avoider-becomeSomeone': 'You have a clear vision of who you want to be. The gap between that vision and today\'s action is where you get stuck.',
    'avoider-survive': 'You operate with minimum viable effort by necessity. Your protocol is built for low-energy days, not ideal conditions.',
    'analyst-feelBetter': 'You think your way through everything, including your feelings. Your protocol uses data and patterns to bypass the analysis paralysis.',
    'analyst-performBetter': 'You are a systems thinker. Once you have the right framework, you execute well. Your protocol is about finding the right frame first.',
    'analyst-becomeSomeone': 'You have a rich internal model of who you want to be. Your challenge is converting that model into daily action.',
    'analyst-survive': 'You analyze threats carefully and act only when necessary. Your protocol is built for pragmatic, low-overhead execution.',
    'drifter-feelBetter': 'You move with energy and emotion. When you feel good, you\'re unstoppable. Your protocol anchors habits to emotional states, not rigid schedules.',
    'drifter-performBetter': 'You sprint hard and then disappear. Your protocol introduces small daily minimums that keep the pathway warm between sprints.',
    'drifter-becomeSomeone': 'You can see a better version of yourself clearly. The drift is between who you are and who you\'re becoming. Your protocol bridges that gap daily.',
    'drifter-survive': 'You\'re navigating day-to-day without a clear anchor. Your protocol gives you three habits you can do in any circumstance.',
  };

  // ---------------------------------------------------------------------------
  // COMPUTED GETTERS — derive display values from the stored enum fields
  // ---------------------------------------------------------------------------

  /// Returns the archetype name for this user based on their failureStyle + coreDriver.
  ///
  /// `.name` on an enum value returns its string identifier, e.g.
  /// `FailureStyle.perfectionist.name` → `"perfectionist"`.
  /// String interpolation builds the lookup key: "perfectionist-feelBetter".
  /// `??` is the null-coalescing operator: if the map lookup returns null
  /// (key not found), fall back to the default string on the right.
  String get _archetype => _archetypeNames['${failureStyle.name}-${coreDriver.name}'] ?? 'The Recovery Builder';

  /// Returns the archetype description for this user's combination.
  String get _description => _archetypeDescriptions['${failureStyle.name}-${coreDriver.name}'] ?? 'Your protocol is personalized to your patterns.';

  /// Returns a human-readable label for the user's failure style.
  ///
  /// Uses a Dart switch EXPRESSION — introduced in Dart 3.0. Unlike a switch
  /// statement (which runs code), a switch expression evaluates to a value.
  /// The format is: `switch (variable) { pattern => result, ... }`
  /// Each `FailureStyle.xxx` pattern matches one enum variant and maps to a string.
  String get _failureLabel => switch (failureStyle) {
        FailureStyle.perfectionist => 'Perfectionist',
        FailureStyle.avoider => 'Avoider',
        FailureStyle.analyst => 'Analyst',
        FailureStyle.drifter => 'Drifter',
      };

  /// Builds a list of 3 personalized insight strings — one each for
  /// peak energy, primary blocker, and recovery speed.
  ///
  /// Each switch expression picks the string that matches the user's answer.
  /// The emoji characters are just unicode — they render as emoji on all platforms.
  List<String> get _insights => [
        switch (peakEnergy) {
          PeakEnergyWindow.morning => '🌅 You\'re sharpest in the morning — your Blueprint schedules key habits before noon.',
          PeakEnergyWindow.afternoon => '☀️ You peak in the afternoon — your Blueprint front-loads easier habits early.',
          PeakEnergyWindow.evening => '🌆 You\'re sharpest in the evening — your Blueprint won\'t fight your biology.',
          PeakEnergyWindow.variable => '🔀 Your energy varies — your Blueprint builds in flexible anchors, not fixed times.',
        },
        switch (primaryBlocker) {
          PrimaryBlocker.energy => '⚡ Low energy is your main blocker — your habits are optimized for 5-minute minimum doses.',
          PrimaryBlocker.overwhelm => '🧠 Overwhelm stops you — your habits are broken into micro-steps to remove the start cost.',
          PrimaryBlocker.distraction => '📱 Distraction derails you — your habits include a friction step to break the pattern.',
          PrimaryBlocker.life => '🌊 Life disruptions hit you hardest — your Comeback Protocol activates within 24 hours of a miss.',
        },
        switch (recoverySpeed) {
          RecoverySpeed.fast => '⚡ You bounce back fast — your protocol capitalizes on that momentum window.',
          RecoverySpeed.medium => '↩ You take about a week — your protocol gives you a 3-day grace window before escalating.',
          RecoverySpeed.slow => '🐢 You recover slowly — your protocol is gentler and uses smaller re-entry actions.',
          RecoverySpeed.variable => '〰️ Your recovery varies — your protocol reads your context and adapts week to week.',
        },
      ];

  // ---------------------------------------------------------------------------
  // build() — draws the reveal/summary screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView makes the content scrollable if it overflows
          // the screen height. Without this, a tall Column on a small device
          // would throw a "pixels overflowed" layout error.
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---- HEADER: "Your Brain Profile" label ----
              Text(
                'Your Brain Profile',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondary),
              ).animate().fadeIn(), // Simple fade-in entrance animation

              const SizedBox(height: 24),

              // ---- ARCHETYPE CARD (gradient box with archetype name) ----
              Container(
                width: double.infinity, // Stretch to full available width
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // LinearGradient paints a smooth color transition across the container.
                  // `colors` is the list of colors (left to right here).
                  // `begin` and `end` set the direction using Alignment constants.
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo → Purple
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20), // Rounded corners: 20px radius
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Small label above the archetype name
                    const Text(
                      'You are…',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      // Colors.white70 is a predefined constant: white at 70% opacity
                    ),

                    const SizedBox(height: 6),

                    // The archetype name (e.g. "The Exhausted Achiever")
                    Text(
                      _archetype,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2, // Tight line spacing for the large heading
                      ),
                    )
                      .animate()
                      .fadeIn(delay: 200.ms)      // Start fade after 200ms
                      .slideY(begin: 0.15),        // Slide up 15% of widget height

                    const SizedBox(height: 12),

                    // ---- FAILURE STYLE BADGE (pill-shaped tag) ----
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      // `symmetric` sets horizontal padding (left+right) and vertical (top+bottom)
                      decoration: BoxDecoration(
                        // Semi-transparent white overlay for the badge background.
                        // withOpacity(0.2) = 20% opaque white (subtle tint).
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20), // Pill shape
                      ),
                      child: Text(
                        'Failure style: $_failureLabel', // e.g. "Failure style: Perfectionist"
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600, // Semi-bold
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms), // Fade in slightly after the name

                  ],
                ),
              )
                .animate()
                .fadeIn()
                // scale() animates from 97% size to 100%, giving a subtle "pop in" feel.
                // Offset(0.97, 0.97) means 97% width and 97% height as the start state.
                .scale(begin: const Offset(0.97, 0.97)),

              const SizedBox(height: 20),

              // ---- ARCHETYPE DESCRIPTION ----
              Text(
                _description,
                style: TextStyle(
                  fontSize: 15,
                  color: context.textSecondary, // Slightly dimmed text for body copy
                  height: 1.5,                  // Generous line spacing for readability
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // ---- SECTION TITLE: "What this means for your protocol" ----
              Text(
                'What this means for your protocol',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 12),

              // ---- PERSONALIZED INSIGHT ROWS ----
              // `..._insights.asMap().entries.map(...)` spreads the mapped widgets
              // directly into this Column's children list (the `...` spread operator).
              // Each _InsightRow is a separate styled card showing one insight string.
              ..._insights.asMap().entries.map((e) => _InsightRow(
                    text: e.value,                 // The insight text string
                    delay: 550 + e.key * 80,       // Stagger: 550ms, 630ms, 710ms
                  )),

              const SizedBox(height: 32),

              // ---- CONTINUE BUTTON ----
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // FilledButton is a Material 3 button style — fully filled with
                  // the primary color (more prominent than ElevatedButton).
                  onPressed: onContinue, // Calls _confirm() in the parent state
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1), // Indigo fill
                    padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14), // Rounded corners
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center children horizontally
                    children: [
                      Text(
                        'Continue to your Blueprint',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8), // Space between text and icon
                      Icon(Icons.arrow_forward, size: 18), // Right-arrow icon
                    ],
                  ),
                ),
              )
                .animate()
                .fadeIn(delay: 800.ms) // Button appears last — after all insight rows
                .slideY(begin: 0.1),   // Slides up slightly as it fades in

              const SizedBox(height: 16),

              // ---- FOOTNOTE ----
              Center(
                child: Text(
                  'Your Blueprint is scored against this profile',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ).animate().fadeIn(delay: 900.ms),

            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _InsightRow — a single styled insight card in the reveal screen
// =============================================================================

/// Renders one personalized insight string inside a rounded card.
///
/// Used by [_RevealPage] to display the three protocol insights.
/// Accepts a [delay] in milliseconds for staggered entrance animations.
///
/// Extends [StatelessWidget] — no mutable state needed; just renders what
/// it receives.
class _InsightRow extends StatelessWidget {
  /// The insight text to display (e.g. "⚡ Low energy is your main blocker…").
  final String text;

  /// Animation delay in milliseconds. The parent staggers this to make each
  /// row appear slightly after the previous one.
  final int delay;

  const _InsightRow({required this.text, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // Space below each card
      child: Container(
        padding: const EdgeInsets.all(12), // Inner padding inside the card
        decoration: BoxDecoration(
          color: context.cardBg,               // Card background from app theme
          borderRadius: BorderRadius.circular(10), // Slightly rounded corners
          border: Border.all(color: context.borderColor), // Subtle outline border
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, height: 1.4), // Readable body size
        ),
      )
        .animate()
        // Duration(milliseconds: delay) creates a Duration object from the int.
        // This is equivalent to `delay.ms` used earlier — both are valid.
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.05), // Slide in 5% from the right
    );
  }
}

// =============================================================================
// DATA CLASSES — simple containers used only within this file
// =============================================================================

/// Holds the data for one quiz question: the question text and its answer options.
///
/// This is a plain Dart class (not a Flutter widget). It just stores data.
/// The `const` constructor means instances can be compile-time constants
/// (slightly more efficient than runtime construction).
class _Question {
  /// The question text displayed to the user.
  final String question;

  /// The list of answer options for this question.
  final List<_Answer> answers;

  const _Question({required this.question, required this.answers});
}

/// Holds the data for one answer option: its display label and what to do when selected.
///
/// Used inside [_Question.answers]. The [onSelect] callback stores the chosen
/// enum value into the parent state when the user taps this answer.
class _Answer {
  /// The text shown on the answer button (e.g. "I do it perfectly or not at all").
  final String label;

  /// The function to call when this answer is tapped.
  /// VoidCallback = `void Function()` — no arguments, no return value.
  final VoidCallback onSelect;

  const _Answer(this.label, this.onSelect);
}

// =============================================================================
// _AnswerButton — a tappable answer card widget
// =============================================================================

/// A full-width tappable card that displays one answer option during the quiz.
///
/// Wraps the answer label in a styled container with a tap detector.
/// Extends [StatelessWidget] — it just renders a label; all state changes
/// happen in the [onTap] callback provided by the parent.
class _AnswerButton extends StatelessWidget {
  /// The text to display on this answer option button.
  final String label;

  /// Called when the user taps this answer button.
  final VoidCallback onTap;

  const _AnswerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // GestureDetector wraps any widget to make it respond to touch gestures.
      // onTap fires when the user lifts their finger after a tap (not on press-down).
      onTap: onTap,
      child: Container(
        width: double.infinity, // Stretch to fill the parent's full width
        padding: const EdgeInsets.all(16), // 16px inner padding on all sides
        decoration: BoxDecoration(
          color: context.cardBg,               // Background from app theme
          borderRadius: BorderRadius.circular(12), // 12px rounded corners
          border: Border.all(color: context.borderColor), // Thin outline border
        ),
        child: Text(
          label,
          // bodyMedium is a predefined text style from Material Design's type scale —
          // it's the standard body text size (typically 14sp).
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
