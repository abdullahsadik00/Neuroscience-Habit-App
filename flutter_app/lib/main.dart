// TODO SETUP — Run the app with your Supabase credentials:
//
//   flutter run \
//     --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
//
// Get these from: Supabase dashboard → Project Settings → API
// The anon key is safe to include in client apps — it's row-level-security gated.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/neuro_provider.dart';

// Compile-time constants injected via --dart-define
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase (no-ops gracefully if URL/key are empty during dev)
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

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
      child: const NeuroFlowApp(),
    ),
  );
}
