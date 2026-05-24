import type { NeuroStack, NeuroSwap, ComebackRecord, Neurochemistry } from '../store/useNeuroStore';
import { getLocalDateString } from './neuroHelpers';

export interface WeekDay {
  dateStr: string;
  label: string; // "Mon", "Tue"…
  completed: boolean;
  comeback: boolean;
  missed: boolean; // before today, after creation, no completion
  isToday: boolean;
  isFuture: boolean;
}

export function getWeekGrid(stack: NeuroStack, comebacks: ComebackRecord[]): WeekDay[] {
  const days: WeekDay[] = [];
  const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const createdDate = stack.createdAt.slice(0, 10);
  const today = getLocalDateString(new Date());

  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = getLocalDateString(d);
    const label = dayLabels[d.getDay()];
    const completed = stack.completions.includes(dateStr);
    const comeback = comebacks.some((c) => c.stackId === stack.id && c.date === dateStr);
    const isFuture = dateStr > today;
    const isBeforeCreation = dateStr < createdDate;
    const missed = !completed && !comeback && !isFuture && !isBeforeCreation;
    const isToday = dateStr === today;
    days.push({ dateStr, label, completed, comeback, missed, isToday, isFuture });
  }
  return days;
}

export function calcRecoveryRate(comebacks: ComebackRecord[]): number {
  if (comebacks.length === 0) return 0;
  const completed = comebacks.filter((c) => c.microActionsCompleted).length;
  return Math.round((completed / comebacks.length) * 100);
}

export function calcBrainScore(
  stacks: NeuroStack[],
  comebacks: ComebackRecord[],
  neurochemistry: Neurochemistry
): number {
  const activeStacks = stacks.filter((s) => s.isActive);
  if (activeStacks.length === 0) return 0;

  const avgMyelination =
    activeStacks.reduce((sum, s) => sum + s.myelinationLevel, 0) / activeStacks.length;

  const recoveryRate = calcRecoveryRate(comebacks);

  const chemAvg =
    (neurochemistry.dopamine +
      neurochemistry.acetylcholine +
      neurochemistry.gaba +
      (100 - neurochemistry.epinephrine)) / // lower epinephrine is healthier
    4;

  const score = Math.round(avgMyelination * 0.4 + recoveryRate * 0.3 + chemAvg * 0.3);
  return Math.min(100, Math.max(0, score));
}

export function getBestStreak(stacks: NeuroStack[]): number {
  return stacks.reduce((best, s) => Math.max(best, s.streak), 0);
}

export function getDaysInSystem(stacks: NeuroStack[]): number {
  if (stacks.length === 0) return 0;
  const earliest = stacks.reduce((min, s) =>
    s.createdAt < min ? s.createdAt : min, stacks[0].createdAt
  );
  const diffMs = Date.now() - new Date(earliest).getTime();
  return Math.max(1, Math.floor(diffMs / 86400000));
}

export function getComebacksThisMonth(comebacks: ComebackRecord[]): number {
  const now = new Date();
  const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  return comebacks.filter((c) => c.date.startsWith(monthStr)).length;
}

export function getRecoveryInsights(
  stacks: NeuroStack[],
  comebacks: ComebackRecord[],
  swaps: NeuroSwap[]
): string[] {
  const insights: string[] = [];

  // Strongest habit
  const strongest = stacks.filter((s) => s.isActive).sort((a, b) => b.streak - a.streak)[0];
  if (strongest && strongest.streak > 0) {
    insights.push(`"${strongest.title}" is your most consistent habit — ${strongest.streak}-day streak.`);
  }

  // Recovery speed
  if (comebacks.length >= 2) {
    const withActions = comebacks.filter((c) => c.microActionsCompleted).length;
    const pct = Math.round((withActions / comebacks.length) * 100);
    if (pct >= 70) {
      insights.push(`You complete re-entry actions ${pct}% of the time. That's strong recovery discipline.`);
    } else if (pct > 0) {
      insights.push(`You've acknowledged ${comebacks.length} comeback${comebacks.length > 1 ? 's' : ''}. Completing micro-actions increases long-term retention.`);
    }
  }

  // Slip control
  const totalSlips = swaps.reduce((n, s) => n + s.slips.length, 0);
  const totalUrges = swaps.reduce((n, s) => n + s.urgeSurfingCompletions.length, 0);
  if (totalUrges > 0 && totalSlips < totalUrges) {
    insights.push(`You've resisted ${totalUrges} urge${totalUrges > 1 ? 's' : ''} vs ${totalSlips} slip${totalSlips !== 1 ? 's' : ''}. Your friction system is working.`);
  }

  // Habit count
  const active = stacks.filter((s) => s.isActive).length;
  if (active === 0) {
    insights.push('Add your first habit to start building your recovery playbook.');
  } else if (active >= 4) {
    insights.push(`${active} active habits is on the high end — consider pausing the weakest one to protect your strongest streaks.`);
  }

  return insights.slice(0, 3);
}
