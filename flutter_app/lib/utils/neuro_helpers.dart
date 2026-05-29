// =============================================================================
// FILE: neuro_helpers.dart
//
// What this file is: A collection of pure utility functions that perform
// neuroscience-inspired calculations used throughout the NeuroSync habit app.
//
// Role in app architecture:
//   This file is a "helpers" or "utils" module — it contains no UI widgets,
//   no state management, and no side effects. It is imported by other files
//   (such as providers or widgets) that need to compute derived values like
//   streak length or myelination progress. Because these are plain Dart
//   functions (not classes), any file in the project can call them directly.
//
// Key concepts a learner needs to know:
//   - Dart functions: Dart (the language Flutter uses) supports top-level
//     functions — functions that live outside any class. These are called
//     directly by name, e.g. calculateStreak(dates).
//   - Pure functions: A pure function always produces the same output for the
//     same input and has no side effects (it does not modify global state,
//     write to disk, or call the network). Pure functions are easy to test.
//   - DateTime: Dart's built-in type for representing a point in time.
//   - String formatting / padding: Ensuring date parts are always 2 or 4
//     digits wide so they sort correctly as strings (e.g. "09" not "9").
// =============================================================================

/// Converts a [DateTime] object into a zero-padded "YYYY-MM-DD" string using
/// the LOCAL time zone of the device (not UTC).
///
/// Why we need this: Dart's [DateTime.toString()] includes hours, minutes,
/// seconds, and timezone info, which makes direct string comparison of dates
/// unreliable. By reducing a date to "YYYY-MM-DD" we can compare two dates
/// as plain strings to check if they fall on the same calendar day.
///
/// Parameters:
///   [date] — any Dart DateTime value (e.g. DateTime.now() or a stored date).
///
/// Returns:
///   A String like "2026-05-29". Always exactly 10 characters.
String getLocalDateString(DateTime date) {
  // Extract the 4-digit year from the DateTime and convert it to a String.
  // padLeft(4, '0') ensures we always get 4 digits — e.g. year 200 → "0200".
  final y = date.year.toString().padLeft(4, '0');

  // Extract the month number (1–12) and zero-pad to 2 digits: "01" through "12".
  final m = date.month.toString().padLeft(2, '0');

  // Extract the day of the month (1–31) and zero-pad to 2 digits: "01" through "31".
  final d = date.day.toString().padLeft(2, '0');

  // String interpolation: $y, $m, $d insert the variable values into the string.
  // The result looks like "2026-05-29".
  return '$y-$m-$d';
}

/// Calculates the current consecutive-day streak from a list of completion
/// date strings.
///
/// The neuroscience rationale: consistent daily repetition strengthens neural
/// pathways (myelination). A streak count gives users a concrete measure of
/// that consistency.
///
/// Algorithm overview:
///   1. Remove duplicate dates and sort them newest-first.
///   2. If the most recent date is neither today nor yesterday, the streak is
///      already broken — return 0.
///   3. Starting from the most recent date, walk backwards one day at a time.
///      Count consecutive days that appear in the date list.
///   4. Stop counting the moment a day is missing.
///
/// Parameters:
///   [dates] — a List of "YYYY-MM-DD" strings, one per completion event.
///             May contain duplicates (e.g. multiple completions on one day).
///
/// Returns:
///   An int representing the number of consecutive days ending today (or
///   yesterday). Returns 0 if no recent streak exists.
int calculateStreak(List<String> dates) {
  // Guard clause: if there are no completions at all, the streak is 0.
  if (dates.isEmpty) return 0;

  // Convert the List to a Set to remove duplicate date strings
  // (multiple completions on the same day should count as 1 day).
  // Then convert back to a List so we can sort it.
  // The cascade operator ".." lets us call .sort() on the same list that
  // .toList() just created, without needing a separate variable.
  // Sorting with (a, b) => b.compareTo(a) gives DESCENDING order (newest first),
  // because for "YYYY-MM-DD" strings, lexicographic order equals date order.
  final unique = dates.toSet().toList()..sort((a, b) => b.compareTo(a));

  // Get today's date as a "YYYY-MM-DD" string in the device's local time zone.
  final todayStr = getLocalDateString(DateTime.now());

  // Get yesterday's date string by subtracting 1 day from now.
  // Duration(days: 1) represents a 24-hour period.
  // subtract() returns a new DateTime — it does NOT modify DateTime.now().
  final yesterdayStr = getLocalDateString(DateTime.now().subtract(const Duration(days: 1)));

  // The most recent date in the sorted list (index 0 = newest after descending sort).
  final latest = unique.first;

  // If the user's most recent completion was neither today nor yesterday, the
  // streak has already been broken. Return 0 immediately.
  if (latest != todayStr && latest != yesterdayStr) return 0;

  // streak starts at 0; we will increment it for each consecutive day found.
  int streak = 0;

  // Parse the most-recent date string back into a DateTime so we can do
  // date arithmetic (subtract one day at a time).
  // DateTime.parse() understands the "YYYY-MM-DD" format.
  DateTime current = DateTime.parse(latest);

  // Walk backward through calendar days, starting from `latest`.
  // unique.length is the maximum possible streak (one entry per unique date).
  for (int i = 0; i < unique.length; i++) {
    // Convert the current day being checked back to a "YYYY-MM-DD" string.
    final checkStr = getLocalDateString(current);

    // Check whether this calendar day appears in our unique date list.
    if (unique.contains(checkStr)) {
      streak++; // This day was completed — extend the streak by 1.
      // Move one day further into the past for the next loop iteration.
      current = current.subtract(const Duration(days: 1));
    } else {
      // This calendar day is missing — the consecutive run is broken.
      break; // Exit the loop immediately; no need to check older dates.
    }
  }

  return streak; // Return the final consecutive-day count.
}

