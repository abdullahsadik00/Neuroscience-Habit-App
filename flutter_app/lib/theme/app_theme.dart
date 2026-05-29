// ============================================================
// FILE: app_theme.dart
//
// What this file is:
//   This file defines the visual design system for the entire app —
//   colors, typography, button styles, card shapes, and more.
//
// Role in the app architecture:
//   Flutter apps have a single root MaterialApp widget (in main.dart)
//   that accepts a `theme` and optionally a `darkTheme`. This file
//   provides those two ThemeData objects: darkTheme() and lightTheme().
//   Every widget throughout the app automatically inherits these styles
//   without needing to pass colors or fonts manually.
//
// Key concepts a learner needs to know:
//   - ThemeData: Flutter's object that bundles all visual settings
//     (colors, fonts, button styles, etc.) into one place.
//   - Material 3 (M3): Google's latest design system. Setting
//     useMaterial3: true tells Flutter to use the newer, rounded
//     visual style across built-in widgets.
//   - ColorScheme: A structured set of named roles (primary, surface,
//     onSurface, etc.) so widgets know which color to use in each context.
//   - Extension methods: Dart lets you add new methods/getters to
//     existing classes you don't own. Here we extend BuildContext so
//     any widget can call `context.cardBg` to get the right color.
//   - const: Tells Dart these values are known at compile time and
//     never change, which improves performance.
// ============================================================

// Brings in Flutter's core UI library — required for Color, ThemeData,
// ColorScheme, AppBarTheme, CardThemeData, BorderRadius, etc.
import 'package:flutter/material.dart';

// Brings in the google_fonts package — lets us use web fonts (like Inter)
// without bundling font files manually in the app assets.
import 'package:google_fonts/google_fonts.dart';

// ── Private color constants (dark palette) ───────────────────────────────────
// The leading underscore (_) is Dart's convention for "private to this file".
// `const` means the value is baked in at compile time — faster and uses less memory.
// Color() takes a hex value in 0xAARRGGBB format: AA=opacity, RR=red, GG=green, BB=blue.

const _indigo = Color(0xFF6366F1);       // Main brand/accent color — used for primary actions and highlights
const _indigoDark = Color(0xFF4F46E5);   // Slightly darker indigo — used as the secondary brand color
const _bgDark = Color(0xFF0A0F1E);       // Near-black navy — the main page background in dark mode
const _surfaceDark = Color(0xFF0F1629);  // Very dark navy — used for surfaces like bottom sheets and dialogs
const _cardDark = Color(0xFF141D35);     // Slightly lighter navy — the background color for card widgets
const _borderDark = Color(0xFF1E2A45);   // Muted navy — drawn as the border/outline around cards and inputs
const _textPrimary = Color(0xFFFFFFFF);  // Pure white — used for headings and body text in dark mode
const _textSecondary = Color(0xFF94A3B8);// Cool grey — used for hints, labels, and less important text

// ── Private color constants (light palette) ──────────────────────────────────

const _bgLight = Color(0xFFF8FAFC);     // Off-white — the main page background in light mode
const _surfaceLight = Color(0xFFFFFFFF); // Pure white — surfaces and card backgrounds in light mode
const _cardLight = Color(0xFFF1F5F9);   // Very light grey — used to fill input fields in light mode
const _borderLight = Color(0xFFE2E8F0); // Pale grey — drawn as borders around cards and inputs in light mode

// ── Neurochemical colors (public — used by widgets across the app) ─────────────
// These are NOT prefixed with _ because other files import and use them directly.
// Each color visually represents a neurotransmitter in the habit tracking UI.

const dopamineColor = Color(0xFFF59E0B);     // Amber/yellow — represents dopamine (reward and motivation)
const acetylcholineColor = Color(0xFF3B82F6);// Blue — represents acetylcholine (focus and learning)
const epinephrineColor = Color(0xFFEF4444);  // Red — represents epinephrine/adrenaline (energy and alertness)
const gabaColor = Color(0xFF10B981);         // Green — represents GABA (calm and recovery)

// ── Category colors (public — used to color-code habit categories) ────────────

