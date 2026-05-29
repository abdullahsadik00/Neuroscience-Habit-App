# NeuroSync — Implementation Checklist
## Feature Sprint: Investor-Grade Product Improvements

> Generated from plan: 4 high-impact features to transform NeuroSync from a habit tracker into an autonomous behavioral coach.

---

## Feature 1: Predictive Pre-covery
*Proactive failure intervention — warns users before their worst habit day strikes.*

- [x] Add `_idPreCoveryEvening = 5` and `_idPreCoveryMorning = 6` constants to `notification_service.dart`
- [x] Implement `schedulePreCoveryNudge({required String habitTitle, required String worstDay})` in `notification_service.dart`
- [x] Implement `cancelPreCoveryNudges()` in `notification_service.dart`
- [x] Add `_schedulePreCovery()` private method to `NeuroNotifier` in `neuro_provider.dart`
- [x] Call `_schedulePreCovery()` after `logSlip()` and on state load when failure data is mature

---

## Feature 2: Dynamic Elasticity — Lite Mode Today
*Instant habit downscaling for today only, preventing the miss entirely.*

- [x] Add `liteModeDates: List<String>` field to `NeuroStack` model in `neuro_stack.dart`
- [x] Update `copyWith()` in `NeuroStack` to include `liteModeDates`
- [x] Update `toJson()` in `NeuroStack` to include `'liteModeDates': liteModeDates`
- [x] Update `fromJson()` in `NeuroStack` to parse `liteModeDates` with null fallback
- [x] Add `activateLiteMode(String habitId)` method to `NeuroNotifier` in `neuro_provider.dart`
- [x] Add `onLiteMode: VoidCallback?` callback parameter to `HabitCard` in `habit_card.dart`
- [x] Add "Lite Mode today" option to `HabitCard` popup menu
- [x] Show blue "Lite Mode" badge in `HabitCard` header when active today
- [x] Change Complete button label to "Complete Lite Version" when lite mode is active
- [x] Pass `onLiteMode` callback in `_HabitsTab` inside `dashboard_page.dart`

---

## Feature 3: Recovery Heatmap Share Card
*GitHub-style 28-day comeback grid — comebacks glow gold, the badge of resilience.*

- [x] Rewrite `ShareCard` constructor to accept `stacks` and `comebacks` instead of pre-computed stats
- [x] Implement 28-day heatmap grid computation in `share_card.dart` (28 days × cell states)
- [x] Color-code cells: completed=green, comeback=gold, liteMode=sky-blue, missed=dark-red, empty=subtle
- [x] Add legend row below grid (4 colored dots with labels)
- [x] Update stats row to 3 compact stats (Recovery Rate, Best Streak, Total Comebacks)
- [x] Update `_showShareSheet` in `dashboard_page.dart` to pass `stacks` and `comebacks`
- [x] Update `_ShareSheet` private class in `dashboard_page.dart` to accept and forward new params

---

## Feature 4: Resilience Score HUD
*Replace fake neurochemistry bars with a proprietary Adaptability Score that rewards recovery behaviors.*

- [x] Create `lib/utils/resilience_score.dart` with `calcResilienceScore()` pure function
- [x] Implement scoring: +50 comeback (complete), +20 comeback (ack), +30 urge surf, +15 lite mode, +10 check-in
- [x] Implement `getResilienceLabel(int score)` returning tier names
- [x] Implement `getResilienceTip(int score, NeuroBrainProfile? profile)` returning coaching tip
- [x] Create `lib/widgets/resilience_hud.dart` with arc-based score visualization
- [x] Replace `NeurochemHUD` with `ResilienceHUD` in `dashboard_page.dart`
- [x] Import `resilience_score.dart` and `resilience_hud.dart` in `dashboard_page.dart`
- [x] Remove unused `neurochem_hud.dart` import from `dashboard_page.dart`

---

## PRD & Docs
- [x] Update `PRD.md` version to 1.1 and date to May 2026
- [x] Replace Section 3.4 (Neurochemistry HUD) with Adaptability Score description
- [x] Add Section 3.7: Predictive Pre-covery
- [x] Add Section 3.8: Dynamic Elasticity — Lite Mode Today
- [x] Add Section 3.9: Recovery Heatmap
- [x] Update Section 5.4 (Dashboard) to reference ResilienceHUD
- [x] Update Section 5.5 (Habit Card) to include Lite Mode Today feature
- [x] Update Section 6.1 (Data Model) to add `liteModeDates` field to `NeuroStack`
- [x] Update Section 11 (Roadmap Phase 2) to include the 4 new features

---

## Git
- [ ] `flutter analyze` passes with no errors
- [ ] Commit: `feat: predictive pre-covery, lite mode, resilience hud, heatmap share card`
- [ ] Push to remote
