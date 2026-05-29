// =============================================================================
// FILE: models.dart
//
// What this file is: A "barrel" export file — a single entry-point that
// re-exports every data-model file in the models/ folder.
//
// Role in app architecture:
//   Instead of writing a long list of individual imports in every file that
//   needs a model (e.g. `import 'neuro_stack.dart'; import 'neuro_log.dart';`),
//   other files can write just ONE import:
//     import 'package:neurosync/models/models.dart';
//   and get access to ALL models at once. This keeps imports DRY (Don't Repeat
//   Yourself) and makes it easy to reorganise files later without updating
//   dozens of import statements across the app.
//
// Key concept — Dart `export`:
//   The `export` keyword works like `import` in reverse. When file A exports
//   file B, anyone who imports A also gets everything that B defines —
//   without needing to know B exists. Think of this file as a "shop window"
//   for the entire models layer.
//
// How this fits the overall architecture:
//   UI Widgets  -->  Riverpod Providers  -->  models/models.dart
//                                               ├── neuro_stack.dart
//                                               ├── neuro_swap.dart
//                                               ├── neuro_log.dart
//                                               ├── comeback_record.dart
//                                               ├── neurochemistry.dart
//                                               ├── user_profile.dart
//                                               ├── brain_profile.dart
//                                               ├── checkin_record.dart
//                                               └── recalibration.dart
// =============================================================================

// Re-export the NeuroStack model (a habit "stack" — cue → action → reward).
// Any file importing models.dart automatically gets NeuroStack and HabitCategory.
export 'neuro_stack.dart';

// Re-export the NeuroSwap model (a bad-habit replacement plan with friction steps).
export 'neuro_swap.dart';

// Re-export the NeuroLog model (an activity-log entry) and the LogType enum.
export 'neuro_log.dart';

// Re-export the ComebackRecord model (a single habit-recovery event).
export 'comeback_record.dart';

// Re-export the Neurochemistry model (dopamine / acetylcholine / epinephrine / GABA levels).
export 'neurochemistry.dart';

// Re-export the UserProfile model (user's name and role).
export 'user_profile.dart';

// Re-export the NeuroBrainProfile model plus all its enums
// (FailureStyle, PeakEnergyWindow, RecoverySpeed, etc.).
export 'brain_profile.dart';

// Re-export the CheckinRecord model and the EnergyLevel enum.
export 'checkin_record.dart';

// Re-export RecalibrationSuggestion, RecalibrationEvent, and the SuggestionType enum.
export 'recalibration.dart';
