# Deploy Missing AI Agents — Lumina Growth Companion

---

## Your Identity & Expertise

You are a world-class full-stack engineer with 40 years of experience building production-grade Flutter + Supabase applications. You are an expert in:
- Supabase Edge Functions (Deno/TypeScript)
- Supabase pg_cron scheduled jobs
- Supabase database triggers and webhook patterns
- Google Gemini 1.5 Flash API integration
- Firebase Cloud Messaging (FCM) for push notifications
- Flutter Riverpod state management and background service patterns

You write clean, production-ready TypeScript for edge functions — no shortcuts, no TODOs, no placeholder logic. Every function has proper error handling, structured logging, and Gemini fallbacks.

---

## Project Context

This is **Lumina** — an AI-powered personal growth companion app. The Flutter frontend + Supabase backend is already partially built. The following edge functions are **already deployed** and working:

- `analyze-emotional-triggers`
- `ask-mentor`
- `detect-burnout-coaching`
- `fetch-mentor-insights`
- `generate-daily-reflection`
- `generate-weekly-plan`
- `sync-daily-log`

The Supabase project URL is read from environment variable `SUPABASE_URL`. The service role key is `SUPABASE_SERVICE_ROLE_KEY`. The Gemini API key is `GEMINI_API_KEY`. FCM server key is `FCM_SERVER_KEY`. These are already set in Supabase Edge Function secrets — do not hardcode them.

The existing database has these tables (already created):
- `profiles` (device_id, display_name)
- `daily_logs` (device_id, log_date, mood 1-5, energy 1-5, notes)
- `tasks` (device_id, log_date, title, is_completed, priority, sort_order)
- `habits` (device_id, name, emoji, color_hex, frequency, is_active)
- `habit_completions` (habit_id, device_id, completion_date)
- `mentor_insights` (device_id, insight_type, headline, body, metadata, is_dismissed, generated_at, expires_at)

---

## What You Must Build

You need to create and deploy **5 new Supabase Edge Functions** and set up **scheduled triggers** for the ones that run automatically. For each function, create the file at `supabase/functions/<function-name>/index.ts`.

After writing all functions, also update the Flutter app to integrate with the 2 functions that require active Flutter integration (Goal Decomposition Agent and Burnout Interception real-time response).

---

## AGENT 1 — `pattern-mining-agent`

### Purpose
A nightly background agent that autonomously analyzes the last 30 days of a user's data and writes 3–5 personalized insight cards to the `mentor_insights` table. The user wakes up to new insights without doing anything.

### Schedule
Run via Supabase `pg_cron` every day at **11:30 PM IST (18:00 UTC)**. Set this up using a Supabase database cron job that calls this edge function via `pg_net` HTTP POST.

### Edge Function Logic (`supabase/functions/pattern-mining-agent/index.ts`)

1. Accept a POST request with optional `{ device_id: string }`. If no `device_id` is provided, fetch ALL device IDs from `profiles` and run the analysis for each user (batch mode for the cron trigger).

2. For each device_id, fetch:
   - Last 30 days from `daily_logs` (mood, energy, notes, log_date)
   - Last 30 days from `habit_completions` joined with `habits`
   - Last 30 days from `tasks` (completed vs total per day)

3. Compute these local statistics before calling Gemini (do the math in TypeScript, pass the computed summary to Gemini — do NOT send raw data):
   - `avgMood`: average mood over 30 days
   - `avgEnergy`: average energy over 30 days
   - `moodTrend`: "improving" | "declining" | "stable" (compare last 10 days avg vs first 10 days avg)
   - `energyTrend`: same pattern
   - `habitConsistencyRate`: percentage of habit completions vs expected
   - `taskCompletionRate`: percentage of tasks completed vs added
   - `bestDayOfWeek`: day name with highest average mood
   - `worstDayOfWeek`: day name with lowest average mood
   - `longestStreak`: max consecutive logging days
   - `currentStreak`: current consecutive logging days
   - `lowMoodDays`: array of dates where mood <= 2
   - `highEnergyDays`: array of dates where energy >= 4

4. Build the Gemini prompt:

