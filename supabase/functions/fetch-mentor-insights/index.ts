import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { adminClient, ensureProfile } from "../_shared/supabase.ts";

function asString(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function errorMessage(error: unknown): string {
  if (error && typeof error === "object" && "message" in error) {
    return String((error as { message: unknown }).message);
  }
  return String(error);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json() as Record<string, unknown>;
    const deviceId = asString(payload.deviceId) ??
      asString(req.headers.get("x-device-id"));
    if (!deviceId) {
      return jsonResponse({ error: "deviceId is required" }, 400);
    }

    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({
        error: "Supabase service role is not configured",
      }, 500);
    }

    await ensureProfile(deviceId);
    const { data, error } = await supabase
      .from("mentor_insights")
      .select("id, headline, body, generated_at")
      .eq("device_id", deviceId)
      .eq("is_dismissed", false)
      .order("generated_at", { ascending: false })
      .limit(30);

    if (error) {
      throw new Error(error.message);
    }

    return jsonResponse({ insights: data ?? [] });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
