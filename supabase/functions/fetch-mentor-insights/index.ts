import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { resolveDeviceForRequest } from "../_shared/agent_utils.ts";
import { adminClient } from "../_shared/supabase.ts";

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

function dateRange(value: unknown): { start: string; end: string } | null {
  const date = asString(value);
  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return null;
  }
  const start = new Date(`${date}T00:00:00.000Z`);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);
  return { start: start.toISOString(), end: end.toISOString() };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json() as Record<string, unknown>;

    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({
        error: "Supabase service role is not configured",
      }, 500);
    }

    const deviceId = await resolveDeviceForRequest({
      supabase,
      req,
      requestedDeviceId: asString(payload.deviceId) ??
        asString(payload.device_id) ??
        asString(req.headers.get("x-device-id")),
    });
    if (payload.action === "dismiss") {
      const insightId = asString(payload.insightId);
      if (!insightId) {
        return jsonResponse({ error: "insightId is required" }, 400);
      }
      const { error } = await supabase
        .from("mentor_insights")
        .update({ is_dismissed: true })
        .eq("device_id", deviceId)
        .eq("id", insightId);
      if (error) {
        throw new Error(error.message);
      }
      return jsonResponse({ success: true });
    }

    let query = supabase
      .from("mentor_insights")
      .select("id, insight_type, headline, body, metadata, generated_at")
      .eq("device_id", deviceId)
      .eq("is_dismissed", false)
      .order("generated_at", { ascending: false });

    const range = dateRange(payload.date);
    if (range) {
      query = query.gte("generated_at", range.start).lt("generated_at", range.end);
    } else {
      query = query.limit(30);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(error.message);
    }

    return jsonResponse({ insights: data ?? [] });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
