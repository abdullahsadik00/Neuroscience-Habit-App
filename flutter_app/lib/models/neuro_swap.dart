// =============================================================================
// FILE: neuro_swap.dart
//
// What this file is:
//   Defines the NeuroSwap data model — a plain Dart class that represents a
//   single "habit swap" entry created by the user.
//
// Role in the app architecture:
//   This is a pure data (model) file. It does NOT contain any UI or business
//   logic. Other files (providers, screens, widgets) import this class to
//   create, read, update, and store NeuroSwap objects. Think of it as the
//   blueprint/schema for one piece of app data.
//
// Key concepts to understand this file:
//   1. Immutable data class — all fields are `final`, meaning they cannot be
//      changed after the object is created. To "update" a NeuroSwap you create
//      a new copy with different values using copyWith().
//   2. `const` constructor — allows Dart to create the object at compile time
//      for performance when all values are known ahead of time.
//   3. Serialization (toJson / fromJson) — converts the object to/from a Map
//      so it can be saved to persistent storage (e.g. SharedPreferences, a
//      database, or sent over a network).
//   4. Factory constructor — a special constructor keyword that lets you run
//      logic before returning an instance (used here for fromJson parsing).
// =============================================================================

/// Represents a single NeuroSwap entry: the user's plan to intercept a bad
/// habit by replacing it with a better response when a specific cue is
/// triggered.
///
/// This is an **immutable** data class — once created, its fields cannot be
/// changed. To modify a NeuroSwap, use [copyWith] to produce a new instance
/// with the desired fields updated.
///
/// Used throughout the app wherever habit-swap data is displayed or
/// manipulated — e.g. in screens, providers, and storage helpers.
class NeuroSwap {
  // ---------------------------------------------------------------------------
  // FIELDS
  // Each field is `final`, which means it is set once in the constructor and
  // can never be reassigned. This makes the object safe to share across
  // different parts of the app without worrying about unexpected mutations.
  // ---------------------------------------------------------------------------

  /// Unique identifier for this NeuroSwap (e.g. a UUID string like
  /// "a1b2c3d4-..."). Used to tell one swap apart from another, especially
  /// when saving/loading from storage.
  final String id;

  /// Human-readable name the user gave this swap (e.g. "Stop doom-scrolling").
  /// Displayed as the title in list and detail views.
  final String title;

  /// The environmental or internal trigger that kicks off the bad habit
  /// (e.g. "Feeling bored", "Phone buzzes"). In habit science, a "cue" is the
  /// first step in the habit loop: Cue → Routine → Reward.
  final String cue;

  /// The current undesirable behaviour the user wants to replace
  /// (e.g. "Open Instagram for 45 minutes"). This is the routine that fires
  /// automatically when the cue is detected.
  final String badResponse;

  /// The replacement action the user plans to do instead when the cue occurs
  /// (e.g. "Do 5 deep breaths then open a book"). This is the new routine that
  /// should fire instead of the bad one.
  final String interceptAction;

  /// How much friction (deliberate inconvenience) the user has added to make
  /// the bad habit harder to do. Stored as an integer level (e.g. 0 = none,
  /// 1 = low, 2 = medium, 3 = high). Higher friction = harder to slip.
  final int frictionLevel;

  /// The concrete steps the user has set up to create friction for the bad
  /// habit (e.g. ["Delete the app", "Put phone in another room"]).
  /// Each element of this List<String> is one friction step.
  final List<String> frictionSteps;

  /// A log of timestamps (as ISO-8601 strings) recording each time the user
  /// successfully "urge surfed" — observed the craving without acting on it.
  /// Urge surfing is a mindfulness technique where you ride out the urge like
  /// a wave without giving in to it.
  final List<String> urgeSurfingCompletions;

  /// A log of timestamps (as ISO-8601 strings) recording each time the user
  /// slipped and performed the bad habit anyway. Tracked non-judgmentally so
  /// the user can spot patterns over time.
  final List<String> slips;

  /// ISO-8601 date-time string (e.g. "2026-05-29T10:30:00Z") recording when
  /// this NeuroSwap was first created by the user. Used for sorting and
  /// display ("Created 3 days ago").
  final String createdAt;

  /// Whether this NeuroSwap is currently active. If `false`, the user has
  /// archived or paused it. Used to filter the main list to show only active
  /// swaps by default.
  final bool isActive;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------

  /// Creates a new NeuroSwap.
  ///
  /// All parameters are `required`, meaning you MUST provide every field when
  /// constructing an instance — Dart will give a compile-time error if any are
  /// missing. The `const` keyword means Dart can evaluate this at compile time
  /// (a performance optimisation) when all argument values are compile-time
  /// constants.
  const NeuroSwap({
    required this.id, // must supply an id string
    required this.title, // must supply a title string
    required this.cue, // must supply the trigger description
    required this.badResponse, // must supply the current bad habit description
    required this.interceptAction, // must supply the replacement action
    required this.frictionLevel, // must supply friction level integer
    required this.frictionSteps, // must supply list of friction steps (can be empty [])
    required this.urgeSurfingCompletions, // must supply list of urge-surf timestamps (can be [])
    required this.slips, // must supply list of slip timestamps (can be [])
    required this.createdAt, // must supply creation timestamp string
    required this.isActive, // must supply active/archived boolean
  });

