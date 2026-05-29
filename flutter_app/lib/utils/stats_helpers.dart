// =============================================================================
// stats_helpers.dart
//
// What this file is:
//   A collection of pure utility functions and one data class that compute all
//   the statistical metrics shown on the Stats screen of the NeuroSync app.
//
// Role in the app architecture:
//   - These are "pure" functions — they receive data in, return data out, and
//     have no side effects (they never update state or call the database).
//   - They are called by Riverpod providers (in providers/) and by screen
//     widgets (in screens/stats_screen.dart) to derive display values.
//   - They depend on the data models defined in models/models.dart and on the
//     date-formatting helper in utils/neuro_helpers.dart.
//
// Key concepts a learner needs:
//   - Dart collections: List, Set, Map — and their chainable methods like
//     .where(), .map(), .reduce(), .fold(), .sort(), .toSet(), .toList().
//   - DateTime arithmetic: subtracting Durations, calling .difference(),
//     parsing ISO strings with DateTime.parse().
//   - The ??, ?., and ternary (condition ? a : b) operators in Dart.
//   - "Pure functions": functions with no side effects — same input always
//     produces the same output. They are easy to test and reason about.
// =============================================================================

// Brings in our app's data model classes: NeuroStack, ComebackRecord,
// NeuroSwap, Neurochemistry, NeuroSwap, etc.
import '../models/models.dart';

// Brings in getLocalDateString() — a helper that formats a DateTime into a
// 'YYYY-MM-DD' string using the device's local timezone (not UTC). We use
// this everywhere dates are stored and compared.
import 'neuro_helpers.dart';

// =============================================================================
// WeekDay — a simple data container (a "plain data class") that holds all the
// information needed to render a single cell in the 7-day habit-grid widget.
// It is NOT a Flutter widget — it is just a Dart class used to bundle related
// data together so functions can return it cleanly.
// =============================================================================

/// Represents the state of one calendar day in the 7-day habit streak grid.
///
/// Each [WeekDay] object is created by [getWeekGrid] and is consumed by the
/// HabitCard widget to decide what colour/icon to show for that day.
class WeekDay {
  /// The date formatted as 'YYYY-MM-DD', e.g. '2026-05-29'.
  /// Used as a lookup key when matching against completions and comebacks.
  final String dateStr;

  /// The short weekday label shown in the UI, e.g. 'Mon', 'Tue'.
  final String label;

  /// True if the user logged this habit as done on this date.
  final bool completed;

  /// True if this date has a Comeback Protocol entry — the user missed the
  /// habit but then triggered the comeback flow for it on that day.
  final bool comeback;

  /// True if the habit was not completed, not a comeback, not in the future,
  /// and not before the habit was created — i.e. a genuine miss.
  final bool missed;

  /// True if this day's date equals today's local date.
  final bool isToday;

  /// True if this day's date is still in the future (can't have completed it yet).
  final bool isFuture;

  // The 'const' keyword here means this constructor can be evaluated at
  // compile time when all arguments are constants — a minor performance hint.
  // 'required' means the caller MUST supply this argument; there is no default.
  const WeekDay({
    required this.dateStr,
    required this.label,
    required this.completed,
    required this.comeback,
    required this.missed,
    required this.isToday,
    required this.isFuture,
  });
}

// =============================================================================
// getWeekGrid
//
// Builds the list of 7 WeekDay objects that power the small calendar row
// shown on each HabitCard. The list always covers today and the 6 days
// immediately before it (oldest first).
// =============================================================================

