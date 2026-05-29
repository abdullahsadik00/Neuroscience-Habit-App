# NeuroFlow — Flutter Mobile App

Flutter port of the NeuroFlow web app. Full feature set: Habit Stacks, Neuro Swaps, Neurochemistry HUD, Brain Assessment, Comeback Protocol, Weekly Check-ins, Recalibration Engine, and Supabase auth + cloud sync.

---

## One-time Setup

### Step 1 — Install Flutter

```bash
# macOS (recommended: via fvm)
brew install fvm
fvm install stable
fvm global stable

# Add to ~/.zshrc:
export PATH="$HOME/fvm/default/bin:$PATH"

# Or install Flutter directly:
# https://docs.flutter.dev/get-started/install/macos
```

Verify:
```bash
flutter doctor
```

### Step 2 — Install dependencies

```bash
cd flutter_app
flutter pub get
```

### Step 3 — Set up Supabase (for auth + cloud sync)

> Skip this for local-only mode — the app works offline without Supabase credentials.

1. Create a project at https://supabase.com (free tier is fine)
2. Enable **Email magic link** auth:
   - Dashboard → Authentication → Providers → Email
   - Enable Email: **ON**, Confirm email: **OFF**, OTP sign-in: **ON**
3. Add redirect URLs:
   - Dashboard → Authentication → URL Configuration → Redirect URLs
   - Add: `com.neuroflow://login-callback/`
   - Add: `http://localhost` (for web/dev)
4. Run the schema SQL in the SQL editor:

```sql
create table neuro_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state_json jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

alter table neuro_state enable row level security;

create policy "Users own their state"
  on neuro_state for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

5. Copy your credentials from Dashboard → Project Settings → API.

### Step 4 — Configure deep links (for magic link redirect back to app)

**Android** — in `android/app/src/main/AndroidManifest.xml`, inside the `<activity>` tag:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.neuroflow" android:host="login-callback" />
</intent-filter>
```

**iOS** — in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.neuroflow</string></array>
  </dict>
</array>
```

---

## Running the App

### Without Supabase (local-only, no auth)
```bash
flutter run -d chrome        # web
flutter run                  # connected device / iOS simulator
```

### With Supabase (auth + cloud sync)
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# Or for web:
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

> Never commit your Supabase keys to git. Keep them in a local `.env` or shell alias.

---

## Stack

| Concern | Library |
|---|---|
| State | `flutter_riverpod` 2.x (`Notifier`) |
| Persistence | `shared_preferences` (local) + Supabase Postgres (cloud) |
| Auth | `supabase_flutter` (email magic link) |
| Animations | `flutter_animate` |
| Fonts | `google_fonts` (Inter) |
| IDs | `uuid` |

## Project structure

```
lib/
├── main.dart              # Preloads SharedPreferences, bootstraps ProviderScope + Supabase
├── app.dart               # MaterialApp + _AppRouter (auth gate → onboarding → dashboard)
├── theme/app_theme.dart   # Dark + light ThemeData, neurochemical colours
├── models/                # All data models with toJson/fromJson
├── providers/
│   ├── neuro_provider.dart  # NeuroNotifier — state, local save, cloud sync
│   └── auth_provider.dart   # Supabase auth stream + currentUser providers
├── utils/                 # Ported 1:1 from TS: neuro_helpers, stats_helpers, etc.
├── data/habit_library.dart  # Full 30-habit library
├── pages/
│   ├── auth_gate_page.dart         # Magic link email form
│   ├── onboarding_page.dart
│   ├── brain_assessment_page.dart
│   ├── routine_blueprint_page.dart
│   └── dashboard_page.dart
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
- [x] Supabase auth (email magic link)
- [x] Cloud state sync (Supabase Postgres — auto-syncs on every action)
- [x] Sign out with confirmation dialog
