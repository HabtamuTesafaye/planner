-- 002_teams: teams, memberships (one team per user) and the join code
-- generator.

-- Join codes: 8 characters from an alphabet without look-alikes
-- (no 0/O, 1/I/L).
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 60),
  join_code text not null unique
    check (join_code ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$'),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create index teams_created_by_idx on public.teams (created_by);

create table public.team_members (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (team_id, user_id),
  -- v1: one team per user.
  unique (user_id)
);

alter table public.teams enable row level security;
alter table public.team_members enable row level security;

revoke all on table public.teams from anon, authenticated;
revoke all on table public.team_members from anon, authenticated;

-- Teams and memberships are created and changed only through the RPCs in
-- 008_rpcs. The app can read them, and the owner can rename the team.
grant select, update (name) on table public.teams to authenticated;
grant select on table public.team_members to authenticated;

-- Random 8-character code from a cryptographic source. Uniqueness is
-- enforced by the unique constraint; create_team retries on a collision.
create function private.generate_join_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  bytes bytea := extensions.gen_random_bytes(8);
  code text := '';
begin
  for i in 0..7 loop
    code := code || substr(alphabet, (get_byte(bytes, i) % 31) + 1, 1);
  end loop;
  return code;
end;
$$;

revoke all on function private.generate_join_code() from public, anon, authenticated;
