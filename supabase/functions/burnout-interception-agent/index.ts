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
  isServiceRoleRequest,
  percentage,
  profileName,
} from "../_shared/agent_utils.ts";

function iso(date: Date): string {
  return date.toISOString().slice(0, 10);
}

async function weeklyHabitRate(supabase: any, deviceId: string, since: string): Promise<number> {
  const [{ data: habits }, { data: completions }] = await Promise.all([
    supabase.from("habits").select("id").eq("device_id", deviceId).eq("is_active", true),
    supabase.from("habit_completions").select("id").eq("device_id", deviceId).gte("completion_date", since),
  ]);
  const expected = (habits?.length ?? 0) * 7;
  return expected === 0 ? 0 : (completions?.length ?? 0) / expected;
}

async function weeklyTaskRate(supabase: any, deviceId: string, since: string): Promise<number> {
  const { data } = await supabase.from("tasks")
    .select("is_completed")
    .eq("device_id", deviceId)
    .gte("log_date", since);
  if (!data?.length) {
    return 0;
  }
  return data.filter((task: any) => task.is_completed === true).length / data.length;
}

function fallbackIntervention(score: number) {
  return {
    headline: "You are running low",
    body:
      `Your recent signals add up to a ${score}/100 risk score, which is enough to protect your energy today. This is not a failure signal; it is your system asking for a smaller load. Take one immediate reset before choosing the next task.`,
    immediateAction: "Step away for ten quiet minutes.",
    recoveryHabit: "One early night",
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!isServiceRoleRequest(req)) {
      return jsonResponse({ error: "Service role authorization is required" }, 401);
    }

    const payload = asRecord(await req.json().catch(() => ({}))) ?? {};
    const deviceId = asString(payload.device_id ?? payload.deviceId);
    const logDate = asString(payload.log_date ?? payload.logDate) ?? iso(new Date());
    if (!deviceId) {
      return jsonResponse({ error: "device_id is required" }, 400);
    }

    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({ error: "Supabase service role is not configured" }, 500);
    }

    const since = iso(addDays(new Date(), -6));
    const [{ data: logs, error: logsError }, { data: profile }] = await Promise.all([
      supabase.from("daily_logs")
        .select("log_date, mood, energy")
        .eq("device_id", deviceId)
        .gte("log_date", since)
        .order("log_date", { ascending: true }),
      supabase.from("profiles")
        .select("device_id, display_name, fcm_token")
        .eq("device_id", deviceId)
        .maybeSingle(),
    ]);
    if (logsError) {
      throw new Error(logsError.message);
    }

    const last3 = (logs ?? []).slice(-3);
    const last3Moods = last3.map((log: any) => log.mood);
    const last3Energies = last3.map((log: any) => log.energy);
    const consecutiveLowMood = last3.length >= 3 && last3Moods.every((mood: number | null) => mood != null && mood <= 2);
    const consecutiveLowEnergy = last3.length >= 3 && last3Energies.every((energy: number | null) => energy != null && energy <= 2);
    const thisWeekHabitRate = await weeklyHabitRate(supabase, deviceId, since);
    const taskCompletionRate = await weeklyTaskRate(supabase, deviceId, since);
    const habitDropout = thisWeekHabitRate < 0.30;
    const taskAbandonment = taskCompletionRate < 0.25;

    let burnoutScore = 0;
    if (consecutiveLowMood) burnoutScore += 35;
    if (consecutiveLowEnergy) burnoutScore += 30;
    if (habitDropout) burnoutScore += 20;
    if (taskAbandonment) burnoutScore += 15;

    if (burnoutScore < 50) {
      return jsonResponse({ triggered: false, burnoutScore });
    }

    const cutoff = addHours(new Date(), -48).toISOString();
    const { data: recent } = await supabase.from("mentor_insights")
      .select("id")
      .eq("device_id", deviceId)
      .eq("insight_type", "burnout_warning")
      .gte("generated_at", cutoff)
      .limit(1);
    if (recent?.length) {
      return jsonResponse({ triggered: false, reason: "already_active", burnoutScore });
    }

    const fallback = fallbackIntervention(burnoutScore);
    const prompt = `You are Lumina, an AI mentor detecting early burnout signals for ${profileName(profile ?? { device_id: deviceId })}.

Burnout Signals Detected:
- Consecutive low mood days: ${consecutiveLowMood}
- Consecutive low energy days: ${consecutiveLowEnergy}
- Habit completion this week: ${percentage(thisWeekHabitRate)}%
- Task completion this week: ${percentage(taskCompletionRate)}%
- Burnout Risk Score: ${burnoutScore}/100

Generate a compassionate, direct intervention response as JSON:
{
  "headline": "max 8 words - honest, not alarming",
  "body": "3 sentences - acknowledge what's happening, validate it, offer one specific immediate action",
  "immediateAction": "1 specific action for TODAY (max 15 words)",
  "recoveryHabit": "1 gentle habit to add for this week (max 10 words)"
}

Rules:
- Do NOT be alarming or clinical
- Do NOT say "burnout" directly - say "running low", "depleted", "overextended"
- Be human, warm, specific
- The immediate action must be something they can do in the next hour
- Return ONLY the JSON object`;

    let intervention = fallback;
    try {
      const text = await generateGeminiText(prompt, JSON.stringify(fallback), { maxOutputTokens: 900, temperature: 0.5 });
      const parsed = safeJsonObject(text);
      intervention = {
        headline: asString(parsed.headline) ?? fallback.headline,
        body: asString(parsed.body) ?? fallback.body,
        immediateAction: asString(parsed.immediateAction) ?? fallback.immediateAction,
        recoveryHabit: asString(parsed.recoveryHabit) ?? fallback.recoveryHabit,
      };
    } catch (error) {
      console.error("burnout-interception-agent Gemini parse failed", deviceId, error);
    }

    const { data: insight, error: insertError } = await supabase.from("mentor_insights")
      .insert({
        device_id: deviceId,
        insight_type: "burnout_warning",
        headline: intervention.headline,
        body: intervention.body,
        metadata: {
          burnoutScore,
          signals: { consecutiveLowMood, consecutiveLowEnergy, habitDropout, taskAbandonment },
          immediateAction: intervention.immediateAction,
          recoveryHabit: intervention.recoveryHabit,
          source: "burnout_interception_agent",
          logDate,
        },
        expires_at: addHours(new Date(), 72).toISOString(),
      })
      .select("id")
      .single();
    if (insertError) {
      throw new Error(insertError.message);
    }

    const tomorrow = iso(addDays(new Date(), 1));
    const { data: lowTasks } = await supabase.from("tasks")
      .select("id, metadata")
      .eq("device_id", deviceId)
      .eq("log_date", tomorrow)
      .eq("priority", "low");

    for (const task of lowTasks ?? []) {
      await supabase.from("tasks").update({
        sort_order: 999,
        metadata: {
          ...(task.metadata ?? {}),
          deferred_by_agent: true,
          deferred_reason: "burnout_protection",
          deferred_at: new Date().toISOString(),
        },
      }).eq("id", task.id);
    }

    await sendFCMNotification({
      deviceToken: profile?.fcm_token,
      title: intervention.headline,
      body: intervention.immediateAction,
      data: { screen: "mentor", insight_type: "burnout_warning", urgent: "true" },
    });

    return jsonResponse({ triggered: true, burnoutScore, insightId: insight?.id });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
