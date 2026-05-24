# NeuroSync — Product Requirements Document

**Version:** 1.0  
**Date:** May 2026  
**Status:** Alpha — all core systems shipped  

---

## 1. Product Overview

NeuroSync is a personal habit recovery system for execution-focused people who keep failing the same habits. Unlike streak trackers that punish failure, NeuroSync's primary mechanic activates *when you miss* — not when you succeed.

**One-line pitch:**  
*NeuroSync is a personal recovery engine that helps you get back on track after you miss a habit — instead of starting over from zero.*

**North star:**  
Every comeback you log strengthens your playbook. That playbook is yours, and no other app has it.

**Primary metric:** Recovery Rate (% of comebacks where micro-actions were completed) — not DAU, not streak length.

---

## 2. Problem Statement

### The gap in existing habit apps

Every habit app on the market is built around a streak. When the streak breaks, the psychological consequence is shame → avoidance → abandonment. This is not a user problem — it is a design problem.

The science is clear (Lally et al., 2010; Fogg, 2019; Neff, 2003): a single missed day does not break a neural pathway. What breaks behavior change is the catastrophic response *to* the miss — the identity collapse, the self-criticism, the decision not to open the app.

### What people actually need

Users do not need more reminders to complete habits. They need:
1. A protocol for when they fail — not an empty streak reset screen
2. A system that understands *how* they fail (their failure style) and responds accordingly
3. Habits calibrated to their neurological state, not generic advice
4. Evidence that recovery is possible — logged, tracked, visible

### Target user

**Primary:** Execution-focused individuals aged 25–40 who:
- Identify as builders, engineers, designers, or ambitious professionals
- Have tried and failed at habit apps before (Streaks, Habitica, Notion dashboards, etc.)
- Talk about productivity and self-improvement publicly
- Have strong intrinsic motivation but inconsistent execution

**Psychographic profile:** They don't lack discipline. They lack a recovery system. They've been measuring success wrong (streaks) and defining failure too harshly (any miss = full reset).

---

## 3. Core Concepts

### 3.1 The Comeback Protocol

The central mechanic. When a user misses a habit, the app surfaces:
1. A **CBT reframe** personalised to their failure style (perfectionist / avoider / analyst / drifter) — dissolves the shame response that normally causes abandonment
2. **Energy-aware micro-actions** — a 2–3 step minimum viable re-entry sequence calibrated to their current blocker (energy / overwhelm / distraction / life)
3. **Acknowledgment** — logging the comeback is a first-class action, worth dopamine points

The protocol is explicitly framed as a strength, not an admission of failure.

### 3.2 Neural Pathway Strength (Myelination)

A progress metaphor for habit pathway strength, inspired by research on myelination (the myelin sheath that speeds axon signal conduction) and basal ganglia LTP (Graybiel). Not a clinical measurement — explicitly labelled as such in the UI.

Formula basis: Lally et al. (2010) found habit automaticity takes 18–254 days (median ~66). The app's formula reaches 85% at ~57 completions and 100% with sustained streak — roughly matching the 66-day median.

Stages: Forming → Building → Strengthening → Established → Well-established

### 3.3 NeuroSync Brain (Psychological Profile)

An 8-question assessment that builds a `NeuroBrainProfile` — a multi-dimensional model of how the user fails and how they recover. This profile drives:
- Which habits are auto-assigned (blueprint engine)
- Which reframe tone appears in the Comeback Protocol
- Which micro-action set is shown
- The user's archetype name (one of 16)

### 3.4 Neurochemistry HUD

A live model of four neurochemicals that shift based on user actions:
- **Dopamine (DA)** — anticipation and motivation drive; fires *before* the reward, not after (Schultz, 1997 prediction error model)
- **Acetylcholine (ACh)** — focus and learning depth; gates neuroplasticity; required for memory consolidation
- **Epinephrine (EPI)** — arousal and urgency signal; flags moments as important; brain uses norepinephrine for the same function internally
- **GABA** — inhibitory brake on stress circuits; calm and recovery state

