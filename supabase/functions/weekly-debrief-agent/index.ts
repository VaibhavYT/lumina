import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFCMNotification } from "../_shared/fcm.ts";
import { generateGeminiText, safeJsonObject } from "../_shared/gemini.ts";
import { adminClient } from "../_shared/supabase.ts";
import {
  addDays,
  addHours,
  asRecord,
  asString,
  average,
  errorMessage,
  percentage,
  ProfileRow,
  profileName,
  round,
  targetProfiles,
} from "../_shared/agent_utils.ts";

function weekStart(date = new Date()): Date {
  const copy = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const diff = copy.getUTCDay() === 0 ? -6 : 1 - copy.getUTCDay();
  copy.setUTCDate(copy.getUTCDate() + diff);
  return copy;
}

function iso(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function weekLabel(overallScore: number): string {
  if (overallScore > 75) {
    return "Strong Week";
  }
  if (overallScore >= 50) {
    return "Solid Progress";
  }
  if (overallScore >= 25) {
    return "Challenging Week";
  }
  return "Recovery Week";
}

function fallbackDebrief(label: string, biggestWin: string, biggestLeak: string) {
  return {
    openingLine: `${label}: the week has a clear signal around ${biggestWin} and ${biggestLeak}.`,
    biggestWinInsight:
      `${biggestWin} was the strongest part of the week. Protect the conditions that made it possible before adding more pressure.`,
    biggestLeakInsight:
      `${biggestLeak} needs a lighter system, not harsher self-talk. Reduce friction first, then rebuild consistency.`,
    nextWeekPriorityStack: [
      `Protect the strongest ${biggestWin.toLowerCase()} routine`,
      `Make ${biggestLeak.toLowerCase()} one step smaller`,
      "Review the week before Sunday night",
    ],
    closingChallenge:
      `Choose one small daily action that repairs ${biggestLeak.toLowerCase()} next week.`,
  };
}

async function runForProfile(supabase: any, profile: ProfileRow) {
  const monday = weekStart();
  const sunday = addDays(monday, 6);
  const start = iso(monday);
  const end = iso(sunday);

  const [
    { data: logs, error: logsError },
    { data: tasks, error: tasksError },
    { data: habits },
    { data: completions },
  ] = await Promise.all([
    supabase.from("daily_logs").select("log_date, mood, energy").eq("device_id", profile.device_id).gte("log_date", start).lte("log_date", end),
    supabase.from("tasks").select("is_completed").eq("device_id", profile.device_id).gte("log_date", start).lte("log_date", end),
    supabase.from("habits").select("id").eq("device_id", profile.device_id).eq("is_active", true),
    supabase.from("habit_completions").select("id").eq("device_id", profile.device_id).gte("completion_date", start).lte("completion_date", end),
  ]);
  if (logsError) {
    throw new Error(logsError.message);
  }
  if (tasksError) {
    throw new Error(tasksError.message);
  }

  const avgMood = average((logs ?? []).map((item: any) => item.mood ?? 0).filter((value: number) => value > 0));
  const avgEnergy = average((logs ?? []).map((item: any) => item.energy ?? 0).filter((value: number) => value > 0));
  const moodScore = percentage(avgMood / 5);
  const energyScore = percentage(avgEnergy / 5);
  const expectedHabits = (habits?.length ?? 0) * 7;
  const consistencyScore = expectedHabits === 0 ? 0 : percentage((completions?.length ?? 0) / expectedHabits);
  const completedTasks = (tasks ?? []).filter((task: any) => task.is_completed === true).length;
  const focusScore = tasks?.length ? percentage(completedTasks / tasks.length) : 0;
  const selfAwarenessScore = percentage((logs?.length ?? 0) / 7);
  const overallScore = Math.round((moodScore + energyScore + consistencyScore + focusScore + selfAwarenessScore) / 5);

  const dimensions = [
    { name: "Mood", score: moodScore },
    { name: "Energy", score: energyScore },
    { name: "Habit Consistency", score: consistencyScore },
    { name: "Focus", score: focusScore },
    { name: "Self-Awareness", score: selfAwarenessScore },
  ].sort((a, b) => b.score - a.score);
  const biggestWin = dimensions[0].name;
  const biggestLeak = dimensions.at(-1)?.name ?? "Focus";
  const label = weekLabel(overallScore);
  const fallback = fallbackDebrief(label, biggestWin, biggestLeak);

  const prompt = `You are Lumina, an AI life mentor generating a weekly debrief for ${profileName(profile)}.

Week Scores (0-100):
- Mood: ${moodScore}
- Energy: ${energyScore}
- Habit Consistency: ${consistencyScore}
- Focus (Task Completion): ${focusScore}
- Self-Awareness (Days Logged): ${selfAwarenessScore}
- Overall: ${overallScore}
- Week Label: ${label}

Biggest Win: ${biggestWin}
Biggest Leak: ${biggestLeak}

Generate a weekly debrief with this exact JSON structure:
{
  "openingLine": "1 sentence that captures the essence of their week - specific, honest, not generic",
  "biggestWinInsight": "2 sentences about their biggest win - what it means for them",
  "biggestLeakInsight": "2 sentences about their biggest leak - honest but compassionate, not harsh",
  "nextWeekPriorityStack": ["Priority 1 (most important)", "Priority 2", "Priority 3"],
  "closingChallenge": "1 sentence: one specific micro-challenge for next week based on their leak"
}

Rules:
- Reference actual scores and numbers
- Tone: direct mentor, not a motivational poster
- nextWeekPriorityStack must be actionable and specific
- Return ONLY the JSON object. No markdown.`;

  let debrief = fallback;
  try {
    const text = await generateGeminiText(prompt, JSON.stringify(fallback), { maxOutputTokens: 1400, temperature: 0.55 });
    const parsed = safeJsonObject(text);
    debrief = {
      openingLine: asString(parsed.openingLine) ?? fallback.openingLine,
      biggestWinInsight: asString(parsed.biggestWinInsight) ?? fallback.biggestWinInsight,
      biggestLeakInsight: asString(parsed.biggestLeakInsight) ?? fallback.biggestLeakInsight,
      nextWeekPriorityStack: Array.isArray(parsed.nextWeekPriorityStack)
        ? parsed.nextWeekPriorityStack.map(asString).filter(Boolean).slice(0, 3) as string[]
        : fallback.nextWeekPriorityStack,
      closingChallenge: asString(parsed.closingChallenge) ?? fallback.closingChallenge,
    };
  } catch (error) {
    console.error("weekly-debrief-agent Gemini parse failed", profile.device_id, error);
  }

  const { data: inserted, error: insertError } = await supabase.from("mentor_insights").insert({
    device_id: profile.device_id,
    insight_type: "weekly_debrief",
    headline: `Week of ${start} - ${label} (${overallScore}/100)`,
    body: debrief.openingLine,
    metadata: {
      scores: {
        mood: moodScore,
        energy: energyScore,
        consistency: consistencyScore,
        focus: focusScore,
        selfAwareness: selfAwarenessScore,
        overall: overallScore,
      },
      biggestWin,
      biggestLeak,
      biggestWinInsight: debrief.biggestWinInsight,
      biggestLeakInsight: debrief.biggestLeakInsight,
      nextWeekPriorityStack: debrief.nextWeekPriorityStack,
      closingChallenge: debrief.closingChallenge,
      weekLabel: label,
      source: "weekly_debrief_agent",
    },
    expires_at: addHours(new Date(), 24 * 14).toISOString(),
  }).select("id").single();
  if (insertError) {
    throw new Error(insertError.message);
  }

  await sendFCMNotification({
    deviceToken: profile.fcm_token,
    title: "Your Weekly Debrief is Ready",
    body: `${label} - Overall score: ${overallScore}/100. Tap to see your full breakdown.`,
    data: { screen: "mentor", insight_type: "weekly_debrief" },
  });

  return {
    success: true,
    deviceId: profile.device_id,
    insightId: inserted?.id,
    overallScore,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json().catch(() => ({}));
    const record = asRecord(payload);
    const deviceId = asString(record?.device_id ?? record?.deviceId);
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
        console.error("weekly-debrief-agent failed", profile.device_id, error);
        results.push({ success: false, deviceId: profile.device_id, error: errorMessage(error) });
      }
    }
    return jsonResponse(deviceId ? results[0] ?? { success: false } : { success: true, results });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
