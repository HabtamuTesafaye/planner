-- The server's clock for the app, and a guard on task days.
--
-- The app decides "today" from the server's time in the phone's time zone,
-- so a wrong phone clock does not move tasks to the wrong day. The database
-- also refuses a task day that cannot be today anywhere on Earth (more than
-- one day from the UTC date), so the 3-a-day limit can't be dodged by
-- changing the phone's date.

create function public.server_now()
returns timestamptz
language sql
stable
set search_path = ''
as $$ select now() $$;

revoke all on function public.server_now() from public, anon;
grant execute on function public.server_now() to authenticated;

create function private.check_task_day()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  utc_today date := (now() at time zone 'utc')::date;
begin
  if new.day not between utc_today - 1 and utc_today + 1 then
    raise exception 'invalid_day'
      using hint = 'A task day must be today in some time zone.';
  end if;
  return new;
end;
$$;

revoke all on function private.check_task_day() from public, anon, authenticated;

-- Only when a day is set or changed: finishing an old task stays possible.
create trigger tasks_check_day
  before insert or update of day on public.tasks
  for each row execute function private.check_task_day();