const focusColor = Color(0xFF6366F1);    // Indigo — used for the "Focus" habit category
const wellnessColor = Color(0xFF10B981); // Green — used for the "Wellness" habit category
const mindsetColor = Color(0xFF8B5CF6);  // Purple — used for the "Mindset" habit category
const fitnessColor = Color(0xFFF97316);  // Orange — used for the "Fitness" habit category

// ── darkTheme() ───────────────────────────────────────────────────────────────

/// Builds and returns the complete dark-mode ThemeData for the app.
///
/// This function is called once in main.dart and passed to MaterialApp's
/// `darkTheme` parameter. Flutter uses it automatically when the device
/// is in dark mode (or when the app forces dark mode).
///
/// Returns a [ThemeData] object with every visual property configured
/// for a dark, high-contrast interface.
ThemeData darkTheme() {
  // ThemeData.dark() gives us a sensible baseline dark theme from Flutter.
  // useMaterial3: true opts into Material Design 3 — newer rounded shapes,
  // tonal colors, and updated component styles compared to Material 2.
  final base = ThemeData.dark(useMaterial3: true);

  // copyWith() creates a modified copy of `base`, overriding only the
  // properties we specify — everything else keeps its default value.
  return base.copyWith(
    // Sets the background color of every Scaffold (the main screen container).
    scaffoldBackgroundColor: _bgDark,

    // ColorScheme assigns semantic color "roles" that built-in Flutter widgets
    // read automatically — e.g., ElevatedButton uses `primary` for its background.
    colorScheme: const ColorScheme.dark(
      primary: _indigo,           // Main action color — buttons, active states, selected items
      secondary: _indigoDark,     // Supporting brand color — used for secondary actions
      surface: _surfaceDark,      // Background of surfaces like Cards, BottomSheet, Dialog
      onSurface: _textPrimary,    // Text/icons that sit ON TOP of surface-colored backgrounds
      outline: _borderDark,       // Borders drawn around outlined widgets (e.g., OutlinedButton)
    ),

    // CardThemeData controls the default appearance of every Card widget in the app.
    cardTheme: CardThemeData(
      color: _cardDark,   // Fill color of the card background
      elevation: 0,       // Removes the drop shadow — we use a border instead for a flat look

      // ShapeBorder defines the outline and corner shape of the card.
      // RoundedRectangleBorder gives rounded corners and lets us add a border stroke.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // All four corners rounded to 16 logical pixels
        side: const BorderSide(color: _borderDark, width: 1), // Thin border line around the card
      ),
    ),

    // AppBarTheme controls the default look of every AppBar (the top navigation bar).
    appBarTheme: const AppBarTheme(
      backgroundColor: _bgDark,       // AppBar blends with the page background (no visible bar)
      elevation: 0,                   // No shadow under the app bar
      foregroundColor: _textPrimary,  // Color for the title text and icon buttons in the app bar
    ),

    // GoogleFonts.interTextTheme() replaces Flutter's default font (Roboto) with
    // "Inter" — a clean, modern typeface designed for screen readability.
    // .apply() then sets body and display text colors to white across all text styles.
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: _textPrimary,    // Applied to paragraph/body text styles
      displayColor: _textPrimary, // Applied to large heading/display text styles
    ),

    // InputDecorationTheme sets defaults for every TextField and TextFormField.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,         // Enables a background fill color inside the input field
      fillColor: _cardDark, // The fill color (slightly lighter than the page background)

      // `border` is the default border shape when no state override applies.
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners on the input box
        borderSide: const BorderSide(color: _borderDark), // Border color in default state
      ),

      // `enabledBorder` overrides the border when the input is enabled but not focused.
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderDark),
      ),

      // `focusedBorder` overrides the border when the user has tapped into the field.
      // We switch to indigo so the active input is visually highlighted.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _indigo), // Indigo glow when field is active
      ),

      labelStyle: const TextStyle(color: _textSecondary), // Floating label color above the field
      hintStyle: const TextStyle(color: _textSecondary),  // Placeholder hint text color
    ),

    // ElevatedButtonThemeData sets the default style for every ElevatedButton.
    elevatedButtonTheme: ElevatedButtonThemeData(
      // ElevatedButton.styleFrom() is a convenience constructor for ButtonStyle.
      style: ElevatedButton.styleFrom(
        backgroundColor: _indigo,          // Button fill color
        foregroundColor: Colors.white,     // Text and icon color on the button
        // RoundedRectangleBorder with a radius gives the button pill-like rounded corners.
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // EdgeInsets.symmetric sets horizontal and vertical padding independently.
        // horizontal: 24 adds space left/right; vertical: 14 makes the button taller.
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

// ── lightTheme() ──────────────────────────────────────────────────────────────

/// Builds and returns the complete light-mode ThemeData for the app.
///
/// This function is called once in main.dart and passed to MaterialApp's
/// `theme` parameter. Flutter uses it when the device is in light mode.
///
/// The structure mirrors darkTheme() exactly — the only differences are
/// the color values (lighter backgrounds, dark text instead of white).
///
/// Returns a [ThemeData] object configured for a clean, light interface.
ThemeData lightTheme() {
  // ThemeData.light() provides a white-based baseline to build on top of.
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: _bgLight, // Off-white page background in light mode

    colorScheme: const ColorScheme.light(
      primary: _indigo,                    // Same brand indigo for actions in both modes
      secondary: _indigoDark,              // Darker indigo for secondary actions
      surface: _surfaceLight,              // Pure white surface backgrounds
      onSurface: Color(0xFF0F172A),        // Near-black text that sits on white surfaces
      outline: _borderLight,              // Light grey borders around outlined widgets
    ),

    cardTheme: CardThemeData(
      color: _surfaceLight, // White card backgrounds (no tint needed in light mode)
      elevation: 0,         // Flat style — border provides visual separation instead of shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Same 16px rounded corners as dark mode
        side: const BorderSide(color: _borderLight, width: 1), // Subtle grey border stroke
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _bgLight,         // App bar blends into the page (invisible bar background)
      elevation: 0,                      // No shadow
      foregroundColor: Color(0xFF0F172A),// Dark text/icon color in the app bar for contrast
    ),

    // In light mode we don't call .apply() — the base Inter theme already has
    // appropriate dark text colors for a white background.
    textTheme: GoogleFonts.interTextTheme(base.textTheme),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,          // Enable background fill
      fillColor: _cardLight, // Very light grey fill for input fields

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderLight),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderLight), // Light grey border when not focused
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _indigo), // Indigo border when the user is typing
      ),
      // Note: labelStyle and hintStyle are omitted here — they inherit
      // sensible defaults from the light base theme automatically.
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      // Buttons look identical in both modes — same indigo brand color.
      style: ElevatedButton.styleFrom(
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

// ── ThemeColors extension on BuildContext ─────────────────────────────────────
//
// PATTERN — Extension Methods:
//   Dart lets you add methods and getters to types you don't own, using the
//   `extension` keyword. Here we extend BuildContext, which is the object
//   Flutter gives every widget to look up things like the current theme.
//
//   After this extension is imported, any widget can write:
//     context.cardBg     — instead of manually checking isDark every time
//     context.isDark     — quick boolean: is the app in dark mode right now?
//
//   This is purely convenience — no new data is created, it just wraps the
//   theme lookup in a cleaner API that widgets can use without boilerplate.

/// Adds theme-aware color helpers to [BuildContext] so widgets can access
/// the correct color for the current light/dark mode without writing
/// repetitive `Theme.of(context).brightness` checks everywhere.
extension ThemeColors on BuildContext {
  /// Returns true if the app is currently in dark mode, false if light mode.
  ///
  /// `Theme.of(this)` — reads the active ThemeData from the widget tree.
  /// `.brightness` — a property that is either Brightness.dark or Brightness.light.
  /// `== Brightness.dark` — compares to determine the current mode.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Returns the correct card background color for the current mode.
  ///
  /// The `? :` is Dart's ternary (conditional) operator:
  ///   isDark ? valueIfTrue : valueIfFalse
  Color get cardBg => isDark ? _cardDark : _surfaceLight;

  /// Returns the correct border/outline color for the current mode.
  Color get borderColor => isDark ? _borderDark : _borderLight;

  /// Returns the muted secondary text color (same in both modes — grey works on both).
  Color get textSecondary => _textSecondary;

  /// Returns the correct page background color for the current mode.
  Color get bgColor => isDark ? _bgDark : _bgLight;
}