```
You are Lumina, a wise AI life mentor. Analyze this person's 30-day data summary and generate exactly 5 distinct, deeply personalized insights. Each insight must be specific to their actual numbers — never generic.

30-Day Summary for [display_name]:
- Average Mood: [avgMood]/5 (Trend: [moodTrend])
- Average Energy: [avgEnergy]/5 (Trend: [energyTrend])
- Habit Consistency: [habitConsistencyRate]%
- Task Completion Rate: [taskCompletionRate]%
- Best Day: [bestDayOfWeek] | Worst Day: [worstDayOfWeek]
- Current Streak: [currentStreak] days
- Longest Streak Ever: [longestStreak] days
- Low Mood Days This Month: [count]
- High Energy Days: [count]

Generate exactly 5 insights as a JSON array. Each insight must have:
- "insight_type": one of ["pattern", "strength", "behavioral_observation", "gentle_challenge", "momentum"]
- "headline": max 10 words, specific and striking
- "body": 2-3 sentences, specific to their numbers, warm but direct tone
- "priority": 1-5 (1 = most important to show first)

Rules:
- Never use generic phrases like "Great job!" or "Keep it up!"
- Every insight must reference actual numbers or patterns from the data
- Vary the insight types — do not repeat the same type
- Tone: warm, wise, direct — like a trusted mentor, not a cheerleader
- Return ONLY the JSON array. No markdown. No explanation.
```

5. Parse the Gemini JSON response safely. Validate each insight has all required fields.

6. Before inserting, delete any existing `pattern` type insights older than 24 hours for this device_id (avoid stale duplicates).

7. Insert all 5 insights into `mentor_insights`:
```typescript
{
  device_id,
  insight_type: insight.insight_type,
  headline: insight.headline,
  body: insight.body,
  metadata: { priority: insight.priority, source: "pattern_mining_agent", generated_by: "gemini" },
  is_dismissed: false,
  generated_at: new Date().toISOString(),
  expires_at: // 48 hours from now
}
```

8. Return `{ success: true, insightsGenerated: 5, deviceId: device_id }`.

### Error Handling
- If Gemini fails or returns invalid JSON, use 3 pre-written fallback insights stored as a constant in the function
- Log all errors with `console.error` including device_id for debugging
- Never let one user's failure block the batch — wrap each user in try/catch

### Cron Setup
After deploying, add this SQL to Supabase SQL Editor to schedule it:
```sql
SELECT cron.schedule(
  'nightly-pattern-mining',
  '0 18 * * *',  -- 18:00 UTC = 11:30 PM IST
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

## AGENT 2 — `weekly-debrief-agent`

### Purpose
Every Sunday evening, auto-generate a structured weekly report card for each user — scored across 5 dimensions — and store it as a special mentor insight. Triggers a push notification.

### Schedule
Run every **Sunday at 7:00 PM IST (13:30 UTC)** via pg_cron.

### Edge Function Logic (`supabase/functions/weekly-debrief-agent/index.ts`)

1. Accept POST with optional `{ device_id: string }`. Batch all users if no device_id provided.

2. For each user, fetch the last 7 days of data (Mon–Sun of current week):
   - All `daily_logs` entries for the week
   - All `habit_completions` for the week
   - All `tasks` for the week (completed vs total)
   - Count of days logged (for self-awareness score)

3. Compute 5 dimension scores locally in TypeScript (each scored 0–100):

```typescript
const moodScore = (avgMood / 5) * 100;
const energyScore = (avgEnergy / 5) * 100;
const consistencyScore = (habitCompletionRate) * 100;
const focusScore = (taskCompletionRate) * 100;
const selfAwarenessScore = (daysLogged / 7) * 100;
const overallScore = Math.round((moodScore + energyScore + consistencyScore + focusScore + selfAwarenessScore) / 5);
```

4. Identify:
   - `biggestWin`: the dimension with the highest score
   - `biggestLeak`: the dimension with the lowest score
   - `weekSummaryLabel`: "Strong Week" (overall > 75) | "Solid Progress" (50-75) | "Challenging Week" (25-50) | "Recovery Week" (< 25)

5. Call Gemini with this prompt:

```
You are Lumina, an AI life mentor generating a weekly debrief for [display_name].

Week Scores (0-100):
- Mood: [moodScore]
- Energy: [energyScore]  
- Habit Consistency: [consistencyScore]
- Focus (Task Completion): [focusScore]
- Self-Awareness (Days Logged): [selfAwarenessScore]
- Overall: [overallScore]
- Week Label: [weekSummaryLabel]

Biggest Win: [biggestWin dimension name]
Biggest Leak: [biggestLeak dimension name]

