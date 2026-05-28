import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/neuro_provider.dart';
import '../utils/comeback_helpers.dart';
import '../theme/app_theme.dart';

class ComebackProtocolBanner extends ConsumerWidget {
  final List<NeuroStack> missedStacks;
  const ComebackProtocolBanner({super.key, required this.missedStacks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (missedStacks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_back_ios, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 8),
              Text(
                'Comeback Protocol',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...missedStacks.map((stack) => _MissedStackItem(stack: stack)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.05);
  }
}

class _MissedStackItem extends ConsumerWidget {
  final NeuroStack stack;
  const _MissedStackItem({required this.stack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysMissed = getDaysMissed(stack);
    final message = getComebackMessage(daysMissed);
    final microActions = generateMicroActions(stack);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stack.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${daysMissed}d missed', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
          const SizedBox(height: 8),
          Text(message.headline, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(message.body, style: TextStyle(fontSize: 12, color: context.textSecondary)),
          const SizedBox(height: 12),
          Text('Re-entry actions:', style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...microActions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 5, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(child: Text(a, style: TextStyle(fontSize: 12, color: context.textSecondary))),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(neuroProvider.notifier).acknowledgeComeback(
                      stack.id, stack.title, microActionsCompleted: false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    foregroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Just acknowledge'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(neuroProvider.notifier).acknowledgeComeback(
                      stack.id, stack.title, microActionsCompleted: true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Done micro-actions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
