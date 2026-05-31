# ✦ Lumina

> **An AI-powered personal growth companion app built to elevate daily ritual, cognitive clarity, and emotional resilience.**
>
> Lumina is crafted with a singular world-class standard, matching the emotional intelligence of a human mentor with a premium, circadian-aware visual design. It bridges Flutter's high-performance UI shell with Deno Edge Functions and Google Gemini AI to create a deeply personalized coaching, task-planning, and trend-analysis system.

---

## 🎨 Aesthetic Soul & Identity

Lumina does not default to pre-packaged theme templates. Every color, curve, typography choice, and animation exists to serve a core emotional contract: **Clarity & Growth**.

```
IDENTITY DECLARATION
────────────────────
Core Emotion:        Clarity & Self-Awareness
User Context:        Overwhelmed high-achievers and creative builders.
                     Opens for morning focus rituals and late-night reflection.
Material Feel:       A hand-bound leather journal with warm Japanese parchment paper,
                     resting under the soft glow of a brass desk lamp.
Signature Colour:    #F0A500 (Warm Amber Gold)
Supporting Palette:  #0A0A0F (Obsidian Dark), #7B61FF (Indigo Accent),
                     #F7F6F2 (Warm Light Parchment), #34C97B (Growth Green)
Motion Verb:         Breathes (Staggered fades, fluid curves, organic transitions)
Font Tension:        Bricolage Grotesque (Humanist Headlines) × DM Sans (Precise UI)
Spatial Philosophy:  Generous & Breathing (Generous whitespace, subtle card borders)
Signature Element:   Living Canvas — A dynamic, time-aware circadian theme engine
```

### 🌓 The Living Canvas Engine
Rather than a binary dark/light switch, Lumina implements **Living Canvas**, a state-aware engine linked to the user's local time. The system smoothly transitions across four distinct phases:
1. **Morning Clarity (5 AM - 11 AM):** Soft sunlit accents (`#FFFBF1` base, `#FFB434` gold), high-contrast type rhythm to spark morning energy.
2. **Daylight Focus (11 AM - 6 PM):** Clean parchment structure, responsive snaps, balanced contrast for maximum daily productivity.
3. **Evening Warmth (6 PM - 11 PM):** Deeper amber tints, dimmed borders, relaxed motion curves to facilitate evening grounding.
4. **Wind Down (11 PM - 5 AM):** Obsidian depths (`#050509`), low contrast ratios, extended slow transitions, and minimized cognitive friction for bedtime logging.

---

## 🚀 Key Feature Experiences

| Route | Screen | Core Experience | Metaphor & Intent |
|---|---|---|---|
| `/auth` | **Authentication** | Onboarding & Sign-in | *Entering a quiet sanctuary* — zero visual noise, smooth entry. |
| `/dashboard` | **Dashboard** | Daily focus, tasks, and habits | *Your desk for the day* — clear visual hierarchy, streak tracking, action highlights. |
| `/log` | **Daily Log** | Rapid emotion, energy, and log tracking | *The leather journal* — effortless tactile input with smooth sliders and notes. |
| `/insights` | **Insights** | Visual data analysis & habit heatmaps | *The self-awareness mirror* — premium `fl_chart` representations of correlation data. |
| `/mentor` | **AI Mentor** | Personal growth coach and spark cards | *A wise counselor* — personalized insights generated overnight, waiting for you. |
| `/mentor/untangle` | **Untangle Chat** | Deep-dive cognitive restructuring chat | *A quiet fireplace conversation* — distraction-free immersive text interface. |
| `/agents` | **Agents Codex** | Orchestration of specialized AI sub-agents | *Your cognitive architects* — visualizing the background team executing specific goals. |
| `/settings` | **Settings** | Data sync, local Hive control, theme override | *The control panel* — absolute privacy control, credentials setup, and manual overrides. |

---

## 🤖 The AI Agent Fleet

Lumina is powered by a multi-agent orchestration architecture executed via **Supabase Edge Functions** and **Google Gemini 1.5 Flash**:

1. **Pattern Mining Agent (`pattern-mining-agent`)**
   * *Trigger:* Nightly cron job at 11:30 PM.
   * *Action:* Aggregates 30-day logs, computes local statistics (mood and energy trends, habit consistency), and calls Gemini to generate exactly 5 highly specific, actionable insight cards for the next morning.
2. **Weekly Debrief Agent (`weekly-debrief-agent`)**
   * *Trigger:* Sunday cron job at 7:00 PM.
   * *Action:* Scores the user across 5 dimensions (Mood, Energy, Consistency, Focus, Self-Awareness), generates a custom debrief card, and fires a push notification outlining priorities for the coming week.
