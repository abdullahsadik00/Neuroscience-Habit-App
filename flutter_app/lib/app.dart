// =============================================================================
// FILE: app.dart
//
// This file is the top-level application widget for the NeuroFlow Flutter app.
//
// ROLE IN ARCHITECTURE:
//   main.dart boots Flutter and hands control to NeuroFlowApp (defined here).
//   This file is responsible for two things:
//     1. Configuring the whole-app look-and-feel (themes, title, debug banner).
//     2. Deciding WHICH full-screen page to show the user based on their current
//        state (not yet signed in? → AuthGatePage; not yet onboarded? →
//        OnboardingPage; etc.).
//   All page files live in lib/pages/. Theme helpers live in lib/theme/.
//   State is managed via Riverpod providers in lib/providers/.
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   - Widget tree: Flutter builds UI as a tree of Widgets. This file sits near
//     the very root of that tree.
//   - ConsumerWidget: A Riverpod-aware widget that can "watch" state providers
//     and automatically rebuild when that state changes.
//   - Riverpod providers: Objects that hold and expose shared app state.
//     ref.watch() subscribes this widget to a provider so it rebuilds on change.
//   - Routing: Flutter doesn't use URL routing here — we just swap which Widget
//     is returned from build() depending on the app state.
//   - Supabase: The backend-as-a-service used for auth and cloud storage.
// =============================================================================

// Flutter's core UI library — provides MaterialApp, Scaffold, Widget, etc.
// "material" refers to Google's Material Design system, which Flutter implements.
import 'package:flutter/material.dart';

// Riverpod is the state management library for this app.
// It lets widgets subscribe to shared state and rebuild automatically.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The Supabase Flutter SDK — handles authentication and cloud database calls.
// We use `show Supabase` to import only the `Supabase` class (not the whole package),
// keeping the namespace clean.
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

// Our custom light/dark theme definitions (colors, fonts, button styles, etc.).
import 'theme/app_theme.dart';

// Riverpod provider that holds app-wide neuroscience/habit state (onboarding
// progress, brain profile, accepted blueprint, habit list, streak data, etc.).
import 'providers/neuro_provider.dart';

// Riverpod providers for authentication state: who is signed in, auth events.
import 'providers/auth_provider.dart';

// The page shown when the user is NOT signed in (login / sign-up screen).
import 'pages/auth_gate_page.dart';

// The page shown after sign-in if the user has never completed onboarding.
import 'pages/onboarding_page.dart';

// The page where the user answers questions to build their personalised
// neuroscience "brain profile".
import 'pages/brain_assessment_page.dart';

// The page that shows the AI-generated habit routine and asks the user to accept it.
import 'pages/routine_blueprint_page.dart';

// The main home screen — shows today's habits, streaks, and progress rings.
import 'pages/dashboard_page.dart';

// -----------------------------------------------------------------------------
// HELPER: _supabaseReady
//
// A computed boolean property (indicated by the `get` keyword in Dart) that
// returns true only if Supabase has been initialised with real credentials.
//
// WHY IT EXISTS: During development, a developer might not have Supabase
// credentials configured. Accessing `Supabase.instance.client` before
// initialisation throws an exception. This getter catches that exception and
// returns false so the app can fall back to a local-only mode.
//
// `bool get` means: "This is a getter named _supabaseReady that returns a bool."
// The underscore prefix (_) means it is private to this file — other files
// cannot use it.
// -----------------------------------------------------------------------------
bool get _supabaseReady {
  try {
    Supabase.instance.client; // Accessing this property throws if not initialised.
    return true; // No exception? Supabase is ready.
  } catch (_) {
    // The underscore after `catch` means we intentionally ignore the error
    // object — we don't need its details, we just know something went wrong.
    return false; // Supabase not initialised → run in local-only mode.
  }
}

