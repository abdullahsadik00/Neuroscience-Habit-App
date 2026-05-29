// =============================================================================
// FILE: neurochemistry.dart
//
// What this file is: A plain Dart data model that holds the four neurochemical
// "scores" that the NeuroSync app tracks for each user.
//
// Role in app architecture:
//   - This is a pure MODEL — it has no UI code, no Flutter widgets, and no
//     network calls. It simply describes the shape of data.
//   - Other files (providers, screens) import this class to read or update
//     the user's neurochemical levels. For example, a Riverpod provider might
//     hold a `Neurochemistry` object and expose it to the UI.
//   - It can be serialised to/from JSON so it can be saved to local storage
//     (SharedPreferences) or sent to a server.
//
// Key concepts a learner needs to understand this file:
//   1. Dart classes — a blueprint that groups related data and behaviour.
//   2. `final` fields — once set in the constructor they cannot be changed.
//      This makes the object *immutable* (safe to share across the app).
//   3. `const` constructor — Dart can compute the object at compile time,
//      making it faster and memory-efficient.
//   4. Named parameters with `required` — callers must supply every field by
//      name, preventing accidentally mixed-up arguments.
//   5. `copyWith` pattern — the standard way to "update" an immutable object
//      by creating a new copy with only specific fields changed.
//   6. JSON serialisation — converting the object to/from a `Map<String, dynamic>`
//      so it can be stored as text (e.g., in device storage or an API).
// =============================================================================

/// Represents the current neurochemical state of a user in the NeuroSync app.
///
/// The app models four key neurotransmitters/neurochemicals as numeric scores
/// (0–100 scale). Habits completed by the user raise or lower these scores,
/// and the UI reflects the resulting "brain health" over time.
///
/// This class is *immutable*: none of its fields can be changed after the
/// object is created. To "update" levels, use [copyWith] to produce a new
/// instance with the desired values.
///
/// Used by: habit providers, progress screens, and any widget that displays
/// neurochemical stats.
class Neurochemistry {
  /// Dopamine level (0–100).
  ///
  /// Dopamine drives motivation and the reward loop — completing goals
  /// and building streaks should raise this value.
  final double dopamine;

  /// Acetylcholine level (0–100).
  ///
  /// Acetylcholine is associated with focus, learning, and neuroplasticity.
  /// Habits like reading or deep work target this neurotransmitter.
  final double acetylcholine;

  /// Epinephrine (adrenaline) level (0–100).
  ///
  /// Epinephrine governs energy and alertness. Exercise and cold-exposure
  /// habits are expected to modulate this score.
  final double epinephrine;

  /// GABA level (0–100).
  ///
  /// GABA is the brain's primary calming neurotransmitter — it reduces
  /// anxiety and promotes recovery. Meditation and sleep habits raise it.
  final double gaba;

  /// Creates a [Neurochemistry] instance with all four levels explicitly set.
  ///
  /// All parameters are *required* and *named*, meaning callers must write:
  ///   Neurochemistry(dopamine: 65, acetylcholine: 55, ...)
  /// rather than positional arguments, which prevents accidental mix-ups.
  ///
  /// The `const` keyword means Dart can evaluate this at compile time when
  /// all values are also compile-time constants, saving memory at runtime.
  const Neurochemistry({
    required this.dopamine,       // must be provided — no default
    required this.acetylcholine,  // must be provided — no default
    required this.epinephrine,    // must be provided — no default
    required this.gaba,           // must be provided — no default
  });

  /// The starting neurochemical state shown to a new user on first launch.
  ///
  /// Values are intentionally above the [baseline] midpoint (50) to give
  /// new users a sense of momentum rather than starting from scratch.
  ///
  /// `static` means this belongs to the *class itself*, not to any single
  /// instance — access it as `Neurochemistry.initial`, not on an object.
  /// `const` makes it a compile-time constant (zero runtime cost to access).
  static const Neurochemistry initial = Neurochemistry(
    dopamine: 65,       // slightly above baseline — gives new users a head start
    acetylcholine: 55,  // moderate focus level at onboarding
    epinephrine: 50,    // neutral energy at the start
    gaba: 60,           // calm baseline — reduces early-app anxiety
  );

