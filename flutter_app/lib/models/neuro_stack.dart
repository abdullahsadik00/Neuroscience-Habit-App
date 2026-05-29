// =============================================================================
// FILE: neuro_stack.dart
//
// What this file is: Defines the core data model for a single habit "stack" —
// the fundamental building block of the NeuroSync habit app.
//
// Role in app architecture:
//   This is a pure data/model file with no UI or state-management code.
//   Riverpod providers read and write NeuroStack objects; widgets display them.
//   Local-storage code serialises them via toJson/fromJson. Think of this class
//   as a blueprint that describes exactly what data one habit holds.
//
// Key concepts a learner needs to know:
//   1. Dart `enum` — a fixed set of named constants. Use it when a field can
//      only be one of a known list of values (here: habit categories).
//   2. Immutable class — all fields are `final`, meaning they cannot be changed
//      after the object is created. This is a Flutter best-practice because it
//      prevents accidental mutation and makes state changes predictable.
//   3. `const` constructor — lets Dart create the object at compile time when
//      all values are known, which is faster and uses less memory.
//   4. `required` named parameters — the compiler forces every caller to supply
//      every field by name, making constructor calls self-documenting.
//   5. Nullable fields (`String?`) — the `?` means the value is allowed to be
//      `null` (absent). Dart is "null-safe": fields without `?` can NEVER be null.
//   6. `copyWith` pattern — creates a new object that is identical to the
//      current one except for the fields you explicitly override. Because objects
//      are immutable, this is how you "update" one: throw away the old object
//      and create a slightly-different new one.
//   7. `toJson` / `fromJson` — converts between a Dart object and a plain Map
//      so the data can be saved to disk or sent over a network.
//   8. `factory` constructor — a constructor that can run arbitrary logic before
//      returning an instance (used here to parse values from a Map).
// =============================================================================

/// The category a habit belongs to.
///
/// Used to group habits visually and to apply category-specific
/// neurochemistry bonuses in the app's scoring logic.
enum HabitCategory {
  focus,    // habits that sharpen attention and cognitive performance
  wellness, // habits related to sleep, nutrition, and physical health
  mindset,  // habits that build emotional resilience and mental framing
  fitness,  // movement and exercise-based habits
}

/// Represents a single habit "stack" in the NeuroSync app.
///
/// A habit stack is built around the neuroscience habit loop:
///   Cue (anchorCue) → Routine (action) → Reward (reward)
///
/// The "stack" terminology comes from "habit stacking" — pairing a new
/// behaviour with an existing one so the brain learns the new habit faster.
///
/// This class is used by:
///   - Riverpod providers to hold and update the list of user habits.
///   - Local-storage helpers to persist habits between app sessions.
///   - UI widgets to display habit cards, streak counters, and progress bars.
class NeuroStack {
  /// Unique identifier for this habit (e.g. a UUID like "a3f9c1d2-...").
  /// Used to find, update, or delete this specific habit in storage.
  final String id;

  /// Human-readable name the user gave this habit (e.g. "Morning meditation").
  final String title;

  /// The existing behaviour this habit is "stacked" onto.
  /// Example: "After I pour my morning coffee" — this is the environmental cue
  /// that triggers the habit loop, based on BJ Fogg's Tiny Habits research.
  final String anchorCue;

  /// The actual behaviour the user will perform (e.g. "Meditate for 5 minutes").
  /// This is the "routine" in the cue → routine → reward loop.
  final String action;

  /// The immediate reward after completing the action
  /// (e.g. "Feel calm and centred"). Rewards reinforce the habit in the brain.
  final String reward;

  /// Which of the four categories this habit belongs to.
  /// See [HabitCategory] for the possible values and their meanings.
  final HabitCategory category;

  /// How many minutes of focused attention (acetylcholine release) this
  /// habit requires. Used by the neurochemistry scoring engine to calculate
  /// acetylcholine level changes when the habit is completed.
  final int acetylcholineDuration;

  /// A 0.0–1.0 score representing how deeply this habit is "wired" into the
  /// user's brain (inspired by the neuroscience concept of myelin sheaths
  /// strengthening neural pathways with repetition). Higher = more automatic.
  final double myelinationLevel;