// -----------------------------------------------------------------------------
// CLASS: NeuroFlowApp
//
// This is the ROOT widget of the entire application — the single widget that
// wraps everything else.
//
// It extends ConsumerWidget (from Riverpod) instead of the simpler StatelessWidget
// because it needs to read the `themeModeProvider` to know whether the user
// wants light mode, dark mode, or system default.
//
// ConsumerWidget gives the build() method a second argument: `WidgetRef ref`.
// `ref` is your handle to the Riverpod system — you use it to read providers.
//
// WHERE IT IS USED: main.dart wraps this widget in a ProviderScope
// (the Riverpod container) and passes it to runApp().
// -----------------------------------------------------------------------------
class NeuroFlowApp extends ConsumerWidget {
  /// Flutter requires a `key` parameter on widgets to help it efficiently
  /// track and update the widget tree. `super.key` forwards that key to the
  /// parent class. `const` means this widget has no mutable state and can be
  /// created at compile time (a performance optimisation).
  const NeuroFlowApp({super.key});

  /// build() is called by Flutter whenever this widget needs to be drawn.
  /// It must return a Widget — here it returns a MaterialApp.
  ///
  /// [context] — provides information about this widget's location in the tree
  ///             (theme, media query, navigator, etc.).
  /// [ref]     — the Riverpod WidgetRef; use it to read/watch/listen to providers.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(themeModeProvider) subscribes this widget to the theme provider.
    // Whenever the user toggles light/dark mode, `themeMode` gets the new value
    // and Flutter automatically calls build() again to repaint with the new theme.
    final themeMode = ref.watch(themeModeProvider);

    // MaterialApp is the top-level Flutter widget that sets up:
    //   - Navigation (the ability to push/pop screens)
    //   - Theme (colors, typography)
    //   - Localisation
    //   - The OS window title
    return MaterialApp(
      title: 'NeuroFlow', // The app name shown in the OS app switcher.

      debugShowCheckedModeBanner: false, // Hides the red "DEBUG" ribbon in the
      // top-right corner that Flutter shows by default in development builds.

      theme: lightTheme(), // The theme applied when themeMode == ThemeMode.light.
      // lightTheme() is defined in theme/app_theme.dart.

      darkTheme: darkTheme(), // The theme applied when themeMode == ThemeMode.dark.

      themeMode: themeMode, // Tells MaterialApp which theme to currently use
      // (ThemeMode.light, ThemeMode.dark, or ThemeMode.system).

      home: const _AppRouter(), // `home` is the first page displayed when the app
      // opens. Here we hand off to _AppRouter (defined below), which decides
      // the correct first page based on auth and onboarding state.
    );
  }
}

// -----------------------------------------------------------------------------
// CLASS: _AppRouter
//
// This widget acts as a "smart redirect" — it reads app state and returns the
// correct full-screen page widget, effectively routing the user to wherever
// they should be.
//
// It extends ConsumerWidget because it needs to read multiple Riverpod providers
// (auth state and neuroscience state) to make its routing decision.
//
// The underscore prefix (_) makes this class private to this file — it is an
// implementation detail of app.dart and should not be used anywhere else.
//
// The routing logic follows this decision tree:
//   Supabase ready?
//     ├─ YES → Auth loaded?
//     │         ├─ LOADING → show spinner
//     │         └─ LOADED  → User signed in?
//     │                       ├─ NO  → AuthGatePage (login/register)
//     │                       └─ YES → (fall through to onboarding checks)
//     └─ NO  → (skip auth, run locally)
//
//   Onboarding complete?    NO  → OnboardingPage
//   Brain profile set?      NO  → BrainAssessmentPage
//   Blueprint accepted?     NO  → RoutineBlueprintPage
//   Everything done?        YES → DashboardPage  ← the normal home screen
// -----------------------------------------------------------------------------
class _AppRouter extends ConsumerWidget {
  /// No fields needed — this widget reads all state it needs from Riverpod.
  const _AppRouter();