  /// The neutral midpoint — all four chemicals at exactly 50.
  ///
  /// Useful as a reference point for calculations (e.g., "how far above/below
  /// neutral is the user right now?") or as a reset target.
  static const Neurochemistry baseline = Neurochemistry(
    dopamine: 50,       // neutral dopamine — neither depleted nor elevated
    acetylcholine: 50,  // neutral acetylcholine
    epinephrine: 50,    // neutral energy
    gaba: 50,           // neutral calm
  );

  /// Returns a *new* [Neurochemistry] object with selected fields replaced.
  ///
  /// Because fields are `final` (immutable), you cannot write
  /// `myLevels.dopamine = 70`. Instead call:
  ///   `myLevels.copyWith(dopamine: 70)`
  /// and you get back a fresh object with that one field changed and all
  /// others preserved.
  ///
  /// Parameters (all optional — omit any you do not want to change):
  ///   [dopamine]       — new dopamine value, or null to keep current
  ///   [acetylcholine]  — new acetylcholine value, or null to keep current
  ///   [epinephrine]    — new epinephrine value, or null to keep current
  ///   [gaba]           — new gaba value, or null to keep current
  ///
  /// Returns: a brand-new [Neurochemistry] with the merged values.
  ///
  /// The `=>` syntax is Dart's "expression body" shorthand — it means
  /// "this method returns the single expression on the right".
  Neurochemistry copyWith({
    double? dopamine,       // `double?` means "a double OR null" (nullable type)
    double? acetylcholine,  // null signals "do not change this field"
    double? epinephrine,
    double? gaba,
  }) =>
      Neurochemistry(
        // `??` is the null-coalescing operator:
        //   left ?? right  →  if left is NOT null, use left; otherwise use right
        // So: use the caller-supplied value if given, else keep the current one.
        dopamine: dopamine ?? this.dopamine,
        acetylcholine: acetylcholine ?? this.acetylcholine,
        epinephrine: epinephrine ?? this.epinephrine,
        gaba: gaba ?? this.gaba,
      );

  /// Converts this object into a plain Dart `Map` (key-value pairs) so it
  /// can be encoded as JSON for storage or network transmission.
  ///
  /// `Map<String, dynamic>` — a dictionary where keys are strings and values
  /// can be any type (`dynamic`). This is the standard interchange format
  /// for JSON in Dart.
  ///
  /// Returns: a `Map` like `{"dopamine": 65.0, "acetylcholine": 55.0, ...}`.
  ///
  /// Callers typically pass the result to `jsonEncode()` or
  /// `SharedPreferences.setString()`.
  Map<String, dynamic> toJson() => {
        'dopamine': dopamine,       // store each level under a string key
        'acetylcholine': acetylcholine,
        'epinephrine': epinephrine,
        'gaba': gaba,           // store gaba level under its string key
      };

  /// Reconstructs a [Neurochemistry] object from a previously-serialised `Map`.
  ///
  /// This is a *factory constructor* — the `factory` keyword means Dart does
  /// not automatically allocate a new object; the constructor itself decides
  /// what to return (useful for parsing, caching, or validation).
  ///
  /// Parameter:
  ///   [json] — a `Map<String, dynamic>` typically produced by
  ///            `jsonDecode(someString)` or read from SharedPreferences.
  ///
  /// Returns: a fully-populated [Neurochemistry] instance.
  ///
  /// Why `(json['dopamine'] as num).toDouble()`?
  ///   JSON numbers can arrive as either `int` or `double` depending on
  ///   whether they have a decimal point. Casting to `num` (the parent type
  ///   of both) and then calling `.toDouble()` guarantees we always get a
  ///   `double`, regardless of how the value was originally stored.
  factory Neurochemistry.fromJson(Map<String, dynamic> json) => Neurochemistry(
        dopamine: (json['dopamine'] as num).toDouble(),           // safe int→double cast
        acetylcholine: (json['acetylcholine'] as num).toDouble(), // same pattern
        epinephrine: (json['epinephrine'] as num).toDouble(),
        gaba: (json['gaba'] as num).toDouble(),
      );
}
