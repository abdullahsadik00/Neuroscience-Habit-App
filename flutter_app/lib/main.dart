// =============================================================================
// FILE: main.dart
// =============================================================================
// This is the entry point of the entire Flutter application — the first file
// that executes when the app launches.
//
// ROLE IN APP ARCHITECTURE:
//   main.dart sits at the very top of the dependency tree:
//     main.dart
//       └── ProviderScope         (Riverpod's state container for the whole app)
//             └── _LifecycleWrapper  (listens to app foreground/background events)
//                   └── NeuroFlowApp  (defined in app.dart — the root Widget tree)
//                         └── screens, providers, services …
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   1. Flutter entry point — Dart programs always start at main(). In Flutter,
//      main() must call runApp() which hands control to the Flutter framework.
//   2. Async initialization — Some services (Supabase, notifications, disk
//      storage) must finish setting up before the UI appears. We use `async /
//      await` to wait for each one in sequence.
//   3. Riverpod ProviderScope — Riverpod is the state-management library used
//      throughout this app. ProviderScope is an invisible widget that wraps the
//      whole app and acts as a global container for all app state (providers).
//      Without it, no provider would work.
//   4. SharedPreferences — A key-value store backed by the device's local disk.
//      Used here to persist and reload the user's habit data across restarts.
//   5. App lifecycle — On mobile, apps can be foregrounded, backgrounded, or
//      killed. _LifecycleWrapper observes these transitions so we can schedule
//      or cancel reminder notifications at the right moment.
// =============================================================================

// TODO SETUP — Run the app with your Supabase credentials:
//
//   flutter run \
//     --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
//
// Get these from: Supabase dashboard → Project Settings → API

// ---------------------------------------------------------------------------
// IMPORTS
// ---------------------------------------------------------------------------

// dart:convert — Dart's built-in library for encoding/decoding data formats.
// We use `jsonDecode` to turn a stored JSON string back into a Dart Map.
import 'dart:convert';

// flutter/material.dart — The core Flutter package. Gives us Material Design
// widgets (buttons, text fields, scaffolds) and the Widget base classes that
// every Flutter UI element extends from.
import 'package:flutter/material.dart';

// flutter_riverpod — The Riverpod state-management library.
// Provides ProviderScope, ConsumerWidget, ref.watch, ref.read, etc.
// Think of Riverpod as a system that keeps data (state) outside widgets so
// multiple screens can share and react to the same data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// shared_preferences — Stores small pieces of data to the device's disk as
// simple key-value pairs. Here we store the serialised habit state so it
// survives the app being closed and reopened.
import 'package:shared_preferences/shared_preferences.dart';

// supabase_flutter — The official Supabase SDK for Flutter.
// Supabase is the cloud backend (database + auth). This import is needed to
// call Supabase.initialize() during startup so the rest of the app can make
// authenticated API calls.
import 'package:supabase_flutter/supabase_flutter.dart';

// app.dart — Our own file that defines NeuroFlowApp, the root widget of the
// visual widget tree (handles routing, theme, MaterialApp setup, etc.).
import 'app.dart';

// providers/neuro_provider.dart — Our own file that declares the Riverpod
// providers for habit state. We import NeuroState (the data model),
// sharedPreferencesProvider, and initialStateProvider so we can set up their
// initial values here in main() before the UI renders.
import 'providers/neuro_provider.dart';

// services/notification_service.dart — Our own file that wraps the local
// push-notification plugin. Exposes static methods like init(),
// scheduleLossAversionNudge(), and cancelLossAversionNudge().
import 'services/notification_service.dart';

// ---------------------------------------------------------------------------
// COMPILE-TIME CONSTANTS — Supabase credentials
// ---------------------------------------------------------------------------

// String.fromEnvironment() reads a value that was baked into the binary at
// compile time via `--dart-define=KEY=VALUE`. If the flag was not passed, the
// result is an empty string ''. This lets the app run without crashing even
// when Supabase credentials are absent (offline / local-only mode).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL'); // The URL of the Supabase project (e.g. https://xyz.supabase.co)
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY'); // The anonymous (public) API key for the project

// ---------------------------------------------------------------------------
// ENTRY POINT
// ---------------------------------------------------------------------------

