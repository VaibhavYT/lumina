# Milestone 5 — AI Mentor Screen + Supabase Backend & Edge Functions

---

## Agent Context

You are a world-class Flutter engineer and product designer with 40 years of combined experience building premium consumer applications. You are also a backend architect experienced in Supabase, PostgreSQL, and serverless edge functions. Milestones 1–4 are complete — the entire frontend UI is functional with local data. Now you build the **AI Mentor Screen** (the conversational intelligence layer) and wire up the complete **Supabase backend** with Gemini-powered Edge Functions.

This milestone transforms Lumina from a beautiful local journal into a **living, learning AI life companion**.

---

## Milestone 5 Objective

1. Build the **AI Mentor Screen** — a conversational, card-based interface where the AI delivers personalized insights, daily reflections, weekly growth plans, and real-time coaching
2. Build the complete **Supabase backend**: database schema, storage, row-level security
3. Build all **Supabase Edge Functions** powered by Gemini 1.5 Flash
4. Wire up the **sync layer** — local Hive data syncs to Supabase, and AI responses flow back to the app

---

## Part A — AI Mentor Screen

### A.1 Screen Philosophy

The Mentor screen is **not a chatbot**. It is a curated feed of personalized intelligence cards — think Spotify's Daily Mixes, but for your personal growth. The AI doesn't wait to be asked. It proactively surfaces insights, asks reflective questions, and offers weekly plans.

The tone is: warm, wise, direct, non-judgmental. Not a cheerleader, not a therapist — a mentor.

---

### A.2 Screen Architecture

A `CustomScrollView` with sections:

1. **Mentor Header** (identity + status)
2. **Daily Reflection Card** (AI's reflection on today's log)
3. **Active Coaching Card** (the AI's current focus area for the user)
4. **Weekly Growth Plan** (expandable, structured plan)
5. **Insight Feed** (scrollable cards, most recent first)
6. **Ask Your Mentor** (open-ended input — optional, not a full chat)

---

### A.3 Mentor Header

Create a **mentor identity** — Lumina has a personality, not just an API.

Design:
- A 72dp circle with a **radial gradient avatar** — not a photo, but an abstract geometric mandala pattern rendered with `CustomPainter`. It uses the amber and indigo accent colors, a 6-petal symmetrical pattern. It slowly rotates (full rotation over 30 seconds, looping — `AnimationController` with `repeat()`)
- To the right of the avatar:
  - Name: "Lumina" in `headingLarge`
  - Status: "Your AI Growth Mentor" in `bodySmall` `textSecondary`
  - A small online/active indicator: 8dp green dot with a slow pulsing glow animation
- Below this row, a horizontal scrollable row of 3 `LuminaTag` chips showing the mentor's current focus areas: e.g., "Energy", "Focus", "Sleep" — derived from the user's recent pattern analysis

---

### A.4 Daily Reflection Card

**Trigger:** Generated after the user completes their daily log. The edge function receives today's full log and generates a personalized reflection.

**Design:**
- The most visually prominent card on the screen
- Background: `backgroundCard` with a gradient border (amber → indigo, same as dashboard mentor card)
- Top: "Today's Reflection" label + date in `labelSmall` amber
- The AI-generated reflection text: 3–5 sentences in `bodyLarge`. The text renders with a **typewriter animation** — characters appear one by one at 18ms per character interval. This creates the feeling that the AI is "thinking" and writing in real time. Use `AnimatedTextKit` package or build a custom `TypewriterText` widget.
- Below the text: An `ActionRow` with 2 text buttons:
  - "Save to Journal" — saves the reflection as a note
  - "Go Deeper →" — triggers a follow-up question from the AI (see Ask Your Mentor section)
- If today's log is not yet complete, this card shows: "Complete today's log to receive your reflection" with a gentle progress indicator

**Loading state:** An animated "thinking" indicator — 3 amber dots bouncing in sequence (the classic typing indicator, but styled to match the design system: 8dp dots, 6dp gap, bounce animation with staggered delays).

---

### A.5 Active Coaching Card

The AI's current "coaching mission" for this user — derived from their patterns over the last 7–30 days.

**Design:**
- Slightly smaller than the reflection card
- Left accent bar: 4dp wide, 100% card height, amber colored
- Top: "Current Focus" label in `labelSmall` amber + a progress arc (40dp diameter) showing progress toward the coaching goal (e.g., "Day 3 of 7")
- Headline: e.g., "Building Your Morning Routine" in `headingMedium`
- Body: 2 sentences on why this focus was chosen (AI-generated, based on patterns) in `bodyMedium` `textSecondary`
- Bottom: "Today's Action:" label + a single bolded action item in `bodyLarge` (e.g., "Spend the first 30 minutes without your phone")
- A small "Done for Today ✓" button (outline style) that marks today's action as complete — stores a flag in Hive

---

### A.6 Weekly Growth Plan

An expandable section. Collapsed by default (shows just the header). Tapping expands it with a smooth height animation.

**Collapsed state:**
- "Your Week Ahead" in `headingMedium`
- Subtitle: "Tap to see your personalized weekly plan" in `bodySmall` `textSecondary`
- Right: A chevron icon that rotates 180° when expanded

**Expanded state (AnimatedCrossFade or SizeTransition):**
7 day rows (Mon–Sun), each showing:
- Day name in `labelLarge`
- A small icon representing the day's focus (energy, mindfulness, productivity, etc.)
- One-line focus description in `bodySmall`
- A small checkbox if today or past (shows completion status)
- Future days: slightly muted (textTertiary) — not clickable

The plan is generated weekly by the `generate-weekly-plan` edge function and cached locally for 7 days.

---

### A.7 Insight Feed

Below the pinned cards, a feed of AI-generated insight cards. Each card is a standard `LuminaCard` with:

**Card types** (the AI generates all of these):

1. **Pattern Insight:** "Your best work days follow 7+ hours of sleep" — with a small 3-point mini chart supporting the claim
2. **Behavioral Observation:** "You tend to rate your mood lower on days you skip your morning habit" — amber text, thoughtful tone
3. **Strength Spotlight:** "You've been remarkably consistent with [habit] for 3 weeks. This is rare." — green accent, celebratory but not over-the-top
4. **Gentle Challenge:** "You haven't reflected in your notes for 5 days. What's been on your mind?" — indigo accent, inquisitive
5. **Weekly Summary:** (generated every Sunday) — a brief paragraph wrapping up the week's patterns

Each card shows:
- Category tag (top left, `LuminaTag`)
- Insight text (`bodyLarge`)
- "Generated [X days ago]" in `labelSmall` `textTertiary` (bottom right)
- A subtle dismiss button (✕ in top right) that removes the card with a swipe-right `Dismissible`

Cards are sorted by recency. Old cards are kept for 30 days.

---

### A.8 Ask Your Mentor

At the very bottom of the scroll (above the bottom nav clearance): a text input field styled as a message composer:

- Background: `backgroundCard`, rounded pill (24dp radius), full-width minus page padding
- Left: The amber Lumina avatar dot (16dp)
- Center: `TextField` with placeholder "Ask your mentor anything..." in `textTertiary`
- Right: A send button (amber circle, 36dp, arrow icon)
- No send history is shown inline here — responses appear as new Insight Feed cards at the top of the feed
- On send:
  1. Show a loading state: the send button becomes a spinning amber loader
  2. Call the `ask-mentor` edge function
  3. On response, dismiss loading, insert a new Insight Feed card at the top of the feed with a slide-down animation
  4. Clear the input field
  5. Haptic: `HapticUtils.light()`

---

## Part B — Supabase Backend

### B.1 Database Schema

Create the following tables in Supabase (Postgres). All tables include `created_at` and `updated_at` timestamp columns with auto-update triggers.

Note: Authentication is out of scope — use a hardcoded `device_id` (UUID stored in SharedPreferences on first launch) as the user identifier. No Supabase Auth is set up.

```sql
-- Device/User profile
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT UNIQUE NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily logs
CREATE TABLE daily_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL REFERENCES profiles(device_id),
  log_date DATE NOT NULL,
  mood INTEGER CHECK (mood BETWEEN 1 AND 5),
  mood_note TEXT,
  energy INTEGER CHECK (energy BETWEEN 1 AND 5),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(device_id, log_date)
);

-- Tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  log_date DATE NOT NULL,
  title TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('high', 'normal', 'low')),
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habits definition
CREATE TABLE habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  name TEXT NOT NULL,
  emoji TEXT,
  color_hex TEXT,
  frequency TEXT DEFAULT 'daily',
  custom_days TEXT[], -- ['Mon','Wed','Fri'] for custom frequency
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habit completions
CREATE TABLE habit_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  completion_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(habit_id, completion_date)
);

-- AI Mentor insights (stored for persistence and feed)
CREATE TABLE mentor_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  insight_type TEXT NOT NULL, -- 'daily_reflection', 'pattern', 'coaching', 'weekly_plan', 'ask_response'
  headline TEXT,
  body TEXT NOT NULL,
  metadata JSONB, -- extra structured data per type
  is_dismissed BOOLEAN DEFAULT FALSE,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- null = never expires
);
```

Create Postgres indexes on `device_id`, `log_date`, and `generated_at` columns for query performance.

---

### B.2 Row-Level Security

Since there is no auth, use a simple RLS approach based on the `device_id` passed in the request headers:

For each table, enable RLS and create a policy:
```sql
CREATE POLICY "device_access" ON daily_logs
  USING (device_id = current_setting('request.jwt.claims', true)::json->>'device_id');
```

Note: Since there's no JWT auth, pass `device_id` via the edge function — the edge function validates and queries on behalf of the device. The Flutter app calls edge functions, not the Supabase tables directly.

---

### B.3 Sync Layer

Create a `SyncService` in Flutter (`lib/core/services/sync_service.dart`):

```
SyncService:
- syncDailyLog(DailyLog log) → upserts to Supabase via edge function or direct client
- syncHabitCompletion(habitId, date) → upserts to Supabase
- syncTasks(List<Task> tasks) → bulk upsert
- fetchRecentInsights(deviceId) → pulls mentor_insights from last 30 days
```

**Sync strategy:**
- Write to Hive first (instant, offline-capable)
- Then call `SyncService` in the background (fire-and-forget with error logging)
- On app startup, `SyncService.fetchRecentInsights()` refreshes the mentor feed
- If sync fails (no network), queue the operation in a Hive `pendingSync` box and retry on next app launch

---

## Part C — Supabase Edge Functions

All edge functions are TypeScript Deno functions. Create in `supabase/functions/`.

---

### C.1 `generate-daily-reflection`

**Trigger:** Called from Flutter after daily log save.

**File:** `supabase/functions/generate-daily-reflection/index.ts`

**Logic:**
1. Receive the full daily log (mood, energy, tasks, notes, habitCompletions) + last 7 days of logs for context
2. Construct a rich Gemini prompt (see prompt template below)
3. Call Gemini 1.5 Flash API
4. Parse and validate the response
5. Store the insight in `mentor_insights` table (type: `daily_reflection`)
6. Return the insight to the Flutter client

**Gemini Prompt Template:**
```
You are Lumina, a warm, wise, and direct AI life mentor. You are not a therapist or a cheerleader — you are a trusted mentor who speaks honestly and helpfully.

Today's log for [display_name]:
- Date: [date]
- Mood: [mood]/5 ([mood_label])
- Energy: [energy]/5 ([energy_label])
- Tasks completed: [completed]/[total]
- Habits done: [habits_done] of [total_habits]
- Notes: "[notes]"

Recent context (last 7 days):
[summary of last 7 days mood/energy averages]

Write a personalized daily reflection for this person. Rules:
1. Be specific — reference their actual mood, energy, and notes
2. Maximum 4 sentences
3. Tone: warm, wise, direct — not overly positive
4. End with one gentle, actionable observation or question
5. Do NOT use generic phrases like "Great job!" or "Keep it up!"
6. Return ONLY the reflection text, nothing else
```

**Response handling:**
- Extract text from Gemini response
- Validate: must be 2–6 sentences, must be under 600 characters
- Fallback if Gemini fails: return a meaningful pre-written reflection template

---

### C.2 `analyze-emotional-triggers`

**Trigger:** Called from Insights screen when the emotional triggers section loads (max once per 24 hours).

**Logic:**
1. Receive last 30 days of notes + mood scores
2. Ask Gemini to identify recurring themes and their sentiment + mood correlation
3. Return structured JSON

**Gemini Prompt:**
```
Analyze these journal notes and identify emotional triggers — recurring themes that correlate with high or low mood.

Data (format: date | mood 1-5 | notes):
[formatted data]

Return ONLY a JSON array with this exact structure — no markdown, no explanation:
[
  {"tag": "string", "sentiment": "positive|negative|neutral", "frequency": number, "moodCorrelation": number between -1.0 and 1.0}
]

Identify 5–12 triggers. Be specific and insightful. Avoid generic tags like "work" — prefer "late meetings", "creative work", "team pressure".
```

**Parse the JSON response safely** — wrap in try/catch, validate each field.

---

### C.3 `generate-weekly-plan`

**Trigger:** Called every Sunday (or when the user opens Mentor screen and no plan exists for this week).

**Logic:**
1. Receive last 30 days of aggregated data (mood trend, energy trend, habit completion rates, top triggers)
2. Generate a 7-day personalized weekly plan

**Gemini Prompt:**
```
You are Lumina, an AI life mentor. Based on this person's patterns, create a practical, personalized weekly growth plan.

Patterns:
- Average mood: [X]/5 (trend: [improving/declining/stable])
- Average energy: [X]/5
- Top positive triggers: [list]
- Top negative triggers: [list]
- Lowest habit consistency: [habit names]
- Burnout risk score: [X]/100

Create a 7-day plan (Monday–Sunday). For each day, provide:
- One focus theme (1-3 words)
- One specific action (1 sentence, actionable, realistic)
- One micro-habit or reflection prompt

Return ONLY a JSON array:
[
  {"day": "Monday", "theme": "string", "action": "string", "microHabit": "string"},
  ...
]
```

---

### C.4 `ask-mentor`

**Trigger:** User submits a question via the "Ask Your Mentor" input.

**Logic:**
1. Receive the user's question + last 14 days of context (mood, energy, habits summary)
2. Generate a mentor response

**Gemini Prompt:**
```
You are Lumina, an AI life mentor. A person is asking you a question about their personal growth journey.

Their context (last 14 days):
- Average mood: [X]/5
- Average energy: [X]/5
- Habit consistency: [X]%
- Recent note themes: [top 3 themes]

Their question: "[user_question]"

Respond as a warm, wise, direct mentor. Rules:
1. Be specific to their context — don't give generic advice
2. Maximum 5 sentences
3. End with one actionable suggestion or a thought-provoking question
4. Never start with "I" or "Great question!"
5. Return ONLY the response text
```

---

### C.5 `detect-burnout-coaching`

**Trigger:** Called weekly to determine if the active coaching card should update.

**Logic:**
1. Receive 30-day pattern summary
2. Ask Gemini to identify the single most impactful coaching focus for this user
3. Generate a 7-day mini coaching plan

**Response structure:**
```json
{
  "coachingTitle": "string",
  "coachingReason": "string (2 sentences)",
  "dailyActions": ["string", "string", "string", "string", "string", "string", "string"]
}
```

---

## Part D — Flutter Wiring

### D.1 Supabase Edge Function Client

Create `EdgeFunctionClient` in `lib/core/services/edge_function_client.dart`:
- Uses `Supabase.instance.client.functions.invoke(functionName, body: payload)`
- Wraps calls in try/catch, returns `Either<Failure, T>` using a simple result type
- Logs errors to console in debug mode

### D.2 Mentor Repository

`MentorRepository`:
- `getDailyReflection(String deviceId, String date)` → checks Hive cache first, calls edge function if no cache
- `getInsightFeed(String deviceId)` → fetches from Supabase `mentor_insights` table, merges with local cache
- `askMentor(String deviceId, String question)` → calls edge function, stores response in Hive + Supabase
- `getWeeklyPlan(String deviceId)` → checks if current week's plan exists, generates if not

### D.3 Mentor Screen Provider

`MentorNotifier` (Riverpod `AsyncNotifierProvider`):
- Loads all mentor data in parallel using `Future.wait`
- Exposes: `dailyReflection`, `insightFeed`, `weeklyPlan`, `coachingCard` as separate computed providers
- `dismissInsight(String id)` — marks dismissed in Hive and Supabase

---

## Deliverables for This Milestone

1. Mentor screen renders all sections with correct loading/empty/data states
2. Rotating avatar mandala renders and animates
3. Daily reflection typewriter animation works
4. Active coaching card shows today's action, completion state persists
5. Weekly plan expands/collapses with smooth animation
6. Insight feed renders all card types, dismissible works
7. Ask Your Mentor — input sends, response inserts at top of feed
8. All 5 Supabase Edge Functions are deployed and callable
9. Supabase database tables are created with correct schema
10. Sync service writes data to Supabase silently after every log save
11. Mentor insights survive app restart (loaded from Hive + Supabase on startup)

---

## Quality Bar

- The typewriter animation for the daily reflection is the signature interaction of this screen — it must feel alive
- Gemini responses must feel personal, not generic — test with real log data
- Edge function cold-start latency should be acceptable — show loading states proactively (optimistic UI where possible)
- The Ask Your Mentor field must handle long responses gracefully (text wraps, card expands)
- All edge functions must have error fallbacks — Gemini is not 100% reliable
