// =============================================================================
// comeback_helpers.dart
//
// What this file is: A collection of pure utility functions and data used to
// power the "comeback" flow — the UI that appears when a user has missed one or
// more days of a habit and needs encouragement to re-engage.
//
// Role in the app architecture:
//   - This file has NO Flutter widgets. It is a "logic-only" helper module.
//   - It is imported by screens/widgets that display missed-habit prompts, such
//     as the comeback card or the home screen streak section.
//   - It depends on: models/models.dart (for NeuroStack data shapes) and
//     neuro_helpers.dart (for the date-formatting utility).
//   - Nothing in this file talks to the internet, a database, or state
//     management — it only transforms data that is passed into it.
//
// Key concepts a learner needs to know:
//   - Pure functions: Functions that receive inputs, return outputs, and do not
//     change anything outside themselves. All functions here are pure.
//   - List<T>: A typed list in Dart. List<NeuroStack> means "a list where every
//     item is a NeuroStack object".
//   - .where(): A Dart method that filters a list, keeping only items where the
//     test function returns true. Similar to Array.filter() in JavaScript.
//   - .toList(): Converts an Iterable (a lazy sequence) into an actual List in
//     memory so it can be stored or passed around.
//   - const: In Dart, `const` means the value is known at compile time and will
//     never change. It is more efficient than `final` because the Dart compiler
//     can share a single instance.
// =============================================================================

// Brings in the app's data models — specifically the `NeuroStack` class, which
// represents a single habit and all its stored data (id, completions list, etc.).
import '../models/models.dart';

// Brings in shared neuroscience/date helper utilities. We use `getLocalDateString`
// from here to convert DateTime objects into consistent "YYYY-MM-DD" strings.
import 'neuro_helpers.dart';

/// Returns a filtered list of [NeuroStack] habits that the user missed yesterday
/// and has not yet completed today, excluding habits the user already dismissed
/// (acknowledged) in today's session.
///
/// Parameters:
///   - [stacks]: The full list of all the user's habits.
///   - [acknowledgedTodayIds]: A list of habit IDs the user already tapped
///     "I'll come back" or "dismiss" on today — we skip those so they are not
///     shown again in the same session.
///
/// Returns: A new List<NeuroStack> containing only habits that qualify as
/// "missed and needing a comeback nudge."
List<NeuroStack> getMissedStacks(
  List<NeuroStack> stacks,
  List<String> acknowledgedTodayIds,
) {
  // Build a "YYYY-MM-DD" string for yesterday by subtracting 1 day from now.
  // `DateTime.now()` returns the current local time.
  // `.subtract(const Duration(days: 1))` shifts it back by exactly 24 hours.
  // `getLocalDateString(...)` formats the DateTime as "YYYY-MM-DD".
  final yesterday = getLocalDateString(DateTime.now().subtract(const Duration(days: 1)));

  // Build the same "YYYY-MM-DD" string for today — used to check if the user
  // has already completed the habit today (in which case no nudge is needed).
  final today = getLocalDateString(DateTime.now());

  // `.where((stack) { ... })` iterates every habit and keeps only those where
  // the function body returns `true`. Think of it as a filter.
  return stacks.where((stack) {
    // Guard: skip habits that are archived (not active) or have never been
    // completed at all — there is nothing to "come back to" yet.
    if (!stack.isActive || stack.completions.isEmpty) return false;

    // Guard: if the user already acknowledged this habit's missed-day banner
    // earlier today, skip it so we don't keep nagging them.
    if (acknowledgedTodayIds.contains(stack.id)) return false;

    // `stack.completions` is a List<String> of "YYYY-MM-DD" completion dates.
    // `.contains(yesterday)` is true if the habit was completed yesterday.
    // We negate it with `!` so `missedYesterday` is true when it was NOT done.
    final missedYesterday = !stack.completions.contains(yesterday);

    // Same logic for today: `notCompletedToday` is true when today is absent
    // from the completions list, meaning the habit hasn't been done yet today.
    final notCompletedToday = !stack.completions.contains(today);

    // Only return true (keep this habit) if BOTH conditions are true:
    // the user missed it yesterday AND hasn't done it yet today.
    return missedYesterday && notCompletedToday;

  // `.toList()` forces the lazy `.where()` result into a concrete List so the
  // caller can index into it, measure its length, etc.
  }).toList();
}

