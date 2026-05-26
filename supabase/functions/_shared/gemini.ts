const geminiUrl =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

export async function generateGeminiText(prompt: string, fallback: string) {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) {
    return fallback;
  }

  try {
    const response = await fetch(`${geminiUrl}?key=${key}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.65,
          maxOutputTokens: 800,
        },
      }),
    });

    if (!response.ok) {
      return fallback;
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return typeof text === "string" && text.trim().length > 0
      ? text.trim()
      : fallback;
  } catch (_error) {
    return fallback;
  }
}

export function safeJsonArray(text: string) {
  const cleaned = text.replace(/```json|```/g, "").trim();
  const parsed = JSON.parse(cleaned);
  return Array.isArray(parsed) ? parsed : [];
}
