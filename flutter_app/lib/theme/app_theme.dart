import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _indigo = Color(0xFF6366F1);
const _indigoDark = Color(0xFF4F46E5);
const _bgDark = Color(0xFF0A0F1E);
const _surfaceDark = Color(0xFF0F1629);
const _cardDark = Color(0xFF141D35);
const _borderDark = Color(0xFF1E2A45);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFF94A3B8);

const _bgLight = Color(0xFFF8FAFC);
const _surfaceLight = Color(0xFFFFFFFF);
const _cardLight = Color(0xFFF1F5F9);
const _borderLight = Color(0xFFE2E8F0);

// Neurochemical colors
const dopamineColor = Color(0xFFF59E0B);
const acetylcholineColor = Color(0xFF3B82F6);
const epinephrineColor = Color(0xFFEF4444);
const gabaColor = Color(0xFF10B981);

// Category colors
const focusColor = Color(0xFF6366F1);
const wellnessColor = Color(0xFF10B981);
const mindsetColor = Color(0xFF8B5CF6);
const fitnessColor = Color(0xFFF97316);

ThemeData darkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: _bgDark,
    colorScheme: const ColorScheme.dark(
      primary: _indigo,
      secondary: _indigoDark,
      surface: _surfaceDark,
      onSurface: _textPrimary,
      outline: _borderDark,
    ),
    cardTheme: CardThemeData(
      color: _cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderDark, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _bgDark,
      elevation: 0,
      foregroundColor: _textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: _textPrimary,
      displayColor: _textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _indigo),
      ),
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: const TextStyle(color: _textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

ThemeData lightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: _bgLight,
    colorScheme: const ColorScheme.light(
      primary: _indigo,
      secondary: _indigoDark,
      surface: _surfaceLight,
      onSurface: Color(0xFF0F172A),
      outline: _borderLight,
    ),
    cardTheme: CardThemeData(
      color: _surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderLight, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _bgLight,
      elevation: 0,
      foregroundColor: Color(0xFF0F172A),
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _indigo),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => isDark ? _cardDark : _surfaceLight;
  Color get borderColor => isDark ? _borderDark : _borderLight;
  Color get textSecondary => _textSecondary;
  Color get bgColor => isDark ? _bgDark : _bgLight;
}
