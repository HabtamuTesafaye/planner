-- Where an income entry came from ("Salary", "Café client"), so a space
-- with several sources can see each one. Optional; same RLS as the entry.

alter table public.income_entries
  add column source text not null default ''
    check (char_length(source) <= 60);

grant update (source) on table public.income_entries to authenticated;

create index income_entries_team_source_idx
  on public.income_entries (team_id, source);
