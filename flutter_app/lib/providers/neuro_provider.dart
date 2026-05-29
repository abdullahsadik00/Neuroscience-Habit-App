// =============================================================================
// FILE: neuro_provider.dart
//
// PURPOSE:
//   This is the central "brain" of the NeuroSync app. It defines the entire
//   application state (all habits, swaps, logs, chemistry, user profile) and
//   all the actions that can change that state (adding habits, completing them,
//   logging slips, etc.).
//
// ROLE IN APP ARCHITECTURE:
//   - This file sits in the "providers" layer — between the UI (screens/widgets)
//     and the data layer (local storage + Supabase cloud).
//   - Screens import `neuroProvider` from this file, watch it with Riverpod, and
//     call methods on `NeuroNotifier` to trigger state changes.
//   - When state changes, Riverpod automatically rebuilds any widget that was
//     watching the provider — no manual setState() calls needed.
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   1. IMMUTABLE STATE — `NeuroState` is a plain data object that can never be
//      changed in place. To "update" it, you create a new copy with new values
//      using `copyWith()`. This prevents bugs caused by hidden mutations.
//
//   2. RIVERPOD — the state management library. Think of a Provider as a global
//      variable that widgets can "subscribe" to. When the value changes, every
//      subscribed widget rebuilds automatically.
//
//   3. NOTIFIER — a class that holds state AND the methods to change it.
//      `NeuroNotifier` extends `Notifier<NeuroState>`. It owns the current
//      `NeuroState` and exposes methods like `completeNeuroStack()` that widgets
//      can call via `ref.read(neuroProvider.notifier)`.
//
//   4. LOCAL PERSISTENCE — changes are saved to the device via SharedPreferences
//      (key-value storage), encoded as JSON. On next app launch, the saved JSON
//      is loaded back to restore the user's data.
//
//   5. CLOUD SYNC — after every local save, the state is also "upserted" (insert
//      or update) to a Supabase (cloud database) row. This is fire-and-forget:
//      the UI never waits for it.
// =============================================================================

// Brings in Flutter's Material Design widgets (Color, ThemeMode, etc.) and the
// @immutable annotation used below.
import 'package:flutter/material.dart';

// Provides dart:convert's jsonEncode / jsonDecode functions, used to turn the
// state object into a JSON string for storage.
import 'dart:convert';

// Brings in Flutter's foundation layer, including the @immutable annotation that
// tells the compiler (and other developers) a class must never be mutated.
import 'package:flutter/foundation.dart';

// Riverpod: the state management library. Provides Provider, StateProvider,
// NotifierProvider, Notifier, Ref, and related classes.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// SharedPreferences: a plugin that gives simple key-value storage on the device
// (like localStorage in browsers). Used to persist the app state between sessions.
import 'package:shared_preferences/shared_preferences.dart';

// Supabase client for cloud database sync. We only import `Supabase` (the
// singleton accessor) rather than the entire package.
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

// UUID package: generates universally-unique identifiers (e.g., "a1b2-c3d4...")
// used to give every new habit/swap/log a guaranteed-unique ID.
import 'package:uuid/uuid.dart';

// App-specific data models: NeuroStack, NeuroSwap, NeuroLog, Neurochemistry, etc.
import '../models/models.dart';

// Pure utility functions: calculateStreak(), calculateMyelination(),
// decayNeurochemical(), getLocalDateString().
import '../utils/neuro_helpers.dart';

// The built-in habit template library — used when applying recalibration
// suggestions to swap a habit for a simpler template.
import '../data/habit_library.dart';

// Failure analysis — computes the user's worst day of the week for pre-covery
// notification scheduling.
import '../utils/failure_analysis.dart';

// Notification service — schedules all local push notifications including the
// new predictive pre-covery nudges.
import '../services/notification_service.dart';

// ---------------------------------------------------------------------------
// CONSTANTS
// ---------------------------------------------------------------------------

// The key used to store (and later retrieve) the serialised state in
// SharedPreferences. Changing this string would orphan existing saved data.
const _storageKey = 'neuroflow-state-v1';

// A single, reusable UUID generator instance. Calling `_uuid.v4()` returns a
// new random ID string each time — cheap and dependency-injection-friendly.
const _uuid = Uuid();

// The myelination percentage thresholds that trigger a celebration animation.
// When a habit crosses one of these values, the dashboard shows a confetti popup.
const _milestones = [10, 25, 50, 75, 100];

// ---------------------------------------------------------------------------
// BOOTSTRAP PROVIDERS
// These two providers are special: their real values are injected by
// ProviderScope overrides at app startup (in main.dart), not constructed here.
// ---------------------------------------------------------------------------

/// A Riverpod Provider that holds the initial NeuroState loaded from local
/// storage at startup. It is overridden in ProviderScope before any widget
/// builds, so the `throw` below is never actually reached in production.
///
/// Think of this as a dependency-injection slot: main.dart fills it with the
/// real saved state; this file just declares that the slot exists.
final initialStateProvider = Provider<NeuroState>(
  (_) => NeuroState.initial(), // Fallback — only used if override is missing.
);

/// A Riverpod Provider that holds the SharedPreferences instance obtained at
/// app startup. The `throw` is intentional — it acts as a guard: if someone
/// forgets to override this provider, the app crashes loudly instead of
/// silently using null storage.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(), // Must be overridden in ProviderScope.
);

// ---------------------------------------------------------------------------
// UI / EVENT PROVIDERS
// These are simple StateProviders — Riverpod's lightest provider type for a
// single mutable value. Any widget can watch or write them.
// ---------------------------------------------------------------------------

/// Controls the app-wide theme (dark or light mode).
/// `StateProvider` wraps a single value and lets widgets call
/// `ref.read(themeModeProvider.notifier).state = ThemeMode.light` to change it.
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.dark, // Default: dark mode on first launch.
);

/// A one-shot event channel for myelination milestone celebrations.
///
/// This uses a Dart "record" type — `(String, int)?` — which is like an
/// anonymous struct: a pair of (habitTitle, milestonePercent). The `?` means
/// it can be null (no celebration pending).
///
/// Flow:
///   1. `completeNeuroStack()` sets this to `("Run 5K", 50)`.
///   2. The Dashboard widget sees the non-null value and shows confetti.
///   3. The Dashboard then sets it back to `null` to clear the event.
final milestoneEventProvider = StateProvider<(String, int)?>(
  (_) => null, // null = no pending celebration.
);

/// A one-shot event channel for the "upgrade to Pro" gate dialog.
/// When a free-tier limit is hit (e.g., trying to add a 6th habit), a method
/// sets this to a human-readable explanation string. A listener widget shows
/// a dialog, then clears this back to null.
final proGateEventProvider = StateProvider<String?>(
  (_) => null, // null = no upgrade prompt pending.
);

