import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { generateGeminiText, safeJsonObject } from "../_shared/gemini.ts";
import { adminClient, ensureProfile } from "../_shared/supabase.ts";
import {
  addDays,
  asInteger,
  asRecord,
  asString,
  average,
  cleanPriority,
  daysBetween,
  errorMessage,
  isoDate,
  parseDate,
} from "../_shared/agent_utils.ts";

type GoalTask = {
  title: string;
  priority: "high" | "normal" | "low";
  dayOffset: number;
};

function fallbackPlan(goalTitle: string, targetDate: string, weeksAvailable: number) {
  const milestones = Array.from({ length: weeksAvailable }, (_, index) => {
    const week = index + 1;
    return {
      weekNumber: week,
      milestoneTitle: week === weeksAvailable ? "Finish and review" : `Week ${week} foundation`,
      description:
        week === weeksAvailable
          ? `Complete the final version of ${goalTitle} and review what worked.`
          : `Make steady progress on ${goalTitle} with a small repeatable rhythm.`,
      targetDate: isoDate(addDays(new Date(), week * 7 - 1)),
    };
  });
  return {
    goalSummary:
      `We will turn "${goalTitle}" into a ${weeksAvailable}-week plan with small repeatable actions before ${targetDate}.`,
    phases: [
      {
        phaseNumber: 1,
        phaseTitle: "Foundation",
        weeksSpan: "Weeks 1-2",
        phaseGoal: "Build the smallest reliable rhythm.",
      },
      {
        phaseNumber: 2,
        phaseTitle: "Momentum",
        weeksSpan: `Weeks 3-${Math.max(3, weeksAvailable)}`,
        phaseGoal: "Increase difficulty only after consistency is visible.",
      },
    ],
    weeklyMilestones: milestones,
    dailyTasksByWeek: milestones.map((milestone) => ({
      weekNumber: milestone.weekNumber,
      tasks: [
        { title: `Plan one step for ${goalTitle}`, priority: "high", dayOffset: 0 },
        { title: `Do a 25 minute ${goalTitle} block`, priority: "normal", dayOffset: 2 },
        { title: `Review progress on ${goalTitle}`, priority: "low", dayOffset: 5 },
      ],
    })),
    adjustmentTriggers: {
      fallingBehindSignal: "Fewer than two goal tasks completed in a week",
      accelerationSignal: "Four goal tasks completed without energy dropping",
    },
  };
}

function validatePlan(parsed: Record<string, unknown>, fallback: ReturnType<typeof fallbackPlan>) {
  const phases = Array.isArray(parsed.phases) ? parsed.phases.map(asRecord).filter(Boolean) : fallback.phases;
  const weeklyMilestones = Array.isArray(parsed.weeklyMilestones)
    ? parsed.weeklyMilestones.map(asRecord).filter(Boolean)
    : fallback.weeklyMilestones;
  const dailyTasksByWeek = Array.isArray(parsed.dailyTasksByWeek)
    ? parsed.dailyTasksByWeek.map(asRecord).filter(Boolean)
    : fallback.dailyTasksByWeek;
  return {
    goalSummary: asString(parsed.goalSummary) ?? fallback.goalSummary,
    phases: phases.slice(0, 3).map((phase, index) => ({
      phaseNumber: asInteger(phase?.phaseNumber, index + 1),
      phaseTitle: asString(phase?.phaseTitle) ?? `Phase ${index + 1}`,
      weeksSpan: asString(phase?.weeksSpan) ?? `Week ${index + 1}`,
      phaseGoal: asString(phase?.phaseGoal) ?? "Make steady progress.",
    })),
    weeklyMilestones: weeklyMilestones.map((milestone, index) => ({
      weekNumber: asInteger(milestone?.weekNumber, index + 1),
      milestoneTitle: asString(milestone?.milestoneTitle) ?? `Week ${index + 1}`,
      description: asString(milestone?.description) ?? "Complete the weekly milestone.",
      targetDate: asString(milestone?.targetDate) ?? isoDate(addDays(new Date(), (index + 1) * 7 - 1)),
    })),
    dailyTasksByWeek: dailyTasksByWeek.map((week, index) => ({
      weekNumber: asInteger(week?.weekNumber, index + 1),
      tasks: Array.isArray(week?.tasks)
        ? week.tasks.map(asRecord).filter(Boolean).slice(0, 8).map((task, taskIndex) => ({
          title: (asString(task?.title) ?? "Complete one goal step").slice(0, 80),
          priority: cleanPriority(task?.priority),
          dayOffset: Math.max(0, Math.min(6, asInteger(task?.dayOffset, taskIndex))),
        }))
        : [] as GoalTask[],
    })),
    adjustmentTriggers: asRecord(parsed.adjustmentTriggers) ?? fallback.adjustmentTriggers,
  };
}

