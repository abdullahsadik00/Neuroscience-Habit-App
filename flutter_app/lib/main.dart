import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/neuro_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