/// main() is the very first function Dart calls when the app launches.
/// It is marked `async` because we need to `await` several initialization
/// steps before drawing any UI.
///
/// Sequence of operations:
///   1. Bind Flutter engine to the platform (required before any plugin calls).
///   2. Initialize Supabase (if credentials are provided).
///   3. Initialize the local notification service.
///   4. Load previously saved app state from the device disk.
///   5. Hand control to Flutter by calling runApp().
void main() async {
  // WidgetsFlutterBinding.ensureInitialized() MUST be called first whenever
  // main() is async and you need to call plugin code before runApp().
  // It connects the Flutter engine (which draws pixels) to the platform
  // (iOS / Android). Without this, plugin calls would throw an error because
  // the engine isn't ready yet.
  WidgetsFlutterBinding.ensureInitialized();

  // --- Supabase initialization (gracefully no-ops when credentials are not provided) ---
  // We only initialise Supabase when both URL and key are present.
  // This allows the app to run fully offline / in a demo mode without a backend.
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    // Supabase.initialize() sets up the global Supabase client singleton.
    // After this call, anywhere in the app you can write:
    //   Supabase.instance.client.from('table').select()
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  // --- Local notifications ---
  // NotificationService.init() requests OS permission and configures the
  // notification channels. Must be done before scheduling any notifications.
  // `await` ensures it completes before we continue.
  await NotificationService.init();

  // --- Load persisted state from device storage ---
  // SharedPreferences.getInstance() returns a Future (a value that will be
  // available later). `await` pauses execution here until the disk is ready.
  final prefs = await SharedPreferences.getInstance();

  // Try to retrieve the JSON string we saved last time the app ran.
  // prefs.getString() returns null if the key doesn't exist yet (first launch).
  final savedJson = prefs.getString('neuroflow-state-v1');

  // Ternary expression:  condition ? valueIfTrue : valueIfFalse
  // If savedJson is not null (we have saved data), parse it into a NeuroState
  // object. Otherwise create a blank starting state with NeuroState.initial().
  //
  // jsonDecode(savedJson) turns the JSON string into a Dart dynamic object.
  // We cast it `as Map<String, dynamic>` so Dart knows the shape of the data.
  // NeuroState.fromJson() is a factory constructor that reads that map and
  // builds the typed NeuroState value.
  final initialState = savedJson != null
      ? NeuroState.fromJson(jsonDecode(savedJson) as Map<String, dynamic>)
      : NeuroState.initial();

  // --- Launch the Flutter widget tree ---
  // runApp() takes a Widget and inflates it as the root of the UI.
  // Everything nested inside it becomes the visible app.
  runApp(
    // ProviderScope is a Riverpod widget that MUST wrap the entire app.
    // It is the container that holds all provider state. Without it, calling
    // ref.watch() or ref.read() anywhere in the app would throw an error.
    ProviderScope(
      // `overrides` let us inject specific values into providers before the
      // app starts. This is how we supply the SharedPreferences instance and
      // the pre-loaded initial state to the rest of the app without each
      // widget having to fetch them independently.
      overrides: [
        // Tell sharedPreferencesProvider to use the `prefs` instance we
        // already loaded above, instead of loading it again.
        sharedPreferencesProvider.overrideWithValue(prefs),

        // Tell initialStateProvider to use the state we just reconstructed
        // from disk (or a blank state on first run).
        initialStateProvider.overrideWithValue(initialState),
      ],
      // The actual UI tree starts here. _LifecycleWrapper is an invisible
      // wrapper that observes app lifecycle events; it renders NeuroFlowApp.
      child: const _LifecycleWrapper(),
    ),
  );
}

// ---------------------------------------------------------------------------
// LIFECYCLE WRAPPER
// ---------------------------------------------------------------------------

/// _LifecycleWrapper is a StatefulWidget whose sole job is to observe the
/// app's foreground / background lifecycle and schedule or cancel the
/// "loss aversion nudge" notification accordingly.
///
/// WHY A SEPARATE WRAPPER?
///   NeuroFlowApp (in app.dart) is a ConsumerWidget focused on rendering.
///   Keeping lifecycle logic here separates concerns and makes both classes
///   easier to reason about and test.
///
/// EXTENDS StatefulWidget:
///   A StatefulWidget has mutable state that can change over time.
///   Unlike a StatelessWidget (which is just a fixed description of UI),
///   StatefulWidget pairs with a State object that lives as long as the widget
///   is on screen and can call setState() to trigger rebuilds.
///   Here we don't actually call setState() — we use the State object purely
///   to get access to lifecycle hooks (initState, dispose, didChangeAppLifecycleState).
class _LifecycleWrapper extends StatefulWidget {
  // `const` constructor — tells Dart this widget's configuration never changes
  // at runtime, allowing Flutter to cache and reuse it for performance.
  const _LifecycleWrapper();

