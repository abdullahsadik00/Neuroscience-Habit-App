# Product Understanding: NeuroSync Habit App
*Audit Phase 1 — Product Understanding*
*Date: 2026-05-29*

---

## 1. App Summary

NeuroSync is a habit recovery system — not a habit-building tracker — for people who have already tried and failed at habit apps. Its defining premise is that the moment of failure (missing a habit) is more important than the moment of success. Where every mainstream habit app surfaces a broken streak and implicitly punishes the user, NeuroSync surfaces a structured re-entry protocol called the Comeback Protocol when a habit is missed. The primary user-facing metric is Recovery Rate (percentage of comeback activations where micro-actions were completed), not streak length or daily active minutes.

The app has two production codebases that implement the same product: a React 19/TypeScript PWA (src/) and a Flutter mobile app (flutter_app/). Both implement the same core loop: psychological profiling via an 8-question Brain Assessment, auto-assignment of matched habits via a blueprint engine, daily habit tracking with a myelination progress metaphor, and a personalised Comeback Protocol modal that fires when habits are missed. A live neurochemistry HUD (Dopamine, Acetylcholine, Epinephrine, GABA) models brain state and updates in response to every user action. A weekly check-in feeds a Recalibration Engine that can suggest downscaling, replacing, or adapting habits.

What differentiates NeuroSync technically is the depth of personalisation layered under the surface. The `NeuroBrainProfile` — derived from 8 assessment questions — feeds at least five downstream systems: the blueprint scoring engine (`blueprintEngine.ts`), the comeback reframe copy (`brainHelpers.ts` `getBrainAwareReframe()`), the micro-action set (`getBrainAwareMicroActions()`), the recalibration engine's UPDATE_MICRO trigger, and the archetype name shown in the Brain Profile card. The habit library (`habitLibrary.ts`, 37 templates on web; `habit_library.dart`, 20 templates on Flutter) is tagged with profile dimensions so the blueprint engine can score and rank habits against the user's profile at first launch, eliminating the blank-state problem that kills activation in most habit apps.

---

## 2. Target Audience

### Stated Target (from PRD)

Execution-focused individuals aged 25–40 who identify as builders, engineers, designers, or ambitious professionals. They have tried and abandoned habit apps before (Streaks, Habitica, Notion dashboards). They have strong intrinsic motivation but inconsistent execution. The PRD's psychographic: "They don't lack discipline. They lack a recovery system." Secondary markers: they discuss productivity and self-improvement publicly (social-media-fluent), they would respond to neuroscience framing, and they have a high tolerance for onboarding depth (8-question assessment before using the app).

### Inferred Target (from code/features)

The code confirms and sharpens the PRD's audience claim. The onboarding role options are Builder, Designer, Athlete, Student, and Other — the habit suggestions for each role (in `Onboarding.tsx` `SUGGESTIONS`) are technology-and-craft-worker oriented: deep work blocks, no-phone-first-hour, end-of-day shutdown, morning sketching, design reference batching. The role-specific suggestions are absent for "Other," which falls back to generic grounding/movement/reflection habits, suggesting "Other" is not the primary target. The Brain Assessment's answer copy assumes a self-reflective, analytically literate user (e.g., Q1: "One data point doesn't define the pattern" is one of the recovery reframes — this is cognitive-behavioral framing that resonates with analytical thinkers). The upgrade page (`upgrade_page.dart`) social proof copy ("Pro users recover 2.3x faster. Average recovery days drop from 4.1 → 1.8 days") uses numeric framing, reinforcing the analytically-oriented audience. The freemium gate (3 comebacks/month, 2 habits max) is designed to convert users who are already engaged with the comeback mechanic — meaning the app presupposes users miss habits regularly, which is a realistic assumption only for people actively tracking habits.

### Target Persona Summary

| Persona | Age | Context | Core Problem | What They Track Today |
|---------|-----|---------|--------------|----------------------|
| The Burnt-Out Builder | 27–33 | Software engineer or indie developer; async, remote work | Starts every productivity system with high motivation, abandons after first off-week; shame about not shipping | Streaks app, Notion habit tables, or nothing |
| The Ambitious Designer | 25–35 | UX/product designer or creative professional | Identifies with discipline but has irregular creative energy; beat themselves up after missed creative rituals | Nothing formal; loose journaling |
| The Analytical Professional | 28–40 | Data, finance, or operations worker | Overthinks habit design, never executes consistently; wants to understand "why" before committing | Spreadsheets, Habitica, or podcast-driven systems they never stick to |

---

## 3. Core Problem Statement

### Problem Being Solved

The core problem is the aftermath of missing a habit, not the habit itself. Every mainstream habit tracker — by design — makes a missed day visible as a broken streak. This creates a shame → avoidance → abandonment loop. The user's identity as "someone trying to build this habit" collapses at the first visible failure. The PRD cites Lally et al. (2010) to make the point that a single missed day has no significant effect on habit automaticity — the harm is entirely psychological, caused by the streak framing, not the miss itself.

Without NeuroSync, a user who misses three days of morning journaling opens their habit app, sees a 0-day streak, feels the psychological cost of the reset, and either forces a hollow "I'll start again today" entry or, more commonly, stops opening the app. There is no system for this failure mode — just a counter that measures it.

### Current User Workarounds

