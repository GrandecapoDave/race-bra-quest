-- 22_privacy_restrict.sql  (PASSO 2 di 2 - da applicare DOPO che il nuovo frontend e' online)
-- Privacy tra squadre. Finora le regole "Secure SELECT" (solo la propria squadra) erano annullate da regole "Public Read" con condizione true:
-- una squadra poteva leggere punteggi, acquisti (chi ha Scudo/Polizza), progressi, log e classifica finale di TUTTE le altre,
-- e chiunque con la chiave pubblica poteva scrivere in jackpot_plays. Qui si chiude tutto. Le RPC SECURITY DEFINER e la Regia (admin) non cambiano.
-- Richiede il passo 1 (vista teams_public) gia' applicato.


-- 1) jackpot_plays: regola "ALL true" = scrittura aperta a chiunque
DROP POLICY IF EXISTS "jackpot_plays_all_admin" ON public.jackpot_plays;
DROP POLICY IF EXISTS "jackpot_plays_select_all" ON public.jackpot_plays;
DROP POLICY IF EXISTS "Admin All Jackpot Plays" ON public.jackpot_plays;
CREATE POLICY "Admin All Jackpot Plays" ON public.jackpot_plays
  FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::text))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::text));

-- 2) Acquisti: la squadra vede i propri e quelli in cui e' bersaglio (malus subiti)
DROP POLICY IF EXISTS "Public Read Transactions" ON public.marketplace_transactions;
DROP POLICY IF EXISTS "Secure SELECT Transactions" ON public.marketplace_transactions;
DROP POLICY IF EXISTS "Own Target Or Admin Read Transactions" ON public.marketplace_transactions;
CREATE POLICY "Own Target Or Admin Read Transactions" ON public.marketplace_transactions
  FOR SELECT TO authenticated
  USING (team_id = public.current_team_id() OR target_team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

-- 3) Letture pubbliche da chiudere (restano le regole "Secure SELECT": propria squadra o admin)
DROP POLICY IF EXISTS "Public Read Scores" ON public.scores;
DROP POLICY IF EXISTS "Public Read Cattiveria" ON public.cattiveria_ledger;
DROP POLICY IF EXISTS "Public Read Submissions" ON public.submissions;
DROP POLICY IF EXISTS "Public Read Progress" ON public.team_progress;

-- 4) team_progress: lo stato si scrive solo tramite RPC (start_challenge / complete_challenge ...), non piu' con INSERT diretto
--    (una squadra poteva segnare 'completed' una prova senza svolgerla e saltare la sequenza)
DROP POLICY IF EXISTS "Team INSERT Progress" ON public.team_progress;

-- 5) team_emoji_movies: scritture solo tramite submit_emoji_movie_answer
DROP POLICY IF EXISTS "Team Insert Own Emoji Movies" ON public.team_emoji_movies;
DROP POLICY IF EXISTS "Team Update Own Emoji Movies" ON public.team_emoji_movies;

-- 6) Locandine, log attivita', report finale: solo proprie / admin
DROP POLICY IF EXISTS "Public Read Team Posters" ON public.team_posters;
DROP POLICY IF EXISTS "Own Or Admin Read Team Posters" ON public.team_posters;
CREATE POLICY "Own Or Admin Read Team Posters" ON public.team_posters
  FOR SELECT TO authenticated
  USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Public Read Activity Log" ON public.activity_log;
DROP POLICY IF EXISTS "Admin Read Activity Log" ON public.activity_log;
DROP POLICY IF EXISTS "Own Or Admin Read Activity Log" ON public.activity_log;
DROP POLICY IF EXISTS "Own Or Admin Read Activity Log" ON public.activity_log;
CREATE POLICY "Own Or Admin Read Activity Log" ON public.activity_log
  FOR SELECT TO authenticated
  USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Public Read Report" ON public.game_report;
DROP POLICY IF EXISTS "Admin Read Report" ON public.game_report;
CREATE POLICY "Admin Read Report" ON public.game_report
  FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::text));

-- 7) teams: ogni squadra vede per intero solo la propria riga (token, freeze...). Per nomi/avatar delle altre c'e' la vista teams_public.
DROP POLICY IF EXISTS "Public Read Teams" ON public.teams;
DROP POLICY IF EXISTS "Own Or Admin Read Teams" ON public.teams;
CREATE POLICY "Own Or Admin Read Teams" ON public.teams
  FOR SELECT TO authenticated
  USING (owner_id = auth.uid() OR id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

