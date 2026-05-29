# User Abuse Testing: NeuroSync Habit App
*Audit Phase 3 — User Abuse Testing*
*Date: 2026-05-29*
*Based on: docs/product-understanding.md (Phase 1), docs/ruthless-product-review.md (Phase 2)*

---

## Overview

This document simulates how users will break, stress, and abuse the NeuroSync app — intentionally and unintentionally. Each scenario includes the exact mechanism of abuse, what happens in the code (with file references), the severity, and a fix recommendation.

Abuse categories covered:
- A. Impatient / Fast-tap users
- B. Confused / non-technical users
- C. Malicious users (premium bypass, data manipulation)
- D. Edge-case users (time zones, multi-device, data volume)
- E. Comeback Protocol abuse
- F. State corruption scenarios
- G. Onboarding skip patterns
- H. Mobile + slow-internet users
- I. Enterprise / shared-device users

---

## A. Impatient / Fast-tap Users

### A1. Rapid-tap through Brain Assessment

**Scenario:** User opens app, Brain Assessment loads. They tap each answer card as fast as possible — 8 taps in under 5 seconds.

**What happens:**
- Each tap triggers `advance(answer)` in `BrainAssessment.tsx`, which calls `setAnswers(prev => ({...prev, [QUESTIONS[currentQ].key]: answer}))` and increments `currentQ`
- Auto-advance animations (CSS transitions) are tied to state changes — if taps come faster than the transition duration, multiple state updates queue
- **Result:** Assessment completes but answers may be partially overwritten by rapid state updates depending on React 19's batching behaviour. The `answers` object is built by accumulating per-question keys — if two transitions fire simultaneously, a race on `setCurrentQ` could skip a question, leaving one dimension unset and potentially undefined in `brainProfile`

**Impact on downstream systems:**
- `brainHelpers.ts` `getArchetypeName(profile)` is not null-safe — it reads `profile.failureStyle` and `profile.peakEnergyWindow` directly. If either is undefined due to a skipped question, the archetype name resolves to undefined and the profile reveal shows a blank title.
- `buildBlueprint()` in `blueprintEngine.ts` scores habits against profile dimensions — an undefined `primaryBlocker` falls through the scoring logic silently (the scoring is additive; a missing dimension just scores 0 for that factor)
- The brain-aware reframe and micro-action functions (`getBrainAwareReframe()`, `getBrainAwareMicroActions()`) — once wired — would receive an undefined key and either throw or return a fallback, depending on how object lookups handle undefined keys

**Severity:** Medium. React 19's automatic batching reduces the race risk, but the skip-a-question path through the "Skip" button (which always sets `failureStyle='analyst'`, see below) is a confirmed corruption path.

**Fix:** Add an `isTransitioning` boolean flag that blocks `advance()` calls during the CSS transition. Clear the flag in `onAnimationEnd`. Cost: ~15 lines.

---

### A2. Double-tap habit completion

**Scenario:** User taps "Mark Complete" on a habit card twice in quick succession.

**What happens in `completeNeuroStack(id)` (`useNeuroStore.ts:295`):**
```
const alreadyCompletedToday = stack.completions.includes(todayStr);
const completions = alreadyCompletedToday
  ? stack.completions
  : [...stack.completions, todayStr];
```
The idempotency guard checks `completions.includes(todayStr)` before adding. This is correct.

**But:** The neurochemistry update and dopamine points update are inside the same `set()` call. If two `completeNeuroStack` calls are dispatched in the same React render batch (before state has flushed), both calls read the pre-update state where `alreadyCompletedToday = false` — both pass the guard, and the completion date is added twice (duplicate `todayStr` entries in the `completions` array).

**Impact:** Duplicate date string in `completions[]`. `calculateStreak()` uses `includes()` to check dates — duplicates don't affect streak calculation. `calculateMyelination()` uses `completions.length` — a duplicate inflates the formula by 1 completion. `getWeekGrid()` uses `stack.completions.includes(dateStr)` — still correct. Minor myelination inflation only.

Dopamine points would be awarded twice if the race is triggered. User ends up with 2x the expected DA points from a double-tap.

**Severity:** Low. The duplicate entry is cosmetic in most places and the points inflation is minor. But the root cause (neurochemistry update outside the idempotency guard) is a pattern that could cause more serious double-award bugs as features are added.

**Fix:** Move the early-return check before the neurochemistry mutation, or deduplicate `completions` array in `calculateMyelination` caller.

---

### A3. Rapid weekly check-in submission

**Scenario:** User submits the 5-step check-in form twice by double-tapping the final "Submit check-in" button.

**What happens:** `submitCheckin()` (`useNeuroStore.ts:560`) is not idempotent:
```
set((state) => ({
  checkinHistory: [full, ...state.checkinHistory],
  lastCheckinDate: full.date,
}));
```
Two rapid taps produce two `CheckinRecord` entries with different `id`s (both use `checkin-${Date.now()}` — if dispatched in the same millisecond, they have the same ID, which is a secondary bug).

`runRecalibration()` (`recalibrationEngine.ts:66`) takes `checkinHistory` as input and reads `checkinHistory[0]` and `checkinHistory.slice(0, 2)`. With two identical records at [0] and [1], the UPDATE_MICRO trigger checks `checkinHistory.slice(0, 2).every(c => c.weeklyBlocker === currentBlocker)` — both identical records satisfy this, so recalibration fires with double-submitted data, potentially producing incorrect SCALE_DOWN/REPLACE suggestions if the second checkin used a different energy level due to auto-advance racing.

