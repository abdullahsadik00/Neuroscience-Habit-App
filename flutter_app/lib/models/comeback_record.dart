// -----------------------------------------------------------------------------
// FILE: comeback_record.dart
//
// What this file is: Defines the data model for a single "comeback" event —
// recorded when a user returns to a habit after having missed it.
//
// Role in app architecture:
//   This is a pure data/model file. It does not touch the UI or state management.
//   Other files (e.g. a Riverpod provider or a local-storage service) will
//   create, read, and persist ComebackRecord objects. Think of it as a blueprint
//   that describes the shape of one piece of data the app needs to store.
//
// Key concepts a learner needs to know:
//   1. Dart class — a template for creating objects with specific fields.
//   2. `final` fields — once set in the constructor, they cannot be changed.
//      This makes the object "immutable" (safe to share without accidental edits).
//   3. `const` constructor — allows Dart to create the object at compile time
//      when all arguments are known, saving memory and improving performance.
//   4. Named parameters with `required` — forces callers to explicitly name
//      and provide every field; prevents mistakes from wrong argument order.
//   5. `toJson` / `fromJson` — a common Dart pattern for converting an object
//      to/from a Map (key-value pairs), which is how data is stored in JSON
//      files, databases, or local device storage (SharedPreferences).
//   6. `factory` constructor — a special constructor that can contain logic
//      before returning the object (here, it reads values out of a Map).
// -----------------------------------------------------------------------------

/// Represents a single "comeback" event in the NeuroSync habit app.
///
/// A comeback is recorded each time a user completes micro-actions after
/// missing a habit for one or more days. This record lets the app track
/// the history of recoveries for a specific habit stack.
///
/// This class is used by local-storage code to persist records on the device,
/// and by UI widgets to display comeback history and streak information.
class ComebackRecord {
  /// The unique identifier for this comeback record.
  /// Generated when the record is first created (e.g. a UUID string like
  /// "a3f9c1d2-..."). Used to distinguish one record from another in storage.
  final String id;

  /// The ID of the habit "stack" (group of habits) this comeback belongs to.
  /// Links this record back to a specific HabitStack object elsewhere in the app.
  final String stackId;

  /// The calendar date on which this comeback occurred, stored as a string
  /// (e.g. "2026-05-29"). Using a String keeps serialisation simple and avoids
  /// timezone issues that come with Dart's DateTime type.
  final String date;

  /// Whether the user completed the micro-actions for this comeback day.
  /// `true` means the user ticked off the small recovery steps; `false` means
  /// the record was created but the steps were not finished.
  final bool microActionsCompleted;

  /// The exact timestamp when the comeback was marked complete, stored as a
  /// string (ISO-8601 format, e.g. "2026-05-29T14:30:00.000Z"). Allows the app
  /// to show the user precisely when they completed their recovery.
  final String completedAt;

  /// Creates a new ComebackRecord with all fields required.
  ///
  /// Using `const` here means Dart can optimise identical objects — if two
  /// widgets reference the exact same record, Dart reuses a single instance
  /// in memory instead of allocating two.
  ///
  /// All parameters use `required` so the compiler will refuse to compile code
  /// that tries to create a ComebackRecord with any field missing.
  const ComebackRecord({
    required this.id,                    // caller must supply the unique ID
    required this.stackId,               // caller must supply which habit stack
    required this.date,                  // caller must supply the date string
    required this.microActionsCompleted, // caller must say whether steps were done
    required this.completedAt,           // caller must supply the completion timestamp
  });

  /// Converts this ComebackRecord into a plain Dart Map (a dictionary of
  /// key-value pairs).
  ///
  /// Why we need this: JSON storage (e.g. SharedPreferences or a REST API)
  /// does not know about our custom Dart class. We must "serialise" the object
  /// into a format that storage understands — a Map<String, dynamic> (a map
  /// whose keys are Strings and whose values can be any type).
  ///
  /// Returns a [Map<String, dynamic>] with each field stored under its name
  /// as a string key. The `=>` arrow syntax is shorthand for `{ return {...}; }`.
  Map<String, dynamic> toJson() => {
        'id': id,                                   // store the id field under the key 'id'
        'stackId': stackId,                         // store stackId under 'stackId'
        'date': date,                               // store the date string
        'microActionsCompleted': microActionsCompleted, // store the boolean
        'completedAt': completedAt,                 // store the completion timestamp
      };

  /// A factory constructor that recreates a ComebackRecord from a Map.
  ///
  /// This is the reverse of `toJson`. When we load data from storage we get
  /// back a Map; this constructor reads each key out of that Map and builds
  /// a proper ComebackRecord object.
  ///
  /// Why `factory`? A regular constructor always calls `this(...)` to create
  /// a new instance. A `factory` constructor can contain arbitrary logic
  /// before deciding what to return — useful here because we need to read and
  /// cast each value from the Map before passing it to the real constructor.
  ///
  /// Parameter:
  ///   [json] — a Map<String, dynamic> that was previously produced by `toJson`
  ///            (or received from a JSON file / API response).
  ///
  /// Returns a new [ComebackRecord] populated with the values from [json].
  ///
  /// The `as String` / `as bool` casts tell Dart: "I know this dynamic value
  /// is actually a String (or bool) — please treat it that way." Without the
  /// cast, Dart would type the field as `dynamic` and lose type safety.
  factory ComebackRecord.fromJson(Map<String, dynamic> json) => ComebackRecord(
        id: json['id'] as String,                                       // read 'id' key, cast to String
        stackId: json['stackId'] as String,                             // read 'stackId', cast to String
        date: json['date'] as String,                                   // read 'date', cast to String
        microActionsCompleted: json['microActionsCompleted'] as bool,   // read boolean flag
        completedAt: json['completedAt'] as String,                     // read completion timestamp
      );
}
