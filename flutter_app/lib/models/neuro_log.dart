// =============================================================================
// FILE: neuro_log.dart
//
// This file defines the data model for a single neuroscience activity log entry
// recorded whenever a user completes a habit, surfs an urge, slips, or makes
// a comeback.
//
// ROLE IN APP ARCHITECTURE:
//   - This is a pure "model" file — it has no UI or Flutter widgets.
//   - It sits at the bottom of the data layer: other files (providers,
//     repositories, screens) all depend on this model.
//   - It is created whenever the user performs an action on a habit item.
//   - It is stored in local device storage (SharedPreferences) as JSON and
//     loaded back on app start.
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   1. Dart classes — blueprints for objects (like a row in a database table).
//   2. Enums — a fixed list of named constant values (like a dropdown with set options).
//   3. JSON serialization — converting a Dart object to/from a Map so it can be
//      saved as a string to disk or sent over a network.
//   4. Factory constructors — a special constructor that can return an object
//      built from some other data source (here: a JSON map).
//   5. `final` fields — fields that cannot be changed once the object is created
//      (immutable data). This prevents accidental bugs.
// =============================================================================

/// Represents the category of action the user took on a habit item.
///
/// Each case of this enum maps to a distinct neuroscience event in the app:
/// completing a habit, resisting a craving, having a setback, or recovering.
enum LogType {
  completion, // The user successfully completed a scheduled habit (dopamine reward).
  urgeSurf,   // The user felt a craving/urge but chose not to act on it (impulse control win).
  slip,       // The user broke the habit or acted on a bad urge (setback recorded honestly).
  comeback,   // The user returned to the habit after a slip (recovery milestone).
}

/// A single log entry that records what happened to a habit item at a specific moment.
///
/// Think of this like one row in a diary: "At 10am on Monday I completed my
/// meditation habit, and here are the neurochemical changes that resulted."
///
/// This class is IMMUTABLE — all fields are `final`, meaning once a NeuroLog
/// is created, its values never change. To "update" a log you would create a
/// new one. Immutability makes state management much easier to reason about.
///
/// USED IN:
///   - Providers/notifiers that manage the log list state.
///   - History/log screens that display past actions.
///   - Neurochemical dashboard calculations that sum up changes over time.
class NeuroLog {
  /// A unique identifier for this log entry (e.g., a UUID string like "a1b2-c3d4").
  /// Used to find or reference this specific entry without confusion.
  final String id;

  /// ISO-8601 formatted date-time string when this log was created
  /// (e.g., "2026-05-29T10:30:00.000"). Stored as a String rather than DateTime
  /// so it serializes to JSON cleanly.
  final String timestamp;

  /// The category of action that was taken — one of the four LogType enum values.
  /// Determines which icon/color/message is shown in the history list.
  final LogType type;

  /// The unique ID of the habit item this log is associated with.
  /// Links this log back to its parent HabitItem without embedding the full item.
  final String itemId;

  /// The human-readable name of the habit item at the time of logging
  /// (e.g., "Morning Meditation"). Stored here so the log still makes sense
  /// even if the habit is later renamed or deleted.
  final String itemTitle;

  /// Optional free-text notes the user typed when logging the action.
  /// The `?` after `String` means this field is NULLABLE — it can hold a String
  /// value OR it can be null (absent). Not every log will have notes.
  final String? notes;

  /// How much the user's dopamine level changed as a result of this action.
  /// Positive = increase (reward), negative = decrease (slip penalty).
  /// Dopamine drives motivation and the feeling of accomplishment.
  final int dopamineChange;

  /// How much the user's epinephrine (adrenaline) level changed.
  /// Positive = the action was activating/energizing (like completing a workout).
  /// Negative = the action was draining or stress-inducing.
  final int epinephrineChange;

  /// How much the user's GABA level changed.
  /// GABA is the brain's main calming neurotransmitter. Surfing an urge
  /// (not giving in) typically increases GABA, signalling calm discipline.
  final int gabaChange;

  /// How much the user's acetylcholine level changed.
  /// Acetylcholine is linked to focus, learning, and memory consolidation.
  /// Completing learning-based habits (e.g., reading) boosts this level.
  final int acetylcholineChange;