**Severity:** Low-Medium. Recalibration is fired on bad data. Suggestions may be irrelevant. Recovery: user can skip all suggestions.

**Fix:** Disable the submit button after first tap (set a `submitting` boolean state). Re-enable only on error.

---

## B. Confused / Non-technical Users

### B1. User tries to "undo" a habit completion

**Scenario:** User taps "Mark Complete" by mistake and wants to undo it.

**What happens:** There is no undo, no un-complete action, and no clear UI affordance that the completion is permanent. The only recovery is:
- Archive the habit (`isActive = false`) and re-add it from scratch
- Or edit the completion date array via DevTools (only possible for tech-savvy users)

The `completeNeuroStack()` action has no reverse. `deleteNeuroStack()` exists in the store but has no UI (kept as an admin backdoor). `archiveNeuroStack` is available via the kebab menu but loses all history.

**Impact:** User accidentally marks a habit complete they didn't do. Myelination level is slightly inflated (by 1 completion). More critically, if the habit had not been completed yesterday, the Comeback Protocol would have fired — but since `completeNeuroStack()` adds today's date to `completions[]`, `getMissedStacks()` now returns false for this habit (`notCompletedToday = false`). The comeback protocol is silently suppressed for an accidentally-completed habit.

**Severity:** Low-Medium. Data accuracy is marginally corrupted. The more important issue is that there is no feedback to the user that this action is permanent.

**Fix:** Add a 5-second undo toast after habit completion ("Marked complete — Undo" dismisses the completion). This is the standard mobile pattern and is a retention tool (users feel safe tapping).

---

### B2. User enters a name with only whitespace

**Scenario:** User types spaces in the name field during onboarding and taps Continue.

**What happens:** `Onboarding.tsx` disables Continue with: `disabled until name.trim() > 0`. If this check is present, the button stays disabled. If the check is `name.length > 0` (whitespace check missing), spaces pass.

**Impact if guard is missing:** `userProfile.name = "   "`. Dashboard header renders "  's System" or similar with leading spaces. Minor cosmetic issue.

**Status:** Phase 1 noted `name.trim() > 0` — the guard appears to be in place. Low risk.

---

### B3. User adds a habit with a 200-character title

**Scenario:** User pastes a long string into the habit title field in the Add Habit modal.

**What happens:** No `maxLength` attribute is specified on the title input in the Phase 1 audit. Long title strings will:
- Overflow the habit card title area (CSS `truncate` or `overflow: hidden` may clip it — but if not, the card layout breaks)
- The implementation intention preview renders "When [anchorCue], I will [action]" — a very long action string wraps and may overflow its container

**Severity:** Low. Cosmetic layout issue. No data corruption.

**Fix:** Add `maxLength={100}` to title, anchorCue, and action inputs.

---

### B4. User taps "Retake Assessment" expecting to keep current habits

**Scenario:** User taps "Retake Brain Assessment" in the Brain Profile Card. Expects to re-answer questions and get a new profile while keeping their current habits.

**What happens:** `BrainProfileCard.tsx` `handleRetake()` calls `setBrainProfile(null as unknown as NeuroBrainProfile)`. This sets `brainProfile = null` in the store. App routing in `App.tsx` checks `brainProfile !== null` — when null, it re-renders `<BrainAssessment />`. After the retake completes, `setBrainProfile(newProfile)` is called, and `App.tsx` then checks `blueprintAccepted` — it is `true`, so the dashboard renders immediately (no new blueprint screen). Habits are preserved.

**Confirmed safe for habits.** But the TypeScript cast `null as unknown as NeuroBrainProfile` bypasses type safety. If any code reads `brainProfile` between the `null` set and the retake completion (e.g., the neurochemical decay interval fires and calls a function that reads `brainProfile?.failureStyle`), a null-access could occur.

**More serious issue:** The Comeback Protocol (once `getBrainAwareReframe()` is wired) will read `brainProfile.failureStyle` during the retake window. If the dashboard is somehow rendered between the null set and the retake completion (e.g., browser back button, state race), `brainProfile.failureStyle` throws a null pointer.

**Severity:** Medium (TypeScript bypass + null-access window). Low impact currently since `getBrainAwareReframe()` is not wired.

**Fix:** Change `setBrainProfile` signature to accept `NeuroBrainProfile | null`. Add a null-safe guard in any function that reads `brainProfile`. Use optional chaining everywhere: `brainProfile?.failureStyle ?? 'analyst'`.

---

## C. Malicious Users (Premium Bypass)

### C1. Web `upgradeToPro()` bypass — no payment required

**File:** `useNeuroStore.ts:642`
```typescript
upgradeToPro: () => {
  set({ isPro: true });
},
```

**Trigger:** `ComebackGateModal.tsx` — clicking "Upgrade to Pro" on the web app calls `upgradeToPro()` directly. No Stripe session is initiated. No server call is made. `isPro` is set to `true` in localStorage.

**Attack path 1 (UI):** Free user hits the 4th comeback gate → clicks "Upgrade to Pro" in the modal → modal dismisses (code: `setShowComebackGate(false); setShowComeback(true);`) → user now has full Pro access → no payment taken.

**Attack path 2 (DevTools):** Any user opens browser DevTools → Application → Local Storage → `neuroflow-state-storage` → edits the JSON blob: `"isPro":false` → `"isPro":true` → refreshes page → full Pro access.

