// =============================================================================
// FILE: brain_profile.dart
//
// This file defines the data model for a user's "NeuroBrainProfile" — the
// result of an onboarding quiz that captures the user's neuroscience-based
// behavioral traits.
//
// ROLE IN APP ARCHITECTURE:
//   - This is a pure "model" file — it holds data shapes only, no UI code.
//   - Other files (providers, screens) import NeuroBrainProfile to read/write
//     profile data. Think of it as the blueprint for what a profile looks like.
//   - The model is saved to device storage (SharedPreferences) as JSON via
//     toJson(), and loaded back via fromJson().
//
// KEY CONCEPTS TO KNOW:
//   - enum: A fixed list of named options (like a dropdown with set choices).
//   - class: A blueprint for creating objects that group related data together.
//   - final: A field that can only be set once (immutable after construction).
//   - const constructor: Creates objects at compile-time; saves memory when the
//     same values are reused.
//   - JSON serialization: Converting a Dart object ↔ a Map of key/value pairs
//     so it can be stored as text or sent over a network.
//   - factory constructor: A special constructor that can contain logic before
//     returning the new object (used here to safely parse JSON).
// =============================================================================

// No external packages are imported — this file uses only plain Dart, which is
// built-in. Dart is the programming language Flutter apps are written in.

// -----------------------------------------------------------------------------
// ENUMS — Fixed sets of choices
//
// An enum (short for "enumeration") is like a strict multiple-choice list.
// Instead of storing raw strings like "perfectionist" (which can be typo'd),
// we use enum values that the compiler validates at build time.
// Each enum below maps to one question from the onboarding brain quiz.
// -----------------------------------------------------------------------------

/// Describes how a user typically responds when they break a habit streak.
/// This is used to personalise coaching messages and recovery suggestions.
enum FailureStyle {
  perfectionist, // User sets unrealistically high standards; any slip feels catastrophic
  avoider,       // User avoids confronting the missed habit entirely and moves on
  analyst,       // User over-analyses what went wrong but struggles to restart
  drifter,       // User simply loses track and drifts away without a clear trigger
}

/// The time of day when the user naturally has the most mental energy.
/// Used to schedule habit reminders at the most effective moments.
enum PeakEnergyWindow {
  morning,   // User is sharpest in the morning (before noon)
  afternoon, // User hits peak focus in the early-to-mid afternoon
  evening,   // User does their best work later in the day
  variable,  // User's energy levels are unpredictable day-to-day
}

/// How quickly the user bounces back after a setback or missed habit.
/// Slower recovery users need gentler nudges; faster ones can handle more challenge.
enum RecoverySpeed {
  fast,     // User gets back on track within a day or two
  medium,   // User typically needs a few days to re-engage
  slow,     // User can stay off-track for weeks after a slip
  variable, // Recovery speed changes depending on context
}

/// The main obstacle that most often derails the user's habits.
/// Drives which type of support or tip is shown inside the app.
enum PrimaryBlocker {
  energy,      // User's biggest barrier is physical or mental fatigue
  overwhelm,   // User feels paralysed by too many competing demands
  distraction, // User is easily pulled away by phones, notifications, etc.
  life,        // External life events (family, work crises) disrupt routines
}

/// How the user talks to themselves after failing or struggling.
/// Used to tailor the tone of in-app coaching copy.
enum SelfTalkPattern {
  selfCritical, // User is harsh on themselves; inner critic is dominant
  avoidant,     // User tries not to think about failures at all
  rational,     // User is balanced and analytical about their shortcomings
  hopeless,     // User slides into "what's the point" thinking after setbacks
}

/// What primarily motivates the user to build habits in the first place.
/// Shapes which type of rewards and progress framing resonate most.
enum MotivationSource {
  identity, // Motivation comes from "I want to be the kind of person who..."
  outcome,  // Motivation comes from a specific goal or end result
  process,  // Motivation comes from enjoying the routine itself
  survival, // Motivation comes from necessity — things will get worse if they don't act
}

/// How the user prefers to stay accountable to their habits.
/// Determines which accountability features are highlighted in the app.
enum AccountabilityStyle {
  tracking,  // User likes logging and seeing data/streaks
  external,  // User needs a friend, coach, or partner to stay on track
  systems,   // User relies on environment design (reminders, cues, schedules)
  none,      // User does not find accountability tools helpful
}

/// The deepest underlying reason the user wants to improve their habits.
/// The most fundamental motivational layer — used for personalised onboarding copy.
enum CoreDriver {
  feelBetter,     // Wants to improve mood, reduce anxiety, or boost wellbeing
  performBetter,  // Wants to be more productive or achieve better results
  becomeSomeone,  // Has an identity goal — wants to see themselves differently
  survive,        // Is in a difficult situation and habits are a coping mechanism
}

