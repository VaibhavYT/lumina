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
    const question = String(payload.question ?? "").trim();
    const deviceId = String(payload.deviceId ?? req.headers.get("x-device-id") ?? "");
    if (!question || !deviceId) {
      return jsonResponse({ error: "deviceId and question are required" }, 400);
    }

    await ensureProfile(deviceId);
    const prompt = `You are Lumina, a warm, wise, direct AI life mentor.

Context:
${JSON.stringify(payload.context ?? {})}

Question: "${question}"

Rules:
1. Maximum 5 sentences.
2. Be specific to context.
3. End with one actionable suggestion or thought-provoking question.
4. Never start with "I" or "Great question!".
5. Return only the response text.`;

    const answer = await generateGeminiText(
      prompt,
      "Start with the smallest next action you can repeat today. The pattern matters less than making it visible, then choosing one honest adjustment.",
    );

    const supabase = adminClient();
    if (supabase) {
      await supabase.from("mentor_insights").insert({
        device_id: deviceId,
        insight_type: "ask_response",
        headline: question,
        body: answer,
        metadata: { question },
      });
    }

    return jsonResponse({ answer });
  } catch (_error) {
    return jsonResponse({
      answer:
        "Pick one small behavior you can actually repeat today, then watch how it changes your energy rather than judging the whole day.",
    });
  }
});