  /// build() is called every time a watched provider changes, which may trigger
  /// a different page to be shown (e.g., once the user completes onboarding,
  /// the onboarding state changes, this widget rebuilds, and now returns
  /// BrainAssessmentPage instead of OnboardingPage).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -------------------------------------------------------------------------
    // STEP 1: Authentication gate (only when Supabase is configured).
    // -------------------------------------------------------------------------
    if (_supabaseReady) {
      // ref.watch(authStateProvider) subscribes to the authentication stream.
      // `authAsync` is an AsyncValue<AuthChangeEvent> — Riverpod's wrapper that
      // can be in one of three states: loading, data (success), or error.
      final authAsync = ref.watch(authStateProvider);

      // `authAsync.isLoading` is true while the auth stream hasn't emitted its
      // first event yet (e.g., the app just launched and is checking the session).
      if (authAsync.isLoading) {
        // Show a blank screen with a spinning loading indicator while we wait.
        // Scaffold is the basic full-screen container Flutter provides.
        // Center + CircularProgressIndicator = the standard "spinner" pattern.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // ref.watch(currentUserProvider) returns the signed-in Supabase User
      // object, or null if nobody is signed in.
      final user = ref.watch(currentUserProvider);

      // If user is null, nobody is signed in — send them to the auth page.
      // The `return` exits build() early; none of the code below runs.
      if (user == null) return const AuthGatePage();

      // -----------------------------------------------------------------------
      // STEP 2: Cloud sync on sign-in.
      //
      // ref.listen() is different from ref.watch():
      //   - ref.watch() rebuilds the widget when the value changes.
      //   - ref.listen() runs a callback (side effect) when the value changes,
      //     WITHOUT triggering a rebuild.
      //
      // Here we listen for auth events (e.g., the user just signed in) and
      // trigger a cloud data load when a valid session is detected.
      // -----------------------------------------------------------------------
      ref.listen(authStateProvider, (_, next) {
        // `next` is the new AsyncValue after the auth state changed.
        // `.whenData()` runs the callback ONLY when `next` holds real data
        // (not loading, not error). `event` is the AuthChangeEvent.
        next.whenData((event) {
          // `event.session != null` means a valid login session exists
          // (i.e., the user just signed in, not signed out).
          if (event.session != null) {
            // ref.read() reads a provider's current value WITHOUT subscribing.
            // We use read (not watch) here because we only want to trigger an
            // action — we don't need this widget to rebuild when neuroProvider
            // changes inside this callback.
            //
            // `.notifier` gives us the NeuroNotifier class (the controller),
            // not just the state value, so we can call methods on it.
            //
            // `loadFromCloud()` fetches the user's habit data from Supabase
            // and updates the local neuroProvider state.
            ref.read(neuroProvider.notifier).loadFromCloud();
          }
        });
      });
    } // End of Supabase auth block.

    // -------------------------------------------------------------------------
    // STEP 3: Onboarding flow routing.
    //
    // At this point we know:
    //   - Either Supabase isn't configured (local mode), OR
    //   - The user is signed in.
    //
    // Now we route based on how far through onboarding the user has progressed.
    // -------------------------------------------------------------------------

    // ref.watch(neuroProvider) subscribes to the full neuroscience state object.
    // `state` contains fields like onboardingComplete, brainProfile, blueprintAccepted.
    final state = ref.watch(neuroProvider);

    // If the user hasn't finished the initial onboarding slides/questions yet,
    // show the onboarding page. The `!` operator means "NOT" — so this reads:
    // "if onboarding is NOT complete, return OnboardingPage".
    if (!state.onboardingComplete) return const OnboardingPage();

    // If the user hasn't completed the brain assessment quiz yet, their
    // brainProfile will be null. The `== null` check catches that case.
    if (state.brainProfile == null) return const BrainAssessmentPage();

    // If the user has a brain profile but hasn't accepted the AI-generated
    // habit blueprint yet, send them to that review/acceptance page.
    if (!state.blueprintAccepted) return const RoutineBlueprintPage();

    // All onboarding steps are done — show the main dashboard (home screen).
    return const DashboardPage();
  }
}
