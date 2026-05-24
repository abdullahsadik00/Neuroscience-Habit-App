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
 * Computes neural pathway strength (called "myelination" in the UI as an accessible metaphor).
 *
 * Research basis: Lally et al. (2010) found habit automaticity takes 18–254 days (median ~66).
 * The primary biological mechanism is basal ganglia LTP (Graybiel), with myelination as a real
 * but secondary contributor to signal speed. "100%" means "well-established" — not fully automatic,
 * which varies by person and behavior complexity.
 *
 * Formula: reaches ~50% at ~33 completions, ~85% base at ~57 completions, 100% requires
 * sustained streak on top — roughly matching Lally's median 66-day finding.
 */
export function calculateMyelination(completionsCount: number, streak: number): number {
  if (completionsCount === 0) return 0;
  const base = Math.min(85, completionsCount * 1.5);
  const streakBonus = Math.min(15, streak * 1.5);
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
