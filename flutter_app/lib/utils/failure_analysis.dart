// =============================================================================
// failure_analysis.dart
//
// What this file is:
//   A pure-logic utility that crunches habit completion data and produces a
//   "FailureSignature" — a snapshot of where, when, and how a user struggles
//   most with their habits.
//
// Role in the app architecture:
//   This file sits in the "utils" layer and contains NO Flutter widgets or UI
//   code. It only reads data (NeuroStack habit objects + ComebackRecord
//   objects) and returns a plain Dart object (FailureSignature) that the UI
//   layer can safely display. The UI calls `analyseFailureSignatures()` and
//   passes in the relevant provider state.
//
// Key concepts a learner needs:
//   • Plain Dart classes  — Dart classes that don't extend any Flutter base
//     class; they are simple containers for data, like a struct in C.
//   • `final` fields      — Fields that can only be set once (immutable after
//     construction). This makes data predictable and safe to share.
//   • `const` constructor — A constructor that can be evaluated at compile
//     time because every value is a constant. Useful for default/empty states.
//   • `List`, `where()`, `map()`, `reduce()` — Dart's built-in collection
//     iteration methods; similar to Array.filter / Array.map / Array.reduce
//     in JavaScript.
//   • `DateTime`          — Dart's built-in type for dates and times.
// =============================================================================

// Brings in the app's shared data model classes (NeuroStack, ComebackRecord,
// etc.). The `..` means "go up one directory", so this is
// flutter_app/lib/models/models.dart.
import '../models/models.dart';

// Brings in helper functions defined in the same utils/ folder, specifically
// `getLocalDateString()` which converts a DateTime into a "YYYY-MM-DD" string
// that matches the format stored in habit completion lists.
import 'neuro_helpers.dart';

// A top-level constant list of abbreviated day names indexed 0–6.
// Index 0 = Sunday, 1 = Monday, … 6 = Saturday.
// This mirrors Dart's DateTime.weekday convention after the `% 7` adjustment
// used later in the analysis (see the "worst day" section below).
const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// =============================================================================
// FailureSignature — the result object produced by analyseFailureSignatures()
// =============================================================================

/// A plain-data class that holds the computed "failure signature" for a user.
///
/// It is returned by [analyseFailureSignatures] and consumed by UI widgets
/// to display personalised insights (e.g., "You miss habits most on Mondays").
///
/// This is a VALUE OBJECT — it carries data but does no computation itself.
/// All fields are `final`, meaning they cannot be changed after the object
/// is created, which prevents accidental mutation elsewhere in the app.
class FailureSignature {
  /// Habit with the highest miss rate over the last 30 days.
  ///
  /// The `?` after `NeuroStack` means this field is NULLABLE — it can hold
  /// either a real NeuroStack object OR the special value `null` (meaning
  /// "no value"). It is null when there is not enough data.
  final NeuroStack? weakestHabit;

  /// The fraction of days (0.0 to 1.0) that the weakest habit was missed.
  /// For example, 0.6 means the habit was skipped on 60 % of days.
  final double weakestHabitMissRate; // 0–1

  /// Day of week (e.g. "Mon") that accumulates the most misses across all habits.
  /// Nullable — null when there is not enough data to identify a worst day.
  final String? worstDayOfWeek;

  /// The raw count of misses on the worst day of the week in the analysis window.
  final int worstDayMissCount;

  /// The habit the user recovers from (gets back on track after missing) fastest.
  /// Nullable — null when no comeback records exist yet.
  final NeuroStack? fastestRecoveryHabit;

  /// Average number of days it takes the fastest-recovery habit to be completed
  /// again after a miss. Lower is better (faster bounce-back).
  final double fastestRecoveryDays; // avg days

  /// Overall average days from any miss to next completion, across ALL habits.
  final double avgRecoveryDays;

  /// A quality-gate flag. True only when there is at least one habit with
  /// 14 or more days of history, ensuring the statistics are meaningful.
  /// The UI should check this before displaying insights.
  final bool hasEnoughData;

  /// `const` constructor — all parameters are optional and have sensible
  /// defaults (mostly 0 / null / false). Using `const` allows Flutter to
  /// reuse the same object instance when no data is available, saving memory.
  ///
  /// The `{...}` syntax means these are NAMED parameters: you pass them by
  /// name, e.g. `FailureSignature(hasEnoughData: true)`, which is much more
  /// readable than positional parameters for objects with many fields.
  const FailureSignature({
    this.weakestHabit,           // defaults to null
    this.weakestHabitMissRate = 0,
    this.worstDayOfWeek,         // defaults to null
    this.worstDayMissCount = 0,
    this.fastestRecoveryHabit,   // defaults to null
    this.fastestRecoveryDays = 0,
    this.avgRecoveryDays = 0,
    this.hasEnoughData = false,
  });
}

// =============================================================================
// analyseFailureSignatures() — the main analysis function
// =============================================================================

