import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText } from "../_shared/gemini.ts";

const fallback = {
  coachingTitle: "Rebuilding Your Morning Anchor",
  coachingReason:
    "Your patterns suggest the day feels steadier when the first focus block is protected. A small morning anchor reduces decision fatigue before messages and requests arrive.",
  dailyActions: [
    "Write tomorrow's first task before bed.",
    "Start with ten quiet minutes before messages.",
    "Do the smallest useful part of the hard task first.",
    "Take a real reset before noon.",
    "Close one open loop before starting a new one.",
    "Leave one recovery block unscheduled.",
    "Review what made the week feel lighter.",
  ],
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const prompt = `Identify the single most impactful 7-day coaching focus.

Pattern summary:
${JSON.stringify(payload.patterns ?? {})}

Return ONLY JSON:
{"coachingTitle":"string","coachingReason":"2 sentences","dailyActions":["string","string","string","string","string","string","string"]}`;
    const text = await generateGeminiText(prompt, JSON.stringify(fallback));
    const parsed = JSON.parse(text.replace(/```json|```/g, "").trim());
    return jsonResponse({
      coaching: Array.isArray(parsed.dailyActions) ? parsed : fallback,
    });
  } catch (_error) {
    return jsonResponse({ coaching: fallback });
  }
});
