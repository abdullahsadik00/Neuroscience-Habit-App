// onboarding_page.dart
//
// WHAT THIS FILE IS:
//   This file defines the multi-step onboarding screen that new users see the
//   very first time they open the NeuroSync app.
//
// ROLE IN APP ARCHITECTURE:
//   - Displayed by the router (main.dart / app router) when neuroProvider reports
//     that onboarding has not yet been completed.
//   - On completion it calls neuroProvider.notifier methods (defined in
//     providers/neuro_provider.dart) to persist the user's name, role, and
//     onboarding-complete flag into SharedPreferences.
//   - It also kicks off NotificationService (services/notification_service.dart)
//     to schedule daily push reminders.
//   - After neuroProvider marks onboarding complete the router automatically
//     redirects the user to the home/habits screen — this file never navigates
//     manually with Navigator.push().
//
// KEY CONCEPTS A LEARNER NEEDS:
//   1. ConsumerStatefulWidget / ConsumerState — Riverpod's version of StatefulWidget
//      that gives the widget access to `ref` so it can read/watch providers.
//   2. StatelessWidget — a simpler widget that has no mutable state of its own.
//   3. setState() — tells Flutter "my local data changed, please redraw me".
//   4. TextEditingController — Flutter's way of reading & controlling a text field.
//   5. AnimatedSwitcher — a Flutter widget that animates when its child changes.
//   6. flutter_animate — a third-party package that adds a fluent animation API
//      to any widget via .animate().fadeIn() etc.
//   7. Dart switch expression (switch (x) { 0 => ..., _ => ... }) — like a
//      switch/case but it returns a value directly.

// ── IMPORTS ──────────────────────────────────────────────────────────────────

// Flutter's core Material Design UI library — gives us Scaffold, Text,
// TextField, ElevatedButton, Icon, Column, Row, Container, etc.
import 'package:flutter/material.dart';

// Third-party animation package. Adds the .animate() extension method to any
// Widget, letting us chain animations like .fadeIn(), .slideX(), .scale() in a
// very readable way, without writing AnimationController boilerplate.
import 'package:flutter_animate/flutter_animate.dart';

// Riverpod — the state management library used throughout this app. Provides
// ConsumerStatefulWidget, ConsumerState, and the `ref` object that lets widgets
// read/watch/modify providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Our own app-level state provider. Contains the NeuroNotifier and neuroProvider
// which hold habit data, user profile, and onboarding status in memory and
// persisted storage.
import '../providers/neuro_provider.dart';

// Our wrapper around Flutter Local Notifications. Exposes static methods to
// request OS-level permission and schedule daily/evening reminders.
import '../services/notification_service.dart';

// Centralised theme helpers — defines colors, text styles, and BuildContext
// extension properties like context.textSecondary, context.cardBg, etc.
import '../theme/app_theme.dart';

// ── MAIN WIDGET ───────────────────────────────────────────────────────────────

/// OnboardingPage is the top-level widget for the entire onboarding flow.
///
/// It extends [ConsumerStatefulWidget], which is Riverpod's version of Flutter's
/// built-in [StatefulWidget]. The "Consumer" part means this widget has access
/// to a `ref` object (via [ConsumerState]) that lets it read and write to
/// Riverpod providers. The "Stateful" part means it can hold mutable local
/// variables (like which step the user is on) and call setState() to rebuild.
///
/// This widget is instantiated by the app's router when the user has not yet
/// completed onboarding.
class OnboardingPage extends ConsumerStatefulWidget {
  // `const` constructor — Flutter can reuse this widget object across rebuilds
  // because it carries no configuration data that could change.
  // `super.key` passes the optional `key` parameter up to the parent class.
  // Keys help Flutter identify widgets in the tree; `const` constructors require
  // the key to be passed this way.
  const OnboardingPage({super.key});

  /// createState() is required by StatefulWidget (and ConsumerStatefulWidget).
  /// Flutter calls this once to create the mutable State object that lives
  /// alongside the widget. The underscore prefix on _OnboardingPageState means
  /// it is private to this file.
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

// ── STATE CLASS ───────────────────────────────────────────────────────────────

/// _OnboardingPageState holds all the mutable data for OnboardingPage and
/// contains the build() method that draws the UI.
///
/// By convention the State class is private (leading underscore) and lives in
/// the same file as its widget. ConsumerState gives us the `ref` property
/// automatically — we do not have to declare it.
class _OnboardingPageState extends ConsumerState<OnboardingPage> {

