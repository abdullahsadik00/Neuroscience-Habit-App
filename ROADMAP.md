# NeuroSync — Product Roadmap to Launch

> **Mission:** Give execution-focused people a personal recovery system for habit failure — not another streak tracker.
>
> **Core mechanic:** The Comeback Protocol. You activate it when you fail, not when you succeed.
> **Primary metric:** Recovery Rate (% of comebacks where micro-actions were completed), not DAU.

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

**Stack:** React 19 + TypeScript + Vite 8 + Tailwind CSS v4 + Zustand v5 + lucide-react

---

## Phase 1 — Alpha Polish (Weeks 1–2)

**Goal:** Make the core loop feel real enough to test with 5–10 people.

### P1 — Must ship

- [ ] **User onboarding flow** — 3-screen setup: name/role, add first habit, explain the Comeback Protocol. No blank-state first launch.
- [ ] **Comeback Protocol gate** — enforce 3 free/month limit. Show freemium modal on 4th trigger.
- [ ] **Persistence reliability** — add migration guard so localStorage schema changes don't wipe data silently.
- [ ] **Mobile-first layout pass** — verify everything works on 375px. Tab bar should be thumb-reachable.
- [ ] **Empty-state habit prompts** — pre-fill 3 suggested habits by archetype (Builder, Athlete, Student) during onboarding.

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
- [ ] Add `.nvmrc` file pinning Node `20.19.0`
- [ ] Set up CI (GitHub Actions) — type check + build on every PR
- [ ] Add Sentry for error tracking (free tier)
- [ ] Add PostHog for product analytics (free tier, self-hostable)
- [ ] Write a migration helper for Zustand `persist` schema versioning
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
