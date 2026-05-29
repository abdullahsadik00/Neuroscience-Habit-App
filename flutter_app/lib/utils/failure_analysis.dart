import '../models/models.dart';
import 'neuro_helpers.dart';

const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class FailureSignature {
  /// Habit with the highest miss rate over the last 30 days.
  final NeuroStack? weakestHabit;
  final double weakestHabitMissRate; // 0–1

  /// Day of week that accumulates the most misses across all habits.
  final String? worstDayOfWeek;
  final int worstDayMissCount;

  /// Habit that bounces back to completion fastest after a miss.
  final NeuroStack? fastestRecoveryHabit;
  final double fastestRecoveryDays; // avg days

  /// Overall average days from miss to next completion.
  final double avgRecoveryDays;

  /// True when there's ≥14 days of data to draw meaningful conclusions.
  final bool hasEnoughData;

  const FailureSignature({
    this.weakestHabit,
    this.weakestHabitMissRate = 0,
    this.worstDayOfWeek,
    this.worstDayMissCount = 0,
    this.fastestRecoveryHabit,
    this.fastestRecoveryDays = 0,
    this.avgRecoveryDays = 0,
    this.hasEnoughData = false,
  });
}

FailureSignature analyseFailureSignatures(
  List<NeuroStack> stacks,
  List<ComebackRecord> comebacks,
) {
  final active = stacks.where((s) => s.isActive).toList();
  if (active.isEmpty) return const FailureSignature();

  final today = DateTime.now();
  final todayStr = getLocalDateString(today);

  // Need at least one habit with ≥14 days of history
  final matured = active.where((s) {
    final created = DateTime.tryParse(s.createdAt);
    if (created == null) return false;
    return today.difference(created).inDays >= 14;
  }).toList();

  if (matured.isEmpty) return const FailureSignature();

  // ── Weakest habit (highest miss rate over last 30 days) ──────────────────
  NeuroStack? weakestHabit;
  double worstMissRate = -1;

  for (final stack in matured) {
    final created = DateTime.parse(stack.createdAt);
    final windowDays = today.difference(created).inDays.clamp(1, 30);
    int misses = 0;
    for (int i = 1; i <= windowDays; i++) {
      final d = getLocalDateString(today.subtract(Duration(days: i)));
      if (!stack.completions.contains(d)) misses++;
    }
    final rate = misses / windowDays;
    if (rate > worstMissRate) {
      worstMissRate = rate;
      weakestHabit = stack;
    }
  }

  // ── Worst day of week (most misses across all habits) ────────────────────
  final dayCounts = List<int>.filled(7, 0);
  for (final stack in matured) {
    final created = DateTime.parse(stack.createdAt);
    for (int i = 1; i <= 30; i++) {
      final d = today.subtract(Duration(days: i));
      final dStr = getLocalDateString(d);
      if (d.isBefore(created)) continue;
      if (!stack.completions.contains(dStr)) {
        dayCounts[d.weekday % 7]++;
      }
    }
  }
  int worstDay = 0;
  for (int i = 1; i < 7; i++) {
    if (dayCounts[i] > dayCounts[worstDay]) worstDay = i;
  }

  // ── Recovery speed per habit ─────────────────────────────────────────────
  NeuroStack? fastestHabit;
  double fastestAvg = double.infinity;
  final allRecoveries = <int>[];

  for (final stack in matured) {
    final stackComebacks = comebacks.where((c) => c.stackId == stack.id).toList();
    if (stackComebacks.isEmpty) continue;
    final completions = stack.completions.toSet();
    final recoveries = <int>[];
    for (final cb in stackComebacks) {
      final cbDate = DateTime.parse(cb.date);
      for (int d = 1; d <= 7; d++) {
        final next = getLocalDateString(cbDate.add(Duration(days: d)));
        if (completions.contains(next)) {
          recoveries.add(d);
          allRecoveries.add(d);
          break;
        }
      }
    }
    if (recoveries.isNotEmpty) {
      final avg = recoveries.reduce((a, b) => a + b) / recoveries.length;
      if (avg < fastestAvg) {
        fastestAvg = avg;
        fastestHabit = stack;
      }
    }
  }

  final avgRecovery = allRecoveries.isEmpty
      ? 0.0
      : allRecoveries.reduce((a, b) => a + b) / allRecoveries.length;

  return FailureSignature(
    weakestHabit: weakestHabit,
    weakestHabitMissRate: worstMissRate.clamp(0, 1),
    worstDayOfWeek: _dayNames[worstDay],
    worstDayMissCount: dayCounts[worstDay],
    fastestRecoveryHabit: fastestHabit,
    fastestRecoveryDays: fastestAvg == double.infinity ? 0 : fastestAvg,
    avgRecoveryDays: avgRecovery,
    hasEnoughData: true,
  );
}
