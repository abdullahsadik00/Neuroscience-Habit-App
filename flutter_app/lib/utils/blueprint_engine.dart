// =============================================================================
// blueprint_engine.dart
//
// What this file is: A pure logic module that selects the best 3-5 habits for
// a user based on their brain profile and optional neurochemistry assessment.
//
// Role in the app architecture:
//   - Called by the onboarding or dashboard screens after the user completes
//     their profile quiz (NeuroBrainProfile) and optional neurochemistry check-in.
//   - Reads from `habit_library.dart` (the full catalogue of available habits)
//     and uses the user's profile data (from `models.dart`) as inputs.
//   - Returns a ranked, de-duplicated list of HabitTemplate objects that become
//     the user's personalised "NeuroBlueprint".
//   - Contains NO Flutter UI widgets — it is plain Dart logic only.
//
// Key concepts a learner needs:
//   1. Pure functions: functions with no side-effects — same input always gives
//      same output. Both functions in this file are pure.
//   2. Dart records (anonymous structs): `(habit: h, score: 3)` is a Dart
//      record — a lightweight way to bundle two values together without defining
//      a full class.
//   3. Method chaining: calling .where().map().toList() in sequence, where each
//      method receives the result of the previous one.
//   4. Cascade operator (..): `list..sort(...)` calls sort() on the list and
//      returns the SAME list (not the sort result). Useful for chaining mutating
//      methods.
//   5. Optional parameters: `[Neurochemistry? chem]` means the caller can omit
//      `chem` entirely — Dart will set it to null automatically.
// =============================================================================

// Brings in the shared data models: HabitTemplate, NeuroBrainProfile,
// Neurochemistry, PeakEnergyWindow, PrimaryBlocker, HabitCategory, etc.
// These are the "shape" definitions for all data objects in the app.
import '../models/models.dart';

// Brings in `habitLibrary` — the master List<HabitTemplate> containing every
// pre-defined habit the app can recommend (defined in data/habit_library.dart).
import '../data/habit_library.dart';

/// Calculates a relevance score for a single [habit] given the user's
/// [profile] and optional real-time neurochemistry reading [chem].
///
/// Higher score = better match for this user.
///
/// Parameters:
///   [habit]   — one candidate HabitTemplate from the library.
///   [profile] — the user's completed brain-profile quiz answers.
///   [chem]    — optional neurochemistry snapshot (dopamine, gaba, etc.
///               measured from a check-in). Pass null to skip chem scoring.
///
/// Returns an [int] score. The scale is not fixed; it is only meaningful
/// relative to other habits scored with the same profile.
///
/// This function is "private" (note the leading underscore `_`). In Dart,
/// any identifier that starts with `_` is private to its own file — other
/// files cannot call _scoreHabit directly.
int _scoreHabit(HabitTemplate habit, NeuroBrainProfile profile, Neurochemistry? chem) {
  int score = 0; // Start at zero; points are added for each matching criterion.

  // +3 if this habit's recommended energy windows include when the user peaks.
  // e.g. a morning-person gets bonus points for habits tagged for morning use.
  // .contains() checks whether a List or Set includes a specific value.
  if (habit.peakEnergyWindows.contains(profile.peakEnergyWindow)) score += 3;

  // +1 if the user's energy peaks vary (variable window) — almost any habit
  // time could work, so we give a small bonus rather than no bonus.
  if (profile.peakEnergyWindow == PeakEnergyWindow.variable) score += 1;

  // +2 if this habit was specifically designed to address the user's blocker
  // (e.g. "overwhelm", "procrastination", "low energy").
  if (habit.primaryBlockers.contains(profile.primaryBlocker)) score += 2;

  // +2 if this habit feeds the user's core motivation driver
  // (e.g. "performance", "clarity", "calm").
  if (habit.coreDrivers.contains(profile.coreDriver)) score += 2;

  // +1 if the habit was designed for people who fail in the same style as
  // the user (e.g. "all-or-nothing", "perfectionism").
  if (habit.failureStyles.contains(profile.failureStyle)) score += 1;

  // Low-energy users get a bonus point for habits that require minimal effort —
  // meeting them where they are rather than asking too much.
  if (profile.primaryBlocker == PrimaryBlocker.energy && habit.energyRequired == 'low') score += 1;

  // Users blocked by overwhelm get a bonus for ultra-short 2-minute habits —
  // reducing the activation cost so they actually start.
  if (profile.primaryBlocker == PrimaryBlocker.overwhelm && habit.duration == '2min') score += 1;

  // The `chem != null` check is a null-safety guard. In Dart, nullable types
  // (written with `?` like `Neurochemistry?`) might hold null. We must check
  // before accessing the object's fields or we'd get a runtime crash.
  if (chem != null) {
    // Score < 40 means the user is low in this neurotransmitter — prioritise
    // habits that are known to boost it.

    // Low dopamine (motivation chemical) → prefer habits that target dopamine.
    if (chem.dopamine < 40 && habit.neurochemTarget.contains('dopamine')) score += 2;

    // Low acetylcholine (focus/learning chemical) → prefer focus-building habits.
    if (chem.acetylcholine < 40 && habit.neurochemTarget.contains('acetylcholine')) score += 2;

    // Low GABA (calm/inhibition chemical) → prefer grounding/calming habits.
    if (chem.gaba < 40 && habit.neurochemTarget.contains('gaba')) score += 2;

    // High epinephrine (adrenaline, stress chemical — score > 65) also benefits
    // from GABA-boosting habits because GABA counteracts excess stress arousal.
    if (chem.epinephrine > 65 && habit.neurochemTarget.contains('gaba')) score += 2;
  }

  return score; // Return the total accumulated score for this habit.
}

