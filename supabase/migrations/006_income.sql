-- 006_income: shared monthly income entries (ETB) and monthly targets.
-- A month is stored as its first day.

create table public.income_entries (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  -- Who added it. Kept as null if they delete their account.
  user_id uuid default auth.uid()
    references public.profiles (id) on delete set null,
  month date not null check (extract(day from month) = 1),
  amount numeric(12, 2) not null check (amount > 0),
  note text not null default '' check (char_length(note) <= 200),
  created_at timestamptz not null default now()
);

create index income_entries_team_month_idx on public.income_entries (team_id, month);
create index income_entries_user_id_idx on public.income_entries (user_id);

create table public.monthly_targets (
  team_id uuid not null references public.teams (id) on delete cascade,
  month date not null check (extract(day from month) = 1),
  target numeric(12, 2) not null check (target > 0),
  primary key (team_id, month)
);

alter table public.income_entries enable row level security;
alter table public.monthly_targets enable row level security;

revoke all on table public.income_entries from anon, authenticated;
revoke all on table public.monthly_targets from anon, authenticated;

grant select, insert, update, delete on table public.income_entries to authenticated;
grant select, insert, update, delete on table public.monthly_targets to authenticated;

create trigger income_entries_keep_identity
  before update on public.income_entries
  for each row
  execute function private.keep_row_identity('team_id', 'user_id', 'created_at');

create trigger monthly_targets_keep_identity
  before update on public.monthly_targets
  for each row execute function private.keep_row_identity('team_id');
