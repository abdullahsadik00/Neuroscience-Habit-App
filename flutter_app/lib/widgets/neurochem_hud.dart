// =============================================================================
// FILE: neurochem_hud.dart
//
// What this file is: A reusable UI widget that displays the user's current
// neurochemical levels (Dopamine, Acetylcholine, Epinephrine, GABA) as a
// horizontal row of animated progress bars — the "Heads-Up Display" for brain
// chemistry state.
//
// Role in app architecture:
//   - This is a "dumb" / presentational widget: it receives a Neurochemistry
//     data object from its parent and just renders it — it does NOT fetch or
//     mutate state itself.
//   - It is used inside screens (e.g., the home dashboard) that pass in the
//     Neurochemistry model obtained from Riverpod providers.
//   - Models are defined in lib/models/models.dart.
//   - Visual styling (colors, card backgrounds) comes from lib/theme/app_theme.dart.
//
// Key concepts a learner needs to understand this file:
//   1. StatelessWidget — a Flutter widget that has no internal mutable state.
//      It takes data in via its constructor and renders once based on that data.
//   2. Widget composition — Flutter UIs are built by nesting widgets inside
//      widgets (like HTML elements inside elements). Container > Column > Row
//      is a common layout pattern.
//   3. Private classes (underscore prefix) — a class named _ChemBar is private
//      to this file, meaning no other file can import and use it directly.
//      This is a Dart convention for internal helper widgets.
//   4. flutter_animate — a third-party package that adds easy fade/slide
//      animation to any widget by calling .animate() on it.
// =============================================================================

// Brings in Flutter's core UI library: material design widgets (Container,
// Column, Row, Text, Icon, etc.), Colors, EdgeInsets, and more.
import 'package:flutter/material.dart';

// Brings in the flutter_animate package, which lets us chain animation effects
// onto any widget with a simple .animate().fadeIn() pattern — no AnimationController needed.
import 'package:flutter_animate/flutter_animate.dart';

// Brings in our app's own data models — specifically the Neurochemistry class,
// which holds fields like dopamine, acetylcholine, epinephrine, and gaba (all doubles 0–100).
import '../models/models.dart';

// Brings in our app's theme helpers — extension methods on BuildContext like
// context.cardBg, context.borderColor, context.textSecondary — so we can read
// the current theme colors without verbose Theme.of(context).colorScheme... calls.
import '../theme/app_theme.dart';

/// NeurochemHUD ("Heads-Up Display") is the main public widget in this file.
///
/// It renders a card showing four neurochemical progress bars side by side.
/// A parent widget (such as the home screen) creates this widget and passes
/// in the current [Neurochemistry] data to display.
///
/// Extends [StatelessWidget] because this widget does not manage any state of
/// its own — it is purely driven by the [neurochemistry] argument passed in.
/// Every time the parent rebuilds and passes new data, this widget re-renders.
class NeurochemHUD extends StatelessWidget {
  /// The neurochemistry data object to display.
  /// Contains four double fields (0–100 range):
  ///   - dopamine, acetylcholine, epinephrine, gaba
  /// The [required] keyword means the caller MUST provide this argument.
  final Neurochemistry neurochemistry;

  /// Constructor for NeurochemHUD.
  ///
  /// [super.key] passes the optional [key] argument up to Flutter's Widget
  /// base class. Flutter uses keys internally to efficiently match widgets
  /// between rebuilds — think of it like a unique ID for the widget.
  /// [required this.neurochemistry] declares and assigns the field in one step.
  const NeurochemHUD({super.key, required this.neurochemistry});