**Attack path 3 (Console):** Any user opens browser console → `JSON.parse(localStorage.getItem('neuroflow-state-storage'))` → mutate → `localStorage.setItem(...)`. Takes ~30 seconds for a developer.

**Attack path 4 (Bookmarklet):** A malicious user could publish: `javascript:void(function(){let s=JSON.parse(localStorage.getItem('neuroflow-state-storage'));s.state.isPro=true;localStorage.setItem('neuroflow-state-storage',JSON.stringify(s));location.reload();}())` as a "NeuroSync Pro unlock" bookmarklet. This requires zero technical knowledge once the bookmarklet link is shared.

**Impact:** The paid tier has zero revenue protection on the web platform. Once this is discovered (likely within days of any public launch with a technical audience), it will be shared widely. Every potential paying web user becomes a free user.

**Severity:** Critical. This is not a theoretical risk — it requires 3 clicks.

**Fixes (in priority order):**
1. **Immediate:** Remove `upgradeToPro()` from the web Zustand action entirely. Replace the ComebackGateModal upgrade button with a redirect to the Flutter App Store listing or a Stripe Checkout URL. `isPro` should never be set client-side from a UI button.
2. **Before payment launch:** `isPro` should be verified server-side on every session start. Store `isPro` in Supabase `neuro_state`, loaded via `loadFromCloud()` on sign-in. Client-side `isPro` is a cache for the last known server state, not the source of truth.
3. **Belt-and-suspenders:** Add Supabase Row Level Security so only the webhook can update `isPro = true` in the database. The client cannot write `isPro` directly.

---

### C2. Stripe subscription cancelled but `stripeCustomerId` never written

**File:** `supabase/functions/stripe-webhook/index.ts`
**Issue confirmed in Phase 1 §7 — expanded with exploit detail here.**

**Attack path:** User signs up for Pro on Flutter ($9/month). Stripe fires `checkout.session.completed` webhook → `isPro = true` written to `neuro_state`. User uses Pro for 1 month → cancels subscription in Stripe dashboard. Stripe fires `customer.subscription.deleted` webhook → handler queries `state_json->>'stripeCustomerId'` to find the user → query returns 0 rows because `stripeCustomerId` was never written to `state_json` → cancellation silently fails → user retains `isPro = true` indefinitely.

**This means every subscription cancellation results in permanent free Pro access.** There is no revenue leakage prevention.

**Secondary impact:** The `customer.subscription.deleted` handler will silently fail for 100% of cancellations at launch. This is not a corner case — it is the guaranteed outcome of every cancellation.

**Severity:** Critical (revenue).

**Fix:**
In the `checkout.session.completed` webhook handler, after setting `isPro = true`, also write the Stripe `customer.id`:
```typescript
// After _setProStatus(userId, true):
const customerId = session.customer as string;
await supabaseAdmin
  .from('neuro_state')
  .update({ state_json: supabaseAdmin.rpc('jsonb_set', {
    state_json, path: '{stripeCustomerId}', value: JSON.stringify(customerId)
  })})
  .eq('user_id', userId);
```
(Exact implementation depends on Supabase jsonb_set support — may need a dedicated `stripe_customer_id` column instead of embedding in the JSON blob.)

---

### C3. Comeback count manipulation via system clock

**File:** `statsHelpers.ts:103` — `getComebacksThisMonth()`
```typescript
export function getComebacksThisMonth(comebacks: ComebackRecord[]): number {
  const now = new Date();
  const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  return comebacks.filter((c) => c.date.startsWith(monthStr)).length;
}
```

**Attack path:** Free user has used their 3 comebacks in January. The freemium gate fires. User changes their device system clock to February 1. `getComebacksThisMonth()` now counts January comebacks against the February month string — returns 0. The gate check passes. User gets unlimited comebacks in "February."

**This attack requires only changing the system clock — no DevTools, no coding.**

On mobile (Flutter), the `neuro_provider.dart` equivalent uses `DateTime.now()` — same vulnerability.

**Severity:** Medium. The attack requires device clock manipulation which is unusual for non-technical users. But for motivated users who want free comebacks, this is discoverable within minutes.

**Fix:** Count comebacks by calendar month using the stored `date` field vs. server time, not device time. Short-term: add server timestamp validation on comeback acknowledgment. Medium-term: move the freemium gate from comeback count to a server-enforced subscription check.

---

### C4. Streak inflation via manual completion date injection

**File:** `useNeuroStore.ts` — `completeNeuroStack()` only adds today's date. But `addNeuroStack()` accepts a partial stack object without a `completions` field — `completions` is initialized to `[]` in the action.

**Attack path (console):** User opens DevTools, reads `neuroflow-state-storage`, finds their habit's `id`, and manually edits the `completions` array to include backdated date strings:
```json
"completions": ["2026-01-01","2026-01-02","2026-01-03",...,"2026-05-29"]
```

**Impact:** `calculateStreak()` computes streaks from the `completions` array. An injected 150-day history gives a 150-day streak and near-maximum myelination. Milestone celebrations would not fire (they check `oldLevel < m && newLevel >= m` — after injection the level jumps from 0 to 92 in one state set, which might fire all milestones simultaneously or none, depending on when the celebration check runs).

**Severity:** Low. This is single-user data corruption with no impact on others. The product has no leaderboards or social proof features where inflated data has external consequences. The user only hurts their own data integrity.

**No fix required** unless social features are added. If a leaderboard or share card uses streak/myelination data, server-side validation becomes necessary.

---