// ---------------------------------------------------------------------------
// NEUROSTATE — The complete application state
// ---------------------------------------------------------------------------

/// `@immutable` is a compile-time annotation from Flutter's foundation package.
/// It tells the Dart analyzer: "no field in this class (or its subclasses)
/// should be mutable after construction." This enforces the immutable-state
/// pattern and helps Riverpod detect when state has truly changed.
@immutable

/// NeuroState is a plain data class (sometimes called a "value object") that
/// holds a complete snapshot of everything the app knows about the user:
/// their habits, swaps, logs, neurochemistry levels, profile, and settings.
///
/// It is NEVER mutated directly. Instead, `copyWith()` creates a new instance
/// with selected fields replaced — similar to how Redux reducers work in React.
///
/// It is NOT a widget — it has no `build()` method. It is just a data container.
class NeuroState {
  /// All habit stacks (both active and archived). Each `NeuroStack` holds one
  /// full habit definition: its cue, action, reward, and completion history.
  final List<NeuroStack> stacks;

  /// All habit-swap plans (bad habit → replacement behaviour). Each `NeuroSwap`
  /// tracks the cue, bad response, the intercept action, and urge-surf history.
  final List<NeuroSwap> swaps;

  /// Chronological activity log: every completion, urge surf, slip, and comeback
  /// is recorded here as a `NeuroLog` entry. Used to render the activity feed.
  final List<NeuroLog> logs;

  /// Records of times the user used the "comeback protocol" after missing a day.
  final List<ComebackRecord> comebacks;

  /// Current levels (0–100) of the four neurochemicals tracked by the app:
  /// dopamine, acetylcholine, epinephrine (noradrenaline), and GABA.
  final Neurochemistry neurochemistry;

  /// Lifetime accumulated dopamine points — a gamification score shown on the
  /// dashboard. Increases when habits are completed; never decreases.
  final int dopaminePoints;

  /// The user's display name and role (e.g., "Alex", "Startup Founder").
  final UserProfile userProfile;

  /// Whether the user has unlocked the Pro tier. Controls free-tier limits
  /// on the number of active habits and swaps.
  final bool isPro;

  /// Whether the user has finished the initial onboarding flow. The app shows
  /// the onboarding screen until this is true.
  final bool onboardingComplete;

  /// The user's "Brain Profile" — their self-assessed neurotype (e.g., ADHD-
  /// leaning, high-stress, dopamine-sensitive). Used to personalise blueprint
  /// habit suggestions. Nullable because it's collected after onboarding.
  final NeuroBrainProfile? brainProfile; // The `?` means this can be null.

  /// Whether the user has reviewed and accepted their personalised habit
  /// blueprint (the curated starter set based on their brain profile).
  final bool blueprintAccepted;

  /// ISO-8601 date string (e.g., "2026-05-29") of the most recent weekly
  /// check-in. Used to decide whether to prompt for a new check-in today.
  final String? lastCheckinDate; // Nullable: null = never checked in.

  /// Full history of weekly check-in submissions, newest first.
  final List<CheckinRecord> checkinHistory;

  /// Log of AI-generated recalibration events — each time the AI suggested
  /// habit changes and the user accepted/rejected them.
  final List<RecalibrationEvent> recalibrationLog;

  /// The `const` constructor means every NeuroState created with all-constant
  /// arguments can be a compile-time constant (helps with performance).
  /// `required` parameters MUST be provided by the caller; optional ones have `?` types.
  const NeuroState({
    required this.stacks,
    required this.swaps,
    required this.logs,
    required this.comebacks,
    required this.neurochemistry,
    required this.dopaminePoints,
    required this.userProfile,
    required this.isPro,
    required this.onboardingComplete,
    this.brainProfile, // Optional — no `required` keyword, defaults to null.
    required this.blueprintAccepted,
    this.lastCheckinDate, // Optional — defaults to null.
    required this.checkinHistory,
    required this.recalibrationLog,
  });

  /// A `factory` constructor is a special constructor that returns an instance
  /// of the class but can contain logic (unlike a regular constructor).
  /// `NeuroState.initial()` returns a safe, empty starting state used when
  /// the app is first installed or when the user resets all data.
  factory NeuroState.initial() => const NeuroState(
        stacks: [], // No habits yet.
        swaps: [], // No swaps yet.
        logs: [], // Empty activity feed.
        comebacks: [], // No comebacks yet.
        neurochemistry: Neurochemistry.initial, // All chemicals at baseline levels.
        dopaminePoints: 0, // Zero gamification score.
        userProfile: UserProfile.empty, // No name/role set.
        isPro: false, // Free tier by default.
        onboardingComplete: false, // Force onboarding on first launch.
        brainProfile: null, // Not assessed yet.
        blueprintAccepted: false, // Blueprint not yet reviewed.
        lastCheckinDate: null, // Never checked in.
        checkinHistory: [], // No check-in history.
        recalibrationLog: [], // No recalibrations yet.
      );

  /// `copyWith` is the standard Dart immutable-update pattern.
  ///
  /// Instead of `state.stacks = newList` (which is forbidden on an immutable
  /// object), you call `state.copyWith(stacks: newList)`. This creates a brand-
  /// new NeuroState where `stacks` is replaced by `newList` and every other
  /// field is copied from the original unchanged.
  ///
  /// The `?` parameter types (e.g., `List<NeuroStack>? stacks`) mean each
  /// argument is optional. If you don't pass it, it defaults to `null`.
  ///
  /// The `??` ("null-coalescing") operator — `stacks ?? this.stacks` — means:
  /// "use the new value if provided, otherwise keep the existing value."
  NeuroState copyWith({
    List<NeuroStack>? stacks,
    List<NeuroSwap>? swaps,
    List<NeuroLog>? logs,
    List<ComebackRecord>? comebacks,
    Neurochemistry? neurochemistry,
    int? dopaminePoints,
    UserProfile? userProfile,
    bool? isPro,
    bool? onboardingComplete,
    NeuroBrainProfile? brainProfile,
    bool? blueprintAccepted,
    String? lastCheckinDate,
    List<CheckinRecord>? checkinHistory,
    List<RecalibrationEvent>? recalibrationLog,
  }) =>
      NeuroState(
        stacks: stacks ?? this.stacks, // Use new value, or fall back to current value.
        swaps: swaps ?? this.swaps,
        logs: logs ?? this.logs,
        comebacks: comebacks ?? this.comebacks,
        neurochemistry: neurochemistry ?? this.neurochemistry,
        dopaminePoints: dopaminePoints ?? this.dopaminePoints,
        userProfile: userProfile ?? this.userProfile,
        isPro: isPro ?? this.isPro,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        brainProfile: brainProfile ?? this.brainProfile,
        blueprintAccepted: blueprintAccepted ?? this.blueprintAccepted,
        lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
        checkinHistory: checkinHistory ?? this.checkinHistory,
        recalibrationLog: recalibrationLog ?? this.recalibrationLog,
      );

