// =============================================================================
// FILE: checkin_record.dart
//
// This file defines the data model for a single weekly check-in entry
// recorded by the user inside the NeuroSync habit app.
//
// ROLE IN THE APP ARCHITECTURE:
//   - This is a "model" file — it describes the *shape* of data, not the UI.
//   - It lives in lib/models/ alongside brain_profile.dart, which defines
//     related types (like FailureStyle) that are imported here.
//   - Providers (in lib/providers/) hold lists of CheckinRecord objects in
//     app state. Screens/widgets (in lib/screens/ and lib/widgets/) read those
//     providers and display check-in history.
//   - When data needs to be saved or loaded (e.g. from SharedPreferences),
//     toJson() and fromJson() are used to convert between this Dart object
//     and a plain Map that can be stored as a JSON string.
//
// KEY CONCEPTS TO KNOW BEFORE READING:
//   - Dart classes: Like classes in any OOP language — they group related
//     data (fields) and behaviour (methods) together.
//   - Immutability: Every field here is marked `final`, meaning once a
//     CheckinRecord is created its values never change. To "edit" one you
//     call copyWith() to get a new object with the changed value.
//   - Enums: A fixed list of named choices. EnergyLevel can only ever be
//     low, normal, or high — nothing else.
//   - Nullable types (String?): The `?` after a type means the value is
//     allowed to be null (absent). Without `?` the value must always be
//     provided.
//   - JSON serialisation: JSON is a text format used to store/transfer data.
//     toJson() converts this object to a Map (dictionary), and fromJson()
//     recreates the object from that Map.
// =============================================================================

// Brings in brain_profile.dart from the same models/ directory.
// We need it because CheckinRecord stores a FailureStyle value, which is
// an enum defined in brain_profile.dart.
import 'brain_profile.dart';

// ---------------------------------------------------------------------------
// ENUM: EnergyLevel
//
// An enum (short for "enumeration") is a Dart type whose only legal values
// are the names you list inside the braces. This prevents typos and makes
// the code self-documenting — instead of storing the string "high" you
// store the compile-time constant EnergyLevel.high.
// ---------------------------------------------------------------------------

/// Represents how energetic the user felt during the week being reviewed.
enum EnergyLevel {
  low,    // User felt depleted / struggling to maintain habits
  normal, // Typical, baseline energy level
  high,   // User felt motivated and energised — peak execution week
}

// ---------------------------------------------------------------------------
// CLASS: CheckinRecord
//
// A plain Dart "data class" — it holds all the information captured during
// one weekly check-in session. It does NOT extend any Flutter widget class
// because it is purely data, not UI.
//
// Instances of this class are created:
//   - In CheckinScreen when the user submits the check-in form.
//   - In fromJson() when loading saved check-ins from local storage.
//
// The class is IMMUTABLE (all fields are final). If any field needs updating
// (e.g. marking recalibrationApplied = true), use copyWith() to get a fresh
// object rather than mutating the original.
// ---------------------------------------------------------------------------

/// Stores all data captured for a single weekly check-in.
class CheckinRecord {
  // -------------------------------------------------------------------------
  // FIELDS
  // Each field is `final` — assigned once in the constructor, never changed.
  // -------------------------------------------------------------------------

  /// Unique identifier for this check-in (e.g. a UUID string like
  /// "a3f2..."). Used to tell apart different records when saving/loading.
  final String id;

  /// The date of this check-in stored as an ISO-8601 string, e.g. "2026-05-29".
  /// We use String rather than DateTime so it serialises easily to/from JSON.
  final String date;

  /// How consistently the user followed their habits this week, on a 1–5 scale.
  /// 1 = barely at all, 5 = every single day without fail.
  final int consistency; // 1-5

  /// Free-text describing the main obstacle the user faced this week
  /// (e.g. "travel", "poor sleep", "work deadline").
  final String weeklyBlocker;

  /// The user's self-reported energy level for the week (low / normal / high).
  /// Uses the EnergyLevel enum defined above so only valid choices are accepted.
  final EnergyLevel energyLevel;

