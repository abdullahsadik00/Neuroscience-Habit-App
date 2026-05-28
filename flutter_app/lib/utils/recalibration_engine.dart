import '../models/models.dart';
import '../data/habit_library.dart';
import 'neuro_helpers.dart';

List<String> _lastNDays(int n) {
  return List.generate(n, (i) {
    final d = DateTime.now().subtract(Duration(days: i + 1));
    return getLocalDateString(d);
  });
}

double _completionRateForPeriod(NeuroStack stack, List<String> days) {
  final eligible = days.where((d) => d.compareTo(stack.createdAt.substring(0, 10)) >= 0).toList();
  if (eligible.isEmpty) return 1.0;
  final done = eligible.where((d) => stack.completions.contains(d)).length;
  return done / eligible.length;
}

String? _findLiteVersion(NeuroStack stack) {
  final template = habitLibrary.firstWhere(
    (h) => h.title == stack.title,
    orElse: () => habitLibrary.first,
  );
  return template.liteVersionId;
}

String? _findReplacement(NeuroStack stack, List<String> excludeIds) {
  final candidates = habitLibrary.where(
    (h) => h.category == stack.category && h.title != stack.title && !excludeIds.contains(h.id),
  ).toList();
  return candidates.isNotEmpty ? candidates.first.id : null;
}

List<RecalibrationSuggestion> runRecalibration(
  List<NeuroStack> stacks,
  List<CheckinRecord> checkinHistory,
  NeuroBrainProfile? brainProfile,
) {
  final suggestions = <RecalibrationSuggestion>[];
  final active = stacks.where((s) => s.isActive).toList();
  final last14 = _lastNDays(14);
  final usedTemplateIds = active.map((s) {
    final t = habitLibrary.firstWhere((h) => h.title == s.title, orElse: () => habitLibrary.first);
    return t.id;
  }).toList();

  for (final stack in active) {
    final rate14 = _completionRateForPeriod(stack, last14);

    if (rate14 < 0.4) {
      final liteId = _findLiteVersion(stack);
      if (liteId != null) {
        final lite = habitLibrary.firstWhere((h) => h.id == liteId, orElse: () => habitLibrary.first);
        suggestions.add(RecalibrationSuggestion(
          id: 'scale-${stack.id}',
          type: SuggestionType.scaleDown,
          habitId: stack.id,
          habitTitle: stack.title,
          reason:
              'You completed "${stack.title}" only ${(rate14 * 100).round()}% of days over the last 2 weeks. A lighter version builds the same neural pathway with less friction.',
          fromValue: stack.title,
          toValue: lite.title,
          replacementTemplateId: liteId,
        ));
        continue;
      }
    }

    final daysOld = DateTime.now().difference(DateTime.parse(stack.createdAt)).inDays;
    if (rate14 == 0 && daysOld >= 14) {
      final replacementId = _findReplacement(stack, usedTemplateIds);
      if (replacementId != null) {
        final replacement = habitLibrary.firstWhere((h) => h.id == replacementId, orElse: () => habitLibrary.first);
        suggestions.add(RecalibrationSuggestion(
          id: 'replace-${stack.id}',
          type: SuggestionType.replace,
          habitId: stack.id,
          habitTitle: stack.title,
          reason:
              '"${stack.title}" hasn\'t been completed in 14 days. Swapping it for a fresh approach in the same category.',
          fromValue: stack.title,
          toValue: replacement.title,
          replacementTemplateId: replacementId,
        ));
      }
    }
  }

  if (brainProfile != null && checkinHistory.length >= 2) {
    final latest = checkinHistory.first;
    final previousBlocker = brainProfile.primaryBlocker.name;
    final currentBlocker = latest.weeklyBlocker;

    if (currentBlocker != previousBlocker &&
        checkinHistory.take(2).every((c) => c.weeklyBlocker == currentBlocker)) {
      const labels = {
        'energy': 'low energy',
        'overwhelm': 'overwhelm',
        'distraction': 'distraction',
        'life': 'life events',
      };
      suggestions.add(RecalibrationSuggestion(
        id: 'micro-${DateTime.now().millisecondsSinceEpoch}',
        type: SuggestionType.updateMicro,
        reason:
            'Your comeback micro-actions were built for "${labels[previousBlocker] ?? previousBlocker}", but your last 2 check-ins show "${labels[currentBlocker] ?? currentBlocker}" as your primary blocker.',
        fromValue: previousBlocker,
        toValue: currentBlocker,
      ));
    }
  }

  return suggestions;
}
