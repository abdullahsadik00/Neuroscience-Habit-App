import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class StatsBar extends StatelessWidget {
  final int brainScore;
  final int comebackStreak;
  final int bestStreak;
  final double recoveryRate;

  const StatsBar({
    super.key,
    required this.brainScore,
    required this.comebackStreak,
    required this.bestStreak,
    required this.recoveryRate,
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
      child: Row(
        children: [
          _Stat(
            label: 'Brain Score',
            value: '$brainScore',
            icon: Icons.psychology,
            color: const Color(0xFF6366F1),
          ).animate().fadeIn(delay: 50.ms),
          _Divider(),
          _Stat(
            label: 'Comeback',
            value: '${comebackStreak}d',
            icon: Icons.replay_circle_filled,
            color: const Color(0xFFF59E0B),
          ).animate().fadeIn(delay: 100.ms),
          _Divider(),
          _Stat(
            label: 'Best Streak',
            value: '${bestStreak}d',
            icon: Icons.local_fire_department,
            color: const Color(0xFF10B981),
          ).animate().fadeIn(delay: 150.ms),
          _Divider(),
          _Stat(
            label: 'Recovery',
            value: '${recoveryRate.round()}%',
            icon: Icons.refresh,
            color: const Color(0xFF8B5CF6),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: context.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
