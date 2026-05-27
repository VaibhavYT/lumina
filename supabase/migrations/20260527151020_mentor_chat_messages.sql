create table if not exists public.mentor_chat_messages (
  id uuid primary key default gen_random_uuid(),
  device_id text not null references public.profiles(device_id) on delete cascade,
  session_id text not null,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create index if not exists mentor_chat_messages_device_session_idx
on public.mentor_chat_messages(device_id, session_id, created_at);

alter table public.mentor_chat_messages enable row level security;

drop policy if exists mentor_chat_messages_device_access on public.mentor_chat_messages;
create policy mentor_chat_messages_device_access on public.mentor_chat_messages
for all
using (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id')
with check (device_id = current_setting('request.jwt.claims', true)::json ->> 'device_id');