// -----------------------------------------------------------------------------
// NeuroBrainProfile — The main data model class
// -----------------------------------------------------------------------------

/// Represents the complete neuroscience-based profile of a single user,
/// collected during the onboarding quiz.
///
/// This class is an immutable "data object" — once created, its values never
/// change. To update a profile, you create a new NeuroBrainProfile instance.
///
/// It is used by:
///   - The onboarding screen (to build and save a profile from quiz answers)
///   - Providers (to hold the current user's profile in app state)
///   - Habit screens (to personalise tips, messages, and scheduling)
class NeuroBrainProfile {
  // ---------------------------------------------------------------------------
  // FIELDS — each field stores one dimension of the user's brain profile.
  // 'final' means these values are set once in the constructor and never changed.
  // ---------------------------------------------------------------------------

  final FailureStyle failureStyle; // How the user responds when they miss a habit

  final PeakEnergyWindow peakEnergyWindow; // The time of day the user is most focused

  final RecoverySpeed recoverySpeed; // How quickly the user bounces back from setbacks

  final PrimaryBlocker primaryBlocker; // The main obstacle that derails their habits

  final SelfTalkPattern selfTalkPattern; // The user's inner dialogue style after failure

  final MotivationSource motivationSource; // What drives the user to build habits

  final AccountabilityStyle accountabilityStyle; // How the user likes to stay accountable

  final CoreDriver coreDriver; // The user's deepest reason for wanting to improve

  final String completedAt; // ISO-8601 timestamp string recording when the quiz was finished
                            // e.g. "2026-05-29T10:30:00.000Z"

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  //
  // A constructor is a special function that runs when you create a new object
  // from this class. 'const' means Dart can evaluate this at compile-time for
  // better performance. 'required' means the caller MUST provide every field —
  // none are optional here because a profile is only complete when all answers
  // are present.
  // ---------------------------------------------------------------------------

  /// Creates a fully populated NeuroBrainProfile.
  /// Every parameter is required — a profile must have all answers to be valid.
  const NeuroBrainProfile({
    required this.failureStyle,       // Must pass a FailureStyle enum value
    required this.peakEnergyWindow,   // Must pass a PeakEnergyWindow enum value
    required this.recoverySpeed,      // Must pass a RecoverySpeed enum value
    required this.primaryBlocker,     // Must pass a PrimaryBlocker enum value
    required this.selfTalkPattern,    // Must pass a SelfTalkPattern enum value
    required this.motivationSource,   // Must pass a MotivationSource enum value
    required this.accountabilityStyle,// Must pass an AccountabilityStyle enum value
    required this.coreDriver,         // Must pass a CoreDriver enum value
    required this.completedAt,        // Must pass a timestamp string
  });

  // ---------------------------------------------------------------------------
  // toJson() — Serialise this object to a Map (for storage)
  //
  // "Serialisation" means converting a Dart object into a simpler format that
  // can be stored or transmitted. Here we convert to a Map<String, dynamic>
  // (a dictionary of key → value pairs), which can then be encoded as a JSON
  // string and saved to SharedPreferences (the device's local key-value store).
  //
  // We store enum values using their .name property, which gives the enum
  // value's identifier as a plain string (e.g. FailureStyle.perfectionist.name
  // gives "perfectionist"). This is reversible — we can look up the enum by
  // name again in fromJson().
  // ---------------------------------------------------------------------------

  /// Converts this NeuroBrainProfile into a plain Map of strings.
  /// Call this before saving the profile to local storage.
  /// Returns a Map<String, dynamic> where each key is a field name and each
  /// value is either the enum's name string or a plain string.
  Map<String, dynamic> toJson() => {
        // .name is a built-in Dart enum property that returns the enum value
        // as a String. e.g. FailureStyle.perfectionist.name == "perfectionist"
        'failureStyle': failureStyle.name,
        'peakEnergyWindow': peakEnergyWindow.name,
        'recoverySpeed': recoverySpeed.name,
        'primaryBlocker': primaryBlocker.name,
        'selfTalkPattern': selfTalkPattern.name,
        'motivationSource': motivationSource.name,
        'accountabilityStyle': accountabilityStyle.name,
        'coreDriver': coreDriver.name,
        'completedAt': completedAt, // already a plain String — no conversion needed
      };

