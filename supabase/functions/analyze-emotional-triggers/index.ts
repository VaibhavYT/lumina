import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText, safeJsonArray } from "../_shared/gemini.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const notes = Array.isArray(payload.notes) ? payload.notes : [];
    const moodData = Array.isArray(payload.moodData) ? payload.moodData : [];
    if (notes.length < 3 || moodData.length < 3) {
      return jsonResponse({ triggers: [] });
    }

    const prompt = `Analyze these real journal notes and identify emotional triggers.

Notes:
${JSON.stringify(notes)}

Mood data:
${JSON.stringify(moodData)}

Return ONLY a JSON array:
[
  {"tag":"string","sentiment":"positive|negative|neutral","frequency":1,"moodCorrelation":0.0}
]`;

    const text = await generateGeminiText(prompt, "[]");
    const parsed = safeJsonArray(text)
      .filter((item) => typeof item?.tag === "string")
      .slice(0, 12);
    return jsonResponse({ triggers: parsed });
  } catch (_error) {
    return jsonResponse({ triggers: [] });
  }
});
