create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  device_id text unique not null,
  display_name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  device_id text not null references public.profiles(device_id),
  log_date date not null,
  mood integer check (mood between 1 and 5),
  mood_note text,
  energy integer check (energy between 1 and 5),
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(device_id, log_date)
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  device_id text not null,
  log_date date not null,
  title text not null,
  is_completed boolean default false,
  priority text default 'normal' check (priority in ('high', 'normal', 'low')),
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  device_id text not null,
  name text not null,
  emoji text,
  color_hex text,
  frequency text default 'daily',
  custom_days text[],
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.habit_completions (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid references public.habits(id) on delete cascade,
  device_id text not null,
  completion_date date not null,
  created_at timestamptz default now(),
  unique(habit_id, completion_date)
);

create table if not exists public.mentor_insights (
  id uuid primary key default gen_random_uuid(),
  device_id text not null,
  insight_type text not null,
  headline text,
  body text not null,
  metadata jsonb,
  is_dismissed boolean default false,
  generated_at timestamptz default now(),
  expires_at timestamptz
);

create index if not exists profiles_device_id_idx on public.profiles(device_id);
create index if not exists daily_logs_device_id_log_date_idx on public.daily_logs(device_id, log_date desc);
create index if not exists tasks_device_id_log_date_idx on public.tasks(device_id, log_date desc);
create index if not exists habits_device_id_idx on public.habits(device_id);
create index if not exists habit_completions_device_date_idx on public.habit_completions(device_id, completion_date desc);
create index if not exists mentor_insights_device_generated_idx on public.mentor_insights(device_id, generated_at desc);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists daily_logs_set_updated_at on public.daily_logs;
create trigger daily_logs_set_updated_at
before update on public.daily_logs
for each row execute function public.set_updated_at();

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
before update on public.tasks
for each row execute function public.set_updated_at();

drop trigger if exists habits_set_updated_at on public.habits;
create trigger habits_set_updated_at
before update on public.habits
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.daily_logs enable row level security;
alter table public.tasks enable row level security;
alter table public.habits enable row level security;
alter table public.habit_completions enable row level security;
alter table public.mentor_insights enable row level security;

drop policy if exists profiles_device_access on public.profiles;
create policy profiles_device_access on public.profiles
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');

drop policy if exists daily_logs_device_access on public.daily_logs;
create policy daily_logs_device_access on public.daily_logs
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');

drop policy if exists tasks_device_access on public.tasks;
create policy tasks_device_access on public.tasks
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');

drop policy if exists habits_device_access on public.habits;
create policy habits_device_access on public.habits
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');

drop policy if exists habit_completions_device_access on public.habit_completions;
create policy habit_completions_device_access on public.habit_completions
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');

drop policy if exists mentor_insights_device_access on public.mentor_insights;
create policy mentor_insights_device_access on public.mentor_insights
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');
