-- 009_realtime: live updates for tasks, contacts and income entries.
-- Realtime applies the same RLS SELECT policies, so a client only receives
-- changes for rows it is allowed to read (its own team).

alter publication supabase_realtime
  add table public.tasks, public.contacts, public.income_entries;
