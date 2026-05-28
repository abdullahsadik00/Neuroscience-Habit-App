# NeuroSync — Build Status & Complete Plan

> Last updated: 2026-05-28  
> Stack: React 19 · TypeScript · Vite 8 · Tailwind CSS v4 · Zustand v5 · lucide-react · framer-motion

---

## What Is This App

NeuroSync is a personal habit recovery system for execution-focused people who keep failing the same habits.

**Core mechanic:** The Comeback Protocol activates *when you miss* — not when you succeed.  
**North star metric:** Recovery Rate (% of comebacks where micro-actions were completed).  
**Anti-pattern:** Deliberately anti-streak. No gamified streak counters that punish failure.

---

## Current Build State

### ✅ Shipped — Core Systems

| Feature | Description |
|---|---|
| Onboarding (4 screens) | Name + role → first habit → Comeback Protocol explainer |
| Brain Assessment | 8-question psychological interview → 16-archetype profile (failureStyle × coreDriver) |
| NeuroRoutine Blueprint | Post-assessment screen auto-assigns 3–5 habits from profile-scored library of 40+ templates |
| Dashboard | Full home screen with all panels below |
| Neurochemistry HUD | Live DA / ACh / EPI / GABA bars, tap to expand science explainer + today's movements |
| Habit Cards (Neuro-Stacks) | Myelination progress, 7-day weekly grid, streak counter, complete button |
| Implementation Intentions | When → Then panel on every habit card; live II preview in Add Habit modal |
| Myelination Tooltip | "?" button opens Lally et al. explainer inline on each habit card |
| Milestone Celebrations | Toast + glow animation when habit crosses 10/25/50/75/100% — variable reward schedule |
| Comeback Protocol | CBT reframe + energy-aware micro-actions modal; personalised by failureStyle + peakEnergyWindow |
| Comeback Protocol Gate | 3 free/month limit; freemium upgrade modal on 4th trigger |
| Habit Archive | Kebab menu → archive (isActive=false, no hard deletes); collapsible restored section |
| Bad Habit Swaps (Neuro-Swaps) | Friction levels + urge surfing + slip logging |
| Weekly Grid | 7-day completion grid; amber comeback cells; ↩ badge on recovery-after-gap |
| Comeback Streak | Consecutive days the Comeback Protocol fired (separate from habit streak) |
| Recovery Playbook | Personal failure pattern history + AI-surfaced recovery insights |
| Stats Bar | Recovery Rate · Comeback Streak · Total Comebacks · Best Streak · Active Habits · Days In |
| Brain Profile Card | Archetype name, failure style badge, 6 dimension values, retake button |
| Weekly Check-in Protocol | 60-second 4-question bottom sheet every 7 days |
| Recalibration Engine | SCALE_DOWN / REPLACE / UPDATE_MICRO suggestions after each check-in |
| Activity Log | Timeline of completions / urge surfs / slips / comebacks with dopamine deltas |
| Dark / Light theme | Glass-panel dark default, toggleable light mode |
| PWA-ready | Vite PWA plugin, service worker, offline-capable |
| Persistence | Zustand v5 + localStorage, schema migration guard (v2) |

---

## What's Pending

### Phase 2 — Validation Sprint (Weeks 3–6)

Goal: 20 real users · 30-day retention · confirm Recovery Rate is sticky

| Item | Priority | Notes |
|---|---|---|
| **Accounts + cloud sync** | 🔴 Critical | Supabase auth (email magic link) + Postgres. Prerequisite for paid tier and cross-device. |
| **Personal Recovery Playbook v2** | 🟠 High | "Failure signatures" — which habit slips most, which day of week, fastest comeback pattern. |
| **Daily digest push notification** | 🟠 High | 8 PM: "You've been consistent X days" OR "You missed [habit] — open your playbook." Requires PWA push or native wrapper. |
| **Share card** | 🟡 Medium | Shareable image of Brain Score + Recovery Rate. Seeds organic sharing without a viral loop. |
| **Referral hook** | 🟡 Medium | "Invite a builder — they get 1 free month Pro." Simple referral code, no complex tracking. |
| **Loss aversion nudge** | 🟡 Medium | After 3 days without opening: "Your myelination is decaying without reinforcement." Neuroscience-accurate, not guilt. |

**Metrics gate before Phase 3:**
- 20+ users who've activated the Comeback Protocol at least once
- Recovery Rate data from ≥ 10 users
- 1-week retention ≥ 40%
- ≥ 3 users who've paid or said they'd pay

---

### Phase 3 — Monetization & Retention (Weeks 7–12)

Goal: $500 MRR · prove someone will pay for recovery, not just use it free