Users either abandon tracking entirely after a miss (confirmed by the PRD's observation that prior app abandonment is a pre-qualification for the target persona), or they manually reset streak counts to avoid the psychological sting (Streaks, Habitica, Bereal all have "miss forgiveness" features that users hack). Some users use Notion or Obsidian to track habits in a custom format that de-emphasises streaks, but these require manual setup and have no adaptive intelligence. Journaling apps (Day One, Notion) provide no accountability structure at all.

### The App's Proposed Solution

NeuroSync replaces the streak-reset moment with the Comeback Protocol modal (`ComebackProtocol.tsx`, `comeback_protocol` widget in Flutter). When `getMissedStacks()` in `comebackHelpers.ts` detects that a habit was not completed yesterday and has not been completed or acknowledged today, the protocol fires automatically on dashboard load. It presents a CBT reframe headline personalised by `failureStyle` (e.g., "Your standard didn't drop. The day did." for perfectionist types), followed by 3 energy-aware micro-actions keyed to `peakEnergyWindow` and `primaryBlocker`. Completing any one micro-action triggers `acknowledgeComeback()` in the store, which logs the comeback, awards neurochemical points, and increments the Recovery Rate metric. The system reframes the miss as data and the re-entry as a first-class accomplishment. The Recovery Playbook (`RecoveryPlaybook.tsx`) then accumulates these comeback records into a visible personal history of recovery patterns.

---

## 4. Complete Feature Inventory

| # | Feature | Description | Platform | Status | Key File(s) |
|---|---------|-------------|----------|--------|-------------|
| 1 | 4-Screen Onboarding | Welcome + name/role setup + first habit selection + Comeback Protocol explainer | Web, Flutter | Shipped | `Onboarding.tsx`, `onboarding_page.dart` |
| 2 | Brain Assessment | 8-question psychological profile interview, 1 question at a time, auto-advance on tap | Web, Flutter | Shipped | `BrainAssessment.tsx`, `brain_assessment_page.dart` |
| 3 | Profile Reveal | Post-assessment reveal: archetype name (16 possible), 4 insight cards, 6-dimension summary | Web, Flutter | Shipped | `BrainAssessment.tsx` reveal phase, `brain_assessment_page.dart` `_RevealPage` |
| 4 | NeuroRoutine Blueprint | Auto-assigned starter routine of 3–5 habits scored against brain profile and neurochemistry; swap/remove UI | Web, Flutter | Shipped | `RoutineBlueprint.tsx`, `routine_blueprint_page.dart`, `blueprintEngine.ts`, `blueprint_engine.dart` |
| 5 | Habit Library | 37 `HabitTemplate` objects (web) / 20 `HabitTemplate` objects (Flutter) tagged with profile dimensions and neurochemical targets | Web, Flutter | Shipped (parity gap) | `habitLibrary.ts`, `habit_library.dart` |
| 6 | Dashboard | Full home screen: header, neurochemistry HUD, stats bar, brain profile card, recovery playbook, tabs (Habits / Swaps / Activity) | Web, Flutter | Shipped | `Dashboard.tsx`, `dashboard_page.dart` |
| 7 | Neurochemistry HUD | Live DA/ACh/EPI/GABA progress bars; tap-to-expand science explainer + today's movement log | Web, Flutter | Shipped | `NeurochemHUD.tsx`, `neurochem_hud.dart` |
| 8 | Habit Cards (Neuro-Stacks) | Per-habit card: category badge, streak, myelination progress bar + stage label, 7-day weekly grid, implementation intention (When→Then), complete button, archive kebab menu | Web, Flutter | Shipped | `HabitCard.tsx`, `habit_card.dart` |
| 9 | Myelination Formula | `calculateMyelination(completions, streak)` — reaches ~85% at 57 completions + streak bonus to 100%; stages: Forming/Building/Strengthening/Established/Well-established | Web, Flutter | Shipped | `neuroHelpers.ts` `calculateMyelination()`, `neuro_helpers.dart` |
| 10 | Myelination Tooltip | Inline "?" button on habit card opens Lally et al. (2010) explainer panel | Web | Shipped | `HabitCard.tsx` `showMyelinInfo` state |
| 11 | Myelination Milestone Celebrations | Toast/snackbar animation when habit crosses 10/25/50/75/100% — variable reward schedule | Web, Flutter | Shipped | `MilestoneCelebration.tsx`, `dashboard_page.dart` `_showMilestoneCelebration()`, `neuro_provider.dart` milestone logic |
| 12 | 7-Day Weekly Grid | Per-habit rolling 7-day completion grid; colour-coded: emerald=completed, amber=comeback, surface=missed, indigo ring=today | Web, Flutter | Shipped | `WeeklyGrid.tsx`, `weekly_grid.dart`, `statsHelpers.ts` `getWeekGrid()` |
| 13 | Recovery Comeback Badge | Visual badge on amber comeback cell when comeback follows a missed day | Web | Shipped | `WeeklyGrid.tsx` `isRecoveryComeback` logic |
| 14 | Comeback Protocol Modal | Two-phase modal: CBT reframe personalised by `failureStyle`, then 3 micro-actions personalised by `peakEnergyWindow` + `primaryBlocker`; checkbox each action; `acknowledgeComeback()` on completion | Web, Flutter | Shipped | `ComebackProtocol.tsx`, `comeback_protocol` widget |
| 15 | Comeback Gate (Freemium) | On 4th comeback of the month (free tier), shows `ComebackGateModal` instead of protocol; lock icon, social proof, upgrade CTA | Web, Flutter | Shipped | `ComebackGateModal.tsx`, `neuro_provider.dart` `proGateEventProvider` |
| 16 | Freemium Banner | Subtle banner showing remaining free comebacks this month; accent/rose border; upgrade CTA | Web | Shipped | `FreemiumBanner.tsx` |
| 17 | Neuro-Swap Cards | Per-swap card: friction level badge, intercept action, urge-surf button (+15 DA, +30 GABA), slip button (+40 EPI, -15 DA), resist rate percentage | Web, Flutter | Shipped | `SwapCard.tsx`, `swap_card.dart` |
| 18 | Add Habit Modal | Guided form: title, anchor cue, action (with live implementation intention preview), reward, category selector; Quick and Detailed modes on web | Web, Flutter | Shipped | `AddHabitModal.tsx`, `add_habit_sheet.dart` |
| 19 | Add Swap Modal/Sheet | Form: title, trigger cue, intercept action, friction level slider (1–5) | Web, Flutter | Shipped | `AddHabitModal.tsx` swap mode, `add_swap_sheet.dart` |
| 20 | Habit Archive | Kebab menu → archive (`isActive=false`, no hard deletes); collapsible archived section in Habits tab with Restore button | Web, Flutter | Shipped | `HabitCard.tsx` `onArchive`, `ArchivedSection` in `Dashboard.tsx`, `_HabitsTab` in `dashboard_page.dart` |
| 21 | Neurochemical Decay | Per-minute decay of all 4 neurochemicals toward baseline 50 at 8%/step; runs on `setInterval` (60s) on web, equivalent in Flutter | Web, Flutter | Shipped | `Dashboard.tsx` `useEffect` decay interval, `neuroHelpers.ts` `decayNeurochemical()` |
| 22 | Activity Log | Reverse-chronological timeline of completions/urge surfs/slips/comebacks with dopamine delta per event; capped at 20 most recent on web | Web, Flutter | Shipped | `Dashboard.tsx` log tab, `_LogItem` in `dashboard_page.dart` |
| 23 | Stats Bar | 6-metric grid: Recovery Rate, Comeback Streak, Total Comebacks, Best Streak, Active Habits, Days In System | Web, Flutter | Shipped | `StatsBar.tsx`, `stats_bar.dart`, `statsHelpers.ts` |
| 24 | Brain Score | Composite 0–100 score: 40% avg myelination, 30% recovery rate, 30% neurochemistry average; colour-coded in header | Web, Flutter | Shipped | `statsHelpers.ts` `calcBrainScore()`, `stats_helpers.dart` |
| 25 | Brain Profile Card | Collapsible card: archetype name, failure style badge, 6 dimension values, Retake Assessment button | Web, Flutter | Shipped | `BrainProfileCard.tsx`, `brain_profile_card.dart` |
| 26 | Recovery Playbook | Collapsible card: AI-surfaced insight strings (up to 3), recent comebacks list with micro-action completion status, recovery rate percentage | Web, Flutter | Shipped | `RecoveryPlaybook.tsx`, `recovery_playbook.dart` |
| 27 | Failure Signatures | Analysis of weakest habit (miss rate), worst day of week, fastest recovery habit, avg recovery days; requires >= 14 days of history | Flutter only | Shipped | `flutter_app/lib/utils/failure_analysis.dart` |
| 28 | Weekly Check-in | 5-step bottom sheet (consistency 1–5 scale, biggest blocker, energy level, environment change + note, failure mode this week); triggers every 7 days | Web, Flutter | Shipped | `WeeklyCheckin.tsx`, `weekly_checkin_modal.dart` |
| 29 | Recalibration Engine | Pure function: runs after check-in; produces SCALE_DOWN / REPLACE / UPDATE_MICRO suggestions based on completion rates and blocker drift | Web, Flutter | Shipped | `recalibrationEngine.ts`, `recalibration_engine.dart` |
| 30 | Recalibration Suggestions UI | Bottom sheet: per-suggestion card with type badge, habit name, reason, before→after preview, Accept/Skip per suggestion; Apply decisions button disabled until all decided | Web, Flutter | Shipped | `RecalibrationSuggestions.tsx`, `recalibration_sheet.dart` |
| 31 | Implementation Intention Preview | Live "When [cue], I will [action]" preview rendered inline as the user types in the Add Habit modal | Web | Shipped | `AddHabitModal.tsx` |
| 32 | Dark/Light Theme | Toggleable dark/light mode; persisted to localStorage (web) / `themeModeProvider` (Flutter); CSS custom properties on web, `AppTheme` on Flutter | Web, Flutter | Shipped | `ThemeContext.tsx`, `app_theme.dart`, `themeModeProvider` |
| 33 | Push Notifications | Daily reminder (8 AM), evening check-in prompt (8 PM), loss aversion nudge (3-day inactivity), comeback nudge (2-day); requested at onboarding | Flutter | Shipped | `notification_service.dart` |
| 34 | PWA / Offline | vite-plugin-pwa service worker; offline-capable shell | Web | Shipped | `vite.config.ts` (implied by STATUS.md), package.json `vite-plugin-pwa` |
| 35 | Share Card | Image-based stats card (Brain Score, Comeback Streak, Recovery Rate, Best Streak, Archetype); captured as PNG via `RepaintBoundary` + `Share.shareXFiles()` | Flutter | Shipped | `share_card.dart`, `dashboard_page.dart` `_ShareSheet` |
| 36 | Upgrade Page | Full-screen pro feature comparison, social proof block, annual ($79/yr) and monthly ($9/mo) price buttons; launches Stripe Checkout URL via `url_launcher` | Flutter | Shipped (Stripe URLs are placeholder `TODO`) | `upgrade_page.dart` |
| 37 | Stripe Webhook Handler | Supabase Edge Function: handles `checkout.session.completed` and `customer.subscription.deleted`; sets `isPro` in `neuro_state` Postgres table | Backend | Shipped (not connected to live keys) | `supabase/functions/stripe-webhook/index.ts` |
| 38 | Supabase Cloud Sync | `neuro_state` table upsert on every state save; `loadFromCloud()` on sign-in; fire-and-forget | Flutter | Shipped (requires Supabase credentials via `--dart-define`) | `neuro_provider.dart` `_syncToCloud()` |
| 39 | Comeback Protocol HTML Prototype | Standalone static HTML/CSS/JS prototype of the comeback protocol; 3 states (initial/recovery/confirm); energy chip selection; no React dependency | Web (standalone) | Shipped | `comeback-protocol.html` |
| 40 | Zustand Persistence + Migration | `persist` middleware, key `neuroflow-state-storage`, version 2; migration guard sets `onboardingComplete=true` for existing users | Web | Shipped | `useNeuroStore.ts` |
| 41 | Dopamine Points Counter | Accumulating point total shown in dashboard header; awarded on habit completion, comeback acknowledgment, urge surfing | Web, Flutter | Shipped | `useNeuroStore.ts` `claimDopaminePoints()`, `neuro_provider.dart` |
| 42 | Comeback Streak | Consecutive days where the Comeback Protocol fired (distinct from habit streak); shown in Stats Bar | Web, Flutter | Shipped | `statsHelpers.ts` `calcComebackStreak()`, `stats_helpers.dart` |
| 43 | Retake Brain Assessment | Button in Brain Profile Card; clears `brainProfile` from store, routes back to BrainAssessment page | Web | Shipped | `BrainProfileCard.tsx` `handleRetake()` |
| 44 | State-Based Routing | App routing via `onboardingComplete` → `brainProfile` → `blueprintAccepted` → Dashboard gates; no router library on web — pure conditional rendering in `App.tsx` | Web | Shipped | `App.tsx` `AppRoutes()` |
| 45 | Comeback Protocol Personalisation | Reframe copy and micro-actions derived from `failureStyle`, `peakEnergyWindow`, `primaryBlocker` via `brainHelpers.ts`; 4 failure styles × 4 energy windows × 4 blockers = 64 micro-action permutations | Web, Flutter | Shipped | `brainHelpers.ts` `getBrainAwareReframe()`, `getBrainAwareMicroActions()` |

---

## 5. User Flow Map

### Onboarding Flow

State gating is pure conditional rendering in `App.tsx`. No router library is used. State transitions are driven by Zustand store mutations.

```
App boots
  └── onboardingComplete = false → <Onboarding />

  ONBOARDING (Onboarding.tsx / onboarding_page.dart)
  Step 0 — Welcome screen
    "Build habits that survive failure."
    3 value prop cards (myelination / comeback protocol / recovery playbook)
    [Get Started →] → setStep(1)

  Step 1 — Profile setup
    Name text input + role chip grid (Builder/Designer/Athlete/Student/Other)
    [Continue →] (disabled until name.trim() > 0 && role !== null) → setStep(2)

  Step 2 — First habit
    3 role-personalised habit suggestion cards (from SUGGESTIONS[role])
    Tap a card to select; [Add this habit →] or [Skip for now →] → setStep(3)

  Step 3 — Comeback Protocol explainer
    3-card explainer: miss → reset plan → playbook grows
    "Your Recovery Rate — not your streak — is the number we track."
    [I'm ready →]
      → setUserProfile({ name, role })
      → if selectedHabit: addNeuroStack(selectedHabit)
      → completeOnboarding()   ← sets onboardingComplete = true in store

  App re-renders: onboardingComplete = true, brainProfile = null
  → <BrainAssessment />
```

### Brain Assessment → Blueprint Flow

```
  BRAIN ASSESSMENT (BrainAssessment.tsx / brain_assessment_page.dart)
  8 questions, one at a time, progress bar across top
  Tap card → auto-advance to next question (no explicit Next button)
  Skip button on web hardcodes 'analyst' as the skipped answer (BrainAssessment.tsx line ~281)

  After Q8 → phase = 'processing'
    1800ms animated spinner

  → phase = 'reveal'
    archetype name (getArchetypeName(profile) from brainHelpers.ts)
    4 insight cards (getProfileInsights(profile))
    6-dimension grid
    [Apply to my system →]
      → setBrainProfile(profile)   ← sets brainProfile in store

  App re-renders: brainProfile set, blueprintAccepted = false
  → <RoutineBlueprint />

  ROUTINE BLUEPRINT (RoutineBlueprint.tsx / routine_blueprint_page.dart)
  buildBlueprint(brainProfile, neurochemistry) → 3–5 HabitTemplate[]
    (scoring: +3 peak energy match, +2 blocker match, +2 core driver,
     +1 failure style, +2 neuro chemical targeting)
  User can:
    - Swap (opens bottom sheet with getAlternativesFor() → same category, top 3)
    - Remove (X button, disabled if only 1 habit remaining on web)
    - Accept as-is

  [Start my routine (N habits) →] or [Skip — I'll add habits myself]
    → forEach: addNeuroStack(template fields)
    → setTimeout 600ms → acceptBlueprint()   ← sets blueprintAccepted = true

  App re-renders: blueprintAccepted = true → <Dashboard />
```

### Core Daily Loop

```
DASHBOARD loads (Dashboard.tsx / dashboard_page.dart)

  Check-in gate (runs on mount):
    if lastCheckinDate = null OR daysSince >= 7:
      → showCheckin = true → WeeklyCheckin bottom sheet

  Missed stacks check (computed on render):
    getMissedStacks(stacks, getTodayComebackIds())
    if missed.length > 0:
      if isPro OR comebacksThisMonth < 3:
        → showComeback = true → ComebackProtocol modal
      else:
        → showComebackGate = true → ComebackGateModal

  Milestone check (Flutter: milestoneEventProvider listener):
    if pendingMilestone !== null:
      → MilestoneCelebration toast (auto-dismisses after 4000ms)

  User actions during session:
    [Mark Complete] on HabitCard
      → completeNeuroStack(id)
          + calculateMyelination(completions.length, streak) → check milestones
          + neurochemistry: DA +25 (+40 if streak>5), ACh +20, EPI +5
          + dopaminePoints += 25 (or 40)
          + log entry
      → weekly grid re-renders; myelination bar animates

    [Urge Surfed] on SwapCard
      → logUrgeSurf(id)
          + DA +15, ACh +10, EPI -10, GABA +30

    [Log Slip] on SwapCard
      → logSlip(id)
          + DA -15, ACh +15, EPI +40, GABA -10

    Every 60 seconds:
      → decayNeurochemistry()
          each chemical moves 10% toward baseline 50

  Tab switching:
    Habits / Swaps / Activity — AnimatePresence fade transition
```

### Failure/Recovery Flow

```
MISSED HABIT DETECTED (on Dashboard mount or re-render)
  getMissedStacks(activeStacks, getTodayComebackIds())
    └── filters: isActive, completions.length > 0,
        missedYesterday = !completions.includes(yesterday),
        notCompletedToday, !acknowledgedTodayIds.includes(id)

  GATE CHECK:
    if !isPro AND getComebacksThisMonth(comebacks) >= 3:
      → ComebackGateModal shown
          "Monthly comeback limit reached"
          Lock icon, social proof pill ("Pro users complete 3x more comebacks")
          [Upgrade to Pro — $9/mo] → upgradeToPro() → setShowComeback(true)
          [Maybe later] → dismiss

    else:
      → ComebackProtocol modal shown

  COMEBACK PROTOCOL MODAL (ComebackProtocol.tsx)
    Phase 1 — REFRAME
      getComebackMessage(daysMissed) from comebackHelpers.ts
        (4 messages, selected by daysMissed index)
      NOTE: brainHelpers.ts getBrainAwareReframe() exists but
            ComebackProtocol.tsx does NOT call it — it uses the
            simpler getComebackMessage() instead (gap vs. PRD spec)
      [Show me the re-entry plan →] → phase = 'actions'

    Phase 2 — ACTIONS
      generateMicroActions(stack) from comebackHelpers.ts
        (category-keyed static arrays: focus/wellness/mindset/fitness)
      NOTE: getBrainAwareMicroActions() in brainHelpers.ts exists
            but is not called here — micro-actions are not personalised
            by brain profile in current implementation (gap vs. PRD spec)
      3 checkboxes; any one must be ticked to enable Continue

      [I'm continuing] / [Continue — next habit]
        → onComplete(stack.id, stack.title, allChecked)
            → acknowledgeComeback(stackId, stackTitle, microActionsCompleted)
                + ComebackRecord logged
                + DA +10–20, ACh +10, EPI -15, GABA +15
                + dopaminePoints += 10
                + log entry type='comeback'
        → if more missed stacks: advance to next; else onDismiss()

      [Skip actions — just acknowledge]
        → onComplete(stack.id, stack.title, false)   // microActionsCompleted=false

  RECOVERY PLAYBOOK (RecoveryPlaybook.tsx)
    Updated with new ComebackRecord
    Collapsible card shows:
      - getRecoveryInsights() strings (up to 3, from statsHelpers.ts)
      - Last 5 comebacks with microActionsCompleted checkmark/x
      - completionRate = comebacks with microActionsCompleted / total
```

### Weekly Check-in + Recalibration Flow

```
WEEKLY CHECK-IN TRIGGER
  on Dashboard mount: if daysSince(lastCheckinDate) >= 7
  → WeeklyCheckin bottom sheet (5 steps, spring animation)

  Step 1: consistency (1–5 tap scale) → auto-advance
  Step 2: weeklyBlocker (4 option cards) → auto-advance
  Step 3: energyLevel (Low/Normal/High) → auto-advance
  Step 4: contextChanged (Yes/No) + optional note textarea → [Continue →]
  Step 5: currentFailureMode (4 options) → [Submit check-in →]

  → onSubmit(draft)
      → submitCheckin(record) in store
          + lastCheckinDate = now
          + checkinHistory.unshift(record)
      → runRecalibration(stacks, latestHistory, brainProfile)
          checks each active stack:
            SCALE_DOWN: completionRate < 0.4 over 14 days AND liteVersionId exists
            REPLACE: completionRate = 0 over 14 days AND stack age >= 14 days
            UPDATE_MICRO: last 2 check-ins have same weeklyBlocker ≠ brainProfile.primaryBlocker
          → returns RecalibrationSuggestion[]

  if suggestions.length > 0:
    → RecalibrationSuggestions bottom sheet
        per suggestion: type badge, habit name, reason, from→to preview
        Accept / Skip per suggestion (all must be decided)
        [Apply decisions →]
          → applyRecalibration(event) in store
              SCALE_DOWN: updateNeuroStack with new title from liteVersion template
              REPLACE: archiveNeuroStack old + addNeuroStack from replacement template
              UPDATE_MICRO: stored in recalibrationLog (no immediate habit mutation)
```

---

## 6. Assumptions Being Made

| # | Assumption | Confidence | Validated? | Risk if Wrong |
|---|------------|------------|------------|---------------|
| 1 | Users who miss habits feel shame, not indifference | High | Partial — cited Neff (2003), not app-specific data | Low risk; the protocol is still useful even without shame; but the emotional framing in copy loses its hook |
| 2 | Users will open the app after missing (to trigger the Comeback Protocol) | Med | No — this is the core activation risk listed in the PRD risk register | Critical; if users don't open the app after missing, the protocol never fires; the product requires the user to return |
| 3 | An 8-question assessment before using the app doesn't kill conversion | Med | No | High; 8 questions is a significant onboarding ask; dropout between assessment start and blueprint accept is an untested funnel |
| 4 | The brain profile is stable enough to drive personalisation for weeks | Med | No | Medium; failure style is not fixed week-to-week (the weekly check-in captures `currentFailureMode` for this reason), but the profile is treated as stable for micro-action selection until recalibration fires |
| 5 | 3 free comebacks/month is the right freemium gate | Low | No — PRD explicitly notes may tighten to 2 post-20-users | Medium; too generous and no one upgrades; too tight and users bounce |
| 6 | The neurochemistry HUD is motivating, not confusing | Med | No | Medium; non-technical users may find DA/ACh/EPI/GABA numbers opaque; the tap-to-explain overlay mitigates but doesn't eliminate this |
| 7 | Recovery Rate is a meaningful metric that users will care about | Med | No — PRD lists this as an alpha launch criterion | Critical; if users don't care about Recovery Rate, the anti-streak positioning has no counter-metric |
| 8 | Myelination as a progress metaphor is understood and motivating | Med | No | Low; stage labels (Forming → Well-established) provide fallback legibility |
| 9 | The habit library (37 web / 20 Flutter) has enough coverage for diverse users | Low | No | Med; 20 Flutter templates is thin; "Other" role has sparse coverage |
| 10 | localStorage is sufficient for alpha persistence | High | Yes — explicitly noted as intentional with Supabase as Phase 2 prerequisite | Med; single device limitation; data loss on clear is a real alpha risk |
| 11 | Users will complete the 7-day check-in when it appears | Med | No | Med; if check-in completion is <50% (PRD target), recalibration never runs and the adaptive loop breaks |
| 12 | Blueprint habits should not count against the free 2-habit limit from day 1 | Low | No — explicitly an open question in PRD §13.4 | High; if blueprint auto-assigns 3–5 habits and all count immediately, free users are locked out of adding custom habits from day 1 |
| 13 | Reframe copy not personalised by brain profile is acceptable for alpha | Med | No — `getBrainAwareReframe()` exists in brainHelpers.ts but is not called from ComebackProtocol.tsx | Med; personalised reframes are a stated differentiator; the current generic `getComebackMessage()` does not use the brain profile |
| 14 | Micro-actions not personalised by brain profile is acceptable for alpha | Med | No — same gap: `getBrainAwareMicroActions()` exists but is not called | Med; category-only micro-actions reduce the personalisation payoff |
| 15 | Dual codebase (React + Flutter) can be maintained in sync | Low | No — feature parity gap already exists (habit library size, failure signatures on Flutter only) | High; two codebases with different feature sets will diverge faster as the team is small |
| 16 | The neurochemical initial state (DA=65, GABA=60 — elevated above baseline 50) is not misleading | Med | No — flagged as open question in PRD §13.3 | Low; risk is user confusion if they interpret it as a measurement |

---

## 7. Business Model Analysis

### Revenue Model

Freemium with a Pro subscription. Free tier has hard limits enforced in the Zustand store and Flutter provider. Upgrade is triggered by hitting the comeback limit (`ComebackGateModal`), from the freemium banner (`FreemiumBanner.tsx`), from a standalone upgrade page in Flutter (`upgrade_page.dart`), or from dashboard action buttons. The upgrade CTA in web (`upgradeToPro()` in store) currently sets `isPro = true` locally without any payment — Stripe is not wired into the web app. Flutter's `upgrade_page.dart` opens a Stripe Checkout URL via `url_launcher`, but the URLs are placeholder `TODO` constants.

### Freemium Gates (exact features locked)

| Feature | Free | Paid |
|---------|------|------|
| Comeback Protocol activations | 3/month | Unlimited |
| Active habits | 2 max (Flutter: 5 max — parity gap) | Unlimited |
| Active swaps | 1 max (Flutter: 3 max — parity gap) | Unlimited |
| Weekly check-in | Full access | Full access |
| Recalibration Engine | Full access | Full access |
| Brain Assessment | Full access | Full access |
| Recovery Playbook v1 | Full access | Full access |
| Failure Signatures (Playbook v2) | Locked (not implemented on web; on Flutter: implemented in `failure_analysis.dart` but gate status unclear) | Unlocked |
| Push notifications | Not available (web: not implemented; Flutter: delivered) | Unlocked per PRD (Flutter ships it regardless of tier) |
| Share card | Not gated | Not gated |

### Pricing

The following price points are present in the codebase:
- Monthly: $9/month (hardcoded in `ComebackGateModal.tsx`, `upgrade_page.dart`, PRD)
- Annual: $79/year (hardcoded in `upgrade_page.dart`)
- Annual savings claim: "Save 27% · $6.58/mo" (`upgrade_page.dart`)
- PRD also mentions a hypothetical $29 lifetime deal for first 100 Pro users (Phase 3) — not implemented

### Payment Infrastructure

The Stripe integration is partially scaffolded:

1. **Supabase Edge Function** (`supabase/functions/stripe-webhook/index.ts`): Handles two Stripe events:
   - `checkout.session.completed`: looks up user by `client_reference_id` (or fallback to `customer_details.email`), then upserts `isPro = true` into `neuro_state` table via `_setProStatus()`
   - `customer.subscription.deleted`: queries `neuro_state` by `stripeCustomerId` in `state_json`, then sets `isPro = false`

2. **Supabase `neuro_state` table**: Stores the full serialised state blob (`state_json JSONB`) per `user_id`. `isPro` is embedded inside this JSON blob — not a separate column — which makes the webhook query for `customer.subscription.deleted` rely on a JSONb path query (`state_json->>stripeCustomerId`).

3. **Flutter upgrade flow**: `upgrade_page.dart` opens `_monthlyUrl` / `_annualUrl` (both `TODO` placeholder Stripe Checkout links) via `url_launcher`. After payment, Stripe fires the webhook to the Supabase Edge Function, which updates `neuro_state`. Flutter's `neuro_provider.dart` `loadFromCloud()` would then pick up the `isPro` change on next sign-in.

4. **Web upgrade flow**: `upgradeToPro()` in `useNeuroStore.ts` sets `isPro = true` locally in Zustand with no server call. No Stripe integration on the web app.

### Monetization Gaps

1. The web app has no Stripe integration — clicking "Upgrade" sets `isPro` locally and permanently without payment.
2. Stripe Checkout URLs in `upgrade_page.dart` are `TODO` placeholder strings that will fail at runtime.
3. There is no `client_reference_id` being set on the Stripe Checkout session — the webhook's primary lookup path requires this to map payment back to user.
4. `stripeCustomerId` is not explicitly stored in the `neuro_state` schema — the webhook's subscription-deleted lookup queries `state_json->>stripeCustomerId`, which means the app must write this field after checkout, but no code in the current codebase does this.
5. No server-side subscription status verification — `isPro` is stored client-side in localStorage (web) and SharedPreferences (Flutter), both mutable without authentication.
6. No trial period enforcement — `upgrade_page.dart` copy mentions "7-day free trial" but no trial logic exists in the codebase.
7. No receipt or confirmation UI after payment.

---

## 8. Technical Architecture Overview

### Web App (React PWA)

- **Framework:** React 19 + TypeScript
- **Build:** Vite 8 (rolldown-based)
- **Styling:** Tailwind CSS v4 (CSS-first config; `@variant dark` for dark mode; CSS custom properties for design tokens)
- **Animations:** Framer Motion (all modals, tab transitions, progress bars)
- **Icons:** lucide-react
- **State:** Zustand v5 + `persist` middleware (localStorage key: `neuroflow-state-storage`, version 2)
- **Routing:** None — pure conditional rendering in `App.tsx` `AppRoutes()` component based on store state flags (`onboardingComplete`, `brainProfile`, `blueprintAccepted`)
- **PWA:** vite-plugin-pwa (service worker, offline shell)
- **Backend calls:** None (web app is fully local; no Supabase calls from the web layer)

### Mobile App (Flutter)

- **Framework:** Flutter (SDK >=3.3.0 <4.0.0)
- **State:** Riverpod v2 (`NotifierProvider`, `StateProvider`); `NeuroNotifier` is a single fat notifier holding all app state
- **Persistence:** SharedPreferences (key: `neuroflow-state-v1`); state serialised as JSON string
- **Notifications:** flutter_local_notifications + timezone; 4 notification channels (daily reminder, loss aversion, comeback nudge, evening check-in)
- **Cloud sync:** supabase_flutter; upserts full state JSON on every save; pull on sign-in
- **Fonts:** google_fonts (Inter)
- **Sharing:** share_plus + path_provider (PNG capture of ShareCard widget)
- **Key dependencies from pubspec.yaml:** flutter_riverpod ^2.5.1, shared_preferences ^2.3.2, flutter_animate ^4.5.0, google_fonts ^6.2.1, uuid ^4.4.2, supabase_flutter ^2.8.1, flutter_local_notifications ^17.0.0, timezone ^0.9.4, share_plus ^10.0.0, url_launcher ^6.3.0, path_provider ^2.1.5

### Backend

- **Platform:** Supabase (Postgres + Edge Functions + Auth)
- **Auth:** Supabase magic link (email) — referenced in PRD Phase 2 and `neuro_provider.dart` sign-out flow, but auth pages are not implemented in the Flutter app; `_SignOutButton` in `dashboard_page.dart` checks `Supabase.instance.client.auth.currentUser` and only shows when a user is signed in
- **Database:** Single `neuro_state` table with columns: `user_id`, `state_json JSONB`, `updated_at`. All app state is serialised into one JSON blob per user. No relational schema.
- **Edge Functions:** One deployed function (`stripe-webhook`) handling Stripe payment events
- **When Supabase is not configured:** Flutter app gracefully skips init (guarded by `_supabaseUrl.isNotEmpty` check in `main.dart`); sign-out button is hidden; cloud sync silently no-ops

### Data Flow Diagram

```
USER ACTION (complete habit, comeback, urge surf, etc.)
    │
    ▼
React PWA                         Flutter App
Zustand store mutation            NeuroNotifier mutation
    │                                   │
    ▼                                   ▼
localStorage                      SharedPreferences
(neuroflow-state-storage)         (neuroflow-state-v1)
    │                                   │
    │                        (if Supabase configured)
    │                                   ▼
    │                         Supabase neuro_state table
    │                         (upsert, fire-and-forget)
    │
    │  (no server calls from web app)

STRIPE PAYMENT (Flutter only, currently TODO URLs)
    │
    ▼
Stripe Checkout (external URL via url_launcher)
    │
    ▼
stripe-webhook Edge Function (Supabase)
    │
    ▼
neuro_state.state_json isPro = true
    │
    ▼
Flutter loadFromCloud() on next sign-in
```

### Data Models

**NeuroStack (habit)**
```
id: string
title: string
anchorCue: string          // implementation intention "when" clause
action: string             // implementation intention "then" clause
reward: string
category: 'focus' | 'wellness' | 'mindset' | 'fitness'
acetylcholineDuration: number   // focus timer in minutes
myelinationLevel: number   // 0–100, computed by calculateMyelination()
streak: number             // consecutive days
completions: string[]      // 'YYYY-MM-DD' strings
createdAt: string          // ISO timestamp
isActive: boolean
// Flutter only:
whenCondition?: string
thenAction?: string
```

**NeuroSwap (bad habit)**
```
id: string
title: string
cue: string
badResponse: string
interceptAction: string
frictionLevel: 1 | 2 | 3 | 4 | 5
frictionSteps: string[]
urgeSurfingCompletions: string[]   // 'YYYY-MM-DD'
slips: string[]                    // 'YYYY-MM-DD'
createdAt: string
isActive: boolean
```

**NeuroBrainProfile**
```
failureStyle: 'perfectionist' | 'avoider' | 'analyst' | 'drifter'
peakEnergyWindow: 'morning' | 'afternoon' | 'evening' | 'variable'
recoverySpeed: 'fast' | 'medium' | 'slow' | 'variable'
primaryBlocker: 'energy' | 'overwhelm' | 'distraction' | 'life'
selfTalkPattern: 'self-critical' | 'avoidant' | 'rational' | 'hopeless'
motivationSource: 'identity' | 'outcome' | 'process' | 'survival'
accountabilityStyle: 'tracking' | 'external' | 'systems' | 'none'
coreDriver: 'feel-better' | 'perform-better' | 'become-someone' | 'survive'
completedAt: string   // ISO timestamp
```

**Neurochemistry**
```
dopamine: number        // 0–100, initial=65 (web) / 65 (Flutter)
acetylcholine: number   // 0–100, initial=55
epinephrine: number     // 0–100, initial=50
gaba: number            // 0–100, initial=60
baseline (all): 50 — decay target
```

**ComebackRecord**
```
id: string
stackId: string
stackTitle: string
date: string              // 'YYYY-MM-DD'
completedAt: string       // ISO timestamp
microActionsCompleted: boolean
```

**CheckinRecord**
```
id: string
date: string              // ISO timestamp
consistency: 1 | 2 | 3 | 4 | 5
weeklyBlocker: string     // 'energy' | 'overwhelm' | 'distraction' | 'life'
energyLevel: 'low' | 'normal' | 'high'
routineChanged: boolean
routineNote?: string
contextChanged?: boolean
currentFailureMode?: 'perfectionist' | 'avoider' | 'analyst' | 'drifter'
recalibrationApplied: boolean
```

**UserProfile**
```
name: string
role: string   // 'Builder' | 'Designer' | 'Athlete' | 'Student' | 'Other'
```

---

## 9. Platform Strategy

### Dual Codebase Reality

There are two complete, independent implementations of NeuroSync: the React 19 PWA (`src/`) and the Flutter mobile app (`flutter_app/`). They share no code, no types, and no library. They use different state management (Zustand vs. Riverpod), different persistence keys, and different habit library sizes (37 vs. 20 templates). The Flutter app is ahead on some features (failure signatures, push notifications, share card, cloud sync, upgrade page) while the web app is ahead on others (habit library size, myelination tooltip, more complete freemium gate logic). This is a significant maintenance liability for a solo or small team.

| Feature | React PWA | Flutter | Notes |
|---------|-----------|---------|-------|
| 4-screen onboarding | ✅ | ✅ | Flutter onboarding is 3 steps (name, role, science explainer) vs. 4 on web (welcome, profile, first habit, comeback explainer) — different structure |
| Brain Assessment (8Q + reveal) | ✅ | ✅ | Flutter's _RevealPage only shows 5 of 8 collected dimensions; selfTalk, motivation, accountability not surfaced in reveal |
| Routine Blueprint | ✅ | ✅ | Flutter uses toggle-to-deselect vs. web's swap/remove; Flutter confirms all selected, web has 1-habit minimum |
| Dashboard | ✅ | ✅ | |
| Neurochemistry HUD | ✅ | ✅ | |
| Habit cards with myelination | ✅ | ✅ | |
| 7-day weekly grid | ✅ | ✅ | |
| Myelination tooltip (inline explainer) | ✅ | ❌ | Web only |
| Myelination milestone celebrations | ✅ | ✅ | Web: full-screen toast widget; Flutter: SnackBar |
| Comeback Protocol modal | ✅ | ✅ | |
| Comeback Gate (freemium limit) | ✅ | 🔶 | Flutter uses `proGateEventProvider` AlertDialog; web has dedicated `ComebackGateModal` component |
| Freemium banner | ✅ | ❌ | Web only |
| Habit archive / restore | ✅ | ✅ | |
| Neuro-Swaps | ✅ | ✅ | |
| Add Habit modal (with II preview) | ✅ | ✅ | Implementation intention live preview is web only |
| Weekly Check-in (5 steps) | ✅ | ✅ | Web: 5 steps; Flutter: check actual `weekly_checkin_modal.dart` (not fully shown but shipped) |
| Recalibration Engine | ✅ | ✅ | |
| Recalibration Suggestions UI | ✅ | ✅ | |
| Recovery Playbook | ✅ | ✅ | |
| Failure Signatures (Playbook v2) | ❌ | ✅ | Flutter: `failure_analysis.dart`; not on web |
| Activity Log | ✅ | ✅ | |
| Stats Bar | ✅ | ✅ | |
| Brain Profile Card | ✅ | ✅ | |
| Comeback streak metric | ✅ | ✅ | |
| Brain score composite | ✅ | ✅ | |
| Dark/light theme | ✅ | ✅ | |
| Share card (PNG export) | ❌ | ✅ | Flutter only |
| Push notifications | ❌ | ✅ | Flutter only |
| Cloud sync (Supabase) | ❌ | ✅ | Flutter only |
| Upgrade page | ❌ | ✅ | Web: inline ComebackGateModal only |
| Stripe webhook backend | ✅ | ✅ | Shared Edge Function |
| PWA / offline | ✅ | N/A | Web only (by nature) |
| Habit library size | 37 templates | 20 templates | Web ahead |
| Free habit limit | 2 | 5 | Inconsistent — web is more restrictive |
| Free swap limit | 1 | 3 | Inconsistent — web is more restrictive |
| Brain-aware reframe in comeback | ❌ | ❌ | `getBrainAwareReframe()` exists but not called on either platform |
| Brain-aware micro-actions in comeback | ❌ | ❌ | `getBrainAwareMicroActions()` exists but not called on either platform |

### The comeback-protocol.html Anomaly

`comeback-protocol.html` is a completely standalone, zero-dependency static HTML file (no React, no Flutter, no build step) implementing a simplified 3-state version of the Comeback Protocol. It lives at the project root alongside `vite.config.ts` and `package.json`, not inside `src/` or `flutter_app/`.

It appears to be an early prototype or design exploration built before the React app was scaffolded. It implements:
- A 3-state machine (initial → recovery → confirm) with CSS animation transitions
- An optional "Add context" expansion panel (what you were trying to do, what got in the way, energy level chips)
- 3 energy-keyed step sets (low/medium/high) as content
- 4 rotating reframe messages
- Dark/light theme toggle responding to `prefers-color-scheme`
- A phone shell chrome (max-width 390px with rounded corners) for desktop preview

The visual design uses a different, starker design language (`#F6F6F4` off-white, `#111111` black CTA, `--accent: #2B5EE8`) compared to the shipped React app's indigo/surface token system. It is likely kept for:
1. A quick shareable demo link without needing the full app deployed
2. A reference design for the core mechanic
3. Potentially the source of a `comeback-protocol` marketing landing page

It is not referenced by any other file in the codebase and has no build pipeline integration.

---

## 10. Dependencies & Risks

| Dependency | Type | Risk Level | Notes |
|------------|------|------------|-------|
| localStorage (web) | Data persistence | 🔴 High | All user data lives in one localStorage key; browser clear = full data loss; no backup; no cross-device; blocks public launch per PRD |
| SharedPreferences (Flutter) | Data persistence | 🟡 Med | Same single-device limitation; Supabase sync partially mitigates when credentials are configured |
| Supabase | Backend + Auth | 🟡 Med | Required for cross-device sync, auth, Pro status persistence; not configured in web app at all; Flutter integration is conditional on `--dart-define` args |
| Stripe | Payments | 🔴 High | Checkout URLs are `TODO` placeholders in Flutter; web app has zero Stripe integration; `isPro` is locally mutable without payment |
| Dual React + Flutter codebase | Architecture | 🔴 High | Feature parity already diverged (37 vs 20 habits, different free limits, Flutter-only features); maintenance cost doubles for every new feature |
| No router library (web) | Architecture | 🟡 Med | App routing is pure conditional rendering in `App.tsx`; acceptable for current 4-state flow but will not scale to deeper navigation (settings, individual habit detail, etc.) |
| Brain profile hardcoded in one-time assessment | Product | 🟡 Med | If user answers assessment dishonestly or their profile changes significantly, comeback personalisation degrades; retake clears and re-runs but is not prompted |
| `getComebackMessage()` not using brain profile | Feature gap | 🟡 Med | `getBrainAwareReframe()` in `brainHelpers.ts` implements personalised reframes but is not called from `ComebackProtocol.tsx`; a core differentiation claim is undelivered |
| Habit library size parity gap | Product | 🟡 Med | Flutter library (20 templates) may produce worse blueprint matches than web (37); especially thin for mindset category (4 vs 7 templates) |
| No auth on web app | Architecture | 🔴 High | Web users cannot sign in; no cloud sync path; if Stripe is ever connected to web, there is no user identity to attach the subscription to |
| `stripeCustomerId` not stored | Payments | 🔴 High | Subscription cancellation webhook queries `state_json->>stripeCustomerId` but nothing in the app writes this field; subscription revocation will silently fail |
| Blueprint free-habit limit open question | Product | 🟡 Med | Blueprint assigns 3–5 habits; free tier caps at 2 (web) or 5 (Flutter); whether blueprint habits count immediately is unresolved (PRD §13.4) |
| Node version pinning | Dev environment | 🟢 Low | `.nvmrc` pins 20.19.0; low risk if team follows nvm workflow |
| No CI | Dev ops | 🟡 Med | STATUS.md lists CI as pending; type errors and build regressions are uncaught until manual build |
| TS6133 unused-variable warnings | Code quality | 🟢 Low | STATUS.md acknowledges these as non-blocking; should be cleaned before launch |
| `deleteNeuroStack` still in store | Data integrity | 🟢 Low | STATUS.md notes hard-delete action exists and should be guarded; no UI calls it currently but it is callable |

---

## 11. Open Questions

1. **Brain-aware comeback personalisation gap**: `getBrainAwareReframe()` and `getBrainAwareMicroActions()` both exist in `brainHelpers.ts` with full implementations keyed to `failureStyle` and `peakEnergyWindow × primaryBlocker`. Neither is called from `ComebackProtocol.tsx`. Is this an intentional deferral, or was it accidentally bypassed? The PRD states personalisation of both reframe and micro-actions as a shipped feature.

2. **Free habit limit vs. blueprint**: Blueprint auto-assigns 3–5 habits; free tier caps at 2 habits (web) or 5 (Flutter). There is no logic to handle the day-1 conflict on web where blueprint adds 3+ habits to a free-tier account. Do blueprint-assigned habits bypass the free limit on first run? If not, `addNeuroStack()` in the store will silently add all habits regardless (there is no enforcement guard in the web store's `addNeuroStack` action — guards only exist in Flutter's `canAddStack`).

3. **Flutter vs. web free tier limits inconsistency**: Web free tier: 2 habits, 1 swap. Flutter free tier: 5 habits, 3 swaps. Which is intentional? Which should be canonical?

4. **Skip button in Brain Assessment hardcodes 'analyst'**: `BrainAssessment.tsx` line ~281 calls `advance('analyst')` for any skipped question. This means skipping Q1 (failureStyle) sets the user as an analyst, skipping Q3 (peakEnergyWindow) also sets it to 'analyst', etc. This is almost certainly a bug that would corrupt the brain profile for any user who skips any question.

5. **ComebackGateModal `upgradeToPro()` call on web**: In `Dashboard.tsx`, clicking "Upgrade to Pro" in `ComebackGateModal` calls `upgradeToPro()` directly in the store, which sets `isPro = true` in localStorage without any payment. This means any user can bypass the freemium gate by clicking upgrade and then dismissing.

6. **`brainProfile` null-setting in BrainProfileCard retake**: `BrainProfileCard.tsx` `handleRetake()` calls `setBrainProfile(null as unknown as NeuroBrainProfile)`. This is a TypeScript cast to bypass null safety — `setBrainProfile` accepts `NeuroBrainProfile`, not `null`. The store's `setBrainProfile` action should accept `null` explicitly for retake to work type-safely.

7. **CHECK-IN interval for new habits**: PRD §13.1 asks whether new habits (<3 weeks) should check in every 3–4 days rather than 7. Currently flat 7-day trigger in both codebases (`CHECKIN_INTERVAL_DAYS = 7`).

8. **`currentFailureMode` not used in recalibration**: `CheckinRecord.currentFailureMode` is captured in check-in Step 5, and the UPDATE_MICRO suggestion type is documented as updating the comeback reframe dynamically when `currentFailureMode` differs from `brainProfile.failureStyle` for 2 consecutive check-ins. However, `recalibrationEngine.ts`'s UPDATE_MICRO trigger compares `weeklyBlocker` (not `currentFailureMode`) against `brainProfile.primaryBlocker`. The failure mode recalibration described in PRD §13.2 is not implemented.

9. **Neurochemical initial state labelling**: DA=65, GABA=60 are above baseline 50, creating an "optimistic" first session. PRD §13.3 suggests adding a tooltip clarifying this is a starting model, not a measurement. No tooltip exists yet.

10. **Myelination decay not implemented**: The neural pathway formula only grows. PRD §13.5 raises the question of mild decay for longer gaps (>3 days). No decay is currently applied — `calculateMyelination()` is only called on completion, not on elapsed time.

11. **Supabase auth pages missing from Flutter**: `neuro_provider.dart` references sign-in and `loadFromCloud()`, and `dashboard_page.dart` has a `_SignOutButton`. But there is no login page, auth flow, or email magic link implementation in the Flutter codebase. Users can only be "signed in" if they somehow authenticated outside the app.

12. **`stripeCustomerId` is never written to `state_json`**: The webhook's `customer.subscription.deleted` handler queries `state_json->>stripeCustomerId` to find which user to downgrade, but nothing in the app stores this field in `state_json` after checkout. Subscription cancellations will silently fail to revoke Pro status.

13. **comeback-protocol.html purpose and maintenance**: The standalone HTML prototype exists at the project root but is not linked from any page, any build, or any documentation. Should it be preserved as a marketing page, deleted, or integrated?

14. **Flutter habit library (20) vs. web (37)**: The Flutter library is missing 17 templates present on web, including the full cross-category and sleep consolidation sections. Will the blueprint engine produce meaningfully worse results on Flutter for users whose profiles match those missing templates?

15. **No analytics instrumentation**: PostHog and Sentry are listed as pending in STATUS.md. Without them, there is no way to measure funnel drop-off through onboarding, assessment completion rate, comeback activation rate, or any of the alpha success metrics listed in PRD §10.

16. **`deleteNeuroStack` is still exported from the web store** but should be archive-only per STATUS.md. No UI calls it, but it is callable from the console or any future accidental wiring.

17. **Flutter `_ActivityTab` has a `TODO` for Brain Assessment retake**: `BrainProfileCard` in the activity tab calls `onRetake` which shows a SnackBar "Retake: navigate to Brain Assessment (coming soon)" — retake is not functional in Flutter.

18. **Brain Assessment Skip button across all questions**: The web skip button on any question defaults `failureStyle` (the key for Q1) to `'analyst'` regardless of which question is being skipped. This implies the skip mechanism was only designed for Q1 and was not generalised.

19. **`HabitTemplate.liteVersionId` in web vs. Flutter**: The web `habitLibrary.ts` has 3 lite version pairs (focus-deep-work-block → focus-micro-work-block, fitness-zone2-cardio → fitness-morning-movement, fitness-strength-session → fitness-desk-pushups). The Flutter `habit_library.dart` has the same 3 pairs. The `blueprintEngine.ts` filter logic (`filter(h => !h.liteVersionId || ...)`) may have an unintended side effect: it filters out habits that are lite versions from the blueprint, which is correct, but the double-negative condition is complex and may allow some edge cases through.

20. **Web app has no sign-in, no accounts, no cross-device**: If a user completes the Brain Assessment on their laptop and opens the app on their phone, they start over from scratch. This is a known limitation (Supabase sync is Phase 2) but blocks any viral sharing or multi-device use cases until resolved.

---

*End of Phase 1 — Product Understanding*
*Next: Phase 2 — Ruthless Product Critique*