  // TextEditingController is Flutter's object for reading and controlling a
  // TextField. We pass it to the TextField widget; the field keeps it in sync
  // so we can read _nameController.text at any time to get the current value.
  final _nameController = TextEditingController();

  // The user's selected role (e.g. 'Builder', 'Designer'). Starts as 'Builder'
  // so there is always a valid default when the user reaches the role step.
  String _role = 'Builder';

  // Which step of the onboarding wizard the user is on:
  //   0 = name entry screen
  //   1 = role selection screen
  //   2 = science explainer screen
  int _step = 0;

  /// dispose() is called by Flutter when this State object is permanently
  /// removed from the widget tree (e.g. the user navigates away).
  ///
  /// We MUST call _nameController.dispose() here to free the memory and
  /// listeners the TextEditingController holds. Forgetting this causes memory
  /// leaks. super.dispose() must always be called last.
  @override
  void dispose() {
    _nameController.dispose(); // Release resources held by the text controller.
    super.dispose(); // Let the parent class (ConsumerState) clean up too.
  }

  /// _next() advances the onboarding wizard by one step.
  ///
  /// On the last step (step 2) it saves the user's data to the Riverpod store
  /// and triggers notification scheduling instead of advancing further.
  ///
  /// No parameters. No return value. Side effects: mutates _step via setState,
  /// writes to neuroProvider, and schedules local push notifications.
  void _next() {
    // Guard: if the user is on step 0 and hasn't typed a name yet, do nothing.
    // .trim() strips leading/trailing whitespace; .isEmpty checks for empty string.
    if (_step == 0 && _nameController.text.trim().isEmpty) return;

    if (_step < 2) {
      // We are on step 0 or 1 — just advance to the next step.
      // setState() is Flutter's way of saying "I changed some local data, please
      // call build() again so the UI reflects the change." The closure passed to
      // setState performs the actual data mutation.
      setState(() => _step++); // _step++ increments _step by 1 (0→1 or 1→2).
    } else {
      // We are on the last step (step 2). Time to save data and finish onboarding.

      // ref.read() reads a provider ONCE without subscribing to future changes.
      // Here we read the notifier (the object that can mutate provider state) and
      // call setUserProfile() to persist the user's chosen name and role.
      ref.read(neuroProvider.notifier).setUserProfile(
            name: _nameController.text.trim(), // Trimmed so no accidental spaces.
            role: _role,                        // The role selected on step 1.
          );

      // Mark onboarding as complete in the provider. The router watches
      // neuroProvider and will automatically switch to the home screen once this
      // flag flips to true — no Navigator.push() needed.
      ref.read(neuroProvider.notifier).completeOnboarding();

      // requestPermission() is async (it shows an OS dialog), so it returns a
      // Future. .then((_) { ... }) runs the callback after the Future resolves.
      // The underscore parameter `_` means "I received a value but don't need it".
      NotificationService.requestPermission().then((_) {
        // Only schedule notifications AFTER the user has granted permission.
        NotificationService.scheduleDailyReminder();    // Morning habit reminder.
        NotificationService.scheduleEveningCheckin();   // Evening reflection prompt.
      });
    }
  }