| Item | Priority | Notes |
|---|---|---|
| **Stripe integration** | 🔴 Critical | Stripe Checkout + webhooks to flip `isPro` in Supabase. One product, two prices (monthly/annual). |
| **Upgrade paywall modal** | 🔴 Critical | Triggered on 4th comeback. Show Recovery Rate of Pro vs free users (social proof). |
| **Comeback streak protection** | 🟠 High | 2 days no comeback acknowledgment → "Your playbook needs you" prompt. |
| **Variable reward milestones** | ✅ Done | Myelination milestone toast at 10/25/50/75/100%. |
| **Failure pattern report (Pro)** | 🟠 High | Weekly email: top failure day, fastest comeback, most myelinated habit. |
| **Comeback leaderboard (Pro, opt-in)** | 🟡 Medium | Anonymous by archetype. "You're in the top 12% of recovery rates this week." |
| **Retention email sequence (5 emails)** | 🟠 High | Day 1/3/7/14/30 sequence. See Phase 3 details in ROADMAP.md. |

**Freemium gate (partially built):**
- Free: 3 Comeback Protocol activations/month, 2 habits max, 1 swap max
- Pro ($9/month): unlimited comebacks, unlimited habits/swaps, Playbook v2, pattern insights, push notifications
- Annual ($79/year): offer at upgrade moment only

---

### Phase 4 — Growth & Product-Market Fit (Months 4–6)

Goal: $3,000 MRR · 300+ active users · D7 ≥ 35%, D30 ≥ 20%

| Item | Notes |
|---|---|
| **Content moat** | Weekly Substack: "The Neuroscience of Not Quitting." Each issue ties a concept to a Comeback Protocol example. |
| **YouTube SEO** | 5–10 videos targeting "habit tracker", "why habit trackers fail", "myelination protocol". |
| **App Store presence** | Wrap as Capacitor PWA or React Native (Expo). App Store discovery for "habit recovery" is underserved. |
| **AI Recovery Coach (Pro+)** | Optional "Why did you slip?" journaling. Claude analyzes patterns across last 10 comebacks → personalized insight. |
| **Recovery Playbook export** | PDF export of failure patterns + recovery signatures. Users take it with them — trust, not lock-in. |
| **Team / accountability mode** | Two people share Brain Scores, get notified when one activates a comeback. Pairs, not public groups. |
| **Integration hooks** | "Log comeback from Notion" / "Sync with Apple Health workouts." |

**Pricing iteration:**
- A/B test $9 vs $12 vs $15/month
- $29 lifetime deal for first 100 Pro users
- B2B angle: team recovery dashboards at $49/month/team of 5

---

### Phase 5 — Scale (Month 6+)

| Item | Notes |
|---|---|
| API / integrations marketplace | Connect Notion, Obsidian, Readwise to auto-generate habits from notes |
| Coach dashboard | Productivity coaches monitor client Recovery Rates + assign comeback protocols |
| Corporate wellness | Enterprise L&D version tracking behavior change post-training |
| Science partnership | IRB-approved neuroscience study on myelination proxies. Publish. Build credibility. |
| Localization | Japanese + German markets over-index on self-improvement apps |

---

## Technical Debt

| Item | Status |
|---|---|
| CI (GitHub Actions) — type check + build on every PR | ⬜ Not done |
| Sentry error tracking (free tier) | ⬜ Not done |
| PostHog product analytics (free tier) | ⬜ Not done |
| Playwright smoke test: onboarding → complete habit → activate comeback | ⬜ Not done |
| Pre-existing unused-variable TS warnings (TS6133) | ⬜ Non-blocking, clean up before launch |
| Hard delete `deleteNeuroStack` still in store (should be archive-only in alpha) | ⬜ Guard or remove |

---

## Launch Checklist

You're ready to launch publicly when:

- [ ] Onboarding works without a guide for a stranger
- [ ] Comeback Protocol paywall is live and Stripe is connected
- [ ] At least 5 non-friends have used it for 7+ days
- [ ] Recovery Rate is being tracked and makes users feel something
- [ ] You can say in one sentence: *"NeuroSync is a personal recovery system that helps you get back on track after you miss a habit — instead of starting over from zero."*

**Target launch date:** Early–mid July 2026

---

## Neuroscience Principles in the App

| Principle | Source | Where it appears |
|---|---|---|
| Habit automaticity takes 18–254 days (median ~66) | Lally et al., 2010 | Myelination progress bar formula + tooltip |
| Implementation intentions triple follow-through | Gollwitzer, 1999 | When → Then panel on every habit card |
| Self-compassion reduces shame-driven abandonment | Neff, 2003 | Comeback Protocol reframe copy |
| Dopamine fires at anticipation, not reward | Berridge; Schultz | NeurochemHUD description + explainer |
| ACh gates neuroplasticity windows | Hasselmo, 2006 | ACh tracked during focus habits |
| Error signals open neuroplasticity windows | Gu & Bhattacharyya | Slip logging spikes EPI — reframed as a teaching signal |
| Variable ratio reinforcement is most durable | Skinner | Milestone celebrations at unpredictable completion counts |
| Basal ganglia LTP encodes automatic behaviors | Graybiel | Myelination metaphor for pathway strength |
| Context change is #1 predictor of habit disruption | Wendy Wood | Weekly check-in asks about routine changes |
| GABA inhibits stress/craving circuits | General | GABA spikes on urge surfing |
