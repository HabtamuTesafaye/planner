-- 010_column_update_grants: least privilege for UPDATE.
--
-- Users may only change the columns the app edits. Ids, team, creator and
-- timestamps can never be rewritten through the API, on top of the RLS
-- policies and the keep_row_identity triggers.
--
-- weekly_goals, weekly_reviews and monthly_targets keep table-level UPDATE:
-- the app saves them with an upsert, which sets the key columns too. RLS
-- (own rows / own team) and the primary keys protect them.

revoke update on table public.tasks from authenticated;
grant update (title, day, done) on table public.tasks to authenticated;

revoke update on table public.contacts from authenticated;
grant update (name, business, channel, status, next_follow_up, price, notes)
  on table public.contacts to authenticated;

revoke update on table public.income_entries from authenticated;
grant update (month, amount, note) on table public.income_entries to authenticated;