  /// Converts this NeuroState into a plain `Map<String, dynamic>` (a dictionary)
  /// so it can be serialised to a JSON string and stored in SharedPreferences
  /// or sent to Supabase.
  ///
  /// `.map((s) => s.toJson()).toList()` is a common Dart pattern:
  ///   - `.map(fn)` applies `fn` to each element and returns a lazy Iterable.
  ///   - `.toList()` materialises that Iterable into an actual List.
  ///
  /// The `?.toJson()` on `brainProfile` uses the null-safe call operator (`?.`):
  /// if `brainProfile` is null, the whole expression returns null instead of
  /// throwing a NullPointerException.
  Map<String, dynamic> toJson() => {
        'stacks': stacks.map((s) => s.toJson()).toList(),
        'swaps': swaps.map((s) => s.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'comebacks': comebacks.map((c) => c.toJson()).toList(),
        'neurochemistry': neurochemistry.toJson(),
        'dopaminePoints': dopaminePoints,
        'userProfile': userProfile.toJson(),
        'isPro': isPro,
        'onboardingComplete': onboardingComplete,
        'brainProfile': brainProfile?.toJson(), // Safe null call — skipped if null.
        'blueprintAccepted': blueprintAccepted,
        'lastCheckinDate': lastCheckinDate,
        'checkinHistory': checkinHistory.map((c) => c.toJson()).toList(),
        'recalibrationLog': recalibrationLog.map((r) => r.toJson()).toList(),
      };

  /// Reconstructs a NeuroState from a JSON map (the reverse of `toJson()`).
  ///
  /// This is called when the app loads previously saved data from SharedPreferences
  /// or from the Supabase cloud row.
  ///
  /// The `as List? ?? []` pattern:
  ///   - `as List?` casts the value to a nullable List (it might be null in old
  ///     saved data).
  ///   - `?? []` provides an empty list as fallback if the cast result is null.
  ///   This makes deserialization "forward-compatible" with older saved data that
  ///   might be missing new fields.
  ///
  /// The outer `try/catch` means that if saved data is ever corrupted or from an
  /// incompatible older version of the app, we safely fall back to a clean initial
  /// state instead of crashing.
  factory NeuroState.fromJson(Map<String, dynamic> json) {
    try {
      return NeuroState(
        // Cast json['stacks'] to a nullable List, fall back to [], then convert
        // each raw map element into a typed NeuroStack object.
        stacks: (json['stacks'] as List? ?? [])
            .map((s) => NeuroStack.fromJson(s as Map<String, dynamic>))
            .toList(),
        swaps: (json['swaps'] as List? ?? [])
            .map((s) => NeuroSwap.fromJson(s as Map<String, dynamic>))
            .toList(),
        logs: (json['logs'] as List? ?? [])
            .map((l) => NeuroLog.fromJson(l as Map<String, dynamic>))
            .toList(),
        comebacks: (json['comebacks'] as List? ?? [])
            .map((c) => ComebackRecord.fromJson(c as Map<String, dynamic>))
            .toList(),
        // If the 'neurochemistry' key exists, parse it; otherwise use the
        // built-in baseline constant.
        neurochemistry: json['neurochemistry'] != null
            ? Neurochemistry.fromJson(json['neurochemistry'] as Map<String, dynamic>)
            : Neurochemistry.initial,
        dopaminePoints: json['dopaminePoints'] as int? ?? 0,
        // Same null-safe pattern for the nested UserProfile object.
        userProfile: json['userProfile'] != null
            ? UserProfile.fromJson(json['userProfile'] as Map<String, dynamic>)
            : UserProfile.empty,
        isPro: json['isPro'] as bool? ?? false,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        // brainProfile is genuinely optional — keep it null if absent.
        brainProfile: json['brainProfile'] != null
            ? NeuroBrainProfile.fromJson(json['brainProfile'] as Map<String, dynamic>)
            : null,
        blueprintAccepted: json['blueprintAccepted'] as bool? ?? false,
        lastCheckinDate: json['lastCheckinDate'] as String?,
        checkinHistory: (json['checkinHistory'] as List? ?? [])
            .map((c) => CheckinRecord.fromJson(c as Map<String, dynamic>))
            .toList(),
        recalibrationLog: (json['recalibrationLog'] as List? ?? [])
            .map((r) => RecalibrationEvent.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      // `_` means we intentionally discard the error — we don't need to log it.
      // If anything goes wrong during parsing (unexpected field type, missing
      // required key, etc.), return a fresh empty state so the app keeps working.
      return NeuroState.initial();
    }
  }
}

// ---------------------------------------------------------------------------
// NEURONOTIFIER — State holder + action dispatcher
// ---------------------------------------------------------------------------

/// `NeuroNotifier` extends Riverpod's `Notifier<NeuroState>`.
///
/// WHAT IS A NOTIFIER?
///   A Notifier is a class that:
///     1. Holds a piece of state (here, the full NeuroState).
///     2. Exposes methods that widgets can call to trigger state changes.
///     3. Automatically notifies all watching widgets when `state` is reassigned.
///
/// HOW WIDGETS USE IT:
///   - To READ state:  `final s = ref.watch(neuroProvider);`
///   - To CALL methods: `ref.read(neuroProvider.notifier).completeNeuroStack(id);`
///
/// LIFE CYCLE:
///   - `build()` is called once when the notifier is first used. It sets up
///     dependencies (like reading SharedPreferences) and returns the initial state.
///   - After `build()`, the notifier lives as long as any widget is watching it.
class NeuroNotifier extends Notifier<NeuroState> {
  /// The SharedPreferences instance used for local on-device storage.
  /// `late final` means: "I promise to assign this before it is first used,
  /// but I can't do it in the constructor." Dart enforces this at runtime.
  late final SharedPreferences _prefs;

  /// `build()` is the Riverpod equivalent of a constructor for a Notifier.
  /// It MUST return the initial state. It is also where you set up resources
  /// (like reading providers) that the notifier needs.
  ///
  /// Inside a Notifier, `ref` is available as a field (no parameter needed).
  /// `ref.read()` fetches a provider's current value without subscribing to
  /// future changes (unlike `ref.watch()`, which rebuilds on every change).
  @override
  NeuroState build() {
    _prefs = ref.read(sharedPreferencesProvider); // Grab the SharedPreferences instance.
    return ref.read(initialStateProvider); // Return the pre-loaded saved state.
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  /// Central "commit" method — every state change in this notifier goes through
  /// here. It does three things atomically (from the app's perspective):
  ///   1. Updates Riverpod's `state`, triggering UI rebuilds.
  ///   2. Persists the new state to local SharedPreferences storage.
  ///   3. Kicks off a non-blocking cloud sync (fire-and-forget).
  ///
  /// [newState] — the fully updated NeuroState to apply.
  void _save(NeuroState newState) {
    state = newState; // Assign to Riverpod's `state` — this triggers widget rebuilds.
    // jsonEncode turns the Map from toJson() into a JSON string like '{"stacks":[...]}'.
    _prefs.setString(_storageKey, jsonEncode(newState.toJson())); // Persist locally.
    _syncToCloud(newState); // Start cloud sync — don't await it.
  }

  /// Upserts ("insert or update if exists") the full state JSON to Supabase.
  ///
  /// This is intentionally fire-and-forget:
  ///   - `_save()` does NOT `await` this method.
  ///   - The UI updates immediately from local state.
  ///   - Cloud sync happens in the background and failures are silently swallowed.
  ///
  /// `async` marks this function as asynchronous — it runs in the background
  /// and returns a `Future<void>` that the caller ignores.
  ///
  /// [newState] — the state snapshot to push to the cloud.
  Future<void> _syncToCloud(NeuroState newState) async {
    try {
      final client = Supabase.instance.client; // Access the singleton Supabase client.
      final user = client.auth.currentUser; // Get the currently logged-in user, or null.
      if (user == null) return; // Not logged in — skip cloud sync silently.
      // `await` pauses this async function until the Supabase upsert completes.
      // `upsert` means: if a row with this user_id exists, update it; otherwise insert it.
      await client.from('neuro_state').upsert({
        'user_id': user.id,
        'state_json': newState.toJson(), // Send the full state as a JSON column.
        'updated_at': DateTime.now().toUtc().toIso8601String(), // UTC timestamp for the audit trail.
      });
    } catch (_) {
      // Sync failure is silent — the local copy is the source of truth.
      // The cloud will be updated on the next successful save.
    }
  }

  /// Loads the user's cloud state from Supabase and hydrates local storage.
  ///
  /// Called after a successful sign-in. If the cloud has newer data (e.g., the
  /// user signed in on a new device), this overwrites the local state.
  ///
  /// `.maybeSingle()` is a Supabase query method that returns the single matching
  /// row as a Map, or `null` if no row exists (unlike `.single()` which throws
  /// if no row is found).
  Future<void> loadFromCloud() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return; // Not signed in — nothing to load.
      // Build the query: SELECT state_json FROM neuro_state WHERE user_id = user.id
      final row = await client
          .from('neuro_state')
          .select('state_json')
          .eq('user_id', user.id) // `.eq` adds a WHERE clause: field equals value.
          .maybeSingle(); // Returns Map or null.
      if (row != null && row['state_json'] != null) {
        // Parse the cloud JSON into a typed NeuroState object.
        final loaded = NeuroState.fromJson(row['state_json'] as Map<String, dynamic>);
        // Write the cloud state to local storage so it persists offline too.
        _prefs.setString(_storageKey, jsonEncode(loaded.toJson()));
        state = loaded; // Update Riverpod state — triggers UI rebuilds.
      }
    } catch (_) {
      // If cloud load fails, keep the local state as-is. The user can still use
      // the app — they'll just see their most recent local data.
    }
  }

  // ── STACKS ────────────────────────────────────────────────────────────────

  /// A computed getter (not a stored field) that returns `true` if the user can
  /// add another habit stack. Free users are limited to 5 active stacks.
  ///
  /// `get` syntax: this looks like a property access (`notifier.canAddStack`) but
  /// computes its value on-the-fly each time it is read — no parentheses needed.
  ///
  /// `.where((s) => s.isActive)` filters the list to only active (non-archived)
  /// stacks. `.length` counts how many remain after filtering.
  bool get canAddStack =>
      state.isPro || // Pro users have no limit.
      state.stacks.where((s) => s.isActive).length < 5; // Free users: max 5 active.

  /// Creates a new habit stack and prepends it to the list.
  ///
  /// [title]                  — human-readable name of the habit (e.g., "Morning Run").
  /// [anchorCue]              — the existing behaviour this habit hooks onto.
  /// [action]                 — the specific action to perform.
  /// [reward]                 — the immediate reward to reinforce the loop.
  /// [category]               — enum categorising the habit (exercise, sleep, etc.).
  /// [acetylcholineDuration]  — estimated focus minutes this habit provides.
  /// [whenCondition]          — optional "When I..." implementation intention trigger.
  /// [thenAction]             — optional "...I will" completion text.
  ///
  /// Side effect: if the free-tier limit is hit, sets `proGateEventProvider`
  /// instead of creating the stack.
  void addNeuroStack({
    required String title,
    required String anchorCue,
    required String action,
    required String reward,
    required HabitCategory category,
    required int acetylcholineDuration,
    String? whenCondition, // Optional — only for implementation intentions.
    String? thenAction, // Optional — paired with whenCondition.
  }) {
    if (!canAddStack) {
      // Gate: set the upgrade prompt event — the UI will pick this up and show
      // a dialog. We use `ref.read` (not `ref.watch`) because we only want to
      // write to the provider, not subscribe to its changes.
      ref.read(proGateEventProvider.notifier).state =
          'Free plan supports up to 5 active habits. Upgrade to Pro for unlimited habits, failure signatures, and deeper recovery insights.';
      return; // Exit early — do NOT create the stack.
    }
    // Build the new NeuroStack value object with all required fields.
    final stack = NeuroStack(
      id: 'stack-${_uuid.v4()}', // Generate a globally unique ID string.
      title: title,
      anchorCue: anchorCue,
      action: action,
      reward: reward,
      category: category,
      acetylcholineDuration: acetylcholineDuration,
      myelinationLevel: 0, // Brand new — no neural pathway reinforcement yet.
      streak: 0, // Starting streak.
      completions: const [], // No completions yet.
      createdAt: DateTime.now().toIso8601String(), // ISO timestamp of creation.
      isActive: true, // Immediately active.
      whenCondition: whenCondition,
      thenAction: thenAction,
    );
    // Prepend to list: `[stack, ...state.stacks]` puts the new stack at index 0.
    // The `...` ("spread") operator expands the existing list in place.
    _save(state.copyWith(stacks: [stack, ...state.stacks]));
  }

  /// Updates a specific stack by ID using a transform function.
  ///
  /// [id]     — the unique ID of the stack to update.
  /// [update] — a function that receives the old stack and returns a new one.
  ///
  /// Example: `updateNeuroStack(id, (s) => s.copyWith(title: "New Title"))`
  ///
  /// `.map((s) => s.id == id ? update(s) : s)` iterates every stack:
  ///   - If the stack's id matches, apply the transform.
  ///   - Otherwise, return it unchanged.
  /// This is the standard "update one item in an immutable list" pattern.
  void updateNeuroStack(String id, NeuroStack Function(NeuroStack) update) {
    _save(state.copyWith(
      stacks: state.stacks.map((s) => s.id == id ? update(s) : s).toList(),
    ));
  }

  /// Soft-deletes a habit stack by setting `isActive = false` (archive).
  ///
  /// We never hard-delete — archived stacks stay in the list so their completion
  /// history is preserved for analytics. The UI simply hides them from the main
  /// screen.
  ///
  /// [id] — the ID of the stack to archive.
  void archiveNeuroStack(String id) {
    _save(state.copyWith(
      stacks: state.stacks
          .map((s) => s.id == id ? s.copyWith(isActive: false) : s) // Archive only the matched stack.
          .toList(),
    ));
  }

  /// Restores a previously archived stack, making it visible and active again.
  ///
  /// [id] — the ID of the archived stack to restore.
  void unarchiveNeuroStack(String id) {
    _save(state.copyWith(
      stacks: state.stacks
          .map((s) => s.id == id ? s.copyWith(isActive: true) : s) // Re-activate the matched stack.
          .toList(),
    ));
  }

  /// Records that the user chose Lite Mode for a specific habit today.
  ///
  /// Lite Mode is a same-day downscale — the user is choosing to do a lower-
  /// friction version of the habit rather than skipping it entirely. This
  /// prevents the miss, awards Resilience Score points, and records the date
  /// in `liteModeDates` for the Recovery Heatmap.
  ///
  /// [habitId] — the ID of the habit to activate lite mode for.
  void activateLiteMode(String habitId) {
    final today = getLocalDateString(DateTime.now());
    _save(state.copyWith(
      stacks: state.stacks.map((s) {
        if (s.id != habitId) return s;
        // Only add today if not already in the list (deduplication).
        if (s.liteModeDates.contains(today)) return s;
        return s.copyWith(liteModeDates: [...s.liteModeDates, today]);
      }).toList(),
    ));
  }

  /// Analyses the user's failure signature and schedules proactive pre-covery
  /// notifications for their worst habit day.
  ///
  /// Should be called after any slip is logged, so the failure signature
  /// stays up to date. Silently exits when there is not enough data.
  void _schedulePreCovery() {
    final sig = analyseFailureSignatures(state.stacks, state.comebacks);
    if (!sig.hasEnoughData) return;
    if (sig.worstDayOfWeek == null || sig.weakestHabit == null) return;
    NotificationService.schedulePreCoveryNudge(
      habitTitle: sig.weakestHabit!.title,
      worstDay: sig.worstDayOfWeek!,
    );
  }

  /// Marks a habit stack as completed for today and updates all derived values:
  /// streak, myelination level, neurochemistry, dopamine points, and activity log.
  /// Also fires a milestone celebration event if a threshold was crossed.
  ///
  /// [id]    — ID of the stack being completed.
  /// [notes] — optional user reflection text stored in the log entry.
  ///
  /// Side effects:
  ///   - Sets `milestoneEventProvider` if a myelination milestone is crossed.
  ///   - Calls `_save()` which persists and syncs the new state.
  void completeNeuroStack(String id, {String? notes}) {
    // Get today's date as a plain "YYYY-MM-DD" string for deduplication.
    final todayStr = getLocalDateString(DateTime.now());
    // Default reward amounts — boosted below if the user is on a long streak.
    int dopamineAward = 25;
    int acetylcholineAward = 20;
    // These are set below when a milestone is detected, then used to fire the
    // celebration event AFTER the state is built (to avoid partial state issues).
    String? celebratedTitle;
    int? milestoneHit;

    // Transform the stacks list: only the matching stack changes, others pass through.
    final updatedStacks = state.stacks.map((stack) {
      if (stack.id != id) return stack; // Not the target — return unchanged.

      // Deduplication: don't add today's date twice if already completed today.
      final alreadyDone = stack.completions.contains(todayStr);
      // Spread operator: if not already done, append today's date to the list.
      final completions = alreadyDone ? stack.completions : [...stack.completions, todayStr];

      // Recalculate derived values from the updated completion history.
      final streak = calculateStreak(completions); // Consecutive-day streak count.
      final oldMyelination = stack.myelinationLevel; // Save before updating.
      final newMyelination = calculateMyelination(completions.length, streak);

      // Streak bonus: more than 5 consecutive days earns larger chemical rewards.
      if (streak > 5) {
        dopamineAward = 40;
        acetylcholineAward = 30;
      }

      // Check if myelination crossed any milestone threshold in this completion.
      // The `for...in` loop tries each milestone in order; `break` stops at the
      // first one crossed so we only celebrate one milestone per completion.
      for (final m in _milestones) {
        if (oldMyelination < m && newMyelination >= m) {
          celebratedTitle = stack.title; // Capture for the event below.
          milestoneHit = m; // Capture the specific milestone percentage.
          break; // Only one celebration per completion.
        }
      }

      // Return a new NeuroStack with updated fields (immutable update pattern).
      return stack.copyWith(
        completions: completions,
        streak: streak,
        myelinationLevel: newMyelination,
      );
    }).toList();

    // Fire the celebration event if a milestone was crossed.
    // `celebratedTitle!` — the `!` is a non-null assertion: tells Dart "I know
    // this is not null here" (we only reach this branch if both are non-null).
    if (celebratedTitle != null && milestoneHit != null) {
      ref.read(milestoneEventProvider.notifier).state = (celebratedTitle!, milestoneHit!);
    }

    // Look up the original stack (before mutation) to get its title for the log.
    // `orElse` handles the edge case where the id is not found (shouldn't happen
    // in practice, but prevents a crash).
    final completed = state.stacks.firstWhere((s) => s.id == id, orElse: () => state.stacks.first);

    // Build an immutable log entry for this completion event.
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.completion, // Enum value — "this log entry is a completion".
      itemId: id,
      itemTitle: completed.title,
      notes: notes,
      dopamineChange: dopamineAward, // How much dopamine this completion added.
      epinephrineChange: 5, // Mild arousal boost from completing a task.
      gabaChange: 0, // Completions don't affect GABA (calm).
      acetylcholineChange: acetylcholineAward, // Focus/attention boost.
    );

    // Capture the current neurochemistry so we can apply delta changes to it.
    final chem = state.neurochemistry;
    _save(state.copyWith(
      stacks: updatedStacks,
      logs: [log, ...state.logs], // Prepend new log entry (newest first).
      dopaminePoints: state.dopaminePoints + dopamineAward, // Accumulate lifetime score.
      neurochemistry: chem.copyWith(
        // `.clamp(0, 100)` ensures the value never goes below 0 or above 100.
        dopamine: (chem.dopamine + dopamineAward).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + acetylcholineAward).clamp(0, 100),
        epinephrine: (chem.epinephrine + 5).clamp(0, 100),
      ),
    ));
  }

