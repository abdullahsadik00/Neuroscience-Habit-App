# NeuroFlow — Flutter Mobile App

Flutter port of the NeuroFlow web app. Same full feature set: Habit Stacks, Neuro Swaps, Neurochemistry HUD, Brain Assessment, Comeback Protocol, Weekly Check-ins, and Recalibration Engine.

## Setup (Flutter not installed yet)

### 1. Install Flutter
```bash
# macOS — using fvm (recommended) or direct download
brew install fvm
fvm install stable
fvm global stable

# Or: https://docs.flutter.dev/get-started/install/macos
```

### 2. Bootstrap the project
```bash
cd flutter_app

# Create the Flutter project scaffold (Android/iOS boilerplate)
flutter create . --project-name neuroflow --org com.neuroflow --platforms ios,android

# Install dependencies
flutter pub get
```

> `flutter create .` will generate platform folders but won't overwrite the existing `lib/` code.

### 3. Run the app
```bash
flutter run          # runs on connected device / simulator
flutter run -d chrome  # runs as web (also supported)
```

## Stack

| Concern | Library |
|---|---|
| State | `flutter_riverpod` 2.x (`Notifier`) |
| Persistence | `shared_preferences` (JSON, mirrors web localStorage) |
| Animations | `flutter_animate` |
| Fonts | `google_fonts` (Inter) |
| IDs | `uuid` |

## Project structure

```
lib/
├── main.dart              # Preloads SharedPreferences, bootstraps ProviderScope
├── app.dart               # MaterialApp + _AppRouter (mirrors App.tsx)
├── theme/app_theme.dart   # Dark + light ThemeData, neurochemical colours
├── models/                # All data models with toJson/fromJson
├── providers/
│   └── neuro_provider.dart  # NeuroNotifier (single Riverpod Notifier, mirrors Zustand store)
├── utils/                 # Ported 1:1 from TS: neuro_helpers, stats_helpers, etc.
├── data/habit_library.dart  # Full 30-habit library
├── pages/                 # Onboarding → BrainAssessment → RoutineBlueprint → Dashboard
└── widgets/               # HabitCard, SwapCard, NeurochemHUD, ComebackProtocol, etc.
```

## Feature parity with web app

- [x] Onboarding (name + role selection + science explainer)
- [x] 8-question Brain Assessment → NeuroBrainProfile
- [x] Routine Blueprint (scored habit matching + accept/deselect)
- [x] Dashboard with 3 tabs: Habits / Swaps / Activity
- [x] Neurochemistry HUD (Dopamine, ACh, Epinephrine, GABA bars)
- [x] Stats bar (Brain Score, Best Streak, Days In, Recovery %)
- [x] Habit cards with weekly grid, myelination bar, streak
- [x] Swap cards with urge surf / slip logging + friction barriers
- [x] Comeback Protocol banner (3/month gate for free users)
- [x] Weekly Check-In modal (consistency, blocker, energy, context)
- [x] Recalibration Engine (SCALE_DOWN / REPLACE / UPDATE_MICRO suggestions)
- [x] Recovery Playbook insights
- [x] Add habit from library (30 habits) or custom
- [x] Add swap (custom)
- [x] Activity log with neurochemical change display
- [x] Dark / light theme toggle (persisted via Riverpod)
- [x] Full local persistence via SharedPreferences
