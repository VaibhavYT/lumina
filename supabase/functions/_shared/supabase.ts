import { createClient } from "jsr:@supabase/supabase-js@2";

export function adminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) {
    return null;
  }
  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export async function ensureProfile(
  deviceId: string,
  displayName?: string,
  fcmToken?: string,
) {
  const supabase = adminClient();
  if (!supabase) {
    return;
  }
  const profile: Record<string, unknown> = {
    device_id: deviceId,
    display_name: displayName ?? null,
  };
  if (fcmToken) {
    profile.fcm_token = fcmToken;
  }
  await supabase.from("profiles").upsert(profile, { onConflict: "device_id" });
}