/// Calculates how many calendar days have passed since the user last completed
/// a given habit. Used to select the right reframe message tone.
///
/// Parameters:
///   - [stack]: The habit whose completion history we will inspect.
///
/// Returns: An integer — the number of days since the last completion.
///   Always at least 1 (clamped), and capped at 999 to avoid edge cases.
int getDaysMissed(NeuroStack stack) {
  // If the habit has never been completed, there is no "last completion" to
  // measure from, so we return 0 as a safe sentinel value.
  if (stack.completions.isEmpty) return 0;

  // `[...stack.completions]` creates a new copy of the list using the spread
  // operator (`...`). We copy it so that the `..sort(...)` below does not
  // mutate (change) the original list stored in the habit object.
  //
  // `..sort((a, b) => b.compareTo(a))` is the "cascade" operator in Dart.
  // It calls `.sort()` on the new list AND returns the list itself.
  // `b.compareTo(a)` sorts in descending order (newest date first) because
  // our dates are "YYYY-MM-DD" strings which sort lexicographically correctly.
  final sorted = [...stack.completions]..sort((a, b) => b.compareTo(a));

  // `sorted.first` is the newest (most recent) date string, e.g. "2025-05-27".
  // We append "T00:00:00" to make it a valid ISO 8601 datetime string so that
  // `DateTime.parse(...)` can parse it into a DateTime object at midnight.
  final lastCompletion = DateTime.parse('${sorted.first}T00:00:00');

  // Get the current local date and time.
  final today = DateTime.now();

  // Strip the time portion so we compare whole calendar days, not hours.
  // `DateTime(year, month, day)` creates a DateTime at midnight on that date.
  final todayMidnight = DateTime(today.year, today.month, today.day);

  // `.difference(other)` returns a Duration representing the gap between two
  // DateTime values. `todayMidnight - lastCompletion` gives us the elapsed time.
  final diff = todayMidnight.difference(lastCompletion);

  // `.inDays` extracts the whole-number days from the Duration.
  // `.clamp(1, 999)` ensures the result is never below 1 (so we always show at
  // least a "1 day missed" message) and never absurdly large.
  return diff.inDays.clamp(1, 999);
}

/// A simple data container (a "value object") that holds one motivational
/// reframe message shown to the user when they are coming back to a missed habit.
///
/// This is a plain Dart class — not a Flutter widget. It only stores data.
/// `const` constructors allow Dart to create these objects at compile time,
/// which is very efficient since the message content never changes at runtime.
class ReframeMessage {
  /// The short, bold headline text displayed prominently in the UI.
  final String headline;

  /// The longer explanatory body text that provides neuroscience context.
  final String body;

  /// `const` constructor: all fields must be supplied and are immutable.
  /// `required` means the caller MUST pass both `headline` and `body` —
  /// Dart will show a compile error if either is missing.
  const ReframeMessage({required this.headline, required this.body});
}

// A private list (the leading `_` makes it private to this file) of four
// reframe messages ordered from "1 day missed" to "many days missed".
// `const` here means the entire list is a compile-time constant — very efficient.
const _reframeMessages = [
  // Message for ~1 day missed: gentle, factual, low-shame tone.
  ReframeMessage(
    headline: "You didn't break the habit. You paused it.",
    body: "Your neural pathway for this habit is still intact. One missed day doesn't erase the wiring you've built. The pathway needs activation, not rebuilding.",
  ),
  // Message for ~2 days missed: focuses on recovery speed over perfection.
  ReframeMessage(
    headline: "One missed day is data, not a verdict.",
    body: "High performers miss days. What separates them isn't a perfect streak — it's how fast they return. You're here now. That's the recovery already starting.",
  ),
  // Message for ~3 days missed: shrinks the task to a single micro-action.
  ReframeMessage(
    headline: "The gap between then and now is one action.",
    body: "Not a restart. Not a new system. One small action that tells your brain the pattern continues. That's all this moment requires.",
  ),
  // Message for 4+ days missed: reframes streaks vs. neural durability.
  ReframeMessage(
    headline: "You're not starting over. You're continuing.",
    body: "Streaks measure consecutive days. They don't measure the durability of your neural wiring. That wiring is still there. Today adds to it.",
  ),
];

