import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { resolveDeviceForRequest } from "../_shared/agent_utils.ts";
import { generateGeminiText } from "../_shared/gemini.ts";
import { adminClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({ error: "Supabase service role is not configured" }, 500);
    }
    const deviceId = await resolveDeviceForRequest({
      supabase,
      req,
      requestedDeviceId: String(payload.deviceId ?? payload.device_id ?? req.headers.get("x-device-id") ?? ""),
      displayName: typeof payload.displayName === "string" ? payload.displayName : null,
    });
    const todayDate = new Date().toISOString().slice(0, 10);
    const [{ data: today }, { data: recent }, { data: tasks }] = await Promise.all([
      supabase.from("daily_logs").select("log_date, mood, energy, notes, mood_note").eq("device_id", deviceId).eq("log_date", todayDate).maybeSingle(),
      supabase.from("daily_logs").select("log_date, mood, energy, notes").eq("device_id", deviceId).order("log_date", { ascending: false }).limit(10),
      supabase.from("tasks").select("title, is_completed, priority").eq("device_id", deviceId).eq("log_date", todayDate),
    ]);
    const fallback =
      "Today has enough signal to be useful: notice what gave you energy, and protect one small choice that made the day feel steadier.";
    const todayLog = today ?? {
      log_date: todayDate,
      mood: "not logged",
      energy: "not logged",
      notes: "",
    };
    const prompt = `You are Lumina, a warm, wise, and direct AI life mentor. You are not a therapist or a cheerleader.

Today's log:
- Date: ${todayLog.log_date}
- Mood: ${todayLog.mood}/5
- Energy: ${todayLog.energy}/5
- Tasks completed: ${(tasks ?? []).filter((task: { is_completed?: boolean }) => task.is_completed === true).length}/${tasks?.length ?? 0}
- Notes: "${todayLog.notes ?? ""}"

Recent context:
${JSON.stringify(recent)}

Write a personalized daily reflection. Rules:
1. Maximum 4 sentences.
2. Be specific to the data.
3. End with one gentle actionable observation or question.
4. Return only the reflection text.`;

    const reflection = await generateGeminiText(prompt, fallback);
    await supabase.from("mentor_insights").insert({
      device_id: deviceId,
      insight_type: "daily_reflection",
      headline: "Today's Reflection",
      body: reflection,
      metadata: { source: "generate-daily-reflection", contextSource: "database" },
    });

    return jsonResponse({ reflection });
  } catch (_error) {
    return jsonResponse({
      reflection:
        "There is useful information in today already. Choose one thing that steadied you, and make it easier to repeat tomorrow.",
    });
  }
});
