// =============================================================================
// resilience_hud.dart
//
// What this file is:
//   The "Heads-Up Display" for the user's Adaptability Score — a proprietary
//   0–1000 metric that measures behavioral resilience: how consistently the
//   user recovers, downscales, and re-engages rather than abandons.
//
// Why this replaces NeurochemHUD:
//   The Neurochemistry bars showed arbitrary numbers that smart users quickly
//   dismissed as pseudoscience. The Adaptability Score measures something the
//   user can actually influence and verify — their comeback and recovery history.
//   Users want to protect and grow this number, just like Strava's Fitness score
//   or Duolingo's Fluency streak.
//
// Visual design:
//   - Circular arc progress bar (CustomPaint) showing 0–1000 progress
//   - Score number centered inside the arc
//   - Tier label below (e.g., "Adaptive Performer")
//   - Optional "+N today" chip when points were earned today
//   - Coaching tip in muted text (personalised by brain profile)
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Displays the user's Adaptability Score as an animated arc gauge.
///
/// Stateless — receives all data via constructor parameters.
/// Parent (dashboard) computes the score and passes it in.
class ResilienceHUD extends StatelessWidget {
  /// The user's current Adaptability Score (0–1000).
  final int score;

  /// Human-readable tier label (e.g., "Adaptive Performer").
  /// Computed by getResilienceLabel() in resilience_score.dart.
  final String label;

  /// A short coaching tip, personalised by brain profile if available.
  /// Computed by getResilienceTip() in resilience_score.dart.
  final String tip;

  /// Points earned today. Shows a "+N today" badge when > 0.
  /// Computed by comparing score snapshots or tracking session deltas.
  final int pointsToday;

  const ResilienceHUD({
    super.key,
    required this.score,
    required this.label,
    required this.tip,
    this.pointsToday = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header row ──────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                'Adaptability Score',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Points earned today badge
              if (pointsToday > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Text(
                    '+$pointsToday today',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Arc gauge + info row ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Arc gauge (CustomPaint circle)
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _ArcGaugePainter(
                    progress: (score / 1000).clamp(0.0, 1.0),
                    trackColor: const Color(0xFF6366F1).withOpacity(0.12),
                    fillColor: const Color(0xFF6366F1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/ 1000',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 9,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(width: 16),

              // Tier label + coaching tip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ArcGaugePainter — draws the circular progress arc
// =============================================================================

/// Custom painter that draws a circular arc progress gauge.
///
/// Renders two arcs:
///   1. A faint full-circle "track" (background)
///   2. A colored partial arc showing the current progress fraction
///
/// The arc starts at the bottom-left (225° in standard math angles, which is
/// the 7 o'clock position visually) and sweeps 270° clockwise, leaving a gap
/// at the bottom of the circle. This is the standard "speedometer" gauge shape.
class _ArcGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color fillColor;

  const _ArcGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6; // 6px inset so the stroke fits inside the box

    // Shared paint settings
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Arc geometry: start at 225° (7 o'clock), sweep 270° clockwise.
    // Flutter's drawArc uses radians, not degrees.
    // `math.pi * (225 / 180)` converts 225° to radians.
    const startAngle = math.pi * 1.25;  // 225° in radians
    const sweepTotal = math.pi * 1.5;   // 270° sweep in radians

    // Draw the faint background track (full 270° arc).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false, // `false` = don't connect to center (arc only, no pie-slice)
      trackPaint,
    );

    // Draw the filled portion — progress fraction of the full sweep.
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * progress, // Only fill the progress fraction
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fillColor != fillColor;
}
