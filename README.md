# NeuroSync

A habit-recovery app built around what happens **after you miss a habit**. Most trackers reset your streak to zero. NeuroSync starts a *Comeback Protocol* instead: a short reframe plus small, energy-aware actions to get you back on track. Every comeback is logged so you can see your own recovery patterns.

The repo contains a **React web app (PWA)**, a **Flutter mobile app**, and a **Supabase Edge Function** that handles Stripe subscription webhooks.

## Features

- **Brain Assessment:** an 8-question onboarding interview that maps you to one of 16 profiles (failure style × core driver). The profile drives which habits are suggested and how the Comeback Protocol responds.
- **Comeback Protocol:** triggered on a missed habit. Personalised by failure style and peak-energy window. The free tier is gated to 3 uses a month, with an upgrade prompt after that.
- **Habit cards:** implementation intentions ("when X, then Y"), a 7-day grid, and progress milestones.
- **Bad-habit swaps:** friction levels, urge surfing and slip logging.
- **Weekly check-in** feeding a recalibration step that suggests scaling a habit down, replacing it or updating it.
- **Stats:** recovery rate, comeback streak, activity timeline.
- Dark/light theme, installable as a PWA, works offline.

## Architecture

| Part | Stack | Notes |
|---|---|---|
| Web app (`/src`) | React 19, TypeScript, Vite, Tailwind CSS v4, Zustand v5, framer-motion | State persists to `localStorage`, with a schema-version migration guard. PWA via `vite-plugin-pwa`. Product analytics via PostHog |
| Mobile app (`/flutter_app`) | Flutter, Riverpod | Port of the web feature set, with Supabase auth and cloud sync |
| Payments (`/supabase/functions/stripe-webhook`) | Supabase Edge Function (Deno), Stripe | Verifies the Stripe signature, then on `checkout.session.completed` / `customer.subscription.deleted` sets or clears the user's Pro flag in Supabase |

## Getting started

### Web app

```bash
npm install
npm run dev      # Vite dev server
npm run build    # tsc type-check + production build
npm run lint
```

### Mobile app

See [`flutter_app/README.md`](flutter_app/README.md).

### Stripe webhook

Deploy with the Supabase CLI (`supabase functions deploy stripe-webhook`) and set `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` as function secrets.

## Product docs

[`PRD.md`](PRD.md) has the product requirements, [`ROADMAP.md`](ROADMAP.md) the plan and [`STATUS.md`](STATUS.md) the current build state.

## Status

Alpha. Next steps:
- [ ] Sync the web app through Supabase, as the mobile app already does
- [ ] Automated tests for the assessment scoring and recalibration logic
- [ ] Public deployment
