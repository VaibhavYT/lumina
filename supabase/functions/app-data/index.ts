import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { adminClient } from "../_shared/supabase.ts";
import {
  addDays,
  asInteger,
  asRecord,
  asString,
  average,
  errorMessage,
  isoDate,
  resolveDeviceForRequest,
  streaksFromLogDates,
} from "../_shared/agent_utils.ts";

function colorForHabit(index: number): string {
  return ["#F0A500", "#34C97B", "#7B61FF", "#FF8C42", "#E74563"][index % 5];
}

function requestDate(value: unknown): string {
  const raw = asString(value);
  return raw && /^\d{4}-\d{2}-\d{2}$/.test(raw) ? raw : isoDate();
}

async function fetchToday(supabase: any, deviceId: string, todayDate: string) {
  const today = todayDate;
  const [{ data: log }, { data: tasks }, { data: habits }, { data: completions }] = await Promise.all([
    supabase.from("daily_logs").select("*").eq("device_id", deviceId).eq("log_date", today).maybeSingle(),
    supabase.from("tasks").select("*").eq("device_id", deviceId).eq("log_date", today).order("sort_order", { ascending: true }),
    supabase.from("habits").select("*").eq("device_id", deviceId).eq("is_active", true).order("created_at", { ascending: true }),
    supabase.from("habit_completions").select("*").eq("device_id", deviceId).eq("completion_date", today),
  ]);
  const completedHabitIds = new Set(
    (completions ?? []).map((item: any) => item.habit_id ?? item.local_habit_id).filter(Boolean),
  );
  return {
    log,
    tasks: tasks ?? [],
    habits: (habits ?? []).map((habit: any, index: number) => ({
      ...habit,
      color_hex: habit.color_hex ?? colorForHabit(index),
      completed_today:
        completedHabitIds.has(habit.id) ||
        completedHabitIds.has(habit.local_habit_id) ||
        completedHabitIds.has(habit.name),
      target_per_day: 1,
    })),
    completedHabitIds: [...completedHabitIds],
  };
}

