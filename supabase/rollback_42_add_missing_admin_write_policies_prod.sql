-- Rollback della migrazione 42_add_missing_admin_write_policies.sql
DROP POLICY IF EXISTS "Admin Write Challenges" ON public.challenges;
DROP POLICY IF EXISTS "Admin Write Marketplace Transactions" ON public.marketplace_transactions;
DROP POLICY IF EXISTS "Admin Delete Scores" ON public.scores;
