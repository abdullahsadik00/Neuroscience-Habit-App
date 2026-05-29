import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class BrainProfileCard extends StatelessWidget {
  final NeuroBrainProfile profile;
  final VoidCallback onRetake;

  const BrainProfileCard({super.key, required this.profile, required this.onRetake});

  static String _archetypeName(NeuroBrainProfile p) {
    // 16 archetypes from failureStyle × coreDriver
    final fs = p.failureStyle.name;
    final cd = p.coreDriver.name;
    const names = {
      'perfectionist-feelBetter': 'The Exhausted Achiever',
      'perfectionist-performBetter': 'The Precision Driver',
      'perfectionist-becomeSomeone': 'The Identity Builder',
      'perfectionist-survive': 'The Cornered Perfectionist',
      'avoider-feelBetter': 'The Comfort Seeker',
      'avoider-performBetter': 'The Quiet Competitor',
      'avoider-becomeSomeone': 'The Reluctant Transformer',
      'avoider-survive': 'The Minimal Risk-Taker',
      'analyst-feelBetter': 'The Thoughtful Healer',
      'analyst-performBetter': 'The Systems Optimizer',
      'analyst-becomeSomeone': 'The Deliberate Builder',
      'analyst-survive': 'The Calculated Survivor',
      'drifter-feelBetter': 'The Restless Dreamer',
      'drifter-performBetter': 'The Inconsistent Sprinter',
      'drifter-becomeSomeone': 'The Aspiring Self',
      'drifter-survive': 'The Day-to-Day Navigator',
    };
    return names['$fs-$cd'] ?? 'The Recovery Builder';
  }

  static String _failureLabel(FailureStyle s) {
    return switch (s) {
      FailureStyle.perfectionist => 'Perfectionist',
      FailureStyle.avoider => 'Avoider',
      FailureStyle.analyst => 'Analyst',
      FailureStyle.drifter => 'Drifter',
    };
  }

  static String _energyLabel(PeakEnergyWindow w) {
    return switch (w) {
      PeakEnergyWindow.morning => 'Morning',
      PeakEnergyWindow.afternoon => 'Afternoon',
      PeakEnergyWindow.evening => 'Evening',
      PeakEnergyWindow.variable => 'Variable',
    };
  }

  static String _blockerLabel(PrimaryBlocker b) {
    return switch (b) {
      PrimaryBlocker.energy => 'Low Energy',
      PrimaryBlocker.overwhelm => 'Overwhelm',
      PrimaryBlocker.distraction => 'Distraction',
      PrimaryBlocker.life => 'Life Events',
    };
  }

  static String _recoveryLabel(RecoverySpeed s) {
    return switch (s) {
      RecoverySpeed.fast => 'Fast',
      RecoverySpeed.medium => 'Medium',
      RecoverySpeed.slow => 'Slow',
      RecoverySpeed.variable => 'Variable',
    };
  }

  static String _motivationLabel(MotivationSource m) {
    return switch (m) {
      MotivationSource.identity => 'Identity',
      MotivationSource.outcome => 'Outcome',
      MotivationSource.process => 'Process',
      MotivationSource.survival => 'Survival',
    };
  }

  static String _driverLabel(CoreDriver d) {
    return switch (d) {
      CoreDriver.feelBetter => 'Feel Better',
      CoreDriver.performBetter => 'Perform Better',
      CoreDriver.becomeSomeone => 'Become Someone',
      CoreDriver.survive => 'Survive',
    };
  }

  @override
  Widget build(BuildContext context) {
    final archetype = _archetypeName(profile);
    final failureLabel = _failureLabel(profile.failureStyle);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              Text('Your Brain Profile', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: onRetake,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Retake', style: TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Archetype name
          Text(
            archetype,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 6),

          // Failure style badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Failure style: $failureLabel',
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),

          // 6 dimension values
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Dimension(label: 'Peak Energy', value: _energyLabel(profile.peakEnergyWindow)),
              _Dimension(label: 'Recovery', value: _recoveryLabel(profile.recoverySpeed)),
              _Dimension(label: 'Blocker', value: _blockerLabel(profile.primaryBlocker)),
              _Dimension(label: 'Motivation', value: _motivationLabel(profile.motivationSource)),
              _Dimension(label: 'Core Driver', value: _driverLabel(profile.coreDriver)),
              _Dimension(label: 'Accountability', value: _accountabilityLabel(profile.accountabilityStyle)),
            ],
          ),
        ],
      ),
    );
  }

  static String _accountabilityLabel(AccountabilityStyle a) {
    return switch (a) {
      AccountabilityStyle.tracking => 'Self-Tracking',
      AccountabilityStyle.external => 'External',
      AccountabilityStyle.systems => 'Systems',
      AccountabilityStyle.none => 'None',
    };
  }
}

class _Dimension extends StatelessWidget {
  final String label;
  final String value;
  const _Dimension({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.borderColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: context.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
