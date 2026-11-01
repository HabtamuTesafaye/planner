-- 012_projects: projects with checklist steps, shared inside a space, and
-- "plan for today" links from tasks to steps.

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  template text not null default 'blank'
    check (template in ('blank', 'client', 'launch', 'content', 'event')),
  status text not null default 'active' check (status in ('active', 'done')),
  created_by uuid default auth.uid()
    references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index projects_team_id_idx on public.projects (team_id);
create index projects_created_by_idx on public.projects (created_by);

create table public.project_items (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  -- Always the project's space (set by trigger). Kept on the row so RLS and
  -- realtime can filter by space directly.
  team_id uuid not null references public.teams (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  done boolean not null default false,
  done_at timestamptz,
  position integer not null default 0,
  created_by uuid default auth.uid()
    references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create index project_items_project_position_idx on public.project_items (project_id, position);
create index project_items_team_id_idx on public.project_items (team_id);
create index project_items_created_by_idx on public.project_items (created_by);

alter table public.projects enable row level security;
alter table public.project_items enable row level security;

revoke all on table public.projects from anon, authenticated;
revoke all on table public.project_items from anon, authenticated;
grant select, insert, delete on table public.projects to authenticated;
grant update (name, status) on table public.projects to authenticated;
grant select, insert, delete on table public.project_items to authenticated;
grant update (title, done, position) on table public.project_items to authenticated;

create trigger projects_set_updated_at
  before update on public.projects
  for each row execute function private.set_updated_at();

-- A step always belongs to its project's space, whatever the client sends.
create function private.set_item_team()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.team_id := (select p.team_id from public.projects p where p.id = new.project_id);
  return new;
end;
$$;

revoke all on function private.set_item_team() from public, anon, authenticated;

create trigger project_items_set_team
  before insert on public.project_items
  for each row execute function private.set_item_team();

-- done_at for steps works like for tasks.
create trigger project_items_set_done_at
  before insert or update on public.project_items
  for each row execute function private.set_task_done_at();

-- Tasks can come from a project step ("plan for today").
alter table public.tasks
  add column project_item_id uuid references public.project_items (id) on delete set null;
create index tasks_project_item_id_idx on public.tasks (project_item_id);

-- A linked step must be in the same space as the task.
create function private.check_task_item()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.project_item_id is not null and not exists (
    select 1 from public.project_items i
    where i.id = new.project_item_id and i.team_id = new.team_id
  ) then
    raise exception 'invalid_project_item' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function private.check_task_item() from public, anon, authenticated;

create trigger tasks_check_item
  before insert on public.tasks
  for each row execute function private.check_task_item();

-- Completing (or reopening) a planned task does the same to its step.
create function private.sync_task_to_item()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.project_item_id is not null and new.done is distinct from old.done then
    update public.project_items set done = new.done where id = new.project_item_id;
  end if;
  return new;
end;
$$;

revoke all on function private.sync_task_to_item() from public, anon, authenticated;

create trigger tasks_sync_item
  after update of done on public.tasks
  for each row execute function private.sync_task_to_item();

-- RLS: shared inside the space ------------------------------------------------
create policy "projects: members read" on public.projects
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "projects: members add as themselves" on public.projects
  for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "projects: members edit" on public.projects
  for update to authenticated
  using ((select private.is_team_member(team_id)))
  with check ((select private.is_team_member(team_id)));

create policy "projects: creator or owner deletes" on public.projects
  for delete to authenticated
  using (
    (select private.is_team_member(team_id))
    and (created_by = (select auth.uid()) or (select private.is_team_owner(team_id)))
  );

create policy "items: members read" on public.project_items
  for select to authenticated
  using ((select private.is_team_member(team_id)));

create policy "items: members add as themselves" on public.project_items
  for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and (select private.is_team_member(team_id))
  );

create policy "items: members edit" on public.project_items
  for update to authenticated
  using ((select private.is_team_member(team_id)))
  with check ((select private.is_team_member(team_id)));

create policy "items: creator or owner deletes" on public.project_items
  for delete to authenticated
  using (
    (select private.is_team_member(team_id))
    and (created_by = (select auth.uid()) or (select private.is_team_owner(team_id)))
  );

-- Live updates for the whole space.
alter publication supabase_realtime add table public.projects, public.project_items;