/// Returns the last 7 days as [WeekDay] objects for the given [stack].
///
/// Parameters:
///   [stack]     — the habit (NeuroStack) whose completion history we inspect.
///   [comebacks] — all ComebackRecord entries in the app (we filter by stackId
///                 inside the function).
///
/// Returns a [List<WeekDay>] with exactly 7 elements, index 0 = 6 days ago,
/// index 6 = today.
List<WeekDay> getWeekGrid(NeuroStack stack, List<ComebackRecord> comebacks) {
  // Short labels used to display which day of the week each cell falls on.
  // Index 0 = Sunday because Dart's DateTime.weekday returns 1=Mon…7=Sun,
  // and we use `d.weekday % 7` below to map Sunday (7) to index 0.
  const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Extract just the date portion 'YYYY-MM-DD' from the habit's ISO timestamp.
  // substring(0, 10) slices the first 10 characters of the string.
  final createdDate = stack.createdAt.substring(0, 10);

  // Today's date as a 'YYYY-MM-DD' string in the user's local timezone.
  final today = getLocalDateString(DateTime.now());

  // Start with an empty list; we'll fill it in the loop below.
  final days = <WeekDay>[];

  // Loop from i=6 down to i=0 so the oldest day is added first.
  // DateTime.now().subtract(Duration(days: i)) counts back i days from today.
  for (int i = 6; i >= 0; i--) {
    final d = DateTime.now().subtract(Duration(days: i)); // compute the target date
    final dateStr = getLocalDateString(d); // format it as 'YYYY-MM-DD'

    // d.weekday returns 1 (Monday) through 7 (Sunday).
    // % 7 maps Sunday's 7 → 0, so it aligns with our dayLabels array above.
    final label = dayLabels[d.weekday % 7];

    // stack.completions is a List<String> of 'YYYY-MM-DD' dates when the user
    // tapped "done". .contains() returns true if dateStr is in that list.
    final completed = stack.completions.contains(dateStr);

    // .any() returns true if at least one element in the list satisfies the
    // test. Here: is there a comeback record for this stack on this date?
    final comeback = comebacks.any((c) => c.stackId == stack.id && c.date == dateStr);

    // String.compareTo() works lexicographically (alphabetically). Because our
    // dates are in 'YYYY-MM-DD' format, alphabetical order == chronological
    // order. compareTo > 0 means dateStr comes after today → it's a future day.
    final isFuture = dateStr.compareTo(today) > 0;

    // Days before the habit was created can't be "missed" — the habit didn't
    // exist yet, so we exclude them from the missed calculation.
    final isBeforeCreation = dateStr.compareTo(createdDate) < 0;

    // A day is a "miss" only if ALL of these are true:
    //   - the habit was not completed on that day
    //   - there is no comeback record for that day
    //   - it is not a future date
    //   - it is not before the habit was created
    final missed = !completed && !comeback && !isFuture && !isBeforeCreation;

    final isToday = dateStr == today; // simple equality check for today

    // Add a new WeekDay object to the list with all computed flags.
    days.add(WeekDay(
      dateStr: dateStr,
      label: label,
      completed: completed,
      comeback: comeback,
      missed: missed,
      isToday: isToday,
      isFuture: isFuture,
    ));
  }

  return days; // the caller gets a list of exactly 7 WeekDay objects
}

// =============================================================================
// calcRecoveryRate
//
// What fraction of comeback attempts were "fully" completed (i.e. the user
// also finished the micro-actions checklist)?  Returns a 0–100 percentage.
// =============================================================================

/// Calculates the recovery rate as a percentage (0–100).
///
/// The recovery rate = (comebacks where micro-actions were completed) /
///                     (total comebacks) × 100.
///
/// Parameters:
///   [comebacks] — all ComebackRecord entries to analyse.
///
/// Returns 0.0 when there are no comeback records (avoids division by zero).
double calcRecoveryRate(List<ComebackRecord> comebacks) {
  // Guard clause: if the list is empty, return early to avoid dividing by zero.
  if (comebacks.isEmpty) return 0;

  // .where() filters the list, keeping only elements where the condition is
  // true. .length counts how many elements remain after filtering.
  final completed = comebacks.where((c) => c.microActionsCompleted).length;

  // Divide, multiply by 100 to turn a ratio into a percentage, then call
  // .roundToDouble() to snap to the nearest whole number but keep type double.
  return (completed / comebacks.length * 100).roundToDouble();
}

// =============================================================================
// calcBrainScore
//
// A composite 0–100 score that summarises overall habit health. Displayed as
// the headline number on the Stats screen. Weighted average of three factors:
//   40% — average myelination level across active habits
//   30% — comeback recovery rate
//   30% — average neurochemistry balance (dopamine, acetylcholine, GABA, and
//           inverted epinephrine because high epinephrine = high stress)
// =============================================================================

