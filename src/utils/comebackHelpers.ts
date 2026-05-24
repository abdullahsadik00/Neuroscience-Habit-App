import { NeuroStack } from '../store/useNeuroStore';
import { getLocalDateString } from './neuroHelpers';

export function getMissedStacks(
  stacks: NeuroStack[],
  acknowledgedTodayIds: string[]
): NeuroStack[] {
  const yesterday = getLocalDateString(new Date(Date.now() - 86400000));
  const today = getLocalDateString(new Date());

  return stacks.filter((stack) => {
    if (!stack.isActive || stack.completions.length === 0) return false;
    // Already acknowledged comeback for this stack today
    if (acknowledgedTodayIds.includes(stack.id)) return false;
    // Has prior completions but missed yesterday AND hasn't completed today
    const missedYesterday = !stack.completions.includes(yesterday);
    const notCompletedToday = !stack.completions.includes(today);
    return missedYesterday && notCompletedToday;
  });
}

export function getDaysMissed(stack: NeuroStack): number {
  if (stack.completions.length === 0) return 0;
  const sorted = [...stack.completions].sort((a, b) => b.localeCompare(a));
  const lastCompletion = new Date(sorted[0] + 'T00:00:00');
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const diffMs = today.getTime() - lastCompletion.getTime();
  return Math.max(1, Math.floor(diffMs / 86400000));
}

interface ReframeMessage {
  headline: string;
  body: string;
}

const REFRAME_MESSAGES: ReframeMessage[] = [
  {
    headline: "You didn't break the habit. You paused it.",
    body: "Your neural pathway for this habit is still intact. One missed day doesn't erase the wiring you've built. The pathway needs activation, not rebuilding.",
  },
  {
    headline: "One missed day is data, not a verdict.",
    body: "High performers miss days. What separates them isn't a perfect streak — it's how fast they return. You're here now. That's the recovery already starting.",
  },
  {
    headline: "The gap between then and now is one action.",
    body: "Not a restart. Not a new system. One small action that tells your brain the pattern continues. That's all this moment requires.",
  },
  {
    headline: "You're not starting over. You're continuing.",
    body: "Streaks measure consecutive days. They don't measure the durability of your neural wiring. That wiring is still there. Today adds to it.",
  },
];

export function getComebackMessage(daysMissed: number): ReframeMessage {
  const idx = Math.min(daysMissed - 1, REFRAME_MESSAGES.length - 1);
  return REFRAME_MESSAGES[Math.max(0, idx)];
}

const CATEGORY_MICRO_ACTIONS: Record<string, string[]> = {
  focus: [
    'Open your task list and read just the title of your most important task',
    'Sit at your work setup and set a 2-minute timer',
    'Write one sentence about what you are working on today',
  ],
  wellness: [
    'Take 3 slow deep breaths right now — that is the entire action',
    'Stand up and stretch your arms above your head for 30 seconds',
    'Drink a glass of water before you do anything else',
  ],
  mindset: [
    'Write one sentence: what is one thing that went okay yesterday?',
    'Say out loud: "I am building this one day at a time"',
    'Read back the anchor cue for this habit once',
  ],
  fitness: [
    'Do 5 bodyweight squats right now — just 5',
    'Put on your workout clothes (that is the only task)',
    'Walk to the front door and back',
  ],
};

export function generateMicroActions(stack: NeuroStack): string[] {
  return (
    CATEGORY_MICRO_ACTIONS[stack.category] ?? [
      `Do a 60-second version of: ${stack.action.slice(0, 50)}…`,
      'Set a 2-minute timer and just begin',
      'Write "continuing" in your notes app',
    ]
  );
}