  /// Whether the user changed any part of their habit routine this week.
  /// true = yes they made a change, false = routine stayed the same.
  final bool routineChanged;

  /// Optional free-text note about what changed in the routine.
  /// The `?` means this may be null — it is only filled in when
  /// routineChanged is true.
  final String? routineNote;

  /// Optional flag indicating whether the user's life context changed
  /// (e.g. new job, moved house). Null means the question was not answered.
  final bool? contextChanged;

  /// Optional — the failure pattern the user is currently exhibiting,
  /// as defined by the FailureStyle enum in brain_profile.dart.
  /// Null means no failure mode was identified / selected.
  final FailureStyle? currentFailureMode;

  /// Whether the app has already shown and applied a recalibration suggestion
  /// to this check-in. Prevents showing the same suggestion twice.
  final bool recalibrationApplied;

  // -------------------------------------------------------------------------
  // CONSTRUCTOR
  //
  // `const` means if you pass all compile-time constants as arguments Dart
  // can build the object at compile time (a minor performance optimisation).
  //
  // Named parameters (inside {}) let callers write:
  //   CheckinRecord(id: '1', date: '2026-05-29', ...)
  // instead of relying on positional order.
  //
  // `required` means the caller MUST provide that argument — the compiler
  // will error if it is missing.
  // Parameters without `required` (routineNote, contextChanged,
  // currentFailureMode) are optional and default to null.
  // -------------------------------------------------------------------------

  /// Creates a new CheckinRecord with all its fields populated.
  const CheckinRecord({
    required this.id,                   // Must provide a unique ID
    required this.date,                 // Must provide the check-in date
    required this.consistency,          // Must provide a 1-5 score
    required this.weeklyBlocker,        // Must describe the main blocker
    required this.energyLevel,          // Must choose low / normal / high
    required this.routineChanged,       // Must say whether routine changed
    this.routineNote,                   // Optional — only if routine changed
    this.contextChanged,                // Optional — life-context question
    this.currentFailureMode,            // Optional — detected failure pattern
    required this.recalibrationApplied, // Must track whether suggestion shown
  });

  // -------------------------------------------------------------------------
  // METHOD: copyWith
  //
  // A common Dart pattern for immutable data classes. Because all fields are
  // final you cannot do `record.recalibrationApplied = true`. Instead you
  // call copyWith() which creates a brand-new CheckinRecord with most fields
  // copied from the original and only the ones you pass in overridden.
  //
  // Currently only recalibrationApplied is exposed as a parameter because
  // that is the only field the app needs to update after creation.
  // -------------------------------------------------------------------------

  /// Returns a new CheckinRecord identical to this one, except for any
  /// fields explicitly passed as arguments.
  ///
  /// [recalibrationApplied] — pass true to mark that the recalibration
  /// suggestion has been shown for this record.
  CheckinRecord copyWith({bool? recalibrationApplied}) => CheckinRecord(
        id: id,                   // Copy the original id unchanged
        date: date,               // Copy the original date unchanged
        consistency: consistency, // Copy the original score unchanged
        weeklyBlocker: weeklyBlocker,
        energyLevel: energyLevel,
        routineChanged: routineChanged,
        routineNote: routineNote,
        contextChanged: contextChanged,
        currentFailureMode: currentFailureMode,
        // `??` is the "null-coalescing" operator: if the left side is null,
        // use the right side instead. So if the caller did NOT pass a new
        // value, keep the original (this.recalibrationApplied).
        recalibrationApplied: recalibrationApplied ?? this.recalibrationApplied,
      );

  // -------------------------------------------------------------------------
  // METHOD: toJson
  //
  // Converts this CheckinRecord into a Map<String, dynamic>.
  // A Map in Dart is like a JavaScript object / Python dictionary — it stores
  // key-value pairs. `dynamic` means the values can be of any type.
  //
  // This Map can then be passed to jsonEncode() (from dart:convert) to get a
  // JSON string suitable for saving to SharedPreferences or sending to an API.
  //
  // The `=>` (fat arrow) is shorthand for a single-expression function body:
  //   Map<String, dynamic> toJson() { return { ... }; }
  // is exactly the same as:
  //   Map<String, dynamic> toJson() => { ... };
  // -------------------------------------------------------------------------

