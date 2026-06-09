import type { NeuroBrainProfile } from '../store/useNeuroStore';
import type { NeuroStack } from '../store/useNeuroStore';
import type { ReframeMessage } from './comebackHelpers';

// ── Archetype matrix (failureStyle × coreDriver) ─────────────────────────────

const ARCHETYPES: Record<string, Record<string, string>> = {
  perfectionist: {
    'feel-better':      'The Burnt-Out Achiever',
    'perform-better':   'The Driven Perfectionist',
    'become-someone':   'The Identity Builder',
    'survive':          'The Pressure Coper',
  },
  avoider: {
    'feel-better':      'The Comfort Seeker',
    'perform-better':   'The Hidden High-Performer',
    'become-someone':   'The Reluctant Transformer',
    'survive':          'The Overwhelmed Avoider',
  },
  analyst: {
    'feel-better':      'The Thoughtful Optimizer',
    'perform-better':   'The Strategic Performer',
    'become-someone':   'The Deliberate Builder',
    'survive':          'The Rational Survivor',
  },
  drifter: {
    'feel-better':      'The Gentle Restarter',
    'perform-better':   'The Latent Performer',
    'become-someone':   'The Wandering Visionary',
    'survive':          'The Day-to-Day Drifter',
  },
};

export function getArchetypeName(profile: NeuroBrainProfile): string {
  return ARCHETYPES[profile.failureStyle]?.[profile.coreDriver] ?? 'The Recovering Human';
}

// ── Profile insights — 4 sentences shown on the reveal screen ────────────────

export function getProfileInsights(profile: NeuroBrainProfile): string[] {
  const insights: string[] = [];

  // Failure style insight
  const failureInsights: Record<string, string> = {
    perfectionist: 'Comeback messages will match your standards — no toxic positivity, just honest resets.',
    avoider:       'The app will lower activation energy. Your reset plan starts with the smallest possible step.',
    analyst:       'Recovery framing will be data-driven. A miss is a signal, not a verdict.',
    drifter:       'No shame-based prompts. You\'ll be met with low-friction re-entry, not guilt.',
  };
  insights.push(failureInsights[profile.failureStyle]);

  // Peak energy window insight
  const energyInsights: Record<string, string> = {
    morning:   'Micro-actions are timed for your morning peak — when your willpower budget is largest.',
    afternoon: 'Re-entry actions are designed for afternoon recovery — short, decisive, and momentum-building.',
    evening:   'Evening recovery plans keep it minimal. One step tonight, full reset tomorrow morning.',
    variable:  'Actions adapt to whatever energy you report — low, medium, or high — at the moment.',
  };
  insights.push(energyInsights[profile.peakEnergyWindow]);

  // Accountability insight
  const accountabilityInsights: Record<string, string> = {
    tracking:  'Your recovery rate will be the number that matters — visible and tracked every session.',
    external:  'Comeback streaks are surfaced prominently — mild social pressure, without judgment.',
    systems:   'The protocol gives you a repeatable system for every miss. No improvising required.',
    none:      'No pressure mechanics. Just a frictionless path back to the habit, every time.',
  };
  insights.push(accountabilityInsights[profile.accountabilityStyle]);

  // Core driver insight
  const driverInsights: Record<string, string> = {
    'feel-better':    'Recovery messages focus on relief and restoration — the emotional payoff of getting back.',
    'perform-better': 'Your habit context will emphasise output and capability — performance is the frame.',
    'become-someone': 'Identity language is used in every reset. You\'re not doing habits — you\'re becoming.',
    'survive':        'The system respects hard days. Minimum viable actions are never dismissed as "not enough".',
  };
  insights.push(driverInsights[profile.coreDriver]);

  return insights;
}

// ── Personalised comeback messages ───────────────────────────────────────────

const BRAIN_AWARE_MESSAGES: Record<string, ReframeMessage[]> = {
  perfectionist: [
    {
      headline: 'Your standard didn\'t drop. The day did.',
      body: 'One missed session doesn\'t revise your baseline. Your capability is exactly where you left it — this is a scheduling correction, not a performance failure.',
    },
    {
      headline: 'The gap between yesterday and today is one action.',
      body: 'Not a new system, not a restart. The same path, resumed. High performers miss days — what separates them is the speed of the return.',
    },
  ],
  avoider: [
    {
      headline: 'The hardest step was opening this. You already did it.',
      body: 'Avoidance is a signal, not a character trait. You\'re here now. That is the whole comeback — the plan below is just the formality.',
    },
    {
      headline: 'You didn\'t need to feel ready. You just needed to start.',
      body: 'Motivation follows action, not the other way around. One small step now will generate the feeling you\'ve been waiting for.',
    },
  ],
  analyst: [
    {
      headline: 'One missed day is a data point, not a pattern.',
      body: 'Patterns require repetition. You have one data point. Resume the experiment — your trendline is still intact from everything before this.',
    },
    {
      headline: 'This is a system correction, not a failure.',
      body: 'Any well-designed system accounts for variance. You\'re inside expected deviation. Adjust and continue.',
    },
  ],
  drifter: [
    {
      headline: 'No momentum lost. Momentum is a return, not a streak.',
      body: 'The habit didn\'t end — it paused. Momentum is rebuilt in one session, not over weeks. You\'re one action away from being back.',
    },
    {
      headline: 'This is a continuation. Not a restart.',
      body: 'The path you\'ve been on is still there. You stepped off for a moment. Step back on — the distance doesn\'t matter.',
    },
  ],
};

