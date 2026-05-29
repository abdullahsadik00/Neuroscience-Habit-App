// =============================================================================
// recalibration_engine.dart
//
// What this file is:
//   A pure-logic utility that analyses a user's active habits and generates
//   "recalibration suggestions" — actionable recommendations such as scaling
//   down a habit that is too hard or swapping out one that has been abandoned.
//
// Role in app architecture:
//   This file sits in the "utils" layer and has no Flutter UI code at all.
//   It is called from a Riverpod provider (likely in providers/) which feeds
//   the results to a screen widget.  Data flows in from:
//     • models/models.dart   — the core data types (NeuroStack, etc.)
//     • data/habit_library.dart — the master list of all available habit templates
//     • utils/neuro_helpers.dart — shared helper functions (e.g. date formatting)
//
// Key concepts to know before reading:
//   1. Pure functions — functions that take inputs and return outputs with
//      no side effects (no UI updates, no network calls).  Easy to test.
//   2. List<T> — Dart's generic list.  List<String> is a list of strings.
//   3. Nullable types (String?, double?) — the '?' means the value might be
//      null (nothing).  Dart forces you to handle this explicitly.
//   4. .where() — filters a list, keeping only items that pass a test.
//   5. .firstWhere() — finds the first item in a list matching a condition.
//   6. Named constructors — e.g. RecalibrationSuggestion(...) is a Dart class
//      being instantiated with named parameters.
// =============================================================================

// Brings in the app's core data model classes:
//   NeuroStack        — represents one active habit the user is tracking
//   CheckinRecord     — represents one weekly check-in the user completed
//   NeuroBrainProfile — the user's personalised "brain type" profile
//   RecalibrationSuggestion — the output type this file produces
//   SuggestionType    — an enum describing what kind of suggestion it is
import '../models/models.dart';

// Brings in `habitLibrary` — a hard-coded List of HabitTemplate objects
// that act as the master catalogue of all available habits in the app.
import '../data/habit_library.dart';

// Brings in shared helper utilities, specifically `getLocalDateString()`
// which converts a DateTime into a consistent "YYYY-MM-DD" string so dates
// can be compared as plain strings.
import 'neuro_helpers.dart';

// -----------------------------------------------------------------------------
// PRIVATE HELPER: _lastNDays
// -----------------------------------------------------------------------------

/// Returns a list of date strings for the last [n] days (not including today).
///
/// For example, _lastNDays(3) called on 2026-05-29 returns:
///   ["2026-05-28", "2026-05-27", "2026-05-26"]
///
/// Parameters:
///   [n] — how many days to look back.
///
/// Returns:
///   A List<String> where each string is a "YYYY-MM-DD" formatted date.
///
/// Why exclude today?  Because the current day is still in progress and
/// including it would unfairly penalise completion rates.
List<String> _lastNDays(int n) {
  // List.generate(n, builder) creates a list of n items.
  // The builder receives the index i (0, 1, 2 … n-1) for each position.
  return List.generate(n, (i) {
    // Subtract (i+1) days from now so index 0 → yesterday, 1 → two days ago, etc.
    final d = DateTime.now().subtract(Duration(days: i + 1));
    // Convert the DateTime to a "YYYY-MM-DD" string using the shared helper.
    return getLocalDateString(d);
  });
}

// -----------------------------------------------------------------------------
// PRIVATE HELPER: _completionRateForPeriod
// -----------------------------------------------------------------------------

/// Calculates what fraction of eligible days within [days] a habit was completed.
///
/// "Eligible" days are those on or after the habit was created — it would be
/// unfair to count days before the habit even existed as missed completions.
///
/// Parameters:
///   [stack] — the habit (NeuroStack) whose completions we are checking.
///   [days]  — the list of date strings to evaluate (e.g. last 14 days).
///
/// Returns:
///   A double between 0.0 (never completed) and 1.0 (completed every day).
///   Returns 1.0 if there are no eligible days (habit too new to judge).
double _completionRateForPeriod(NeuroStack stack, List<String> days) {
  // Filter [days] to only those on or after the habit's creation date.
  // stack.createdAt is an ISO 8601 timestamp like "2026-05-01T10:00:00.000Z".
  // .substring(0, 10) trims it to just the date part "2026-05-01".
  // .compareTo() on strings does lexicographic comparison — because our dates
  // are in YYYY-MM-DD format, lexicographic order == chronological order.
  // >= 0 means the candidate day is the same as or later than createdAt.
  final eligible = days.where((d) => d.compareTo(stack.createdAt.substring(0, 10)) >= 0).toList();

  // If no days qualify (habit was created after all the days we're looking at),
  // return 1.0 so we don't mistakenly flag it as problematic.
  if (eligible.isEmpty) return 1.0;

  // Count how many eligible days appear in the habit's completions list.
  // stack.completions is a Set or List of "YYYY-MM-DD" strings for completed days.
  // .where(...).length counts the matching items without building a new list.
  final done = eligible.where((d) => stack.completions.contains(d)).length;

  // Integer division would truncate to 0 or 1, so we let Dart do double division.
  return done / eligible.length;
}