/// Analyses habit completion history and comeback records to identify
/// patterns in where and when the user tends to fail or struggle.
///
/// Parameters:
///   [stacks]    — The full list of the user's NeuroStack habit objects.
///                 Each NeuroStack contains a list of completion date strings.
///   [comebacks] — Records of when the user broke a streak and came back.
///                 Used to measure recovery speed.
///
/// Returns a [FailureSignature] containing:
///   • The habit with the highest miss rate (weakest habit)
///   • The day of the week with the most misses (worst day)
///   • The habit the user recovers from fastest (fastest recovery habit)
///   • Average recovery time across all habits
///
/// If there is not enough historical data (< 14 days for any habit),
/// an empty [FailureSignature] with `hasEnoughData: false` is returned.
FailureSignature analyseFailureSignatures(
  List<NeuroStack> stacks,       // all habit stacks from app state
  List<ComebackRecord> comebacks, // all comeback records from app state
) {
  // ── Step 1: Filter to only active (not archived) habits ────────────────────
  // `.where()` is like Array.filter in JS — it keeps only items where the
  // callback returns true. `.toList()` converts the lazy result back to a
  // concrete List so we can iterate it multiple times.
  final active = stacks.where((s) => s.isActive).toList();

  // If there are no active habits at all, return an empty result immediately.
  // `const FailureSignature()` uses the default constructor values (all zeros
  // and nulls, hasEnoughData = false).
  if (active.isEmpty) return const FailureSignature();

  // Capture the current date/time once so all comparisons use the same instant.
  final today = DateTime.now();

  // Convert today's DateTime to the "YYYY-MM-DD" string format used throughout
  // the app (e.g. "2026-05-29"). Defined in neuro_helpers.dart.
  // Note: `todayStr` is declared but used implicitly via the loop below; it
  // represents the boundary for "today" in date arithmetic.
  final todayStr = getLocalDateString(today);

  // ── Step 2: Filter to "matured" habits (≥ 14 days old) ────────────────────
  // We need at least 14 days of history to draw statistically meaningful
  // conclusions. Habits newer than that are excluded from analysis.
  final matured = active.where((s) {
    // `DateTime.tryParse()` attempts to convert a date string to a DateTime.
    // It returns null if the string is not a valid date, rather than throwing
    // an exception. The `?` in the type annotation allows it to be null.
    final created = DateTime.tryParse(s.createdAt);

    // If the date couldn't be parsed, exclude this habit from analysis.
    if (created == null) return false;

    // `.difference()` returns a Duration object representing the time between
    // two DateTimes. `.inDays` extracts that duration as a whole number of days.
    return today.difference(created).inDays >= 14;
  }).toList();

  // Return early if no habit has 14+ days of history yet.
  if (matured.isEmpty) return const FailureSignature();

  // ── Step 3: Find the weakest habit (highest miss rate over 30 days) ────────

  // Will hold the habit we identify as weakest; starts as null.
  NeuroStack? weakestHabit;

  // Tracks the highest miss rate seen so far. Starts at -1 so ANY real miss
  // rate (which is ≥ 0) will be larger and trigger the first update.
  double worstMissRate = -1;

  // Loop through every matured habit to calculate its individual miss rate.
  for (final stack in matured) {
    // Parse the creation date (we already know it's valid from the filter above,
    // so we use `DateTime.parse()` which throws on invalid input rather than
    // the safer `tryParse()`).
    final created = DateTime.parse(stack.createdAt);

    // Look back at most 30 days, but no further than when the habit was created.
    // `.clamp(1, 30)` ensures the value stays between 1 and 30 inclusive —
    // avoids dividing by zero if somehow the habit is 0 days old.
    final windowDays = today.difference(created).inDays.clamp(1, 30);

    // Count how many days in the window were missed (no completion recorded).
    int misses = 0;
    for (int i = 1; i <= windowDays; i++) {
      // `today.subtract(Duration(days: i))` goes back `i` days from today.
      // e.g. i=1 → yesterday, i=2 → two days ago, etc.
      final d = getLocalDateString(today.subtract(Duration(days: i)));

      // `stack.completions` is a list of "YYYY-MM-DD" strings for days the
      // user completed this habit. If the date is NOT in that list, it's a miss.
      if (!stack.completions.contains(d)) misses++;
    }

    // Miss rate = missed days / total days in window. Gives a 0–1 fraction.
    final rate = misses / windowDays;

    // If this habit's miss rate is higher than the current worst, update.
    if (rate > worstMissRate) {
      worstMissRate = rate;
      weakestHabit = stack;
    }
  }

  // ── Step 4: Find the worst day of the week ─────────────────────────────────

  // A list of 7 integers (one per day of the week), all starting at 0.
  // Index mapping: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat.
  // `List<int>.filled(7, 0)` creates [0, 0, 0, 0, 0, 0, 0].
  final dayCounts = List<int>.filled(7, 0);

  for (final stack in matured) {
    final created = DateTime.parse(stack.createdAt);

    // Look at each of the last 30 days.
    for (int i = 1; i <= 30; i++) {
      final d = today.subtract(Duration(days: i)); // the actual DateTime object
      final dStr = getLocalDateString(d);           // "YYYY-MM-DD" string version

      // Skip days before this habit even existed (can't miss something not started).
      if (d.isBefore(created)) continue;

      // If this day has no completion recorded, tally it as a miss for that weekday.
      if (!stack.completions.contains(dStr)) {
        // `d.weekday` returns 1 (Mon) through 7 (Sun) in Dart's DateTime.
        // `% 7` converts Sunday (7) → 0, and shifts Mon–Sat to 1–6,
        // matching the _dayNames array layout where index 0 = Sun.
        dayCounts[d.weekday % 7]++;
      }
    }
  }

  // Find the index (0–6) with the highest miss count.
  // Start by assuming index 0 (Sunday) is the worst, then compare the rest.
  int worstDay = 0;
  for (int i = 1; i < 7; i++) {
    // If day `i` has more misses than the current worst, update worstDay.
    if (dayCounts[i] > dayCounts[worstDay]) worstDay = i;
  }

  // ── Step 5: Calculate recovery speed per habit ─────────────────────────────

  // Will hold the habit with the fastest (lowest average) recovery time.
  NeuroStack? fastestHabit;

  // `double.infinity` is a special Dart constant meaning "infinitely large".
  // Using it as the initial value means any real recovery time will be smaller,
  // triggering the first update correctly.
  double fastestAvg = double.infinity;

  // Accumulates all recovery durations (in days) across all habits, used to
  // compute the overall average at the end.
  final allRecoveries = <int>[];

  for (final stack in matured) {
    // Get only the comeback records that belong to this specific habit.
    // `.where()` filters by matching stackId. `.toList()` materialises the result.
    final stackComebacks = comebacks.where((c) => c.stackId == stack.id).toList();

    // Skip habits that have no comeback records — nothing to measure.
    if (stackComebacks.isEmpty) continue;

    // Convert the completions list to a Set for O(1) lookup performance.
    // A Set has no duplicate entries and checking `.contains()` on a Set is
    // much faster than on a List for large collections.
    final completions = stack.completions.toSet();

    // Will hold the recovery duration (days) for each comeback event for this habit.
    final recoveries = <int>[];

    for (final cb in stackComebacks) {
      // Parse the date of the comeback (when the streak was broken).
      final cbDate = DateTime.parse(cb.date);

      // Look forward up to 7 days after the comeback to find the next completion.
      for (int d = 1; d <= 7; d++) {
        // `cbDate.add(Duration(days: d))` moves forward d days from the comeback date.
        final next = getLocalDateString(cbDate.add(Duration(days: d)));

        // If the user completed the habit on this future day, record the recovery time.
        if (completions.contains(next)) {
          recoveries.add(d);       // record how many days it took for THIS habit
          allRecoveries.add(d);    // also add to the global pool for overall avg

          // `break` exits the inner for-loop immediately — we only want the FIRST
          // completion after the comeback, not all subsequent ones.
          break;
        }
      }
    }

    // Only update the "fastest" tracker if this habit actually had recoveries.
    if (recoveries.isNotEmpty) {
      // `.reduce((a, b) => a + b)` sums all values in the list.
      // e.g. [1, 3, 2].reduce((a, b) => a + b) → 6
      // Dividing by length gives the mean (average).
      final avg = recoveries.reduce((a, b) => a + b) / recoveries.length;

      // If this habit's average recovery is faster (lower) than the current
      // best, update the tracker.
      if (avg < fastestAvg) {
        fastestAvg = avg;
        fastestHabit = stack;
      }
    }
  }

  // ── Step 6: Compute the overall average recovery time ──────────────────────

  // If no recoveries were recorded at all, default to 0.0 to avoid dividing
  // by zero. The ternary `condition ? valueIfTrue : valueIfFalse` is Dart's
  // inline if-else expression.
  final avgRecovery = allRecoveries.isEmpty
      ? 0.0
      : allRecoveries.reduce((a, b) => a + b) / allRecoveries.length;

  // ── Step 7: Build and return the result object ─────────────────────────────

  return FailureSignature(
    weakestHabit: weakestHabit,

    // `.clamp(0, 1)` ensures the rate stays within [0, 1] even if floating-
    // point arithmetic produces a value like 1.0000000001.
    weakestHabitMissRate: worstMissRate.clamp(0, 1),

    // Look up the abbreviated day name using the worst-day index (e.g. 1 → "Mon").
    worstDayOfWeek: _dayNames[worstDay],

    // The raw count of misses on that worst day.
    worstDayMissCount: dayCounts[worstDay],

    fastestRecoveryHabit: fastestHabit,

    // If fastestAvg is still `double.infinity` (no recoveries found at all),
    // report 0 instead of infinity, which would crash the UI.
    fastestRecoveryDays: fastestAvg == double.infinity ? 0 : fastestAvg,

    avgRecoveryDays: avgRecovery,

    // We reached this point, so at least one habit had ≥14 days of data.
    hasEnoughData: true,
  );
}