  /// createState() is called by Flutter exactly once when this widget is first
  /// inserted into the widget tree. It must return the associated State object.
  @override
  State<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

/// _LifecycleWrapperState is the mutable companion to _LifecycleWrapper.
///
/// It mixes in WidgetsBindingObserver, which is an interface (mixin) provided
/// by Flutter that lets this object receive notifications about changes to the
/// app's lifecycle (foreground, background, paused, resumed, etc.).
///
/// `with WidgetsBindingObserver` — Dart's `with` keyword applies a mixin,
/// adding the observer interface's methods to this class without full
/// inheritance. Think of it as "also implement these extra capabilities".
class _LifecycleWrapperState extends State<_LifecycleWrapper> with WidgetsBindingObserver {

  /// initState() is the very first method Flutter calls after the State object
  /// is created and inserted into the tree. Use it for one-time setup.
  /// You MUST call super.initState() first — it runs Flutter's own setup code.
  @override
  void initState() {
    super.initState(); // Always call super first — Flutter requires it.

    // Register this object as an observer. After this line, Flutter will call
    // didChangeAppLifecycleState() on this object whenever the app moves
    // between foreground and background states.
    WidgetsBinding.instance.addObserver(this);

    // Cancel the loss aversion nudge on fresh launch (user opened app).
    // If a nudge was scheduled from a previous background event, clear it now
    // because the user is actively using the app.
    NotificationService.cancelLossAversionNudge();
  }

  /// dispose() is called when this widget is permanently removed from the tree
  /// (e.g. the app shuts down, or the widget is replaced).
  /// Always unregister observers and free resources here to avoid memory leaks.
  @override
  void dispose() {
    // Unregister from the binding so Flutter stops sending lifecycle events
    // to this object after it has been removed from the tree.
    WidgetsBinding.instance.removeObserver(this);

    super.dispose(); // Always call super last in dispose() — Flutter requires it.
  }

  /// didChangeAppLifecycleState() is called by Flutter (via WidgetsBindingObserver)
  /// whenever the app's lifecycle state changes.
  ///
  /// [state] — the new AppLifecycleState. Possible values:
  ///   • resumed  — app is in the foreground and receiving user input.
  ///   • inactive — app is visible but not receiving input (e.g. phone call overlay).
  ///   • paused   — app is in the background (user pressed Home or switched apps).
  ///   • detached — app is being torn down (engine shutting down).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // The app has moved to the background — the user left the app.
      // Schedule a "loss aversion nudge" notification to fire 3 days from now.
      // Loss aversion is a neuroscience principle: people are more motivated by
      // the fear of losing a streak than by gaining a reward.
      //
      // WHY paused and NOT detached?
      //   `detached` fires during engine teardown when the notification plugin's
      //   native context is already destroyed, causing a NullPointerException crash.
      //   `paused` is the safe moment to schedule background work.
      NotificationService.scheduleLossAversionNudge(daysFromNow: 3);
    } else if (state == AppLifecycleState.resumed) {
      // The user has come back to the app — cancel the pending nudge because
      // there is no need to nag someone who is already actively using the app.
      NotificationService.cancelLossAversionNudge();
    }
    // We intentionally ignore `inactive` and `detached` states here:
    //   inactive — transient, no reliable plugin access.
    //   detached — engine shutting down, plugin context may be null (crash risk).
  }

  /// build() is the only required method in any State class.
  /// Flutter calls it whenever this widget needs to render (or re-render).
  /// It must return a Widget — the visual representation of this state.
  ///
  /// Here we simply render NeuroFlowApp (the real root UI widget from app.dart).
  /// The `=>` syntax is Dart's arrow function shorthand for:
  ///   @override Widget build(BuildContext context) { return const NeuroFlowApp(); }
  @override
  Widget build(BuildContext context) => const NeuroFlowApp(); // Delegate all rendering to the real app widget.
}