// -----------------------------------------------------------------------------
// PRIVATE HELPER: _findLiteVersion
// -----------------------------------------------------------------------------

/// Looks up whether the given habit has a "lite" (easier) variant in the library.
///
/// Some habits have a gentler version designed to keep the neural pathway
/// forming with less friction (e.g. "10-min run" → "5-min walk").
///
/// Parameters:
///   [stack] — the active habit we want to find a lite version for.
///
/// Returns:
///   The template ID (String) of the lite version, or null if none exists.
///
/// The return type is String? — the '?' means it can be null.
String? _findLiteVersion(NeuroStack stack) {
  // Search the master habit library for a template whose title matches this stack.
  // orElse: () => habitLibrary.first  is a fallback in case no match is found
  // (firstWhere throws an error without a fallback when nothing matches).
  final template = habitLibrary.firstWhere(
    (h) => h.title == stack.title,
    orElse: () => habitLibrary.first, // safe fallback — we check liteVersionId below
  );
  // liteVersionId is nullable on HabitTemplate; null means no lite version exists.
  return template.liteVersionId;
}

// -----------------------------------------------------------------------------
// PRIVATE HELPER: _findReplacement
// -----------------------------------------------------------------------------

/// Finds a different habit template in the same category that the user hasn't
/// already added, to suggest as a fresh replacement for an abandoned habit.
///
/// Parameters:
///   [stack]      — the habit we want to replace.
///   [excludeIds] — template IDs the user already has active (to avoid duplicates).
///
/// Returns:
///   The template ID of a suitable replacement, or null if none is available.
String? _findReplacement(NeuroStack stack, List<String> excludeIds) {
  // Filter the library to habits that:
  //   • belong to the same category as the struggling habit
  //   • are not the exact same habit (different title)
  //   • are not already in the user's active stack (not in excludeIds)
  final candidates = habitLibrary.where(
    (h) => h.category == stack.category && h.title != stack.title && !excludeIds.contains(h.id),
  ).toList();

  // If candidates exist, suggest the first one; otherwise return null.
  // The ternary  condition ? valueIfTrue : valueIfFalse  is Dart's inline if.
  return candidates.isNotEmpty ? candidates.first.id : null;
}

// -----------------------------------------------------------------------------
// PUBLIC FUNCTION: runRecalibration
// -----------------------------------------------------------------------------

