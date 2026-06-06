// =============================================================================
// dashboard_page.dart
//
// WHAT THIS FILE IS:
//   The main screen of the NeuroSync app — the "home" that users see after
//   logging in. It displays habit stacks, behavior swaps, and activity logs,
//   and orchestrates all the major UI interactions (check-ins, comebacks,
//   milestone celebrations, sharing stats).
//
// ROLE IN THE APP ARCHITECTURE:
//   - Reads app state from `neuroProvider` (defined in providers/neuro_provider.dart)
//   - Delegates rendering to sub-widgets: HabitCard, SwapCard, NeurochemHUD, etc.
//   - Triggers modals: WeeklyCheckinModal, RecalibrationSheet, AddHabitSheet, etc.
//   - Passes computed stats (brain score, streaks) down to display widgets
//   - Sits at the top of the widget tree after authentication; Navigator pushes
//     to UpgradePage when the user taps "Upgrade to Pro"
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   1. Flutter widgets — everything on screen is a "widget" (a reusable UI block).
//      Widgets can be stateless (never change) or stateful (can update themselves).
//   2. Riverpod — the state-management library. Think of it as a global storage
//      that widgets can subscribe to. When stored data changes, subscribed
//      widgets automatically rebuild.
//   3. ConsumerWidget / ConsumerStatefulWidget — Riverpod-aware versions of the
//      standard Flutter widgets. They receive a `ref` object that lets you read
//      or watch Riverpod providers.
//   4. TabController — manages which tab is active in a multi-tab layout.
//   5. Modals — dialogs / bottom sheets that slide over the current screen.
// =============================================================================

// dart:io gives us access to the file system (needed to write the PNG share image).
import 'dart:io';

// dart:typed_data provides ByteData, which holds raw binary data (the PNG bytes).
import 'dart:typed_data';

// dart:ui (aliased as `ui`) is Flutter's low-level rendering engine.
// We use it here to convert a rendered widget into a raster image.
import 'dart:ui' as ui;

// Flutter's Material Design widget library — provides Scaffold, AppBar, TabBar,
// FloatingActionButton, SnackBar, AlertDialog, and almost everything visible.
import 'package:flutter/material.dart';

// Flutter's rendering layer — gives us RenderRepaintBoundary, which lets us
// capture a widget tree as a bitmap (used for the share-image feature).
import 'package:flutter/rendering.dart';

// flutter_animate adds fluid, chainable animations to any widget.
// Example: MyWidget().animate().fadeIn() makes MyWidget fade in on first build.
import 'package:flutter_animate/flutter_animate.dart';

// flutter_riverpod is the state-management library used throughout this app.
// It provides ConsumerWidget, ConsumerStatefulWidget, ref.watch, ref.read, etc.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// path_provider gives us platform-specific temporary/document directories.
// We use getTemporaryDirectory() to save the share PNG before passing it to the OS.
import 'package:path_provider/path_provider.dart';

// share_plus lets us invoke the native iOS/Android share sheet to send files/text.
import 'package:share_plus/share_plus.dart';

// Supabase is the backend-as-a-service used for auth and cloud sync.
// We only import the `Supabase` singleton here (to check if the user is signed in).
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

// App-level Riverpod providers: neuroProvider (all habit state), themeModeProvider,
// milestoneEventProvider, proGateEventProvider, etc.
import '../providers/neuro_provider.dart';

// Data model classes: NeuroStack, NeuroSwap, NeuroLog, CheckinRecord, etc.
import '../models/models.dart';

// Theme helpers — custom extension methods like context.cardBg, context.textSecondary.
import '../theme/app_theme.dart';

// Pure functions for neuroscience logic — e.g. getLocalDateString().
import '../utils/neuro_helpers.dart';

// Pure functions for computing stats — calcBrainScore, getBestStreak, etc.
import '../utils/stats_helpers.dart';

// Pure functions for comeback (habit-recovery) logic — getMissedStacks, etc.
import '../utils/comeback_helpers.dart';

// The recalibration engine analyses check-in history and suggests habit adjustments.
import '../utils/recalibration_engine.dart';

// Widgets imported below are all self-contained UI components.
// Each lives in its own file and is composed here.
import '../widgets/resilience_hud.dart';       // Adaptability Score arc gauge (replaces NeurochemHUD)
import '../utils/resilience_score.dart';       // calcResilienceScore, getResilienceLabel, getResilienceTip
import '../widgets/stats_bar.dart';           // Row of key stats (brain score, streaks, etc.)
import '../widgets/habit_card.dart';          // Card for a single active habit stack
import '../widgets/swap_card.dart';           // Card for a single behavior swap
import '../widgets/comeback_protocol.dart';   // Banner urging the user to "come back" after a miss
import '../widgets/add_habit_sheet.dart';     // Bottom sheet form to add a new habit
import '../widgets/add_swap_sheet.dart';      // Bottom sheet form to add a new swap
import '../widgets/weekly_checkin_modal.dart'; // Weekly mood/energy check-in survey
import '../widgets/recalibration_sheet.dart'; // Suggests habit adjustments based on check-in data
import '../widgets/recovery_playbook.dart';   // Summary of recovery strategies in the Activity tab
import '../widgets/brain_profile_card.dart';  // Shows the user's neuro-archetype profile
import '../widgets/share_card.dart';          // The visual card that gets screenshotted and shared
import '../widgets/year_heatmap_card.dart';   // 52-week GitHub-style recovery heatmap + share button
import '../widgets/freemium_banner.dart';     // Inline strip showing monthly comeback usage for free users
import '../widgets/comeback_gate_modal.dart'; // Modal shown when free-tier comeback limit is reached
import '../widgets/milestone_celebration.dart'; // Rich bottom-toast for myelination milestone events

// The Pro upgrade paywall page; pushed via Navigator.
import 'upgrade_page.dart';

// ---------------------------------------------------------------------------
// CONSTANT
// ---------------------------------------------------------------------------

/// How many days must pass between weekly check-ins before we prompt the user again.
/// Stored as a top-level constant so it is easy to change in one place.
const _checkinIntervalDays = 7;