  // ── SWAPS ────────────────────────────────────────────────────────────────

  /// Returns `true` if the user can add another habit swap.
  /// Free users are capped at 3 active swaps.
  bool get canAddSwap =>
      state.isPro || // Pro users have unlimited swaps.
      state.swaps.where((s) => s.isActive).length < 3; // Free: max 3 active.

  /// Creates a new habit-swap plan and prepends it to the swaps list.
  ///
  /// A "swap" is a structured plan to intercept a bad habit:
  ///   cue → (used to trigger bad response) → intercept action instead.
  ///
  /// [title]           — short name for this swap (e.g., "Phone doom-scroll").
  /// [cue]             — the trigger event (e.g., "Feeling bored at work").
  /// [badResponse]     — the habitual bad behaviour triggered by the cue.
  /// [interceptAction] — what to do instead of the bad response.
  /// [frictionLevel]   — 1–5 scale of how hard the intercept is to perform.
  /// [frictionSteps]   — ordered list of micro-steps to make the bad habit harder.
  ///
  /// Side effect: may set `proGateEventProvider` if the free limit is reached.
  void addNeuroSwap({
    required String title,
    required String cue,
    required String badResponse,
    required String interceptAction,
    required int frictionLevel,
    required List<String> frictionSteps,
  }) {
    if (!canAddSwap) {
      // Free limit hit — show the upgrade gate instead of creating the swap.
      ref.read(proGateEventProvider.notifier).state =
          'Free plan supports up to 3 active swaps. Upgrade to Pro for unlimited swaps and personalized friction coaching.';
      return;
    }
    final swap = NeuroSwap(
      id: 'swap-${_uuid.v4()}', // Unique ID.
      title: title,
      cue: cue,
      badResponse: badResponse,
      interceptAction: interceptAction,
      frictionLevel: frictionLevel,
      frictionSteps: frictionSteps,
      urgeSurfingCompletions: const [], // No urge surfs yet.
      slips: const [], // No slips yet.
      createdAt: DateTime.now().toIso8601String(),
      isActive: true,
    );
    _save(state.copyWith(swaps: [swap, ...state.swaps])); // Prepend to list.
  }

