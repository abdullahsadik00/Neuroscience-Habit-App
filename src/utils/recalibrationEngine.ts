import type { NeuroStack, CheckinRecord, NeuroBrainProfile } from '../store/useNeuroStore';
import { HABIT_LIBRARY } from '../data/habitLibrary';
import { getLocalDateString } from './neuroHelpers';

export type SuggestionType = 'SCALE_DOWN' | 'REPLACE' | 'UPDATE_MICRO';

export interface RecalibrationSuggestion {
  id: string;
  type: SuggestionType;
  habitId?: string;
  habitTitle?: string;
  reason: string;
  fromValue: string;
  toValue: string;
  /** ID of the replacement template from habitLibrary (for SCALE_DOWN / REPLACE) */
  replacementTemplateId?: string;
}

export interface RecalibrationEvent {
  id: string;
  date: string;
  trigger: 'weekly-checkin';
  suggestions: RecalibrationSuggestion[];
  accepted: string[];
  rejected: string[];
}

/** Returns date strings for the last N days (not including today) */
function lastNDays(n: number): string[] {
  const days: string[] = [];
  for (let i = 1; i <= n; i++) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push(getLocalDateString(d));
  }
  return days;
}

function completionRateForPeriod(stack: NeuroStack, days: string[]): number {
  const eligible = days.filter(d => d >= stack.createdAt.slice(0, 10));
  if (eligible.length === 0) return 1; // too new — don't penalise
  const done = eligible.filter(d => stack.completions.includes(d)).length;
  return done / eligible.length;
}

function findLiteVersion(stack: NeuroStack): string | null {
  const template = HABIT_LIBRARY.find(h => h.title === stack.title);
  if (!template?.liteVersionId) return null;
  return template.liteVersionId;
}

function findReplacement(stack: NeuroStack, excludeIds: string[]): string | null {
  const candidates = HABIT_LIBRARY.filter(
    h =>
      h.category === stack.category &&
      h.title !== stack.title &&
      !excludeIds.includes(h.id)
  );
  return candidates.length > 0 ? candidates[0].id : null;
}

export function runRecalibration(
  stacks: NeuroStack[],
  checkinHistory: CheckinRecord[],
  brainProfile: NeuroBrainProfile | null
): RecalibrationSuggestion[] {
  const suggestions: RecalibrationSuggestion[] = [];
  const activeStacks = stacks.filter(s => s.isActive);
  const last14 = lastNDays(14);
  const last7 = lastNDays(7);
  const usedTemplateIds = activeStacks.map(s =>
    HABIT_LIBRARY.find(h => h.title === s.title)?.id ?? ''
  ).filter(Boolean);

  // ── SCALE_DOWN: <40% completion over last 14 days ──────────────────────────
  for (const stack of activeStacks) {
    const rate14 = completionRateForPeriod(stack, last14);
    if (rate14 < 0.4) {
      const liteId = findLiteVersion(stack);
      if (liteId) {
        const lite = HABIT_LIBRARY.find(h => h.id === liteId);
        if (lite) {
          suggestions.push({
            id: `scale-${stack.id}`,
            type: 'SCALE_DOWN',
            habitId: stack.id,
            habitTitle: stack.title,
            reason: `You completed "${stack.title}" only ${Math.round(rate14 * 100)}% of days over the last 2 weeks. A lighter version builds the same neural pathway with less friction.`,
            fromValue: stack.title,
            toValue: lite.title,
            replacementTemplateId: liteId,
          });
          continue; // don't also REPLACE the same habit
        }
      }
    }

    // ── REPLACE: 0% completion for 14 days ──────────────────────────────────
    const rate14Zero = completionRateForPeriod(stack, last14);
    const daysOld = (Date.now() - new Date(stack.createdAt).getTime()) / 86_400_000;
    if (rate14Zero === 0 && daysOld >= 14) {
      const replacementId = findReplacement(stack, usedTemplateIds);
      if (replacementId) {
        const replacement = HABIT_LIBRARY.find(h => h.id === replacementId);
        if (replacement) {
          suggestions.push({
            id: `replace-${stack.id}`,
            type: 'REPLACE',
            habitId: stack.id,
            habitTitle: stack.title,
            reason: `"${stack.title}" hasn't been completed in 14 days. Something in this habit isn't working right now — swapping it for a fresh approach in the same category.`,
            fromValue: stack.title,
            toValue: replacement.title,
            replacementTemplateId: replacementId,
          });
        }
      }
    }
  }

  // ── UPDATE_MICRO: weeklyBlocker shifted vs brain assessment primaryBlocker ──
  if (brainProfile && checkinHistory.length >= 2) {
    const latestCheckin = checkinHistory[0];
    const previousBlocker = brainProfile.primaryBlocker;
    const currentBlocker = latestCheckin.weeklyBlocker;

    if (
      currentBlocker !== previousBlocker &&
      // Only suggest if recent check-ins consistently show the same new blocker
      checkinHistory.slice(0, 2).every(c => c.weeklyBlocker === currentBlocker)
    ) {
      const blockerLabels: Record<string, string> = {
        energy: 'low energy',
        overwhelm: 'overwhelm',
        distraction: 'distraction',
        life: 'life events',
      };
      suggestions.push({
        id: `micro-${Date.now()}`,
        type: 'UPDATE_MICRO',
        reason: `Your comeback micro-actions were built for "${blockerLabels[previousBlocker] ?? previousBlocker}", but your last 2 check-ins show "${blockerLabels[currentBlocker] ?? currentBlocker}" as your primary blocker. Updating your re-entry actions to match.`,
        fromValue: previousBlocker,
        toValue: currentBlocker,
      });
    }
  }

  return suggestions;
}
