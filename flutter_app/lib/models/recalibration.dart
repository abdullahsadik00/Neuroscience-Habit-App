// =============================================================================
// FILE: recalibration.dart
//
// This file defines the data models used to represent a "recalibration" event —
// the moment when the app suggests the user adjust one or more habits that are
// not being completed consistently.
//
// ROLE IN THE APP ARCHITECTURE:
//   These are pure "model" classes — they hold data only, with no UI or logic.
//   They are used by:
//     - Riverpod providers (state management layer) to store recalibration state
//     - The recalibration screen/widget (UI layer) to render suggestions
//     - The persistence layer (SharedPreferences / JSON storage) to save/load
//       recalibration history to the device
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   1. Enum — A fixed list of named values. Like a category label.
//   2. Class — A blueprint for creating objects that hold related data.
//   3. `final` fields — Once set, these values cannot change (immutable data).
//   4. Named constructors — `factory` keyword lets us define alternative ways
//      to create an object (e.g., building one from raw JSON data).
//   5. JSON serialization — Converting a Dart object to/from a Map<String, dynamic>
//      so it can be saved as text (JSON) and later restored.
//   6. Nullable types (`String?`) — The `?` means the value is optional and
//      might be null (absent). Without `?`, the value MUST be provided.
// =============================================================================

/// Represents the three possible kinds of adjustments the app can suggest
/// when a habit is struggling.
///
/// An enum (enumeration) is a special Dart type that restricts a variable to
/// one of a fixed set of named options — like a dropdown with only 3 choices.
enum SuggestionType {
  scaleDown, // Reduce the difficulty/duration of the existing habit (e.g., "5 min → 2 min")
  replace, // Swap the habit out entirely for a different template habit
  updateMicro, // Update the "micro" version of the habit — the smallest possible action
}

/// Represents a single suggestion made to the user during a recalibration check-in.
///
/// A suggestion tells the user: "Your habit [habitTitle] is struggling.
/// We recommend [type]: change it from [fromValue] to [toValue] because [reason]."
///
/// This class is a plain Dart "model" class — it just holds data.
/// It is NOT a Flutter widget; it has no build() method or UI.
///
/// Used in:
///   - [RecalibrationEvent] (a list of these is bundled into one event)
///   - The recalibration UI screen (to render each suggestion card)
class RecalibrationSuggestion {
  /// A unique identifier for this suggestion (e.g., a UUID string like "abc-123").
  /// Used to track which suggestions the user accepted or rejected.
  final String id;

  /// What kind of change is being suggested — one of the three [SuggestionType] values.
  final SuggestionType type;

  /// The ID of the habit this suggestion targets.
  /// Nullable (`String?`) because a "replace" suggestion might refer to a new habit
  /// that doesn't yet have an ID assigned.
  final String? habitId;

  /// The human-readable name of the habit (e.g., "Morning Run").
  /// Nullable because it may not always be available (e.g., during preview).
  final String? habitTitle;

  /// Plain-English explanation of WHY this change is recommended.
  /// Example: "You've missed this habit 4 of the last 7 days."
  final String reason;

  /// Describes the current (before) state of the habit being changed.
  /// Example: "10 minutes" or "Run 5km".
  final String fromValue;

  /// Describes the proposed (after) state of the habit.
  /// Example: "5 minutes" or "Run 2km".
  final String toValue;

  /// If the suggestion type is [SuggestionType.replace], this holds the ID of the
  /// habit template that should replace the current habit.
  /// Null for scaleDown and updateMicro suggestions.
  final String? replacementTemplateId;

  /// The primary constructor. All `required` fields MUST be passed in;
  /// optional (`this.habitId` etc.) default to null if not provided.
  ///
  /// `const` means Dart can evaluate this at compile time if all values are
  /// constants — a performance optimization.
  const RecalibrationSuggestion({
    required this.id, // Must provide an ID
    required this.type, // Must specify what kind of suggestion this is
    this.habitId, // Optional — may be null
    this.habitTitle, // Optional — may be null
    required this.reason, // Must explain why
    required this.fromValue, // Must show current state
    required this.toValue, // Must show proposed state
    this.replacementTemplateId, // Optional — only needed for "replace" type
  });

  /// Converts this object into a [Map<String, dynamic>] — essentially a
  /// dictionary of key/value pairs that can be encoded as JSON text.
  ///
  /// This is called "serialization": turning a structured object into a flat
  /// format that can be saved to disk or sent over a network.
  ///
  /// The `=>` (fat arrow) is Dart shorthand for a function that immediately
  /// returns a single expression — equivalent to `{ return { ... }; }`.
  Map<String, dynamic> toJson() => {
        'id': id, // Save the ID string as-is
        'type': type.name, // `.name` converts the enum value to its string name (e.g., "scaleDown")
        'habitId': habitId, // Will be null in JSON if not set
        'habitTitle': habitTitle, // Will be null in JSON if not set
        'reason': reason,
        'fromValue': fromValue,
        'toValue': toValue,
        'replacementTemplateId': replacementTemplateId, // Will be null in JSON if not set
      };

