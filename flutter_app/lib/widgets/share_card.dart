import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../utils/neuro_helpers.dart';
import '../utils/stats_helpers.dart';

/// Fixed-size card rendered into an image for sharing.
/// Must be placed inside a RepaintBoundary with a GlobalKey.
///
/// Hard-codes all colors — never reads from Theme/context so the
/// capture is identical regardless of the app's current theme.
///
/// Displays a 28-day Recovery Heatmap (GitHub-style grid) where:
///   • Emerald green = at least one habit completed
///   • Amber/gold    = Comeback Protocol activated (badge of resilience)
///   • Sky blue      = Lite Mode used (adaptive downscale)
///   • Dark red      = habit existed but was missed
///   • Subtle dark   = no habits existed yet
class ShareCard extends StatelessWidget {
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final double recoveryRate;
  final int bestStreak;
  final String? archetypeName;
  final String userName;

  const ShareCard({
    super.key,
    required this.stacks,
    required this.comebacks,
    required this.recoveryRate,
    required this.bestStreak,
    this.archetypeName,
    this.userName = '',
  });

  // Cell state constants — determines color priority when multiple states apply.
  // Priority (highest to lowest): comeback > completed > liteMode > missed > empty
  static const _cellComeback   = 3;
  static const _cellCompleted  = 2;
  static const _cellLiteMode   = 1;
  static const _cellMissed     = -1;
  static const _cellEmpty      = 0;

  /// Computes 28 cell states for the heatmap, newest-last (left→right, top→bottom).
  List<int> _computeGrid() {
    final today = getLocalDateString(DateTime.now());
    final cells = <int>[];

    // Active stacks only — archived habits shouldn't affect the grid.
    final active = stacks.where((s) => s.isActive).toList();
    // Unique comeback dates for O(1) lookup.
    final comebackDates = comebacks.map((c) => c.date).toSet();

    for (int i = 27; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final dateStr = getLocalDateString(d);

      // Future days are impossible on a share card — guard against clock drift.
      if (dateStr.compareTo(today) > 0) { cells.add(_cellEmpty); continue; }

      // No habits existed yet on this day.
      final anyHabitExisted = active.any((s) => dateStr.compareTo(s.createdAt.substring(0, 10)) >= 0);
      if (!anyHabitExisted) { cells.add(_cellEmpty); continue; }

      // Comeback > completed > liteMode > missed.
      if (comebackDates.contains(dateStr)) {
        cells.add(_cellComeback);
      } else if (active.any((s) => s.completions.contains(dateStr))) {
        cells.add(_cellCompleted);
      } else if (active.any((s) => s.liteModeDates.contains(dateStr))) {
        cells.add(_cellLiteMode);
      } else {
        cells.add(_cellMissed);
      }
    }

    return cells;
  }

  Color _cellColor(int state) {
    switch (state) {
      case _cellComeback:   return const Color(0xFFF59E0B); // amber — comeback gold
      case _cellCompleted:  return const Color(0xFF10B981); // emerald — completed
      case _cellLiteMode:   return const Color(0xFF38BDF8); // sky blue — lite mode
      case _cellMissed:     return const Color(0xFF7F1D1D); // dark red — missed
      default:              return const Color(0xFF1F2937); // subtle dark — empty
    }
  }

  @override
  Widget build(BuildContext context) {
    final grid = _computeGrid();
    final totalComebacks = comebacks.length;

    return SizedBox(
      width: 400,
      height: 520,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F1A), Color(0xFF1A1033)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Subtle dot pattern overlay
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

          // Glow blob top-right
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.18),
              ),
            ),
          ),

          // Glow blob bottom-left
          Positioned(
            bottom: -40, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.14),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Brand row ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NeuroSync',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (userName.isNotEmpty)
                      Text(
                        userName,
                        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Archetype + headline ──────────────────────────────────────
                if (archetypeName != null) ...[
                  Text(
                    archetypeName!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Recovery Heatmap',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Last 28 days',
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 11),
                ),

                const SizedBox(height: 16),

                // ── 28-day heatmap grid (4 rows × 7 cols) ────────────────────
                _HeatmapGrid(cells: grid, cellColor: _cellColor),

                const SizedBox(height: 10),

                // ── Legend row ────────────────────────────────────────────────
                Row(
                  children: [
                    _LegendDot(color: const Color(0xFF10B981), label: 'Done'),
                    const SizedBox(width: 12),
                    _LegendDot(color: const Color(0xFFF59E0B), label: 'Comeback'),
                    const SizedBox(width: 12),
                    _LegendDot(color: const Color(0xFF38BDF8), label: 'Lite Mode'),
                    const SizedBox(width: 12),
                    _LegendDot(color: const Color(0xFF7F1D1D), label: 'Missed'),
                  ],
                ),

                const Spacer(),

                // ── Stats row ─────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _StatBlock(
                      value: '${recoveryRate.round()}%',
                      label: 'Recovery Rate',
                      color: const Color(0xFF8B5CF6),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBlock(
                      value: '${bestStreak}d',
                      label: 'Best Streak',
                      color: const Color(0xFF10B981),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBlock(
                      value: '$totalComebacks',
                      label: 'Comebacks',
                      color: const Color(0xFFF59E0B),
                    )),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Divider + footer ──────────────────────────────────────────
                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'The comeback is stronger\nthan the setback.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      'neurosync.app',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6366F1),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _HeatmapGrid — renders the 4×7 cell grid
// =============================================================================

class _HeatmapGrid extends StatelessWidget {
  final List<int> cells;
  final Color Function(int) cellColor;

  const _HeatmapGrid({required this.cells, required this.cellColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final state = idx < cells.length ? cells[idx] : 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: cellColor(state),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// _LegendDot — colored dot + label for the legend row
// =============================================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 10)),
      ],
    );
  }
}

// =============================================================================
// _StatBlock — compact stat display used in the bottom row
// =============================================================================

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBlock({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 10)),
        ],
      ),
    );
  }
}

// =============================================================================
// _DotPatternPainter — subtle background texture
// =============================================================================

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