  /// build() is called by Flutter whenever this widget needs to be drawn (or
  /// redrawn). It returns a Widget tree — a description of what to show on screen.
  /// Flutter is DECLARATIVE: you describe what the UI should look like given the
  /// current state, and Flutter handles actually drawing it.
  ///
  /// [context] is the BuildContext — a handle to this widget's position in the
  /// widget tree. We use it to access theme data (colors, text styles).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold provides the basic Material page structure: background color,
      // safe-area handling, space for a bottom nav bar, snack bars, etc.
      body: SafeArea(
        // SafeArea insets its child away from system UI (notch, status bar,
        // home indicator) so our content is never hidden behind device chrome.
        child: Padding(
          // Add 24px on left/right, 16px on top, 24px on bottom.
          // EdgeInsets.fromLTRB = Left, Top, Right, Bottom.
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: AnimatedSwitcher(
            // AnimatedSwitcher watches its `child` property. When the child
            // widget changes (different key = different widget), it plays an
            // animated transition between the old and new child.
            duration: const Duration(milliseconds: 400), // Transition takes 400 ms.
            child: _buildStep(_step), // The current step widget (keyed so Flutter
                                      // knows when it has actually changed).
          ),
        ),
      ),
    );
  }

  /// _buildStep() chooses which step widget to display based on the current
  /// step index.
  ///
  /// Uses a Dart switch EXPRESSION (not a switch statement). Unlike a switch
  /// statement, a switch expression returns a value — here it returns a Widget.
  /// The `_` pattern at the end is the default/fallthrough case (like `default:`).
  ///
  /// [step] — the current onboarding step index (0, 1, or 2).
  /// Returns the Widget that should be displayed for that step.
  Widget _buildStep(int step) {
    return switch (step) {
      // Step 0: Ask for the user's name.
      // `key: const ValueKey(0)` gives this widget a stable identity.
      // AnimatedSwitcher uses keys to detect "the child changed" — without keys
      // it might not animate because Flutter thinks it's the same widget type.
      0 => _WelcomeStep(
          key: const ValueKey(0),
          nameController: _nameController, // Pass the controller so the step can
                                            // display and edit the text field.
          onNext: _next,                   // Callback — step calls this when done.
        ),

      // Step 1: Ask for the user's role.
      1 => _RoleStep(
          key: const ValueKey(1),
          selected: _role,                         // Currently selected role string.
          onSelect: (r) => setState(() => _role = r), // When user taps a role, update
                                                       // _role and rebuild. `r` is the
                                                       // role string passed by _RoleStep.
          onNext: _next,
        ),

      // Default case (`_`) covers step 2 and any unexpected values.
      _ => _ScienceStep(key: const ValueKey(2), onNext: _next),
    };
  }
}

// ── SHARED LAYOUT WIDGET ──────────────────────────────────────────────────────

// This private class is a reusable layout that every onboarding step uses.
// It places the step content in a scrollable area so it works on small screens
// and when the keyboard is open (which pushes content upward), and pins a
// full-width action button to the bottom of the screen.

/// _StepLayout is a private, reusable scaffold for each onboarding step.
///
/// Extends [StatelessWidget] — the simplest kind of Flutter widget. It has no
/// mutable state; it just takes data via constructor parameters and builds a
/// fixed UI from them. Every time Flutter needs to redraw it, it simply re-runs
/// build() with the same parameters.
///
/// Pattern: wrapping repeated layout structure into its own widget keeps the
/// step-specific widgets (WelcomeStep, RoleStep, ScienceStep) focused purely on
/// their content, not on how that content is framed.
class _StepLayout extends StatelessWidget {
  /// The scrollable content area of this step (the "body" above the button).
  final Widget content;

  /// The label string shown on the action button, e.g. "Get Started".
  final String buttonLabel;

  /// Callback invoked when the user taps the action button.
  /// VoidCallback is a Dart typedef meaning: a function that takes no arguments
  /// and returns nothing — i.e. `() => void` in TypeScript terms.
  final VoidCallback onNext;

  /// Constructor. All three fields are required; Flutter will throw if any are
  /// missing. The `const` keyword means this object can be created at compile
  /// time, which is a small performance win Flutter encourages.
  const _StepLayout({
    required this.content,
    required this.buttonLabel,
    required this.onNext,
  });

  /// build() returns the layout: scrollable content + pinned bottom button.
  @override
  Widget build(BuildContext context) {
    return Column(
      // Column stacks its children vertically, top to bottom.
      children: [
        Expanded(
          // Expanded tells this child to take up ALL remaining vertical space
          // not claimed by the other Column children (the button at the bottom).
          // Without Expanded, the SingleChildScrollView would try to be
          // infinitely tall inside a Column, causing a layout error.
          child: SingleChildScrollView(
            // SingleChildScrollView makes its child scrollable when content is
            // taller than the available space (e.g. small phone or open keyboard).
            physics: const ClampingScrollPhysics(),
            // ClampingScrollPhysics gives Android-style scroll physics — it stops
            // dead at the edge rather than the bouncing "iOS rubber-band" effect.
            child: content, // The step-specific content widget.
          ),
        ),
        const SizedBox(height: 16), // 16px vertical gap between content and button.
        SizedBox(
          width: double.infinity, // Make the button stretch to the full screen width.
          child: ElevatedButton(
            onPressed: onNext, // Wire up the tap handler passed in by the parent.
            child: Text(buttonLabel), // Display the label, e.g. "Get Started".
          ),
        ),
      ],
    );
  }
}

// ── STEP 0: NAME ENTRY ────────────────────────────────────────────────────────

