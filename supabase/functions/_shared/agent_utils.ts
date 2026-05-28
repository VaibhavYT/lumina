export type JsonRecord = Record<string, unknown>;

export type ProfileRow = {
  device_id: string;
  display_name?: string | null;
  fcm_token?: string | null;
};

export const dayNames = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

export function asRecord(value: unknown): JsonRecord | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as JsonRecord
    : null;
}

export function asString(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

export function asNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

export function asInteger(value: unknown, fallback = 0): number {
  return Math.trunc(asNumber(value, fallback));
}

export function asBoolean(value: unknown): boolean {
  return value === true;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function round(value: number, decimals = 1): number {
  const factor = 10 ** decimals;
  return Math.round(value * factor) / factor;
}

export function percentage(value: number): number {
  return Math.round(clamp(value, 0, 1) * 100);
}

export function average(values: number[]): number {
  const usable = values.filter((value) => Number.isFinite(value));
  if (usable.length === 0) {
    return 0;
  }
  return usable.reduce((sum, value) => sum + value, 0) / usable.length;
}

export function trendFromValues(values: number[]): "improving" | "declining" | "stable" {
  if (values.length < 4) {
    return "stable";
  }
  const first = average(values.slice(0, Math.min(10, values.length)));
  const last = average(values.slice(-Math.min(10, values.length)));
  if (last - first > 0.35) {
    return "improving";
  }
  if (first - last > 0.35) {
    return "declining";
  }
  return "stable";
}

export function isoDate(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

export function parseDate(value: string): Date {
  return new Date(`${value}T00:00:00.000Z`);
}

export function addDays(date: Date, days: number): Date {
  const copy = new Date(date);
  copy.setUTCDate(copy.getUTCDate() + days);
  return copy;
}

export function addHours(date: Date, hours: number): Date {
  const copy = new Date(date);
  copy.setUTCHours(copy.getUTCHours() + hours);
  return copy;
}

export function daysBetween(start: Date, end: Date): number {
  const ms = parseDate(isoDate(end)).getTime() - parseDate(isoDate(start)).getTime();
  return Math.ceil(ms / 86_400_000);
}

export function dayNameFromDate(date: string | Date): string {
  const parsed = typeof date === "string" ? parseDate(date) : date;
  return dayNames[parsed.getUTCDay()];
}

export function streaksFromLogDates(dates: string[]): {
  currentStreak: number;
  longestStreak: number;
} {
  const unique = [...new Set(dates)].sort();
  if (unique.length === 0) {
    return { currentStreak: 0, longestStreak: 0 };
  }

  let longestStreak = 1;
  let run = 1;
  for (let index = 1; index < unique.length; index++) {
    const previous = parseDate(unique[index - 1]);
    const current = parseDate(unique[index]);
    if (daysBetween(previous, current) === 1) {
      run += 1;
      longestStreak = Math.max(longestStreak, run);
    } else {
      run = 1;
    }
  }

  let currentStreak = 0;
  let cursor = parseDate(isoDate());
  const set = new Set(unique);
  while (set.has(isoDate(cursor))) {
    currentStreak += 1;
    cursor = addDays(cursor, -1);
  }

  return { currentStreak, longestStreak };
}

export function profileName(profile: ProfileRow): string {
  return profile.display_name?.trim() || "friend";
}

export function errorMessage(error: unknown): string {
  if (error && typeof error === "object" && "message" in error) {
    return String((error as { message: unknown }).message);
  }
  return String(error);
}

export function cleanPriority(value: unknown): "high" | "normal" | "low" {
  const priority = asString(value);
  return priority === "high" || priority === "low" || priority === "normal"
    ? priority
    : "normal";
}

export async function targetProfiles(
  supabase: any,
  deviceId: string | null,
): Promise<ProfileRow[]> {
  let query = supabase
    .from("profiles")
    .select("device_id, display_name, fcm_token")
    .order("created_at", { ascending: true });
  if (deviceId) {
    query = query.eq("device_id", deviceId);
  }
  const { data, error } = await query;
  if (error) {
    throw new Error(`profiles fetch failed: ${error.message}`);
  }
  return (data ?? [])
    .map((item: JsonRecord) => ({
      device_id: String(item.device_id ?? ""),
      display_name: item.display_name as string | null,
      fcm_token: item.fcm_token as string | null,
    }))
    .filter((item: ProfileRow) => item.device_id.length > 0);
}

export function jsonHeaders(serviceKey?: string | null) {
  return {
    "Content-Type": "application/json",
    ...(serviceKey ? { Authorization: `Bearer ${serviceKey}` } : {}),
  };
}

function base64UrlDecode(value: string): string {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return atob(padded);
}

function bearerToken(req: Request): string {
  const header = req.headers.get("authorization") ?? "";
  return header.replace(/^Bearer\s+/i, "").trim();
}

export function authClaims(req: Request): JsonRecord | null {
  const token = bearerToken(req);
  const payload = token.split(".")[1];
  if (!payload) {
    return null;
  }
  try {
    return JSON.parse(base64UrlDecode(payload)) as JsonRecord;
  } catch (_error) {
    return null;
  }
}

export function isServiceRoleRequest(req: Request): boolean {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  return Boolean(serviceRoleKey && bearerToken(req) === serviceRoleKey);
}

export async function resolveDeviceForRequest({
  supabase,
  req,
  requestedDeviceId,
  displayName,
  fcmToken,
}: {
  supabase: any;
  req: Request;
  requestedDeviceId?: string | null;
  displayName?: string | null;
  fcmToken?: string | null;
}): Promise<string> {
  const claims = authClaims(req);
  const userId = asString(claims?.sub);

  if (isServiceRoleRequest(req)) {
    const deviceId = asString(requestedDeviceId);
    if (!deviceId) {
      throw new Error("device_id is required for service role requests");
    }
    return deviceId;
  }

  if (!userId) {
    throw new Error("A signed-in user session is required");
  }

  const { data: existing, error: existingError } = await supabase
    .from("profiles")
    .select("device_id")
    .eq("user_id", userId)
    .maybeSingle();
  if (existingError) {
    throw new Error(`profile lookup failed: ${existingError.message}`);
  }
  if (existing?.device_id) {
    const update: JsonRecord = {};
    if (displayName) {
      update.display_name = displayName;
    }
    if (fcmToken) {
      update.fcm_token = fcmToken;
    }
    if (Object.keys(update).length > 0) {
      await supabase.from("profiles").update(update).eq("device_id", existing.device_id);
    }
    return existing.device_id;
  }

  const deviceId = asString(requestedDeviceId) ?? userId;
  const { data: deviceProfile, error: deviceError } = await supabase
    .from("profiles")
    .select("user_id")
    .eq("device_id", deviceId)
    .maybeSingle();
  if (deviceError) {
    throw new Error(`device profile lookup failed: ${deviceError.message}`);
  }
  if (deviceProfile?.user_id && deviceProfile.user_id !== userId) {
    throw new Error("device_id already belongs to another user");
  }

  const profile: JsonRecord = {
    device_id: deviceId,
    user_id: userId,
  };
  if (displayName) {
    profile.display_name = displayName;
  }
  if (fcmToken) {
    profile.fcm_token = fcmToken;
  }

  const { error: upsertError } = await supabase
    .from("profiles")
    .upsert(profile, { onConflict: "device_id" });
  if (upsertError) {
    throw new Error(`profile upsert failed: ${upsertError.message}`);
  }

  return deviceId;
}
