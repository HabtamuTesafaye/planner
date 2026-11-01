-- 003_tasks: daily tasks, max 3 per person per day (enforced here; the app
-- also checks, but the database is the source of truth).

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  day date not null,
  done boolean not null default false,
  done_at timestamptz,
  created_at timestamptz not null default now()
);

create index tasks_team_id_idx on public.tasks (team_id);
create index tasks_user_day_idx on public.tasks (user_id, day);

alter table public.tasks enable row level security;
revoke all on table public.tasks from anon, authenticated;
grant select, insert, update, delete on table public.tasks to authenticated;

-- Rejects a 4th task for the same user and day. Runs as definer so the
-- count sees all of the user's rows, even ones RLS would hide (for example
-- tasks left in a previous team). An advisory lock per (user, day) stops two
-- simultaneous inserts from both passing the check.
create function private.enforce_task_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
     and new.user_id = old.user_id
     and new.day = old.day then
    return new;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(new.user_id::text || ':' || new.day::text, 0)
  );

  if (
    select count(*)
    from public.tasks t
    where t.user_id = new.user_id
      and t.day = new.day
      and t.id <> new.id
  ) >= 3 then
    raise exception 'task_limit_reached'
      using errcode = 'P0001',
            hint = 'Three is the limit. Finish or remove one first.';
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_task_limit() from public, anon, authenticated;

create trigger tasks_enforce_limit
  before insert or update of user_id, day on public.tasks
  for each row execute function private.enforce_task_limit();

-- done_at is owned by the database: set when a task becomes done, kept while
-- it stays done, cleared when it is undone. Clients cannot fake it.
create function private.set_task_done_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.done_at := case when new.done then now() end;
  elsif new.done and not old.done then
    new.done_at := now();
  elsif new.done then
    new.done_at := old.done_at;
  else
    new.done_at := null;
  end if;
  return new;
end;
$$;

revoke all on function private.set_task_done_at() from public, anon, authenticated;

create trigger tasks_set_done_at
  before insert or update on public.tasks
  for each row execute function private.set_task_done_at();
