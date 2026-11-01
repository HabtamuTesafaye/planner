-- 013_last_team_soft_link: profiles.last_team_id is a plain id, not a
-- foreign key.
--
-- Why: deleting an account deletes its personal space. With a foreign key
-- (ON DELETE SET NULL), that tried to update the profile row that was being
-- deleted, and the delete failed. The column is already validated by the
-- check_last_team trigger on every change, and the app falls back to the
-- personal space when it points at a space the user is no longer in.

alter table public.profiles drop constraint profiles_last_team_id_fkey;