  // ---------------------------------------------------------------------------
  // copyWith METHOD
  // ---------------------------------------------------------------------------

  /// Returns a new NeuroSwap that is identical to this one except for the
  /// fields you explicitly pass in. Fields you do NOT pass keep their current
  /// values.
  ///
  /// This is the standard pattern for "updating" immutable objects in Dart.
  /// Because fields are `final`, you cannot do `mySwap.title = "New Title"`.
  /// Instead you do: `mySwap.copyWith(title: "New Title")`.
  ///
  /// Parameters:
  ///   All parameters are optional (marked with `?` — "nullable"). If you pass
  ///   `null` or leave a parameter out, the existing value is kept unchanged.
  ///
  /// Returns: a brand-new NeuroSwap instance with the merged values.
  NeuroSwap copyWith({
    String? id, // `String?` means this can be a String OR null
    String? title,
    String? cue,
    String? badResponse,
    String? interceptAction,
    int? frictionLevel,
    List<String>? frictionSteps,
    List<String>? urgeSurfingCompletions,
    List<String>? slips,
    String? createdAt,
    bool? isActive,
  }) =>
      // `=>` is the arrow syntax for a single-expression function body.
      // It is equivalent to writing `{ return NeuroSwap(...); }`.
      NeuroSwap(
        // `??` is the "null-coalescing" operator.
        // `id ?? this.id` means: "use the new `id` if it was provided (non-null),
        // otherwise fall back to the current object's `this.id`."
        id: id ?? this.id,
        title: title ?? this.title,
        cue: cue ?? this.cue,
        badResponse: badResponse ?? this.badResponse,
        interceptAction: interceptAction ?? this.interceptAction,
        frictionLevel: frictionLevel ?? this.frictionLevel,
        frictionSteps: frictionSteps ?? this.frictionSteps,
        urgeSurfingCompletions: urgeSurfingCompletions ?? this.urgeSurfingCompletions,
        slips: slips ?? this.slips,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  // ---------------------------------------------------------------------------
  // toJson METHOD
  // ---------------------------------------------------------------------------

  /// Converts this NeuroSwap into a Map<String, dynamic> so it can be
  /// serialized (turned into a storable/transmittable format).
  ///
  /// `Map<String, dynamic>` is Dart's equivalent of a JSON object: a
  /// collection of key-value pairs where keys are Strings and values can be
  /// any type (String, int, bool, List, etc.).
  ///
  /// This is used when SAVING the object — e.g. encoding to JSON and writing
  /// to SharedPreferences or sending to a server.
  ///
  /// Returns: a Map representation of this object where every field maps to
  /// its JSON key name.
  Map<String, dynamic> toJson() => {
        // Each entry is 'jsonKey': dartField.
        // The keys (left side) are the string names that will appear in the
        // stored JSON. They must match the keys used in fromJson() below.
        'id': id,
        'title': title,
        'cue': cue,
        'badResponse': badResponse,
        'interceptAction': interceptAction,
        'frictionLevel': frictionLevel,
        'frictionSteps': frictionSteps, // List<String> serialises naturally to a JSON array
        'urgeSurfingCompletions': urgeSurfingCompletions,
        'slips': slips,
        'createdAt': createdAt,
        'isActive': isActive,
      };

  // ---------------------------------------------------------------------------
  // fromJson FACTORY CONSTRUCTOR
  // ---------------------------------------------------------------------------

  /// Creates a NeuroSwap by reading data out of a Map<String, dynamic> (i.e.
  /// parsed JSON). This is used when LOADING a previously saved NeuroSwap —
  /// e.g. after decoding a JSON string from SharedPreferences.
  ///
  /// The `factory` keyword tells Dart this constructor may contain logic before
  /// returning an instance (unlike a normal constructor which just assigns
  /// fields). Here the logic is type-casting the raw dynamic values to the
  /// correct Dart types.
  ///
  /// Parameter:
  ///   [json] — a Map where keys are field name strings and values are the raw
  ///   dynamic data read from storage. Example:
  ///   `{"id": "abc", "title": "Stop scrolling", "frictionLevel": 2, ...}`
  ///
  /// Returns: a fully populated NeuroSwap instance.
  factory NeuroSwap.fromJson(Map<String, dynamic> json) => NeuroSwap(
        // `json['id'] as String` reads the value for key 'id' from the map and
        // casts it to a String. The `as` keyword is a type cast — it tells Dart
        // "trust me, this value is a String". If the value is actually something
        // else at runtime, Dart will throw a CastError.
        id: json['id'] as String,
        title: json['title'] as String,
        cue: json['cue'] as String,
        badResponse: json['badResponse'] as String,
        interceptAction: json['interceptAction'] as String,
        frictionLevel: json['frictionLevel'] as int,
        // `List<String>.from(...)` creates a new typed List<String> from an
        // untyped List. When JSON is decoded, arrays come back as `List<dynamic>`
        // (a list where each element's type is unknown). `List<String>.from()`
        // iterates each element and asserts it is a String, giving us a proper
        // typed list that the rest of the app can use safely.
        frictionSteps: List<String>.from(json['frictionSteps'] as List),
        urgeSurfingCompletions: List<String>.from(json['urgeSurfingCompletions'] as List),
        slips: List<String>.from(json['slips'] as List),
        createdAt: json['createdAt'] as String,
        isActive: json['isActive'] as bool,
      );
}
