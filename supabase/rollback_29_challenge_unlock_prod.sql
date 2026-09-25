-- rollback_29_challenge_unlock_prod.sql
-- Ripristina le 8 funzioni come erano prima della migrazione 29 (prova sbloccata lato server) e rimuove assert_challenge_unlocked.
-- Definizioni prese da Production (identiche a Staging) il 2026-09-25.

CREATE OR REPLACE FUNCTION public.submit_quiz_answer(p_question uuid, p_selected integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_question RECORD;
  v_correct BOOLEAN;
  v_points INTEGER := 0;
  v_prev_correct BOOLEAN := false;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_question FROM public.quiz_questions WHERE id = p_question;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('correct', false, 'points', 0, 'error', 'Domanda non trovata');
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext('quiz:' || v_team_id::text || ':' || p_question::text));
  SELECT EXISTS (SELECT 1 FROM public.team_answers WHERE team_id = v_team_id AND question_id = p_question AND correct) INTO v_prev_correct;

  v_correct := (p_selected = v_question.correct_answer_index);
  v_points := CASE WHEN v_correct THEN v_question.points ELSE 0 END;

  -- Upsert risposta (UNIQUE su team_id, question_id)
  INSERT INTO public.team_answers (team_id, question_id, selected_answer, correct)
  VALUES (v_team_id, p_question, p_selected, v_correct)
  ON CONFLICT (team_id, question_id) DO UPDATE
    SET selected_answer = EXCLUDED.selected_answer, correct = EXCLUDED.correct;

  -- Assegna punti se corretto
  IF v_correct AND v_points > 0 AND NOT v_prev_correct THEN
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_question.challenge_id, v_points, 'challenge_points', 'Risposta corretta al quiz');
  END IF;

  RETURN jsonb_build_object('correct', v_correct, 'points', v_points);
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_bank_answer(p_question_number integer, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_correct_answer TEXT;
  v_extracted_letter CHAR(1);
  v_correct BOOLEAN := false;
  v_challenge_completed BOOLEAN := false;
  v_already_answered BOOLEAN := false;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
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
    PERFORM pg_advisory_xact_lock(hashtext('bank:' || v_team_id::text || ':' || p_question_number::text));
    SELECT EXISTS (SELECT 1 FROM public.team_bank_answers WHERE team_id = v_team_id AND question_number = p_question_number) INTO v_already_answered;

    INSERT INTO public.team_bank_answers (team_id, question_number, answer, extracted_letter)
    VALUES (v_team_id, p_question_number, UPPER(TRIM(p_answer)), v_extracted_letter)
    ON CONFLICT (team_id, question_number) DO UPDATE
    SET answer = EXCLUDED.answer, extracted_letter = EXCLUDED.extracted_letter;

    -- Assegna 5 punti per ogni enigma risolto
    IF NOT v_already_answered THEN
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, 5, 'challenge_points', 'Risposta esatta enigma ' || p_question_number || ' - La Banca')
    ON CONFLICT DO NOTHING;
    END IF;

    -- Se ha completato tutti e 4 gli enigmi, segna la sfida completata
    IF (SELECT COUNT(*) FROM public.team_bank_answers WHERE team_id = v_team_id) = 4 THEN
      v_challenge_completed := true;
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team_id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE
      SET stato = 'completed', completata_il = now();

      PERFORM public.apply_completion_effects(v_team_id, v_challenge_id);
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'correct', v_correct,
    'letter', v_extracted_letter,
    'challenge_completed', v_challenge_completed
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_emoji_movie_answer(p_movie_index integer, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := '777f4e1f-7443-42e7-9d7a-115f2122888f';
  v_stage_id UUID;
  v_titles TEXT[] := ARRAY['Venom','Inside Out','Titanic','Toy Story','Oceania','Ratatouille','It','Avatar'];
  v_title TEXT;
  v_letter TEXT;
  v_existing RECORD;
  v_attempts INTEGER;
  v_correct BOOLEAN;
  v_resolved BOOLEAN;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile compiere azioni.';
  END IF;

  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  IF p_movie_index IS NULL OR p_movie_index < 1 OR p_movie_index > 8 THEN
    RAISE EXCEPTION 'Film non valido';
  END IF;

  v_title := v_titles[p_movie_index];
  v_letter := UPPER(LEFT(v_title, 1));
  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  PERFORM pg_advisory_xact_lock(hashtext('emoji:' || v_team_id::text || ':' || p_movie_index::text));

  SELECT * INTO v_existing
  FROM public.team_emoji_movies
  WHERE team_id = v_team_id AND movie_index = p_movie_index
  LIMIT 1;

  -- Già risolto (giusto o 3 tentativi esauriti): nessun nuovo punteggio
  IF FOUND AND (v_existing.is_correct OR v_existing.attempts >= 3) THEN
    RETURN jsonb_build_object(
      'is_correct', v_existing.is_correct,
      'attempts', v_existing.attempts,
      'already_resolved', true,
      'title', v_title,
      'letter', v_letter
    );
  END IF;

  v_attempts := COALESCE(v_existing.attempts, 0) + 1;
  v_correct := LOWER(TRIM(COALESCE(p_answer, ''))) = LOWER(v_title);
  v_resolved := v_correct OR v_attempts >= 3;

  IF FOUND THEN
    UPDATE public.team_emoji_movies
    SET attempts = v_attempts,
        last_answer = p_answer,
        is_correct = v_correct,
        points = CASE WHEN v_correct THEN 1 ELSE 0 END,
        letter = CASE WHEN v_resolved THEN v_letter ELSE NULL END,
        title = CASE WHEN v_resolved THEN v_title ELSE NULL END
    WHERE id = v_existing.id;
  ELSE
    INSERT INTO public.team_emoji_movies (team_id, movie_index, attempts, last_answer, is_correct, points, letter, title)
    VALUES (v_team_id, p_movie_index, v_attempts, p_answer, v_correct, CASE WHEN v_correct THEN 1 ELSE 0 END,
            CASE WHEN v_resolved THEN v_letter ELSE NULL END, CASE WHEN v_resolved THEN v_title ELSE NULL END);
  END IF;

  IF v_correct THEN
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, 1, 'challenge_points',
            'Indovinato film dalle emoji: ' || v_title || ' (' || p_movie_index || '/8)');
  ELSE
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, -2, 'penalty',
            'Errore film emoji #' || p_movie_index || ': "' || LEFT(COALESCE(p_answer, ''), 60) || '" (-2 PT)');
  END IF;

  RETURN jsonb_build_object(
    'is_correct', v_correct,
    'attempts', v_attempts,
    'already_resolved', false,
    'title', CASE WHEN v_resolved THEN v_title ELSE NULL END,
    'letter', CASE WHEN v_resolved THEN v_letter ELSE NULL END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_enigma_answer(p_challenge_id uuid, p_answer jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_solution RECORD;
  v_already_completed BOOLEAN;
  v_attempt_count INTEGER;
  v_is_correct BOOLEAN := false;
  v_penalty INTEGER := -8;
  v_team_name TEXT;
  v_challenge_title TEXT;
  v_stage_id UUID;
  v_notes_correct TEXT[];
  v_notes_submitted TEXT[];
  v_dirs_correct TEXT[];
  v_dirs_submitted TEXT[];
  v_lat_correct TEXT;
  v_lng_correct TEXT;
  v_lat_submitted TEXT;
  v_lng_submitted TEXT;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open(p_challenge_id);
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato come team');
  END IF;

  SELECT * INTO v_solution FROM public.enigma_solutions WHERE challenge_id = p_challenge_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Enigma non configurato');
  END IF;

  SELECT titolo, stage_id INTO v_challenge_title, v_stage_id FROM public.challenges WHERE id = p_challenge_id;

  SELECT EXISTS(
    SELECT 1 FROM public.team_progress 
    WHERE team_id = v_team_id AND challenge_id = p_challenge_id AND stato = 'completed'
  ) INTO v_already_completed;

  IF v_already_completed THEN
    RETURN jsonb_build_object(
      'is_correct', true,
      'already_completed', true,
      'attempt_number', 0,
      'points', v_solution.punteggio
    );
  END IF;

  -- Lock concorrente sul team
  PERFORM 1 FROM public.teams WHERE id = v_team_id FOR UPDATE;

  SELECT COUNT(*) INTO v_attempt_count FROM public.enigma_attempts
  WHERE team_id = v_team_id AND challenge_id = p_challenge_id;
  v_attempt_count := v_attempt_count + 1;

  -- Valutazione a seconda del tipo
  IF v_solution.solution_type = 'notes' THEN
    SELECT ARRAY(SELECT jsonb_array_elements_text(v_solution.solution)) INTO v_notes_correct;
    SELECT ARRAY(SELECT jsonb_array_elements_text(p_answer)) INTO v_notes_submitted;
    
    IF array_length(v_notes_correct, 1) = array_length(v_notes_submitted, 1) THEN
      v_is_correct := true;
      FOR i IN 1..array_length(v_notes_correct, 1) LOOP
        IF LOWER(v_notes_correct[i]) != LOWER(v_notes_submitted[i]) THEN
          v_is_correct := false;
        END IF;
      END LOOP;
    END IF;

  ELSIF v_solution.solution_type = 'directions' THEN
    SELECT ARRAY(SELECT jsonb_array_elements_text(v_solution.solution)) INTO v_dirs_correct;
    SELECT ARRAY(SELECT jsonb_array_elements_text(p_answer)) INTO v_dirs_submitted;

    IF array_length(v_dirs_correct, 1) = array_length(v_dirs_submitted, 1) THEN
      v_is_correct := true;
      FOR i IN 1..array_length(v_dirs_correct, 1) LOOP
        IF LOWER(v_dirs_correct[i]) != LOWER(v_dirs_submitted[i]) THEN
          v_is_correct := false;
        END IF;
      END LOOP;
    END IF;

  ELSIF v_solution.solution_type = 'coordinates' THEN
    v_lat_correct := REPLACE(TRIM(v_solution.solution->>'lat'), ',', '.');
    v_lng_correct := REPLACE(TRIM(v_solution.solution->>'lng'), ',', '.');
    v_lat_submitted := REPLACE(TRIM(p_answer->>'lat'), ',', '.');
    v_lng_submitted := REPLACE(TRIM(p_answer->>'lng'), ',', '.');

    v_is_correct := (v_lat_correct = v_lat_submitted AND v_lng_correct = v_lng_submitted);
  ELSE
    v_is_correct := (LOWER(REGEXP_REPLACE(v_solution.solution->>0, '\s+', '', 'g')) = LOWER(REGEXP_REPLACE(p_answer->>0, '\s+', '', 'g')));
  END IF;

  -- Registra tentativo
  INSERT INTO public.enigma_attempts (team_id, challenge_id, attempt_number, answer, is_correct)
  VALUES (v_team_id, p_challenge_id, v_attempt_count, p_answer, v_is_correct);

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_team_id;

  IF v_is_correct THEN
    -- Completa sfida
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, p_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    -- Assegna punti (+20)
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, p_challenge_id, v_stage_id, v_solution.punteggio, 'challenge_points', 'Enigma risolto: ' || v_challenge_title);

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES ('enigma_solved', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team_name || '" ha risolto l''enigma "' || v_challenge_title || '" al tentativo #' || v_attempt_count, 'punti', v_solution.punteggio));

    PERFORM public.apply_completion_effects(v_team_id, p_challenge_id);
  ELSE
    -- Detrae punti (-8)
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, p_challenge_id, v_stage_id, v_penalty, 'penalty', 'Risposta enigma errata: ' || v_challenge_title);

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES ('enigma_failed', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team_name || '" ha risposto in modo errato all''enigma "' || v_challenge_title || '", subendo ' || v_penalty || ' PT.', 'punti', v_penalty));
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'is_correct', v_is_correct,
    'attempt_number', v_attempt_count,
    'points', CASE WHEN v_is_correct THEN v_solution.punteggio ELSE v_penalty END,
    'already_completed', false
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_secret_code_pin(p_inserted_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_correct_pin TEXT;
  v_correct BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_stage_id UUID;
  v_already_done BOOLEAN := false;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open('d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8'::uuid);
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT full_code INTO v_correct_pin FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_correct_pin IS NULL THEN
    v_correct_pin := '4829167305';
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  v_correct := (TRIM(p_inserted_code) = TRIM(v_correct_pin));

  IF v_correct THEN
    PERFORM pg_advisory_xact_lock(hashtext('pin:' || v_team_id::text));
    SELECT EXISTS (SELECT 1 FROM public.team_progress WHERE team_id = v_team_id AND challenge_id = v_challenge_id AND stato = 'completed') INTO v_already_done;
  END IF;

  IF v_correct AND NOT v_already_done THEN
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, v_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, 30, 'challenge_points', 'Sfida PIN superata')
    ON CONFLICT DO NOTHING;

    PERFORM public.apply_completion_effects(v_team_id, v_challenge_id);
  END IF;

  RETURN jsonb_build_object(
    'success', v_correct,
    'message', CASE WHEN v_correct THEN 'Sbloccato!' ELSE 'Codice errato. Controlla attentamente le cifre.' END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_social_challenge(p_image_1_path text, p_image_2_path text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7'::uuid);
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  INSERT INTO public.team_social_submissions (
    team_id, challenge_id, social_url, image_1_url, image_2_url, status, stato_approvazione, uploaded_at
  )
  VALUES (
    v_team_id, v_challenge_id, p_image_1_path, p_image_1_path, p_image_2_path, 'submitted', 'pending', now()
  )
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET 
    image_1_url = EXCLUDED.image_1_url,
    image_2_url = EXCLUDED.image_2_url,
    social_url = EXCLUDED.social_url,
    status = 'submitted',
    stato_approvazione = 'pending',
    uploaded_at = now();

  -- Segna progresso in completed o submitted
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET stato = 'completed', completata_il = now();

  PERFORM public.apply_completion_effects(v_team_id, v_challenge_id);

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_challenge(p_challenge uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_team_name TEXT;
  v_challenge RECORD;
  v_already BOOLEAN := false;
  v_bonus INTEGER := 0;
  v_base_points INTEGER := 0;
  v_completed_challenges_count INTEGER := 0;
  v_total_challenges_count INTEGER := 0;
  v_stage_completed BOOLEAN := false;
  v_stage_reward INTEGER := 0;
  v_stage_arrival_pos INTEGER := 1;
  v_stage_number INTEGER := 1;
  v_active_2x RECORD;
  v_multiplier_2x_bonus INTEGER := 0;
  v_active_stage_dimezza RECORD;
  v_full_stage_score INTEGER := 0;
  v_stage_dimezza_penalty INTEGER := 0;
  v_active_polizza RECORD;
  v_polizza_refund INTEGER := 0;
  v_new_bal INTEGER := 0;
  v_stage_name TEXT;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open(p_challenge);
  -- CONTROLLO GARA TERMINATA
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile completare sfide.';
  END IF;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT team_id INTO v_team_id
  FROM public.user_roles
  WHERE user_id = v_user_id;

  IF v_team_id IS NULL THEN
    SELECT id INTO v_team_id
    FROM public.teams
    WHERE owner_id = v_user_id;
  END IF;

  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Nessuna squadra associata all''utente';
  END IF;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_team_id;
  SELECT * INTO v_challenge FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sfida non trovata';
  END IF;

  SELECT numero_tappa INTO v_stage_number FROM public.stages WHERE id = v_challenge.stage_id;

  -- 1. VERIFICA IDEMPOTENZA (DOPPIO CLICK / COMPLETAMENTO DUPLICATO)
  IF EXISTS (
    SELECT 1 FROM public.team_progress
    WHERE team_id = v_team_id AND challenge_id = p_challenge AND stato = 'completed'
  ) THEN
    v_already := true;
    RETURN jsonb_build_object(
      'already', true,
      'points', 0,
      'base_points', 0,
      'stage_completed', false,
      'stage_reward', 0
    );
  END IF;

  -- 1b. VALIDAZIONE LATO SERVER: la prova deve essere stata realmente svolta
  IF NOT public.challenge_requirements_met(v_team_id, p_challenge) THEN
    RAISE EXCEPTION 'La prova non risulta ancora svolta: completa tutti i passaggi richiesti.';
  END IF;

  -- 2. REGISTRA COMPLETAMENTO PROVA
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_team_id, p_challenge, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  v_base_points := COALESCE(v_challenge.punteggio_massimo, 0);

  -- 3. CONTROLLO MOLTIPLICATORE 2X ATTIVO
  SELECT * INTO v_active_2x
  FROM public.marketplace_transactions
  WHERE team_id = v_team_id
    AND marketplace_item_id = 'moltiplicatore_2x_disattivato'
    AND stato = 'completed'
  ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

  IF FOUND AND v_base_points > 0 THEN
    v_multiplier_2x_bonus := v_base_points;
    
    INSERT INTO public.scores (team_id, stage_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (
      v_team_id,
      v_challenge.stage_id,
      p_challenge,
      v_multiplier_2x_bonus,
      'bonus_moltiplicatore_2x',
      'Moltiplicatore 2X applicato alla prova ' || v_challenge.titolo || ' (+' || v_multiplier_2x_bonus::text || ' PT)'
    );

    UPDATE public.marketplace_transactions
    SET stato = 'used',
        data_utilizzo = now(),
        dettagli = jsonb_build_object(
          'applied_challenge_id', p_challenge,
          'challenge_title', v_challenge.titolo,
          'bonus_points_awarded', v_multiplier_2x_bonus
        )
    WHERE id = v_active_2x.id;
  END IF;

  -- 4. INSERISCI PUNTEGGIO BASE DELLA PROVA
  INSERT INTO public.scores (team_id, stage_id, challenge_id, punti, motivo)
  VALUES (
    v_team_id,
    v_challenge.stage_id,
    p_challenge,
    v_base_points,
    'Completamento prova: ' || v_challenge.titolo
  );

  -- 5. VERIFICA COMPLETAMENTO DELLA TAPPA
  SELECT COUNT(*) INTO v_total_challenges_count
  FROM public.challenges
  WHERE stage_id = v_challenge.stage_id AND tipo_sfida <> 'jackpot';

  SELECT COUNT(DISTINCT challenge_id) INTO v_completed_challenges_count
  FROM public.team_progress
  WHERE team_id = v_team_id
    AND challenge_id IN (SELECT id FROM public.challenges WHERE stage_id = v_challenge.stage_id AND tipo_sfida <> 'jackpot')
    AND stato = 'completed';

  IF v_completed_challenges_count = v_total_challenges_count THEN
    v_stage_completed := true;
    -- Serializza il calcolo della posizione di arrivo per tappa (evita posizioni duplicate)
    PERFORM pg_advisory_xact_lock(hashtext('stage_arrival:' || v_challenge.stage_id::text));

    -- Applicazione eventuale Malus DIMEZZA PUNTI TAPPA registrato per questa tappa
    SELECT * INTO v_active_stage_dimezza
    FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id
      AND marketplace_item_id = 'dimezza_punti'
      AND stage_id = v_challenge.stage_id
      AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      SELECT COALESCE(SUM(punti), 0)::integer INTO v_full_stage_score
      FROM public.scores
      WHERE team_id = v_team_id
        AND stage_id = v_challenge.stage_id
        AND (tipo_modificatore IS NULL OR tipo_modificatore != 'penalty_dimezza_tappa');

      IF v_full_stage_score > 0 THEN
        v_stage_dimezza_penalty := FLOOR(v_full_stage_score / 2.0)::integer;
        
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (
          v_team_id,
          v_challenge.stage_id,
          -v_stage_dimezza_penalty,
          'penalty_dimezza_tappa',
          'Malus Dimezza Punti Tappa ' || v_stage_number::text || ': penalità −' || v_stage_dimezza_penalty::text || ' PT (50% del punteggio complessivo della tappa)'
        );

        -- Controllo Polizza Diretta
        SELECT * INTO v_active_polizza
        FROM public.marketplace_transactions
        WHERE team_id = v_team_id
          AND marketplace_item_id = 'polizza_diretta'
          AND stato = 'completed'
        ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

        IF FOUND AND v_stage_dimezza_penalty > 0 THEN
          v_polizza_refund := CEIL(v_stage_dimezza_penalty / 2.0)::integer;
          IF v_polizza_refund > 0 THEN
            INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
            VALUES (
              v_team_id,
              v_challenge.stage_id,
              v_polizza_refund,
              'bonus_polizza',
              'Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+' || v_polizza_refund::text || ' PT)'
            );

            UPDATE public.marketplace_transactions
            SET stato = 'used',
                data_utilizzo = now(),
                dettagli = jsonb_build_object('refunded_points', v_polizza_refund, 'source_malus', 'dimezza_punti', 'target_stage_id', v_challenge.stage_id)
            WHERE id = v_active_polizza.id;
          END IF;
        END IF;
      ELSE
        v_stage_dimezza_penalty := 0;
      END IF;

      UPDATE public.marketplace_transactions
      SET stato = 'used',
          data_utilizzo = now(),
          dettagli = (COALESCE(dettagli, '{}'::jsonb) || jsonb_build_object(
            'stage_score_before', v_full_stage_score,
            'penalty_applied', v_stage_dimezza_penalty,
            'stage_score_after', v_full_stage_score - v_stage_dimezza_penalty,
            'applied_at_stage_completion', true
          ))
      WHERE id = v_active_stage_dimezza.id;
    END IF;

    -- CALCOLO ORDINE DI ARRIVO DINAMICO PER LA TAPPA (SCALA 12 SQUADRE)
    SELECT COUNT(*) + 1 INTO v_stage_arrival_pos
    FROM public.marketplace_transactions
    WHERE marketplace_item_id = 'reward_stage'
      AND stage_id = v_challenge.stage_id;

    IF v_stage_arrival_pos = 1 THEN v_stage_reward := 25;
    ELSIF v_stage_arrival_pos = 2 THEN v_stage_reward := 20;
    ELSIF v_stage_arrival_pos = 3 THEN v_stage_reward := 16;
    ELSIF v_stage_arrival_pos = 4 THEN v_stage_reward := 13;
    ELSIF v_stage_arrival_pos = 5 THEN v_stage_reward := 10;
    ELSIF v_stage_arrival_pos = 6 THEN v_stage_reward := 8;
    ELSIF v_stage_arrival_pos = 7 THEN v_stage_reward := 6;
    ELSIF v_stage_arrival_pos = 8 THEN v_stage_reward := 5;
    ELSIF v_stage_arrival_pos = 9 THEN v_stage_reward := 4;
    ELSIF v_stage_arrival_pos = 10 THEN v_stage_reward := 3;
    ELSIF v_stage_arrival_pos = 11 THEN v_stage_reward := 2;
    ELSE v_stage_reward := 1;
    END IF;

    -- Accredita i Token ricompensa alla squadra
    UPDATE public.teams
    SET token_balance = token_balance + v_stage_reward
    WHERE id = v_team_id
    RETURNING token_balance INTO v_new_bal;

    SELECT titolo INTO v_stage_name FROM public.stages WHERE id = v_challenge.stage_id;

    INSERT INTO public.marketplace_transactions (team_id, stage_id, marketplace_item_id, costo_token, stato, dettagli)
    VALUES (
      v_team_id, v_challenge.stage_id, 'reward_stage', -v_stage_reward, 'completed',
      jsonb_build_object(
        'stage_id', v_challenge.stage_id,
        'stage_index', v_stage_number,
        'position', v_stage_arrival_pos,
        'reward_tokens', v_stage_reward,
        'stage_name', v_stage_name,
        'old_balance', v_new_bal - v_stage_reward,
        'new_balance', v_new_bal
      )
    );

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES (
      'stage_reward_credited', v_team_id,
      jsonb_build_object(
        'message', 'La squadra ' || COALESCE(v_team_name, 'Squadra') || ' ha concluso la Tappa ' || v_stage_number || ' in ' || v_stage_arrival_pos || 'ª posizione e ha ricevuto +' || v_stage_reward || ' Token! 🪙',
        'stage_id', v_challenge.stage_id,
        'position', v_stage_arrival_pos,
        'tokens_added', v_stage_reward
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'already', v_already,
    'points', v_base_points + v_multiplier_2x_bonus - v_stage_dimezza_penalty + v_polizza_refund,
    'base_points', v_base_points,
    'multiplier_2x_bonus', v_multiplier_2x_bonus,
    'stage_dimezza_penalty', v_stage_dimezza_penalty,
    'polizza_refund', v_polizza_refund,
    'bonus', v_bonus,
    'stage_completed', v_stage_completed,
    'stage_reward', v_stage_reward,
    'position', v_stage_arrival_pos
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.play_jackpot(p_team_id uuid DEFAULT NULL::uuid, p_puntata integer DEFAULT 10)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_already_played BOOLEAN;
  v_current_score INTEGER := 0;
  v_pool TEXT[] := ARRAY['🍒', '🍋', '🔔', '💎'];
  v_s1 INTEGER;
  v_s2 INTEGER;
  v_s3 INTEGER;
  v_sym1 TEXT;
  v_sym2 TEXT;
  v_sym3 TEXT;
  v_simboli TEXT;
  v_is_win BOOLEAN;
  v_risultato TEXT;
  v_variazione INTEGER;
  v_nuovo_punteggio INTEGER;
  v_play_id UUID;
  v_play RECORD;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open('f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0'::uuid);
  v_team_id := COALESCE(p_team_id, public.current_team_id());
  IF p_team_id IS NOT NULL AND p_team_id IS DISTINCT FROM public.current_team_id() THEN
    PERFORM public.assert_admin_caller();
  END IF;
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Squadra non identificata.';
  END IF;

  PERFORM 1 FROM public.teams WHERE id = v_team_id FOR UPDATE;

  SELECT EXISTS(
    SELECT 1 FROM public.jackpot_plays
    WHERE team_id = v_team_id AND challenge_id = v_challenge_id
  ) INTO v_already_played;

  IF v_already_played THEN
    RAISE EXCEPTION 'La tua squadra ha già tentato il Jackpot della Regia.';
  END IF;

  SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_current_score
  FROM public.scores
  WHERE team_id = v_team_id;

  IF p_puntata < 5 OR p_puntata > 20 THEN
    RAISE EXCEPTION 'La puntata deve essere compresa tra 5 e 20 punti.';
  END IF;

  IF p_puntata > v_current_score THEN
    RAISE EXCEPTION 'Non puoi scommettere più punti di quelli che possiedi (% PT attuali).', v_current_score;
  END IF;

  v_s1 := 1 + floor(random() * 4)::INTEGER;
  v_s2 := 1 + floor(random() * 4)::INTEGER;
  v_s3 := 1 + floor(random() * 4)::INTEGER;

  v_sym1 := v_pool[v_s1];
  v_sym2 := v_pool[v_s2];
  v_sym3 := v_pool[v_s3];
  v_simboli := v_sym1 || ',' || v_sym2 || ',' || v_sym3;

  v_is_win := (v_s1 = v_s2 AND v_s2 = v_s3);
  v_risultato := CASE WHEN v_is_win THEN 'vinta' ELSE 'persa' END;
  v_variazione := CASE WHEN v_is_win THEN p_puntata ELSE -p_puntata END;
  v_nuovo_punteggio := v_current_score + v_variazione;

  v_play_id := gen_random_uuid();

  INSERT INTO public.jackpot_plays (
    id, team_id, challenge_id, puntata, puntata_punti, simboli, risultato, variazione, delta_punti, punteggio_precedente, punteggio_attuale, timestamp
  ) VALUES (
    v_play_id, v_team_id, v_challenge_id, p_puntata, p_puntata, v_simboli, v_risultato, v_variazione, v_variazione, v_current_score, v_nuovo_punteggio, now()
  );

  INSERT INTO public.scores (
    team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo
  ) VALUES (
    v_team_id, v_challenge_id, v_stage_id, v_variazione, 'challenge_points', 'Jackpot della Regia: ' || UPPER(v_risultato) || ' (' || v_sym1 || ' ' || v_sym2 || ' ' || v_sym3 || ')'
  );

  INSERT INTO public.team_progress (
    team_id, challenge_id, stato, completata_il
  ) VALUES (
    v_team_id, v_challenge_id, 'completed', now()
  )
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET stato = 'completed', completata_il = now();

  SELECT * INTO v_play FROM public.jackpot_plays WHERE id = v_play_id;

  RETURN row_to_json(v_play);
END;
$function$;

DROP FUNCTION IF EXISTS public.assert_challenge_unlocked(uuid);
