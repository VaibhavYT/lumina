import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText } from "../_shared/gemini.ts";
import { adminClient, ensureProfile } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const deviceId = String(payload.deviceId ?? req.headers.get("x-device-id") ?? "");
    if (!deviceId) {
      return jsonResponse({ error: "deviceId is required" }, 400);
    }

    await ensureProfile(deviceId, payload.displayName);
    const today = payload.todayLog ?? {};
    const recent = payload.recentLogs ?? [];
    const fallback =
      "Today has enough signal to be useful: notice what gave you energy, and protect one small choice that made the day feel steadier.";
    const prompt = `You are Lumina, a warm, wise, and direct AI life mentor. You are not a therapist or a cheerleader.

Today's log:
- Date: ${today.date}
- Mood: ${today.mood}/5
- Energy: ${today.energy}/5
- Tasks completed: ${today.completedTasks}/${today.totalTasks}
- Notes: "${today.notes ?? ""}"

Recent context:
${JSON.stringify(recent)}

Write a personalized daily reflection. Rules:
1. Maximum 4 sentences.
2. Be specific to the data.
3. End with one gentle actionable observation or question.
4. Return only the reflection text.`;

    const reflection = await generateGeminiText(prompt, fallback);
    const supabase = adminClient();
    if (supabase) {
      await supabase.from("mentor_insights").insert({
        device_id: deviceId,
        insight_type: "daily_reflection",
        headline: "Today's Reflection",
        body: reflection,
        metadata: { source: "generate-daily-reflection" },
      });
    }

    return jsonResponse({ reflection });
  } catch (_error) {
    return jsonResponse({
      reflection:
        "There is useful information in today already. Choose one thing that steadied you, and make it easier to repeat tomorrow.",
    });
  }
});
