# NeuroSync — Product Roadmap to Launch

> **Mission:** Give execution-focused people a personal recovery system for habit failure — not another streak tracker.
>
> **Core mechanic:** The Comeback Protocol. You activate it when you fail, not when you succeed.
> **Primary metric:** Recovery Rate (% of comebacks where micro-actions were completed), not DAU.

---

## Complete App Flow (Current State)

```
NEW USER
  │
  ▼
┌─────────────────────────────────────────────────────────────┐
│  ONBOARDING  (4 screens)                                    │
│                                                             │
│  Screen 1 — Welcome                                         │
│    "Your brain is wired for recovery — not perfection."     │
│    [Get Started →]                                          │
│                                                             │
│  Screen 2 — Profile Setup                                   │
│    Name + Role (Builder / Designer / Athlete / Student)     │
│    [Continue →]                                             │
│                                                             │
│  Screen 3 — First Habit                                     │
│    Role-personalised suggestions (3 per role, tap to add)  │
│    Custom habit form (title, anchor cue, action, reward)   │
│    [Add and Continue →]                                     │
│                                                             │
│  Screen 4 — Comeback Protocol Explainer                     │
│    "You WILL miss days. That's where the real protocol is." │
│    [Begin your system →] → sets onboardingComplete = true   │
└─────────────────────────────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────────────────────────────┐
│  BRAIN ASSESSMENT  (NeuroSync Brain)                        │
│                                                             │
│  8 questions, one at a time, Typeform-style                 │
│  Progress dots across top. Tap card → auto-advance.        │
│                                                             │
│  Q1  When you miss something, what's your first instinct?  │
│      → failureStyle: perfectionist | avoider | analyst | drifter
│                                                             │
│  Q2  What usually gets you started on a habit?             │
│      → motivationSource: identity | outcome | process | survival
│                                                             │
│  Q3  When is your mental energy highest?                   │
│      → peakEnergyWindow: morning | afternoon | evening | variable
│                                                             │
│  Q4  After a setback, how long do you feel stuck?          │
│      → recoverySpeed: fast | medium | slow | variable       │
│                                                             │
│  Q5  What most often breaks your habits?                   │
│      → primaryBlocker: energy | overwhelm | distraction | life
│                                                             │
│  Q6  What does your inner voice say after missing?         │
│      → selfTalkPattern: self-critical | avoidant | rational | hopeless
│                                                             │
│  Q7  How do you best hold yourself accountable?            │
│      → accountabilityStyle: tracking | external | systems | none
│                                                             │
│  Q8  What do you actually want your habits to do?          │
│      → coreDriver: feel-better | perform-better | become-someone | survive
│                                                             │
│  ── 1.5s processing animation ──                           │
│                                                             │
│  PROFILE REVEAL                                             │
│    Archetype name (16 unique: 4 failureStyles × 4 drivers) │
│    e.g. "The Driven Perfectionist", "The Comfort Seeker"   │
│    4 personalised insight cards                             │
│    Dimension summary grid (6 fields)                       │
│    [Apply to my system →] → sets brainProfile in store     │
└─────────────────────────────────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────────────────────────────────┐
│  DASHBOARD  (Returning user home)                           │
│                                                             │
│  HEADER                                                     │
│    Hey, {name} · {role}                                     │
│    Brain Score (0–100, colour-coded)                        │
│    Dopamine Points counter                                   │
│                                                             │
│  ── if missed habits exist ──                               │
│  COMEBACK PROTOCOL OVERLAY                                  │
│    CBT reframe headline (personalised by failureStyle)      │
│    Energy-aware micro-actions (by peakEnergyWindow + blocker)
│    Tap steps to complete → acknowledgeComeback()            │
│                                                             │
│  FREEMIUM BANNER                                            │
│    Free: 3 comebacks/month. Pro: unlimited.                 │
│                                                             │
│  NEUROCHEMISTRY HUD                                         │
│    Dopamine / Acetylcholine / Epinephrine / GABA bars       │
│    Decay over time, spike on actions                        │
│                                                             │
│  STATS BAR                                                  │
│    Recovery Rate · Comebacks · Best Streak                  │
│    Active Habits · Days in System · Brain Score             │
│                                                             │
│  NEURAL PROFILE CARD (collapsible)                          │
│    Archetype name + failure style badge                     │
│    Expandable: 6 dimension values                           │
│    [Retake assessment] → clears brainProfile → routes back  │
│                                                             │
│  RECOVERY PLAYBOOK                                          │
│    Personal failure pattern history                         │
│    AI-surfaced recovery insights                            │
│                                                             │
│  TABS                                                       │
│    [Habits] [Swaps] [Activity Log]                          │
│                                                             │
│  HABITS TAB                                                 │
│    HabitCard per stack:                                     │
│      - Myelination progress bar                             │
│      - 7-day weekly grid (completions + gaps)               │
│      - Streak counter                                        │
│      - [✓ Complete] [↩ Comeback] buttons                   │
│    Empty state: [+ Add your first habit]                    │
│    FAB: + Add Habit                                         │
│                                                             │
│  SWAPS TAB                                                  │
│    SwapCard per swap:                                       │
│      - Bad response description                             │
│      - Friction steps                                        │
│      - [Surfed Urge] [Logged Slip] buttons                  │
│    Empty state: [+ Add your first swap]                     │
│                                                             │
│  ACTIVITY LOG TAB                                           │
│    Timeline of: completions / urge surfs / slips / comebacks│
│    Dopamine change per event (+/-)                          │
└─────────────────────────────────────────────────────────────┘
```