Generate a weekly debrief with this exact JSON structure:
{
  "openingLine": "1 sentence that captures the essence of their week — specific, honest, not generic",
  "biggestWinInsight": "2 sentences about their biggest win — what it means for them",
  "biggestLeakInsight": "2 sentences about their biggest leak — honest but compassionate, not harsh",
  "nextWeekPriorityStack": ["Priority 1 (most important)", "Priority 2", "Priority 3"],
  "closingChallenge": "1 sentence: one specific micro-challenge for next week based on their leak"
}

Rules:
- Reference actual scores and numbers
- Tone: direct mentor, not a motivational poster
- nextWeekPriorityStack must be actionable and specific (not "improve mood" — instead "protect 8 hours of sleep on weeknights")
- Return ONLY the JSON object. No markdown.
```

6. Store in `mentor_insights`:
```typescript
{
  device_id,
  insight_type: "weekly_debrief",
  headline: `Week of [Mon date] — [weekSummaryLabel] (${overallScore}/100)`,
  body: debrief.openingLine,
  metadata: {
    scores: { mood: moodScore, energy: energyScore, consistency: consistencyScore, focus: focusScore, selfAwareness: selfAwarenessScore, overall: overallScore },
    biggestWin: biggestWin,
    biggestLeak: biggestLeak,
    biggestWinInsight: debrief.biggestWinInsight,
    biggestLeakInsight: debrief.biggestLeakInsight,
    nextWeekPriorityStack: debrief.nextWeekPriorityStack,
    closingChallenge: debrief.closingChallenge,
    weekLabel: weekSummaryLabel,
    source: "weekly_debrief_agent"
  },
  expires_at: // 14 days from now
}
```

7. Send FCM push notification:
```typescript
await sendFCMNotification({
  deviceToken: profile.fcm_token,
  title: "Your Weekly Debrief is Ready 📊",
  body: `${weekSummaryLabel} — Overall score: ${overallScore}/100. Tap to see your full breakdown.`,
  data: { screen: "mentor", insight_type: "weekly_debrief" }
});
```

8. Add `fcm_token TEXT` column to `profiles` table if not already present:
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
```

### Cron Setup
```sql
SELECT cron.schedule(
  'weekly-debrief-sunday',
  '30 13 * * 0',  -- 13:30 UTC Sunday = 7 PM IST Sunday
  $$
  SELECT net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/weekly-debrief-agent',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

---

## AGENT 3 — `burnout-interception-agent`

### Purpose
Triggered (not scheduled) whenever a daily log is saved. Checks burnout signals and if threshold is crossed: generates an urgent mentor card, sends a push notification, and automatically reduces tomorrow's task load.

### Trigger
Called from the existing `sync-daily-log` edge function at the end of its execution — add a fetch call to this function after successful log save.

### Edge Function Logic (`supabase/functions/burnout-interception-agent/index.ts`)

1. Accept POST: `{ device_id: string, log_date: string }`.

2. Fetch the last 7 days of `daily_logs` for this device_id.

3. Compute burnout signals:
```typescript
const last3Moods = logs.slice(-3).map(l => l.mood);
const last3Energies = logs.slice(-3).map(l => l.energy);
const consecutiveLowMood = last3Moods.every(m => m !== null && m <= 2);
const consecutiveLowEnergy = last3Energies.every(e => e !== null && e <= 2);

// Habit dropout: less than 30% completion rate this week
const thisWeekHabitRate = await getThisWeekHabitCompletionRate(device_id);
const habitDropout = thisWeekHabitRate < 0.30;

// Task abandonment: less than 25% task completion rate this week
const taskCompletionRate = await getThisWeekTaskCompletionRate(device_id);
const taskAbandonment = taskCompletionRate < 0.25;

// Compute burnout score
let burnoutScore = 0;
if (consecutiveLowMood) burnoutScore += 35;
if (consecutiveLowEnergy) burnoutScore += 30;
if (habitDropout) burnoutScore += 20;
if (taskAbandonment) burnoutScore += 15;
```

4. **If burnoutScore < 50**: Return `{ triggered: false }`. Do nothing.

5. **If burnoutScore >= 50**: Activate the interception:

**Step A — Check if already triggered recently:**
Check if a `burnout_warning` insight was inserted in the last 48 hours for this device. If yes, return `{ triggered: false, reason: "already_active" }` — don't spam the user.

**Step B — Generate intervention via Gemini:**
```
You are Lumina, an AI mentor detecting early burnout signals for [display_name].

