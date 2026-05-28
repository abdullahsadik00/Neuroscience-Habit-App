String getLocalDateString(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int calculateStreak(List<String> dates) {
  if (dates.isEmpty) return 0;

  final unique = dates.toSet().toList()..sort((a, b) => b.compareTo(a));

  final todayStr = getLocalDateString(DateTime.now());
  final yesterdayStr = getLocalDateString(DateTime.now().subtract(const Duration(days: 1)));

  final latest = unique.first;
  if (latest != todayStr && latest != yesterdayStr) return 0;

  int streak = 0;
  DateTime current = DateTime.parse(latest);

  for (int i = 0; i < unique.length; i++) {
    final checkStr = getLocalDateString(current);
    if (unique.contains(checkStr)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
}

double calculateMyelination(int completionsCount, int streak) {
  if (completionsCount == 0) return 0;
  final base = (completionsCount * 1.5).clamp(0, 85).toDouble();
  final streakBonus = (streak * 1.5).clamp(0, 15).toDouble();
  return (base + streakBonus).clamp(0, 100);
}

double decayNeurochemical(double current, {double baseline = 50, double rate = 0.08}) {
  final difference = baseline - current;
  final updated = current + difference * rate;
  return (updated * 10).round() / 10;
}