// =============================================================================
// DashboardPage — the root widget for the main screen
// =============================================================================

/// The primary screen of the NeuroSync app, shown after the user passes
/// onboarding/authentication.
///
/// Extends [ConsumerStatefulWidget] — Riverpod's stateful widget type.
/// "Stateful" means this widget owns mutable state (like `_tabController`
/// and `_checkinShown`) that can change over time, causing a rebuild.
/// "Consumer" means it has access to a `ref` object for reading Riverpod providers.
///
/// Used in: the app's router / Navigator stack as the home route.
class DashboardPage extends ConsumerStatefulWidget {
  /// `super.key` passes the optional `key` parameter up to Flutter's widget
  /// system. Keys help Flutter identify widgets across rebuilds — usually not
  /// needed for top-level pages but is good practice.
  const DashboardPage({super.key});

  /// createState() is required by StatefulWidget. Flutter calls it once to
  /// create the mutable State object that lives alongside this widget.
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

// =============================================================================
// _DashboardPageState — the mutable state for DashboardPage
// =============================================================================

/// Holds all mutable data and logic for [DashboardPage].
///
/// The `with SingleTickerProviderStateMixin` part makes this class a "ticker
/// provider" — meaning it can supply animation timing signals to widgets like
/// [TabController] that need to animate transitions. Without this mixin,
/// creating a TabController would throw an error.
class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {

  /// Controls which of the three tabs (Habits / Swaps / Activity) is currently
  /// selected, and animates transitions between them.
  /// `late final` means: declared now, assigned once in initState(), never
  /// reassigned. Dart will throw if you try to read it before assignment.
  late final TabController _tabController;

  /// Guards against showing the weekly check-in modal more than once per
  /// app session, even if the user navigates away and back.
  bool _checkinShown = false;

  // ---------------------------------------------------------------------------
  // Lifecycle methods — Flutter calls these automatically
  // ---------------------------------------------------------------------------

  /// Called once when this State object is first inserted into the widget tree.
  /// Think of it as a constructor for your stateful logic.
  /// Always call `super.initState()` first — that sets up Flutter internals.
  @override
  void initState() {
    super.initState(); // Required — must be first line

    // Create the TabController for 3 tabs. `vsync: this` provides the ticker
    // timing we set up with SingleTickerProviderStateMixin.
    _tabController = TabController(length: 3, vsync: this);

    // addPostFrameCallback schedules _checkCheckin() to run AFTER the first
    // frame is painted. We defer it because showModalBottomSheet can't be
    // called during the widget's build phase — the frame must be complete first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCheckin());
  }

  /// Called when this State object is permanently removed from the tree.
  /// Always dispose resources here to prevent memory leaks.
  @override
  void dispose() {
    _tabController.dispose(); // Frees the animation ticker
    super.dispose(); // Required — must be last line
  }

  // ---------------------------------------------------------------------------
  // Check-in logic
  // ---------------------------------------------------------------------------

  /// Decides whether to show the weekly check-in modal.
  /// Does nothing if the check-in was already shown this session, or if not
  /// enough days have passed since the last check-in.
  void _checkCheckin() {
    if (_checkinShown) return; // Already shown this session — bail out

    // ref.read() reads the current value of neuroProvider without subscribing
    // to future changes (unlike ref.watch, which would cause rebuilds).
    final state = ref.read(neuroProvider);

    // If the user has never done a check-in, show it immediately.
    if (state.lastCheckinDate == null) { _showCheckin(); return; }

    // DateTime.parse() converts an ISO-8601 date string (e.g. "2026-05-22")
    // into a Dart DateTime object. `.difference()` gives a Duration.
    final daysSince = DateTime.now()
        .difference(DateTime.parse(state.lastCheckinDate!)) // `!` asserts non-null (we checked above)
        .inDays;

    // Only prompt if enough days have elapsed since the last check-in.
    if (daysSince >= _checkinIntervalDays) _showCheckin();
  }

