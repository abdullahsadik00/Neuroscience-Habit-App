import type { NeuroStack, NeuroSwap, ComebackRecord, Neurochemistry, NeuroLog } from '../store/useNeuroStore';
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

export function calcComebackStreak(comebacks: ComebackRecord[]): number {
  if (comebacks.length === 0) return 0;

  const uniqueDates = [...new Set(comebacks.map((c) => c.date))].sort((a, b) => b.localeCompare(a));
  const today = getLocalDateString(new Date());
  const yesterday = getLocalDateString(new Date(Date.now() - 86400000));

  if (uniqueDates[0] !== today && uniqueDates[0] !== yesterday) return 0;

  let streak = 0;
  const cursor = new Date(uniqueDates[0]);

  for (const date of uniqueDates) {
    if (date === getLocalDateString(cursor)) {
      streak++;
      cursor.setDate(cursor.getDate() - 1);
    } else {
      break;
    }
  }

  return streak;
}

export function getComebacksThisMonth(comebacks: ComebackRecord[]): number {
  const now = new Date();
  const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  return comebacks.filter((c) => c.date.startsWith(monthStr)).length;
}

export function calcResilienceScore(
  comebacks: ComebackRecord[],
  logs: NeuroLog[],
  stacks: NeuroStack[]
): number {
  // 60 pts: quality of comeback completions (did the user actually do the micro-actions?)
  const comebackBase = comebacks.length > 0
    ? (comebacks.filter(c => c.microActionsCompleted).length / comebacks.length) * 60
    : 0;

  // Up to 20 pts: urge surfing in last 30 days (4 pts each, capped at 5 surfs)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const recentSurfs = logs.filter(
    l => l.type === 'urge_surf' && new Date(l.timestamp) >= thirtyDaysAgo
  ).length;
  const urgeSurfBonus = Math.min(recentSurfs * 4, 20);

  // Up to 20 pts: average myelination across active habits (pathway strength proxy)
  const activeStacks = stacks.filter(s => s.isActive);
  const avgMyelination = activeStacks.length > 0
    ? activeStacks.reduce((sum, s) => sum + s.myelinationLevel, 0) / activeStacks.length
    : 0;
  const consistencyBonus = Math.round(avgMyelination * 0.2);

  return Math.min(Math.round(comebackBase + urgeSurfBonus + consistencyBonus), 100);
}

export interface HeatmapDay {
  dateStr: string;
  completions: number;
  hasComeback: boolean;
  isMiss: boolean;
  isToday: boolean;
  isFuture: boolean;
}

export function getYearGrid(stacks: NeuroStack[], comebacks: ComebackRecord[]): HeatmapDay[][] {
  const todayDate = new Date();
  todayDate.setHours(0, 0, 0, 0);
  const today = getLocalDateString(todayDate);
  const activeStacks = stacks.filter(s => s.isActive);

  // Start ~52 weeks ago, aligned to Sunday so columns are full weeks
  const startDate = new Date(todayDate);
  startDate.setDate(startDate.getDate() - 364);
  startDate.setDate(startDate.getDate() - startDate.getDay());

  const cursor = new Date(startDate);
  const weeks: HeatmapDay[][] = [];

  for (let w = 0; w < 53; w++) {
    const week: HeatmapDay[] = [];
    for (let d = 0; d < 7; d++) {
      const dateStr = getLocalDateString(cursor);
      const isFuture = cursor > todayDate;
      const isToday = dateStr === today;

      const completions = activeStacks.filter(
        s => s.createdAt.slice(0, 10) <= dateStr && s.completions.includes(dateStr)
      ).length;

      const hasComeback = comebacks.some(c => c.date === dateStr);

      const habitsExistedCount = activeStacks.filter(s => s.createdAt.slice(0, 10) <= dateStr).length;
      const isMiss = !isFuture && !isToday && habitsExistedCount > 0 && completions === 0 && !hasComeback;

      week.push({ dateStr, completions, hasComeback, isMiss, isToday, isFuture });
      cursor.setDate(cursor.getDate() + 1);
    }
    weeks.push(week);
  }
  return weeks;
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
