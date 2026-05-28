import '../models/models.dart';
import '../data/habit_library.dart';

int _scoreHabit(HabitTemplate habit, NeuroBrainProfile profile, Neurochemistry? chem) {
  int score = 0;

  if (habit.peakEnergyWindows.contains(profile.peakEnergyWindow)) score += 3;
  if (profile.peakEnergyWindow == PeakEnergyWindow.variable) score += 1;
  if (habit.primaryBlockers.contains(profile.primaryBlocker)) score += 2;
  if (habit.coreDrivers.contains(profile.coreDriver)) score += 2;
  if (habit.failureStyles.contains(profile.failureStyle)) score += 1;

  if (profile.primaryBlocker == PrimaryBlocker.energy && habit.energyRequired == 'low') score += 1;
  if (profile.primaryBlocker == PrimaryBlocker.overwhelm && habit.duration == '2min') score += 1;

  if (chem != null) {
    if (chem.dopamine < 40 && habit.neurochemTarget.contains('dopamine')) score += 2;
    if (chem.acetylcholine < 40 && habit.neurochemTarget.contains('acetylcholine')) score += 2;
    if (chem.gaba < 40 && habit.neurochemTarget.contains('gaba')) score += 2;
    if (chem.epinephrine > 65 && habit.neurochemTarget.contains('gaba')) score += 2;
  }

  return score;
}

List<HabitTemplate> buildBlueprint(NeuroBrainProfile profile, [Neurochemistry? chem]) {
  final scored = habitLibrary
      .where((h) => h.liteVersionId == null)
      .map((h) => (habit: h, score: _scoreHabit(h, profile, chem)))
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final selected = <HabitTemplate>[];
  final usedCategories = <HabitCategory>{};

  for (final cat in HabitCategory.values) {
    final best = scored.firstWhere(
      (s) => s.habit.category == cat && !selected.any((sel) => sel.id == s.habit.id),
      orElse: () => (habit: scored.first.habit, score: -1),
    );
    if (best.score >= 0 && !selected.any((s) => s.id == best.habit.id)) {
      selected.add(best.habit);
      usedCategories.add(cat);
      if (selected.length >= 3) break;
    }
  }

  for (final item in scored) {
    if (selected.length >= 5) break;
    if (!selected.any((s) => s.id == item.habit.id)) {
      selected.add(item.habit);
    }
  }

  return selected.take(5).toList();
}
