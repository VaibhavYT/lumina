import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { jsonHeaders, resolveDeviceForRequest } from "../_shared/agent_utils.ts";
import { adminClient } from "../_shared/supabase.ts";

type PayloadRecord = Record<string, unknown>;

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function asRecord(value: unknown): PayloadRecord | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as PayloadRecord
    : null;
}

function asString(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function isString(value: string | null): value is string {
  return value !== null;
}

function isRecord(value: PayloadRecord | null): value is PayloadRecord {
  return value !== null;
}

function asInteger(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.trunc(value)
    : null;
}

function asBoolean(value: unknown): boolean {
  return value === true;
}

function asDateString(value: unknown, fallback: string): string {
  const text = asString(value);
  if (!text) {
    return fallback;
  }
  const match = text.match(/^\d{4}-\d{2}-\d{2}/);
  return match ? match[0] : fallback;
}

function asPriority(value: unknown): string {
  const priority = asString(value);
  return priority === "high" || priority === "low" || priority === "normal"
    ? priority
    : "normal";
}

function ensureUuid(value: unknown): string | null {
  const text = asString(value);
  return text && uuidPattern.test(text) ? text : null;
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
    const payload = await req.json() as PayloadRecord;
    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({
        error: "Supabase service role is not configured",
      }, 500);
    }

    const profile = asRecord(payload.profile);
    const deviceId = await resolveDeviceForRequest({
      supabase,
      req,
      requestedDeviceId: asString(payload.deviceId) ??
        asString(payload.device_id) ??
        asString(req.headers.get("x-device-id")),
      displayName: asString(profile?.display_name),
      fcmToken: asString(profile?.fcm_token),
    });

    const today = new Date().toISOString().slice(0, 10);
    const dailyLog = asRecord(payload.dailyLog);
    const logDate = asDateString(dailyLog?.log_date ?? payload.logDate, today);
    const hasCompletedHabitSnapshot = Array.isArray(payload.completedHabitIds);
    const completedHabitIds = hasCompletedHabitSnapshot
      ? (payload.completedHabitIds as unknown[]).map(asString).filter(isString)
      : [];

    if (dailyLog) {
      const { error } = await supabase.from("daily_logs").upsert({
        device_id: deviceId,
        log_date: logDate,
        mood: asInteger(dailyLog.mood),
        mood_note: asString(dailyLog.mood_note),
        energy: asInteger(dailyLog.energy),
        notes: asString(dailyLog.notes),
        completed_habit_ids: completedHabitIds,
      }, { onConflict: "device_id,log_date" });
      if (error) {
        throw new Error(`daily_logs upsert failed: ${error.message}`);
      }
    }

    const taskRows = (Array.isArray(payload.tasks) ? payload.tasks : [])
      .map((value, index) => {
        const task = asRecord(value);
        if (!task) {
          return null;
        }
        const title = asString(task.title);
        if (!title) {
          return null;
        }
        const row: PayloadRecord = {
          device_id: deviceId,
          log_date: asDateString(task.log_date, logDate),
          title,
          is_completed: asBoolean(task.is_completed ?? task.isCompleted),
          priority: asPriority(task.priority),
          sort_order: asInteger(task.sort_order) ?? index,
        };
        const id = ensureUuid(task.id);
        if (id) {
          row.id = id;
        }
        return row;
      })
      .filter(isRecord);

    if (Array.isArray(payload.tasks)) {
      const taskIds = taskRows.map((row) => asString(row.id)).filter(isString);
      let deleteQuery = supabase.from("tasks")
        .delete()
        .eq("device_id", deviceId)
        .eq("log_date", logDate);
      if (taskIds.length > 0) {
        deleteQuery = deleteQuery.not("id", "in", `(${taskIds.join(",")})`);
      }
      const { error } = await deleteQuery;
      if (error) {
        throw new Error(`tasks snapshot delete failed: ${error.message}`);
      }
    }

    if (taskRows.length > 0) {
      const { error } = await supabase.from("tasks")
        .upsert(taskRows, { onConflict: "id" });
      if (error) {
        throw new Error(`tasks upsert failed: ${error.message}`);
      }
    }

    const habitRows = (Array.isArray(payload.habits) ? payload.habits : [])
      .map((value, index) => {
        const habit = asRecord(value);
        if (!habit) {
          return null;
        }
        const name = asString(habit.name);
        if (!name) {
          return null;
        }
        const row: PayloadRecord = {
          device_id: deviceId,
          name,
          emoji: asString(habit.emoji),
          color_hex: asString(habit.color_hex ?? habit.colorHex),
          frequency: asString(habit.frequency) ?? "daily",
          is_active: habit.is_active ?? habit.isActive ?? true,
        };
        const id = ensureUuid(habit.id ?? habit.habit_id ?? habit.habitId);
        if (id) {
          row.id = id;
        } else {
          row.local_habit_id = asString(habit.habit_id ?? habit.habitId ?? habit.id) ??
            `habit-${index}`;
        }
        return row;
      })
      .filter(isRecord);

    const uuidHabitRows = habitRows.filter((row) => row.id);
    const localHabitRows = habitRows.filter((row) => row.local_habit_id);
    if (uuidHabitRows.length > 0) {
      const { error } = await supabase.from("habits")
        .upsert(uuidHabitRows, { onConflict: "id" });
      if (error) {
        throw new Error(`habit UUID upsert failed: ${error.message}`);
      }
    }
    for (const row of localHabitRows) {
      const { error } = await supabase.from("habits")
        .upsert(row, { onConflict: "device_id,local_habit_id" });
      if (error) {
        throw new Error(`habit local upsert failed: ${error.message}`);
      }
    }

    const completionValues = Array.isArray(payload.habitCompletions)
      ? payload.habitCompletions
      : completedHabitIds.map((habitId) => ({
        habit_id: habitId,
        completion_date: logDate,
      }));

    if (hasCompletedHabitSnapshot) {
      const { error: deleteSnapshotError } = await supabase
        .from("habit_completions")
        .delete()
        .eq("device_id", deviceId)
        .eq("completion_date", logDate);
      if (deleteSnapshotError) {
        throw new Error(
          `habit completion snapshot delete failed: ${deleteSnapshotError.message}`,
        );
      }
    }

    const uuidCompletionRows: PayloadRecord[] = [];
    const localCompletionRows: PayloadRecord[] = [];
    for (const value of completionValues) {
      const completion = asRecord(value);
      if (!completion) {
        continue;
      }
      const habitId = asString(completion.habit_id ?? completion.habitId);
      const completionDate = asDateString(completion.completion_date, logDate);
      if (!habitId) {
        continue;
      }
      const uuid = ensureUuid(habitId);
      if (uuid) {
        uuidCompletionRows.push({
          device_id: deviceId,
          habit_id: uuid,
          completion_date: completionDate,
        });
      } else {
        localCompletionRows.push({
          device_id: deviceId,
          local_habit_id: habitId,
          completion_date: completionDate,
        });
      }
    }

    if (uuidCompletionRows.length > 0) {
      const { error } = await supabase.from("habit_completions")
        .upsert(uuidCompletionRows, { onConflict: "habit_id,completion_date" });
      if (error) {
        throw new Error(`habit UUID completion upsert failed: ${error.message}`);
      }
    }

    if (localCompletionRows.length > 0) {
      for (const row of localCompletionRows) {
        const { error: deleteError } = await supabase.from("habit_completions")
          .delete()
          .eq("device_id", deviceId)
          .eq("local_habit_id", String(row.local_habit_id))
          .eq("completion_date", String(row.completion_date));
        if (deleteError) {
          throw new Error(
            `habit local completion delete failed: ${deleteError.message}`,
          );
        }
      }

      const { error: insertError } = await supabase.from("habit_completions")
        .insert(localCompletionRows);
      if (insertError) {
        throw new Error(
          `habit local completion insert failed: ${insertError.message}`,
        );
      }
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (dailyLog && supabaseUrl && serviceKey) {
      EdgeRuntime.waitUntil(
        fetch(`${supabaseUrl}/functions/v1/burnout-interception-agent`, {
          method: "POST",
          headers: jsonHeaders(serviceKey),
          body: JSON.stringify({ device_id: deviceId, log_date: logDate }),
        }).catch((error) => {
          console.error("Burnout agent call failed:", error);
        }),
      );
    }

    return jsonResponse({
      ok: true,
      synced: {
        dailyLog: Boolean(dailyLog),
        tasks: taskRows.length,
        habitCompletions: uuidCompletionRows.length + localCompletionRows.length,
      },
    });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
