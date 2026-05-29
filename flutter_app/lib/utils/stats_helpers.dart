import '../models/models.dart';
import 'neuro_helpers.dart';

class WeekDay {
  final String dateStr;
  final String label;
  final bool completed;
  final bool comeback;
  final bool missed;
  final bool isToday;
  final bool isFuture;

  const WeekDay({
    required this.dateStr,
    required this.label,
    required this.completed,
    required this.comeback,
    required this.missed,
    required this.isToday,
    required this.isFuture,
  });
}

List<WeekDay> getWeekGrid(NeuroStack stack, List<ComebackRecord> comebacks) {
  const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final createdDate = stack.createdAt.substring(0, 10);
  final today = getLocalDateString(DateTime.now());
  final days = <WeekDay>[];

  for (int i = 6; i >= 0; i--) {
    final d = DateTime.now().subtract(Duration(days: i));
    final dateStr = getLocalDateString(d);
    final label = dayLabels[d.weekday % 7];
    final completed = stack.completions.contains(dateStr);
    final comeback = comebacks.any((c) => c.stackId == stack.id && c.date == dateStr);
    final isFuture = dateStr.compareTo(today) > 0;
    final isBeforeCreation = dateStr.compareTo(createdDate) < 0;
    final missed = !completed && !comeback && !isFuture && !isBeforeCreation;
    final isToday = dateStr == today;

    days.add(WeekDay(
      dateStr: dateStr,
      label: label,
      completed: completed,
      comeback: comeback,
      missed: missed,
      isToday: isToday,
      isFuture: isFuture,
    ));
  }

  return days;
}

double calcRecoveryRate(List<ComebackRecord> comebacks) {
  if (comebacks.isEmpty) return 0;
  final completed = comebacks.where((c) => c.microActionsCompleted).length;
  return (completed / comebacks.length * 100).roundToDouble();
}

int calcBrainScore(
  List<NeuroStack> stacks,
  List<ComebackRecord> comebacks,
  Neurochemistry neurochemistry,
) {
  final active = stacks.where((s) => s.isActive).toList();
  if (active.isEmpty) return 0;

  final avgMyelination = active.map((s) => s.myelinationLevel).reduce((a, b) => a + b) / active.length;
  final recoveryRate = calcRecoveryRate(comebacks);
  final chemAvg = (neurochemistry.dopamine +
          neurochemistry.acetylcholine +
          neurochemistry.gaba +
          (100 - neurochemistry.epinephrine)) /
      4;

  final score = (avgMyelination * 0.4 + recoveryRate * 0.3 + chemAvg * 0.3).round();
  return score.clamp(0, 100);
}

int getBestStreak(List<NeuroStack> stacks) {
  if (stacks.isEmpty) return 0;
  return stacks.map((s) => s.streak).reduce((a, b) => a > b ? a : b);
}

int getDaysInSystem(List<NeuroStack> stacks) {
  if (stacks.isEmpty) return 0;
  final earliest = stacks.map((s) => s.createdAt).reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  final diffMs = DateTime.now().difference(DateTime.parse(earliest));
  return diffMs.inDays.clamp(1, 99999);
}

int getComebacksThisMonth(List<ComebackRecord> comebacks) {
  final now = DateTime.now();
  final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  return comebacks.where((c) => c.date.startsWith(monthStr)).length;
}

/// Consecutive days the Comeback Protocol fired — our core differentiator metric.
int getComebackStreak(List<ComebackRecord> comebacks) {
  if (comebacks.isEmpty) return 0;
  // Deduplicate to one entry per day, sorted descending
  final dates = comebacks.map((c) => c.date).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  int streak = 1;
  for (int i = 1; i < dates.length; i++) {
    final prev = DateTime.parse(dates[i - 1]);
    final curr = DateTime.parse(dates[i]);
    if (prev.difference(curr).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

/// Average days from a miss to the next completion — "recovery speed".
/// Lower is better. Returns 0 when no data exists.
double getAvgRecoveryDays(List<NeuroStack> stacks, List<ComebackRecord> comebacks) {
  final recoveries = <int>[];
  for (final stack in stacks.where((s) => s.isActive)) {
    final completions = stack.completions.toSet();
    final stackComebacks = comebacks.where((c) => c.stackId == stack.id).toList();
    for (final cb in stackComebacks) {
      final cbDate = DateTime.parse(cb.date);
      for (int d = 1; d <= 7; d++) {
        final next = getLocalDateString(cbDate.add(Duration(days: d)));
        if (completions.contains(next)) {
          recoveries.add(d);
          break;
        }
      }
    }
  }
  if (recoveries.isEmpty) return 0;
  return recoveries.reduce((a, b) => a + b) / recoveries.length;
}


List<String> getRecoveryInsights(
  List<NeuroStack> stacks,
  List<ComebackRecord> comebacks,
  List<NeuroSwap> swaps,
) {
  final insights = <String>[];

  final strongest = [...stacks.where((s) => s.isActive)]
    ..sort((a, b) => b.streak.compareTo(a.streak));
  if (strongest.isNotEmpty && strongest.first.streak > 0) {
    final s = strongest.first;
    insights.add('"${s.title}" is your most consistent habit — ${s.streak}-day streak.');
  }

  if (comebacks.length >= 2) {
    final withActions = comebacks.where((c) => c.microActionsCompleted).length;
    final pct = (withActions / comebacks.length * 100).round();
    if (pct >= 70) {
      insights.add('You complete re-entry actions $pct% of the time. That\'s strong recovery discipline.');
    } else if (pct > 0) {
      insights.add('You\'ve acknowledged ${comebacks.length} comeback${comebacks.length > 1 ? 's' : ''}. Completing micro-actions increases long-term retention.');
    }
  }

  final totalSlips = swaps.fold<int>(0, (n, s) => n + s.slips.length);
  final totalUrges = swaps.fold<int>(0, (n, s) => n + s.urgeSurfingCompletions.length);
  if (totalUrges > 0 && totalSlips < totalUrges) {
    insights.add('You\'ve resisted $totalUrges urge${totalUrges > 1 ? 's' : ''} vs $totalSlips slip${totalSlips != 1 ? 's' : ''}. Your friction system is working.');
  }

  final active = stacks.where((s) => s.isActive).length;
  if (active == 0) {
    insights.add('Add your first habit to start building your recovery playbook.');
  } else if (active >= 4) {
    insights.add('$active active habits is on the high end — consider pausing the weakest one to protect your strongest streaks.');
  }

  return insights.take(3).toList();
}