async function fetchActiveGoal(supabase: any, deviceId: string) {
  const { data: goal, error } = await supabase.from("goals")
    .select("id, title, description, target_date, status, health_score, created_at")
    .eq("device_id", deviceId)
    .eq("status", "active")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) {
    throw new Error(error.message);
  }
  if (!goal) {
    return { activeGoal: null, milestones: [], stats: null, todaysTasks: [] };
  }
  const [{ data: milestones }, { data: tasks }, { data: todaysTasks }] = await Promise.all([
    supabase.from("goal_milestones")
      .select("id, week_number, title, description, target_date, is_completed")
      .eq("goal_id", goal.id)
      .order("week_number", { ascending: true }),
    supabase.from("tasks").select("id, is_completed").eq("goal_id", goal.id),
    supabase.from("tasks")
      .select("id, title, priority, is_completed, log_date")
      .eq("goal_id", goal.id)
      .eq("log_date", isoDate())
      .order("sort_order", { ascending: true }),
  ]);
  const totalTasks = tasks?.length ?? 0;
  const completedTasks = (tasks ?? []).filter((task: any) => task.is_completed === true).length;
  const totalWeeks = Math.max(1, Math.ceil(daysBetween(parseDate(goal.created_at.slice(0, 10)), parseDate(goal.target_date)) / 7));
  const weeksElapsed = Math.max(1, Math.min(totalWeeks, Math.ceil(daysBetween(parseDate(goal.created_at.slice(0, 10)), new Date()) / 7)));
  const currentMilestone = (milestones ?? []).find((milestone: any) => milestone.week_number >= weeksElapsed) ?? milestones?.at(-1) ?? null;
  const completionRate = totalTasks === 0 ? 0 : completedTasks / totalTasks;
  const expectedRate = weeksElapsed / totalWeeks;
  const status = completionRate + 0.15 < expectedRate ? "Behind" : completionRate > expectedRate + 0.20 ? "Ahead" : "On Track";
  return {
    activeGoal: goal,
    milestones: milestones ?? [],
    todaysTasks: todaysTasks ?? [],
    stats: {
      totalWeeks,
      weeksElapsed,
      completedTasks,
      totalTasks,
      completionRate,
      expectedRate,
      status,
      currentMilestone,
    },
  };
}