/// Computes the composite "Brain Score" (0–100) for the user.
///
/// Parameters:
///   [stacks]         — all habit stacks; inactive ones are excluded.
///   [comebacks]      — all comeback records, passed to [calcRecoveryRate].
///   [neurochemistry] — current neurochemical balance snapshot.
///
/// Returns an integer clamped to [0, 100].
int calcBrainScore(
  List<NeuroStack> stacks,
  List<ComebackRecord> comebacks,
  Neurochemistry neurochemistry,
) {
  // Filter to only habits the user has not archived/deactivated.
  final active = stacks.where((s) => s.isActive).toList();

  // If there are no active habits, there is nothing to score.
  if (active.isEmpty) return 0;

  // .map() transforms each element; here we extract the myelinationLevel int.
  // .reduce((a, b) => a + b) sums all values by repeatedly adding pairs.
  // Dividing by active.length gives the arithmetic mean.
  final avgMyelination = active.map((s) => s.myelinationLevel).reduce((a, b) => a + b) / active.length;

  // Reuse our already-defined recovery rate function.
  final recoveryRate = calcRecoveryRate(comebacks);

  // Build a 0–100 chemistry balance score. Epinephrine (adrenaline/stress) is
  // inverted — (100 - epinephrine) — because lower stress = better brain health.
  // We average the four values to get a single 0–100 number.
  final chemAvg = (neurochemistry.dopamine +
          neurochemistry.acetylcholine +
          neurochemistry.gaba +
          (100 - neurochemistry.epinephrine)) /
      4;

  // Weighted sum: myelination counts 40%, recovery 30%, chemistry 30%.
  // .round() converts the double result to the nearest integer.
  final score = (avgMyelination * 0.4 + recoveryRate * 0.3 + chemAvg * 0.3).round();

  // .clamp(min, max) ensures the result never goes below 0 or above 100,
  // regardless of any floating-point drift in the inputs.
  return score.clamp(0, 100);
}

// =============================================================================
// getBestStreak
//
// Finds the single highest current streak across all habits, shown as the
// "Best Streak" badge on the Stats screen.
// =============================================================================

/// Returns the highest streak value among all provided [stacks].
///
/// Parameters:
///   [stacks] — all habit stacks to compare.
///
/// Returns 0 when the list is empty.
int getBestStreak(List<NeuroStack> stacks) {
  if (stacks.isEmpty) return 0;

  // .map() extracts each stack's streak integer into a new iterable.
  // .reduce() picks the larger of each pair (a > b ? a : b) until one winner
  // remains — this is equivalent to finding the maximum value.
  return stacks.map((s) => s.streak).reduce((a, b) => a > b ? a : b);
}

// =============================================================================
// getDaysInSystem
//
// How many days ago did the user create their very first habit? This is the
// "Days in System" counter — a simple measure of overall commitment length.
// =============================================================================

/// Returns how many days ago the earliest habit was created.
///
/// Parameters:
///   [stacks] — all habit stacks; we look at their [createdAt] timestamps.
///
/// Returns a minimum of 1 (so "Day 0" never appears) and is uncapped above.
int getDaysInSystem(List<NeuroStack> stacks) {
  if (stacks.isEmpty) return 0;

  // .map() extracts the createdAt ISO string from each stack.
  // .reduce() keeps whichever string is alphabetically earlier — because
  // 'YYYY-MM-DD...' strings sort chronologically, the smallest is the oldest.
  final earliest = stacks.map((s) => s.createdAt).reduce((a, b) => a.compareTo(b) < 0 ? a : b);

  // DateTime.parse() converts the ISO string back to a DateTime object.
  // .difference() returns a Duration representing the gap between two DateTimes.
  final diffMs = DateTime.now().difference(DateTime.parse(earliest));

  // .inDays extracts the whole-day count from the Duration.
  // .clamp(1, 99999) ensures we show at least "1 day" and cap at a
  // reasonable display ceiling.
  return diffMs.inDays.clamp(1, 99999);
}