### C5. `resetAllData()` callable from browser console

**File:** `useNeuroStore.ts:675`
```typescript
resetAllData: () => {
  set({
    stacks: [],
    swaps: [],
    logs: [],
    comebacks: [],
    neurochemistry: { dopamine: 50, acetylcholine: 50, epinephrine: 50, gaba: 50 },
    dopaminePoints: 0,
  });
}
```

**Note:** `resetAllData()` does NOT reset `onboardingComplete`, `brainProfile`, `blueprintAccepted`, `userProfile`, `isPro`, or any of the onboarding state. Calling it from the console erases all habits, comebacks, and logs, but the user stays on the Dashboard (because `onboardingComplete` and `blueprintAccepted` remain `true`).

**Attack path (shared device):** User A completes onboarding on a shared device. User B picks up the device, opens DevTools, calls `useNeuroStore.getState().resetAllData()` — erases User A's habit data but leaves the profile intact. User A returns to an empty dashboard with their name still showing and no habits.

**More destructive attack:** `localStorage.clear()` or `localStorage.removeItem('neuroflow-state-storage')` wipes everything including onboarding state. User is sent back to the blank onboarding flow.

**Severity:** Low on its own (single-device, requires console access). Medium in shared-device environments (workplace wellness programs, family iPads, kiosk demos).

**Fix:** Add a confirmation dialog before `resetAllData()` in any UI that calls it. Do not expose `resetAllData()` directly to the store's public interface — wrap it in a UI-gated action with a confirmation step.

---

## D. Edge-Case Users

### D1. Timezone boundary users

**Scenario:** User in UTC+5:30 (India Standard Time) completes a habit at 11:45 PM local time on May 29. At 12:01 AM local time on May 30 (still May 29 in UTC), they open the app and the Comeback Protocol fires.

**Root cause:** `getLocalDateString()` in `neuroHelpers.ts` uses:
```typescript
export function getLocalDateString(date: Date): string {
  return date.toLocaleDateString('en-CA'); // YYYY-MM-DD format using local time
}
```
`en-CA` locale with `toLocaleDateString` returns the date in the user's local timezone. This is correct for single-device use. But `ComebackRecord.date` stores the local date string at acknowledgment time. `getComebacksThisMonth()` uses `date.startsWith(monthStr)` where `monthStr` is built from `new Date()` — also local time. These are consistent.

**Issue:** The `getMissedStacks()` function computes `yesterday = getLocalDateString(new Date(Date.now() - 86400000))`. Subtracting 86400000ms (exactly 24 hours) is correct for most cases but breaks during Daylight Saving Time transitions — when clocks spring forward 1 hour, the "day before yesterday" calculation at midnight may return the wrong date string.

**Severity:** Low. DST boundary bug produces a false-positive missed habit detection for one day per year per affected timezone. User sees an unexpected Comeback Protocol modal.

**Fix:** Use proper calendar arithmetic: `const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1); return getLocalDateString(yesterday);` instead of subtracting milliseconds.

---

### D2. Multi-device data loss (web)

**Scenario:** User completes 30 days of habits on their work laptop. Browser updates and clears application storage. User opens app on their home laptop — sees blank onboarding.

**What happens:** All state is in a single localStorage key `neuroflow-state-storage`. Browser clears = total data loss. No backup, no export, no recovery path.