### Personalisation matrix (Brain → App)

| Brain dimension | What it changes in the app |
|---|---|
| `failureStyle` | Comeback Protocol reframe tone (perfectionist / avoider / analyst / drifter) |
| `peakEnergyWindow` | Micro-action set shown in Comeback Protocol (morning / afternoon / evening / variable) |
| `primaryBlocker` | Micro-action sub-set (energy / overwhelm / distraction / life) |
| `coreDriver` | Archetype name + profile insight #4 language |
| `accountabilityStyle` | Profile insight #3 framing |
| `selfTalkPattern` | Display label in BrainProfileCard |
| `recoverySpeed` | Profile insight framing (fast recoverer vs slow processor) |
| `motivationSource` | Profile insight #1 framing |

### State routing logic

```
App boots
  └─ onboardingComplete = false  → Onboarding
  └─ onboardingComplete = true
       └─ brainProfile = null     → BrainAssessment
       └─ brainProfile ≠ null     → Dashboard
```

### Key data model

```typescript
NeuroBrainProfile {
  failureStyle:       'perfectionist' | 'avoider' | 'analyst' | 'drifter'
  peakEnergyWindow:   'morning' | 'afternoon' | 'evening' | 'variable'
  recoverySpeed:      'fast' | 'medium' | 'slow' | 'variable'
  primaryBlocker:     'energy' | 'overwhelm' | 'distraction' | 'life'
  selfTalkPattern:    'self-critical' | 'avoidant' | 'rational' | 'hopeless'
  motivationSource:   'identity' | 'outcome' | 'process' | 'survival'
  accountabilityStyle:'tracking' | 'external' | 'systems' | 'none'
  coreDriver:         'feel-better' | 'perform-better' | 'become-someone' | 'survive'
  completedAt:        string (ISO timestamp)
}
```

16 archetypes derived from `failureStyle × coreDriver`:

| | feel-better | perform-better | become-someone | survive |
|---|---|---|---|---|
| **perfectionist** | The Burnt-Out Achiever | The Driven Perfectionist | The Identity Builder | The Pressure Coper |
| **avoider** | The Comfort Seeker | The Hidden High-Performer | The Reluctant Transformer | The Overwhelmed Avoider |
| **analyst** | The Thoughtful Optimizer | The Strategic Performer | The Deliberate Builder | The Rational Survivor |
| **drifter** | The Gentle Restarter | The Latent Performer | The Wandering Visionary | The Day-to-Day Drifter |

---

## Where We Are Now (v0.1 — MVP Done)

