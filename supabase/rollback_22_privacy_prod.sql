-- rollback_22_privacy_prod.sql
-- Ripristina le regole di lettura/scrittura PRECEDENTI alla migrazione 22 (letture pubbliche aperte).
-- ATTENZIONE: riapre di nuovo la lettura pubblica di punteggi, acquisti, progressi, log e token delle squadre,
-- e la scrittura aperta su jackpot_plays. Usare solo in emergenza (es. app che non carica dopo la 22).

-- jackpot_plays
DROP POLICY IF EXISTS "Admin All Jackpot Plays" ON public.jackpot_plays;
DROP POLICY IF EXISTS "jackpot_plays_all_admin" ON public.jackpot_plays;
CREATE POLICY "jackpot_plays_all_admin" ON public.jackpot_plays FOR ALL TO public USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "jackpot_plays_select_all" ON public.jackpot_plays;
CREATE POLICY "jackpot_plays_select_all" ON public.jackpot_plays FOR SELECT TO public USING (true);

-- marketplace_transactions
DROP POLICY IF EXISTS "Own Target Or Admin Read Transactions" ON public.marketplace_transactions;
DROP POLICY IF EXISTS "Public Read Transactions" ON public.marketplace_transactions;
CREATE POLICY "Public Read Transactions" ON public.marketplace_transactions FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Secure SELECT Transactions" ON public.marketplace_transactions;
CREATE POLICY "Secure SELECT Transactions" ON public.marketplace_transactions FOR SELECT TO public
  USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

-- letture pubbliche
DROP POLICY IF EXISTS "Public Read Scores" ON public.scores;
CREATE POLICY "Public Read Scores" ON public.scores FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Public Read Cattiveria" ON public.cattiveria_ledger;
CREATE POLICY "Public Read Cattiveria" ON public.cattiveria_ledger FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Public Read Submissions" ON public.submissions;
CREATE POLICY "Public Read Submissions" ON public.submissions FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Public Read Progress" ON public.team_progress;
CREATE POLICY "Public Read Progress" ON public.team_progress FOR SELECT TO public USING (true);

-- scritture dirette sui progressi / emoji
DROP POLICY IF EXISTS "Team INSERT Progress" ON public.team_progress;
CREATE POLICY "Team INSERT Progress" ON public.team_progress FOR INSERT TO public WITH CHECK (team_id = public.current_team_id());
DROP POLICY IF EXISTS "Team Insert Own Emoji Movies" ON public.team_emoji_movies;
CREATE POLICY "Team Insert Own Emoji Movies" ON public.team_emoji_movies FOR INSERT TO public
  WITH CHECK (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));
DROP POLICY IF EXISTS "Team Update Own Emoji Movies" ON public.team_emoji_movies;
CREATE POLICY "Team Update Own Emoji Movies" ON public.team_emoji_movies FOR UPDATE TO public
  USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

-- locandine, log attivita', report
DROP POLICY IF EXISTS "Own Or Admin Read Team Posters" ON public.team_posters;
DROP POLICY IF EXISTS "Public Read Team Posters" ON public.team_posters;
CREATE POLICY "Public Read Team Posters" ON public.team_posters FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Own Or Admin Read Activity Log" ON public.activity_log;
DROP POLICY IF EXISTS "Public Read Activity Log" ON public.activity_log;
CREATE POLICY "Public Read Activity Log" ON public.activity_log FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Admin Read Report" ON public.game_report;
DROP POLICY IF EXISTS "Public Read Report" ON public.game_report;
CREATE POLICY "Public Read Report" ON public.game_report FOR SELECT TO public USING (true);

-- teams
DROP POLICY IF EXISTS "Own Or Admin Read Teams" ON public.teams;
DROP POLICY IF EXISTS "Public Read Teams" ON public.teams;
CREATE POLICY "Public Read Teams" ON public.teams FOR SELECT TO public USING (true);