async function fetchDashboard(supabase: any, deviceId: string, todayDate: string) {
  const today = await fetchToday(supabase, deviceId, todayDate);
  const since = isoDate(addDays(new Date(), -90));
  const [{ data: logs }, { data: latestInsight }, { data: burnout }] = await Promise.all([
    supabase.from("daily_logs").select("log_date").eq("device_id", deviceId).gte("log_date", since).order("log_date"),
    supabase.from("mentor_insights")
      .select("id, insight_type, headline, body, metadata, generated_at")
      .eq("device_id", deviceId)
      .eq("is_dismissed", false)
      .order("generated_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase.from("mentor_insights")
      .select("id, insight_type, headline, body, metadata, generated_at")
      .eq("device_id", deviceId)
      .eq("is_dismissed", false)
      .eq("insight_type", "burnout_warning")
      .order("generated_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);
  return {
    ...today,
    streak: streaksFromLogDates((logs ?? []).map((item: any) => item.log_date)).currentStreak,
    mentorInsight: latestInsight,
    burnoutWarning: burnout,
  };
}

async function fetchAgents(supabase: any, deviceId: string) {
  const [{ data: insights }, { data: chatMessages }, { data: latestLog }, { data: activeGoal }] = await Promise.all([
    supabase.from("mentor_insights")
      .select("id, insight_type, headline, body, metadata, generated_at")
      .eq("device_id", deviceId)
      .order("generated_at", { ascending: false })
      .limit(80),
    supabase.from("mentor_chat_messages")
      .select("id, role, metadata, created_at")
      .eq("device_id", deviceId)
      .eq("role", "assistant")
      .order("created_at", { ascending: false })
      .limit(1),
    supabase.from("daily_logs")
      .select("log_date, mood, energy, updated_at")
      .eq("device_id", deviceId)
      .order("log_date", { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase.from("goals")
      .select("id, title, created_at, updated_at")
      .eq("device_id", deviceId)
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);

  return {
    serverTime: new Date().toISOString(),
    insights: insights ?? [],
    chatMessages: chatMessages ?? [],
    latestLog,
    activeGoal,
  };
}

async function fetchInsights(supabase: any, deviceId: string, rangeDays: number) {
  const since = isoDate(addDays(new Date(), -(rangeDays - 1)));
  const [{ data: logs }, { data: tasks }, { data: habits }, { data: completions }] = await Promise.all([
    supabase.from("daily_logs").select("log_date, mood, energy, notes").eq("device_id", deviceId).gte("log_date", since).order("log_date"),
    supabase.from("tasks").select("log_date, is_completed").eq("device_id", deviceId).gte("log_date", since),
    supabase.from("habits").select("id").eq("device_id", deviceId).eq("is_active", true),
    supabase.from("habit_completions").select("completion_date").eq("device_id", deviceId).gte("completion_date", since),
  ]);
  const tasksByDate = new Map<string, { added: number; completed: number }>();
  for (const task of tasks ?? []) {
    const entry = tasksByDate.get(task.log_date) ?? { added: 0, completed: 0 };
    entry.added += 1;
    if (task.is_completed === true) {
      entry.completed += 1;
    }
    tasksByDate.set(task.log_date, entry);
  }
  const completionsByDate = new Map<string, number>();
  for (const completion of completions ?? []) {
    completionsByDate.set(completion.completion_date, (completionsByDate.get(completion.completion_date) ?? 0) + 1);
  }
  const activeHabitCount = habits?.length ?? 0;
  const days = (logs ?? []).map((log: any) => {
    const taskStats = tasksByDate.get(log.log_date) ?? { added: 0, completed: 0 };
    return {
      date: log.log_date,
      mood: log.mood,
      energy: log.energy,
      notes: log.notes ?? "",
      tasksAdded: taskStats.added,
      tasksCompleted: taskStats.completed,
      habitRate: activeHabitCount === 0 ? 0 : (completionsByDate.get(log.log_date) ?? 0) / activeHabitCount,
    };
  });
  return { days, triggers: localTriggers(days) };
}

function localTriggers(days: any[]) {
  const words = new Map<string, { count: number; moods: number[] }>();
  const stop = new Set(["the", "and", "for", "with", "that", "this", "today", "very", "from"]);
  for (const day of days) {
    const note = String(day.notes ?? "").toLowerCase();
    for (const word of note.match(/[a-z]{4,}/g) ?? []) {
      if (stop.has(word)) continue;
      const entry = words.get(word) ?? { count: 0, moods: [] };
      entry.count += 1;
      if (typeof day.mood === "number") entry.moods.push(day.mood);
      words.set(word, entry);
    }
  }
  return [...words.entries()]
    .filter(([, value]) => value.count >= 2)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 8)
    .map(([tag, value]) => {
      const mood = average(value.moods);
      return {
        tag,
        sentiment: mood >= 3.5 ? "positive" : mood <= 2.5 ? "negative" : "neutral",
        frequency: value.count,
        moodCorrelation: mood === 0 ? 0 : (mood - 3) / 2,
      };
    });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const payload = asRecord(await req.json().catch(() => ({}))) ?? {};
    const supabase = adminClient();
    if (!supabase) return jsonResponse({ error: "Supabase service role is not configured" }, 500);
    const deviceId = await resolveDeviceForRequest({
      supabase,
      req,
      requestedDeviceId: asString(payload.device_id ?? payload.deviceId ?? req.headers.get("x-device-id")),
    });
    const action = asString(payload.action) ?? "dashboard";
    const todayDate = requestDate(payload.todayDate ?? payload.date);
    switch (action) {
      case "dashboard":
        return jsonResponse(await fetchDashboard(supabase, deviceId, todayDate));
      case "today_log":
        return jsonResponse(await fetchToday(supabase, deviceId, todayDate));
      case "insights":
        return jsonResponse(await fetchInsights(supabase, deviceId, asInteger(payload.rangeDays, 7)));
      case "agents":
        return jsonResponse(await fetchAgents(supabase, deviceId));
      default:
        return jsonResponse({ error: "Unknown app-data action" }, 400);
    }
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
