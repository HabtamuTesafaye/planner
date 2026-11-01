-- Google sign-in: Google sends the person's name as full_name (or name),
-- not display_name. Use it, so a new Google account is greeted by name
-- instead of the part of the email before the @.
-- Order: display_name (email sign-up) > full_name > name > email prefix.

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_name text := btrim(coalesce(
    nullif(btrim(v_meta ->> 'display_name'), ''),
    nullif(btrim(v_meta ->> 'full_name'), ''),
    nullif(btrim(v_meta ->> 'name'), ''),
    ''
  ));
begin
  if v_name = '' then
    v_name := split_part(coalesce(new.email, 'Member'), '@', 1);
  end if;
  insert into public.profiles (id, display_name)
  values (new.id, left(v_name, 60));
  perform private.create_personal_space(new.id);
  return new;
end;
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;
