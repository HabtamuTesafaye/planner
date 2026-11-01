-- 005_contacts: the shared outreach pipeline.

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  -- Creator. Kept when they delete their account (set null) so the team
  -- keeps the lead.
  owner_id uuid default auth.uid()
    references public.profiles (id) on delete set null,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  business text not null default '' check (char_length(business) <= 120),
  channel text not null default '' check (char_length(channel) <= 40),
  status text not null default 'contacted'
    check (status in ('contacted', 'replied', 'meeting', 'proposal', 'paid', 'dead')),
  next_follow_up date,
  price numeric(12, 2) check (price is null or price >= 0),
  notes text not null default '' check (char_length(notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Covers lookups by team_id alone too (leading column).
create index contacts_team_follow_up_idx on public.contacts (team_id, next_follow_up);
create index contacts_owner_id_idx on public.contacts (owner_id);

alter table public.contacts enable row level security;
revoke all on table public.contacts from anon, authenticated;
grant select, insert, update, delete on table public.contacts to authenticated;

create trigger contacts_set_updated_at
  before update on public.contacts
  for each row execute function private.set_updated_at();

-- Shared helper: blocks changes to the listed columns on UPDATE, so a team
-- member can edit a shared row but cannot move it to another team, take
-- over its creator, or rewrite its history. Changes made by foreign-key
-- actions (for example ON DELETE SET NULL when a user is deleted) run at
-- trigger depth > 1 and are allowed.
create function private.keep_row_identity()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  col text;
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  foreach col in array tg_argv loop
    if (to_jsonb(new) -> col) is distinct from (to_jsonb(old) -> col) then
      raise exception 'immutable_column'
        using errcode = 'P0001', detail = col;
    end if;
  end loop;
  return new;
end;
$$;

revoke all on function private.keep_row_identity() from public, anon, authenticated;

create trigger contacts_keep_identity
  before update on public.contacts
  for each row
  execute function private.keep_row_identity('team_id', 'owner_id', 'created_at');
