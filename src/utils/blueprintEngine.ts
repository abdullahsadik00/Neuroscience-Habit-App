import type { NeuroBrainProfile } from '../store/useNeuroStore';
import { HABIT_LIBRARY, type HabitTemplate } from '../data/habitLibrary';

export function scoreHabit(habit: HabitTemplate, profile: NeuroBrainProfile): number {
  let score = 0;

  // +3 if habit timing matches peak energy window
  if (habit.tags.peakEnergyWindow?.includes(profile.peakEnergyWindow)) score += 3;
  if (profile.peakEnergyWindow === 'variable') score += 1; // variable users benefit from any timing

  // +2 if habit addresses the user's primary blocker
  if (habit.tags.primaryBlocker?.includes(profile.primaryBlocker)) score += 2;

  // +2 if habit aligns with user's core driver
  if (habit.tags.coreDriver?.includes(profile.coreDriver)) score += 2;

  // +1 if habit supports user's failure style recovery pattern
  if (habit.tags.failureStyle?.includes(profile.failureStyle)) score += 1;

  // Energy level modifier: if user's peak is variable or primaryBlocker is energy,
  // prefer lower-energy habits slightly
  if (profile.primaryBlocker === 'energy' && habit.energyRequired === 'low') score += 1;
  if (profile.primaryBlocker === 'overwhelm' && habit.duration === '2min') score += 1;

  return score;
}

export interface ScoredHabit extends HabitTemplate {
  score: number;
}

export function buildBlueprint(profile: NeuroBrainProfile): HabitTemplate[] {
  const scored: ScoredHabit[] = HABIT_LIBRARY
    .filter(h => !h.liteVersionId || HABIT_LIBRARY.some(l => l.id === h.liteVersionId))
    // Exclude lite versions from primary selection (they appear as swap options)
    .filter(h => !HABIT_LIBRARY.some(full => full.liteVersionId === h.id) || h.liteVersionId == null)
    .map(h => ({ ...h, score: scoreHabit(h, profile) }))
    .sort((a, b) => b.score - a.score);

  const selected: HabitTemplate[] = [];
  const usedCategories = new Set<string>();

  // First pass: pick top-scoring habit from each category (ensures variety)
  const categories: HabitTemplate['category'][] = ['focus', 'wellness', 'mindset', 'fitness'];
  for (const cat of categories) {
    const best = scored.find(h => h.category === cat && !selected.includes(h));
    if (best) {
      selected.push(best);
      usedCategories.add(cat);
      if (selected.length >= 3) break;
    }
  }

  // Second pass: fill up to 5 with highest remaining scores
  for (const habit of scored) {
    if (selected.length >= 5) break;
    if (!selected.find(s => s.id === habit.id)) {
      selected.push(habit);
    }
  }

  return selected.slice(0, 5);
}

export function getAlternativesFor(habitId: string, profile: NeuroBrainProfile, excludeIds: string[]): HabitTemplate[] {
  const current = HABIT_LIBRARY.find(h => h.id === habitId);
  if (!current) return [];

  return HABIT_LIBRARY
    .filter(h =>
      h.id !== habitId &&
      !excludeIds.includes(h.id) &&
      h.category === current.category
    )
    .map(h => ({ ...h, score: scoreHabit(h, profile) }))
    .sort((a: ScoredHabit, b: ScoredHabit) => b.score - a.score)
    .slice(0, 3);
}
