import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/neuro_provider.dart';
import '../utils/stats_helpers.dart';
import '../utils/failure_analysis.dart';
import '../theme/app_theme.dart';

class RecoveryPlaybook extends ConsumerWidget {
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final List<NeuroSwap> swaps;

  const RecoveryPlaybook({
    super.key,
    required this.stacks,
    required this.comebacks,
    required this.swaps,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(neuroProvider).isPro;
    final insights = getRecoveryInsights(stacks, comebacks, swaps);
    final sig = analyseFailureSignatures(stacks, comebacks);

    if (insights.isEmpty && (!sig.hasEnoughData || !isPro)) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'Recovery Playbook',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (sig.hasEnoughData && isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('v2 · Failure Signatures', style: TextStyle(fontSize: 10, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
                )
              else if (sig.hasEnoughData && !isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 10, color: Color(0xFFF59E0B)),
                      SizedBox(width: 3),
                      Text('Failure Signatures · Pro', style: TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),

          // ── Failure Signatures (v2 — Pro only) ──────────────────────────
          if (sig.hasEnoughData && isPro) ...[
            const SizedBox(height: 14),
            _SectionLabel(label: 'Your failure patterns'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (sig.weakestHabit != null)
                  Expanded(
                    child: _SignatureCard(
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xFFEF4444),
                      label: 'Slips most',
                      value: sig.weakestHabit!.title,
                      sub: '${(sig.weakestHabitMissRate * 100).round()}% miss rate',
                    ).animate().fadeIn(delay: 50.ms),
                  ),
                if (sig.weakestHabit != null && sig.worstDayOfWeek != null)
                  const SizedBox(width: 8),
                if (sig.worstDayOfWeek != null)
                  Expanded(
                    child: _SignatureCard(
                      icon: Icons.calendar_today_outlined,
                      color: const Color(0xFFF59E0B),
                      label: 'Hardest day',
                      value: sig.worstDayOfWeek!,
                      sub: '${sig.worstDayMissCount} misses (30d)',
                    ).animate().fadeIn(delay: 100.ms),
                  ),
              ],
            ),
            if (sig.avgRecoveryDays > 0 || sig.fastestRecoveryHabit != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (sig.avgRecoveryDays > 0)
                    Expanded(
                      child: _SignatureCard(
                        icon: Icons.replay_circle_filled,
                        color: const Color(0xFF10B981),
                        label: 'Avg recovery',
                        value: '${sig.avgRecoveryDays.toStringAsFixed(1)} days',
                        sub: 'miss → next completion',
                      ).animate().fadeIn(delay: 150.ms),
                    ),
                  if (sig.avgRecoveryDays > 0 && sig.fastestRecoveryHabit != null)
                    const SizedBox(width: 8),
                  if (sig.fastestRecoveryHabit != null)
                    Expanded(
                      child: _SignatureCard(
                        icon: Icons.bolt,
                        color: const Color(0xFF6366F1),
                        label: 'Fastest bounce',
                        value: sig.fastestRecoveryHabit!.title,
                        sub: '${sig.fastestRecoveryDays.toStringAsFixed(1)}d avg comeback',
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                ],
              ),
            ],
          ],

          // ── Text insights ────────────────────────────────────────────────
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel(label: 'Insights'),
            const SizedBox(height: 8),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(insight, style: TextStyle(fontSize: 13, color: context.textSecondary))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textSecondary, letterSpacing: 0.8),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  const _SignatureCard({required this.icon, required this.color, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: TextStyle(fontSize: 10, color: context.textSecondary)),
        ],
      ),
    );
  }
}
