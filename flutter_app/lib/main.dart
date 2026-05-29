// TODO SETUP — Run the app with your Supabase credentials:
//
//   flutter run \
//     --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
//
// Get these from: Supabase dashboard → Project Settings → API

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/neuro_provider.dart';
import 'services/notification_service.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase (gracefully no-ops when credentials are not provided)
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  // Local notifications
  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString('neuroflow-state-v1');
  final initialState = savedJson != null
      ? NeuroState.fromJson(jsonDecode(savedJson) as Map<String, dynamic>)
      : NeuroState.initial();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialStateProvider.overrideWithValue(initialState),
      ],
      child: const _LifecycleWrapper(),
    ),
  );
}

/// Wraps the app to manage notification scheduling on lifecycle events.
class _LifecycleWrapper extends StatefulWidget {
  const _LifecycleWrapper();
  @override
  State<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends State<_LifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cancel the loss aversion nudge on fresh launch (user opened app)
    NotificationService.cancelLossAversionNudge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Schedule loss aversion nudge — fires if user doesn't open app for 3 days
      NotificationService.scheduleLossAversionNudge(daysFromNow: 3);
    } else if (state == AppLifecycleState.resumed) {
      // Cancel nudge when user comes back
      NotificationService.cancelLossAversionNudge();
    }
  }

  @override
  Widget build(BuildContext context) => const NeuroFlowApp();
}