**Shipped:**
- Neurochemistry HUD (dopamine, acetylcholine, epinephrine, GABA)
- Neuro-Stack habits with myelination progress, 7-day weekly grid, streak tracking
- Neuro-Swap bad habit interception with friction levels and urge-surfing
- Comeback Protocol — CBT reframe + micro-action re-entry modal
- Recovery Playbook — personal failure pattern history + AI-surface insights
- Brain Score (composite: myelination 40% + recovery rate 30% + chem health 30%)
- Stats Bar (recovery rate, comebacks, best streak, active habits, days in system)
- Add Habit / Add Swap modals with guided fields
- Freemium banner (3 comebacks/month free, upgrade CTA)
- Activity Log with dopamine change tracking
- Zustand v5 + localStorage persistence
- Dark glass-panel design system
- **4-screen onboarding flow** (name + role + first habit + comeback explainer)
- **NeuroSync Brain** — 8-question psychological interview, 16-archetype profile reveal, BrainProfileCard in Dashboard
- Comeback Protocol personalised by `failureStyle` + `peakEnergyWindow` + `primaryBlocker`

**Stack:** React 19 + TypeScript + Vite 8 + Tailwind CSS v4 + Zustand v5 + lucide-react

---

## Adaptive Brain Loop — Core Vision

> **The system should understand you, assign what to do, watch what happens, ask how it's going, then update itself.**

This is the gap between v0.1 and a product that actually rewires behaviour. Three systems need to be built to close it:

| Gap | Current state | What we're building |
|---|---|---|
| Profile → assigned habits | User manually adds their own | NeuroRoutine Blueprint (auto-assigned starter pack) |
| Periodic check-in | Nothing | Weekly Check-in Protocol (60-second feedback) |
| Adapt tasks to reality | Static habits never change | Recalibration Engine (adjusts after each check-in) |

### Updated state routing

```
App boots
  └─ onboardingComplete = false         → Onboarding
  └─ onboardingComplete = true
       └─ brainProfile = null            → BrainAssessment
       └─ blueprintAccepted = false      → RoutineBlueprint        ← NEW
       └─ daysSinceCheckin >= 7          → WeeklyCheckin overlay   ← NEW
       └─ default                        → Dashboard
```

---

## System A — NeuroRoutine Blueprint ✅

**What:** After the brain profile reveal, instead of a blank dashboard, show a personalised starter routine of 3–5 habits auto-selected from a curated library of 40+ templates. User reviews, swaps, or removes before confirming.

**Why it matters:** The current blank-state problem kills activation. Users who see a personalised plan on day 1 are far more likely to return on day 2.

**New files:**
- `src/pages/RoutineBlueprint.tsx` — full-screen review UI, card per assigned habit with swap/remove
- `src/data/habitLibrary.ts` — 40+ `HabitTemplate` objects tagged by profile dimensions
- `src/utils/blueprintEngine.ts` — scoring function: given a `NeuroBrainProfile`, returns top 3–5 ranked habits

**New data model:**
```typescript
HabitTemplate {
  id: string
  title: string
  cue: string
  category: 'morning' | 'focus' | 'recovery' | 'evening'
  energyRequired: 'low' | 'medium' | 'high'
  duration: '2min' | '5min' | '15min' | '30min'
  tags: {
    failureStyle?: string[]
    primaryBlocker?: string[]
    peakEnergyWindow?: string[]
    coreDriver?: string[]
  }
  liteVersion?: string  // ID of lower-intensity variant
}
```

**New store field:** `blueprintAccepted: boolean` (default `false`)

**Scoring logic in `blueprintEngine.ts`:**
- +3 pts if habit tag matches user's `peakEnergyWindow`
- +2 pts if habit tag matches user's `primaryBlocker` mitigation
- +2 pts if habit tag matches user's `coreDriver`
- +1 pt if habit tag matches user's `failureStyle` recovery pattern
- Return top 5 by score, ensure at least 1 per category

**Build estimate:** 1 day

---

## System B — Weekly Check-in Protocol ✅

**What:** Every 7 days, when the user opens the Dashboard, a bottom sheet appears with 4 questions (60 seconds total). Answers are stored and feed into the Recalibration Engine.

**New files:**
- `src/components/WeeklyCheckin.tsx` — bottom sheet, 4-step micro-survey
- Trigger in `src/pages/Dashboard.tsx` — check `daysSinceLastCheckin >= 7` on mount

**The 4 questions:**

| # | Question | Input type | Maps to |
|---|---|---|---|
| 1 | "How consistent were you this week?" | 1–5 tap scale | `consistency` |
| 2 | "What was your biggest blocker?" | Same options as Brain Q5 | `weeklyBlocker` |
| 3 | "How's your overall energy been?" | Low / Normal / High tap | `energyLevel` |
| 4 | "Any big changes to your routine?" | Yes / No (Yes → free text) | `routineChanged` |

