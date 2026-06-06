# Executive Summary: NeuroSync Habit App
*Audit Phase 5 — Scores, Critical Issues, Opportunities, Recommendation*
*Date: 2026-06-06*
*Based on: Phases 1–4 (product understanding, ruthless critique, abuse testing, research backing)*

---

## TL;DR

NeuroSync has found a real problem and a genuinely differentiated solution. It has also buried that solution under 44 extraneous features, shipped it with two critical security vulnerabilities, and wired none of its core personalisation engine. The product is a compelling pitch wrapped around a pre-alpha implementation.

**Overall score: 4.6 / 10**
**Survival probability as-is: 10–15%**
**Survival probability after MLP: 55–65%**

---

## Audit Scores

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| **Market Viability** | 5/10 | Real problem, defensible niche, $810K–$8.1M Year 1 ceiling. But no validation data, crowded category, $0 revenue today, no distribution. |
| **Product Clarity** | 5/10 | Core thesis (comeback > streak) is clear and differentiating. Buried by 45 features, heavy jargon, and 8–12 minute onboarding before first value. |
| **UX Quality** | 5/10 | Happy path works. Skip button corrupts personalisation. HUD jargon alienates analytical users. Stacked comebacks recreate the shame the product is designed to prevent. |
| **Retention Likelihood** | 4/10 | Comeback Protocol concept is strong but not wired. Recovery Rate is 0% for consistent users — the app's headline metric penalises success. Freemium gate fires at the worst emotional moment. |
| **Technical Health** | 4/10 | Clean TypeScript architecture. Two critical security vulnerabilities ($0 revenue protection on web, every cancellation keeps Pro forever). No CI/CD. No auth. Dual codebase diverging. |

---

## Top 5 Critical Issues

### 1. Comeback Protocol is not personalised — the product's core claim is false
`getBrainAwareReframe()` and `getBrainAwareMicroActions()` are implemented in `brainHelpers.ts`. They are never called. The Comeback Protocol delivers identical generic CBT reframes to every user regardless of their failure style, energy window, or blocker profile — despite the app collecting 8 questions specifically to personalise this experience. The product's single strongest differentiator does not function.

**File to fix:** `ComebackProtocol.tsx` — wire `getBrainAwareReframe(brainProfile)` and `getBrainAwareMicroActions(brainProfile)` in place of hardcoded fallback text.
**Effort:** S (< 2 hours). **Impact: Existential.**

---

### 2. No payment flow — the product cannot generate revenue
- **Web app:** `upgradeToPro()` sets `isPro = true` in localStorage without taking payment. Any user can get Pro for free in 3 clicks.
- **Flutter app:** Stripe Checkout URLs are `TODO` placeholder strings.
- **Webhook:** Cancellation handler queries `stripeCustomerId` that was never written — every Pro subscription cancelled retains Pro access permanently.

The product is currently incapable of converting a single user to paid. This is a configuration and wiring task, not a research task.
**Effort:** S–M for Stripe URL fix and stripeCustomerId write. **Impact: Existential.**

---

### 3. Brain Assessment Skip button corrupts the personalisation engine
Tapping "Skip" on any Brain Assessment question calls `advance('analyst')` regardless of the question. For Q2–Q8, `'analyst'` is not a valid value for the target field type. The brain profile is silently corrupted. Functions that read `brainProfile.peakEnergyWindow` (e.g., the not-yet-wired `getBrainAwareMicroActions()`) receive an invalid key and return `undefined` — which propagates to runtime crashes when the Comeback Protocol personalisation is wired.

**File to fix:** `BrainAssessment.tsx` ~line 281 — replace `advance('analyst')` with a per-question `SKIP_DEFAULTS` map.
**Effort:** S. **Impact: High.**

---

