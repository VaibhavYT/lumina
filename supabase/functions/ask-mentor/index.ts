import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { resolveDeviceForRequest } from "../_shared/agent_utils.ts";
import { generateGeminiText } from "../_shared/gemini.ts";
import { adminClient } from "../_shared/supabase.ts";

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

function chatHistory(value: unknown): ChatMessage[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => {
      if (!item || typeof item !== "object") {
        return null;
      }
      const record = item as Record<string, unknown>;
      const role = record.role === "assistant" ? "assistant" : "user";
      const content = String(record.content ?? "").trim();
      return content ? { role, content } : null;
    })
    .filter((item): item is ChatMessage => item !== null)
    .slice(-12);
}

function payloadContext(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as Record<string, unknown>;
}

async function storeChatMessages(
  supabase: any,
  deviceId: string,
  sessionId: string,
  question: string,
  answer: string,
) {
  try {
    const { error } = await supabase.from("mentor_chat_messages").insert([
      {
        device_id: deviceId,
        session_id: sessionId,
        role: "user",
        content: question,
      },
      {
        device_id: deviceId,
        session_id: sessionId,
        role: "assistant",
        content: answer,
      },
    ]);
    if (error) {
      console.error("mentor chat persistence skipped", deviceId, error.message);
    }
  } catch (error) {
    console.error("mentor chat persistence skipped", deviceId, error);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const question = String(payload.question ?? "").trim();
    if (!question) {
      return jsonResponse({ error: "question is required" }, 400);
    }

    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({ error: "Supabase service role is not configured" }, 500);
    }
    const deviceId = await resolveDeviceForRequest({
      supabase,
      req,
      requestedDeviceId: String(payload.deviceId ?? payload.device_id ?? req.headers.get("x-device-id") ?? ""),
    });
    const sessionId = String(payload.sessionId ?? payload.session_id ?? crypto.randomUUID());
    const history = chatHistory(payload.history);
    const appContext = payloadContext(payload.context);
    const [{ data: recentLogs }, { data: tasks }, { data: habits }, { data: insights }] =
      await Promise.all([
        supabase.from("daily_logs").select("log_date, mood, energy, notes").eq("device_id", deviceId).order("log_date", { ascending: false }).limit(14),
        supabase.from("tasks").select("log_date, title, is_completed, priority").eq("device_id", deviceId).order("log_date", { ascending: false }).limit(40),
        supabase.from("habits").select("name, frequency, is_active").eq("device_id", deviceId).eq("is_active", true),
        supabase.from("mentor_insights").select("insight_type, headline, body, generated_at").eq("device_id", deviceId).eq("is_dismissed", false).order("generated_at", { ascending: false }).limit(8),
      ]);
    const context = JSON.stringify({
      recentLogs,
      recentTasks: tasks,
      activeHabits: habits,
      recentInsights: insights,
      appContext,
      conversationHistory: history,
    });

    const isUntangle = appContext.source === "untangle";
    const untangleStage = String(appContext.stage ?? "");
    const prompt = isUntangle && untangleStage === "breakthrough"
      ? `You are Lumina in Untangle mode. Synthesize this Socratic session into one Breakthrough card.

Context:
${context}

Final user request: "${question}"

Rules:
1. Return exactly three plain-text sections: "Pattern:", "Truth:", and "Next brave move:".
2. Keep the entire card under 120 words.
3. Be specific to the conversation and the user's real context.
4. Make it compassionate, clear, and memorable.
5. Do not add markdown, bullets, greetings, or caveats.`
      : isUntangle
      ? `You are Lumina in Untangle mode: a calm Socratic mentor for complex thoughts.

Context:
${context}

User's latest reply: "${question}"

Rules:
1. Ask exactly one piercing question.
2. Do not answer, advise, summarize, validate, or list options.
3. The question must follow from the user's latest reply and the conversation history.
4. Prefer "why", "what", or "if" questions that reveal assumptions, fear, stakes, or values.
5. Keep it under 24 words.
6. If the user describes self-harm, immediate danger, or abuse, prioritize immediate safety in one concise sentence, then ask one grounding question.
7. Return only the response text.`
      : `You are Lumina, a warm, wise, direct AI life mentor.

Context:
${context}

Question: "${question}"

Rules:
1. Maximum 5 sentences.
2. Be specific to context.
3. End with one actionable suggestion or thought-provoking question.
4. Never start with "I" or "Great question!".
5. Return only the response text.`;

    const answer = await generateGeminiText(
      prompt,
      isUntangle && untangleStage === "breakthrough"
        ? "Pattern: Something important is asking for attention.\n\nTruth: The next step does not need to solve everything.\n\nNext brave move: Name one honest action you can take today."
        : isUntangle
        ? "What feels most true about that, even if it is uncomfortable to say plainly?"
        : "Start with the smallest next action you can repeat today. The pattern matters less than making it visible, then choosing one honest adjustment.",
    );

    await storeChatMessages(supabase, deviceId, sessionId, question, answer);

    return jsonResponse({ answer });
  } catch (_error) {
    return jsonResponse({
      answer:
        "Pick one small behavior you can actually repeat today, then watch how it changes your energy rather than judging the whole day.",
    });
  }
});