// =============================================================================
// getComebacksThisMonth
//
// Counts how many comeback records fall within the current calendar month.
// Displayed as a monthly engagement metric on the Stats screen.
// =============================================================================

/// Counts comeback records whose date falls in the current calendar month.
///
/// Parameters:
///   [comebacks] — all comeback records to filter.
///
/// Returns an integer count (0 if none this month).
int getComebacksThisMonth(List<ComebackRecord> comebacks) {
  final now = DateTime.now();

  // Build a 'YYYY-MM' prefix string, e.g. '2026-05'.
  // .toString().padLeft(2, '0') ensures single-digit months like 5 → '05'.
  final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  // .where() keeps only records whose date string starts with this month prefix.
  // .length counts the matching records.
  return comebacks.where((c) => c.date.startsWith(monthStr)).length;
}

/// Consecutive days the Comeback Protocol fired — our core differentiator metric.
///
/// A "comeback streak" is a run of consecutive calendar days on which the user
/// triggered at least one comeback. This measures consistency in recovery
/// behaviour, not habit completion.
///
/// Parameters:
///   [comebacks] — all comeback records across all habits.
///
/// Returns the length of the most recent consecutive-day streak (0 if none).
int getComebackStreak(List<ComebackRecord> comebacks) {
  if (comebacks.isEmpty) return 0;

  // Deduplicate to one entry per day, sorted descending (newest first).
  // .map((c) => c.date) extracts just the date strings.
  // .toSet() removes duplicates (multiple comebacks on the same day become one).
  // .toList() converts the Set back to a List so we can sort it.
  // ..sort() is Dart's "cascade" operator — it calls sort() on the list and
  //   returns the same list (not the void result of sort). This lets us chain
  //   it inline. The comparator (a, b) => b.compareTo(a) sorts descending.
  final dates = comebacks.map((c) => c.date).toSet().toList()
    ..sort((a, b) => b.compareTo(a));

  int streak = 1; // we always have at least the most recent date

  // Walk through the sorted dates, comparing each adjacent pair.
  for (int i = 1; i < dates.length; i++) {
    final prev = DateTime.parse(dates[i - 1]); // the more-recent date
    final curr = DateTime.parse(dates[i]);      // the older date

    // If the two dates are exactly 1 day apart, the streak is unbroken.
    if (prev.difference(curr).inDays == 1) {
      streak++; // extend the streak
    } else {
      // Gap found — stop counting. We only care about the MOST RECENT streak.
      break;
    }
  }

  return streak;
}

/// Average days from a miss to the next completion — "recovery speed".
/// Lower is better. Returns 0 when no data exists.
///
/// For each active habit, we look at every comeback record and then scan the
/// following 7 days to find the first completion date. The gap in days is the
/// recovery time for that comeback. We average all gaps found.
///
/// Parameters:
///   [stacks]    — all habit stacks; only active ones are analysed.
///   [comebacks] — all comeback records; filtered per-stack inside.
///
/// Returns a double (e.g. 2.5 = "on average 2.5 days to get back on track").
double getAvgRecoveryDays(List<NeuroStack> stacks, List<ComebackRecord> comebacks) {
  // We'll collect individual recovery-day counts here, then average them.
  final recoveries = <int>[];

  // Only look at habits the user is actively tracking.
  for (final stack in stacks.where((s) => s.isActive)) {
    // Convert the completions list to a Set for O(1) lookup (sets use hashing).
    final completions = stack.completions.toSet();

    // Filter comebacks to only those belonging to this specific habit.
    final stackComebacks = comebacks.where((c) => c.stackId == stack.id).toList();

    for (final cb in stackComebacks) {
      final cbDate = DateTime.parse(cb.date); // parse the comeback date

      // Check each of the next 7 days to see if the user completed the habit.
      for (int d = 1; d <= 7; d++) {
        // cbDate.add(Duration(days: d)) moves d days into the future.
        final next = getLocalDateString(cbDate.add(Duration(days: d)));

        if (completions.contains(next)) {
          recoveries.add(d); // record how many days it took to recover
          break; // stop looking further — we found the first post-comeback completion
        }
      }
    }
  }

  if (recoveries.isEmpty) return 0; // no recovery data yet

  // Sum all recovery day counts with .reduce(), then divide by count → mean.
  return recoveries.reduce((a, b) => a + b) / recoveries.length;
}

