alter table public.habits
add column if not exists local_habit_id text;

create unique index if not exists habits_device_local_id_idx
on public.habits(device_id, local_habit_id)
where local_habit_id is not null;
