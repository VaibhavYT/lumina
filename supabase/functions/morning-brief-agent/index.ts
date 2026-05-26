import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { sendFCMNotification } from "../_shared/fcm.ts";
import { adminClient } from "../_shared/supabase.ts";
import {
  addDays,
  addHours,
  asRecord,
  asString,
  average,
  dayNameFromDate,
  errorMessage,
  isoDate,
  ProfileRow,
  profileName,
  streaksFromLogDates,
  targetProfiles,
} from "../_shared/agent_utils.ts";

async function runForProfile(supabase: any, profile: ProfileRow) {
  const today = isoDate();
  const since = isoDate(addDays(new Date(), -29));
  const [{ data: logs }, { data: tasks }] = await Promise.all([
    supabase.from("daily_logs")
      .select("log_date, mood, energy")
      .eq("device_id", profile.device_id)
      .gte("log_date", since)
      .order("log_date", { ascending: true }),
    supabase.from("tasks")
      .select("title, priority, is_completed")
      .eq("device_id", profile.device_id)
      .eq("log_date", today)
      .order("sort_order", { ascending: true }),
  ]);

  const avgMood30Days = average((logs ?? []).map((log: any) => log.mood ?? 0).filter((value: number) => value > 0));
  const dayAverages = new Map<string, number[]>();
  for (const log of logs ?? []) {
    if (log.mood == null) {
      continue;
    }
    const day = dayNameFromDate(log.log_date);
    dayAverages.set(day, [...(dayAverages.get(day) ?? []), log.mood]);
  }

  const todayDayName = dayNameFromDate(today);
  const todayDayAvgMood = average(dayAverages.get(todayDayName) ?? []);
  const streak = streaksFromLogDates((logs ?? []).map((log: any) => log.log_date));
  const focusTask = (tasks ?? []).find((task: any) => task.is_completed !== true && task.priority === "high");

  const line1 = avgMood30Days >= 3.5
    ? "Your energy tends to peak in the morning - a good time for your hardest task."
    : "Energy has been low lately. Start with one small win today.";
  const line2 = todayDayAvgMood > 0 && todayDayAvgMood < 3
    ? `Heads up: ${todayDayName}s are historically your lowest mood day. Plan lighter if you can.`
    : `${todayDayName}s tend to be good days for you. Make it count.`;
  const line3 = streak.currentStreak >= 3
    ? `${streak.currentStreak}-day streak - log before 10 PM.`
    : streak.currentStreak === 0
    ? "Start fresh today. Log anything - even one line counts."
    : `Day ${streak.currentStreak} of your streak. Keep going.`;

  const headline = `Good morning, ${profileName(profile)}`;
  const body = `${line1}\n${line2}\n${line3}`;
  const { data: inserted, error: insertError } = await supabase.from("mentor_insights").insert({
    device_id: profile.device_id,
    insight_type: "morning_brief",
    headline,
    body,
    metadata: {
      line1,
      line2,
      line3,
      focusTask: focusTask?.title ?? null,
      streakDays: streak.currentStreak,
      todayDayAvgMood,
      source: "morning_brief_agent",
    },
    expires_at: addHours(new Date(), 20).toISOString(),
  }).select("id").single();
  if (insertError) {
    throw new Error(insertError.message);
  }

  await sendFCMNotification({
    deviceToken: profile.fcm_token,
    title: headline,
    body: focusTask ? `Today's focus: "${focusTask.title}" - ${line2}` : line2,
    data: { screen: "dashboard", insight_type: "morning_brief" },
  });

  return { success: true, deviceId: profile.device_id, insightId: inserted?.id };
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
        console.error("morning-brief-agent failed", profile.device_id, error);
        results.push({ success: false, deviceId: profile.device_id, error: errorMessage(error) });
      }
    }
    return jsonResponse(deviceId ? results[0] ?? { success: false } : { success: true, results });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
