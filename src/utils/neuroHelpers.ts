/**
 * Neuroscience habit rewiring helpers
 */

/**
 * Calculates the current consecutive day streak based on completion dates.
 * Dates are stored in "YYYY-MM-DD" format.
 */
export function calculateStreak(dates: string[]): number {
  if (dates.length === 0) return 0;
  
  // Sort dates descending (most recent first)
  const sortedDates = [...new Set(dates)].sort((a, b) => b.localeCompare(a));
  
  const todayStr = getLocalDateString(new Date());
  const yesterdayStr = getLocalDateString(new Date(Date.now() - 86400000));
  
  const latestDate = sortedDates[0];
  
  // If the last completion was neither today nor yesterday, the streak is broken
  if (latestDate !== todayStr && latestDate !== yesterdayStr) {
    return 0;
  }
  
  let streak = 0;
  let currentDate = new Date(latestDate);
  
  for (let i = 0; i < sortedDates.length; i++) {
    const checkStr = getLocalDateString(currentDate);
    if (sortedDates.includes(checkStr)) {
      streak++;
      // Move to previous day
      currentDate.setDate(currentDate.getDate() - 1);
    } else {
      break;
    }
  }
  
  return streak;
}

/**
 * Formats a Date object to "YYYY-MM-DD" in local time.
 */
export function getLocalDateString(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Computes myelination percentage.
 * Myelination represents the thickness of the insulating myelin sheath surrounding the nerve fiber.
 * Scientifically, myelination increases with high repetition, deep attention (acetylcholine), and consistency.
 * In our system:
 * - Each completion adds 3% myelination base.
 * - An active streak adds a streak bonus (streak * 1.5%).
 * - Fully completed 21-day streaks lock it at 100% representing an "automatic" neural pathway.
 * - Minimum is 0%, maximum is 100%.
 */
export function calculateMyelination(completionsCount: number, streak: number): number {
  if (completionsCount === 0) return 0;
  const base = completionsCount * 4; // 25 completions for 100%
  const streakBonus = streak * 2.5; // High consistency speeds up myelination
  return Math.min(100, Math.round(base + streakBonus));
}

/**
 * Simulates a neurochemical decay to homeostatic baseline (50).
 * Should be called periodically to represent synaptic neurotransmitter clearing.
 */
export function decayNeurochemical(current: number, baseline = 50, rate = 0.1): number {
  const difference = baseline - current;
  const updated = current + difference * rate;
  return Math.round(updated * 10) / 10;
}
