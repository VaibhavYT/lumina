import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText, safeJsonArray } from "../_shared/gemini.ts";

const fallback = [
  { day: "Monday", theme: "Clean Start", action: "Choose one meaningful focus before opening messages.", microHabit: "Write the first task by hand." },
  { day: "Tuesday", theme: "Deep Work", action: "Protect a 45-minute block for your hardest task.", microHabit: "Set the phone away from the desk." },
  { day: "Wednesday", theme: "Energy Check", action: "Take a real midday reset before your energy dips.", microHabit: "Walk for ten minutes." },
  { day: "Thursday", theme: "Repair", action: "Close one lingering loop that has been draining attention.", microHabit: "Send one honest update." },
  { day: "Friday", theme: "Review", action: "Name what worked this week and repeat the smallest piece.", microHabit: "Write three bullets." },
  { day: "Saturday", theme: "Recovery", action: "Let one block of time stay unscheduled.", microHabit: "Do nothing for five minutes." },
  { day: "Sunday", theme: "Preview", action: "Choose the week’s first focus before the week begins.", microHabit: "Set Monday’s first step." },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const prompt = `You are Lumina, an AI life mentor. Create a practical 7-day weekly growth plan.

Patterns:
${JSON.stringify(payload.patterns ?? {})}

Return ONLY a JSON array of seven objects:
{"day":"Monday","theme":"string","action":"string","microHabit":"string"}`;
    const text = await generateGeminiText(prompt, JSON.stringify(fallback));
    const plan = safeJsonArray(text).slice(0, 7);
    return jsonResponse({ plan: plan.length === 7 ? plan : fallback });
  } catch (_error) {
    return jsonResponse({ plan: fallback });
  }
});
