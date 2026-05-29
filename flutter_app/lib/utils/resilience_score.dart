// =============================================================================
// resilience_score.dart
//
// What this file is:
//   A pure utility that computes the user's Adaptability Score (0–1000) —
//   NeuroSync's proprietary metric for measuring behavioral resilience.
//
// Why this metric exists:
//   The Neurochemistry HUD showed arbitrary numbers that smart users would
//   eventually dismiss as pseudoscience. The Adaptability Score measures
//   something real: how consistently the user chooses to recover, downscale,
//   and re-engage rather than abandon. It rewards recovery behaviors directly.
//
// Scoring model:
//   +50  — Comeback Protocol completed with micro-actions
//   +20  — Comeback Protocol acknowledged (without micro-actions)
//   +30  — Urge surf completed (NeuroSwap behavior)
//   +15  — Lite Mode activated (chose to downscale instead of skipping)
//   +10  — Weekly check-in completed
//   Cap  — 1000 points maximum
//
// Role in app architecture:
//   - Pure functions only — no Flutter widgets, no state management.
//   - Called by dashboard_page.dart to compute the score before passing it
//     to ResilienceHUD.
// =============================================================================

import '../models/models.dart';

// =============================================================================
// calcResilienceScore — the main scoring function
// =============================================================================

/// Computes the user's Adaptability Score (0–1000).
///
/// The score measures how consistently the user chooses adaptive behaviors:
/// coming back after misses, surfing urges, downscaling instead of skipping,
/// and completing weekly check-ins.
///
/// Parameters:
///   [comebacks]    — all comeback records (used to score comeback events)
///   [swaps]        — all NeuroSwap records (used to score urge surfs)
///   [stacks]       — all habit stacks (used to score lite mode activations)
///   [checkins]     — all weekly check-in records (used to score check-ins)
///
/// Returns an integer clamped to [0, 1000].
int calcResilienceScore(
  List<ComebackRecord> comebacks,
  List<NeuroSwap> swaps,
  List<NeuroStack> stacks,
  List<CheckinRecord> checkins,
) {
  int score = 0;

  // ── Comeback points ────────────────────────────────────────────────────────
  // Full comeback with micro-actions = +50, acknowledged only = +20.
  for (final cb in comebacks) {
    score += cb.microActionsCompleted ? 50 : 20;
  }

  // ── Urge surf points ───────────────────────────────────────────────────────
  // Each urge surf event across all swaps is worth +30.
  for (final swap in swaps) {
    score += swap.urgeSurfingCompletions.length * 30;
  }

  // ── Lite mode points ───────────────────────────────────────────────────────
  // Each date a user activated lite mode on any habit is worth +15.
  // We count unique (habitId, date) pairs to avoid double-counting.
  for (final stack in stacks) {
    score += stack.liteModeDates.length * 15;
  }

  // ── Check-in points ────────────────────────────────────────────────────────
  // Each completed weekly check-in is worth +10.
  score += checkins.length * 10;

  // Cap at 1000 — a meaningful ceiling that takes months to reach.
  return score.clamp(0, 1000);
}

// =============================================================================
// getResilienceLabel — tier name for a given score
// =============================================================================

/// Returns the tier label for a given Adaptability Score.
///
/// Tiers are designed so each feels genuinely earned:
///   - "Getting Started" (0–99): brand new user
///   - "Building Resilience" (100–299): consistent early usage (~2–3 weeks)
///   - "Adaptive Performer" (300–499): solid comeback track record
///   - "Recovery Expert" (500–699): months of consistent practice
///   - "Neural Architect" (700–899): deep resilience system mastery
///   - "Apex Resilience" (900–1000): elite — the top fraction of users
///
/// Parameters:
///   [score] — the user's current Adaptability Score (0–1000).
///
/// Returns the matching tier name as a String.
String getResilienceLabel(int score) {
  if (score >= 900) return 'Apex Resilience';
  if (score >= 700) return 'Neural Architect';
  if (score >= 500) return 'Recovery Expert';
  if (score >= 300) return 'Adaptive Performer';
  if (score >= 100) return 'Building Resilience';
  return 'Getting Started';
}

// =============================================================================
// getResilienceTip — one-line coaching tip based on score + profile
// =============================================================================

/// Returns a short coaching tip tailored to the user's current score and
/// optional brain profile (failure style).
///
/// Parameters:
///   [score]   — the user's Adaptability Score.
///   [profile] — the user's NeuroBrainProfile (nullable; tips still work without it).
///
/// Returns a single-sentence coaching prompt.
String getResilienceTip(int score, NeuroBrainProfile? profile) {
  // If the user has a brain profile, use their failure style to personalise.
  if (profile != null) {
    switch (profile.failureStyle) {
      case FailureStyle.perfectionist:
        if (score < 100) return 'Every comeback earns more than every perfect day.';
        if (score < 300) return 'Your recovery rate matters more than your miss rate.';
        return 'You\'re building a system, not chasing a streak. Keep going.';
      case FailureStyle.avoider:
        if (score < 100) return 'Opening the app after a miss IS the habit.';
        if (score < 300) return 'Each lite mode day is a win, not a compromise.';
        return 'You face it instead of avoiding it. That\'s the whole skill.';
      case FailureStyle.analyst:
        if (score < 100) return 'This score measures adaptive behavior, not willpower.';
        if (score < 300) return 'Resilience compounds just like skill — log the data.';
        return 'Your failure signature is shrinking. The system is working.';
      case FailureStyle.drifter:
        if (score < 100) return 'One comeback resets the momentum. Just one.';
        if (score < 300) return 'Lite mode keeps identity alive on low-energy days.';
        return 'Consistency of identity, not intensity of action. You\'re getting it.';
    }
  }

  // Generic tips when no profile is available.
  if (score < 100) return 'Each comeback earns 50 points. Start your streak now.';
  if (score < 300) return 'You\'re building the most important muscle: recovery.';
  if (score < 500) return 'Adaptive performers recover faster than they fail.';
  if (score < 700) return 'Your Recovery Rate separates you from streak-chasers.';
  if (score < 900) return 'You are resilient. The data proves it.';
  return 'Apex Resilience. Your comeback system is elite.';
}
