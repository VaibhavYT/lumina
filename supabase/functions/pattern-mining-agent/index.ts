import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText, safeJsonArray } from "../_shared/gemini.ts";
import { adminClient } from "../_shared/supabase.ts";
import {
  addDays,
  addHours,
  asRecord,
  asString,
  average,
  dayNameFromDate,
  errorMessage,
  percentage,
  ProfileRow,
  profileName,
  round,
  streaksFromLogDates,
  targetProfiles,
  trendFromValues,
} from "../_shared/agent_utils.ts";

type DailyLogRow = {
  log_date: string;
  mood: number | null;
  energy: number | null;
  notes: string | null;
};

type TaskRow = {
  log_date: string;
  is_completed: boolean | null;
};

type Insight = {
  insight_type: string;
  headline: string;
  body: string;
  priority: number;
};

function fallbackInsights(summary: Summary): Insight[] {
  return [
    {
      insight_type: "pattern",
      headline: `${summary.currentStreak}-day streak signal`,
      body:
        `Your current logging streak is ${summary.currentStreak} days, with a longest streak of ${summary.longestStreak}. Treat the streak as data, not pressure: one honest entry keeps the pattern visible.`,
      priority: 1,
    },
    {
      insight_type: "behavioral_observation",
      headline: `${summary.taskCompletionRate}% task follow-through`,
      body:
        `You completed ${summary.taskCompletionRate}% of the tasks you added in the last 30 days. If the number feels low, shrink tomorrow's list before trying to push harder.`,
      priority: 2,
    },
    {
      insight_type: "momentum",
      headline: `${summary.bestDayOfWeek} carries momentum`,
      body:
        `${summary.bestDayOfWeek} has been your strongest mood day, while ${summary.worstDayOfWeek} asks for more care. Use the stronger day for demanding work and make the weaker day simpler by design.`,
      priority: 3,
    },
  ];
}

type Summary = {
  avgMood: number;
  avgEnergy: number;
  moodTrend: string;
  energyTrend: string;
  habitConsistencyRate: number;
  taskCompletionRate: number;
  bestDayOfWeek: string;
  worstDayOfWeek: string;
  longestStreak: number;
  currentStreak: number;
  lowMoodDays: string[];
  highEnergyDays: string[];
};

function buildSummary(logs: DailyLogRow[], tasks: TaskRow[], habitRate: number): Summary {
  const moodValues = logs.map((item) => item.mood).filter((value): value is number => value != null);
  const energyValues = logs.map((item) => item.energy).filter((value): value is number => value != null);
  const groupedMood = new Map<string, number[]>();

  for (const log of logs) {
    if (log.mood == null) {
      continue;
    }
    const day = dayNameFromDate(log.log_date);
    groupedMood.set(day, [...(groupedMood.get(day) ?? []), log.mood]);
  }

  const dayAverages = [...groupedMood.entries()].map(([day, values]) => ({
    day,
    average: average(values),
  }));
  dayAverages.sort((a, b) => b.average - a.average);

  const completed = tasks.filter((task) => task.is_completed === true).length;
  const taskCompletionRate = tasks.length === 0 ? 0 : percentage(completed / tasks.length);
  const streaks = streaksFromLogDates(logs.map((item) => item.log_date));

  return {
    avgMood: round(average(moodValues)),
    avgEnergy: round(average(energyValues)),
    moodTrend: trendFromValues(moodValues),
    energyTrend: trendFromValues(energyValues),
    habitConsistencyRate: percentage(habitRate),
    taskCompletionRate,
    bestDayOfWeek: dayAverages.at(0)?.day ?? "Unknown",
    worstDayOfWeek: dayAverages.at(-1)?.day ?? "Unknown",
    longestStreak: streaks.longestStreak,
    currentStreak: streaks.currentStreak,
    lowMoodDays: logs.filter((item) => (item.mood ?? 99) <= 2).map((item) => item.log_date),
    highEnergyDays: logs.filter((item) => (item.energy ?? 0) >= 4).map((item) => item.log_date),
  };
}

function validateInsights(value: unknown, fallback: Insight[]): Insight[] {
  const array = Array.isArray(value) ? value : [];
  const insights = array
    .map(asRecord)
    .filter((item): item is Record<string, unknown> => item !== null)
    .map((item, index) => ({
      insight_type: asString(item.insight_type) ?? "pattern",
      headline: (asString(item.headline) ?? fallback[index % fallback.length].headline).slice(0, 80),
      body: asString(item.body) ?? fallback[index % fallback.length].body,
      priority: Math.max(1, Math.min(5, Number(item.priority ?? index + 1))),
    }))
    .filter((item) => item.headline.length > 0 && item.body.length > 0)
    .slice(0, 5);
  return insights.length >= 3 ? insights : fallback;
}