### 4. The Recovery Rate paradox — the headline metric punishes consistency
Recovery Rate is the app's defining metric ("the number we track"). It equals `comebacks with micro-actions completed / total comebacks`. For users who never miss a habit, Recovery Rate is permanently 0%. The only way to improve Recovery Rate is to miss habits. The app's primary measurement system is miscalibrated against its most successful users, and invisible to new users who haven't yet missed anything.

**Fix recommendation:** Redefine Recovery Rate to include "habits completed after a comeback" as the numerator and "total habit days including comebacks" as the denominator. Or rename it "Comeback Rate" and define it only once comebacks exist, replacing it with "On Track" for users with no misses.
**Effort:** M. **Impact: High.**

---

### 5. No analytics — every fix is a guess
There is no PostHog, Mixpanel, or equivalent instrumentation. This means:
- Unknown where users drop off in onboarding (Q3? Q5? Blueprint reveal?)
- Unknown whether the freemium gate converts or churns
- Unknown whether the Comeback Protocol creates retention or frustration
- Unknown whether the Brain Assessment archetypes resonate

Without funnel data, the priority order of every other fix in this document is an educated guess. Every day without analytics is a day of wasted data.
**Effort:** S (PostHog free tier, one npm install, 10 events). **Impact: High.**

---

## Top 5 Opportunities

### 1. Archetype sharing as organic acquisition
"What's your habit recovery type?" is a shareable personality test format (cf. 16Personalities, StrengthsFinder). The Brain Assessment result — "You're a Resilient Analyst" — is inherently shareable with the analytical/productivity audience on Twitter and LinkedIn. A shareable archetype card (not the Brain Score PNG, which reads as pseudoscience) could drive organic acquisition with zero ad spend. This is the strongest viral mechanic available without a social graph.

---

### 2. The Comeback Protocol personalisation gap is a marketing story
Once `getBrainAwareReframe()` and `getBrainAwareMicroActions()` are wired, NeuroSync can truthfully claim: "the only habit app that delivers a personalised comeback strategy based on your specific failure style." No competitor currently offers this. Finch provides emotional safety (a pet that forgives you). Streaks provides nothing. NeuroSync provides a tailored cognitive protocol. This claim is defensible, differentiating, and can drive App Store positioning, press coverage, and creator partnerships.

---

### 3. B2B / HR channel — "Habit recovery for high-performing teams"
The Brain Assessment is better positioned as a team tool ("understand your team's execution patterns and build resilience systems") than a consumer app ("answer 8 questions before tracking your first habit"). Corporate wellness programmes have budgets of $40–$100/employee/year, care about burnout prevention, and respond to science-backed frameworks. A B2B licence at $5/seat/month with 100-employee teams = $500/month per account. 20 accounts = $10K MRR with zero App Store dependency. This is a Phase 3 play but the product design should not preclude it.

---

### 4. Weekly recalibration as the differentiation story
The recalibration engine (SCALE_DOWN / REPLACE / UPDATE_MICRO / UPDATE_CUE suggestions based on 2-week performance patterns) is genuinely sophisticated. No competitor does this. Notion templates cannot adapt. Streaks doesn't notice when a habit is too hard. The weekly check-in + recalibration loop is the product's second strongest differentiator after the Comeback Protocol, and it is undermarketed. The onboarding should explain this explicitly: "We'll help you adjust your habits every week until they stick — not just track them until you quit."

---

### 5. Research partnership — generate publishable data
"Recovery Rate vs. streak length as a predictor of 30-day habit retention" has no published research. NeuroSync could be the first product to generate this data at scale. A partnership with a behavioural science lab (UCL, MIT, Stanford d.school) would provide:
- Academic credibility for the science-forward positioning
- Peer-reviewed validation of the Recovery Rate hypothesis
- Press coverage from the research publication
- No cost (labs often want data access, not money)

This is a 6-month play, but worth initiating once the alpha data pipeline exists.

---

## MVP Recommendation

**Ship Flutter-first. Web app is a landing page until Flutter generates revenue.**

