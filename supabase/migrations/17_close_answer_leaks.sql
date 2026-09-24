-- 17_close_answer_leaks.sql
-- Chiude letture/scritture pubbliche che esponevano le risposte del gioco:
--  * game_final_code (PIN finale): RLS disattivata e permessi completi ad anon/authenticated -> nessun accesso diretto
--    (le RPC SECURITY DEFINER e l'admin tramite admin_edit_secret_code_settings continuano a funzionare)
--  * quiz_questions: la colonna correct_answer_index era leggibile da tutti -> solo admin (le squadre usano quiz_questions_public)
--  * team_code_parts / team_code_matches / code_purchase_transactions: lettura solo per la propria squadra o admin

ALTER TABLE public.game_final_code ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.game_final_code FROM anon, authenticated;

DROP POLICY IF EXISTS "Public Read Quiz Questions" ON public.quiz_questions;
CREATE POLICY "Admin Read Quiz Questions" ON public.quiz_questions
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Public Read Code Parts" ON public.team_code_parts;
CREATE POLICY "Own Or Admin Read Code Parts" ON public.team_code_parts
  FOR SELECT TO authenticated
  USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Public Read Code Matches" ON public.team_code_matches;
CREATE POLICY "Own Or Admin Read Code Matches" ON public.team_code_matches
  FOR SELECT TO authenticated
  USING (buyer_team_id = public.current_team_id() OR seller_team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Public Read Code Purchases" ON public.code_purchase_transactions;
CREATE POLICY "Own Or Admin Read Code Purchases" ON public.code_purchase_transactions
  FOR SELECT TO authenticated
  USING (buyer_team_id = public.current_team_id() OR seller_team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));