/// Builds a personalised NeuroBlueprint — an ordered list of 3-5 [HabitTemplate]s
/// that best match the user's [profile] and optional real-time [chem] data.
///
/// The algorithm:
///   1. Scores every "full" habit in the library (skipping lite/teaser variants).
///   2. Sorts all habits by score, highest first.
///   3. Picks the best habit from each HabitCategory (ensuring variety).
///   4. Fills remaining slots (up to 5 total) with the next highest-scored habits.
///   5. Returns the final list, capped at 5.
///
/// Parameters:
///   [profile] — the user's completed NeuroBrainProfile.
///   [chem]    — optional neurochemistry snapshot. If omitted, only profile
///               criteria are used for scoring.
///
/// Returns a [List<HabitTemplate>] of 3–5 habits in descending relevance order.
List<HabitTemplate> buildBlueprint(NeuroBrainProfile profile, [Neurochemistry? chem]) {
  // `[Neurochemistry? chem]` is an optional positional parameter (square brackets).
  // The caller may write: buildBlueprint(profile) — chem will be null.
  // Or:                   buildBlueprint(profile, myChem) — chem will hold data.

  // --- Step 1: Score every full habit and sort descending ---

  final scored = habitLibrary
      // .where() filters the list — keep only habits that do NOT have a
      // liteVersionId. Lite variants are teaser/preview habits; we exclude them
      // from recommendations so users only see the full versions.
      // `h.liteVersionId == null` is true when the field holds no value (i.e.,
      // this habit is not a lite variant).
      .where((h) => h.liteVersionId == null)

      // .map() transforms each element — here we wrap each habit in a Dart
      // record that bundles the habit object together with its computed score.
      // Dart records use named fields: `(habit: h, score: _scoreHabit(...))`.
      // This lets us sort by score while keeping the habit object attached.
      .map((h) => (habit: h, score: _scoreHabit(h, profile, chem)))

      // Convert the lazy iterable (result of .where().map()) into an actual
      // List so we can call .sort() on it.
      .toList()

    // The `..` is the CASCADE OPERATOR. It calls sort() on the list and then
    // returns the SAME list (not the void return of sort). This lets us chain
    // the sort directly onto the .toList() call above.
    // Sorting with `b.score.compareTo(a.score)` puts the HIGHEST scores first
    // (descending order). Reversing a and b flips the default ascending order.
    ..sort((a, b) => b.score.compareTo(a.score));

  // `selected` will hold the final recommended habits as we build the list.
  final selected = <HabitTemplate>[];

  // `usedCategories` tracks which HabitCategory values we have already covered.
  // Using a Set<> (not a List<>) ensures no duplicate categories are recorded.
  // (This variable is declared for potential future use in filtering logic.)
  final usedCategories = <HabitCategory>{};

  // --- Step 2: Pick the best habit from each category (ensures variety) ---

  // HabitCategory.values is a built-in Dart enum property — it returns a list
  // of every value in the HabitCategory enum (e.g. sleep, movement, focus…).
  for (final cat in HabitCategory.values) {
    // .firstWhere() scans the list and returns the first element matching the
    // test. Here we want the highest-scored habit in category `cat` that
    // hasn't already been added to `selected`.
    // `.any()` returns true if at least one element in the list satisfies the test.
    final best = scored.firstWhere(
      (s) => s.habit.category == cat && !selected.any((sel) => sel.id == s.habit.id),

      // `orElse` is a fallback called when no element matches the test.
      // We return a dummy record with score: -1 as a sentinel value meaning
      // "nothing found". Using `scored.first.habit` for the habit field is
      // arbitrary — we only care that score is -1 to detect "no match".
      orElse: () => (habit: scored.first.habit, score: -1),
    );

    // Only add this category's best habit if:
    //   a) We actually found a valid match (score >= 0, not our -1 sentinel), AND
    //   b) That habit is not already in selected (defensive duplicate check).
    if (best.score >= 0 && !selected.any((s) => s.id == best.habit.id)) {
      selected.add(best.habit); // Add the HabitTemplate to our selection list.
      usedCategories.add(cat);  // Mark this category as covered.

      // Stop early once we have 3 habits — we want diversity but not too many
      // category-locked picks before we fill remaining slots by pure score.
      if (selected.length >= 3) break;
    }
  }

  // --- Step 3: Fill remaining slots (up to 5) with next highest-scored habits ---

  // Iterate through all scored habits in order (highest score first, from Step 1).
  for (final item in scored) {
    if (selected.length >= 5) break; // We already have 5 — stop iterating.

    // Only add this habit if it isn't already in the selected list.
    // `.any()` returns true if any element in selected has the same id.
    // The `!` negates it — so this condition means "not already selected".
    if (!selected.any((s) => s.id == item.habit.id)) {
      selected.add(item.habit);
    }
  }

  // --- Step 4: Return the final list, hard-capped at 5 habits ---

  // .take(5) returns an Iterable of at most 5 elements (safe even if selected
  // has fewer than 5). .toList() converts it back to a concrete List<HabitTemplate>.
  return selected.take(5).toList();
}
