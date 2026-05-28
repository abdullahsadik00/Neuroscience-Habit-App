import '../models/models.dart';
import 'neuro_helpers.dart';

List<NeuroStack> getMissedStacks(
  List<NeuroStack> stacks,
  List<String> acknowledgedTodayIds,
) {
  final yesterday = getLocalDateString(DateTime.now().subtract(const Duration(days: 1)));
  final today = getLocalDateString(DateTime.now());

  return stacks.where((stack) {
    if (!stack.isActive || stack.completions.isEmpty) return false;
    if (acknowledgedTodayIds.contains(stack.id)) return false;
    final missedYesterday = !stack.completions.contains(yesterday);
    final notCompletedToday = !stack.completions.contains(today);
    return missedYesterday && notCompletedToday;
  }).toList();
}

int getDaysMissed(NeuroStack stack) {
  if (stack.completions.isEmpty) return 0;
  final sorted = [...stack.completions]..sort((a, b) => b.compareTo(a));
  final lastCompletion = DateTime.parse('${sorted.first}T00:00:00');
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final diff = todayMidnight.difference(lastCompletion);
  return diff.inDays.clamp(1, 999);
}

class ReframeMessage {
  final String headline;
  final String body;
  const ReframeMessage({required this.headline, required this.body});
}

const _reframeMessages = [
  ReframeMessage(
    headline: "You didn't break the habit. You paused it.",
    body: "Your neural pathway for this habit is still intact. One missed day doesn't erase the wiring you've built. The pathway needs activation, not rebuilding.",
  ),
  ReframeMessage(
    headline: "One missed day is data, not a verdict.",
    body: "High performers miss days. What separates them isn't a perfect streak — it's how fast they return. You're here now. That's the recovery already starting.",
  ),
  ReframeMessage(
    headline: "The gap between then and now is one action.",
    body: "Not a restart. Not a new system. One small action that tells your brain the pattern continues. That's all this moment requires.",
  ),
  ReframeMessage(
    headline: "You're not starting over. You're continuing.",
    body: "Streaks measure consecutive days. They don't measure the durability of your neural wiring. That wiring is still there. Today adds to it.",
  ),
];

ReframeMessage getComebackMessage(int daysMissed) {
  final idx = (daysMissed - 1).clamp(0, _reframeMessages.length - 1);
  return _reframeMessages[idx];
}

const _microActions = {
  'focus': [
    'Open your task list and read just the title of your most important task',
    'Sit at your work setup and set a 2-minute timer',
    'Write one sentence about what you are working on today',
  ],
  'wellness': [
    'Take 3 slow deep breaths right now — that is the entire action',
    'Stand up and stretch your arms above your head for 30 seconds',
    'Drink a glass of water before you do anything else',
  ],
  'mindset': [
    'Write one sentence: what is one thing that went okay yesterday?',
    'Say out loud: "I am building this one day at a time"',
    'Read back the anchor cue for this habit once',
  ],
  'fitness': [
    'Do 5 bodyweight squats right now — just 5',
    'Put on your workout clothes (that is the only task)',
    'Walk to the front door and back',
  ],
};

List<String> generateMicroActions(NeuroStack stack) {
  return _microActions[stack.category.name] ?? [
    'Do a 60-second version of: ${stack.action.substring(0, stack.action.length.clamp(0, 50))}…',
    'Set a 2-minute timer and just begin',
    'Write "continuing" in your notes app',
  ];
}