### What Version 1.0 must include:
1. 4-question Brain Assessment (failureStyle, peakEnergyWindow, primaryBlocker, recoverySpeed)
2. Profile reveal: archetype name + 2 key insight cards
3. Blueprint: 3 auto-assigned habits, no more
4. Dashboard: habit cards (completion + 7-day grid + myelination stage label only), Recovery Rate (redesigned definition), Comeback Streak
5. **Comeback Protocol fully personalised** — wire `getBrainAwareReframe()` and `getBrainAwareMicroActions()`. This is the product.
6. Weekly check-in + SCALE_DOWN recalibration only (REPLACE deferred to V1.5)
7. Push notifications (Flutter — already implemented)
8. Working Stripe payment flow (fix TODO URLs, live keys, write stripeCustomerId in webhook)
9. Freemium gate redesigned: gate multi-device sync + failure signatures, not comeback count
10. **Remove fabricated social proof stats** from `upgrade_page.dart` before App Store submission

### What Version 1.0 must exclude (delay to V1.5):
- Neurochemistry HUD (or collapse to a hidden "Nerd View" toggle)
- Brain Score (remove entirely)
- Dopamine Points Counter (remove)
- Neurochemical Decay (remove)
- Neuro-Swaps (entirely different product mode — Phase 2)
- Activity Log detail view
- Share Card (rebuild in V1.5 with archetype sharing, not Brain Score PNG)
- comeback-protocol.html (archive or delete)

### Engineering estimate from current state:
- Wiring Comeback Protocol personalisation: 2–4 hours
- Fixing Brain Assessment skip defaults: 1 hour
- Fixing Stripe TODO URLs + stripeCustomerId webhook write: 4–8 hours
- Removing/hiding disqualified features: 4–8 hours
- Installing PostHog analytics: 2–4 hours
- **Total MLP delta: 1–3 days focused engineering**

---

## Investor / Launch Recommendation

**Do not seek investment or press coverage in the current state.**

A journalist or investor who tries the web app today will:
1. Enter their name and role (fine)
2. Start the Brain Assessment and potentially skip a question — silently corrupting their profile
3. Receive a Comeback Protocol that is completely generic despite 8 questions of personalisation setup
4. Discover they can click "Upgrade to Pro" for free

This experience will generate negative press ("neuroscience habit app doesn't actually use the brain profile") rather than positive coverage.

**Wait for:**
- Comeback Protocol fully personalised and demonstrable
- Stripe payment flow working end-to-end
- 50+ alpha users with 30-day retention data
- Brain Assessment skip bug fixed

**Then:** "The only habit app that builds your comeback strategy around your specific failure style" is a defensible, differentiating pitch with a working demo. Seek seed ($250K–$750K) to fund distribution (creator partnerships, paid acquisition test), backend infrastructure (Supabase auth + sync), and a design pass on the onboarding flow.

---

## Audit Score Summary

| Phase | Document | Key Finding |
|-------|----------|-------------|
| Phase 1 | `product-understanding.md` | 45 features across 2 codebases; Comeback Protocol is the core differentiator |
| Phase 2 | `ruthless-product-review.md` | Comeback Protocol unwired; payment broken; onboarding 8–12 min; survival 15% as-is |
| Phase 3 | `user-abuse-testing.md` | 2 critical security bugs (Pro bypass, cancellation silent fail), 1 critical data bug (Skip corruption) |
| Phase 4 | `research-backing.md` | 5 strong citations; fabricated social proof stats (FTC risk); neurochemical HUD weakly grounded |
| **Phase 5** | **`executive-summary.md`** | **Overall 4.6/10; MLP is 1–3 days of focused work; do not launch or fundraise in current state** |

---

*End of Phase 5 — Executive Summary*
*Next: Phase 6 — Code Improvements (implementing highest-impact S-effort fixes from Phases 2–3)*
