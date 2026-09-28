-- 38_fix_admin_edit_bank_answer.sql
-- Bug 1 (blocca sempre): la Regia invia p_question_number, la funzione si aspettava p_question_id e un
-- p_answer obbligatorio mai inviato -> "Could not find the function ... in the schema cache", non ha mai funzionato.
-- Bug 2 (piu' grave, silenzioso): anche correggendo solo i parametri, la funzione scriveva su team_answers e
-- quiz_questions (le tabelle del Quiz Bra, Tappa 1), creando una domanda finta "Banca Q1" - un sistema
-- completamente scollegato da quello vero della Banca. Le risposte reali della Banca sono in team_bank_answers
-- (submit_bank_answer): correggere una risposta da questo pannello non avrebbe mai toccato il punteggio o
-- l'avanzamento reali della squadra. Rischio aggiuntivo: la vecchia INSERT INTO team_answers cancellava/toccava
-- involontariamente le risposte del Quiz Bra della stessa squadra (tabella condivisa con un'altra prova).
-- Ora la funzione lavora sulle tabelle vere e replica esattamente l'effetto di una risposta esatta/rimossa,
-- inclusi i punti e, se e' la quarta risposta esatta, il completamento della prova (apply_completion_effects,
-- la stessa funzione usata da submit_bank_answer).

CREATE OR REPLACE FUNCTION public.admin_edit_bank_answer(
  p_team_id uuid,
  p_question_number integer,
  p_correct boolean,
  p_admin_id uuid,
  p_answer text DEFAULT NULL::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
  v_letter CHAR(1);
  v_was_correct BOOLEAN;
  v_now_count INTEGER;
  v_stage_completed_now BOOLEAN := false;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
  IF p_question_number NOT BETWEEN 1 AND 4 THEN
    RAISE EXCEPTION 'Numero domanda non valido: deve essere tra 1 e 4';
  END IF;

  v_letter := CASE p_question_number WHEN 1 THEN 'B' WHEN 2 THEN 'P' WHEN 3 THEN 'E' WHEN 4 THEN 'R' END;

  SELECT EXISTS (
    SELECT 1 FROM public.team_bank_answers WHERE team_id = p_team_id AND question_number = p_question_number
  ) INTO v_was_correct;

  IF p_correct AND NOT v_was_correct THEN
    INSERT INTO public.team_bank_answers (team_id, question_number, answer, extracted_letter)
    VALUES (p_team_id, p_question_number, COALESCE(NULLIF(TRIM(p_answer), ''), '(corretto dalla Regia)'), v_letter)
    ON CONFLICT (team_id, question_number) DO UPDATE
    SET answer = EXCLUDED.answer, extracted_letter = EXCLUDED.extracted_letter;

    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (p_team_id, v_challenge_id, 5, 'challenge_points', 'Risposta esatta enigma ' || p_question_number || ' - La Banca')
    ON CONFLICT DO NOTHING;

    SELECT COUNT(*) INTO v_now_count FROM public.team_bank_answers WHERE team_id = p_team_id;
    IF v_now_count = 4 THEN
      v_stage_completed_now := true;
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (p_team_id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = now();
      PERFORM public.apply_completion_effects(p_team_id, v_challenge_id);
    END IF;

  ELSIF NOT p_correct AND v_was_correct THEN
    -- Revoca una risposta segnata per errore come esatta. Non ripristina eventuali effetti di completamento
    -- tappa gia' scattati (bonus 2X, malus Dimezza, token di arrivo tappa): se la Banca era l'ultima prova
    -- della tappa gia' completata, quegli effetti vanno sistemati a mano dalla Regia.
    DELETE FROM public.team_bank_answers WHERE team_id = p_team_id AND question_number = p_question_number;
    DELETE FROM public.scores
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND tipo_modificatore = 'challenge_points'
      AND motivo = 'Risposta esatta enigma ' || p_question_number || ' - La Banca';

    UPDATE public.team_progress SET stato = 'in_progress', completata_il = NULL
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND stato = 'completed';
  END IF;

  RETURN jsonb_build_object(
    'success', true, 'question_number', p_question_number, 'correct', p_correct,
    'stage_completed_now', v_stage_completed_now
  );
END;
$function$;
REVOKE ALL ON FUNCTION public.admin_edit_bank_answer(uuid, integer, boolean, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_edit_bank_answer(uuid, integer, boolean, uuid, text) TO authenticated;
DROP FUNCTION IF EXISTS public.admin_edit_bank_answer(uuid, integer, text, boolean, uuid);
