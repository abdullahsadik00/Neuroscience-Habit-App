import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/stats_helpers.dart';
import '../theme/app_theme.dart';

class RecoveryPlaybook extends StatelessWidget {
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final List<NeuroSwap> swaps;
  const RecoveryPlaybook({super.key, required this.stacks, required this.comebacks, required this.swaps});

  @override
  Widget build(BuildContext context) {
    final insights = getRecoveryInsights(stacks, comebacks, swaps);
    if (insights.isEmpty) return const SizedBox.shrink();

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
          Row(
            children: [
              const Icon(Icons.book_outlined, size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text('Recovery Playbook', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(insight, style: TextStyle(fontSize: 13, color: context.textSecondary))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
