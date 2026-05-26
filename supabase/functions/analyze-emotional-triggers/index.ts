import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText, safeJsonArray } from "../_shared/gemini.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const fallback = [
    { tag: "early focus", sentiment: "positive", frequency: 6, moodCorrelation: 0.62 },
    { tag: "late messages", sentiment: "negative", frequency: 5, moodCorrelation: -0.55 },
  ];

  try {
    const payload = await req.json();
    const notes = payload.notes ?? [];
    const moodData = payload.moodData ?? [];
    const prompt = `Analyze these journal notes and identify emotional triggers.

Notes:
${JSON.stringify(notes)}

Mood data:
${JSON.stringify(moodData)}

Return ONLY a JSON array:
[
  {"tag":"string","sentiment":"positive|negative|neutral","frequency":1,"moodCorrelation":0.0}
]`;

    const text = await generateGeminiText(prompt, JSON.stringify(fallback));
    const parsed = safeJsonArray(text)
      .filter((item) => typeof item?.tag === "string")
      .slice(0, 12);
    return jsonResponse({ triggers: parsed.length > 0 ? parsed : fallback });
  } catch (_error) {
    return jsonResponse({ triggers: fallback });
  }
});
