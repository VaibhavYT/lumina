import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText, safeJsonArray } from "../_shared/gemini.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const patterns = payload.patterns ?? {};
    if (!Array.isArray(patterns.days) || patterns.days.length < 3) {
      return jsonResponse({ plan: [] });
    }

    const prompt = `You are Lumina, an AI life mentor. Create a practical 7-day weekly growth plan from only the user's real app data.

Patterns:
${JSON.stringify(patterns)}

Return ONLY a JSON array of seven objects:
{"day":"Monday","theme":"string","action":"string","microHabit":"string"}`;
    const text = await generateGeminiText(prompt, "[]");
    const plan = safeJsonArray(text).slice(0, 7);
    return jsonResponse({ plan: plan.length === 7 ? plan : [] });
  } catch (_error) {
    return jsonResponse({ plan: [] });
  }
});