  /// [build] is the single method every StatelessWidget must implement.
  /// Flutter calls it whenever this widget needs to be rendered (or re-rendered).
  ///
  /// [context] is a BuildContext — a handle to the widget's position in the
  /// widget tree. We use it to look up theme colors and text styles.
  ///
  /// Returns a [Widget] tree (the UI structure to draw on screen).
  @override
  Widget build(BuildContext context) {
    // Container is Flutter's equivalent of a styled <div> in HTML.
    // It wraps its child in padding, background color, border, and rounded corners.
    return Container(
      // Adds 16 logical pixels of space on all four sides inside the container.
      // EdgeInsets.all(16) is shorthand for padding on top/right/bottom/left = 16.
      padding: const EdgeInsets.all(16),

      // BoxDecoration lets us style the Container's box (background, border, radius).
      decoration: BoxDecoration(
        // context.cardBg is a custom extension getter defined in app_theme.dart
        // that returns the correct background color for a card in the current theme
        // (light or dark mode). This avoids hardcoding a color value here.
        color: context.cardBg,

        // Makes all four corners rounded with a radius of 16 pixels.
        // A larger number = more rounded corners.
        borderRadius: BorderRadius.circular(16),

        // Draws a 1-pixel border around the container using the theme's border color.
        // Border.all(...) creates a uniform border on all sides.
        border: Border.all(color: context.borderColor),
      ),

      // Column stacks its children vertically (top to bottom), like a vertical flexbox.
      child: Column(
        // Align children to the left (start) of the column rather than centering them.
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ---- SECTION HEADER ROW ----------------------------------------
          // Row lays out its children horizontally (left to right).
          Row(
            children: [
              // A small science/flask icon to visually anchor the section.
              // Icons.science_outlined is a built-in Material Design icon.
              // size: 16 sets the icon to 16x16 logical pixels.
              const Icon(Icons.science_outlined, size: 16, color: Color(0xFF6366F1)),
              // 0xFF6366F1 is an ARGB hex color: FF=fully opaque, 6366F1=indigo.

              // SizedBox is Flutter's way to insert fixed empty space.
              // SizedBox(width: 8) creates an 8-pixel horizontal gap between the icon and text.
              const SizedBox(width: 8),

              // Section label text "Neurochemistry".
              // Theme.of(context).textTheme.labelMedium retrieves the pre-defined
              // "labelMedium" text style from the app's theme (size ~12, etc.).
              // ?.copyWith(...) — the ?. is a null-safe call: if labelMedium is
              // somehow null, this returns null instead of crashing.
              // copyWith creates a modified copy of the style with overrides.
              Text('Neurochemistry', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF6366F1), // Match the icon's indigo color.
                fontWeight: FontWeight.w600,    // Semi-bold text weight.
              )),
            ],
          ),

          // 16-pixel vertical gap between the header row and the bar row below.
          const SizedBox(height: 16),

          // ---- FOUR CHEMICAL BARS ROW ------------------------------------
          // Row containing one _ChemBar widget for each neurochemical.
          Row(
            children: [
              // Dopamine bar — label 'DA', value from the model, color from theme constants,
              // tooltip shows full name on long-press.
              // .animate() — attaches the flutter_animate animation controller to this widget.
              // .fadeIn(delay: 100.ms) — fades this bar in 100 milliseconds after the widget appears.
              // 100.ms is an extension on int provided by flutter_animate, equivalent to Duration(milliseconds: 100).
              _ChemBar(label: 'DA', value: neurochemistry.dopamine, color: dopamineColor, tooltip: 'Dopamine').animate().fadeIn(delay: 100.ms),

              // 8-pixel horizontal gap between bars.
              const SizedBox(width: 8),

              // Acetylcholine bar — fades in 50ms after the dopamine bar (staggered animation).
              _ChemBar(label: 'ACh', value: neurochemistry.acetylcholine, color: acetylcholineColor, tooltip: 'Acetylcholine').animate().fadeIn(delay: 150.ms),

              const SizedBox(width: 8),

              // Epinephrine bar — fades in 50ms after acetylcholine.
              _ChemBar(label: 'EPI', value: neurochemistry.epinephrine, color: epinephrineColor, tooltip: 'Epinephrine').animate().fadeIn(delay: 200.ms),

              const SizedBox(width: 8),

              // GABA bar — fades in last (staggered by 50ms steps creates a cascade effect).
              _ChemBar(label: 'GABA', value: neurochemistry.gaba, color: gabaColor, tooltip: 'GABA').animate().fadeIn(delay: 250.ms),
            ],
          ),
        ],
      ),
    );
  }
}

