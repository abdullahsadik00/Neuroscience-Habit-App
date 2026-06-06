// =============================================================================
// milestone_celebration.dart
//
// A rich bottom-anchored toast shown when a habit crosses a myelination
// milestone (10 / 25 / 50 / 75 / 100 %).
//
// BEHAVIOUR:
//   - Animates up from off-screen; auto-dismisses after 4 seconds.
//   - Tap anywhere on the card to dismiss immediately.
//   - Displays neuroscience copy tailored to the specific milestone %.
//   - An animated progress bar sweeps to the milestone value on mount.
//   - A pulsing indigo glow overlay mimics the React "glow pulse" effect.
//
// USAGE (via showMilestoneCelebration helper at the bottom of this file):
//   showMilestoneCelebration(context, habitTitle: 'Morning Run', milestone: 50);
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Neuroscience copy keyed by milestone percent.
const Map<int, ({String headline, String science})> _milestoneCopy = {
  10: (
    headline: 'Your pathway is forming.',
    science:
        'Early repetitions lay down the initial neural traces in the basal ganglia. Each completion makes the next one slightly easier.',
  ),
  25: (
    headline: 'Momentum is building.',
    science:
        'At this stage, the behavior starts competing with older, more established patterns. Keep going — it gets easier from here.',
  ),
  50: (
    headline: 'Halfway myelinated.',
    science:
        'Your brain has wrapped this pathway in enough myelin that the signal is noticeably faster. The habit is becoming part of your identity.',
  ),
  75: (
    headline: 'Strengthening fast.',
    science:
        'Research by Lally et al. shows most habits reach near-automaticity between 66–100 repetitions. You\'re in the final stretch.',
  ),
  100: (
    headline: 'Pathway well-established.',
    science:
        'This behavior no longer requires deliberate effort — it\'s wired in. Your brain now expends minimal glucose to execute it.',
  ),
};

const Map<int, String> _milestoneStageNames = {
  10: 'Pathway forming',
  25: 'Building momentum',
  50: 'Halfway myelinated',
  75: 'Strengthening fast',
  100: 'Well-established',
};

/// Shows the milestone celebration overlay. Call this from the dashboard when
/// [milestoneEventProvider] fires a non-null value. Internally uses
/// [showGeneralDialog] so it renders above the Scaffold.
void showMilestoneCelebration(
  BuildContext context, {
  required String habitTitle,
  required int milestone,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) => _MilestoneCelebrationOverlay(
      habitTitle: habitTitle,
      milestone: milestone,
    ),
  );
}

class _MilestoneCelebrationOverlay extends StatefulWidget {
  const _MilestoneCelebrationOverlay({
    required this.habitTitle,
    required this.milestone,
  });

  final String habitTitle;
  final int milestone;

  @override
  State<_MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<_MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barController;
  late final Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();

    // Animate the progress bar from (milestone - 15) to milestone over 1 second.
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    final startFraction =
        (widget.milestone - 15).clamp(0, 100) / 100.0;
    final endFraction = widget.milestone / 100.0;
    _barAnimation = Tween<double>(
      begin: startFraction,
      end: endFraction,
    ).animate(CurvedAnimation(
      parent: _barController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Start the bar animation after a short delay (matches React's 200ms delay).
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _barController.forward();
    });

    // Auto-dismiss after 4 seconds.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _milestoneCopy[widget.milestone];
    final stageName = _milestoneStageNames[widget.milestone] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              onTap: _dismiss,
              child: _CelebrationCard(
                habitTitle: widget.habitTitle,
                milestone: widget.milestone,
                stageName: stageName,
                copy: copy,
                barAnimation: _barAnimation,
                barController: _barController,
                isDark: isDark,
                surface: surface,
                onSurface: onSurface,
              )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .moveY(
                    begin: 40,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.habitTitle,
    required this.milestone,
    required this.stageName,
    required this.copy,
    required this.barAnimation,
    required this.barController,
    required this.isDark,
    required this.surface,
    required this.onSurface,
  });

  final String habitTitle;
  final int milestone;
  final String stageName;
  final ({String headline, String science})? copy;
  final Animation<double> barAnimation;
  final AnimationController barController;
  final bool isDark;
  final Color surface;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Pulsing indigo glow overlay ──────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.07),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .custom(
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                    builder: (context, value, child) => Opacity(
                      opacity: 0.4 + 0.4 * value,
                      child: child,
                    ),
                  ),
            ),
          ),

          // ── Card content ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: ⚡ "Myelination milestone" + percentage
                Row(
                  children: [
                    // Pulsing ⚡ emoji
                    const Text('⚡', style: TextStyle(fontSize: 20))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(width: 8),
                    Text(
                      'Myelination milestone',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${milestone}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Headline
                if (copy != null)
                  Text(
                    copy!.headline,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 4),

                // Habit title in italic
                Text(
                  habitTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 10),

                // Science copy
                if (copy != null)
                  Text(
                    copy!.science,
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withOpacity(0.6),
                      height: 1.55,
                    ),
                  ),
                const SizedBox(height: 16),

                // Animated progress bar
                AnimatedBuilder(
                  animation: barAnimation,
                  builder: (_, __) {
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: barAnimation.value,
                            minHeight: 3,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.07),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stageName,
                              style: TextStyle(
                                fontSize: 9,
                                color: onSurface.withOpacity(0.4),
                              ),
                            ),
                            Text(
                              'tap to dismiss',
                              style: TextStyle(
                                fontSize: 9,
                                color: onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
