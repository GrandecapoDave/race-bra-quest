BEGIN;

-- ==========================================================
-- AGGIORNAMENTO ENIGMI ESATTI DE LA BANCA (DA LOCALHOST)
-- ==========================================================

CREATE OR REPLACE FUNCTION public.get_bank_state(p_team_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_answers JSONB;
  v_questions JSONB;
  v_progress RECORD;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  -- Recupera risposte corrette del team
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'question_number', question_number,
    'answer', answer,
    'extracted_letter', extracted_letter
  ) ORDER BY question_number), '[]'::jsonb) INTO v_answers
  FROM public.team_bank_answers
  WHERE team_id = p_team_id;

  -- Domande originali da localhost / local_database.json
  v_questions := '[
    {"question_number": 1, "question_text": "Lo usi per prelevare contanti senza fare la fila allo sportello", "length": 8},
    {"question_number": 2, "question_text": "Il codice segreto a 4 cifre che non devi mai dire a nessuno", "length": 3},
    {"question_number": 3, "question_text": "La moneta che hai in tasca in tutta Europa", "length": 4},
    {"question_number": 4, "question_text": "La scadenza mensile del mutuo, incubo di ogni famiglia", "length": 4}
  ]'::jsonb;

  SELECT * INTO v_progress FROM public.team_progress
  WHERE team_id = p_team_id AND challenge_id = 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';

  RETURN jsonb_build_object(
    'progress', jsonb_build_object('status', COALESCE(v_progress.stato, 'locked')),
    'answers', v_answers,
    'all_questions', v_questions
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_bank_answer(
  p_question_number INTEGER,
  p_answer TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_correct_answer TEXT;
  v_extracted_letter CHAR(1);
  v_correct BOOLEAN := false;
  v_challenge_completed BOOLEAN := false;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Risposte esatte originali:
  -- 1: BANCOMAT (B)
  -- 2: PIN (P)
  -- 3: EURO (E)
  -- 4: RATA (R)
  IF p_question_number = 1 THEN 
    v_correct_answer := 'BANCOMAT';
    v_extracted_letter := 'B';
  ELSIF p_question_number = 2 THEN 
    v_correct_answer := 'PIN';
    v_extracted_letter := 'P';
  ELSIF p_question_number = 3 THEN 
    v_correct_answer := 'EURO';
    v_extracted_letter := 'E';
  ELSIF p_question_number = 4 THEN 
    v_correct_answer := 'RATA';
    v_extracted_letter := 'R';
  ELSE 
    RAISE EXCEPTION 'Numero domanda non valido';
  END IF;

  v_correct := (UPPER(TRIM(p_answer)) = v_correct_answer);

  IF v_correct THEN
    INSERT INTO public.team_bank_answers (team_id, question_number, answer, extracted_letter)
    VALUES (v_team_id, p_question_number, UPPER(TRIM(p_answer)), v_extracted_letter)
    ON CONFLICT (team_id, question_number) DO UPDATE
    SET answer = EXCLUDED.answer, extracted_letter = EXCLUDED.extracted_letter;

    -- Assegna 5 punti per ogni enigma risolto
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, 5, 'challenge_points', 'Risposta esatta enigma ' || p_question_number || ' - La Banca')
    ON CONFLICT DO NOTHING;

    -- Se ha completato tutti e 4 gli enigmi, segna la sfida completata
    IF (SELECT COUNT(*) FROM public.team_bank_answers WHERE team_id = v_team_id) = 4 THEN
      v_challenge_completed := true;
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team_id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE
      SET stato = 'completed', completata_il = now();
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'correct', v_correct,
    'letter', v_extracted_letter,
    'challenge_completed', v_challenge_completed
  );
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
