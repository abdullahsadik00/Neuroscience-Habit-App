import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'theme/app_theme.dart';
import 'providers/neuro_provider.dart';
import 'providers/auth_provider.dart';
import 'pages/auth_gate_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/brain_assessment_page.dart';
import 'pages/routine_blueprint_page.dart';
import 'pages/dashboard_page.dart';

// Whether Supabase was actually initialised (credentials were provided).
bool get _supabaseReady {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

class NeuroFlowApp extends ConsumerWidget {
  const NeuroFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'NeuroFlow',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When Supabase is configured, gate on auth first.
    if (_supabaseReady) {
      final authAsync = ref.watch(authStateProvider);

      // While the auth stream is loading, show a blank scaffold.
      if (authAsync.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final user = ref.watch(currentUserProvider);
      if (user == null) return const AuthGatePage();

      // Signed in — pull cloud state once on auth change.
      ref.listen(authStateProvider, (_, next) {
        next.whenData((event) {
          if (event.session != null) {
            ref.read(neuroProvider.notifier).loadFromCloud();
          }
        });
      });
    }

    final state = ref.watch(neuroProvider);
    if (!state.onboardingComplete) return const OnboardingPage();
    if (state.brainProfile == null) return const BrainAssessmentPage();
    if (!state.blueprintAccepted) return const RoutineBlueprintPage();
    return const DashboardPage();
  }
}
