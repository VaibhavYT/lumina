create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema extensions;

alter table public.profiles
add column if not exists fcm_token text;

alter table public.tasks
add column if not exists metadata jsonb default '{}'::jsonb;

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  device_id text not null references public.profiles(device_id),
  title text not null,
  description text,
  target_date date not null,
  status text default 'active' check (status in ('active', 'completed', 'abandoned', 'paused')),
  health_score integer default 100,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.goal_milestones (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid references public.goals(id) on delete cascade,
  device_id text not null references public.profiles(device_id),
  week_number integer not null,
  title text not null,
  description text,
  target_date date not null,
  is_completed boolean default false,
  created_at timestamptz default now()
);

alter table public.tasks
add column if not exists goal_id uuid references public.goals(id) on delete set null;

create index if not exists goals_device_status_idx on public.goals(device_id, status, created_at desc);
create index if not exists goal_milestones_goal_week_idx on public.goal_milestones(goal_id, week_number);
create index if not exists tasks_goal_log_date_idx on public.tasks(goal_id, log_date);

drop trigger if exists goals_set_updated_at on public.goals;
create trigger goals_set_updated_at
before update on public.goals
for each row execute function public.set_updated_at();

alter table public.goals enable row level security;
alter table public.goal_milestones enable row level security;

drop policy if exists goals_device_access on public.goals;
create policy goals_device_access on public.goals
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');

drop policy if exists goal_milestones_device_access on public.goal_milestones;
create policy goal_milestones_device_access on public.goal_milestones
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');
