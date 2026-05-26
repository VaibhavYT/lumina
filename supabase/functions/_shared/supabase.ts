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

export async function ensureProfile(deviceId: string, displayName?: string) {
  const supabase = adminClient();
  if (!supabase) {
    return;
  }
  await supabase.from("profiles").upsert({
    device_id: deviceId,
    display_name: displayName ?? null,
  }, { onConflict: "device_id" });
}