These decay toward baseline (50) over time and spike on specific actions. They are not clinical measurements — they are a motivational model that makes neurochemistry legible.

### 3.5 Neuro-Swaps

Bad habit interception system. Each swap has:
- A defined cue-trigger (when it fires)
- A defined bad response (what the user normally does)
- A replacement intercept action
- Friction steps (physical barriers to the bad habit — Wendy Wood's contextual friction research)
- Urge-surfing completions and slip logging

### 3.6 Recovery Rate

The primary success metric displayed to users. Calculated as the percentage of comebacks where micro-actions were completed. Deliberately more Goodhart-resistant than streaks — you cannot "game" Recovery Rate without actually doing comebacks.

---

## 4. User Flows

### 4.1 First-time user flow

```
Welcome screen
  → Profile setup (name + role)
    → Role-personalised habit suggestions (add first habit)
      → Comeback Protocol explainer
        → Brain Assessment (8 questions, 1 at a time)
          → Profile Reveal (archetype + 4 insights + 6 dimensions)
            → RoutineBlueprint (3–5 auto-assigned habits, review/swap/remove)
              → Dashboard
```

### 4.2 Returning user flow (day with missed habits)

```
Dashboard loads
  → Comeback Protocol overlay (if missed habits exist)
    → CBT reframe personalised by failureStyle
      → Micro-actions (personalised by peakEnergyWindow + primaryBlocker)
        → acknowledgeComeback() logged
```

### 4.3 Weekly check-in flow

```
Dashboard loads (daysSinceCheckin >= 7)
  → WeeklyCheckin bottom sheet (5 questions, ~90 seconds)
    → recalibrationEngine runs on submit
      → RecalibrationSuggestions bottom sheet (if suggestions exist)
        → User accepts/rejects each suggestion
          → applyRecalibration() mutates habits
```

### 4.4 State routing logic

```
App boots
  └─ onboardingComplete = false         → Onboarding
  └─ onboardingComplete = true
       └─ brainProfile = null            → BrainAssessment
       └─ blueprintAccepted = false      → RoutineBlueprint
       └─ daysSinceCheckin >= 7          → WeeklyCheckin overlay (on Dashboard)
       └─ default                        → Dashboard
```

---

## 5. Feature Specifications

### 5.1 Onboarding (4 screens)

| Screen | Content | Action |
|---|---|---|
| Welcome | Mission statement, 3 value props | Get Started |
| Profile | Name input + role selection (Builder / Designer / Athlete / Student) | Continue |
| First Habit | Role-personalised suggestions (3 per role) + custom habit form | Add and Continue |
| Comeback Explainer | Protocol explainer, normalises failure | Begin your system |

**Completion:** Sets `onboardingComplete = true`.

### 5.2 Brain Assessment (NeuroSync Brain)

8 questions, one at a time, Typeform-style card-tap. Auto-advances on selection.

| Q | Dimension | Options |
|---|---|---|
| 1 | `failureStyle` | perfectionist / avoider / analyst / drifter |
| 2 | `motivationSource` | identity / outcome / process / survival |
| 3 | `peakEnergyWindow` | morning / afternoon / evening / variable |
| 4 | `recoverySpeed` | fast / medium / slow / variable |
| 5 | `primaryBlocker` | energy / overwhelm / distraction / life |
| 6 | `selfTalkPattern` | self-critical / avoidant / rational / hopeless |
| 7 | `accountabilityStyle` | tracking / external / systems / none |
| 8 | `coreDriver` | feel-better / perform-better / become-someone / survive |

**Profile Reveal:** 1.5s processing animation → archetype name (16 possible: `failureStyle × coreDriver`) + 4 personalised insight cards + 6-dimension summary grid.

**16 archetypes:**

| | feel-better | perform-better | become-someone | survive |
|---|---|---|---|---|
| **perfectionist** | The Burnt-Out Achiever | The Driven Perfectionist | The Identity Builder | The Pressure Coper |
| **avoider** | The Comfort Seeker | The Hidden High-Performer | The Reluctant Transformer | The Overwhelmed Avoider |
| **analyst** | The Thoughtful Optimizer | The Strategic Performer | The Deliberate Builder | The Rational Survivor |
| **drifter** | The Gentle Restarter | The Latent Performer | The Wandering Visionary | The Day-to-Day Drifter |

### 5.3 NeuroRoutine Blueprint

Full-screen habit review shown after Brain Assessment, before Dashboard. Prevents blank-state problem.

**Behavior:**
- Scores all 30+ library habits against the user's `NeuroBrainProfile` + live `Neurochemistry`
- Selects top 3–5, ensuring category variety (focus / wellness / mindset / fitness)
- User can swap (bottom sheet with alternatives from same category), remove, or accept as-is
- Confirming calls `addNeuroStack()` per habit then `acceptBlueprint()`

**Scoring algorithm (`blueprintEngine.ts`):**
- +3 pts: habit timing matches `peakEnergyWindow`
- +2 pts: habit addresses `primaryBlocker`
- +2 pts: habit aligns with `coreDriver`
- +1 pt: habit supports `failureStyle` recovery
- +2 pts: habit targets a depleted neurochemical (DA/ACh/GABA <40, or EPI >65 → GABA habits)

### 5.4 Dashboard

Max-width 2xl container. Mobile-first (375px baseline).

**Header:** Name + role, Brain Score badge (0–100, colour-coded), Dopamine Points counter, theme toggle.

**Brain Score formula:** Myelination 40% + Recovery Rate 30% + Chemical Health 30%

**Stats Bar (6 metrics):**
- Recovery Rate — % of comebacks with micro-actions completed
- Comebacks — total this month
- Best Streak — longest consecutive completion streak
- Active Habits — count of `isActive` stacks
- Days in System — days since `createdAt` of earliest stack
- Brain Score — composite

**Neurochemistry HUD:** 4 chemical cards (2×2 grid, 4-col on md). Each: abbreviation, value (0–100), level badge (High/Normal/Low), animated progress bar, description.

**Tabs:** Habits / Swaps / Activity Log. AnimatePresence fade on tab change.

**Habits tab:** HabitCard per active stack. FAB to add habit.

**Swaps tab:** SwapCard per active swap. FAB to add swap.

**Activity Log:** Reverse-chronological timeline of completions, urge surfs, slips, and comebacks with neurochemical delta per event.

### 5.5 Habit Card

Per-stack card with:
- Category badge (color-coded: focus=indigo, wellness=emerald, mindset=sky, fitness=amber)
- Streak counter
- Anchor cue preview
- **Neural Pathway** progress bar (0–100%) with stage label
- 7-day weekly grid (completed=emerald, comeback=amber, missed=surface, today=indigo ring)
- Mark Complete / already-completed state button

### 5.6 Comeback Protocol

Framer Motion modal (scale+fade entrance). Triggered from HabitCard or on Dashboard load when missed stacks exist.

Two phases within one modal:
1. **Reframe phase** — CBT headline personalised by `failureStyle`, calm body copy, card-style layout
2. **Actions phase** — 3 micro-actions personalised by `peakEnergyWindow` + `primaryBlocker`, checkbox each, `acknowledgeComeback()` on completion

**Personalisation matrix:**

| `failureStyle` | Reframe tone |
|---|---|
| perfectionist | "Your standard didn't drop. The day did." |
| avoider | "The hardest step was opening this. You already did it." |
| analyst | "One data point does not define a pattern." |
| drifter | "You drifted. Now you're back. That's the whole protocol." |

**Freemium gate:** Free tier = 3 comebacks/month. On 4th trigger, `ComebackGateModal` shown instead (Lock icon, upgrade CTA, social proof).

### 5.7 Weekly Check-in

5-step bottom sheet (spring animation). Triggers when `daysSinceLastCheckin >= 7`.

| Step | Question | Input | Field |
|---|---|---|---|
| 1 | How consistent were you this week? | 1–5 tap scale | `consistency` |
| 2 | What was your biggest blocker? | 4-option cards | `weeklyBlocker` |
| 3 | How has your overall energy been? | Low/Normal/High cards | `energyLevel` |
| 4 | Did your environment change this week? | Yes/No + optional note | `contextChanged`, `routineNote` |
| 5 | How did you mostly slip up this week? | 4-option cards | `currentFailureMode` |

Step 4 rationale: Wendy Wood's research — environment/location change is the #1 predictor of habit disruption. More diagnostic than the generic "routine changed?" question.

Step 5 rationale: Failure style is not fixed. Capturing the current mode each week enables recalibration to adapt the comeback reframe dynamically, rather than relying on a one-time assessment.

### 5.8 Recalibration Engine

Pure function (`recalibrationEngine.ts`) — no side effects. Runs after each check-in submission.

**Three suggestion types:**

| Type | Trigger | Action |
|---|---|---|
| `SCALE_DOWN` | <40% completion over 14 days + lite version exists | Swap to lower-friction version of same habit |
| `REPLACE` | 0% completion for 14 days + habit ≥14 days old | Archive habit, suggest replacement from same category |
| `UPDATE_MICRO` | `weeklyBlocker` ≠ `primaryBlocker` for 2 consecutive check-ins | Log signal to update comeback micro-action set |

**RecalibrationSuggestions UI:** Bottom sheet. Per-suggestion card shows type badge, habit name, reason, before→after preview. User accepts or rejects each. "Apply decisions" disabled until all decided.

### 5.9 Neuro-Swap Card

Per-swap card with:
- Trigger cue description
- Friction steps list
- Urge-surf completion count + last date
- Slip count
- Two action buttons: "Surfed the Urge" (+15 DA, +30 GABA) / "Logged a Slip" (+40 EPI, -15 DA)

### 5.10 Brain Profile Card

Collapsible card in Dashboard sidebar/section:
- Header: archetype name, failure style badge
- Expanded: 6-dimension grid (failureStyle, peakEnergyWindow, primaryBlocker, coreDriver, accountabilityStyle, selfTalkPattern)
- Retake Assessment button — clears `brainProfile`, routes back to BrainAssessment

### 5.11 Add Habit Modal

Framer Motion modal. Two modes: Quick (title + anchor cue) / Detailed (+ action, reward, category, focus duration). All fields validated. Category selection uses color-coded pill grid.

### 5.12 Freemium Banner

Subtle card with left accent border. Shows remaining free comebacks this month. Upgrade CTA with `.btn-secondary`.

---

## 6. Data Model

### 6.1 Core types

```typescript
NeuroBrainProfile {
  failureStyle:        'perfectionist' | 'avoider' | 'analyst' | 'drifter'
  peakEnergyWindow:    'morning' | 'afternoon' | 'evening' | 'variable'
  recoverySpeed:       'fast' | 'medium' | 'slow' | 'variable'
  primaryBlocker:      'energy' | 'overwhelm' | 'distraction' | 'life'
  selfTalkPattern:     'self-critical' | 'avoidant' | 'rational' | 'hopeless'
  motivationSource:    'identity' | 'outcome' | 'process' | 'survival'
  accountabilityStyle: 'tracking' | 'external' | 'systems' | 'none'
  coreDriver:          'feel-better' | 'perform-better' | 'become-someone' | 'survive'
  completedAt:         string (ISO)
}

NeuroStack {
  id:                  string
  title:               string
  anchorCue:           string
  action:              string
  reward:              string
  category:            'focus' | 'wellness' | 'mindset' | 'fitness'
  acetylcholineDuration: number    // focus timer in minutes
  myelinationLevel:    number      // 0–100
  streak:              number
  completions:         string[]    // 'YYYY-MM-DD'
  createdAt:           string (ISO)
  isActive:            boolean
}

NeuroSwap {
  id:                  string
  title:               string
  cue:                 string
  badResponse:         string
  interceptAction:     string
  frictionLevel:       1 | 2 | 3 | 4 | 5
  frictionSteps:       string[]
  urgeSurfingCompletions: string[]
  slips:               string[]
  createdAt:           string (ISO)
  isActive:            boolean
}

Neurochemistry {
  dopamine:       number  // 0–100, baseline 50
  acetylcholine:  number
  epinephrine:    number
  gaba:           number
}

CheckinRecord {
  id:                  string
  date:                string (ISO)
  consistency:         1 | 2 | 3 | 4 | 5
  weeklyBlocker:       string
  energyLevel:         'low' | 'normal' | 'high'
  routineChanged:      boolean
  routineNote?:        string
  contextChanged?:     boolean
  currentFailureMode?: 'perfectionist' | 'avoider' | 'analyst' | 'drifter'
  recalibrationApplied: boolean
}

HabitTemplate {
  id:              string
  title:           string
  anchorCue:       string
  action:          string
  reward:          string
  category:        'focus' | 'wellness' | 'mindset' | 'fitness'
  timing:          'morning' | 'anytime' | 'evening'
  energyRequired:  'low' | 'medium' | 'high'
  duration:        '2min' | '5min' | '10min' | '15min' | '30min'
  description:     string
  tags: {
    failureStyle?:      string[]
    primaryBlocker?:    string[]
    peakEnergyWindow?:  string[]
    coreDriver?:        string[]
  }
  neurochemTarget?: Array<'dopamine' | 'acetylcholine' | 'epinephrine' | 'gaba'>
  liteVersionId?:   string
}
```

### 6.2 Neurochemical event effects

| Event | DA | ACh | EPI | GABA |
|---|---|---|---|---|
| Complete habit | +25 (+40 if streak >5) | +20 (+30 if streak >5) | +5 | — |
| Urge surf | +15 | +10 | −10 | +30 |
| Log slip | −15 | +15 | +40 | −10 |
| Acknowledge comeback | +10–20 | +10 | −15 | +15 |
| Decay (per session) | → 50 at 8%/step | → 50 at 8%/step | → 50 at 8%/step | → 50 at 8%/step |

---

## 7. Neuroscience Foundations

The app is explicitly inspired by — not clinically prescribing — the following research. All claims in user-facing copy are hedged accordingly.

| Concept | Research basis |
|---|---|
| Dopamine as anticipation, not reward | Schultz, Dayan & Montague (1997) — prediction error signals |
| Myelination & neural pathway strength | R. Douglas Fields (2005), Coyle (2009) — myelin and skill acquisition; primary mechanism is basal ganglia LTP (Graybiel) |
| Habit automaticity timeline | Lally et al. (2010) — 18–254 days, median ~66 |
| Anchor cues = implementation intentions | Gollwitzer & Sheeran (2006) — "after I X, I will Y" doubles follow-through |
| One miss doesn't break a habit | Lally et al. (2010) — single misses had no significant effect on automaticity |
| Self-compassion for recovery | Neff (2003–2011) — self-compassion outperforms self-criticism for behavior maintenance |
| Sleep consolidates learning | Bellesi et al. (2013); Matthew Walker — ACh-dependent memory consolidation during sleep |
| Cold exposure → dopamine | Shevchuk (2008) — 30–60s cold water → 250%+ dopamine increase lasting 2–3 hours |
| GABA and meditation | Streeter et al. (2007, 2010) — direct MRS-measured GABA increase from yoga/meditation |
| Friction as habit intervention | Wendy Wood (2019) — environment/context change is the #1 predictor of habit disruption |
| Failure style archetypes | Maps to: perfectionism (Hewitt & Flett), avoidance (Hayes ACT), NfC scale (Cacioppo & Petty), trait self-control (Tangney et al.) |
| Error as neuroplasticity window | Morishita & Bhattacharya — norepinephrine spike post-error opens a learning window |
| Dynamic failure modes | Higgins (1997) regulatory focus theory — prevention/promotion focus shifts with context |

---

## 8. Technical Architecture

### 8.1 Stack

| Layer | Technology |
|---|---|
| Framework | React 19 + TypeScript |
| Build | Vite 8 |
| Styling | Tailwind CSS v4 (CSS-first config, `@variant dark`) |
| State | Zustand v5 + `persist` middleware (localStorage) |
| Animation | Framer Motion |
| Icons | lucide-react |
| Runtime | Node 20.19.0 (pinned in `.nvmrc`) |

### 8.2 Design system

**Color tokens (CSS custom properties):**

| Token | Light | Dark |
|---|---|---|
| `--bg` | `#FAFAF8` | `#0F1115` |
| `--surface` | `#FFFFFF` | `#171923` |
| `--surface-2` | `#F5F5F3` | `#1E2230` |
| `--text-1` | `#111111` | `#F0F0F0` |
| `--text-2` | `#555555` | `#9A9AA0` |
| `--text-3` | `#999999` | `#606068` |
| `--accent` | `#4F46E5` | `#818CF8` |

**Dark mode:** Responds to `data-theme="dark"` attribute on `<html>` (set by ThemeContext, persisted to localStorage).

**Component utilities:** `.card`, `.card-2`, `.btn-primary`, `.btn-secondary`, `.btn-ghost`, `.ns-input`, `.ns-label`, `.section-header`, `.progress-track`, `.pb-safe`

**Typography:** Inter (Google Fonts). Hero: text-4xl/5xl bold. H1: text-3xl bold. Body: text-base. Labels: text-[11px] uppercase tracking-wider.

### 8.3 State persistence

Zustand `persist` v2. Migration guard in store handles schema changes without wiping user data. Current migration: v0→v2 sets `onboardingComplete = true` for existing users who had habits saved.

### 8.4 File structure

```
src/
  pages/
    Onboarding.tsx          — 4-screen first-time flow
    BrainAssessment.tsx     — 8-question profile interview + reveal
    RoutineBlueprint.tsx    — post-assessment habit assignment review
    Dashboard.tsx           — returning user home screen
  components/
    HabitCard.tsx           — per-habit card with myelination + weekly grid
    NeurochemHUD.tsx        — 4-chemical status grid
    StatsBar.tsx            — 6-metric summary row
    BrainProfileCard.tsx    — collapsible archetype + dimensions card
    ComebackProtocol.tsx    — reframe + micro-actions modal
    ComebackGateModal.tsx   — freemium gate on 4th comeback
    WeeklyCheckin.tsx       — 5-step check-in bottom sheet
    RecalibrationSuggestions.tsx — accept/reject adjustment proposals
    RecoveryPlaybook.tsx    — failure pattern history + insights
    AddHabitModal.tsx       — guided habit creation modal
    SwapCard.tsx            — per-swap card with urge-surf / slip buttons
    WeeklyGrid.tsx          — 7-day completion dot grid
    FreemiumBanner.tsx      — upgrade nudge bar
  store/
    useNeuroStore.ts        — single Zustand store, all state + actions
  utils/
    neuroHelpers.ts         — myelination formula, streak calc, date utils
    blueprintEngine.ts      — habit scoring + blueprint selection
    recalibrationEngine.ts  — pure recalibration logic
    brainHelpers.ts         — archetype name lookup
    comebackHelpers.ts      — missed habit detection
    statsHelpers.ts         — weekly grid + stats computation
  data/
    habitLibrary.ts         — 30+ HabitTemplate objects with neurochemTarget tags
  contexts/
    ThemeContext.tsx         — dark/light mode, localStorage persistence
```

---

## 9. Freemium Model

### Free tier
- 3 Comeback Protocol activations per month
- Up to 2 active habits
- 1 active swap
- Weekly check-in + recalibration (full access)
- Brain Assessment (full access)

### Pro tier ($9/month or $79/year)
- Unlimited comebacks
- Unlimited habits and swaps
- Recovery Playbook v2 (pattern analysis, failure signatures)
- Pro-only: Failure pattern email report (weekly)
- Pro-only: Comeback streak leaderboard (opt-in, anonymous)
- Push notifications (daily digest)

### Upgrade trigger
The `ComebackGateModal` fires on the 4th comeback of the month. Shows Recovery Rate social proof (Pro vs free users) and an upgrade CTA.

---

## 10. Metrics & Success Criteria

### Product health metrics

| Metric | Definition | Target (alpha) |
|---|---|---|
| Recovery Rate | % of comebacks with micro-actions completed | Baseline data needed |
| Comeback activation | % of missed-habit sessions where Comeback Protocol is opened | >30% |
| Check-in completion | % of triggered check-ins completed | >50% |
| D7 retention | % of users active on day 7 | ≥40% |
| D30 retention | % of users active on day 30 | ≥20% |

### Alpha launch criteria (before public release)
- [ ] 5 non-friends have used it for 7+ days
- [ ] Comeback Protocol paywall live + Stripe connected
- [ ] Onboarding flow works without a guide (zero support messages from first 5 testers)
- [ ] Recovery Rate visible and users report it "means something"
- [ ] At least 3 users have said they'd pay

---

## 11. Phased Roadmap

### Phase 1 — Alpha (complete)
All P1 items shipped. App is functionally complete for first-user testing.

**Shipped:**
- 4-screen onboarding
- Brain Assessment (8Q, 16 archetypes)
- NeuroRoutine Blueprint (auto-assigned habits, swap UI)
- Dashboard (full component set, dark/light, mobile-first 375px)
- Comeback Protocol (personalised by profile)
- Freemium gate (3/month, ComebackGateModal)
- Weekly Check-in (5-step, environment + failure mode questions)
- Recalibration Engine (SCALE_DOWN / REPLACE / UPDATE_MICRO)
- Neurochemistry HUD (research-accurate descriptions + neurochemTarget scoring)
- Neural pathway strength formula (Lally-aligned, ~66 completions for 100%)
- Habit library (30+ templates with neurochemTarget tags)

### Phase 2 — Validation Sprint (Weeks 3–6)

**Goal:** 20 users, 30-day retention data.

| Feature | Priority |
|---|---|
| P2: Habit edit/archive (swipe-to-archive, no hard deletes) | High |
| P2: Neurochemistry tap-to-explain overlay | High |
| P2: Streak recovery badge in weekly grid | Medium |
| P2: Accounts + cloud sync (Supabase magic link) | Critical for cross-device |
| P2: Recovery Playbook v2 (failure signature patterns) | High |
| P2: Comeback streak metric | Medium |
| P2: Daily digest push notification (PWA or Capacitor) | Medium |
| P2: Share card (Brain Score + Recovery Rate image) | Low |
| Infra: CI (GitHub Actions — type check + build on PR) | High |
| Infra: Sentry (error tracking) | Medium |
| Infra: PostHog (product analytics) | High |
| Infra: Playwright smoke test | Medium |

### Phase 3 — Monetisation (Weeks 7–12)

**Goal:** $500 MRR.

| Feature | Priority |
|---|---|
| Stripe Checkout + webhooks | Critical |
| Upgrade paywall modal (social proof) | Critical |
| Pro: Failure pattern weekly email report | High |
| Pro: Comeback streaks leaderboard (opt-in, anonymous) | Medium |
| Retention email sequence (5 emails, D1/D3/D7/D14/D30) | High |
| Variable reward milestones (10%/25%/50%/75%/100% myelination) | Medium |
| Loss aversion nudge (3-day inactivity push) | Low |

### Phase 4 — Growth (Months 4–6)

**Goal:** $3,000 MRR, 300+ active users, D7 ≥35%, D30 ≥20%.

- Content moat: weekly newsletter "The Neuroscience of Not Quitting"
- YouTube SEO: 5–10 explainer videos (habit recovery neuroscience)
- App Store: React Native (Expo) or Capacitor wrapper
- AI Recovery Coach (Pro+): GPT-4o pattern analysis across 10 comebacks
- Recovery Playbook PDF export
- Team/accountability mode (pair Brain Scores)

### Phase 5 — Scale (Month 6+)

Hypotheses pending Phase 4 validation:
- API/integrations (Notion, Obsidian, Readwise)
- Coach dashboard (monitor client Recovery Rates)
- Corporate wellness (L&D team behavior change tracking)
- Science partnership (IRB-approved myelination proxy study)
- Localisation (Japanese, German markets)

---

## 12. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Users don't activate Comeback Protocol (shame barrier) | High | Critical | Celebrate activation as strength in UX copy. A/B test modal framing. |
| Freemium users never convert | Medium | High | Tighten free tier post-20-users: try 2 comebacks/month instead of 3 |
| Streak-app competitor copies comeback mechanic | Medium | Medium | Moat is the Personal Recovery Playbook data — not the mechanic |
| Neuroscience accuracy claims scrutinised | Low | Medium | Keep all claims hedged: "inspired by," "maps to" — never "clinically proven" |
| Neural pathway 100% feels meaningless | Low | Medium | Stage labels (Forming → Well-established) provide richer feedback than % alone |
| Context-only localStorage data loss | Medium | High | Phase 2: Supabase cloud sync is a prerequisite before public launch |
| Build breakage on Node version drift | Low | Low | `.nvmrc` pins Node 20.19.0 |

---

## 13. Open Questions

1. **Check-in cadence:** Research suggests new habits (<3 weeks) benefit from 3–4 day review, not 7 days. Should the check-in interval adapt based on habit myelination level? Current implementation: flat 7-day trigger.

2. **Failure mode recalibration:** `currentFailureMode` is now captured in check-ins but not yet used to update the comeback reframe dynamically. The recalibration engine should read the last 2 `currentFailureMode` values and switch the comeback protocol tone if consistently different from `brainProfile.failureStyle`.

3. **Neurochemical baselines:** The initial `Neurochemistry` state is slightly elevated (dopamine 65, GABA 60) to create an optimistic first-day feel. This could be misleading for users who interpret it as a real baseline. Consider adding a tooltip clarifying this is a starting model, not a measurement.

4. **Habit count freemium limit:** Currently 2 habits max on free tier — but the blueprint auto-assigns 3–5. Do blueprint habits count against the limit from day 1, or do they start unlimited and lock only when adding new ones manually?

5. **Myelination decay:** The neural pathway formula only grows — it never decays when the user misses days. Research on synaptic LTD suggests short gaps (<3 days) don't cause meaningful decay, but longer gaps do. A mild decay mechanic could reinforce the "comeback early" message without causing abandonment.

---

## 14. Launch Definition

**Target:** Early July 2026 (6–8 weeks from now).

**Launch = the moment you post publicly and invite strangers.**

You are ready when:
1. Onboarding works without a guide (zero support requests from first 5 testers)
2. Comeback Protocol paywall live with Stripe connected
3. At least 5 non-friends have used it for 7+ days
4. Recovery Rate is tracked and users report it feels meaningful
5. You can say in one sentence: *"NeuroSync is a personal recovery system that helps you get back on track after you miss a habit — instead of starting over from zero."*