**This is a known limitation** (Phase 1 §10, Risk #1). But the abuse testing scenario surfaces the specific user experience:
1. User opens blank onboarding
2. Completes onboarding again with the same name/role
3. A new Brain Assessment is taken — may yield a different archetype (if they answer differently this time)
4. Blueprint assigns new habits — old progress is permanently gone
5. User sees their old "habit streaks" as 0. They feel cheated. They leave a 1-star review.

**Severity:** High from a retention perspective. A single viral post about data loss can permanently damage a habit app's reputation.

**Fix (immediate, no backend required):** Add a JSON export button on the dashboard. On app boot, if localStorage is empty, check for a `?restore` URL parameter and prompt the user to import. This is a 2-hour implementation that survives the worst data-loss scenarios for technically capable users.

---

### D3. User with large data volume (2+ years of history)

**Scenario:** User has been using the app for 730 days. Their state object contains:
- `completions` arrays: 3 habits × 730 completions = 2,190 date strings (each ~12 bytes = ~26KB)
- `logs`: activity log capped at 20 entries on web (safe) — Flutter has no cap
- `comebacks`: 2 comebacks/month × 24 months = 48 records (trivial)
- `checkinHistory`: 52 check-ins/year × 2 = 104 records (trivial)

**localStorage size:** The entire state JSON is estimated at ~100–150KB for a power user with 10 habits over 2 years. localStorage limits are 5MB on most browsers. No overflow risk for the web app.

**Flutter SharedPreferences:** No documented size limit from the SDK. Large JSON blobs can cause slow serialisation/deserialisation on older devices. `NeuroNotifier`'s `_save()` is called on every state mutation — for a high-frequency user, this could cause perceptible lag on older Android devices.

**`calculateStreak()` performance:** Called on every `completeNeuroStack()`. If a habit has 730 completions, sorting 730 strings and iterating backwards is O(n log n). Imperceptible for 730 items. No performance issue.

**`getRecoveryInsights()` in statsHelpers:** Iterates `stacks`, `comebacks`, and `swaps` — all bounded by user data volume. No computed lists are unbounded. No performance concern.

**Severity:** Low. No crash or data corruption risk for realistic usage volumes.

---

### D4. User with no habits (empty dashboard)

**Scenario:** User completes onboarding, skips all habit selection steps, lands on an empty dashboard.

**What happens:**
- `getMissedStacks([], [])` returns `[]` — no comeback fires (correct)
- `calcBrainScore([], [], neurochemistry)` at `statsHelpers.ts:42`: `if (activeStacks.length === 0) return 0;` — returns 0 (correct, but showing "Brain Score: 0" to a brand-new user is demoralising)
- `getRecoveryInsights()` last branch: `if (active === 0) { insights.push('Add your first habit to start building your recovery playbook.') }` — surfaces an onboarding nudge (correct)
- `getBestStreak([])` returns 0 (correct)
- `getDaysInSystem([])` returns 0 (safe — `if (stacks.length === 0) return 0`)

**Severity:** Low — the empty state is handled without crashes. The Brain Score of 0 is demoralising but not a bug.

---

## E. Comeback Protocol Abuse

### E1. Spam-acknowledging comebacks

**Scenario:** User wants to inflate their Recovery Rate. They repeatedly trigger and acknowledge the Comeback Protocol.

**Can the Comeback Protocol be re-triggered after acknowledgment?**

`getMissedStacks()` (`comebackHelpers.ts:4`) filters:
```typescript
if (acknowledgedTodayIds.includes(stack.id)) return false;
```
`getTodayComebackIds()` returns all `stackId`s from `comebacks` where `date === today`. Once a comeback is acknowledged for a habit today, the habit is excluded from missed stacks for the rest of the day.

**Result:** Comeback spam within a single day is blocked. Each habit can only receive one comeback acknowledgment per calendar day. **This idempotency is correct.**

**Cross-day abuse:** User misses Habit A on Day 1. They acknowledge the comeback. On Day 2, they don't complete Habit A. The `getMissedStacks()` check for Day 2: `missedYesterday = !stack.completions.includes(yesterday)` — they didn't complete it yesterday. `notCompletedToday = !stack.completions.includes(today)` — true. `acknowledgedTodayIds.includes(stack.id)` — Day 1's comeback record has `date = day1`, today is day2, so Day 1's comeback is NOT in the acknowledged list for day 2. **The protocol fires again on Day 2.** This is correct product behaviour but means a user can accumulate N comebacks from a single habit by never completing it over N days.

**Recovery Rate inflation:** `calcRecoveryRate()` = `comebacks.filter(c => c.microActionsCompleted).length / comebacks.length`. If a user acknowledges every comeback (even by clicking "Skip actions — just acknowledge"), `microActionsCompleted = false` for each, and Recovery Rate stays 0%. To inflate Recovery Rate, the user must check at least one checkbox and tap "I'm continuing" — which is the intended use of the protocol. This is not a meaningful "abuse" — the user is using the product correctly.

**Severity:** Low. No meaningful abuse vector here.

---

### E2. Comeback gate bypass via clock manipulation (repeat of C3 with fuller detail)

**Scenario:** Free user has used 3 comebacks this month. Changes device clock to Month+1. See C3 for full detail.

**Additional discovery:** On web, the freemium gate check in `Dashboard.tsx`:
```tsx
if (isPro || getComebacksThisMonth(comebacks) < 3) {
  setShowComeback(true);
} else {
  setShowComebackGate(true);
}
```
The constant `3` is hardcoded inline — it is not referenced from a config constant or environment variable. To change the free tier from 3 to 2 comebacks (as the PRD suggests for tightening), the developer must grep for this `< 3` expression. Risk of missing other occurrences is moderate.

**Fix:** Define `const FREE_COMEBACK_LIMIT = 3;` in a shared constants file and import it wherever the limit is checked.

---

### E3. "Skip actions — just acknowledge" always

**Scenario:** User triggers the Comeback Protocol and always taps "Skip actions — just acknowledge" without completing any micro-actions.

**What happens:** `onComplete(stack.id, stack.title, false)` → `acknowledgeComeback(stackId, stackTitle, false)` → `ComebackRecord { microActionsCompleted: false }`. Dopamine boost is 10 (vs. 20 for completing actions). Recovery Rate calculation: `completedWithActions / total` — this record does not count as "completed."

**Product effect:** User's Recovery Rate stays at 0%. The app's primary metric shows no progress. User feels the app isn't working for them. **The "Skip" button is a churn trigger** because it lets users go through the motions of the protocol without generating any positive metric signal.

**Recommendation:** Remove the "Skip actions — just acknowledge" button in the MLP. Require completing at least one micro-action (which only requires tapping one checkbox). Alternatively, rename it "Acknowledge (no actions today)" and add a soft nudge: "Your Recovery Rate grows when you complete at least one action."

---

## F. State Corruption Scenarios

### F1. Zustand state migration failure

**File:** `useNeuroStore.ts:688`
```typescript
migrate: (persisted: unknown, fromVersion: number) => {
  const state = persisted as Record<string, unknown>;
  if (fromVersion < 2) {
    const stacks = state.stacks as unknown[] | undefined;
    state.onboardingComplete = Array.isArray(stacks) && stacks.length > 0;
  }
  return state;
},
```

**Scenario:** User has an old v0 or v1 state with `stacks` data. Migration runs, sets `onboardingComplete = true` based on whether stacks exist.

**Issue 1:** The migration sets `onboardingComplete` but does NOT set `blueprintAccepted`. If an old user has habits but no `blueprintAccepted` flag (because that field was added after their initial save), `App.tsx` routing sends them to `<RoutineBlueprint />` on next load. The blueprint page runs `buildBlueprint()` and renders 3–5 suggested habits on top of their existing ones. If they click "Accept," `addNeuroStack()` is called for each blueprint habit — they now have their existing habits PLUS the blueprint's auto-assigned habits. Potential for duplicate habits if any blueprint suggestion matches a habit they already have (title comparison is not enforced).

**Issue 2:** The migration does not validate the shape of `stacks` entries. A corrupted `stack` object without required fields (e.g., missing `completions` array) will cause `stack.completions.includes()` to throw at runtime.

**Severity:** Medium. Migration path from v1 is a one-time event, but any user who upgrades from an old version hits it. Blueprint re-firing for returning users is a confusing experience.

**Fix:** Set `blueprintAccepted: true` in the migration if `stacks.length > 0`. Add a shape validator on `stacks` entries during migration.

---

### F2. `acknowledgeComeback` called with a `stackId` that no longer exists

**Scenario:** User has two missed habits queued in the Comeback Protocol. While the modal is open for Habit 1, they (on another device or in another tab) archive Habit 2. When the modal advances to Habit 2's comeback, `acknowledgeComeback(habit2Id, ...)` fires.

**What happens:** `acknowledgeComeback()` creates a `ComebackRecord` with `stackId: habit2Id` regardless of whether the habit still exists. The comeback record is persisted. `getMissedStacks()` later checks `acknowledgedTodayIds.includes(stack.id)` — but Habit 2 is now archived (`isActive = false`), so it won't appear in missed stacks anyway. The orphaned comeback record just exists in the `comebacks` array forever.

**Impact:** Orphaned comeback records inflate the total comeback count, which affects `getComebacksThisMonth()` (freemium gate) and `calcRecoveryRate()`. If the user archived Habit 2 because they wanted to reset it, they now have a phantom comeback record affecting their Recovery Rate for a habit that no longer exists.

**Severity:** Low. Only affects users with multi-session simultaneous access or users who archive mid-comeback-protocol.

---

### F3. `recalibrationEngine` REPLACE action creates a duplicate habit

**File:** `useNeuroStore.ts:600` — REPLACE case:
```typescript
updatedStacks = updatedStacks.map(s =>
  s.id === suggestion.habitId ? { ...s, isActive: false } : s
);
const newStack: NeuroStack = {
  id: `stack-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
  ...
};
updatedStacks = [newStack, ...updatedStacks];
```

`findReplacement()` (`recalibrationEngine.ts:52`) picks the first candidate from the habit library that:
- Has the same `category` as the failing habit
- Has a different `title`
- Is not in `usedTemplateIds` (the list of template IDs of currently active stacks)

**Issue:** `usedTemplateIds` is built at the start of `runRecalibration()` from active stacks. If two habits in the same category both fail (0% completion for 14 days), both generate REPLACE suggestions. `findReplacement()` for Habit A picks Replacement X. `findReplacement()` for Habit B also picks Replacement X (because `usedTemplateIds` was built before either suggestion was created — the exclusion list doesn't include X from Habit A's suggestion).

**Result:** Two REPLACE suggestions both recommend the same replacement template. User accepts both. Two new habits with the same template content are added, producing duplicate habits.

**Severity:** Medium. Duplicate habits are confusing and affect metrics (two habits with the same title confuse `getMissedStacks()` pattern matching).

**Fix:** In `runRecalibration()`, accumulate suggested template IDs as suggestions are generated and exclude them from subsequent `findReplacement()` calls.

---

### F4. `applyRecalibration` SCALE_DOWN resets myelination to 0

**File:** `useNeuroStore.ts:580`
```typescript
if (suggestion.type === 'SCALE_DOWN' && suggestion.habitId && suggestion.replacementTemplateId) {
  const template = HABIT_LIBRARY.find(h => h.id === suggestion.replacementTemplateId);
  if (template) {
    updatedStacks = updatedStacks.map(s =>
      s.id === suggestion.habitId
        ? {
            ...s,
            title: template.title,
            anchorCue: template.anchorCue,
            action: template.action,
            reward: template.reward,
            completions: [],   // ← reset
            streak: 0,         // ← reset
            myelinationLevel: 0, // ← reset
          }
        : s
    );
  }
}
```

**Issue:** SCALE_DOWN replaces the habit content but wipes the `completions` array, `streak`, and `myelinationLevel`. This is correct for the new habit title, but it resets the myelination progress to 0. A user who has built 35% myelination on "Deep Work Block (60 min)" and scales down to "Micro Work Block (10 min)" starts myelination from 0.

**Product impact:** The scale-down is presented as a continuity action ("build the same neural pathway with less friction"). Resetting myelination contradicts this framing — the user sees their progress bar wipe to 0, which triggers exactly the shame/failure feeling the app is designed to prevent.

**Fix options:**
1. Preserve 50% of the existing myelination when scaling down (the neural pathway is partially maintained)
2. Show an explicit preview in the Recalibration Suggestions UI: "Your myelination progress will reset to 0%" so users can make an informed choice
3. Preserve completions count and only replace the content fields (myelination would recalculate correctly from the same completions history)

**Severity:** Medium. Unexpected myelination reset is a churn trigger.

---

## G. Onboarding Skip Patterns

### G1. Brain Assessment skip button corrupts brain profile

**File:** `BrainAssessment.tsx` ~line 281

**Confirmed bug from Phase 1:**
The Skip button on any Brain Assessment question calls `advance('analyst')` regardless of which question is being skipped.

**Impact per question:**

| Q# | Key | Hardcoded Skip Answer | Correct Type | Impact |
|----|-----|-----------------------|--------------|--------|
| Q1 | `failureStyle` | `'analyst'` | Matches type | Correct by coincidence |
| Q2 | `peakEnergyWindow` | `'analyst'` | Should be `'morning'\|'afternoon'\|'evening'\|'variable'` | **Type mismatch** |
| Q3 | `recoverySpeed` | `'analyst'` | Should be `'fast'\|'medium'\|'slow'\|'variable'` | **Type mismatch** |
| Q4 | `primaryBlocker` | `'analyst'` | Should be `'energy'\|'overwhelm'\|'distraction'\|'life'` | **Type mismatch** |
| Q5 | `selfTalkPattern` | `'analyst'` | Should be `'self-critical'\|'avoidant'\|'rational'\|'hopeless'` | **Type mismatch** |
| Q6 | `motivationSource` | `'analyst'` | Should be `'identity'\|'outcome'\|'process'\|'survival'` | **Type mismatch** |
| Q7 | `accountabilityStyle` | `'analyst'` | Should be `'tracking'\|'external'\|'systems'\|'none'` | **Type mismatch** |
| Q8 | `coreDriver` | `'analyst'` | Should be `'feel-better'\|'perform-better'\|'become-someone'\|'survive'` | **Type mismatch** |

**Runtime consequences:** TypeScript types are compile-time only. At runtime, `brainProfile.peakEnergyWindow = 'analyst'` is a string. `getBrainAwareMicroActions()` likely uses a lookup keyed on `peakEnergyWindow` — `'analyst'` is not a valid key, so the lookup returns `undefined`. Downstream code that calls `undefined[0]` or `.map()` on `undefined` throws at runtime.

**This is an unhandled runtime crash path in the Brain Assessment skip flow.** Any user who skips any question other than Q1 will receive a corrupt brain profile that breaks any function that reads the skipped field.

**Severity:** High. The Skip button is a visible UI element. Tech-savvy or impatient users will use it on any question, not just Q1.

**Fix:** Replace the single hardcoded `advance('analyst')` call with a per-question default mapping:
```typescript
const SKIP_DEFAULTS: Record<string, string> = {
  failureStyle: 'analyst',
  peakEnergyWindow: 'variable',
  recoverySpeed: 'variable',
  primaryBlocker: 'distraction',
  selfTalkPattern: 'avoidant',
  motivationSource: 'outcome',
  accountabilityStyle: 'none',
  coreDriver: 'perform-better',
};
const question = QUESTIONS[currentQ];
advance(SKIP_DEFAULTS[question.key]);
```

---

### G2. Skipping blueprint via "Skip — I'll add habits myself"

**Scenario:** User clicks "Skip — I'll add habits myself" on the RoutineBlueprint screen.

**What happens:** `acceptBlueprint()` is called (sets `blueprintAccepted = true`). No habits are added. Dashboard loads with empty stacks.

**Discovered issue:** `getMissedStacks()` requires `stack.completions.length > 0` before returning a stack as missed. With no habits, no comeback fires. The product's core loop never activates.

**Dashboard empty state:** `getRecoveryInsights()` returns "Add your first habit to start building your recovery playbook." The add-habit modal is the path. Users who skip the blueprint start from blank — which is the exact blank-state problem the blueprint was designed to solve.

**Severity:** Low. Users who skip the blueprint chose to. The empty state guidance is adequate. But the "Skip" button undermines the blueprint's value — consider renaming it "Add my own habits instead" to make the path clear without the word "skip" (which implies dismissal).

---

### G3. User enters onboarding but abandons mid-assessment

**Scenario:** User completes the 4-screen onboarding (sets `onboardingComplete = true`), starts the Brain Assessment, completes Q1–Q4, closes the browser tab.

**State on return:** `onboardingComplete = true`, `brainProfile = null` (not yet set — `setBrainProfile()` is only called after the full reveal phase). App routing: `onboardingComplete = true` → check `brainProfile` → null → render `<BrainAssessment />`.

**Result:** User restarts the Brain Assessment from Q1. Their Q1–Q4 answers from the previous session are lost — the assessment state is local component state (`useState`), not persisted to the store. **This is correct behaviour** — the full assessment is required to set a valid `brainProfile`, and partial answers cannot be saved meaningfully.

**Issue:** There is no feedback that "You were in the middle of this assessment last time." User has no idea their prior answers were discarded.

**Severity:** Low. Minor UX friction. Fix: Add a "Continuing from where you left off..." message on the Brain Assessment start screen when `onboardingComplete = true && brainProfile === null`.

---

## H. Mobile + Slow-Internet Users

### H1. Flutter app with no Supabase credentials

**What happens:** `main.dart` guards Supabase init with `_supabaseUrl.isNotEmpty`. If no `--dart-define` credentials are passed, Supabase is skipped. `_syncToCloud()` in `neuro_provider.dart` is called on every state save — it checks for a current user session before syncing. Without Supabase, `Supabase.instance.client.auth.currentUser` is null → sync silently no-ops.

**Impact:** App functions correctly in fully offline mode. No crash. The sign-out button in the dashboard is hidden (only shown when `currentUser != null`). **This is well-handled.**

**Discovered edge case:** If the app is built with Supabase credentials BUT the device has no internet, `_syncToCloud()` will make a failing network call on every state save. The `try/catch` in the sync function absorbs the error silently (Phase 1 confirmed: "fire-and-forget"). On a 3G connection with 500ms+ latency, this means every habit completion triggers a background HTTP request that times out after 30+ seconds. Battery and network impact on poor connections is unmeasured.

**Severity:** Low. Silent failure is better than crashing. Battery impact is theoretical.

---

### H2. PWA offline-first behaviour on web

**What happens:** vite-plugin-pwa registers a service worker. The offline shell is served from cache. But the web app is purely local (no API calls), so "offline" is the app's normal operating mode.

**Issue not covered in Phase 1:** The service worker caches the app shell at install time. If a new version of the app is deployed, returning users may be served the old cached version until the service worker updates (which requires a background refresh, then a page reload). This is the standard PWA update delay problem.

**Severity:** Low. Standard PWA trade-off. Address with `skipWaiting: true` in the service worker config and a "New version available — reload to update" banner.

---

## I. Enterprise / Shared-Device Users

### I1. Multiple users on one browser

**Scenario:** Two employees at a company that trialled NeuroSync on shared workstations. User A completes onboarding. User B opens the same browser — sees User A's dashboard, User A's name, User A's habits.

**Impact:** User B has two options: use User A's account or clear localStorage. "Clear localStorage" is not a visible UI option — they would need DevTools or to look for a settings/reset option. No such option is surfaced in the current app.

**Severity:** Medium for enterprise/team use cases. The web app has no multi-user support and no visible "log out / start fresh" mechanism.

**Fix:** Add a "Start fresh / This isn't me" link on the dashboard header for the web app. This calls `resetAllData()` and clears `onboardingComplete`, routing back to onboarding.

---

### I2. Corporate firewall blocks Stripe Checkout URLs

**Scenario:** User is at work, hits the freemium gate, clicks upgrade. Stripe Checkout URL is blocked by corporate firewall or content filter.

**Impact:** `url_launcher` on Flutter opens the URL — if blocked, the browser shows an error page. The user returns to the app without completing payment. No feedback that payment failed vs. was blocked.

**Severity:** Low. Standard e-commerce issue. Not worth fixing in MLP.

---

## Summary: Severity-Ranked Issue List

| # | Issue | Severity | File(s) | Effort |
|---|-------|----------|---------|--------|
| 1 | Web `upgradeToPro()` bypasses payment (C1) | 🔴 Critical | `useNeuroStore.ts:642`, `ComebackGateModal.tsx` | S |
| 2 | Stripe cancellation webhook silently fails — `stripeCustomerId` never written (C2) | 🔴 Critical | `stripe-webhook/index.ts` | M |
| 3 | Brain Assessment Skip button corrupts brain profile for Q2–Q8 (G1) | 🔴 High | `BrainAssessment.tsx:~281` | S |
| 4 | `isPro` stored client-side — trivially editable via DevTools (C1) | 🔴 High | `useNeuroStore.ts` | L (requires auth) |
| 5 | Comeback freemium count bypassed via system clock manipulation (C3) | 🟡 Medium | `statsHelpers.ts:103` | S |
| 6 | SCALE_DOWN recalibration resets myelination to 0 (F4) | 🟡 Medium | `useNeuroStore.ts:580` | S |
| 7 | `recalibrationEngine` can suggest same replacement template twice (F3) | 🟡 Medium | `recalibrationEngine.ts:52` | S |
| 8 | Retake Assessment sets `brainProfile = null` via TypeScript cast (B4) | 🟡 Medium | `BrainProfileCard.tsx` | S |
| 9 | Zustand migration does not set `blueprintAccepted` — causes re-blueprint for returning users (F1) | 🟡 Medium | `useNeuroStore.ts:688` | S |
| 10 | Multi-device data loss on web — no export mechanism (D2) | 🟡 Medium | Architecture | M |
| 11 | "Skip actions" button keeps Recovery Rate at 0% — churn trigger (E3) | 🟡 Medium | `ComebackProtocol.tsx` | S |
| 12 | `DST boundary bug` in `getMissedStacks` "yesterday" calculation (D1) | 🟢 Low | `comebackHelpers.ts:8` | S |
| 13 | Double-tap neurochemistry double-award (A2) | 🟢 Low | `useNeuroStore.ts:295` | S |
| 14 | Double-tap check-in submission triggers duplicate recalibration (A3) | 🟢 Low | `submitCheckin`, `WeeklyCheckin.tsx` | S |
| 15 | No undo for accidental habit completion (B1) | 🟢 Low | `HabitCard.tsx` | M |
| 16 | No "start fresh" UI for shared-device multi-user (I1) | 🟢 Low | `Dashboard.tsx` header | S |

**Effort key:** S = <2 hours, M = 2–8 hours, L = >1 day

---

## Phase 3 Verdict

The app has **two critical security/revenue vulnerabilities** (premium bypass, Stripe cancellation failure) and **one critical data integrity bug** (Brain Assessment skip corruption). These must be fixed before any paid traffic is sent to the product.

The remaining issues are Medium or Low severity — addressable in a focused 1-week hardening sprint before MLP launch.

No crash-level bugs were found in the happy path. The app is structurally sound for the use case it was designed for. The bugs are concentrated in the edge cases (Skip button, system clock, shared device) and the monetization layer — which is consistent with a product that was built feature-first before the payment and security paths were hardened.

---

*End of Phase 3 — User Abuse Testing*
*Next: Phase 4 — Research Backing (citations for all major claims)*