  /// The current consecutive-day streak for this habit.
  /// Resets to 0 when a day is missed; used to motivate consistency.
  final int streak;

  /// A list of date strings (e.g. ["2026-05-28", "2026-05-29"]) recording
  /// every day on which this habit was completed. Used to calculate streaks
  /// and display a history calendar in the UI.
  final List<String> completions;

  /// ISO-8601 date string of when the habit was first created
  /// (e.g. "2026-05-01"). Helps sort habits and show "days since started".
  final String createdAt;

  /// Whether this habit is currently active (visible in the dashboard).
  /// When `false` the habit is "archived" — hidden but not deleted, so
  /// history is preserved and the user can re-activate it later.
  final bool isActive;

  // -------------------------------------------------------------------------
  // Implementation Intentions — "When [whenCondition] I will [thenAction]"
  //
  // Implementation intentions are a research-backed technique where you
  // pre-commit to exactly WHEN and WHERE you will perform a habit. The `?`
  // after String means these fields are optional — not every habit needs them.
  // -------------------------------------------------------------------------

  /// The "when" part of an implementation intention.
  /// Example: "When I sit down at my desk at 9 am".
  /// `null` if the user has not set one.
  final String? whenCondition;

  /// The "then I will" part of an implementation intention.
  /// Example: "then I will write 3 things I'm grateful for".
  /// `null` if the user has not set one.
  final String? thenAction;

  /// Dates (YYYY-MM-DD) on which the user chose "Lite Mode Today" for this habit.
  /// Each entry records a day the user intentionally downscaled instead of skipping,
  /// rewarding self-awareness and preventing full misses.
  final List<String> liteModeDates;

  /// Creates a new NeuroStack with every field specified.
  ///
  /// The `const` keyword means Dart can create identical objects as compile-time
  /// constants, saving memory. All parameters are `required` except the two
  /// nullable implementation-intention fields, which default to `null` if omitted.
  const NeuroStack({
    required this.id,
    required this.title,
    required this.anchorCue,
    required this.action,
    required this.reward,
    required this.category,
    required this.acetylcholineDuration,
    required this.myelinationLevel,
    required this.streak,
    required this.completions,
    required this.createdAt,
    required this.isActive,
    this.whenCondition, // optional — omitting it sets the field to null
    this.thenAction,    // optional — omitting it sets the field to null
    this.liteModeDates = const [], // optional — defaults to empty list
  });

  /// Returns a new [NeuroStack] that is a copy of this one, with only the
  /// specified fields replaced by the new values.
  ///
  /// This is the standard "immutable update" pattern in Dart/Flutter. Because
  /// [NeuroStack] fields are all `final`, you cannot do `stack.streak = 5;`.
  /// Instead you call `stack.copyWith(streak: 5)` to get a brand-new object
  /// with streak = 5 and all other fields identical to the original.
  ///
  /// How the `??` operator works:
  ///   `streak ?? this.streak` means: "if the caller passed a new `streak`
  ///   value, use that; otherwise keep the existing one (`this.streak`)."
  ///   The `?` in `int? streak` in the parameter list means the caller is
  ///   allowed to pass `null` (i.e. omit the field), which is how we know
  ///   "no change requested for this field".
  ///
  /// The `=>` arrow syntax is shorthand for `{ return NeuroStack(...); }`.
  NeuroStack copyWith({
    String? id,
    String? title,
    String? anchorCue,
    String? action,
    String? reward,
    HabitCategory? category,
    int? acetylcholineDuration,
    double? myelinationLevel,
    int? streak,
    List<String>? completions,
    String? createdAt,
    bool? isActive,
    String? whenCondition,
    String? thenAction,
    List<String>? liteModeDates,
  }) =>
      NeuroStack(
        id: id ?? this.id,                                         // use new id if provided, else keep existing
        title: title ?? this.title,
        anchorCue: anchorCue ?? this.anchorCue,
        action: action ?? this.action,
        reward: reward ?? this.reward,
        category: category ?? this.category,
        acetylcholineDuration: acetylcholineDuration ?? this.acetylcholineDuration,
        myelinationLevel: myelinationLevel ?? this.myelinationLevel,
        streak: streak ?? this.streak,
        completions: completions ?? this.completions,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        whenCondition: whenCondition ?? this.whenCondition,
        thenAction: thenAction ?? this.thenAction,
        liteModeDates: liteModeDates ?? this.liteModeDates,
      );