3. **Burnout Interception Agent (`burnout-interception-agent`)**
   * *Trigger:* Real-time, fired when a Daily Log is saved.
   * *Action:* Detects consecutive low mood/energy days or dropouts. If risk exceeds 50%, inserts an urgent warning, suggests a micro-habit, and automatically defers low-priority tasks for the next day.
4. **Morning Brief Agent (`morning-brief-agent`)**
   * *Trigger:* Daily cron job at 8:00 AM.
   * *Action:* Prepares a deterministic 3-line morning notification outlining focus tasks, streak warnings, and historical day-of-week correlations without calling expensive API loops.
5. **Goal Decomposition Agent (`goal-decomposition-agent`)**
   * *Trigger:* Real-time, fired when the user inputs a major objective (e.g., "Run a 5K in 60 days").
   * *Action:* Calculates timeframes, maps objectives into 2–3 macro phases, builds week-by-week milestones, and pre-populates initial daily tasks directly in the user's task calendar.

---

## 🛠️ System Architecture & Technology Stack

Lumina adheres to strict **Clean Architecture (Feature-First)** patterns, separating code by boundaries that guarantee maintainability, testability, and clarity.

```
lib/
├── core/                  # Shared foundations
│   ├── theme/             # Design tokens & Living Canvas engine
│   ├── constants/         # App constants and configuration keys
│   ├── extensions/        # Context-aware helpers and utilities
│   └── utils/             # Haptic and platform interfaces
├── features/              # Feature-driven modules (Clean Architecture)
│   ├── dashboard/         # Progress and focus highlights
│   ├── auth/              # Supabase auth integrations
│   ├── log/               # Daily metrics logging
│   ├── insights/          # Pattern plotting with fl_chart
│   ├── mentor/            # AI mentoring & Untangle chat
│   ├── agents/            # Multi-agent visualization
│   └── settings/          # Local & remote config
├── router/                # Custom GoRouter shell & animations
├── shared/                # Global widgets & custom animations
└── main.dart              # Secure startup bootstrap
```

### Technical Specs
* **Frontend Framework:** Flutter (Null-Safe, Native Performance)
* **Backend Platform:** Supabase (Database, Auth, Storage, Edge Functions)
* **Local Caching:** Hive (Offline-first, encrypted key-value stores)
* **State & Dependency:** Riverpod (Declarative provider chains)
* **Navigation:** GoRouter (Clean shell routing with custom `FadeSlideTransition`)
* **Haptics:** Precise haptic engine (`HapticUtils`) triggering micro-tactile feedback on selections, saves, and streaks.

---

## 📥 Getting Started

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
* [Dart SDK](https://dart.dev/get-tools)
* [Supabase CLI](https://supabase.com/docs/guides/cli) (if deploying or debugging edge functions locally)

### 2. Environment Configuration
Create a `.env` file in the project root matching [.env.example](file:///v:/Flutter_26/lumina/.env.example):
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
# Firebase credentials for cross-platform notifications (optional)
FIREBASE_ANDROID_API_KEY=...
FIREBASE_IOS_API_KEY=...
```

### 3. Bootstrap & Dependency Resolution
Resolve assets, plugins, and dependencies:
```bash
flutter pub get
```

Generate database models and Riverpod provider codegen files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Running the Development Server
Launch the application on your preferred mobile device or emulator:
```bash
flutter run
```

---

## ⚡ Deployment & Supabase Edge Functions

Lumina's intelligent background services reside in secure Supabase Deno environments.

### Setting Up Secrets
Ensure the following secrets are configured in your Supabase dashboard or via the CLI before executing functions:
```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
supabase secrets set FCM_SERVER_KEY=your_firebase_messaging_key
```

### Function Deployment
Deploy all agent functions using the Supabase CLI:
```bash
supabase functions deploy pattern-mining-agent
supabase functions deploy weekly-debrief-agent
supabase functions deploy burnout-interception-agent
supabase functions deploy morning-brief-agent
supabase functions deploy goal-decomposition-agent
```

### Nightly & Weekly Cron Setup
Run the SQL queries located in the database migrations or copy them directly into the Supabase SQL editor to schedule the cron tasks.
```sql
-- Example schedule for Pattern Mining Agent (Nightly at 11:30 PM IST / 18:00 UTC)
SELECT cron.schedule(
  'nightly-pattern-mining',
  '30 18 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/pattern-mining-agent',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb,
    body := '{}'::jsonb
  ) AS request_id;
  $$
);
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](file:///v:/Flutter_26/lumina/LICENSE) file for details.

---

*Crafted with absolute obsession by the Lumina Product Studio. Changing the standard of personal self-awareness.*