/// Analyses all of the user's active habits and weekly check-ins, then returns
/// a list of recalibration suggestions the app can present to the user.
///
/// This is the main entry point of this file.  It orchestrates the three private
/// helpers above and applies all recalibration rules in one pass.
///
/// Parameters:
///   [stacks]         — every NeuroStack the user has ever created (active + archived).
///   [checkinHistory] — ordered list of weekly check-in records, newest first.
///   [brainProfile]   — the user's brain profile, or null if not yet completed.
///                      The '?' makes the parameter optional/nullable.
///
/// Returns:
///   A List<RecalibrationSuggestion> — may be empty if no issues are detected.
///
/// Side effects: none — this is a pure function.
List<RecalibrationSuggestion> runRecalibration(
  List<NeuroStack> stacks,
  List<CheckinRecord> checkinHistory,
  NeuroBrainProfile? brainProfile, // nullable — user may not have completed onboarding
) {
  // Start with an empty, growable list that we'll populate with suggestions.
  // <RecalibrationSuggestion>[] is a typed empty list literal.
  final suggestions = <RecalibrationSuggestion>[];

  // Only evaluate habits that the user has not archived.
  // isActive is a bool field on NeuroStack.
  final active = stacks.where((s) => s.isActive).toList();

  // Build the reference window: the last 14 days as date strings.
  final last14 = _lastNDays(14);

  // Build a list of template IDs that the user is already using.
  // This prevents us from recommending a habit they already have.
  // .map() transforms each item; here it looks up the library template for each stack.
  final usedTemplateIds = active.map((s) {
    // Find the library template that matches this stack's title.
    final t = habitLibrary.firstWhere((h) => h.title == s.title, orElse: () => habitLibrary.first);
    return t.id; // return just the ID from the transformed item
  }).toList(); // .toList() materialises the lazy .map() into an actual List

  // ---- RULE 1 & 2: Per-habit completion rate checks ----

  // Loop over every active habit to check whether it needs intervention.
  for (final stack in active) {
    // Calculate what percentage of the last 14 eligible days were completed.
    final rate14 = _completionRateForPeriod(stack, last14);

    // RULE 1 — Scale down if completion rate is below 40%.
    // A rate < 0.4 means the habit is generating friction / resistance.
    if (rate14 < 0.4) {
      // Check whether a lite (easier) version exists in the library.
      final liteId = _findLiteVersion(stack);

      // liteId != null means a lite version was found — proceed.
      if (liteId != null) {
        // Look up the full lite template object by its ID.
        final lite = habitLibrary.firstWhere((h) => h.id == liteId, orElse: () => habitLibrary.first);

        // Add a "scale down" suggestion to the results list.
        suggestions.add(RecalibrationSuggestion(
          id: 'scale-${stack.id}', // unique ID for this suggestion using string interpolation
          type: SuggestionType.scaleDown, // enum value — tells the UI what kind this is
          habitId: stack.id,             // the habit being recommended to change
          habitTitle: stack.title,       // human-readable title for display
          // The reason string uses string interpolation ($variable) and
          // .round() to turn a decimal like 0.37 into the integer 37.
          reason:
              'You completed "${stack.title}" only ${(rate14 * 100).round()}% of days over the last 2 weeks. A lighter version builds the same neural pathway with less friction.',
          fromValue: stack.title, // what the habit is now
          toValue: lite.title,    // what we recommend switching it to
          replacementTemplateId: liteId, // the template to use when applying the suggestion
        ));

        // `continue` skips the rest of this loop iteration — we don't need to
        // also check Rule 2 for a habit we're already suggesting to scale down.
        continue;
      }
    }

    // RULE 2 — Replace entirely if the habit has been completely ignored for 14+ days.
    // daysOld measures how long ago the habit was first created.
    final daysOld = DateTime.now().difference(DateTime.parse(stack.createdAt)).inDays;

    // rate14 == 0 means not completed once in 14 days.
    // daysOld >= 14 ensures the habit is old enough to fairly judge.
    if (rate14 == 0 && daysOld >= 14) {
      // Find a fresh alternative in the same category the user doesn't already have.
      final replacementId = _findReplacement(stack, usedTemplateIds);

      if (replacementId != null) {
        // Look up the full replacement template by ID.
        final replacement = habitLibrary.firstWhere((h) => h.id == replacementId, orElse: () => habitLibrary.first);

        // Add a "replace" suggestion.
        suggestions.add(RecalibrationSuggestion(
          id: 'replace-${stack.id}', // unique ID using string interpolation
          type: SuggestionType.replace, // enum: full replacement, not just a tweak
          habitId: stack.id,
          habitTitle: stack.title,
          // The backslash before the apostrophe (\') is an escape sequence —
          // it lets us use an apostrophe inside a single-quoted string.
          reason:
              '"${stack.title}" hasn\'t been completed in 14 days. Swapping it for a fresh approach in the same category.',
          fromValue: stack.title,
          toValue: replacement.title,
          replacementTemplateId: replacementId,
        ));
      }
    }
  }

  // ---- RULE 3: Blocker shift detection (uses brain profile + check-in history) ----

  // brainProfile != null checks that onboarding is complete so we have a profile.
  // checkinHistory.length >= 2 ensures we have at least two check-ins to compare.
  if (brainProfile != null && checkinHistory.length >= 2) {
    // The most recent check-in is at index 0 (list is newest-first).
    final latest = checkinHistory.first;

    // The blocker the user's brain profile was originally calibrated around.
    // .name converts a Dart enum value to its string name (e.g. Blocker.energy → "energy").
    final previousBlocker = brainProfile.primaryBlocker.name;

    // The blocker the user reported in their most recent check-in.
    final currentBlocker = latest.weeklyBlocker;

    // Only suggest updating the micro-actions if:
    //   a) the blocker has actually changed from the profile baseline, AND
    //   b) the new blocker has been reported consistently for the last 2 check-ins
    //      (to avoid reacting to a one-off bad week).
    if (currentBlocker != previousBlocker &&
        // .take(2) returns an Iterable of only the first 2 items.
        // .every() returns true only if the condition holds for ALL items.
        checkinHistory.take(2).every((c) => c.weeklyBlocker == currentBlocker)) {

      // A lookup map from internal blocker keys to user-friendly display labels.
      // `const` means this map is a compile-time constant — it never changes.
      const labels = {
        'energy': 'low energy',
        'overwhelm': 'overwhelm',
        'distraction': 'distraction',
        'life': 'life events',
      };

      // Add an "update micro-actions" suggestion.
      suggestions.add(RecalibrationSuggestion(
        // Use DateTime.now().millisecondsSinceEpoch to generate a unique numeric ID
        // since this suggestion is not tied to a specific habit.
        id: 'micro-${DateTime.now().millisecondsSinceEpoch}',
        type: SuggestionType.updateMicro, // enum: update comeback micro-actions
        // No habitId/habitTitle here — this suggestion is about the overall plan,
        // not a single habit, so those named parameters are omitted (they're nullable).
        reason:
            // ?? is the "null-coalescing" operator — if labels[previousBlocker] is null
            // (key not found in the map), fall back to the raw previousBlocker string.
            'Your comeback micro-actions were built for "${labels[previousBlocker] ?? previousBlocker}", but your last 2 check-ins show "${labels[currentBlocker] ?? currentBlocker}" as your primary blocker.',
        fromValue: previousBlocker, // original blocker the plan was built for
        toValue: currentBlocker,    // new blocker to recalibrate towards
      ));
    }
  }

  // Return the complete list of suggestions (may be empty if nothing needs fixing).
  return suggestions;
}
