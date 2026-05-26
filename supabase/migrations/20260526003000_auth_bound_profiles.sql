alter table public.profiles
add column if not exists user_id uuid unique;

create index if not exists profiles_user_id_idx on public.profiles(user_id);