/// _WelcomeStep is the first onboarding screen (step 0).
///
/// Shows the NeuroSync logo icon, headline, tagline, and a TextField where
/// the user types their name. Extends [StatelessWidget] because it owns no
/// mutable state — the TextEditingController is owned by the parent State class
/// and passed down as a parameter.
///
/// Used exclusively by _OnboardingPageState._buildStep() when step == 0.
class _WelcomeStep extends StatelessWidget {
  /// The TextEditingController shared with the parent. Passing it down (rather
  /// than creating a new one here) means the parent can read the typed name
  /// when the user taps "Get Started".
  final TextEditingController nameController;

  /// Called when the user taps the "Get Started" button or submits the keyboard.
  final VoidCallback onNext;

  /// Constructor. `super.key` passes the optional key up to StatelessWidget.
  /// The parent passes `key: const ValueKey(0)` so AnimatedSwitcher can
  /// detect when this widget is swapped out.
  const _WelcomeStep({super.key, required this.nameController, required this.onNext});

  /// build() returns the welcome screen UI tree.
  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      buttonLabel: 'Get Started',
      onNext: onNext,
      content: Column(
        // CrossAxisAlignment.start means all children hug the LEFT edge of the
        // column (for a left-to-right locale). The default would center them.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32), // Top breathing room.

          // Brain / psychology icon badge — a square Container styled as a
          // rounded rectangle with a subtle indigo background.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              // withOpacity(0.15) creates a very light tint of the indigo color
              // — 15% opaque so the background shows through faintly.
              color: const Color(0xFF6366F1).withOpacity(0.15),
              // BorderRadius.circular(16) rounds all four corners by 16px,
              // giving a "squircle" look common in modern mobile UIs.
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.psychology, color: Color(0xFF6366F1), size: 28),
          )
              // .animate() is from the flutter_animate package. It creates an
              // animation controller attached to this widget.
              .animate()
              // .fadeIn() fades the widget from transparent to opaque.
              .fadeIn()
              // .scale() scales the widget from slightly smaller to full size,
              // creating a "pop in" entrance effect. Both run simultaneously.
              .scale(),

          const SizedBox(height: 24),

          // App name headline. Theme.of(context) looks up the nearest Theme
          // widget in the tree and returns its ThemeData. textTheme.headlineMedium
          // returns the pre-configured large headline style.
          // The `?` after headlineMedium is the Dart null-safety operator —
          // it means "only call .copyWith() if headlineMedium is not null".
          // .copyWith() creates a copy of the style with only the specified
          // properties changed (here, fontWeight becomes bold).
          Text(
            'NeuroSync',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          )
              .animate()
              .fadeIn(delay: 100.ms) // Start this animation 100 milliseconds after
                                      // the widget appears (staggered entrance).
              // .slideX(begin: -0.1) slides from 10% to the left of final position.
              // begin is a fraction of the widget's own width, not pixels.
              .slideX(begin: -0.1),

          const SizedBox(height: 8),

          // Tagline subtext. context.textSecondary is a custom extension property
          // defined in app_theme.dart — it returns a muted color appropriate for
          // secondary text in both light and dark mode.
          Text(
            'Build habits using neuroscience — not willpower.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.textSecondary),
          ).animate().fadeIn(delay: 200.ms), // Staggered 200ms after widget appears.

          const SizedBox(height: 40),

          Text(
            "What's your name?",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          // The name input field. Connected to nameController so the parent can
          // read the typed value later.
          TextField(
            controller: nameController, // Binds this field to our controller.
            autofocus: true,            // Automatically opens the keyboard when
                                        // this screen appears.
            decoration: const InputDecoration(
              hintText: 'Enter your name',           // Grey placeholder text.
              prefixIcon: Icon(Icons.person_outline), // Person icon inside the field.
            ),
            // TextInputAction.done shows a "Done" / checkmark button on the
            // software keyboard instead of the default "Return/Enter" key.
            textInputAction: TextInputAction.done,
            // onSubmitted fires when the user taps the keyboard's "Done" button.
            // The `_` parameter is the submitted string — we ignore it because
            // we already have nameController.text. We call onNext() to advance.
            onSubmitted: (_) => onNext(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── STEP 1: ROLE SELECTION ────────────────────────────────────────────────────

/// _RoleStep is the second onboarding screen (step 1).
///
/// Displays a list of role tiles (Builder, Designer, Athlete, Student, Other).
/// The currently selected tile is highlighted. Tapping a tile calls onSelect()
/// in the parent which updates _role and rebuilds this widget with the new
/// selection. Extends [StatelessWidget] because selection state is managed by
/// the parent.
///
/// Used exclusively by _OnboardingPageState._buildStep() when step == 1.
class _RoleStep extends StatelessWidget {
  /// The currently selected role string. The parent passes its _role variable
  /// here so this widget always renders the correct highlighted tile.
  final String selected;

  /// Callback invoked when the user taps a role tile. The parent uses this to
  /// update its _role field. ValueChanged<String> is a Dart typedef for a
  /// function that receives one String argument and returns nothing.
  final ValueChanged<String> onSelect;

  /// Called when the user taps "Continue" to move to the next step.
  final VoidCallback onNext;

  const _RoleStep({super.key, required this.selected, required this.onSelect, required this.onNext});

  // Static constants — these belong to the CLASS, not to any instance, so they
  // are created once and shared. `static const` means they are both class-level
  // and compile-time constants (immutable lists).

  /// The list of role labels shown as selectable tiles.
  static const _roles = ['Builder', 'Designer', 'Athlete', 'Student', 'Other'];

  /// Icon for each role, in the same order as _roles so index `i` gives the
  /// right icon for _roles[i].
  static const _icons = [Icons.code, Icons.brush, Icons.fitness_center, Icons.school, Icons.person];

  /// build() returns the role selection UI.
  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      buttonLabel: 'Continue',
      onNext: onNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          Text(
            'What best describes you?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          )
              .animate()
              .fadeIn()
              // .slideY(begin: -0.1) slides from 10% ABOVE the final position downward.
              .slideY(begin: -0.1),

          const SizedBox(height: 8),

          Text(
            "We'll suggest habits matched to your life.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // The `...` (spread operator) unpacks the List returned by
          // List.generate() into the children array. Without `...` we would
          // be adding a List<Widget> inside a List<Widget>, which is a type error.
          //
          // List.generate(count, builder) creates a list of `count` items.
          // The builder receives the index `i` (0, 1, 2, …) and returns
          // the widget for that index.
          ...List.generate(_roles.length, (i) {
            final role = _roles[i];         // e.g. 'Builder' for i == 0.
            final isSelected = selected == role; // true if this tile is chosen.

            return Padding(
              padding: const EdgeInsets.only(bottom: 10), // Gap between tiles.
              child: GestureDetector(
                // GestureDetector wraps any widget to make it respond to touch.
                // onTap fires when the user taps anywhere within the child area.
                onTap: () => onSelect(role), // Notify parent which role was tapped.
                child: AnimatedContainer(
                  // AnimatedContainer is like a regular Container but it smoothly
                  // interpolates (tweens) its decoration/size/color when they
                  // change — no explicit animation controller needed.
                  duration: const Duration(milliseconds: 200), // Transition speed.
                  padding: const EdgeInsets.all(14), // Inner spacing on all sides.
                  decoration: BoxDecoration(
                    // Ternary expression: condition ? valueIfTrue : valueIfFalse.
                    // Selected tile gets a light indigo tint; unselected uses the
                    // theme's card background color (adapts to light/dark mode).
                    color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // Selected tile gets an indigo border; unselected gets the
                      // subtle theme border color.
                      color: isSelected ? const Color(0xFF6366F1) : context.borderColor,
                      // Selected tile border is thicker (2px vs 1px) to make it
                      // clearly active.
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    // Row lays out children horizontally.
                    children: [
                      // Role icon — tinted indigo when selected, muted otherwise.
                      Icon(_icons[i], color: isSelected ? const Color(0xFF6366F1) : context.textSecondary),
                      const SizedBox(width: 16), // Gap between icon and label.
                      // Role name label.
                      Text(role, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      // Spacer() takes up all remaining horizontal space between
                      // the label and the checkmark, pushing the checkmark to
                      // the far right edge of the row.
                      const Spacer(),
                      // Only show the checkmark icon when this tile is selected.
                      // The `if (condition) widget` syntax inside a list literal
                      // conditionally includes the widget — Dart's "collection if".
                      if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
                    ],
                  ),
                ),
              ),
            )
                // Stagger each tile's entrance animation by 60ms × its index so
                // they appear one after another instead of all at once.
                // (i * 60).ms converts the integer milliseconds into a Duration
                // using flutter_animate's `.ms` extension.
                .animate(delay: (i * 60).ms)
                .fadeIn()
                .slideX(begin: 0.1); // Slide in from slightly to the right.
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── STEP 2: SCIENCE EXPLAINER ─────────────────────────────────────────────────

/// _ScienceStep is the third and final onboarding screen (step 2).
///
/// Shows three "science cards" explaining the key techniques in NeuroSync:
/// Habit Stacking, Neuro Swaps, and the Comeback Protocol. The user reads
/// them and then taps "Let's begin" to complete onboarding.
///
/// Extends [StatelessWidget] — no local state needed; everything is hard-coded
/// educational content.
///
/// Used exclusively by _OnboardingPageState._buildStep() for the default case
/// (step == 2).
class _ScienceStep extends StatelessWidget {
  /// Called when the user taps "Let's begin". In the parent (_next()), this
  /// triggers saving the profile and completing onboarding.
  final VoidCallback onNext;

  const _ScienceStep({super.key, required this.onNext});

  /// build() returns the science explainer UI.
  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      buttonLabel: "Let's begin",
      onNext: onNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          Text(
            'How NeuroSync works',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          // We define the three science cards as a list literal and then
          // transform that list before spreading it into the Column's children.
          //
          // The `...[ ... ]` syntax creates an inline list and spreads it.
          // .asMap() converts the List<_Science> into a Map<int, _Science>
          //   where the key is the index and the value is the element.
          // .entries is the Iterable<MapEntry<int, _Science>> of key-value pairs.
          // .map((e) => ...) transforms each MapEntry into a Padding widget.
          //   e.key is the index (0, 1, 2); e.value is the _Science widget.
          // The result is an Iterable<Padding> which `...` spreads into children.
          ...[
            // Science card 1: Habit Stacking
            _Science(
              icon: Icons.link,
              color: const Color(0xFF6366F1), // Indigo.
              title: 'Habit Stacking',
              body: 'Attach new habits to existing anchors. The brain builds pathways faster when linked to established ones.',
            ),
            // Science card 2: Neuro Swaps
            _Science(
              icon: Icons.swap_horiz,
              color: const Color(0xFF10B981), // Emerald green.
              title: 'Neuro Swaps',
              body: 'Replace bad habits with urge surfing. Riding the craving is more durable than suppression.',
            ),
            // Science card 3: Comeback Protocol
            _Science(
              icon: Icons.replay_circle_filled,
              color: const Color(0xFFF59E0B), // Amber.
              title: 'Comeback Protocol',
              body: 'Missing a day is normal. The protocol gets you back with zero shame and one small action.',
            ),
          ]
              // Convert list to an indexed map so we have both the item and its
              // index available inside the mapping function.
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 20), // Gap below each card.
                    // e.value is the _Science widget; we animate it with a staggered
                    // delay of 100ms × index so cards appear sequentially.
                    child: e.value.animate(delay: (e.key * 100).ms).fadeIn().slideX(begin: 0.1),
                  )),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── SCIENCE CARD WIDGET ───────────────────────────────────────────────────────

/// _Science is a private widget that renders a single science/feature card.
///
/// Each card has a colored icon badge on the left and a title + body text on
/// the right. Used three times inside _ScienceStep. Extends [StatelessWidget].
class _Science extends StatelessWidget {
  /// The icon to show in the colored badge (e.g. Icons.link).
  final IconData icon;

  /// The accent color used for both the icon itself and the badge background
  /// (at reduced opacity). Each card uses a different color.
  final Color color;

  /// Short name of the feature, displayed in bold (e.g. 'Habit Stacking').
  final String title;

  /// One- or two-sentence explanation of the feature.
  final String body;

  const _Science({required this.icon, required this.color, required this.title, required this.body});

  /// build() returns a horizontal Row with an icon badge and text block.
  @override
  Widget build(BuildContext context) {
    return Row(
      // crossAxisAlignment.start aligns children to the TOP of the row.
      // Without this, the icon would be vertically centered relative to the
      // potentially multi-line text on the right, which looks off.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colored icon badge — same pattern as the logo badge in _WelcomeStep.
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // Very light tint of the card's accent color (15% opacity).
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),

        const SizedBox(width: 16), // Horizontal gap between badge and text.

        Expanded(
          // Expanded here makes the text column take up all the remaining
          // horizontal width after the icon. Without it the text might overflow
          // to the right edge of the screen, especially on narrow devices.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature title — bold, slightly larger than body text.
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4), // Tight gap between title and body.
              // Feature description — smaller, muted color.
              Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
