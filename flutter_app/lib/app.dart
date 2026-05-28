import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/neuro_provider.dart';
import 'pages/onboarding_page.dart';
import 'pages/brain_assessment_page.dart';
import 'pages/routine_blueprint_page.dart';
import 'pages/dashboard_page.dart';

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
    final state = ref.watch(neuroProvider);

    if (!state.onboardingComplete) return const OnboardingPage();
    if (state.brainProfile == null) return const BrainAssessmentPage();
    if (!state.blueprintAccepted) return const RoutineBlueprintPage();
    return const DashboardPage();
  }
}