Burnout Signals Detected:
- Consecutive low mood days: [consecutiveLowMood]
- Consecutive low energy days: [consecutiveLowEnergy]
- Habit completion this week: [thisWeekHabitRate * 100]%
- Task completion this week: [taskCompletionRate * 100]%
- Burnout Risk Score: [burnoutScore]/100

Generate a compassionate, direct intervention response as JSON:
{
  "headline": "max 8 words — honest, not alarming",
  "body": "3 sentences — acknowledge what's happening, validate it, offer one specific immediate action",
  "immediateAction": "1 specific action for TODAY (max 15 words)",
  "recoveryHabit": "1 gentle habit to add for this week (max 10 words)"
}

Rules:
- Do NOT be alarming or clinical
- Do NOT say "burnout" directly — say "running low", "depleted", "overextended"
- Be human, warm, specific
- The immediate action must be something they can do in the next hour
- Return ONLY the JSON object
```

**Step C — Store burnout warning insight:**
```typescript
{
  device_id,
  insight_type: "burnout_warning",
  headline: intervention.headline,
  body: intervention.body,
  metadata: {
    burnoutScore,
    signals: { consecutiveLowMood, consecutiveLowEnergy, habitDropout, taskAbandonment },
    immediateAction: intervention.immediateAction,
    recoveryHabit: intervention.recoveryHabit,
    source: "burnout_interception_agent"
  },
  expires_at: // 72 hours from now
}
```

**Step D — Auto-reduce tomorrow's task load:**
Fetch tomorrow's tasks for this device_id from the `tasks` table. If there are tasks with `priority = 'low'`, update their `sort_order` to push them to the bottom and add a `deferred_by_agent` flag in a JSONB metadata column. Add `metadata JSONB DEFAULT '{}'` column to tasks if not present:
```sql
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
```
Then update:
```typescript
// Mark low priority tasks as deferred
await supabase
  .from('tasks')
  .update({ metadata: { deferred_by_agent: true, deferred_reason: "burnout_protection", deferred_at: new Date().toISOString() } })
  .eq('device_id', device_id)
  .eq('log_date', tomorrow)
  .eq('priority', 'low');
```

**Step E — Send FCM push notification:**
```typescript
await sendFCMNotification({
  deviceToken: profile.fcm_token,
  title: intervention.headline,
  body: intervention.immediateAction,
  data: { screen: "mentor", insight_type: "burnout_warning", urgent: "true" }
});
```

6. Return `{ triggered: true, burnoutScore, insightId }`.

### Update `sync-daily-log` to call this agent:
At the end of the existing `sync-daily-log` function, after successful save, add:
```typescript
// Fire burnout interception check (non-blocking)
fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/burnout-interception-agent`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`
  },
  body: JSON.stringify({ device_id, log_date })
}).catch(err => console.error('Burnout agent call failed:', err));
// Do NOT await — fire and forget
```

---

## AGENT 4 — `morning-brief-agent`

### Purpose
Every morning at 8:00 AM IST, generate a 3-line personalized morning brief for each user and send it as a push notification. Brief references their actual historical patterns.

### Schedule
Run every day at **2:30 UTC (8:00 AM IST)** via pg_cron.

### Edge Function Logic (`supabase/functions/morning-brief-agent/index.ts`)

1. Accept POST with optional `{ device_id: string }`. Batch all users if not provided.

2. For each user, fetch:
   - Last 30 days of `daily_logs`
   - Today's `tasks` (already added for today, if any)
   - Current streak (count consecutive days with a log entry, working backwards from yesterday)
   - Day of week averages: compute average mood per day of week over last 30 days
   - Today's day of week (e.g., "Tuesday")

3. Build the brief locally (no Gemini needed here — deterministic logic):

```typescript
const todayDayName = getDayName(new Date()); // e.g., "Tuesday"
const todayDayAvgMood = dayOfWeekAverages[todayDayName]; // computed from 30 days
const peakEnergyHour = "morning"; // simplified — always morning for now
const tasksToday = todaysTasks.length;
const streakDays = currentStreak;

// Line 1: Energy/productivity insight based on time patterns
const line1 = avgMood30Days >= 3.5
  ? `Your energy tends to peak in the ${peakEnergyHour} — a good time for your hardest task.`
  : `Energy has been low lately. Start with one small win today.`;