  /// Creates a new NeuroLog instance with all required fields.
  ///
  /// `const` means the constructor can create compile-time constant objects
  /// when all argument values are also constants — Flutter uses this for
  /// performance optimizations.
  ///
  /// All fields tagged `required` MUST be supplied by the caller; Dart will
  /// show a compile error if any are missing. `notes` is optional (no `required`)
  /// because it is nullable — the caller may omit it entirely.
  const NeuroLog({
    required this.id,               // Must provide a unique ID string.
    required this.timestamp,        // Must provide an ISO date-time string.
    required this.type,             // Must provide one of the LogType enum values.
    required this.itemId,           // Must provide the parent habit item's ID.
    required this.itemTitle,        // Must provide the habit item's display title.
    this.notes,                     // Optional: caller may omit or pass null.
    required this.dopamineChange,
    required this.epinephrineChange,
    required this.gabaChange,
    required this.acetylcholineChange,
  });

  /// Converts this NeuroLog object into a plain Dart Map (key-value pairs),
  /// suitable for encoding as a JSON string for storage or transmission.
  ///
  /// `Map<String, dynamic>` means: keys are Strings, values can be any type
  /// (int, String, null, etc.) — exactly what JSON requires.
  ///
  /// The `=>` (fat arrow) is shorthand for a one-expression function body:
  /// `Map<String, dynamic> toJson() { return { ... }; }` — same thing, shorter.
  ///
  /// Returns a Map where every field of this object becomes a JSON-safe entry.
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'type': type.name, // `.name` converts the enum value to its string name, e.g., LogType.completion → "completion".
        'itemId': itemId,
        'itemTitle': itemTitle,
        'notes': notes,             // Will be null in the map if no notes were provided; JSON encodes null as null.
        'dopamineChange': dopamineChange,
        'epinephrineChange': epinephrineChange,
        'gabaChange': gabaChange,
        'acetylcholineChange': acetylcholineChange,
      };

  /// A "factory constructor" that builds a NeuroLog from a JSON map.
  ///
  /// FACTORY CONSTRUCTORS: Unlike a normal constructor, a `factory` constructor
  /// can contain logic before returning the object. Here we use it to parse raw
  /// JSON data (loaded from disk or received from a server) back into a typed object.
  ///
  /// Parameters:
  ///   [json] — A Map<String, dynamic> produced by dart:convert's `jsonDecode()`.
  ///            Keys are field names (strings), values are the stored data.
  ///
  /// Returns a fully populated NeuroLog instance.
  factory NeuroLog.fromJson(Map<String, dynamic> json) => NeuroLog(
        // `json['id'] as String` reads the value at key 'id' and casts it to String.
        // The `as String` is an explicit type cast — it tells Dart "I know this is a String".
        id: json['id'] as String,
        timestamp: json['timestamp'] as String,

        // Enum values cannot be decoded from JSON automatically, so we search
        // through all LogType values to find the one whose `.name` matches the
        // stored string (e.g., "completion" → LogType.completion).
        //
        // `LogType.values` is a list of all enum cases: [completion, urgeSurf, slip, comeback].
        // `.firstWhere(...)` scans that list and returns the first element where the
        // condition `(t) => t.name == json['type']` is true (arrow function / lambda).
        // `orElse: () => LogType.completion` is a fallback: if the stored string doesn't
        // match any known enum value (e.g., data was corrupted), default to `completion`
        // rather than crashing the app.
        type: LogType.values.firstWhere(
          (t) => t.name == json['type'], // Check if this enum value's name equals the JSON string.
          orElse: () => LogType.completion, // Safe default if no match is found.
        ),

        itemId: json['itemId'] as String,
        itemTitle: json['itemTitle'] as String,

        // `as String?` means cast to a nullable String — the result is allowed to be null.
        // This is correct because `notes` was stored as null when the user didn't add any.
        notes: json['notes'] as String?,

        dopamineChange: json['dopamineChange'] as int,
        epinephrineChange: json['epinephrineChange'] as int,
        gabaChange: json['gabaChange'] as int,
        acetylcholineChange: json['acetylcholineChange'] as int,
      );
}