**New data model:**
```typescript
CheckinRecord {
  date: string           // ISO timestamp
  consistency: 1 | 2 | 3 | 4 | 5
  weeklyBlocker: string
  energyLevel: 'low' | 'normal' | 'high'
  routineChanged: boolean
  routineNote?: string
  recalibrationApplied: boolean
}
```

**New store fields:** `lastCheckinDate: string | null`, `checkinHistory: CheckinRecord[]`

**Build estimate:** 1 day

---

## System C — Recalibration Engine ✅

**What:** A pure-logic utility that runs after each check-in. Reads `checkinHistory` + habit completion data and returns a list of suggested adjustments. User approves or rejects each one.

**New files:**
- `src/utils/recalibrationEngine.ts` — pure function, no side effects
- `src/components/RecalibrationSuggestions.tsx` — shown after check-in if suggestions exist

**Three adjustment types the engine can produce:**

```
SCALE_DOWN   — habit has <40% completion for 2+ weeks
               → suggest swapping to liteVersion from habitLibrary
               → e.g. "30-min deep work" → "10-min deep work"

REPLACE      — habit has 0% completion for 14 days
               → suggest a replacement from habitLibrary (same category, different tags)
               → old habit archived, not deleted

UPDATE_MICRO — weeklyBlocker changed vs Brain Assessment primaryBlocker
               → update micro-action set used in Comeback Protocol
               → e.g. blocker was "energy", now "distraction" → swap action set
```

**Recalibration record:**
```typescript
RecalibrationEvent {
  date: string
  trigger: 'weekly-checkin'
  suggestions: RecalibrationSuggestion[]
  accepted: string[]   // suggestion IDs user approved
  rejected: string[]
}

RecalibrationSuggestion {
  id: string
  type: 'SCALE_DOWN' | 'REPLACE' | 'UPDATE_MICRO'
  habitId?: string
  reason: string        // shown to user, plain English
  fromValue: string
  toValue: string
}
```

**New store fields:** `recalibrationLog: RecalibrationEvent[]`

**Build estimate:** 1 day for engine + 0.5 day for suggestions UI

---

## Build order for the adaptive loop

| Order | System | File(s) | Est. |
|---|---|---|---|
| 1 | Habit library data | `src/data/habitLibrary.ts` | 2h |
| 2 | Blueprint scoring engine | `src/utils/blueprintEngine.ts` | 1h |
| 3 | RoutineBlueprint screen | `src/pages/RoutineBlueprint.tsx` | 4h |
| 4 | Store fields + routing | `src/store/useNeuroStore.ts`, `src/App.tsx` | 1h |
| 5 | WeeklyCheckin component | `src/components/WeeklyCheckin.tsx` | 3h |
| 6 | Dashboard check-in trigger | `src/pages/Dashboard.tsx` | 1h |
| 7 | Recalibration engine | `src/utils/recalibrationEngine.ts` | 3h |
| 8 | RecalibrationSuggestions UI | `src/components/RecalibrationSuggestions.tsx` | 2h |

**Total: ~3.5 days** for the complete adaptive loop.

---

## Phase 1 — Alpha Polish (Weeks 1–2)

**Goal:** Make the core loop feel real enough to test with 5–10 people.

### P1 — Must ship

- [x] **User onboarding flow** — 4-screen setup: name/role, add first habit, explain the Comeback Protocol. No blank-state first launch.
- [x] **NeuroRoutine Blueprint** — post-assessment screen that auto-assigns 3–5 habits from a profile-scored library. Eliminates blank dashboard. *(System A above)*
- [x] **Weekly Check-in Protocol** — 60-second 4-question bottom sheet, triggers every 7 days. *(System B above)*
- [x] **Recalibration Engine** — adjusts habit difficulty/type after each check-in. *(System C above)*
- [x] **Comeback Protocol gate** — enforce 3 free/month limit. Show freemium modal on 4th trigger.
- [x] **Persistence reliability** — Zustand v2 migration guard handles localStorage schema changes without wiping data.
- [x] **Mobile-first layout pass** — verify everything works on 375px. Tab bar should be thumb-reachable.
- [x] **Empty-state habit prompts** — 15 role-personalised habit suggestions (3 per role) shown during onboarding.