async function habitRateForDevice(supabase: any, deviceId: string, since: string): Promise<number> {
  const [{ data: habits }, { data: completions }] = await Promise.all([
    supabase.from("habits").select("id").eq("device_id", deviceId).eq("is_active", true),
    supabase.from("habit_completions").select("id").eq("device_id", deviceId).gte("completion_date", since),
  ]);
  const expected = (habits?.length ?? 0) * 30;
  if (expected === 0) {
    return 0;
  }
  return (completions?.length ?? 0) / expected;
}

async function runForProfile(supabase: any, profile: ProfileRow) {
  const since = addDays(new Date(), -29).toISOString().slice(0, 10);
  const [{ data: logs, error: logsError }, { data: tasks, error: tasksError }, habitRate] =
    await Promise.all([
      supabase.from("daily_logs")
        .select("log_date, mood, energy, notes")
        .eq("device_id", profile.device_id)
        .gte("log_date", since)
        .order("log_date", { ascending: true }),
      supabase.from("tasks")
        .select("log_date, is_completed")
        .eq("device_id", profile.device_id)
        .gte("log_date", since),
      habitRateForDevice(supabase, profile.device_id, since),
    ]);

  if (logsError) {
    throw new Error(logsError.message);
  }
  if (tasksError) {
    throw new Error(tasksError.message);
  }

  const summary = buildSummary(logs ?? [], tasks ?? [], habitRate);
  const fallback = fallbackInsights(summary);
  const prompt = `You are Lumina, a wise AI life mentor. Analyze this person's 30-day data summary and generate exactly 5 distinct, deeply personalized insights. Each insight must be specific to their actual numbers - never generic.

30-Day Summary for ${profileName(profile)}:
- Average Mood: ${summary.avgMood}/5 (Trend: ${summary.moodTrend})
- Average Energy: ${summary.avgEnergy}/5 (Trend: ${summary.energyTrend})
- Habit Consistency: ${summary.habitConsistencyRate}%
- Task Completion Rate: ${summary.taskCompletionRate}%
- Best Day: ${summary.bestDayOfWeek} | Worst Day: ${summary.worstDayOfWeek}
- Current Streak: ${summary.currentStreak} days
- Longest Streak Ever: ${summary.longestStreak} days
- Low Mood Days This Month: ${summary.lowMoodDays.length}
- High Energy Days: ${summary.highEnergyDays.length}

Generate exactly 5 insights as a JSON array. Each insight must have:
- "insight_type": one of ["pattern", "strength", "behavioral_observation", "gentle_challenge", "momentum"]
- "headline": max 10 words, specific and striking
- "body": 2-3 sentences, specific to their numbers, warm but direct tone
- "priority": 1-5 (1 = most important to show first)

Rules:
- Never use generic phrases like "Great job!" or "Keep it up!"
- Every insight must reference actual numbers or patterns from the data
- Vary the insight types - do not repeat the same type
- Tone: warm, wise, direct - like a trusted mentor, not a cheerleader
- Return ONLY the JSON array. No markdown. No explanation.`;

  let parsed: unknown[] = [];
  try {
    const text = await generateGeminiText(prompt, JSON.stringify(fallback), {
      maxOutputTokens: 1800,
      temperature: 0.55,
    });
    parsed = safeJsonArray(text);
  } catch (error) {
    console.error("pattern-mining-agent Gemini parse failed", profile.device_id, error);
  }

  const insights = validateInsights(parsed, fallback);
  const staleCutoff = addHours(new Date(), -24).toISOString();
  await supabase.from("mentor_insights")
    .delete()
    .eq("device_id", profile.device_id)
    .eq("insight_type", "pattern")
    .lt("generated_at", staleCutoff);

  const expiresAt = addHours(new Date(), 48).toISOString();
  const { error: insertError } = await supabase.from("mentor_insights").insert(
    insights.map((insight) => ({
      device_id: profile.device_id,
      insight_type: insight.insight_type,
      headline: insight.headline,
      body: insight.body,
      metadata: {
        priority: insight.priority,
        source: "pattern_mining_agent",
        generated_by: parsed.length > 0 ? "gemini" : "fallback",
        summary,
      },
      is_dismissed: false,
      generated_at: new Date().toISOString(),
      expires_at: expiresAt,
    })),
  );
  if (insertError) {
    throw new Error(insertError.message);
  }
  return {
    success: true,
    insightsGenerated: insights.length,
    deviceId: profile.device_id,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json().catch(() => ({}));
    const deviceId = asString(asRecord(payload)?.device_id ?? asRecord(payload)?.deviceId);
    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({ error: "Supabase service role is not configured" }, 500);
    }

    const profiles = await targetProfiles(supabase, deviceId);
    const results = [];
    for (const profile of profiles) {
      try {
        results.push(await runForProfile(supabase, profile));
      } catch (error) {
        console.error("pattern-mining-agent failed", profile.device_id, error);
        results.push({ success: false, deviceId: profile.device_id, error: errorMessage(error) });
      }
    }

    return jsonResponse(deviceId ? results[0] ?? { success: false } : { success: true, results });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