async function createGoal(supabase: any, payload: Record<string, unknown>) {
  const deviceId = asString(payload.device_id ?? payload.deviceId);
  const goalTitle = asString(payload.goalTitle);
  const targetDate = asString(payload.targetDate);
  const context = asString(payload.context) ?? "Not provided";
  if (!deviceId || !goalTitle || !targetDate) {
    return jsonResponse({ error: "device_id, goalTitle, and targetDate are required" }, 400);
  }

  await ensureProfile(deviceId);
  const today = new Date();
  const target = parseDate(targetDate);
  const weeksAvailable = Math.max(1, Math.min(16, Math.ceil(daysBetween(today, target) / 7)));
  const since = isoDate(addDays(today, -13));
  const [{ data: logs }, { data: habits }] = await Promise.all([
    supabase.from("daily_logs").select("mood, energy").eq("device_id", deviceId).gte("log_date", since),
    supabase.from("habits").select("name").eq("device_id", deviceId).eq("is_active", true),
  ]);
  const avgMood = average((logs ?? []).map((log: any) => log.mood ?? 0).filter((value: number) => value > 0));
  const avgEnergy = average((logs ?? []).map((log: any) => log.energy ?? 0).filter((value: number) => value > 0));
  const habitNames = (habits ?? []).map((habit: any) => habit.name).filter(Boolean).join(", ") || "None tracked";
  const fallback = fallbackPlan(goalTitle, targetDate, weeksAvailable);
  const prompt = `You are Lumina, an AI life mentor. A user has set a goal and you must create a complete, phased action plan for them.

Goal: "${goalTitle}"
Target Date: ${targetDate} (${weeksAvailable} weeks away)
User Context: ${context}
User's Current Mood Level (avg): ${avgMood.toFixed(1)}/5
User's Current Energy Level (avg): ${avgEnergy.toFixed(1)}/5
User's Existing Habits: ${habitNames}

Create a week-by-week milestone plan and specific daily tasks. Return ONLY this JSON structure:

{
  "goalSummary": "1 sentence describing how you'll approach this goal for this specific person",
  "phases": [
    {
      "phaseNumber": 1,
      "phaseTitle": "Phase name",
      "weeksSpan": "Weeks 1-2",
      "phaseGoal": "1 sentence goal for this phase"
    }
  ],
  "weeklyMilestones": [
    {
      "weekNumber": 1,
      "milestoneTitle": "Short milestone name",
      "description": "What success looks like this week",
      "targetDate": "ISO date of end of this week"
    }
  ],
  "dailyTasksByWeek": [
    {
      "weekNumber": 1,
      "tasks": [
        {
          "title": "Task title (max 60 chars)",
          "priority": "high | normal | low",
          "dayOffset": 0
        }
      ]
    }
  ],
  "adjustmentTriggers": {
    "fallingBehindSignal": "What metric indicates the user is falling behind",
    "accelerationSignal": "What metric indicates they can push harder"
  }
}

Rules:
- Make tasks SPECIFIC and ACHIEVABLE
- Max 2 tasks per day from this goal
- dailyTasksByWeek: include 3-4 representative tasks per week
- Phases should be 2-3 phases total regardless of goal length
- Tasks should progress in difficulty across weeks
- Consider the user's energy level
- Return ONLY the JSON. No markdown. No explanation.`;

  let plan = fallback;
  try {
    const text = await generateGeminiText(prompt, JSON.stringify(fallback), { maxOutputTokens: 3000, temperature: 0.58 });
    plan = validatePlan(safeJsonObject(text), fallback);
  } catch (error) {
    console.error("goal-decomposition-agent Gemini parse failed", deviceId, error);
  }

  const { data: goal, error: goalError } = await supabase.from("goals")
    .insert({ device_id: deviceId, title: goalTitle, description: plan.goalSummary, target_date: targetDate })
    .select("id")
    .single();
  if (goalError) {
    throw new Error(goalError.message);
  }

  const milestones = plan.weeklyMilestones.map((milestone) => ({
    goal_id: goal.id,
    device_id: deviceId,
    week_number: milestone.weekNumber,
    title: milestone.milestoneTitle,
    description: milestone.description,
    target_date: milestone.targetDate,
  }));
  if (milestones.length) {
    const { error } = await supabase.from("goal_milestones").insert(milestones);
    if (error) {
      throw new Error(error.message);
    }
  }

  const taskRows = [];
  for (const week of plan.dailyTasksByWeek.filter((week) => week.weekNumber <= 2)) {
    for (const task of week.tasks) {
      const taskDate = addDays(today, ((week.weekNumber - 1) * 7) + task.dayOffset);
      taskRows.push({
        device_id: deviceId,
        log_date: isoDate(taskDate),
        title: task.title,
        priority: task.priority,
        goal_id: goal.id,
        is_completed: false,
        metadata: { source: "goal_decomposition_agent" },
      });
    }
  }
  if (taskRows.length) {
    const { error } = await supabase.from("tasks").insert(taskRows);
    if (error) {
      throw new Error(error.message);
    }
  }

  await supabase.from("mentor_insights").insert({
    device_id: deviceId,
    insight_type: "goal_created",
    headline: `New Goal: ${goalTitle}`,
    body: plan.goalSummary,
    metadata: {
      goalId: goal.id,
      targetDate,
      weeksAvailable,
      phases: plan.phases,
      adjustmentTriggers: plan.adjustmentTriggers,
      source: "goal_decomposition_agent",
    },
    expires_at: null,
  });

  return jsonResponse({
    success: true,
    goalId: goal.id,
    milestonesCreated: milestones.length,
    tasksCreated: taskRows.length,
    todayTasks: taskRows.filter((task) => task.log_date === isoDate()),
    goalSummary: plan.goalSummary,
    phases: plan.phases,
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = asRecord(await req.json().catch(() => ({}))) ?? {};
    const deviceId = asString(payload.device_id ?? payload.deviceId);
    const supabase = adminClient();
    if (!supabase) {
      return jsonResponse({ error: "Supabase service role is not configured" }, 500);
    }

    const action = asString(payload.action);
    if (action === "active_goal") {
      if (!deviceId) {
        return jsonResponse({ error: "device_id is required" }, 400);
      }
      return jsonResponse(await fetchActiveGoal(supabase, deviceId));
    }
    if (action === "goal_milestones") {
      const goalId = asString(payload.goalId);
      if (!deviceId || !goalId) {
        return jsonResponse({ error: "device_id and goalId are required" }, 400);
      }
      const { data, error } = await supabase.from("goal_milestones")
        .select("id, week_number, title, description, target_date, is_completed")
        .eq("device_id", deviceId)
        .eq("goal_id", goalId)
        .order("week_number", { ascending: true });
      if (error) {
        throw new Error(error.message);
      }
      return jsonResponse({ milestones: data ?? [] });
    }
    if (action === "todays_goal_tasks") {
      if (!deviceId) {
        return jsonResponse({ error: "device_id is required" }, 400);
      }
      const state = await fetchActiveGoal(supabase, deviceId);
      return jsonResponse({ tasks: state.todaysTasks ?? [] });
    }

    return await createGoal(supabase, payload);
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