  /// Soft-deletes a swap by marking it inactive (hides from main UI).
  ///
  /// [id] — the swap to archive.
  void archiveNeuroSwap(String id) {
    _save(state.copyWith(
      swaps: state.swaps
          .map((s) => s.id == id ? s.copyWith(isActive: false) : s)
          .toList(),
    ));
  }

  /// Permanently removes a swap from the list (hard delete).
  ///
  /// Unlike habits (which are soft-deleted to preserve history), swaps can be
  /// fully removed because they don't contribute to myelination analytics.
  ///
  /// [id] — the swap to delete.
  ///
  /// `.where((s) => s.id != id)` filters OUT the matching swap,
  /// effectively deleting it from the list.
  void deleteNeuroSwap(String id) {
    _save(state.copyWith(
      swaps: state.swaps.where((s) => s.id != id).toList(),
    ));
  }

  /// Logs a successful "urge surf" — the user felt the craving and rode it out
  /// without acting on the bad habit. Rewards GABA (calm) and small dopamine.
  ///
  /// [id]    — the swap whose urge was surfed.
  /// [notes] — optional reflection or strategy the user used.
  ///
  /// Side effects: updates swap's urgeSurfingCompletions list, adds a log entry,
  /// boosts GABA + dopamine, and reduces epinephrine (stress/arousal).
  void logUrgeSurf(String id, {String? notes}) {
    final todayStr = getLocalDateString(DateTime.now());
    const dopamineAward = 15; // Small dopamine reward for resisting the urge.
    const gabaAward = 30; // Large GABA boost — calm reward for self-regulation.

    // Update the matching swap's urge-surf completion list (deduplicated by date).
    final updatedSwaps = state.swaps.map((swap) {
      if (swap.id != id) return swap;
      final alreadyDone = swap.urgeSurfingCompletions.contains(todayStr);
      final completions = alreadyDone
          ? swap.urgeSurfingCompletions // Already logged today — don't duplicate.
          : [...swap.urgeSurfingCompletions, todayStr]; // Append today.
      return swap.copyWith(urgeSurfingCompletions: completions);
    }).toList();

    // Find the swap by ID to get its title for the log entry.
    final swap = state.swaps.firstWhere((s) => s.id == id);
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.urgeSurf, // Marks this as an urge-surf event in the feed.
      itemId: id,
      itemTitle: swap.title,
      notes: notes ?? 'Successfully rode out the craving using box breathing.', // Default note.
      dopamineChange: dopamineAward,
      epinephrineChange: -10, // Urge-surfing REDUCES stress/arousal.
      gabaChange: gabaAward,
      acetylcholineChange: 10, // Small focus boost from the mindful act.
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      swaps: updatedSwaps,
      logs: [log, ...state.logs],
      dopaminePoints: state.dopaminePoints + dopamineAward + 10, // +10 bonus for urge surf.
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + dopamineAward).clamp(0, 100),
        gaba: (chem.gaba + gabaAward).clamp(0, 100),
        epinephrine: (chem.epinephrine - 10).clamp(0, 100), // Stress goes down.
        acetylcholine: (chem.acetylcholine + 10).clamp(0, 100),
      ),
    ));
  }

  /// Logs a "slip" — the user gave in to the bad habit they were trying to swap.
  /// Increases epinephrine (stress response) and drops dopamine slightly to
  /// simulate the real neurochemical consequence of a relapse.
  ///
  /// [id]         — the swap that was slipped on.
  /// [reflection] — optional text about what caused the slip.
  ///
  /// Side effects: adds today's date to the swap's slips list, creates a log
  /// entry with negative dopamine change, and updates neurochemistry accordingly.
  void logSlip(String id, {String? reflection}) {
    final todayStr = getLocalDateString(DateTime.now());
    const epinephrineIncrease = 40; // Big epinephrine spike — stress response from a slip.
    const dopamineDrop = -15; // Negative value — dopamine decreases after a slip.

    // Mark today as a slip day in the swap record (deduplicated).
    final updatedSwaps = state.swaps.map((swap) {
      if (swap.id != id) return swap;
      final alreadySlipped = swap.slips.contains(todayStr);
      final slips = alreadySlipped ? swap.slips : [...swap.slips, todayStr];
      return swap.copyWith(slips: slips);
    }).toList();

    final swap = state.swaps.firstWhere((s) => s.id == id);
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.slip, // Marks this as a slip event in the activity feed.
      itemId: id,
      itemTitle: swap.title,
      notes: reflection ?? 'Logged a slip. Triggered neural correction alert.',
      dopamineChange: dopamineDrop, // Negative — shown as a decrease in the UI.
      epinephrineChange: epinephrineIncrease, // Stress spikes after a slip.
      gabaChange: -10, // GABA (calm) drops — the user feels worse.
      acetylcholineChange: 15, // Acetylcholine spike — the brain encodes the failure for learning.
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      swaps: updatedSwaps,
      logs: [log, ...state.logs],
      // Note: dopamine POINTS (gamification) are NOT reduced on a slip — only
      // the neurochemistry model is affected. This prevents punishing the user
      // for honest self-reporting.
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + dopamineDrop).clamp(0, 100), // dopamineDrop is negative.
        epinephrine: (chem.epinephrine + epinephrineIncrease).clamp(0, 100),
        gaba: (chem.gaba - 10).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + 15).clamp(0, 100),
      ),
    ));

    // After recording the slip, refresh the pre-covery schedule so the worst-day
    // calculation stays current as failure patterns accumulate.
    _schedulePreCovery();
  }

  // ── COMEBACKS ────────────────────────────────────────────────────────────

  /// Records that the user used the "comeback protocol" after missing a streak day.
  ///
  /// The comeback protocol is the app's recovery mechanism: instead of shame,
  /// the user acknowledges the miss, optionally completes micro-actions, and
  /// gets a dopamine boost for re-engaging.
  ///
  /// [stackId]               — the habit stack the comeback applies to.
  /// [stackTitle]            — human-readable name (used in the log entry).
  /// [microActionsCompleted] — true if the user also completed the micro-action
  ///                           set; earns a larger reward (20 pts vs 10 pts).
  ///
  /// Side effects: creates a ComebackRecord, logs the event, awards dopamine
  /// points, and shifts neurochemistry toward calm/focus.
  void acknowledgeComeback(
    String stackId,
    String stackTitle, {
    required bool microActionsCompleted,
  }) {
    final today = getLocalDateString(DateTime.now());
    // Ternary expression: `condition ? valueIfTrue : valueIfFalse`
    final boost = microActionsCompleted ? 20 : 10; // Bigger reward for doing micro-actions.

    final record = ComebackRecord(
      id: 'comeback-${_uuid.v4()}',
      stackId: stackId,
      date: today,
      microActionsCompleted: microActionsCompleted,
      completedAt: DateTime.now().toIso8601String(),
    );
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.comeback, // Marks this as a comeback event.
      itemId: stackId,
      itemTitle: stackTitle,
      // Ternary used to choose a more descriptive note based on completion.
      notes: microActionsCompleted
          ? 'Activated comeback protocol — micro-actions completed.'
          : 'Activated comeback protocol — acknowledged failure, ready to continue.',
      dopamineChange: boost,
      epinephrineChange: -15, // Comeback reduces stress — relief of re-engaging.
      gabaChange: 15, // Increases calm — the shame cycle is broken.
      acetylcholineChange: 10,
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      comebacks: [record, ...state.comebacks], // Prepend new comeback record.
      logs: [log, ...state.logs],
      dopaminePoints: state.dopaminePoints + boost,
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + boost).clamp(0, 100),
        epinephrine: (chem.epinephrine - 15).clamp(0, 100),
        gaba: (chem.gaba + 15).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + 10).clamp(0, 100),
      ),
    ));
  }

  /// Returns a list of stack IDs that the user has already acknowledged a
  /// comeback for today. Used by the UI to hide the comeback prompt for habits
  /// that have already been addressed.
  ///
  /// Returns: a `List<String>` of stackId values (not ComebackRecord objects).
  List<String> getTodayComebackIds() {
    final today = getLocalDateString(DateTime.now());
    // Filter comebacks to today only, then extract just the stackId field.
    return state.comebacks
        .where((c) => c.date == today) // Keep only today's comeback records.
        .map((c) => c.stackId) // Transform: ComebackRecord → stackId string.
        .toList(); // Materialise the lazy Iterable into a concrete List.
  }

  // ── PROFILE / PRO ────────────────────────────────────────────────────────

  /// Updates the user's display profile. Both parameters are optional — you can
  /// update just the name, just the role, or both at once.
  ///
  /// [name] — the user's display name (e.g., "Alex").
  /// [role] — the user's self-described role (e.g., "Startup Founder").
  void setUserProfile({String? name, String? role}) {
    _save(state.copyWith(
      userProfile: state.userProfile.copyWith(name: name, role: role),
    ));
  }

  /// Stores the user's NeuroBrainProfile — the neurotype assessment result that
  /// powers personalised habit blueprint recommendations.
  ///
  /// [profile] — the completed NeuroBrainProfile object from the assessment flow.
  void setBrainProfile(NeuroBrainProfile profile) {
    _save(state.copyWith(brainProfile: profile));
  }

  /// Marks the personalised habit blueprint as accepted by the user.
  /// Once accepted, the blueprint screen is no longer shown.
  void acceptBlueprint() {
    _save(state.copyWith(blueprintAccepted: true));
  }

  /// Adds a list of pre-built blueprint habits to the front of the stacks list.
  ///
  /// [habits] — the list of NeuroStack objects generated from the blueprint
  ///            recommendations screen.
  ///
  /// Spread operator: `[...habits, ...state.stacks]` creates a new list by
  /// concatenating the blueprint habits first, then all existing stacks.
  void addBlueprintHabits(List<NeuroStack> habits) {
    _save(state.copyWith(stacks: [...habits, ...state.stacks]));
  }

  /// Saves a weekly check-in record and updates the last check-in date.
  ///
  /// [record] — the completed CheckinRecord (contains mood, energy, and
  ///            ratings for each habit from the weekly review flow).
  void submitCheckin(CheckinRecord record) {
    _save(state.copyWith(
      checkinHistory: [record, ...state.checkinHistory], // Newest first.
      lastCheckinDate: record.date, // Update the "last checked in" timestamp.
    ));
  }

  /// Applies a set of AI-generated recalibration suggestions to the habit list.
  ///
  /// A "recalibration event" is when the AI reviews recent check-in data and
  /// suggests changes: scaling down a too-hard habit, replacing one that isn't
  /// working, or adjusting the approach. The user accepts or rejects each
  /// suggestion individually.
  ///
  /// [event] — the full RecalibrationEvent including all suggestions and the
  ///           list of suggestion IDs the user accepted (`event.accepted`).
  ///
  /// For each accepted suggestion:
  ///   - `SuggestionType.scaleDown`: replaces the habit's template fields with
  ///     a simpler version (resets completions/streak to 0).
  ///   - `SuggestionType.replace`: archives the old habit and adds a brand-new
  ///     stack based on the replacement template.
  void applyRecalibration(RecalibrationEvent event) {
    // Start with a mutable copy of the stacks list (using spread to copy it).
    var updatedStacks = [...state.stacks];

    // Iterate over the IDs of suggestions the user chose to accept.
    for (final sid in event.accepted) {
      // Find the full suggestion object matching this accepted ID.
      // `orElse` prevents a crash if the ID is somehow not found.
      final suggestion = event.suggestions.firstWhere(
        (s) => s.id == sid,
        orElse: () => event.suggestions.first,
      );

      // SCALE DOWN: Swap the habit's fields with a simpler template, but keep
      // the same stack entry (same ID, just updated content). Resets progress.
      if (suggestion.type == SuggestionType.scaleDown &&
          suggestion.habitId != null &&
          suggestion.replacementTemplateId != null) {
        // Look up the template from the built-in habit library.
        // The `!` asserts non-null (we already checked `!= null` above).
        final template = findTemplate(suggestion.replacementTemplateId!);
        if (template != null) {
          updatedStacks = updatedStacks.map((s) {
            if (s.id != suggestion.habitId) return s; // Not the target — skip.
            // Replace content fields with the simpler template, reset progress.
            return s.copyWith(
              title: template.title,
              anchorCue: template.anchorCue,
              action: template.action,
              reward: template.reward,
              completions: [], // Reset — starting fresh with new habit.
              streak: 0, // Streak resets.
              myelinationLevel: 0, // Myelination resets — new neural pathway.
            );
          }).toList();
        }
      }

      // REPLACE: Archive the old habit and add a completely new stack from the
      // replacement template. The user starts fresh with a new ID and 0 progress.
      if (suggestion.type == SuggestionType.replace &&
          suggestion.habitId != null &&
          suggestion.replacementTemplateId != null) {
        final template = findTemplate(suggestion.replacementTemplateId!);
        if (template != null) {
          // Step 1: Archive (soft-delete) the old habit.
          updatedStacks = updatedStacks
              .map((s) => s.id == suggestion.habitId ? s.copyWith(isActive: false) : s)
              .toList();

          // Step 2: Create a brand-new stack from the template.
          final newStack = NeuroStack(
            id: 'stack-${_uuid.v4()}', // New unique ID — this is a different habit.
            title: template.title,
            anchorCue: template.anchorCue,
            action: template.action,
            reward: template.reward,
            category: template.category,
            acetylcholineDuration: 10, // Default focus duration for new habits.
            myelinationLevel: 0,
            streak: 0,
            completions: const [],
            createdAt: DateTime.now().toIso8601String(),
            isActive: true,
          );
          // Prepend the new stack — it appears at the top of the habits list.
          updatedStacks = [newStack, ...updatedStacks];
        }
      }
    }

    // Mark the most recent check-in as having had a recalibration applied.
    // `.skip(1)` returns all elements after the first as a lazy Iterable.
    // The spread `...` materialises it back into a list.
    final updatedCheckins = state.checkinHistory.isEmpty
        ? state.checkinHistory // Nothing to update if no check-ins yet.
        : [
            state.checkinHistory.first.copyWith(recalibrationApplied: true), // Update latest.
            ...state.checkinHistory.skip(1), // Keep the rest unchanged.
          ];

    _save(state.copyWith(
      stacks: updatedStacks,
      checkinHistory: updatedCheckins,
      recalibrationLog: [event, ...state.recalibrationLog], // Record this recalibration.
    ));
  }

  /// Upgrades the user to Pro tier, removing all free-tier limits.
  /// The `=>` ("fat arrow") syntax is shorthand for a one-liner method body.
  void upgradeToPro() => _save(state.copyWith(isPro: true));

  /// Marks onboarding as complete and awards 50 dopamine points as a welcome reward.
  /// Also uses `=>` shorthand for the single-expression body.
  void completeOnboarding() => _save(state.copyWith(
        onboardingComplete: true,
        dopaminePoints: 50, // Welcome bonus — gives the user a head start.
      ));

  // ── GLOBAL ────────────────────────────────────────────────────────────────

  /// Applies a natural decay to all neurochemical levels.
  ///
  /// This is called periodically (e.g., once per day) to simulate the brain
  /// returning toward baseline when habits aren't being performed. Levels that
  /// are above baseline drift back down; levels below baseline may drift up.
  ///
  /// The actual decay formula is in `decayNeurochemical()` in neuro_helpers.dart.
  void decayNeurochemistry() {
    final chem = state.neurochemistry; // Capture current levels for readability.
    _save(state.copyWith(
      neurochemistry: Neurochemistry(
        dopamine: decayNeurochemical(chem.dopamine), // Apply decay to each chemical.
        acetylcholine: decayNeurochemical(chem.acetylcholine),
        epinephrine: decayNeurochemical(chem.epinephrine),
        gaba: decayNeurochemical(chem.gaba),
      ),
    ));
  }

  /// Wipes all app data and returns to the empty initial state.
  /// Used from the Settings screen's "Reset All Data" button.
  ///
  /// `NeuroState.initial()` returns a fresh blank state — this is equivalent
  /// to uninstalling and reinstalling the app (for local data).
  void resetAllData() {
    _save(NeuroState.initial());
  }
}

// ---------------------------------------------------------------------------
// PROVIDER REGISTRATION
// ---------------------------------------------------------------------------

/// The main Riverpod provider that widgets use to access the app's state.
///
/// `NotifierProvider` is the Riverpod provider type for classes that extend
/// `Notifier`. It takes two type parameters:
///   - `NeuroNotifier` — the class that manages state and exposes methods.
///   - `NeuroState`    — the type of value the provider holds.
///
/// `NeuroNotifier.new` is Dart shorthand for `() => NeuroNotifier()` — it
/// passes the constructor itself as a factory function.
///
/// HOW TO USE IN A WIDGET:
///   ```dart
///   // Read state (rebuilds widget when state changes):
///   final state = ref.watch(neuroProvider);
///
///   // Call a method (does NOT rebuild — just triggers an action):
///   ref.read(neuroProvider.notifier).completeNeuroStack(id);
///   ```
final neuroProvider = NotifierProvider<NeuroNotifier, NeuroState>(NeuroNotifier.new);