// =============================================================================
// getRecoveryInsights
//
// Generates up to 3 human-readable insight strings displayed in the "Insights"
// card on the Stats screen. Each insight is context-dependent — it only
// appears if the relevant data condition is met.
// =============================================================================

/// Returns up to 3 personalised insight strings based on the user's data.
///
/// Parameters:
///   [stacks]    — all habit stacks; used to find the strongest habit.
///   [comebacks] — all comeback records; used to analyse recovery behaviour.
///   [swaps]     — all NeuroSwap records; used to assess urge-surfing success.
///
/// Returns a [List<String>] with 0–3 elements (never more than 3).
List<String> getRecoveryInsights(
  List<NeuroStack> stacks,
  List<ComebackRecord> comebacks,
  List<NeuroSwap> swaps,
) {
  // Collect insight strings as we discover them.
  final insights = <String>[];

  // --- Insight 1: Strongest habit by streak ---
  // [...stacks.where(...)] is the "spread" operator — it creates a NEW list
  // from the filtered iterable. We need a new list because .sort() mutates
  // in place and we don't want to change the original stacks list.
  final strongest = [...stacks.where((s) => s.isActive)]
    ..sort((a, b) => b.streak.compareTo(a.streak)); // sort descending by streak

  // Only add this insight if at least one active habit has a streak > 0.
  if (strongest.isNotEmpty && strongest.first.streak > 0) {
    final s = strongest.first; // the habit with the highest streak
    insights.add('"${s.title}" is your most consistent habit — ${s.streak}-day streak.');
  }

  // --- Insight 2: Comeback completion rate message ---
  // Only meaningful once there are at least 2 data points.
  if (comebacks.length >= 2) {
    // Count how many comebacks had micro-actions completed.
    final withActions = comebacks.where((c) => c.microActionsCompleted).length;

    // Calculate percentage and round to nearest whole number.
    final pct = (withActions / comebacks.length * 100).round();

    if (pct >= 70) {
      // Strong performer — celebrate their discipline.
      insights.add('You complete re-entry actions $pct% of the time. That\'s strong recovery discipline.');
    } else if (pct > 0) {
      // Some comebacks but not completing micro-actions — give a gentle nudge.
      // The ternary `comebacks.length > 1 ? 's' : ''` appends an 's' for
      // plural or nothing for singular — "1 comeback" vs "2 comebacks".
      insights.add('You\'ve acknowledged ${comebacks.length} comeback${comebacks.length > 1 ? 's' : ''}. Completing micro-actions increases long-term retention.');
    }
  }

  // --- Insight 3: Urge surfing vs slips comparison ---
  // .fold<int>(0, (n, s) => n + s.slips.length) starts at 0 and accumulates
  // the total number of slips across all NeuroSwap records.
  // fold is like reduce but lets you set a starting value (0 here).
  final totalSlips = swaps.fold<int>(0, (n, s) => n + s.slips.length);
  final totalUrges = swaps.fold<int>(0, (n, s) => n + s.urgeSurfingCompletions.length);

  // Only show this if urges were surfed AND urges outnumber slips.
  if (totalUrges > 0 && totalSlips < totalUrges) {
    // Again, ternary operator to handle plural/singular grammar correctly.
    insights.add('You\'ve resisted $totalUrges urge${totalUrges > 1 ? 's' : ''} vs $totalSlips slip${totalSlips != 1 ? 's' : ''}. Your friction system is working.');
  }

  // --- Insight 4: Habit count guidance ---
  final active = stacks.where((s) => s.isActive).length;

  if (active == 0) {
    // No habits yet — prompt them to start.
    insights.add('Add your first habit to start building your recovery playbook.');
  } else if (active >= 4) {
    // Research suggests habit overload degrades adherence — warn them gently.
    insights.add('$active active habits is on the high end — consider pausing the weakest one to protect your strongest streaks.');
  }

  // .take(3) returns at most the first 3 elements of the list,
  // then .toList() materialises them into a concrete List<String>.
  return insights.take(3).toList();
}