  /// Shows the [WeeklyCheckinModal] as a bottom sheet after a 1-second delay
  /// (gives the dashboard time to fully appear before interrupting the user).
  /// If the user completes the check-in, follows up with recalibration logic.
  void _showCheckin() {
    // Mark the flag immediately so nothing else triggers a second modal.
    setState(() => _checkinShown = true);

    // Future.delayed returns a Future that resolves after the given Duration.
    // The callback runs on the main thread after 1 second.
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return; // `mounted` is false if the widget was disposed while waiting

      // showModalBottomSheet slides a panel up from the bottom of the screen.
      // `isScrollControlled: true` allows the sheet to grow taller than 50% of the screen.
      // `backgroundColor: Colors.transparent` lets the sheet widget draw its own rounded background.
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const WeeklyCheckinModal(), // The widget drawn inside the sheet
      ).then((record) {
        // `.then()` runs when the bottom sheet is dismissed.
        // `record` is whatever value was passed to `Navigator.pop(context, value)` inside the modal.
        // We check if it is a CheckinRecord (the modal can also be dismissed with null).
        if (record is CheckinRecord && mounted) _checkRecalibration(record);
      });
    });
  }

  /// After a check-in is completed, runs the recalibration engine to detect
  /// patterns and, if suggestions exist, shows the [RecalibrationSheet].
  ///
  /// [record] — the CheckinRecord submitted by the user; passed to the engine
  ///            for analysis (though the engine also uses full history).
  void _checkRecalibration(CheckinRecord record) {
    final state = ref.read(neuroProvider); // Read current state (no subscription)

    // runRecalibration analyses habit stacks, check-in history, and the user's
    // brain profile to produce a list of suggested changes.
    final suggestions = runRecalibration(
      state.stacks,
      state.checkinHistory,
      state.brainProfile,
    );

    if (suggestions.isEmpty) return; // Nothing to suggest — silently exit

    // Show the recalibration recommendations in a bottom sheet.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecalibrationSheet(suggestions: suggestions),
    );
  }

  // ---------------------------------------------------------------------------
  // Milestone celebration
  // ---------------------------------------------------------------------------

  /// Shows the rich [MilestoneCelebration] overlay for a myelination milestone.
  /// Called when [milestoneEventProvider] fires a non-null event.
  ///
  /// [habitTitle] — the name of the habit that hit a milestone (e.g. "Morning Run")
  /// [milestone]  — the percentage milestone reached (10 / 25 / 50 / 75 / 100)
  void _showMilestoneCelebration(String habitTitle, int milestone) {
    showMilestoneCelebration(context, habitTitle: habitTitle, milestone: milestone);
  }

  /// Shows the [ComebackGateModal] when the user taps the locked comeback banner.
  void _showComebackGate(int used) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => ComebackGateModal(
        used: used,
        onUpgrade: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradePage()),
        ),
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pro upgrade gate
  // ---------------------------------------------------------------------------

  /// Shows an [AlertDialog] explaining a feature requires Pro, with a button
  /// to upgrade.  Currently the upgrade is simulated (no real Stripe paywall yet).
  ///
  /// [message] — the human-readable explanation of why Pro is needed.
  void _showProGate(String message) {
    // showDialog overlays a modal dialog in the center of the screen.
    // It returns a Future that resolves to whatever Navigator.pop passes back.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF6366F1)), // Brain icon
            const SizedBox(width: 8),
            const Text('Upgrade to Pro'),
          ],
        ),
        content: Text(message), // Display the reason for the gate
        actions: [
          // "Not now" dismisses the dialog without upgrading
          TextButton(
            onPressed: () => Navigator.pop(context), // Pop removes the dialog from the stack
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog first
              // TODO: launch Stripe paywall when Stripe is integrated
              // For now, just flip the isPro flag in local state as a simulation.
              ref.read(neuroProvider.notifier).upgradeToPro();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pro unlocked! (Stripe coming soon)')),
              );
            },
            // styleFrom creates a ButtonStyle from simple parameters
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Upgrade — \$9/mo'), // `\$` escapes the dollar sign in a string
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build() — describes the widget tree for this screen
  // ---------------------------------------------------------------------------

  /// Flutter calls build() every time this widget needs to redraw.
  /// It MUST be pure — read state, return widgets, no side effects here.
  /// Side effects (showing dialogs, etc.) happen in callbacks and ref.listen.
  @override
  Widget build(BuildContext context) {

    // -------------------------------------------------------------------------
    // RIVERPOD SIDE-EFFECT LISTENERS
    // ref.listen() is like ref.watch() but instead of triggering a rebuild,
    // it calls a callback when the watched value changes. Ideal for one-time
    // events like showing a SnackBar or dialog.
    // -------------------------------------------------------------------------

    // Listen for milestone celebration events.
    // The provider type `(String, int)?` is a Dart *record* (tuple) — a lightweight
    // pair of values. `$1` is the String (habit title), `$2` is the int (milestone %).
    // The `?` means the value can be null (null = no pending event).
    ref.listen<(String, int)?>(milestoneEventProvider, (_, event) {
      if (event != null && mounted) {
        _showMilestoneCelebration(event.$1, event.$2); // Unpack the record fields
        // After showing the snackbar, reset the event to null on the next frame
        // so it doesn't fire again on the next rebuild.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(milestoneEventProvider.notifier).state = null;
          // `.notifier` gives us write-access to the StateProvider.
          // `.state = null` clears the event.
        });
      }
    });

    // Listen for Pro-gate events (when a non-pro user tries a Pro feature).
    ref.listen<String?>(proGateEventProvider, (_, message) {
      if (message != null && mounted) {
        _showProGate(message);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(proGateEventProvider.notifier).state = null;
        });
      }
    });

    // -------------------------------------------------------------------------
    // READ STATE
    // ref.watch() subscribes this widget to neuroProvider — every time the
    // NeuroState changes (habit completed, streak updated, etc.), Flutter will
    // call build() again so the UI reflects the new data.
    // -------------------------------------------------------------------------
    final state = ref.watch(neuroProvider);

    // Filter to only habits that are currently active (not archived).
    // `.where()` returns an Iterable of elements that satisfy the test.
    // `.toList()` materialises it into a growable List.
    final activeStacks = state.stacks.where((s) => s.isActive).toList();

    // Get today's date as a "YYYY-MM-DD" string (used to check completion status).
    final today = getLocalDateString(DateTime.now());

    // Get IDs of habits the user has already "come back to" today, so we don't
    // re-prompt them in the Comeback banner.
    // Note: ref.read (not watch) because this is a one-time read at build time;
    // we don't need to rebuild if this changes mid-render.
    final todayComebacks = ref.read(neuroProvider.notifier).getTodayComebackIds();

    // Habits that were missed AND not yet recovered today.
    final missedStacks = getMissedStacks(activeStacks, todayComebacks);

    // How many comeback actions the user has logged this calendar month.
    final camebacksThisMonth = getComebacksThisMonth(state.comebacks);

    // Free users get 3 comeback actions per month; Pro users get unlimited.
    final canShowComeback = state.isPro || camebacksThisMonth < 3;

    // Derived stats displayed in the StatsBar.
    final comebackStreak = getComebackStreak(state.comebacks);
    final bestStreak     = getBestStreak(state.stacks);
    final recoveryRate   = calcRecoveryRate(state.comebacks);

    // Adaptability Score — the proprietary resilience metric.
    final resilienceScore = calcResilienceScore(
      state.comebacks,
      state.swaps,
      state.stacks,
      state.checkinHistory,
    );
    final resilienceLabel = getResilienceLabel(resilienceScore);
    final resilienceTip   = getResilienceTip(resilienceScore, state.brainProfile);

    // 52-week grid passed to the Activity tab's YearHeatmapCard.
    final yearGrid = getYearGrid(state.stacks, state.comebacks);
    final archetypeName = state.brainProfile != null ? _archetypeName(state.brainProfile!) : null;

    // -------------------------------------------------------------------------
    // WIDGET TREE
    // Scaffold is the standard full-screen layout widget. It provides AppBar,
    // body, and FloatingActionButton slots.
    // -------------------------------------------------------------------------
    return Scaffold(
      // ------------------------------------------------------------------
      // AppBar — the top navigation bar
      // ------------------------------------------------------------------
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show a personalised greeting if the user has set their name,
            // otherwise fall back to the app name.
            // `.isNotEmpty` is true when the string has at least one character.
            // `?.copyWith()` — the `?` is null-safe access: if textTheme.titleMedium
            // is null, the whole expression returns null instead of crashing.
            Text(
              state.userProfile.name.isNotEmpty
                  ? 'Hey, ${state.userProfile.name}'
                  : 'NeuroSync',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // A small subtitle showing "Good morning / afternoon / evening"
            Text(
              _dayGreeting(),
              style: TextStyle(fontSize: 12, color: context.textSecondary),
              // `context.textSecondary` is a custom extension getter defined in app_theme.dart
            ),
          ],
        ),
        actions: [
          // ----------------------------------------------------------------
          // Dopamine points badge (top-right pill)
          // ----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                // `.withOpacity()` creates a copy of the colour with reduced transparency (0.0–1.0)
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20), // Makes it pill-shaped
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFF6366F1), size: 14), // Lightning bolt icon
                  const SizedBox(width: 4),
                  Text(
                    '${state.dopaminePoints}', // Convert int to string via interpolation
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Share stats button
          // ----------------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share your stats', // Long-press hint on iOS/Android
            onPressed: () => _showShareSheet(
              context,
              stacks: state.stacks,
              comebacks: state.comebacks,
              recoveryRate: recoveryRate,
              bestStreak: bestStreak,
              archetypeName: state.brainProfile != null
                  ? _archetypeName(state.brainProfile!)
                  : null,
              userName: state.userProfile.name,
            ),
          ),

          // ----------------------------------------------------------------
          // Upgrade to Pro button
          // ----------------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'Upgrade to Pro',
            // Navigator.push adds a new route on top of the current one (like
            // pushing a page onto a stack). MaterialPageRoute wraps a widget as
            // a navigable page with a default slide transition.
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpgradePage()),
            ),
          ),

          // ----------------------------------------------------------------
          // Dark/light mode toggle
          // ----------------------------------------------------------------
          IconButton(
            // ref.watch inside actions is fine — this widget rebuilds whenever
            // themeModeProvider changes, so the icon stays in sync.
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode   // Currently dark → show sun icon to switch to light
                  : Icons.dark_mode,   // Currently light → show moon icon to switch to dark
            ),
            onPressed: () {
              // ref.read (not watch) in callbacks — we only need the current value,
              // not a subscription. `.notifier.state =` writes a new value to a StateProvider.
              ref.read(themeModeProvider.notifier).state =
                  ref.read(themeModeProvider) == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),

          // Sign-out button (shown only when Supabase auth is active)
          _SignOutButton(),
        ],
      ),

      // ------------------------------------------------------------------
      // body — the main scrollable area below the AppBar
      // ------------------------------------------------------------------
      body: Column(
        children: [
          // Top section: HUD + stats bar + optional comeback banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), // left, top, right, bottom
            child: Column(
              children: [
                // ResilienceHUD shows the user's Adaptability Score arc gauge.
                // `.animate().fadeIn()` — flutter_animate chain: widget fades from
                // transparent to opaque when first rendered.
                ResilienceHUD(
                  score: resilienceScore,
                  label: resilienceLabel,
                  tip: resilienceTip,
                ).animate().fadeIn(),

                const SizedBox(height: 12), // Vertical spacer of 12 logical pixels

                // StatsBar shows resilience score, comeback streak, best streak, recovery rate.
                StatsBar(
                  resilienceScore: resilienceScore,
                  comebackStreak: comebackStreak,
                  bestStreak: bestStreak,
                  recoveryRate: recoveryRate,
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 12),

                // FreemiumBanner — invisible for Pro users; shows monthly comeback
                // usage for free-tier users. Tapping "Upgrade" navigates to UpgradePage.
                FreemiumBanner(
                  comebacksThisMonth: camebacksThisMonth,
                  isPro: state.isPro,
                  onUpgrade: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradePage()),
                  ),
                ),

                if (!state.isPro && camebacksThisMonth >= 3)
                  const SizedBox(height: 12),

                // ComebackProtocolBanner — visible when the user can act on comebacks.
                // When the monthly free limit is hit AND there are missed habits,
                // show the banner in "locked" state that opens the gate modal on tap.
                if (missedStacks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (canShowComeback)
                    ComebackProtocolBanner(missedStacks: missedStacks)
                  else
                    _LockedComebackBanner(
                      onTap: () => _showComebackGate(camebacksThisMonth),
                    ),
                ],
              ],
            ),
          ),

          // TabBar renders the three labelled tab buttons (Habits / Swaps / Activity).
          // It is linked to _tabController so tapping a tab updates the view.
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Habits'),
              Tab(text: 'Swaps'),
              Tab(text: 'Activity'),
            ],
          ),

          // Expanded makes the TabBarView fill all remaining vertical space.
          // Without it, Flutter would complain that the TabBarView has unbounded height.
          Expanded(
            child: TabBarView(
              controller: _tabController, // Must match the TabBar's controller
              children: [
                // Tab 0 — Habits
                _HabitsTab(
                  stacks: state.stacks,     // All habits (active + archived)
                  comebacks: state.comebacks,
                  today: today,
                ),

                // Tab 1 — Swaps (only active swaps)
                // `.where().toList()` filters out archived swaps inline
                _SwapsTab(swaps: state.swaps.where((s) => s.isActive).toList()),

                // Tab 2 — Activity feed + brain profile + playbook
                _ActivityTab(
                  logs: state.logs,
                  stacks: state.stacks,
                  comebacks: state.comebacks,
                  swaps: state.swaps,
                  brainProfile: state.brainProfile,
                  yearGrid: yearGrid,
                  resilienceScore: resilienceScore,
                  comebackStreak: comebackStreak,
                  archetypeName: archetypeName,
                ),
              ],
            ),
          ),
        ],
      ),

      // FAB (Floating Action Button) — the + button in the bottom-right corner.
      // We call a builder method so the FAB can change based on the active tab.
      floatingActionButton: _buildFab(context, state),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: map a BrainProfile to a human-readable archetype name
  // ---------------------------------------------------------------------------

  /// Maps a [NeuroBrainProfile] combination of failureStyle + coreDriver to a
  /// descriptive archetype label like "The Systems Optimizer".
  ///
  /// [p] — the user's brain profile.
  /// Returns the archetype name String, or a default if the key is not found.
  ///
  /// `static` means this method belongs to the class, not a specific instance —
  /// it cannot access `this`, `ref`, or any instance fields.
  static String _archetypeName(NeuroBrainProfile p) {
    // A const Map literal — the key is "failureStyle-coreDriver" (both enum .name values),
    // and the value is the user-friendly archetype label.
    const names = {
      'perfectionist-feelBetter':    'The Exhausted Achiever',
      'perfectionist-performBetter': 'The Precision Driver',
      'perfectionist-becomeSomeone': 'The Identity Builder',
      'perfectionist-survive':       'The Cornered Perfectionist',
      'avoider-feelBetter':          'The Comfort Seeker',
      'avoider-performBetter':       'The Quiet Competitor',
      'avoider-becomeSomeone':       'The Reluctant Transformer',
      'avoider-survive':             'The Minimal Risk-Taker',
      'analyst-feelBetter':          'The Thoughtful Healer',
      'analyst-performBetter':       'The Systems Optimizer',
      'analyst-becomeSomeone':       'The Deliberate Builder',
      'analyst-survive':             'The Calculated Survivor',
      'drifter-feelBetter':          'The Restless Dreamer',
      'drifter-performBetter':       'The Inconsistent Sprinter',
      'drifter-becomeSomeone':       'The Aspiring Self',
      'drifter-survive':             'The Day-to-Day Navigator',
    };

    // Construct the lookup key from the enum `.name` property (returns the
    // enum value name as a lowercase String, e.g. `FailureStyle.analyst` → "analyst").
    // `?? 'The Recovery Builder'` is the null-coalescing operator:
    // if the map lookup returns null (key not found), use this fallback instead.
    return names['${p.failureStyle.name}-${p.coreDriver.name}'] ?? 'The Recovery Builder';
  }

  // ---------------------------------------------------------------------------
  // Helper: open the share bottom sheet
  // ---------------------------------------------------------------------------

  /// Opens a [_ShareSheet] bottom sheet so the user can export a stats card as a PNG.
  void _showShareSheet(
    BuildContext context, {
    required List<NeuroStack> stacks,
    required List<ComebackRecord> comebacks,
    required double recoveryRate,
    required int bestStreak,
    String? archetypeName,
    String userName = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        stacks: stacks,
        comebacks: comebacks,
        recoveryRate: recoveryRate,
        bestStreak: bestStreak,
        archetypeName: archetypeName,
        userName: userName,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: time-of-day greeting
  // ---------------------------------------------------------------------------

  /// Returns a greeting string appropriate for the current hour.
  /// Used as the subtitle under the user's name in the AppBar.
  String _dayGreeting() {
    final hour = DateTime.now().hour; // 0–23 integer
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ---------------------------------------------------------------------------
  // Helper: build the Floating Action Button (FAB)
  // ---------------------------------------------------------------------------

  /// Returns the appropriate FAB for the currently selected tab, or an
  /// invisible widget when on the Activity tab (which needs no FAB).
  ///
  /// [context] — the build context (needed for showModalBottomSheet).
  /// [state]   — the current NeuroState (passed in but not used directly here;
  ///             available for future gating logic).
  /// Returns a Widget (FloatingActionButton or SizedBox.shrink).
  Widget? _buildFab(BuildContext context, NeuroState state) {
    // AnimatedBuilder rebuilds its `builder` callback every time the given
    // `animation` emits a new value. We pass `_tabController` (which is also
    // an Animation) so the FAB is recreated whenever the user switches tabs.
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        // SizedBox.shrink() is a zero-size invisible widget — Flutter's idiomatic
        // way to render "nothing" when a widget slot must return something.
        if (_tabController.index == 2) return const SizedBox.shrink();

        return FloatingActionButton(
          onPressed: () {
            // Show the correct add-sheet depending on which tab is active.
            if (_tabController.index == 0) {
              // Tab 0 (Habits) → open the add-habit form
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddHabitSheet(),
              );
            } else {
              // Tab 1 (Swaps) → open the add-swap form
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddSwapSheet(),
              );
            }
          },
          backgroundColor: const Color(0xFF6366F1), // Indigo brand colour
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }
}

// =============================================================================
// _HabitsTab — the "Habits" tab content
// =============================================================================

/// Displays active habit cards and a collapsible archived-habits section.
///
/// Extends [ConsumerStatefulWidget] because it needs:
///   - State: `_showArchived` toggle (stateful)
///   - `ref`: to call notifier methods when the user taps Archive / Restore
///
/// Private (prefixed with `_`) because it is only used inside this file.
class _HabitsTab extends ConsumerStatefulWidget {
  /// All habit stacks (both active and archived) passed from the parent.
  final List<NeuroStack> stacks;

  /// All comeback records (used by HabitCard to show comeback history).
  final List<ComebackRecord> comebacks;

  /// Today's date as "YYYY-MM-DD" string, used to determine if a habit was
  /// already completed today.
  final String today;

  const _HabitsTab({
    required this.stacks,
    required this.comebacks,
    required this.today,
  });

  @override
  ConsumerState<_HabitsTab> createState() => _HabitsTabState();
}

/// State for [_HabitsTab].
class _HabitsTabState extends ConsumerState<_HabitsTab> {

  /// Whether the archived-habits section is currently expanded.
  /// Starts collapsed (false). Toggled by tapping the archive header row.
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    // Split widget.stacks into active and archived lists for separate rendering.
    // `widget.` is how a State accesses its parent widget's properties.
    final active   = widget.stacks.where((s) => s.isActive).toList();
    final archived = widget.stacks.where((s) => !s.isActive).toList(); // `!` negates the bool

    // Empty state — shown when the user has no habits at all yet.
    if (active.isEmpty && archived.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Vertically centre the column
          children: [
            const Icon(Icons.psychology_outlined, size: 48, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            Text('No habits yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first habit',
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    // ListView renders a scrollable list. `padding` adds inset space.
    // The bottom padding of 100 leaves room above the FAB.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [

        // ── Active habits ──────────────────────────────────────────────────
        // `.asMap()` converts the list to a Map<int, NeuroStack> so we get
        // both the index (e.key) and the value (e.value) in the map callback.
        // The spread operator `...` inserts all items from the iterable into
        // the parent list (flattens one level).
        ...active.asMap().entries.map((e) {
          final stack = e.value;

          // Check if the user already completed this habit today.
          // `.contains()` returns true if the Set/List has the given element.
          final completedToday = stack.completions.contains(widget.today);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitCard(
              stack: stack,
              comebacks: widget.comebacks,
              completedToday: completedToday,
              onComplete: () => ref.read(neuroProvider.notifier).completeNeuroStack(stack.id),
              onArchive:  () => ref.read(neuroProvider.notifier).archiveNeuroStack(stack.id),
              onLiteMode: () => ref.read(neuroProvider.notifier).activateLiteMode(stack.id),
            )
            // Stagger the entrance animations: each card delays by 60ms × its index.
            // `e.key` is the 0-based position of this card in the list.
            .animate(delay: (e.key * 60).ms).fadeIn().slideY(begin: 0.05),
            // `slideY(begin: 0.05)` makes the card slide up from 5% below its
            // final position — a subtle entrance motion.
          );
        }),

        // ── Archived section ───────────────────────────────────────────────
        // `if (archived.isNotEmpty) ...[...]` — collection-if with a spread:
        // only adds these widgets to the list when there is at least one
        // archived habit.
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 8),

          // Tappable header row that toggles the archived list visibility.
          GestureDetector(
            // `setState()` calls Flutter's rebuild scheduler.
            // Anything changed inside the callback will be reflected on-screen.
            onTap: () => setState(() => _showArchived = !_showArchived),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 16, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Archived (${archived.length})', // Show count in the label
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(), // Pushes the chevron icon to the far right
                  // Ternary chooses up or down chevron based on expansion state
                  Icon(
                    _showArchived ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Only render archived items when the section is expanded.
          if (_showArchived) ...[
            const SizedBox(height: 8),
            // `.map()` transforms each NeuroStack into a Padding widget.
            // The outer spread `...` inlines the resulting widgets into the list.
            ...archived.map((stack) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  // `.withOpacity(0.6)` makes the archived card slightly transparent
                  // to visually distinguish it from active habits.
                  color: context.cardBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stack.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          // `.round()` rounds the double myelinationLevel to the nearest int.
                          Text(
                            '${stack.streak}d streak · ${stack.myelinationLevel.round()}% pathway',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Restore button — moves the habit back to the active list.
                    TextButton(
                      onPressed: () => ref.read(neuroProvider.notifier).unarchiveNeuroStack(stack.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero, // Allow button to be very compact
                      ),
                      child: const Text(
                        'Restore',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ],
    );
  }
}

// =============================================================================
// _SwapsTab — the "Swaps" tab content
// =============================================================================

/// Displays the list of active behavior swaps (replacing bad habits with good ones).
///
/// Extends [ConsumerWidget] — Riverpod's *stateless* consumer widget.
/// Unlike ConsumerStatefulWidget, there is no mutable state here;
/// `ref` is provided as a parameter to `build()` instead of being a field.
///
/// Private — only used inside this file.
class _SwapsTab extends ConsumerWidget {
  /// The filtered list of active swaps (archived ones are excluded before
  /// this widget is created, in [DashboardPage.build]).
  final List<NeuroSwap> swaps;

  const _SwapsTab({required this.swaps});

  /// [ref] is the Riverpod WidgetRef — use it for ref.read() inside callbacks.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Empty state — shown when the user has added no swaps yet.
    if (swaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz, size: 48, color: Color(0xFF10B981)), // Green swap icon
            const SizedBox(height: 16),
            Text('No swaps yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap + to replace a bad habit',
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    // ListView.separated builds a scrollable list where each pair of items is
    // separated by the widget returned from `separatorBuilder`.
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: swaps.length, // Total number of items
      // `_` and `__` are placeholder variable names — the separator doesn't need
      // the context or index, so we use underscores by convention.
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final swap = swaps[i]; // Look up the swap at position i
        return SwapCard(
          swap: swap,
          onUrgeSurf: () => ref.read(neuroProvider.notifier).logUrgeSurf(swap.id),
          onSlip:     () => ref.read(neuroProvider.notifier).logSlip(swap.id),
          onDelete:   () => ref.read(neuroProvider.notifier).archiveNeuroSwap(swap.id),
        ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.05); // Staggered entrance
      },
    );
  }
}

// =============================================================================
// _ActivityTab — the "Activity" tab content
// =============================================================================

/// Displays the Recovery Playbook, the Brain Profile card, and a chronological
/// activity log of completions, slips, urge surfs, and comebacks.
///
/// Extends plain [StatelessWidget] — no Riverpod needed here because all data
/// is passed in as constructor parameters from the parent.
///
/// Private — only used inside this file.
class _ActivityTab extends StatelessWidget {
  /// All activity log entries (completions, slips, urge surfs, comebacks).
  final List<NeuroLog> logs;

  /// All habit stacks (used by RecoveryPlaybook and YearHeatmapCard).
  final List<NeuroStack> stacks;

  /// All comeback records (used by RecoveryPlaybook and YearHeatmapCard).
  final List<ComebackRecord> comebacks;

  /// All swap records (used by RecoveryPlaybook).
  final List<NeuroSwap> swaps;

  /// The user's brain profile, or null if they haven't taken the assessment.
  final NeuroBrainProfile? brainProfile;

  /// 52-week heatmap grid for YearHeatmapCard.
  final List<List<HeatmapDay>> yearGrid;

  /// Adaptability Score (0–1000) for the share text.
  final int resilienceScore;

  /// Current comeback streak for the share text.
  final int comebackStreak;

  /// Archetype name for the share text (e.g. "The Resilient Analyst"), or null.
  final String? archetypeName;

  const _ActivityTab({
    required this.logs,
    required this.stacks,
    required this.comebacks,
    required this.swaps,
    required this.brainProfile,
    required this.yearGrid,
    required this.resilienceScore,
    required this.comebackStreak,
    this.archetypeName,
  });

  @override
  Widget build(BuildContext context) {
    // CustomScrollView is a scrollable area that can contain "slivers" —
    // scroll-aware widgets. It gives us finer control than ListView when we
    // need to mix different content types (sticky headers, lists, etc.).
    return CustomScrollView(
      slivers: [

        // SliverPadding wraps a sliver with uniform padding.
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          // SliverToBoxAdapter lets you put a regular (non-sliver) widget
          // inside a CustomScrollView.
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // The Recovery Playbook summarises recovery patterns and tips.
                RecoveryPlaybook(stacks: stacks, comebacks: comebacks, swaps: swaps),

                const SizedBox(height: 16),

                // Year heatmap — GitHub-style 52-week recovery grid with share button.
                YearHeatmapCard(
                  weeks: yearGrid,
                  resilienceScore: resilienceScore,
                  comebackStreak: comebackStreak,
                  archetype: archetypeName,
                ),

                // Only show the brain profile card if the user has taken the assessment.
                // `...[...]` is a spread inside a collection-if — inserts the
                // list of widgets when the condition is true.
                if (brainProfile != null) ...[
                  const SizedBox(height: 16),

                  // Consumer is a lightweight Riverpod widget that gives access to
                  // `ref` inside a StatelessWidget without converting the whole
                  // class to ConsumerWidget. Useful for one-off ref.read calls.
                  Consumer(
                    builder: (context, ref, _) => BrainProfileCard(
                      profile: brainProfile!, // `!` asserts non-null (we checked above)
                      onRetake: () {
                        // Tell the provider about the current profile (so it is
                        // available when the user navigates to BrainAssessmentPage).
                        ref.read(neuroProvider.notifier).setBrainProfile(brainProfile!);
                        // TODO: navigate to BrainAssessmentPage for retake
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Retake: navigate to Brain Assessment (coming soon)'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // If there are no log entries, render an empty fill sliver so the
        // CustomScrollView still fills the screen correctly.
        if (logs.isEmpty)
          const SliverFillRemaining(child: SizedBox.shrink())
        else ...[

          // "Recent Activity" section header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // SliverList is the scroll-aware equivalent of ListView inside a
          // CustomScrollView. SliverChildBuilderDelegate lazily builds list
          // items on demand (only renders items that are visible on screen),
          // which is efficient for long lists.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _LogItem(log: logs[i])
                    .animate(delay: (i * 40).ms).fadeIn(), // Stagger each row 40ms apart
                childCount: logs.length, // Total number of items to build
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// _LogItem — a single row in the activity log
// =============================================================================

/// Renders one [NeuroLog] entry as a card with an icon, title, label, and
/// optional dopamine change value.
///
/// Extends [StatelessWidget] — receives all its data via the constructor,
/// never needs to update itself independently.
///
/// Private — only used inside this file.
class _LogItem extends StatelessWidget {
  /// The log entry to display.
  final NeuroLog log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {

    // Dart's switch expression (introduced in Dart 3) returns a value based on
    // a pattern match. Here we destructure a *record* (a fixed-size tuple of
    // values) from each branch: (IconData icon, Color color, String label).
    // The `(icon, color, label)` on the left is called a *record pattern* —
    // it declares three variables and assigns them in one expression.
    final (icon, color, label) = switch (log.type) {
      LogType.completion => (Icons.check_circle,        const Color(0xFF10B981), 'Completed'),   // Green check
      LogType.urgeSurf   => (Icons.waves,               const Color(0xFF3B82F6), 'Urge Surfed'), // Blue waves
      LogType.slip       => (Icons.warning_amber,       const Color(0xFFEF4444), 'Slip'),         // Red warning
      LogType.comeback   => (Icons.replay_circle_filled, const Color(0xFFF59E0B), 'Comeback'),   // Amber replay
    };

    // Parse the ISO-8601 timestamp string into a DateTime object.
    // `DateTime.tryParse` returns null if the string is invalid (safe parse).
    final time = DateTime.tryParse(log.timestamp);

    // Format as HH:MM, padding with leading zeros so single-digit hours look right.
    // If parsing failed, fall back to an empty string.
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            // Circular icon badge with a tinted background
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), // Lightly tinted background
                shape: BoxShape.circle,          // Makes the container a circle
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),

            // Title + log type label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.itemTitle, // e.g. "Morning Run"
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    label,         // e.g. "Completed", "Slip"
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),

            // Right-side: dopamine change + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Only show the dopamine badge when the change is positive.
                // `> 0` compares the int to zero.
                if (log.dopamineChange > 0)
                  Text(
                    '+${log.dopamineChange} DA', // e.g. "+10 DA"
                    style: const TextStyle(
                      color: Color(0xFFF59E0B), // Amber
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 10, color: context.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ShareSheet — bottom sheet that previews and exports the stats card as PNG
// =============================================================================

/// A modal bottom sheet that shows the user a preview of their shareable
/// Recovery Heatmap card, then captures it as a PNG image and invokes the
/// native share sheet.
///
/// Private — only used inside this file.
class _ShareSheet extends StatefulWidget {
  /// All habit stacks — used to compute the 28-day heatmap grid.
  final List<NeuroStack> stacks;

  /// All comeback records — highlighted gold in the heatmap.
  final List<ComebackRecord> comebacks;

  /// Recovery rate percentage (0–100 range as double).
  final double recoveryRate;

  /// The longest single habit streak the user has ever achieved.
  final int bestStreak;

  /// Optional archetype name. Null if the user hasn't taken the brain assessment.
  final String? archetypeName;

  /// The user's display name (empty string if not set).
  final String userName;

  const _ShareSheet({
    required this.stacks,
    required this.comebacks,
    required this.recoveryRate,
    required this.bestStreak,
    this.archetypeName,
    this.userName = '',
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

/// State for [_ShareSheet].
class _ShareSheetState extends State<_ShareSheet> {

  /// A GlobalKey uniquely identifies a widget in the tree so we can access
  /// its RenderObject later. Here we use it to find the RepaintBoundary widget
  /// and capture it as a bitmap.
  final _cardKey = GlobalKey();

  /// True while the capture-and-share async operation is in progress.
  /// Used to show a loading spinner on the button.
  bool _capturing = false;

  // ---------------------------------------------------------------------------
  // Capture and share
  // ---------------------------------------------------------------------------

  /// Renders the [ShareCard] widget to a PNG file and opens the native share sheet.
  ///
  /// This is an `async` function — it contains `await` expressions.
  /// `async` functions return a `Future`, letting callers await them too.
  Future<void> _captureAndShare() async {
    // setState triggers a rebuild, switching the button to its loading state.
    setState(() => _capturing = true);

    // try/catch/finally — if any `await` throws, we jump to `catch`.
    // `finally` always runs whether or not there was an error.
    try {
      // Wait one frame so the RepaintBoundary is fully laid out at its
      // natural size before we try to rasterise it.
      // `await` pauses this function until the Future resolves.
      await Future.delayed(const Duration(milliseconds: 50));

      // `_cardKey.currentContext` is the BuildContext of the widget with this key.
      // `findRenderObject()` returns the RenderObject (the layout/paint node).
      // We cast it to RenderRepaintBoundary with `as` — throws if wrong type.
      // The `?` makes the whole expression null-safe (null if widget was disposed).
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return; // Widget not in the tree — nothing to capture

      // `toImage()` rasterises the boundary into a ui.Image.
      // `pixelRatio: 3.0` captures at 3× device resolution for a crisp image.
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // `toByteData()` encodes the image as PNG raw bytes.
      // Returns null if encoding fails.
      final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      // Get the platform's temporary directory — a scratch space for ephemeral files.
      final dir = await getTemporaryDirectory();

      // Create a File object at the desired path.
      final file = File('${dir.path}/neurosync_stats.png');

      // `.buffer.asUint8List()` converts ByteData to a List<int> that File.writeAsBytes accepts.
      await file.writeAsBytes(bytes.buffer.asUint8List());

      // Invoke the native iOS/Android share sheet with the PNG file attached.
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')], // XFile wraps a file path + MIME type
        text: 'My NeuroSync recovery stats 🧠',    // Optional accompanying text
      );

      // Dismiss the bottom sheet after sharing.
      // `mounted` is false if the widget was disposed while we were awaiting —
      // checking it prevents calling Navigator on a dead context.
      if (mounted) Navigator.pop(context);

    } catch (e) {
      // `e` is the caught exception. Show it to the user as a SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture image: $e')),
        );
      }
    } finally {
      // Always reset the loading spinner, even if an error occurred.
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Match the app background
        // Rounded top corners only — bottom corners stay sharp against the screen edge.
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Sheet only as tall as its content
        children: [

          // ── Handle bar (decorative pill at the top of the sheet) ──────────
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Share your stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ── Card preview ──────────────────────────────────────────────────
          // RepaintBoundary isolates this subtree from the rest of the render
          // tree, which (a) improves performance by preventing unnecessary
          // repaints, and (b) gives us a clean capture boundary.
          // `key: _cardKey` lets us locate this specific RenderObject later.
          Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: ShareCard(
                stacks: widget.stacks,
                comebacks: widget.comebacks,
                recoveryRate: widget.recoveryRate,
                bestStreak: widget.bestStreak,
                archetypeName: widget.archetypeName,
                userName: widget.userName,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Share button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, // Stretch button to full sheet width
            child: FilledButton.icon(
              // `null` onPressed disables the button (shows it as greyed out)
              // while the capture is in progress.
              onPressed: _capturing ? null : _captureAndShare,
              icon: _capturing
                  // Show a small circular progress indicator inside the button while busy.
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.ios_share, size: 18),
              label: Text(_capturing ? 'Capturing…' : 'Share image'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _SignOutButton — shows a sign-out icon only when Supabase is active
// =============================================================================

/// A small widget that renders an icon button for signing out.
/// Renders nothing (SizedBox.shrink) when Supabase is not configured or
/// when no user is signed in — so it is safe to include unconditionally.
///
/// Extends plain [StatelessWidget] — no state, no Riverpod.
/// Private — only used inside this file.
class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Supabase.instance.client throws if Supabase was never initialised.
    // We wrap the access in a try/catch to detect that case gracefully.
    bool supabaseReady = false;
    try {
      Supabase.instance.client; // Just accessing the getter; if it throws, supabaseReady stays false
      supabaseReady = true;
    } catch (_) {} // `_` discards the exception — we don't need its details

    // If Supabase is not set up, render nothing.
    if (!supabaseReady) return const SizedBox.shrink();

    // If no user is signed in, render nothing.
    if (Supabase.instance.client.auth.currentUser == null) return const SizedBox.shrink();

    // Supabase is ready and a user is signed in — show the sign-out button.
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      // `async` callback — we need to `await` the showDialog result.
      onPressed: () async {
        // showDialog returns a Future<T?> that resolves when the dialog is closed.
        // We type it as `bool` so we can check if the user confirmed.
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text(
              'Your data is saved to the cloud. You can sign back in anytime.',
            ),
            actions: [
              // Passes `false` back to the showDialog future → user cancelled
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              // Passes `true` back → user confirmed sign out
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );

        // `confirmed == true` (not just `confirmed!`) is safe even if showDialog
        // returns null (user dismissed by tapping outside).
        if (confirmed == true) await Supabase.instance.client.auth.signOut();
      },
    );
  }
}

// =============================================================================
// _LockedComebackBanner
//
// Shown in place of ComebackProtocolBanner when the user has exhausted their
// monthly free comeback limit.  Tapping it opens the ComebackGateModal.
// =============================================================================
class _LockedComebackBanner extends StatelessWidget {
  const _LockedComebackBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Comeback Protocol locked',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly free limit reached — tap to unlock',
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: onSurface.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }
}