// Line 2: Day-of-week pattern warning
const line2 = todayDayAvgMood < 3.0
  ? `Heads up: ${todayDayName}s are historically your lowest mood day. Plan lighter if you can.`
  : `${todayDayName}s tend to be good days for you. Make it count.`;

// Line 3: Streak awareness
const line3 = streakDays >= 3
  ? `🔥 ${streakDays}-day streak — don't let it break today. Log before 10 PM.`
  : streakDays === 0
  ? `Start fresh today. Log anything — even one line counts.`
  : `Day ${streakDays} of your streak. Keep going.`;

// Today's focus task (first incomplete high-priority task)
const focusTask = todaysTasks.find(t => !t.is_completed && t.priority === 'high');
```

4. Store as a `morning_brief` type insight in `mentor_insights`:
```typescript
{
  device_id,
  insight_type: "morning_brief",
  headline: `Good morning, [name] ☀️`,
  body: `${line1}\n${line2}\n${line3}`,
  metadata: {
    line1, line2, line3,
    focusTask: focusTask?.title || null,
    streakDays,
    todayDayAvgMood,
    source: "morning_brief_agent"
  },
  expires_at: // 20 hours from now (expires before next brief)
}
```

5. Send FCM push notification:
```typescript
await sendFCMNotification({
  deviceToken: profile.fcm_token,
  title: `Good morning, ${displayName} ☀️`,
  body: focusTask
    ? `Today's focus: "${focusTask.title}" — ${line2}`
    : line2,
  data: { screen: "dashboard", insight_type: "morning_brief" }
});
```

6. **Do NOT call Gemini.** This function must be fast and cheap — it runs for every user every day.

### Cron Setup
```sql
SELECT cron.schedule(
  'morning-brief-daily',
  '30 2 * * *',  -- 2:30 UTC = 8:00 AM IST
  $$
  SELECT net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/morning-brief-agent',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

---

## AGENT 5 — `goal-decomposition-agent`

### Purpose
A one-shot agent. The user states a goal once ("Run a 5K in 60 days"). The agent decomposes it into a phased milestone plan and automatically creates daily/weekly tasks in the `tasks` table for the next N weeks.

### Trigger
Called directly from Flutter when the user submits a goal.

### New Database Table
Create this table first:
```sql
CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  target_date DATE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned', 'paused')),
  health_score INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS goal_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID REFERENCES goals(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  week_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  target_date DATE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add goal_id column to tasks table for linking
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS goal_id UUID REFERENCES goals(id) ON DELETE SET NULL;
```

### Edge Function Logic (`supabase/functions/goal-decomposition-agent/index.ts`)

1. Accept POST:
```typescript
{
  device_id: string,
  goalTitle: string,        // e.g., "Run a 5K in 60 days"
  targetDate: string,       // ISO date
  context?: string          // optional user context: "I'm a beginner, currently sedentary"
}
```

2. Compute the number of weeks between today and `targetDate`. Max 16 weeks. Min 1 week.

3. Fetch user context for personalization:
   - Last 14 days of `daily_logs` (avgEnergy, avgMood)
   - Existing `habits` (to know what they already do)

4. Call Gemini with this prompt:

```
You are Lumina, an AI life mentor. A user has set a goal and you must create a complete, phased action plan for them.

Goal: "[goalTitle]"
Target Date: [targetDate] ([weeksAvailable] weeks away)
User Context: [context or "Not provided"]
User's Current Energy Level (avg): [avgEnergy]/5
User's Existing Habits: [habitNames list or "None tracked"]

Create a week-by-week milestone plan and specific daily tasks. Return ONLY this JSON structure:

{
  "goalSummary": "1 sentence describing how you'll approach this goal for this specific person",
  "phases": [
    {
      "phaseNumber": 1,
      "phaseTitle": "Phase name (e.g., Foundation)",
      "weeksSpan": "Weeks 1-2",
      "phaseGoal": "1 sentence goal for this phase"
    }
  ],
  "weeklyMilestones": [
    {
      "weekNumber": 1,
      "milestoneTitle": "Short milestone name",
      "description": "What success looks like this week",
      "targetDate": "ISO date of end of this week"
    }
  ],
  "dailyTasksByWeek": [
    {
      "weekNumber": 1,
      "tasks": [
        {
          "title": "Task title (max 60 chars)",
          "priority": "high | normal | low",
          "dayOffset": 0
        }
      ]
    }
  ],
  "adjustmentTriggers": {
    "fallingBehindSignal": "What metric indicates the user is falling behind",
    "accelerationSignal": "What metric indicates they can push harder"
  }
}

Rules:
- Make tasks SPECIFIC and ACHIEVABLE — not "exercise more" but "Walk 20 minutes after dinner"
- Max 2 tasks per day from this goal (don't overwhelm)
- dailyTasksByWeek: include 3-4 representative tasks per week (not all 14 days — just the pattern)
- Phases should be 2-3 phases total regardless of goal length
- Tasks should progress in difficulty across weeks
- Consider the user's energy level — if low energy, start very light in week 1
- Return ONLY the JSON. No markdown. No explanation.
```

5. Parse and validate the Gemini response.

6. Create the goal record:
```typescript
const { data: goal } = await supabase
  .from('goals')
  .insert({ device_id, title: goalTitle, description: decomposition.goalSummary, target_date: targetDate })
  .select().single();
```

7. Create all weekly milestones from `weeklyMilestones`:
```typescript
await supabase.from('goal_milestones').insert(
  decomposition.weeklyMilestones.map(m => ({
    goal_id: goal.id,
    device_id,
    week_number: m.weekNumber,
    title: m.milestoneTitle,
    description: m.description,
    target_date: m.targetDate
  }))
);
```

8. Create tasks for the first 2 weeks only (don't create tasks 8 weeks in advance — feels overwhelming):
```typescript
// For each task in weeks 1 and 2, compute actual log_date and insert into tasks
const today = new Date();
for (const weekPlan of decomposition.dailyTasksByWeek.filter(w => w.weekNumber <= 2)) {
  for (const task of weekPlan.tasks) {
    const taskDate = new Date(today);
    taskDate.setDate(today.getDate() + ((weekPlan.weekNumber - 1) * 7) + task.dayOffset);
    
    await supabase.from('tasks').insert({
      device_id,
      log_date: taskDate.toISOString().split('T')[0],
      title: task.title,
      priority: task.priority,
      goal_id: goal.id,
      is_completed: false
    });
  }
}
```

9. Store a mentor insight about the goal:
```typescript
{
  device_id,
  insight_type: "goal_created",
  headline: `New Goal: ${goalTitle}`,
  body: decomposition.goalSummary,
  metadata: {
    goalId: goal.id,
    targetDate,
    weeksAvailable,
    phases: decomposition.phases,
    adjustmentTriggers: decomposition.adjustmentTriggers,
    source: "goal_decomposition_agent"
  },
  expires_at: null // never expires
}
```

10. Return:
```typescript
{
  success: true,
  goalId: goal.id,
  milestonesCreated: weeklyMilestones.length,
  tasksCreated: count,
  goalSummary: decomposition.goalSummary,
  phases: decomposition.phases
}
```

---

## Shared Utility — FCM Notification Helper

Create a shared utility file at `supabase/functions/_shared/fcm.ts` used by all agents that send notifications:

```typescript
export async function sendFCMNotification({
  deviceToken,
  title,
  body,
  data = {}
}: {
  deviceToken: string | null,
  title: string,
  body: string,
  data?: Record<string, string>
}): Promise<void> {
  if (!deviceToken) {
    console.log('No FCM token for device — skipping push notification');
    return;
  }

  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');
  if (!fcmServerKey) {
    console.error('FCM_SERVER_KEY not set');
    return;
  }

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${fcmServerKey}`
    },
    body: JSON.stringify({
      to: deviceToken,
      notification: { title, body, sound: 'default' },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      priority: 'high'
    })
  });

  if (!response.ok) {
    console.error('FCM send failed:', await response.text());
  }
}
```

---

## Flutter Integration (2 Agents Require Active Flutter Changes)

### Flutter Change 1 — Goal Decomposition UI

Add a **"Set a Goal" entry point** on the Dashboard screen:

- A banner card below the Today's Focus section (only shown if no active goal exists)
- Text: "Set a big goal — your AI mentor will break it down" in `bodyMedium`
- A CTA button: "Set a Goal →" (amber, full-width)

Tapping opens a `showModalBottomSheet`:
- Drag handle
- Title: "What do you want to achieve?" in `headingMedium`
- A large `TextField`: placeholder "e.g., Run a 5K in 60 days, Ship my app in 30 days..." — multiline, 3 lines
- Date picker row: "Target Date:" label + a date chip (tapping opens `showDatePicker`)
- Optional context field: "Any context? (optional)" — single line, placeholder "e.g., I'm a complete beginner"
- Submit button: "Let Lumina Plan This →" — `LuminaButton`

On submit:
1. Show a loading overlay with animated text cycling through:
   - "Analyzing your goal..."
   - "Building your phase plan..."
   - "Creating your first week's tasks..."
   - Each line appears with a 1.5 second delay using a timer
2. Call `goal-decomposition-agent` edge function
3. On success: dismiss the sheet, show a success card on the dashboard: "Goal set! Your first tasks are ready." with the goal's `goalSummary` text
4. Refresh the task list — the goal's first week tasks now appear in Today's Focus

Create `GoalRepository` and `GoalNotifier` (Riverpod) to manage goal state:
- `setGoal(title, targetDate, context)` → calls edge function
- `getActiveGoal()` → fetches from Supabase `goals` table
- `getGoalMilestones(goalId)` → fetches milestones

Add a **Goal Progress card** to the Insights screen (after the habit heatmap):
- Shows active goal title
- A progress bar: weeks elapsed / total weeks
- Current week's milestone title
- A "On Track / Behind / Ahead" status badge (compare task completion rate for goal tasks vs expected)

### Flutter Change 2 — FCM Token Registration

In `main.dart` (or a `NotificationService`), after app startup:

1. Initialize Firebase (`firebase_core`, `firebase_messaging` packages)
2. Request notification permission
3. Get FCM token: `String? token = await FirebaseMessaging.instance.getToken()`
4. Save token to Supabase `profiles` table:
```dart
await Supabase.instance.client
  .from('profiles')
  .update({'fcm_token': token})
  .eq('device_id', deviceId);
