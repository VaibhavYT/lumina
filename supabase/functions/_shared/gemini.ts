const geminiBaseUrl = "https://generativelanguage.googleapis.com/v1beta";

function geminiModel() {
  return Deno.env.get("GEMINI_MODEL")?.trim() || "gemini-2.5-flash";
}

export async function generateGeminiText(
  prompt: string,
  fallback: string,
  options: { maxOutputTokens?: number; temperature?: number } = {},
) {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) {
    console.error("Gemini request skipped: GEMINI_API_KEY is not configured");
    return fallback;
  }

  try {
    const response = await fetch(
      `${geminiBaseUrl}/models/${geminiModel()}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": key,
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: options.temperature ?? 0.65,
            maxOutputTokens: options.maxOutputTokens ?? 800,
          },
        }),
      },
    );

    if (!response.ok) {
      const body = await response.text().catch(() => "");
      console.error(
        `Gemini request failed: ${response.status} ${response.statusText} ${body.slice(0, 500)}`,
      );
      return fallback;
    }

    const data = await response.json();
    const parts = data?.candidates?.[0]?.content?.parts;
    const text = Array.isArray(parts)
      ? parts
        .map((part) => part?.text)
        .filter((part) => typeof part === "string")
        .join("\n")
      : null;
    return typeof text === "string" && text.trim().length > 0
      ? text.trim()
      : fallback;
  } catch (error) {
    console.error("Gemini request crashed:", error);
    return fallback;
  }
}

export function safeJsonArray(text: string) {
  const cleaned = text
    .replace(/```json|```/g, "")
    .trim()
    .replace(/^[^\[]*/, "")
    .replace(/[^\]]*$/, "");
  const parsed = JSON.parse(cleaned);
  return Array.isArray(parsed) ? parsed : [];
}

export function safeJsonObject(text: string) {
  const cleaned = text
    .replace(/```json|```/g, "")
    .trim()
    .replace(/^[^{]*/, "")
    .replace(/[^}]*$/, "");
  const parsed = JSON.parse(cleaned);
  return parsed && typeof parsed === "object" && !Array.isArray(parsed)
    ? parsed as Record<string, unknown>
    : {};
}