### P2 — Should ship

- [ ] **Habit edit/archive** — swipe-to-archive on habit card. No hard deletes in alpha.
- [ ] **Neurochemistry explanations** — tap a chemical bar to see a 2-sentence explainer + what raised/lowered it today.
- [ ] **Myelination tooltip** — "What is myelination?" inline explanation for first-time users.
- [ ] **Streak recovery badge** — visual reward when a user comes back after a gap (the "comeback" cell in the weekly grid).

---

## Phase 2 — Validation Sprint (Weeks 3–6)

**Goal:** 20 real users, 30-day retention data, confirm Recovery Rate as the sticky metric.

### Metrics to hit before moving to Phase 3
- 20+ users who've activated the Comeback Protocol at least once
- Recovery Rate data from at least 10 users (need baseline)
- 1-week retention ≥ 40%
- At least 3 users who've paid or said they'd pay

### What to build

- [ ] **Accounts + cloud sync** — Supabase auth (email magic link) + Postgres backend. This unlocks cross-device and is the prerequisite for paid tier.
- [ ] **Personal Recovery Playbook v2** — pattern analysis: which habit do you slip on most? What day of the week? Surface these as "Your failure signatures."
- [ ] **Comeback streak** — track consecutive days where the Comeback Protocol was activated (different from habit streak — this rewards showing up after failure).
- [ ] **Daily digest push notification** — one notification at 8 PM: "You've been consistent for X days" OR "You missed [habit] — open your playbook." Requires PWA or native wrapper.
- [ ] **Share card** — shareable image of Brain Score + Recovery Rate. No viral loop, just seed organic sharing.
- [ ] **Referral hook** — "Invite a fellow builder — they get 1 free month Pro." Simple referral code, no complex tracking needed at this stage.

### GTM for validation
- Post on X/Twitter (builder audience) — build in public, share Brain Score screenshots
- Share in communities: Ness Labs, Ali Abdaal Discord, developer Slack groups
- Cold DM 20 people who match the archetype (27–32, SW engineer, talk about consistency publicly)
- Offer free 1:1 "neuro audit" for first 10 users in exchange for feedback session

---

## Phase 3 — Monetization & Retention (Weeks 7–12)

**Goal:** $500 MRR. Prove someone will pay for the recovery system, not just use it free.

### Freemium gate (already partially built)
- Free tier: 3 Comeback Protocol activations/month, 2 habits max, 1 swap max
- Pro ($9/month): unlimited comebacks, unlimited habits/swaps, Recovery Playbook v2, pattern insights, push notifications
- Annual plan ($79/year) — offer at upgrade moment only

### What to build

- [ ] **Stripe integration** — Stripe Checkout + webhooks to flip `isPro` in Supabase. Keep it simple: one product, two prices (monthly/annual).
- [ ] **Upgrade paywall modal** — triggered on 4th comeback of the month. Show Recovery Rate of Pro users vs free users (social proof). CTA: "Unlock your full recovery engine."
- [ ] **Pro-only: Failure pattern report** — weekly email summary: your top failure day, your fastest comeback, your most myelinated habit. Auto-generated from user data.
- [ ] **Pro-only: Comeback streaks leaderboard (opt-in)** — anonymous leaderboard of comeback streaks. "You're in the top 12% of recovery rates this week." No names, just archetypes.
- [ ] **Retention email sequence (5 emails)**
  1. Day 1: Welcome + what the Brain Score means
  2. Day 3: "Your first habit is building myelination — here's the science"
  3. Day 7: Recovery Rate explanation + how to improve it
  4. Day 14: "You've been in the system 2 weeks — here's your pattern"
  5. Day 30: Milestone recap + Pro upgrade offer

### Retention mechanics
- [ ] **Variable reward schedule** — myelination milestones (10%, 25%, 50%, 75%, 100%) trigger a dopamine burst animation + notification
- [ ] **Loss aversion nudge** — if user hasn't opened in 3 days, send: "Your myelination is decaying without reinforcement." Neuroscience-accurate, not guilt.
- [ ] **Comeback streak protection** — if user goes 2 days without a comeback acknowledgment, show a "Your playbook needs you" prompt