/// _ChemBar is a private helper widget (note the underscore prefix — private to this file).
///
/// It renders a single neurochemical column: a short label ('DA'), a numeric value,
/// and a colored progress bar beneath them. Four of these are shown side-by-side in
/// the NeurochemHUD above.
///
/// Also extends [StatelessWidget] — it receives all its data through constructor
/// parameters and has no internal state to manage.
class _ChemBar extends StatelessWidget {
  /// The short abbreviation label displayed above the bar (e.g., 'DA', 'ACh').
  final String label;

  /// The neurochemical level, expressed as a number from 0 to 100.
  /// 0 = depleted, 100 = peak level.
  final double value;

  /// The color used for the bar fill and the label text, so each chemical
  /// has a distinct, recognizable color at a glance.
  final Color color;

  /// The full human-readable name of the chemical shown in the tooltip
  /// (e.g., 'Dopamine'). Displayed when the user long-presses the bar.
  final String tooltip;

  /// Constructor — all four fields are required.
  /// No [key] parameter needed here because _ChemBar is a short-lived internal
  /// widget and Flutter can track it by position within its parent Row.
  const _ChemBar({required this.label, required this.value, required this.color, required this.tooltip});

  /// Builds the visual representation of a single chemical bar.
  ///
  /// [context] provides access to the current theme for secondary text color.
  ///
  /// Returns an [Expanded] widget so all four bars share available width equally.
  @override
  Widget build(BuildContext context) {
    // Convert the 0–100 value to a 0.0–1.0 fraction required by LinearProgressIndicator.
    // .clamp(0.0, 1.0) ensures that even if the model has an out-of-range value,
    // we never pass something like 1.5 or -0.2 to the progress bar (which would throw an error).
    final pct = (value / 100).clamp(0.0, 1.0);

    // Expanded tells the Row to give this widget an equal share of the remaining
    // horizontal space. Since there are four _ChemBar widgets and four SizedBox
    // gaps, each bar gets roughly (totalWidth - 3*8) / 4 pixels wide.
    return Expanded(
      // Tooltip shows a popup message with the full chemical name and numeric value
      // when the user long-presses (on mobile) or hovers (on desktop/web).
      child: Tooltip(
        // String interpolation: '$tooltip: ${value.round()}' builds a string like
        // "Dopamine: 73". value.round() converts the double to the nearest integer.
        message: '$tooltip: ${value.round()}',

        // Column stacks label row and progress bar vertically within each chemical's slot.
        child: Column(
          // Align children to the left edge of the column.
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ---- TOP ROW: short label on left, numeric value on right ----------
            Row(
              // mainAxisAlignment: spaceBetween pushes children to opposite ends of
              // the row — label on the far left, number on the far right.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                // Short label (e.g., 'DA') styled in the chemical's own color,
                // slightly bold, at a small 11px font size.
                Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),

                // Numeric value (e.g., '73') in a smaller, secondary-color font.
                // value.round() converts 72.6 → 73 for cleaner display.
                // context.textSecondary is a theme extension for a muted gray color.
                Text('${value.round()}', style: TextStyle(fontSize: 10, color: context.textSecondary)),
              ],
            ),

            // 4-pixel gap between the label row and the progress bar.
            const SizedBox(height: 4),

            // ClipRRect clips its child to rounded corners.
            // Without this, LinearProgressIndicator has square ends;
            // wrapping it in ClipRRect with borderRadius: BorderRadius.circular(4)
            // gives it pill-shaped rounded ends.
            ClipRRect(
              borderRadius: BorderRadius.circular(4), // 4-pixel corner radius on the bar.

              // LinearProgressIndicator is Flutter's built-in horizontal progress bar widget.
              child: LinearProgressIndicator(
                // value (0.0 to 1.0) sets how full the bar is. pct was calculated above.
                value: pct,

                // minHeight sets how tall the progress bar track is in pixels.
                minHeight: 6,

                // The unfilled (background) portion of the bar — a very faint tint
                // of the chemical's color. withOpacity(0.15) means 15% opacity = nearly transparent.
                backgroundColor: color.withOpacity(0.15),

                // AlwaysStoppedAnimation<Color> is a workaround for a Flutter API quirk:
                // LinearProgressIndicator expects an Animation<Color> for the fill color,
                // not just a plain Color. AlwaysStoppedAnimation wraps a static value
                // so it satisfies that type requirement without any actual animation.
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