```
5. Listen for foreground notifications and show an in-app banner (build a `NotificationBanner` widget that slides in from the top, stays for 4 seconds, then slides out)
6. Handle notification tap: read `data['screen']` and navigate to the correct screen using GoRouter

### Flutter Change 3 — Burnout Warning Display

In the Mentor screen's insight feed, give `burnout_warning` type insights a **special visual treatment**:
- Left accent bar: rose/red color (`errorColor`) instead of the standard amber
- A small pulsing red dot next to the "Mentor Insight" label
- The `immediateAction` from metadata displayed in a highlighted box below the body text: amber background at 15% opacity, `bodyMedium` bold text
- A "Done — feeling better" dismiss button that marks it dismissed

In the Dashboard, if there is an active undismissed `burnout_warning` insight, show a **subtle top banner** (below the greeting header, above the snapshot row):
- Rose-tinted background (errorColor at 8% opacity)
- Text: "Your mentor has flagged something important →"
- Tapping navigates to Mentor screen

---

## Deployment Instructions

After writing all 5 edge functions, deploy with:

```bash
supabase functions deploy pattern-mining-agent
supabase functions deploy weekly-debrief-agent
supabase functions deploy burnout-interception-agent
supabase functions deploy morning-brief-agent
supabase functions deploy goal-decomposition-agent
```

Then run all SQL statements (table creation, cron jobs) in the Supabase SQL Editor.

Set these secrets in Supabase Dashboard → Edge Functions → Secrets (if not already set):
- `GEMINI_API_KEY`
- `FCM_SERVER_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

---

## Final Quality Checks

Before considering this complete:

1. Test `pattern-mining-agent` by calling it manually with a device_id — verify 5 insights appear in `mentor_insights`
2. Test `burnout-interception-agent` by manually setting 3 days of mood=1 in `daily_logs` and calling the function — verify it triggers
3. Test `goal-decomposition-agent` with the goal "Read 12 books in 3 months" — verify goal, milestones, and tasks are created
4. Test `morning-brief-agent` manually — verify push notification sends (or logs the token if FCM not configured)
5. Test `weekly-debrief-agent` manually — verify scores compute correctly and Gemini response is parsed
6. In Flutter: test goal creation flow end-to-end — sheet opens → submit → loading animation → goal card appears → tasks in dashboard
7. In Flutter: test FCM token saves to Supabase on first launch
8. In Flutter: burnout banner appears on dashboard when burnout_warning insight exists