---

## Phase 4 — Growth & Product-Market Fit (Months 4–6)

**Goal:** $3,000 MRR, 300+ active users, clear retention curve (D7 ≥ 35%, D30 ≥ 20%).

### Distribution
- [ ] **Content moat** — weekly Substack/newsletter: "The Neuroscience of Not Quitting." Each issue ties a neuroscience concept to a Comeback Protocol example. Link back to app.
- [ ] **YouTube SEO** — 5–10 videos: "Why your habit tracker is making you quit faster," "The myelination protocol," "What dopamine actually does to your habits." Drive organic search.
- [ ] **App Store presence** — wrap as React Native (Expo) or Capacitor PWA. App Store discovery for "habit tracker" + "habit recovery" is underserved.
- [ ] **Integration hooks** — "Log comeback from Notion" / "Sync with Apple Health workouts" — extend the anchor cue concept into existing tools.

### Product moat deepening
- [ ] **AI Recovery Coach (Pro+)** — on comeback activation, offer optional "Why did you slip?" journaling. GPT-4o analyzes patterns across last 10 comebacks and returns a personalized insight. This is the non-transferable, compounding data asset.
- [ ] **Recovery Playbook export** — PDF export of your personal failure patterns + recovery signatures. The playbook becomes yours — you take it with you even if you leave the app. This builds trust, not lock-in.
- [ ] **Team / accountability mode** — two people share their Brain Scores and get notified when one activates a comeback. Pairs, not public groups.

### Pricing iteration
- Run a pricing page A/B test: $9 vs $12 vs $15/month
- Add a $29 lifetime deal for first 100 Pro users (one-time, creates urgency, seed MRR)
- Consider B2B angle: sell "team recovery dashboards" to remote-first engineering teams ($49/month/team of 5)

---

## Phase 5 — Scale (Month 6+)

These are hypotheses, not commitments. Revisit after Phase 4 data.

- **API / integrations marketplace** — let power users connect Notion, Obsidian, Readwise to auto-generate habits from notes
- **Coach dashboard** — productivity coaches can monitor client Recovery Rates + assign comeback protocols
- **Corporate wellness** — enterprise version for L&D teams tracking behavior change post-training
- **Science partnership** — collaborate with a neuroscience lab for IRB-approved study on myelination proxies. Publish results. Build academic credibility.
- **Localization** — Japanese and German markets over-index on self-improvement apps

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Users don't activate Comeback Protocol (shame barrier) | High | Critical | Reframe in UX: celebrate the activation as strength, not failure. A/B test the modal copy. |
| Freemium users never convert | Medium | High | Tighten free tier after 20 users — move limit to 2 comebacks, not 3 |
| Competitor (Streaks, Habitica) copies the comeback mechanic | Medium | Medium | Our moat is the Personal Recovery Playbook data — not the mechanic itself |
| Neuroscience claims scrutinized | Low | Medium | Keep claims hedged ("inspired by," "maps to") — never "clinically proven" |
| Node/Vite version drift breaks builds | Low | Low | Pin Node version in `.nvmrc` (Node 20.19+) |

---

## Technical Debt & Infrastructure

Before Phase 2 launch:
- [x] Add `.nvmrc` file pinning Node `20.19.0`
- [ ] Set up CI (GitHub Actions) — type check + build on every PR
- [ ] Add Sentry for error tracking (free tier)
- [ ] Add PostHog for product analytics (free tier, self-hostable)
- [x] Write a migration helper for Zustand `persist` schema versioning
- [ ] Add Playwright smoke test: load app → complete a habit → activate comeback protocol

---

## Definition of "Launch"

**Launch = the moment you post publicly and invite strangers.**

You're ready to launch when:
- [ ] Onboarding flow works without a guide
- [ ] Comeback Protocol paywall is live and Stripe is connected
- [ ] At least 5 non-friends have used it for 7+ days
- [ ] You can explain the product in one sentence: *"NeuroSync is a personal recovery system that helps you get back on track after you miss a habit — instead of starting over from zero."*
- [ ] Recovery Rate is being tracked and makes users feel something

**Target launch date:** 6–8 weeks from today (by early July 2026).

---

## One-Line North Star

> **Every comeback you log strengthens your playbook. That playbook is yours, and no other app has it.**