  /// Converts this [NeuroStack] into a plain Dart Map so it can be saved to
  /// local storage (SharedPreferences) or sent as JSON over a network.
  ///
  /// `Map<String, dynamic>` is a dictionary whose keys are Strings and whose
  /// values can be any Dart type (int, double, bool, String, List, etc.).
  ///
  /// Note `category.name`: enums have a built-in `.name` getter that returns
  /// the enum value as a plain String (e.g. `HabitCategory.focus.name == "focus"`).
  /// We store the name (not the enum itself) because JSON cannot store Dart enums.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'anchorCue': anchorCue,
        'action': action,
        'reward': reward,
        'category': category.name, // convert enum to its string name for JSON storage
        'acetylcholineDuration': acetylcholineDuration,
        'myelinationLevel': myelinationLevel,
        'streak': streak,
        'completions': completions, // List<String> is directly JSON-serialisable
        'createdAt': createdAt,
        'isActive': isActive,
        'whenCondition': whenCondition, // will be null in JSON if not set — that is fine
        'thenAction': thenAction,
        'liteModeDates': liteModeDates, // List<String> of 'YYYY-MM-DD' dates
      };

  /// Recreates a [NeuroStack] from a Map that was previously produced by [toJson].
  ///
  /// This is a `factory` constructor — it can contain logic before returning the
  /// object. Here we need to:
  ///   1. Cast each dynamic Map value to its proper Dart type (`as String`, `as int`, etc.).
  ///   2. Convert the category string back into a [HabitCategory] enum value.
  ///   3. Safely cast the completions List.
  ///
  /// Parameter:
  ///   [json] — A Map<String, dynamic> (typically loaded from device storage).
  ///
  /// Returns a fully populated [NeuroStack].
  factory NeuroStack.fromJson(Map<String, dynamic> json) => NeuroStack(
        id: json['id'] as String,
        title: json['title'] as String,
        anchorCue: json['anchorCue'] as String,
        action: json['action'] as String,
        reward: json['reward'] as String,
        // Convert the stored string (e.g. "focus") back to the enum value.
        // `HabitCategory.values` is the list of all enum values.
        // `.firstWhere(...)` searches the list for the one whose `.name` matches.
        // `orElse: () => HabitCategory.focus` provides a safe default if the
        // stored string doesn't match any known value (e.g. corrupted data).
        category: HabitCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => HabitCategory.focus, // fallback so the app doesn't crash
        ),
        acetylcholineDuration: json['acetylcholineDuration'] as int,
        // `(... as num).toDouble()` — JSON numbers can be stored as int or double.
        // Casting to `num` first (the parent of both) then calling `.toDouble()`
        // ensures we always get a double regardless of how the value was stored.
        myelinationLevel: (json['myelinationLevel'] as num).toDouble(),
        streak: json['streak'] as int,
        // `List<String>.from(...)` creates a new typed List<String> from the
        // untyped List that comes out of JSON parsing. Without this, Dart would
        // give us `List<dynamic>` and we'd lose type safety.
        completions: List<String>.from(json['completions'] as List),
        createdAt: json['createdAt'] as String,
        // `as bool? ?? true` — the `?` cast allows null; `?? true` provides a
        // default of true so that old records without this field are treated as active.
        isActive: json['isActive'] as bool? ?? true,
        whenCondition: json['whenCondition'] as String?, // nullable — may be null
        thenAction: json['thenAction'] as String?,       // nullable — may be null
        // `as List? ?? []` — backward-compatible: old records without this field
        // default to an empty list (no lite mode activations).
        liteModeDates: List<String>.from(json['liteModeDates'] as List? ?? []),
      );
}