  /// A "factory constructor" — an alternative way to create a [RecalibrationSuggestion]
  /// by reading data from a JSON map (the raw data loaded from storage).
  ///
  /// This is called "deserialization": rebuilding a structured object from flat data.
  ///
  /// The `factory` keyword means this constructor can return an existing object
  /// or do more complex logic — it's not required to directly call `this(...)`.
  ///
  /// [json] — a Map<String, dynamic> where keys are strings and values can be
  ///          any type (String, int, List, null, etc.)
  factory RecalibrationSuggestion.fromJson(Map<String, dynamic> json) =>
      RecalibrationSuggestion(
        id: json['id'] as String, // `as String` casts the dynamic value to a String — throws if wrong type
        type: SuggestionType.values.firstWhere(
          // `.values` is a built-in List of all enum cases: [scaleDown, replace, updateMicro]
          // `.firstWhere()` searches the list and returns the first match for the condition
          (t) => t.name == json['type'], // Compare each enum's string name to what's stored in JSON
          orElse: () => SuggestionType.scaleDown, // Fallback: if the stored string is unrecognized, use scaleDown
        ),
        habitId: json['habitId'] as String?, // `as String?` allows null — won't throw if value is absent
        habitTitle: json['habitTitle'] as String?,
        reason: json['reason'] as String,
        fromValue: json['fromValue'] as String,
        toValue: json['toValue'] as String,
        replacementTemplateId: json['replacementTemplateId'] as String?,
      );
}

/// Represents a complete recalibration session — a snapshot in time when the
/// app reviewed the user's habits and generated a set of suggestions.
///
/// Think of this as a "report card" event: on a certain [date], the app
/// produced [suggestions], and the user either [accepted] or [rejected] each one.
///
/// A list of these events forms the user's recalibration history, which can
/// be reviewed later to understand how their habits have evolved.
///
/// Used in:
///   - Riverpod state (stored in a list, one entry per recalibration session)
///   - The recalibration history screen
///   - Persistent storage (saved/loaded as JSON)
class RecalibrationEvent {
  /// Unique identifier for this recalibration event (e.g., a UUID or timestamp string).
  final String id;

  /// The date this recalibration event occurred, stored as a string
  /// (typically ISO 8601 format: "2024-01-15").
  final String date;

  /// The list of individual suggestions generated during this session.
  /// Each [RecalibrationSuggestion] targets one habit.
  final List<RecalibrationSuggestion> suggestions;

  /// A list of suggestion IDs that the user accepted (agreed to change).
  /// Storing just the ID (not the full object) keeps this list lightweight.
  final List<String> accepted;

  /// A list of suggestion IDs that the user rejected (chose to keep as-is).
  final List<String> rejected;

  /// Primary constructor — all fields are required for a complete event record.
  const RecalibrationEvent({
    required this.id,
    required this.date,
    required this.suggestions,
    required this.accepted,
    required this.rejected,
  });

  /// Serializes this event to a JSON-compatible map for saving to storage.
  ///
  /// Note the `suggestions` field: since each suggestion is itself an object,
  /// we must call `.toJson()` on each one before putting it in the map.
  /// `.map((s) => s.toJson())` iterates over the list and transforms each item.
  /// `.toList()` is required because `.map()` returns a lazy Iterable, not a List —
  /// we need to force it to evaluate and produce an actual List.
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'suggestions': suggestions.map((s) => s.toJson()).toList(), // Convert each suggestion object → map
        'accepted': accepted, // List<String> serializes directly — no conversion needed
        'rejected': rejected,
      };

  /// Deserializes a [RecalibrationEvent] from a JSON map loaded from storage.
  ///
  /// [json] — the raw map read from disk/SharedPreferences.
  factory RecalibrationEvent.fromJson(Map<String, dynamic> json) =>
      RecalibrationEvent(
        id: json['id'] as String,
        date: json['date'] as String,
        suggestions: (json['suggestions'] as List) // Cast to List (type is dynamic at this point)
            .map((s) => RecalibrationSuggestion.fromJson(s as Map<String, dynamic>))
            // For each item `s` in the list, cast it to a Map and reconstruct the full object
            .toList(), // Force the lazy Iterable into a concrete List<RecalibrationSuggestion>
        accepted: List<String>.from(json['accepted'] as List),
        // `List<String>.from(...)` creates a typed List<String> from an untyped List
        // This is needed because JSON lists come back as List<dynamic>, not List<String>
        rejected: List<String>.from(json['rejected'] as List),
      );
}
