-- 004_goals_reviews: goal of the week and weekly reviews. Weeks start on
-- Monday (ISO day 1).

create table public.weekly_goals (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  week_start date not null check (extract(isodow from week_start) = 1),
  goal text not null check (char_length(btrim(goal)) between 1 and 200),
  updated_at timestamptz not null default now(),
  primary key (team_id, user_id, week_start)
);

create index weekly_goals_user_id_idx on public.weekly_goals (user_id);

create table public.weekly_reviews (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  week_start date not null check (extract(isodow from week_start) = 1),
  did text not null default '' check (char_length(did) <= 1000),
  blocked text not null default '' check (char_length(blocked) <= 1000),
  next_goal text not null default '' check (char_length(next_goal) <= 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, user_id, week_start)
);

create index weekly_reviews_user_id_idx on public.weekly_reviews (user_id);

alter table public.weekly_goals enable row level security;
alter table public.weekly_reviews enable row level security;

revoke all on table public.weekly_goals from anon, authenticated;
revoke all on table public.weekly_reviews from anon, authenticated;

grant select, insert, update, delete on table public.weekly_goals to authenticated;
grant select, insert, update, delete on table public.weekly_reviews to authenticated;

-- Shared helper: keeps updated_at current on every update.
create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.set_updated_at() from public, anon, authenticated;

create trigger weekly_goals_set_updated_at
  before update on public.weekly_goals
  for each row execute function private.set_updated_at();

create trigger weekly_reviews_set_updated_at
  before update on public.weekly_reviews
  for each row execute function private.set_updated_at();
