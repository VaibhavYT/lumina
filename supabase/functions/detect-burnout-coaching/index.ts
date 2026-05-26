import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText } from "../_shared/gemini.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const patterns = payload.patterns ?? {};
    if (!Array.isArray(patterns.days) || patterns.days.length < 3) {
      return jsonResponse({ coaching: null });
    }

    const prompt = `Identify the single most impactful 7-day coaching focus from only this user's real Lumina data.

Pattern summary:
${JSON.stringify(patterns)}

Return ONLY JSON:
{"coachingTitle":"string","coachingReason":"2 sentences","dailyActions":["string","string","string","string","string","string","string"]}`;
    const text = await generateGeminiText(prompt, "null");
    const parsed = JSON.parse(text.replace(/```json|```/g, "").trim());
    const actions = Array.isArray(parsed?.dailyActions) ? parsed.dailyActions : [];
    return jsonResponse({
      coaching: actions.length > 0 ? parsed : null,
    });
  } catch (_error) {
    return jsonResponse({ coaching: null });
  }
});
