-- Notes on project steps, readable and editable by everyone in the space
-- (same RLS as the step itself). Plain text, up to 2000 characters.
-- Who last changed the note, and when, is set by the database, never by
-- the client.

alter table public.project_items
  add column note text
    check (note is null or char_length(note) <= 2000),
  add column note_updated_at timestamptz,
  add column note_updated_by uuid
    references public.profiles (id) on delete set null;

create index project_items_note_updated_by_idx
  on public.project_items (note_updated_by);

-- Members may change the note; the stamp columns stay server-only.
grant update (note) on table public.project_items to authenticated;

create or replace function private.stamp_item_note()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.note is not null then
      new.note_updated_at := now();
      new.note_updated_by := auth.uid();
    else
      new.note_updated_at := null;
      new.note_updated_by := null;
    end if;
  elsif new.note is distinct from old.note then
    new.note_updated_at := now();
    new.note_updated_by := auth.uid();
  else
    new.note_updated_at := old.note_updated_at;
    new.note_updated_by := old.note_updated_by;
  end if;
  -- An empty note is no note.
  if new.note is not null and btrim(new.note) = '' then
    new.note := null;
  end if;
  return new;
end;
$$;

revoke all on function private.stamp_item_note() from public;

create trigger project_items_stamp_note
  before insert or update on public.project_items
  for each row execute function private.stamp_item_note();
