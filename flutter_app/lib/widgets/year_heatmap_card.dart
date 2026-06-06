// =============================================================================
// year_heatmap_card.dart
//
// What this file is:
//   A dashboard card showing the user's full-year (52-week) recovery heatmap —
//   the GitHub contribution graph equivalent for habit resilience.
//
// Design:
//   - 53 week-columns (Sun→Sat rows) scrolling horizontally
//   - Month labels above the columns
//   - Color tiers: emerald=completed, amber=comeback, sky=lite mode,
//     dark red=missed, subtle=empty/future
//   - Today's cell gets an indigo ring
//   - Tap any cell for a brief tooltip
//   - "Share your story" button at the bottom uses share_plus
// =============================================================================

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../utils/stats_helpers.dart';

// Month abbreviations indexed 0=Jan … 11=Dec.
const _kMonthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// Cell size and gap in logical pixels.
const _kCellSize = 10.0;
const _kCellGap = 2.0;
const _kColWidth = _kCellSize + _kCellGap;

/// Displays the full-year recovery heatmap and a share button.
///
/// Stateless — all data is passed in from the parent (dashboard Activity tab).
class YearHeatmapCard extends StatefulWidget {
  /// 53-week grid produced by [getYearGrid].
  final List<List<HeatmapDay>> weeks;

  /// Optional archetype name for the share text (e.g. "The Resilient Analyst").
  final String? archetype;

  /// Adaptability Score (0–1000) to include in the share text.
  final int resilienceScore;

  /// Comeback streak to include in the share text.
  final int comebackStreak;

  const YearHeatmapCard({
    super.key,
    required this.weeks,
    required this.resilienceScore,
    required this.comebackStreak,
    this.archetype,
  });

  @override
  State<YearHeatmapCard> createState() => _YearHeatmapCardState();
}

class _YearHeatmapCardState extends State<YearHeatmapCard> {
  String? _tooltip;

  // Returns the display color for a single cell.
  Color _cellColor(HeatmapDay day) {
    if (day.isFuture) return Colors.transparent;
    if (day.hasComeback) return const Color(0xFFF59E0B);  // amber — comeback
    if (day.completions > 0) return const Color(0xFF10B981); // emerald — done
    if (day.hasLiteMode) return const Color(0xFF38BDF8);  // sky — lite mode
    if (day.isMiss) return const Color(0xFF7F1D1D);       // dark red — missed
    return const Color(0xFF1F2937).withOpacity(0.4);      // subtle — no habits yet
  }

  // Short tooltip text for a cell tap.
  String _cellTooltip(HeatmapDay day) {
    if (day.isFuture) return '';
    if (day.hasComeback) return '${day.dateStr} · Comeback day';
    if (day.completions > 0) return '${day.dateStr} · ${day.completions} habit${day.completions > 1 ? 's' : ''} done';
    if (day.hasLiteMode) return '${day.dateStr} · Lite mode';
    if (day.isMiss) return '${day.dateStr} · Missed';
    if (day.isToday) return 'Today';
    return day.dateStr;
  }

  // Determines which week-column indices start a new month, for label placement.
  List<({int weekIndex, String label})> _monthMarkers() {
    final markers = <({int weekIndex, String label})>[];
    String? lastLabel;
    for (int wi = 0; wi < widget.weeks.length; wi++) {
      final week = widget.weeks[wi];
      // Use the first non-future day in the week to read its month.
      final first = week.firstWhere(
        (d) => !d.isFuture && d.dateStr.length == 10,
        orElse: () => week.first,
      );
      final month = int.tryParse(first.dateStr.substring(5, 7));
      if (month == null) continue;
      final label = _kMonthLabels[month - 1];
      final dayOfMonth = int.tryParse(first.dateStr.substring(8, 10)) ?? 99;
      if (dayOfMonth <= 7 && label != lastLabel) {
        markers.add((weekIndex: wi, label: label));
        lastLabel = label;
      }
    }
    return markers;
  }

  Future<void> _share() async {
    final lines = [
      '🧠 NeuroSync Recovery Story',
      if (widget.archetype != null) 'Archetype: ${widget.archetype}',
      'Adaptability Score: ${widget.resilienceScore} / 1000',
      'Comeback Streak: ${widget.comebackStreak} days',
      '',
      "The flex isn't a perfect streak. It's recovery.",
      'neurosync.app',
    ];
    await Share.share(lines.join('\n'), subject: 'My NeuroSync Recovery Story');
  }

  @override
  Widget build(BuildContext context) {
    final markers = _monthMarkers();
    final totalWidth = widget.weeks.length * _kColWidth;

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

          // ── Section header ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                'Recovery Story',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Last 12 months',
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Heatmap (scrollable horizontally) ────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Month labels row
                  SizedBox(
                    height: 14,
                    child: Stack(
                      children: markers.map((m) {
                        return Positioned(
                          left: m.weekIndex * _kColWidth,
                          child: Text(
                            m.label,
                            style: TextStyle(
                              fontSize: 9,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Day rows (Sun=0 … Sat=6), one row per weekday
                  ...List.generate(7, (dayIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: _kCellGap),
                      child: Row(
                        children: widget.weeks.map((week) {
                          final day = week[dayIndex];
                          final color = _cellColor(day);
                          return GestureDetector(
                            onTap: () {
                              final tip = _cellTooltip(day);
                              if (tip.isEmpty) return;
                              setState(() => _tooltip = tip);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _tooltip = null);
                              });
                            },
                            child: Container(
                              width: _kCellSize,
                              height: _kCellSize,
                              margin: const EdgeInsets.only(right: _kCellGap),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                                border: day.isToday
                                    ? Border.all(color: const Color(0xFF6366F1), width: 1)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Tooltip ───────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _tooltip != null
                ? Padding(
                    key: ValueKey(_tooltip),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _tooltip!,
                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),

          // ── Legend ────────────────────────────────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: const [
              _LegendDot(color: Color(0xFF10B981), label: 'Done'),
              _LegendDot(color: Color(0xFFF59E0B), label: 'Comeback'),
              _LegendDot(color: Color(0xFF38BDF8), label: 'Lite Mode'),
              _LegendDot(color: Color(0xFF7F1D1D), label: 'Missed'),
            ],
          ),

          const SizedBox(height: 12),

          // ── Share button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Share your recovery story'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textSecondary,
                side: BorderSide(color: context.borderColor),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Small colored dot + label for the legend row.
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
      ],
    );
  }
}