  /// Serialises this CheckinRecord to a plain Map so it can be stored as JSON.
  /// Returns a Map where every key is a String and values are basic Dart types.
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'consistency': consistency,
        'weeklyBlocker': weeklyBlocker,
        // Enums cannot be stored directly in JSON. `.name` gives the string
        // representation, e.g. EnergyLevel.high.name == "high".
        'energyLevel': energyLevel.name,
        'routineChanged': routineChanged,
        'routineNote': routineNote,       // Will be null if not set — JSON supports null
        'contextChanged': contextChanged, // May be null
        // `?.name` is "null-safe member access": if currentFailureMode is null,
        // the whole expression is null instead of throwing a NullPointerError.
        'currentFailureMode': currentFailureMode?.name,
        'recalibrationApplied': recalibrationApplied,
      };

  // -------------------------------------------------------------------------
  // FACTORY CONSTRUCTOR: fromJson
  //
  // A `factory` constructor is a special constructor that can return an
  // existing object or delegate creation logic — here we use it as the
  // conventional name for "build an instance from a Map (parsed JSON)".
  //
  // Map<String, dynamic> json — the decoded JSON, e.g.:
  //   { "id": "abc", "energyLevel": "high", ... }
  //
  // `as String`, `as int`, `as bool` — Dart's explicit type-cast operator.
  // JSON decoding produces dynamic values; casting tells Dart what type to
  // expect and will throw if the data is wrong (helpful for debugging).
  //
  // `as String?` — nullable cast: the value may be null, and that is fine.
  // -------------------------------------------------------------------------

  /// Recreates a CheckinRecord from a Map (e.g. data loaded from storage).
  ///
  /// [json] — a Map<String, dynamic> previously produced by toJson().
  /// Returns a fully populated CheckinRecord instance.
  factory CheckinRecord.fromJson(Map<String, dynamic> json) => CheckinRecord(
        id: json['id'] as String,                     // Read the id key and cast to String
        date: json['date'] as String,                 // Read the date key
        consistency: json['consistency'] as int,      // Read the 1-5 integer score
        weeklyBlocker: json['weeklyBlocker'] as String,

        // EnergyLevel.values is a list of all enum cases: [low, normal, high].
        // .firstWhere() searches the list for the first element where the
        // provided condition is true — here, where the enum's `.name` string
        // matches the stored JSON string.
        // orElse: () => EnergyLevel.normal is a fallback: if the stored string
        // somehow doesn't match any case (e.g. old data), default to normal.
        energyLevel: EnergyLevel.values.firstWhere(
          (e) => e.name == json['energyLevel'], // `e` is each enum value in turn
          orElse: () => EnergyLevel.normal,     // Safety fallback if data is missing/corrupt
        ),

        routineChanged: json['routineChanged'] as bool,

        // `as String?` — cast allows null because this field is optional
        routineNote: json['routineNote'] as String?,

        // `as bool?` — nullable bool cast; will be null if key was never set
        contextChanged: json['contextChanged'] as bool?,

        // If the JSON key is present and non-null, look up the matching
        // FailureStyle enum value. If the key is null (field was never set),
        // the ternary expression short-circuits to null without calling
        // firstWhere at all.
        //
        // `condition ? valueIfTrue : valueIfFalse` is Dart's ternary operator —
        // equivalent to an if/else expression written on one line.
        currentFailureMode: json['currentFailureMode'] != null
            ? FailureStyle.values.firstWhere(
                (f) => f.name == json['currentFailureMode'], // Match stored string to enum
                orElse: () => FailureStyle.drifter,          // Fallback if unrecognised value
              )
            : null, // Key was null in JSON — keep the field null

        recalibrationApplied: json['recalibrationApplied'] as bool,
      );
}
