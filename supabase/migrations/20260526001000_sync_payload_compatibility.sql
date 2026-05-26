alter table public.daily_logs
add column if not exists completed_habit_ids text[] default '{}';

alter table public.habit_completions
add column if not exists local_habit_id text;

create unique index if not exists habit_completions_device_local_date_idx
on public.habit_completions(device_id, local_habit_id, completion_date)
where local_habit_id is not null;