  // ---------------------------------------------------------------------------
  // fromJson() — Deserialise a Map back into a NeuroBrainProfile
  //
  // This is a "factory constructor" — it looks like a constructor but can run
  // arbitrary logic before returning the object. We use it here to safely parse
  // a JSON Map (loaded from device storage) back into a NeuroBrainProfile.
  //
  // The main challenge: the stored JSON has strings like "perfectionist", but
  // we need the actual enum value FailureStyle.perfectionist. The local helper
  // function `pick` handles this lookup for every enum field.
  // ---------------------------------------------------------------------------

  /// Rebuilds a NeuroBrainProfile from a JSON Map (e.g. loaded from storage).
  ///
  /// [json] — A Map<String, dynamic> previously produced by toJson().
  ///
  /// Returns a new NeuroBrainProfile instance. If any field's stored string
  /// doesn't match a known enum value (e.g. data was corrupted), a safe
  /// fallback value is used instead of crashing the app.
  factory NeuroBrainProfile.fromJson(Map<String, dynamic> json) {
    // -------------------------------------------------------------------------
    // LOCAL HELPER FUNCTION: pick<T>
    //
    // This is a generic helper defined inside fromJson — it only exists within
    // this method, keeping the code tidy.
    //
    // Generic means it works with any type T (FailureStyle, PeakEnergyWindow,
    // etc.) — we pass in the specific type when we call it below.
    //
    // What it does:
    //   1. Takes the full list of valid enum values (e.g. FailureStyle.values)
    //   2. Searches that list for the one whose .name matches the stored string
    //   3. If found, returns that enum value; if not found, returns the fallback
    // -------------------------------------------------------------------------

    /// Searches [values] for an enum entry whose .name matches [name].
    /// Returns [fallback] if no match is found or if an error occurs.
    /// [T] is the enum type (inferred automatically by Dart at the call site).
    T pick<T>(List<T> values, String name, T fallback) {
      try {
        // firstWhere() scans the list and returns the first element that
        // satisfies the test. If none match, it calls orElse() instead.
        // We cast to (dynamic) so we can access the .name property, which
        // is an enum feature not directly visible on a generic type T.
        return (values as List<dynamic>).firstWhere(
          (v) => (v as dynamic).name == name, // test: does this value's name match?
          orElse: () => fallback,              // if nothing matches, return the safe default
        ) as T; // cast the result back to T so Dart is happy with the type
      } catch (_) {
        // The underscore _ means "I don't care about the error details".
        // If anything unexpected goes wrong (e.g. null value), return fallback.
        return fallback;
      }
    }

    // -------------------------------------------------------------------------
    // BUILD AND RETURN THE OBJECT
    //
    // Now we call pick() once for each enum field, passing:
    //   1. The enum's .values list (all valid options for that enum)
    //   2. The string stored in the JSON map under the matching key
    //   3. A sensible fallback in case the stored string is unrecognised
    //
    // json['key'] as String — reads the value from the map and casts it to
    // String. The 'as String' cast tells Dart "trust me, this is a String".
    // -------------------------------------------------------------------------

    return NeuroBrainProfile(
      failureStyle: pick(FailureStyle.values, json['failureStyle'] as String, FailureStyle.drifter),
      // Fallback: drifter — neutral default if the stored value is unreadable

      peakEnergyWindow: pick(PeakEnergyWindow.values, json['peakEnergyWindow'] as String, PeakEnergyWindow.morning),
      // Fallback: morning — most common peak window

      recoverySpeed: pick(RecoverySpeed.values, json['recoverySpeed'] as String, RecoverySpeed.medium),
      // Fallback: medium — middle-of-the-road assumption

      primaryBlocker: pick(PrimaryBlocker.values, json['primaryBlocker'] as String, PrimaryBlocker.distraction),
      // Fallback: distraction — common blocker for most people

      selfTalkPattern: pick(SelfTalkPattern.values, json['selfTalkPattern'] as String, SelfTalkPattern.rational),
      // Fallback: rational — the most neutral self-talk style

      motivationSource: pick(MotivationSource.values, json['motivationSource'] as String, MotivationSource.outcome),
      // Fallback: outcome — goal-oriented motivation is a safe default

      accountabilityStyle: pick(AccountabilityStyle.values, json['accountabilityStyle'] as String, AccountabilityStyle.tracking),
      // Fallback: tracking — the most common in-app accountability mode

      coreDriver: pick(CoreDriver.values, json['coreDriver'] as String, CoreDriver.performBetter),
      // Fallback: performBetter — achievement-oriented default

      completedAt: json['completedAt'] as String,
      // No fallback needed — this is a plain String, not an enum
    );
  }
}
