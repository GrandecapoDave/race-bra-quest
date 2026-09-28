-- 40_fix_admin_reset_bank.sql
-- Bug (silenzioso, pericoloso): "Reset Banca" cancellava da team_answers, che e' la tabella del Quiz Bra
-- (Tappa 1), non quella della Banca. Effetto reale: ogni volta che veniva usato, azzerava per errore le
-- risposte del QUIZ della squadra (prova non collegata alla Banca), mentre le vere risposte della Banca
-- (team_bank_answers) restavano intatte - quindi la squadra non poteva nemmeno ripetere la prova come previsto,
-- perche' submit_bank_answer avrebbe visto le domande gia' segnate come risposte.
-- Ora cancella davvero le risposte della Banca (team_bank_answers), senza toccare il Quiz.

CREATE OR REPLACE FUNCTION public.admin_reset_bank(p_team_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  -- Elimina le risposte vere della Banca (non il Quiz Bra, che usa una tabella diversa)
  DELETE FROM public.team_bank_answers WHERE team_id = p_team_id;

  -- Resetta progresso
  DELETE FROM public.team_progress WHERE team_id = p_team_id AND challenge_id = v_challenge_id;

  -- Elimina punteggio associato
  DELETE FROM public.scores WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
END;
$function$;
