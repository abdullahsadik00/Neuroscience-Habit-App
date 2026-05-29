// =============================================================================
// FILE: user_profile.dart
//
// This file defines the UserProfile data model — a plain Dart class that holds
// information about the current app user (their name and role).
//
// ROLE IN APP ARCHITECTURE:
//   - This is a "model" file. Models live in lib/models/ and represent
//     structured data. They don't know about the UI or Flutter widgets.
//   - Other files (providers, screens) import this class to read or update
//     user information throughout the app.
//   - It is typically stored in a Riverpod provider (state management layer)
//     and read by widgets that display or edit the user's profile.
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//   1. Dart class  — A blueprint for creating objects that hold related data.
//   2. final       — Once assigned, this field cannot be reassigned. It makes
//                    objects immutable (safe to share across the app).
//   3. const       — A compile-time constant: the value is known before the app
//                    runs, making it extremely fast and memory-efficient.
//   4. Immutability pattern — Instead of changing an object in place, we create
//                    a new copy with the changed fields (see copyWith below).
//                    This prevents hard-to-find bugs where one part of the app
//                    silently mutates data another part is reading.
//   5. Serialization — Converting an object to/from JSON (a text format) so it
//                    can be saved to disk or sent over the network.
// =============================================================================

/// Represents a single user's profile within the NeuroSync app.
///
/// This class is *immutable* — once created, its fields cannot change.
/// To "update" a profile, call [copyWith] to get a new instance with the
/// desired changes, leaving the original untouched.
///
/// Used by:
///   - Profile-related widgets (e.g., a settings screen showing the user's name)
///   - Riverpod providers that hold and expose the current user state
class UserProfile {
  /// The display name of the user (e.g., "Alex Johnson").
  /// Marked `final` so it can never be accidentally reassigned after creation.
  final String name;

  /// The user's role or occupation (e.g., "Software Engineer", "Student").
  /// Used to personalise habit suggestions or UI copy in the app.
  final String role;

  /// Constructor for UserProfile.
  ///
  /// `const` means Dart can evaluate this at compile time — useful for
  /// creating lightweight, reusable instances like [UserProfile.empty].
  ///
  /// `required` means callers *must* supply both [name] and [role]; Dart will
  /// give a compile error if either is missing. This prevents accidentally
  /// creating a profile with undefined fields.
  ///
  /// The `{...}` curly braces make these *named parameters*, so you call it as:
  ///   UserProfile(name: 'Alex', role: 'Engineer')
  /// rather than relying on positional order, which is clearer to read.
  const UserProfile({required this.name, required this.role});

  /// A pre-built "blank" UserProfile used as a safe default before real data loads.
  ///
  /// `static` means this belongs to the *class itself*, not to any instance.
  /// You access it as `UserProfile.empty` without ever creating an object first.
  ///
  /// `const` here means the object is created once at compile time and reused,
  /// rather than allocating new memory each time — important for performance in
  /// state management where defaults are checked frequently.
  static const UserProfile empty = UserProfile(name: '', role: '');

  /// Returns a *new* UserProfile that is identical to this one, except for any
  /// fields you explicitly override.
  ///
  /// This is the standard Flutter/Dart pattern for "updating" immutable objects.
  /// Because [name] and [role] are `final`, we cannot do `profile.name = 'Bob'`.
  /// Instead: `final updated = profile.copyWith(name: 'Bob');`
  ///
  /// Parameters:
  ///   [name]  — Optional new name. If omitted (null), the current name is kept.
  ///   [role]  — Optional new role. If omitted (null), the current role is kept.
  ///
  /// Returns a brand-new [UserProfile] instance with the merged values.
  ///
  /// The `?` after `String` means the parameter is *nullable* — it can be a
  /// String OR null. Passing null means "I don't want to change this field."
  UserProfile copyWith({String? name, String? role}) =>
      // `??` is the null-coalescing operator:
      //   `name ?? this.name` means "use the new name if provided, otherwise
      //   fall back to the existing name stored in this object."
      // `=>` is shorthand for a one-expression function body (no need for `{}`).
      UserProfile(name: name ?? this.name, role: role ?? this.role);

  /// Converts this UserProfile into a JSON-compatible Map so it can be saved
  /// to local storage (SharedPreferences) or sent to a server.
  ///
  /// `Map<String, dynamic>` is a Dart dictionary where keys are Strings and
  /// values can be any type (`dynamic`). JSON objects map directly to this type.
  ///
  /// Returns a Map like: `{'name': 'Alex', 'role': 'Engineer'}`
  ///
  /// This is called "serialization" — turning a structured object into a flat
  /// format that can be stored or transmitted.
  Map<String, dynamic> toJson() => {'name': name, 'role': role};

  /// Creates a UserProfile by reading values out of a JSON Map.
  ///
  /// This is the reverse of [toJson] — called "deserialization".
  /// Use this when you load saved data back from storage or receive it from
  /// a server.
  ///
  /// `factory` is a special Dart constructor keyword that lets the constructor
  /// return an existing instance or delegate creation logic. Here it reads the
  /// map and passes values into the normal constructor.
  ///
  /// Parameters:
  ///   [json] — A `Map<String, dynamic>` (typically parsed from a JSON string)
  ///            that must contain 'name' and 'role' keys.
  ///
  /// `json['name'] as String` reads the value for key 'name' from the map and
  /// casts it to a String. The `as String` cast is required because map values
  /// are typed as `dynamic` (unknown type) — we assert what type we expect.
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      UserProfile(name: json['name'] as String, role: json['role'] as String);
}