export function getBrainAwareReframe(
  profile: NeuroBrainProfile,
  daysMissed: number
): ReframeMessage {
  const messages = BRAIN_AWARE_MESSAGES[profile.failureStyle] ?? BRAIN_AWARE_MESSAGES.analyst;
  return messages[Math.min(daysMissed - 1, messages.length - 1)] ?? messages[0];
}

// ── Energy-aware micro-actions ────────────────────────────────────────────────

const BRAIN_AWARE_ACTIONS: Record<string, Record<string, string[]>> = {
  morning: {
    energy:      ['Drink a glass of water and sit at your workspace.', 'Open the task and read the first line only.', 'Set a 5-minute timer. Start when it runs.'],
    overwhelm:   ['Write one sentence: what is the single most important thing today?', 'Close every tab except the one you need.', 'Begin the task for exactly 2 minutes — nothing more required.'],
    distraction: ['Put your phone in another room before you open your laptop.', 'Set a 25-minute block with one tab open.', 'Read your habit cue out loud, then start.'],
    life:        ['Acknowledge what happened. It was real. Now: one small step.', 'Lower the bar — 10 minutes counts today.', 'Open the thing and just look at it for 60 seconds.'],
  },
  afternoon: {
    energy:      ['Step outside for 3 minutes — then come back and begin.', 'Drink water. Sit down. Open the task.', 'Do one small piece. Momentum builds from there.'],
    overwhelm:   ['Pick the smallest sub-task and do only that.', 'Write down everything you\'re holding in your head, then close the list.', 'Work for 10 minutes with everything else closed.'],
    distraction: ['Environment reset: close tabs, silence notifications, sit down.', 'Start the clock — distraction can\'t compete with a timer that\'s already running.', 'Do the action for 5 minutes. You can stop after.'],
    life:        ['Today\'s bar is lower. That\'s allowed.', 'Do the minimum viable version of this habit.', 'One step. That\'s the whole plan.'],
  },
  evening: {
    energy:      ['Tonight: one sentence of intention. Tomorrow: full reset.', 'Drink water. Rest. Plan the first step for tomorrow morning.', 'Note what you\'ll do first tomorrow. That\'s enough for tonight.'],
    overwhelm:   ['Write tomorrow\'s single priority on a piece of paper and close the laptop.', 'List three things that are actually done today — even small ones.', 'No action needed tonight. Just acknowledge and plan for morning.'],
    distraction: ['Log this comeback now. That counts as showing up.', 'Plan one concrete action for tomorrow before midnight.', 'Write: "Tomorrow I will [action] when I [cue]."'],
    life:        ['Tonight is for rest. The habit resumes tomorrow — schedule it now.', 'You showed up to log this. That is non-trivial.', 'Put a reminder for tomorrow morning. Then fully rest tonight.'],
  },
  variable: {
    energy:      ['Match the action to your current energy — pick the easiest version.', 'Low energy: just open it. Medium: do 5 minutes. High: full session.', 'Ask yourself: what\'s the smallest thing I could do right now?'],
    overwhelm:   ['Reduce scope until it feels doable. Then do that.', 'One thing. Not the whole habit — one piece of it.', 'What took less than 2 minutes? Start there.'],
    distraction: ['One device, one tab, one task.', 'Timed sprint: 10 minutes, no exceptions, no context switching.', 'Remove the distraction before you begin — not during.'],
    life:        ['Today is a reduced-capacity day. That\'s a valid day.', 'Minimum viable action only. The full habit returns tomorrow.', 'Give yourself the smallest possible win — it still counts.'],
  },
};

export function getBrainAwareMicroActions(
  _stack: NeuroStack,
  profile: NeuroBrainProfile
): string[] {
  const window = profile.peakEnergyWindow;
  const blocker = profile.primaryBlocker;
  return BRAIN_AWARE_ACTIONS[window]?.[blocker] ?? [
    'Open the task and sit with it for 2 minutes.',
    'Drink water.',
    'Write one line of what you will do next.',
  ];
}

// ── Self-talk pattern label (for display) ─────────────────────────────────────

export function getSelfTalkLabel(pattern: NeuroBrainProfile['selfTalkPattern']): string {
  return {
    'self-critical': 'Self-Critical',
    avoidant:        'Avoidant',
    rational:        'Analytical',
    hopeless:        'Defeated',
  }[pattern] ?? pattern;
}

export function getFailureStyleLabel(style: NeuroBrainProfile['failureStyle']): string {
  return {
    perfectionist: 'Perfectionist',
    avoider:       'Avoider',
    analyst:       'Analyst',
    drifter:       'Drifter',
  }[style] ?? style;
}

export function getPeakWindowLabel(window: NeuroBrainProfile['peakEnergyWindow']): string {
  return {
    morning:   'Morning',
    afternoon: 'Afternoon',
    evening:   'Evening',
    variable:  'Variable',
  }[window] ?? window;
}