/// Selects and returns the most appropriate [ReframeMessage] based on how many
/// days the user has missed. The messages escalate in gentleness as the gap grows.
///
/// Parameters:
///   - [daysMissed]: The integer returned by [getDaysMissed]. Should be >= 1.
///
/// Returns: A [ReframeMessage] object with a `headline` and `body` to display.
ReframeMessage getComebackMessage(int daysMissed) {
  // Map daysMissed (1-based) to a 0-based list index.
  // `(daysMissed - 1)` converts "1 day missed" → index 0, "2 days" → index 1, etc.
  // `.clamp(0, _reframeMessages.length - 1)` prevents an "index out of range"
  // error if daysMissed is 0 or larger than the number of messages we have.
  final idx = (daysMissed - 1).clamp(0, _reframeMessages.length - 1);

  // Return the message at the computed index.
  return _reframeMessages[idx];
}

// A private Map (dictionary) from habit category name → list of micro-action strings.
// Map<String, List<String>> means: keys are Strings, values are lists of Strings.
// Each micro-action is a tiny, frictionless step designed to re-ignite the habit
// without overwhelming the user.
const _microActions = {
  // Actions for habits tagged as "focus" (deep work, task management, etc.)
  'focus': [
    'Open your task list and read just the title of your most important task',
    'Sit at your work setup and set a 2-minute timer',
    'Write one sentence about what you are working on today',
  ],
  // Actions for habits tagged as "wellness" (sleep, hydration, nutrition, etc.)
  'wellness': [
    'Take 3 slow deep breaths right now — that is the entire action',
    'Stand up and stretch your arms above your head for 30 seconds',
    'Drink a glass of water before you do anything else',
  ],
  // Actions for habits tagged as "mindset" (journaling, affirmations, reflection)
  'mindset': [
    'Write one sentence: what is one thing that went okay yesterday?',
    'Say out loud: "I am building this one day at a time"',
    'Read back the anchor cue for this habit once',
  ],
  // Actions for habits tagged as "fitness" (exercise, movement, training)
  'fitness': [
    'Do 5 bodyweight squats right now — just 5',
    'Put on your workout clothes (that is the only task)',
    'Walk to the front door and back',
  ],
};

/// Generates a list of 3 tiny "micro-actions" that help the user re-engage with
/// a missed habit without feeling overwhelmed. The actions are tailored to the
/// habit's category if a matching set exists, otherwise generic fallbacks are used.
///
/// Parameters:
///   - [stack]: The missed habit. We use `stack.category` to look up the right
///     set of micro-actions, and `stack.action` to personalise the fallback text.
///
/// Returns: A List<String> with exactly 3 short, actionable strings.
List<String> generateMicroActions(NeuroStack stack) {
  // `stack.category` is an enum value (e.g. Category.focus).
  // `.name` is a built-in Dart property on every enum that returns its name as
  // a plain String (e.g. "focus"), which we use as the Map lookup key.
  //
  // `_microActions[stack.category.name]` looks up the list for this category.
  // The `??` operator is the "null-coalescing" operator in Dart: if the left
  // side is null (no matching category key), use the right side instead.
  return _microActions[stack.category.name] ?? [
    // Fallback action 1: truncate the habit's own action text to 50 characters
    // so the string isn't awkwardly long in the UI.
    // `stack.action.length.clamp(0, 50)` ensures we never ask for more characters
    // than the string contains (avoids a RangeError).
    // `substring(0, n)` extracts the first n characters of the string.
    // The `${}` is Dart string interpolation — it embeds the variable value inline.
    'Do a 60-second version of: ${stack.action.substring(0, stack.action.length.clamp(0, 50))}…',
    // Fallback action 2: a timer-based entry point that requires zero decisions.
    'Set a 2-minute timer and just begin',
    // Fallback action 3: a journaling micro-signal that the pattern is continuing.
    'Write "continuing" in your notes app',
  ];
}
