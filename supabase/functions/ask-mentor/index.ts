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
    const [{ data: recentLogs }, { data: tasks }, { data: habits }, { data: insights }] =
      await Promise.all([
        supabase.from("daily_logs").select("log_date, mood, energy, notes").eq("device_id", deviceId).order("log_date", { ascending: false }).limit(14),
        supabase.from("tasks").select("log_date, title, is_completed, priority").eq("device_id", deviceId).order("log_date", { ascending: false }).limit(40),
        supabase.from("habits").select("name, frequency, is_active").eq("device_id", deviceId).eq("is_active", true),
        supabase.from("mentor_insights").select("insight_type, headline, body, generated_at").eq("device_id", deviceId).eq("is_dismissed", false).order("generated_at", { ascending: false }).limit(8),
      ]);
    const prompt = `You are Lumina, a warm, wise, direct AI life mentor.

Context:
${JSON.stringify({
  recentLogs,
  recentTasks: tasks,
  activeHabits: habits,
  recentInsights: insights,
  appContext: payload.context ?? {},
  conversationHistory: history,
})}

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

    await storeChatMessages(supabase, deviceId, sessionId, question, answer);

    return jsonResponse({ answer });
  } catch (_error) {
    return jsonResponse({
      answer:
        "Pick one small behavior you can actually repeat today, then watch how it changes your energy rather than judging the whole day.",
    });
  }
});