/// Calculates a "myelination percentage" (0–100) that represents how deeply
/// a neural pathway has been reinforced through habit repetition.
///
/// Neuroscience background: Myelin is the insulating sheath that forms around
/// nerve fibers through repeated use, speeding up signal transmission. More
/// repetitions + longer streaks = stronger myelination = more automatic habit.
///
/// Formula:
///   base        = completionsCount × 1.5, clamped to [0, 85]
///   streakBonus = streak × 1.5,           clamped to [0, 15]
///   result      = base + streakBonus,      clamped to [0, 100]
///
/// The split (85 base + 15 bonus) means raw volume drives most of the score,
/// but consistent streaks can push it toward 100%.
///
/// Parameters:
///   [completionsCount] — total number of times the habit has been completed
///                        (not deduplicated; every completion counts).
///   [streak]           — the current consecutive-day streak from [calculateStreak].
///
/// Returns:
///   A double in the range [0.0, 100.0] representing myelination percentage.
double calculateMyelination(int completionsCount, int streak) {
  // If the habit has never been completed, myelination is 0 — no pathway yet.
  if (completionsCount == 0) return 0;

  // base score: each completion contributes 1.5 points of myelination.
  // .clamp(0, 85) prevents the base from exceeding 85 (leaving room for the
  // streak bonus). clamp() is a Dart num method: clamp(min, max).
  // .toDouble() converts the result to a decimal number (double) because
  // clamp returns num, and the rest of the function needs double.
  final base = (completionsCount * 1.5).clamp(0, 85).toDouble();

  // Streak bonus: each consecutive day adds 1.5 extra points, up to 15 max.
  // This rewards consistency on top of raw volume.
  final streakBonus = (streak * 1.5).clamp(0, 15).toDouble();

  // Sum base and bonus, then clamp the total to [0, 100] to produce a valid
  // percentage. Even if both components are at their max, the total won't
  // exceed 100.
  return (base + streakBonus).clamp(0, 100);
}

/// Simulates the natural decay of a neurochemical level back toward a
/// baseline value over time.
///
/// Neuroscience background: neurochemicals like dopamine and serotonin do not
/// stay at peak levels indefinitely — they drift back toward a homeostatic
/// baseline. This function models one "tick" of that drift using a simple
/// proportional approach: the level moves a fraction of the way from its
/// current value toward the baseline.
///
/// The formula is an exponential decay step:
///   updated = current + (baseline − current) × rate
///
/// If current < baseline the value rises; if current > baseline it falls.
/// Each call moves it `rate × 100`% of the remaining distance to baseline.
///
/// Parameters:
///   [current]  — the current neurochemical level (any double, typically 0–100).
///   [baseline] — named/optional parameter. The resting level the neurochemical
///                returns to. Defaults to 50. Named parameters are written with
///                curly braces {}: the caller can write decayNeurochemical(x, baseline: 60).
///   [rate]     — named/optional parameter. How fast the decay happens per tick.
///                0.08 means 8% of the gap is closed each tick. Defaults to 0.08.
///
/// Returns:
///   A double rounded to 1 decimal place representing the new neurochemical level.
double decayNeurochemical(double current, {double baseline = 50, double rate = 0.08}) {
  // How far the current level is from the baseline.
  // Positive if current is below baseline; negative if above.
  final difference = baseline - current;

  // Move `rate` fraction of the way toward baseline.
  // e.g. if current=30, baseline=50, rate=0.08:
  //   difference = 20, updated = 30 + 20*0.08 = 31.6
  final updated = current + difference * rate;

  // Round to 1 decimal place to avoid floating-point noise (e.g. 31.600000001).
  // Multiplying by 10, rounding to the nearest integer, then dividing by 10
  // is a standard trick for single-decimal rounding in Dart (which has no
  // built-in "round to N decimals" method on doubles).
  return (updated * 10).round() / 10;
}
