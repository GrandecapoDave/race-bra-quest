-- Snapshot delle funzioni public di Production PRIMA delle migrazioni 07-10 (dopo la 06), 2026-09-24.
-- Rollback: eseguire questo file, poi ripristinare i criteri storage descritti in 10_team_media_lockdown.sql.

CREATE OR REPLACE FUNCTION public._get_time_bonus_points(p_rank integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  RETURN CASE p_rank
    WHEN 1 THEN 30
    WHEN 2 THEN 25
    WHEN 3 THEN 20
    WHEN 4 THEN 17
    WHEN 5 THEN 14
    WHEN 6 THEN 11
    WHEN 7 THEN 8
    WHEN 8 THEN 5
    WHEN 9 THEN 3
    ELSE 0
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_points(p_team_id uuid, p_stage_id uuid, p_points integer, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, p_stage_id, p_points, 'bonus', p_reason);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_tokens(p_team_id uuid, p_tokens integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.teams 
  SET token_balance = token_balance + p_tokens 
  WHERE id = p_team_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_adjust_team_score(p_team_id uuid, p_punti integer, p_motivo text, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_score_id UUID;
  v_team_name TEXT;
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NULL
     OR NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT nome_squadra
  INTO v_team_name
  FROM public.teams
  WHERE id = p_team_id;

  IF v_team_name IS NULL THEN
    RAISE EXCEPTION 'Squadra non trovata';
  END IF;

  INSERT INTO public.scores (
    id,
    team_id,
    challenge_id,
    stage_id,
    punti,
    tipo_modificatore,
    motivo,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    p_team_id,
    NULL,
    NULL,
    p_punti,
    'admin_adjustment',
    COALESCE(NULLIF(TRIM(p_motivo), ''), 'Regolazione manuale Regia'),
    now()
  )
  RETURNING id INTO v_score_id;

  INSERT INTO public.activity_log (
    id,
    tipo_evento,
    team_id,
    target_team_id,
    dettagli,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'ADMIN_SCORE_ADJUSTMENT',
    NULL,
    p_team_id,
    jsonb_build_object(
      'admin_id', p_admin_id,
      'team_id', p_team_id,
      'team_name', v_team_name,
      'points', p_punti,
      'reason', COALESCE(NULLIF(TRIM(p_motivo), ''), 'Regolazione manuale Regia'),
      'score_id', v_score_id
    ),
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'score_id', v_score_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_adjust_team_tokens(p_team_id uuid, p_amount integer, p_reason text, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_current_tokens INTEGER;
  v_new_balance INTEGER;
  v_team_name TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT token_balance, nome_squadra INTO v_current_tokens, v_team_name 
  FROM public.teams 
  WHERE id = p_team_id 
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Squadra non trovata';
  END IF;

  v_new_balance := GREATEST(0, v_current_tokens + p_amount);

  UPDATE public.teams 
  SET token_balance = v_new_balance 
  WHERE id = p_team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('admin_tokens_adjusted', p_team_id, jsonb_build_object(
    'message', 'La Regia ha ' || CASE WHEN p_amount >= 0 THEN 'aggiunto ' ELSE 'rimosso ' END || ABS(p_amount)::text || ' token alla squadra "' || v_team_name || '".' || CASE WHEN p_reason != '' THEN ' Motivazione: ' || p_reason ELSE '' END,
    'new_balance', v_new_balance
  ));

  RETURN jsonb_build_object('success', true, 'new_balance', v_new_balance);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_delete_team_score(p_score_id uuid, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_points INTEGER;
  v_reason TEXT;
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NULL
     OR NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT team_id, punti, motivo
  INTO v_team_id, v_points, v_reason
  FROM public.scores
  WHERE id = p_score_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Punteggio non trovato';
  END IF;

  DELETE FROM public.scores
  WHERE id = p_score_id;

  INSERT INTO public.activity_log (
    id,
    tipo_evento,
    team_id,
    target_team_id,
    dettagli,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'ADMIN_SCORE_DELETED',
    NULL,
    v_team_id,
    jsonb_build_object(
      'admin_id', p_admin_id,
      'score_id', p_score_id,
      'points', v_points,
      'reason', v_reason
    ),
    now()
  );

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_edit_bank_answer(p_team_id uuid, p_question_id integer, p_answer text, p_correct boolean, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_real_q_id UUID;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  -- Cerchiamo se c'è una domanda fittizia
  -- Nella banca le domande sono logiche e registrate per numero. Per evitare FK errors, associamo ad una riga in quiz_questions se presente o la creiamo fittizia.
  SELECT id INTO v_real_q_id FROM public.quiz_questions WHERE question = 'Banca Q' || p_question_id::text LIMIT 1;
  IF NOT FOUND THEN
    INSERT INTO public.quiz_questions (challenge_id, question, options, correct_answer_index, order_index, points)
    VALUES (v_challenge_id, 'Banca Q' || p_question_id::text, '[]'::jsonb, 0, p_question_id, 5)
    RETURNING id INTO v_real_q_id;
  END IF;

  INSERT INTO public.team_answers (team_id, question_id, selected_answer, correct)
  VALUES (p_team_id, v_real_q_id, 0, p_correct) -- Selected index fittizio
  ON CONFLICT (team_id, question_id)
  DO UPDATE SET correct = p_correct;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_match(p_team_id uuid, p_partner_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
  -- Logica fittizia per evitare errori
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_settings(p_full_code text, p_destination text, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
  -- Logica fittizia per evitare errori
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_force_complete_bank(p_team_id uuid, p_admin_id uuid)
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

  -- Completa la sfida
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (p_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  -- Assegna punteggio (25 punti)
  INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, v_challenge_id, 25, 'challenge_points', 'Sfida Banca forzata da Admin');
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_force_complete_secret_code(p_team_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7'; -- Codice Segreto
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (p_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, v_challenge_id, 15, 'challenge_points', 'Codice Segreto sbloccato da Admin');
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_get_enigma_dashboard(p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_stage4_id UUID := '4b4b4c4d-5e5f-6061-7172-838485868788';
  v_rows JSONB;
  v_solutions JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  WITH stage4_challenges AS (
    SELECT id, titolo, ordine_sfida 
    FROM public.challenges 
    WHERE stage_id = v_stage4_id
    ORDER BY ordine_sfida ASC
  ),
  team_enigma_progress AS (
    SELECT 
      t.id AS team_id,
      t.nome_squadra,
      t.active,
      sc.id AS challenge_id,
      sc.titolo,
      sc.ordine_sfida,
      COALESCE(tp.stato, 'not_started') AS stato,
      tp.created_at AS started_at,
      tp.completata_il AS completed_at,
      (SELECT COUNT(*)::INTEGER FROM public.enigma_attempts ea WHERE ea.team_id = t.id AND ea.challenge_id = sc.id) AS attempt_count
    FROM public.teams t
    CROSS JOIN stage4_challenges sc
    LEFT JOIN public.team_progress tp ON tp.team_id = t.id AND tp.challenge_id = sc.id
  ),
  aggregated_teams AS (
    SELECT 
      team_id,
      nome_squadra,
      active,
      bool_or(stato != 'not_started') AS started,
      count(*) FILTER (WHERE stato = 'completed') = (SELECT count(*) FROM stage4_challenges) AS completed_all,
      count(*) FILTER (WHERE stato = 'completed')::INTEGER AS enigmi_completati,
      (SELECT count(*)::INTEGER FROM stage4_challenges) AS enigmi_totali,
      jsonb_agg(jsonb_build_object(
        'challenge_id', challenge_id,
        'titolo', titolo,
        'ordine', ordine_sfida,
        'stato', stato,
        'started_at', started_at,
        'completed_at', completed_at,
        'attempt_count', attempt_count
      ) ORDER BY ordine_sfida) AS enigma_progress
    FROM team_enigma_progress
    GROUP BY team_id, nome_squadra, active
  )
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', team_id,
    'nome_squadra', nome_squadra,
    'active', active,
    'started', started,
    'completed_all', completed_all,
    'enigmi_completati', enigmi_completati,
    'enigmi_totali', enigmi_totali,
    'enigma_progress', enigma_progress
  )), '[]'::jsonb) INTO v_rows
  FROM aggregated_teams;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'challenge_id', challenge_id,
    'solution_type', solution_type,
    'hint', CASE 
      WHEN solution_type = 'text' THEN SUBSTRING(solution->>0 FROM 1 FOR 3) || '...'
      WHEN solution_type = 'directions' THEN '[lucchetto]'
      WHEN solution_type = 'coordinates' THEN 'Lat: 44.71, Lng: 7.84'
      ELSE '[note]'
    END
  )), '[]'::jsonb) INTO v_solutions
  FROM public.enigma_solutions;

  RETURN jsonb_build_object(
    'rows', v_rows,
    'enigma_solutions', v_solutions
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_get_posters_overview()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_teams JSONB;
  v_posters JSONB;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'titolo', p.titolo,
    'file_name', p.file_name,
    'active', p.active
  ) ORDER BY p.id), '[]'::jsonb) INTO v_posters
  FROM public.posters p;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', t.id,
    'nome_squadra', t.nome_squadra,
    'avatar_url', t.avatar_url,
    'colore', t.colore,
    'poster_id', tp.poster_id,
    'titolo', p.titolo,
    'file_name', p.file_name,
    'assigned_at', tp.assigned_at
  ) ORDER BY t.created_at), '[]'::jsonb) INTO v_teams
  FROM public.teams t
  LEFT JOIN public.team_posters tp ON tp.team_id = t.id
  LEFT JOIN public.posters p ON p.id = tp.poster_id
  WHERE t.active = true;

  RETURN jsonb_build_object(
    'posters', v_posters,
    'team_assignments', v_teams
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_get_secret_code_dashboard()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_full_code TEXT := '4829167305';
  v_destination TEXT := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)';
  v_parts JSONB := '[]'::jsonb;
  v_matches JSONB := '[]'::jsonb;
  v_transactions JSONB := '[]'::jsonb;
  v_attempts JSONB := '[]'::jsonb;
  v_completed_teams JSONB := '[]'::jsonb;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code, next_stage_destination 
  INTO v_full_code, v_destination 
  FROM public.game_final_code 
  WHERE id = 'current' 
  LIMIT 1;

  -- 1. Parts
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', tcp.id,
    'team_id', tcp.team_id,
    'code_part', tcp.code_part,
    'part_type', tcp.part_type,
    'assigned_at', tcp.assigned_at
  )), '[]'::jsonb) INTO v_parts
  FROM public.team_code_parts tcp;

  -- 2. Matches
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'buyer_team_id', tcm.buyer_team_id,
    'seller_team_id', tcm.seller_team_id,
    'required_part', tcm.required_part,
    'token_cost', COALESCE(tcm.token_cost, 4),
    'created_at', tcm.created_at
  )), '[]'::jsonb) INTO v_matches
  FROM public.team_code_matches tcm;

  -- 3. Transactions
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', cpt.id,
    'buyer_team_id', cpt.buyer_team_id,
    'seller_team_id', cpt.seller_team_id,
    'token_cost', cpt.token_cost,
    'digits_received', cpt.digits_received,
    'timestamp', cpt.created_at
  )), '[]'::jsonb) INTO v_transactions
  FROM public.code_purchase_transactions cpt;

  -- 4. Attempts from activity_log or attempts table
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', al.id,
    'team_id', al.team_id,
    'inserted_code', COALESCE(al.dettagli->>'inserted_code', al.dettagli->>'code', '—'),
    'timestamp', al.created_at,
    'success', (al.tipo_evento = 'secret_code_solved')
  ) ORDER BY al.created_at DESC), '[]'::jsonb) INTO v_attempts
  FROM public.activity_log al
  WHERE al.tipo_evento IN ('secret_code_solved', 'secret_code_attempt');

  -- 5. Completed teams
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', tp.team_id,
    'nome_squadra', t.nome_squadra,
    'completed_at', tp.completata_il
  )), '[]'::jsonb) INTO v_completed_teams
  FROM public.team_progress tp
  JOIN public.teams t ON t.id = tp.team_id
  WHERE (tp.challenge_id = v_challenge_id OR tp.challenge_id IN (SELECT id FROM public.challenges WHERE tipo_sfida = 'codice'))
    AND tp.stato = 'completed';

  RETURN jsonb_build_object(
    'full_code', COALESCE(v_full_code, '4829167305'),
    'destination', COALESCE(v_destination, 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'),
    'parts', v_parts,
    'matches', v_matches,
    'transactions', v_transactions,
    'attempts', v_attempts,
    'completed_teams', v_completed_teams
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_remove_points(p_team_id uuid, p_stage_id uuid, p_points integer, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, p_stage_id, -ABS(p_points), 'penalty', p_reason);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_remove_tokens(p_team_id uuid, p_tokens integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_current_tokens INTEGER;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT token_balance INTO v_current_tokens FROM public.teams WHERE id = p_team_id FOR UPDATE;
  
  UPDATE public.teams 
  SET token_balance = GREATEST(0, v_current_tokens - p_tokens)
  WHERE id = p_team_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_reopen_game_results(p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NULL
     OR NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.game_report
  SET
    state = 'PRIVATE_LIVE',
    published_at = NULL,
    published_by = NULL,
    updated_at = now()
  WHERE id = 'current';

  IF NOT FOUND THEN
    INSERT INTO public.game_report (
      id,
      state,
      published_at,
      published_by,
      snapshot,
      updated_at
    )
    VALUES (
      'current',
      'PRIVATE_LIVE',
      NULL,
      NULL,
      NULL,
      now()
    );
  END IF;

  INSERT INTO public.activity_log (
    id,
    tipo_evento,
    team_id,
    target_team_id,
    dettagli,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'REOPEN_FINAL_RESULTS',
    NULL,
    NULL,
    jsonb_build_object('admin_id', p_admin_id),
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'CALCULATED'
  );
END;
$function$;

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

  -- Elimina risposte
  DELETE FROM public.team_answers WHERE team_id = p_team_id;

  -- Resetta progresso
  DELETE FROM public.team_progress WHERE team_id = p_team_id AND challenge_id = v_challenge_id;

  -- Elimina punteggio associato
  DELETE FROM public.scores WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_enigma_solution(p_challenge_id uuid, p_solution jsonb, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.enigma_solutions (challenge_id, solution, solution_type)
  VALUES (p_challenge_id, p_solution, 'text')
  ON CONFLICT (challenge_id) 
  DO UPDATE SET solution = EXCLUDED.solution;
END;
$function$;

CREATE OR REPLACE FUNCTION public.after_sync_team_to_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NEW.owner_id IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role, team_id, username)
    VALUES (NEW.owner_id, 'team', NEW.id, LOWER(TRIM(NEW.username)))
    ON CONFLICT (user_id) DO UPDATE 
    SET username = EXCLUDED.username, team_id = EXCLUDED.team_id;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.assert_admin_caller()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN;
  END IF;
  IF auth.uid() IS NULL OR NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.buy_marketplace_item(p_item_id text, p_target_team_id uuid DEFAULT NULL::uuid, p_target_stage_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp', 'extensions'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_team RECORD;
  v_item RECORD;
  v_target_team_name TEXT;
  v_target_shield RECORD;
  v_target_polizza RECORD;
  v_tx_id UUID;
  v_dettagli JSONB := '{}'::jsonb;
  v_roll INTEGER;
  v_outcome_id TEXT;
  v_outcome_label TEXT;
  v_outcome_pts INTEGER := 0;
  v_outcome_tokens INTEGER := 0;
  v_target_points INTEGER := 0;
  v_buyer_points INTEGER := 0;
  v_points_to_steal INTEGER := 0;
  v_stolen_points INTEGER := 0;
  v_refund INTEGER := 0;
  v_freeze_expires_at TIMESTAMPTZ;
  v_stage_tot_ch INTEGER := 0;
  v_stage_comp_ch INTEGER := 0;
  v_target_stage RECORD;
  v_full_stage_score INTEGER := 0;
  v_stage_penalty INTEGER := 0;
  v_polizza_refund INTEGER := 0;
BEGIN
  -- 1. IDENTIFICA UTENTE E SQUADRA
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
    RAISE EXCEPTION 'Nessuna squadra associata a questo account';
  END IF;

  -- 2. LOCK TEAM PER CONSISTENZA TOKEN
  SELECT * INTO v_team
  FROM public.teams
  WHERE id = v_team_id
  FOR UPDATE;

  -- 3. CONTROLLO GARA TERMINATA
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile effettuare acquisti al Marketplace.';
  END IF;

  -- 4. CONTROLLO MARKETPLACE ATTIVO
  IF NOT EXISTS (SELECT 1 FROM public.game_settings WHERE marketplace_active = true) THEN
    RAISE EXCEPTION 'Il Marketplace è attualmente chiuso dalla Regia!';
  END IF;

  -- 5. CONTROLLO BLACKOUT MERCATO
  IF EXISTS (
    SELECT 1 FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id
      AND marketplace_item_id = 'blackout_mercato'
      AND stato = 'completed'
      AND (data_acquisto + INTERVAL '6 minutes') > now()
  ) THEN
    RAISE EXCEPTION 'La tua squadra è sotto BLACKOUT MERCATO! Il Marketplace è bloccato.';
  END IF;

  -- 6. INFO ARTICOLO E CONTROLLO SALDO & MONOUSO
  SELECT * INTO v_item FROM public.marketplace_items WHERE id = p_item_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Articolo del Marketplace non valido: %', p_item_id;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.marketplace_transactions
    WHERE team_id = v_team_id
      AND marketplace_item_id = p_item_id
      AND stato != 'expired'
  ) THEN
    RAISE EXCEPTION 'Hai già acquistato questo articolo durante la gara! Ogni articolo è utilizzabile 1 sola volta.';
  END IF;

  IF v_team.token_balance < v_item.costo_token THEN
    RAISE EXCEPTION 'Token insufficienti! Costo: % 🪙, Saldo attuale: % 🪙', v_item.costo_token, v_team.token_balance;
  END IF;

  -- Deduce token
  UPDATE public.teams
  SET token_balance = token_balance - v_item.costo_token
  WHERE id = v_team_id;

  -- 7. GESTIONE BERSAGLIO E CONTROLLO SCUDO UNIVERSALE (PER MALUS)
  IF UPPER(COALESCE(v_item.tipo, '')) = 'MALUS' THEN
    IF p_target_team_id IS NULL THEN
      RAISE EXCEPTION 'È obbligatorio selezionare una squadra bersaglio per i Malus!';
    END IF;

    IF p_target_team_id = v_team_id THEN
      RAISE EXCEPTION 'Non puoi lanciare un Malus contro la tua stessa squadra!';
    END IF;

    SELECT nome_squadra INTO v_target_team_name FROM public.teams WHERE id = p_target_team_id;

    -- REGISTRAZIONE PRIVATA PREMIO CATTIVERIA (+10 PT) PER L'ADMIN E IL REPORT FINALE
    INSERT INTO public.cattiveria_ledger (team_id, tipo, marketplace_item_id, punti, motivo)
    VALUES (
      v_team_id,
      'MALUS_UTILIZZATO',
      p_item_id,
      10,
      'Lancio del malus ' || v_item.nome || ' contro ' || COALESCE(v_target_team_name, 'Squadra') || ' (+10 PT Cattiveria)'
    );

    -- CONTROLLO SCUDO UNIVERSALE
    SELECT * INTO v_target_shield
    FROM public.marketplace_transactions
    WHERE team_id = p_target_team_id
      AND marketplace_item_id = 'bonus_scudo'
      AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      UPDATE public.marketplace_transactions
      SET stato = 'used',
          data_utilizzo = now(),
          dettagli = jsonb_build_object(
            'blocked_malus', p_item_id,
            'blocked_malus_id', p_item_id,
            'blocked_malus_name', v_item.nome,
            'attacker_team_id', v_team_id,
            'attacker_name', v_team.nome_squadra,
            'blocked_at', now()
          )
      WHERE id = v_target_shield.id;

      INSERT INTO public.marketplace_transactions (
        team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
      ) VALUES (
        v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'expired', now(),
        jsonb_build_object(
          'blocked_by_shield', true,
          'blocked_by_shield_id', v_target_shield.id,
          'target_team_name', v_target_team_name,
          'blocked_at', now()
        )
      ) RETURNING id INTO v_tx_id;

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'malus_blocked_by_shield', v_team_id, p_target_team_id,
        jsonb_build_object(
          'message', 'Lo Scudo di ' || v_target_team_name || ' ha parato il Malus ' || v_item.nome || ' lanciato da ' || v_team.nome_squadra || '!',
          'malus_id', p_item_id
        )
      );

      RETURN jsonb_build_object(
        'success', true,
        'shielded', true,
        'blocked_by_shield', true,
        'transaction_id', v_tx_id,
        'message', 'Il Malus è stato parato dallo Scudo avversario!',
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    END IF;
  END IF;

  -- 8. ESECUZIONE SPECIFICA PER ITEM
  IF p_item_id = 'bonus_punti' THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, 20, 'bonus_punti', 'Acquisto Marketplace: +20 Punti Squadra');
    v_dettagli := jsonb_build_object('points_added', 20);

    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'ruota_fortuna' THEN
    v_roll := floor(random() * 100 + 1)::integer;
    IF v_roll <= 5 THEN
      v_outcome_id := 'jackpot';
      v_outcome_label := '🏆 JACKPOT (+20 PT)';
      v_outcome_pts := 20;
    ELSIF v_roll <= 15 THEN
      v_outcome_id := 'dave_help';
      v_outcome_label := '🧠 AIUTO DAVE';
    ELSIF v_roll <= 30 THEN
      v_outcome_id := 'mega_bonus';
      v_outcome_label := '💎 MEGA (+15 PT)';
      v_outcome_pts := 15;
    ELSIF v_roll <= 45 THEN
      v_outcome_id := 'bonus';
      v_outcome_label := '⭐ BONUS (+10 PT)';
      v_outcome_pts := 10;
    ELSIF v_roll <= 60 THEN
      v_outcome_id := 'piccolo_bonus';
      v_outcome_label := '🎁 PICCOLO (+5 PT)';
      v_outcome_pts := 5;
    ELSIF v_roll <= 75 THEN
      v_outcome_id := 'gettoni_bonus';
      v_outcome_label := '🪙 +10 TOKEN';
      v_outcome_tokens := 10;
    ELSIF v_roll <= 85 THEN
      v_outcome_id := 'doppio_premio';
      v_outcome_label := '🎯 DOPPIO (+5/+5)';
      v_outcome_pts := 5;
      v_outcome_tokens := 5;
    ELSIF v_roll <= 95 THEN
      v_outcome_id := 'fortuna';
      v_outcome_label := '🍀 +5 TOKEN';
      v_outcome_tokens := 5;
    ELSE
      v_outcome_id := 'sorpresa';
      v_outcome_label := '🎉 +3 PUNTI';
      v_outcome_pts := 3;
    END IF;

    IF v_outcome_pts > 0 THEN
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_outcome_pts, 'bonus_ruota', 'Ruota della Fortuna: ' || v_outcome_label);
    END IF;

    IF v_outcome_tokens > 0 THEN
      UPDATE public.teams
      SET token_balance = token_balance + v_outcome_tokens
      WHERE id = v_team_id;
    END IF;

    v_dettagli := jsonb_build_object(
      'id', v_outcome_id,
      'outcome_id', v_outcome_id,
      'outcome_label', v_outcome_label,
      'label', v_outcome_label,
      'points_awarded', v_outcome_pts,
      'tokens_awarded', v_outcome_tokens,
      'roll', v_roll
    );

    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'passaparola' THEN
    v_dettagli := jsonb_build_object('available', true);
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'bonus_classifica' THEN
    v_dettagli := jsonb_build_object('available', true);

    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'bonus_scudo' THEN
    v_dettagli := jsonb_build_object('activated_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'partenza_anticipata' THEN
    v_dettagli := jsonb_build_object('available_bonus_seconds', 120, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'moltiplicatore_2x' THEN
    v_dettagli := jsonb_build_object('multiplier', 2, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'polizza_diretta' THEN
    v_dettagli := jsonb_build_object('coverage_percent', 50, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'penalita_punti' THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (p_target_team_id, -20, 'penalty', 'Penalità Punti subita da ' || v_team.nome_squadra || ' (−20 PT)');

    -- Controllo Polizza
    SELECT * INTO v_target_polizza
    FROM public.marketplace_transactions
    WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      v_refund := 10;
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, v_refund, 'bonus_polizza', 'Polizza Diretta: Rimborso 50% penalità (+' || v_refund::text || ' PT)');

      UPDATE public.marketplace_transactions
      SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'penalita_punti')
      WHERE id = v_target_polizza.id;
    END IF;

    v_dettagli := jsonb_build_object('target_team_id', p_target_team_id, 'target_team_name', v_target_team_name, 'points_deducted', 20);

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'trappola' THEN
    SELECT COALESCE(SUM(s.punti), 0)::integer INTO v_target_points
    FROM public.scores s WHERE s.team_id = p_target_team_id;
    
    v_points_to_steal := LEAST(30, GREATEST(0, v_target_points));
    v_stolen_points := v_points_to_steal;

    IF v_stolen_points > 0 THEN
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, -v_stolen_points, 'penalty', 'Trappola subita da ' || v_team.nome_squadra || ': −' || v_stolen_points::text || ' PT');

      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_stolen_points, 'bonus_punti', 'Punti rubati con Trappola a ' || v_target_team_name || ': +' || v_stolen_points::text || ' PT');

      -- Polizza rimborso 50%
      SELECT * INTO v_target_polizza
      FROM public.marketplace_transactions
      WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
      ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

      IF FOUND THEN
        v_refund := CEIL(v_stolen_points / 2.0)::integer;
        IF v_refund > 0 THEN
          INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
          VALUES (p_target_team_id, v_refund, 'bonus_polizza', 'Polizza Diretta: Rimborso 50% punti rubati (+' || v_refund::text || ' PT)');

          UPDATE public.marketplace_transactions
          SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'trappola')
          WHERE id = v_target_polizza.id;
        END IF;
      END IF;
    END IF;

    v_dettagli := jsonb_build_object('stolen_points', v_stolen_points, 'target_team_id', p_target_team_id, 'target_team_name', v_target_team_name);

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'tassa_passaggio' THEN
    -- Calcolo atomico ed esatto dei punteggi di gara LIVE (esclusivamente public.scores)
    SELECT COALESCE(SUM(s.punti), 0)::integer INTO v_buyer_points
    FROM public.scores s WHERE s.team_id = v_team_id;

    SELECT COALESCE(SUM(s.punti), 0)::integer INTO v_target_points
    FROM public.scores s WHERE s.team_id = p_target_team_id;

    -- Inserisce la compensazione esatta in scores per rendere Total_A_after = Total_B_before e viceversa
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, (v_target_points - v_buyer_points), 'switch_punti', 'Tassa di Passaggio: Switch punti con ' || v_target_team_name);

    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (p_target_team_id, (v_buyer_points - v_target_points), 'switch_punti', 'Tassa di Passaggio: Switch punti con ' || v_team.nome_squadra);

    -- Polizza Diretta rimborso per il bersaglio se perde punti nello switch
    IF v_buyer_points < v_target_points THEN
      SELECT * INTO v_target_polizza
      FROM public.marketplace_transactions
      WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
      ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

      IF FOUND THEN
        v_refund := CEIL((v_target_points - v_buyer_points) / 2.0)::integer;
        IF v_refund > 0 THEN
          INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
          VALUES (p_target_team_id, v_refund, 'bonus_polizza', 'Polizza Diretta: Rimborso 50% perdita switch (+' || v_refund::text || ' PT)');

          UPDATE public.marketplace_transactions
          SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'tassa_passaggio')
          WHERE id = v_target_polizza.id;
        END IF;
      END IF;
    END IF;

    v_dettagli := jsonb_build_object(
      'buyer_points_before', v_buyer_points,
      'target_points_before', v_target_points,
      'buyer_points_after', v_target_points,
      'target_points_after', v_buyer_points
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'freeze_2min' THEN
    UPDATE public.teams
    SET freeze_started_at = COALESCE(
          CASE WHEN freeze_expires_at > now() THEN freeze_started_at ELSE now() END,
          now()
        ),
        freeze_expires_at = GREATEST(now(), COALESCE(freeze_expires_at, now())) + INTERVAL '120 seconds',
        freeze_duration_seconds = COALESCE(freeze_duration_seconds, 0) + 120
    WHERE id = p_target_team_id
    RETURNING freeze_expires_at INTO v_freeze_expires_at;

    v_dettagli := jsonb_build_object(
      'duration_seconds', 120,
      'freeze_expires_at', v_freeze_expires_at,
      'attacker_id', v_team_id,
      'attacker_name', v_team.nome_squadra
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'blackout_mercato' THEN
    v_dettagli := jsonb_build_object(
      'duration_seconds', 360,
      'expires_at', now() + INTERVAL '6 minutes',
      'attacker_id', v_team_id,
      'attacker_name', v_team.nome_squadra
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'dimezza_punti' THEN
    IF p_target_stage_id IS NULL THEN
      RAISE EXCEPTION 'È obbligatorio selezionare una tappa da colpire per il malus DIMEZZA PUNTI TAPPA.';
    END IF;

    SELECT * INTO v_target_stage FROM public.stages WHERE id = p_target_stage_id;
    IF NOT FOUND OR v_target_stage.numero_tappa < 1 OR v_target_stage.numero_tappa > 4 THEN
      RAISE EXCEPTION 'Tappa non valida. È possibile selezionare esclusivamente le Tappe 1, 2, 3 o 4.';
    END IF;

    SELECT COUNT(*) INTO v_stage_tot_ch FROM public.challenges WHERE stage_id = p_target_stage_id;
    SELECT COUNT(DISTINCT tp.challenge_id) INTO v_stage_comp_ch
    FROM public.team_progress tp
    JOIN public.challenges c ON c.id = tp.challenge_id
    WHERE tp.team_id = p_target_team_id AND c.stage_id = p_target_stage_id AND tp.stato = 'completed';

    IF v_stage_tot_ch > 0 AND v_stage_comp_ch >= v_stage_tot_ch THEN
      SELECT COALESCE(SUM(punti), 0)::integer INTO v_full_stage_score
      FROM public.scores
      WHERE team_id = p_target_team_id
        AND stage_id = p_target_stage_id
        AND (tipo_modificatore IS NULL OR tipo_modificatore != 'penalty_dimezza_tappa');

      IF v_full_stage_score > 0 THEN
        v_stage_penalty := FLOOR(v_full_stage_score / 2.0)::integer;
        
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (
          p_target_team_id,
          p_target_stage_id,
          -v_stage_penalty,
          'penalty_dimezza_tappa',
          'Malus Dimezza Punti Tappa ' || v_target_stage.numero_tappa::text || ': penalità −' || v_stage_penalty::text || ' PT (50% del punteggio complessivo della tappa)'
        );

        -- Polizza Diretta rimborso
        SELECT * INTO v_target_polizza
        FROM public.marketplace_transactions
        WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
        ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

        IF FOUND AND v_stage_penalty > 0 THEN
          v_polizza_refund := CEIL(v_stage_penalty / 2.0)::integer;
          IF v_polizza_refund > 0 THEN
            INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
            VALUES (
              p_target_team_id,
              p_target_stage_id,
              v_polizza_refund,
              'bonus_polizza',
              'Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+' || v_polizza_refund::text || ' PT)'
            );

            UPDATE public.marketplace_transactions
            SET stato = 'used',
                data_utilizzo = now(),
                dettagli = jsonb_build_object('refunded_points', v_polizza_refund, 'source_malus', 'dimezza_punti', 'target_stage_id', p_target_stage_id)
            WHERE id = v_target_polizza.id;
          END IF;
        END IF;
      ELSE
        v_stage_penalty := 0;
      END IF;

      v_dettagli := jsonb_build_object(
        'target_stage_id', p_target_stage_id,
        'stage_number', v_target_stage.numero_tappa,
        'stage_title', v_target_stage.titolo,
        'target_team_id', p_target_team_id,
        'target_team_name', v_target_team_name,
        'attacker_name', v_team.nome_squadra,
        'applied_mode', 'immediate_completed',
        'stage_status_at_purchase', 'completed',
        'stage_score_before', v_full_stage_score,
        'penalty_applied', v_stage_penalty,
        'stage_score_after', v_full_stage_score - v_stage_penalty
      );

      INSERT INTO public.marketplace_transactions (
        team_id, target_team_id, stage_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
      ) VALUES (
        v_team_id, p_target_team_id, p_target_stage_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
      ) RETURNING id INTO v_tx_id;
    ELSE
      v_dettagli := jsonb_build_object(
        'target_stage_id', p_target_stage_id,
        'stage_number', v_target_stage.numero_tappa,
        'stage_title', v_target_stage.titolo,
        'target_team_id', p_target_team_id,
        'target_team_name', v_target_team_name,
        'attacker_name', v_team.nome_squadra,
        'applied_mode', 'pending_future',
        'stage_status_at_purchase', CASE WHEN v_stage_comp_ch > 0 THEN 'in_progress' ELSE 'not_started' END
      );

      INSERT INTO public.marketplace_transactions (
        team_id, target_team_id, stage_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
      ) VALUES (
        v_team_id, p_target_team_id, p_target_stage_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
      ) RETURNING id INTO v_tx_id;
    END IF;

  ELSIF p_item_id = 'enigma_extra' OR p_item_id = 'ruota_sfortunata' THEN
    v_dettagli := jsonb_build_object(
      'target_team_id', p_target_team_id,
      'target_team_name', v_target_team_name,
      'assigned_at', now(),
      'attacker_id', v_team_id,
      'attacker_name', v_team.nome_squadra
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;
  END IF;

  -- 9. REGISTRAZIONE LOG ATTIVITÀ
  INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
  VALUES (
    'marketplace_purchase', v_team_id, p_target_team_id,
    jsonb_build_object(
      'item_id', p_item_id,
      'item_name', v_item.nome,
      'buyer_team_name', v_team.nome_squadra,
      'target_team_name', v_target_team_name,
      'cost', v_item.costo_token,
      'outcome', v_dettagli
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'transaction_id', v_tx_id,
    'new_balance', v_team.token_balance - v_item.costo_token,
    'shielded', false,
    'outcome', v_dettagli
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.buy_secret_code_part()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_buyer_id UUID;
  v_match RECORD;
  v_buyer RECORD;
  v_seller RECORD;
  v_cost INTEGER;
  v_full_code TEXT;
  v_digits TEXT;
BEGIN
  v_buyer_id := public.current_team_id();
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Verifica se già acquistato
  IF EXISTS (SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = v_buyer_id) THEN
    RETURN jsonb_build_object('success', true, 'message', 'Frammento già acquistato');
  END IF;

  -- Assicura match
  PERFORM public.get_secret_code_state(v_buyer_id);
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = v_buyer_id;

  v_cost := COALESCE(v_match.token_cost, 4);

  SELECT * INTO v_buyer FROM public.teams WHERE id = v_buyer_id FOR UPDATE;
  IF (v_buyer.token_balance < v_cost) THEN
    RAISE EXCEPTION 'Token insufficienti (Costo: % Token, Tuo saldo: %)', v_cost, v_buyer.token_balance;
  END IF;

  -- Scala token al compratore
  UPDATE public.teams SET token_balance = token_balance - v_cost WHERE id = v_buyer_id;

  -- Accredita token al venditore se presente
  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> v_buyer_id THEN
    UPDATE public.teams SET token_balance = token_balance + v_cost WHERE id = v_match.seller_team_id;
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_digits := CASE WHEN v_match.required_part = 'FIRST_5' THEN SUBSTRING(v_full_code FROM 1 FOR 5) ELSE SUBSTRING(v_full_code FROM 6 FOR 5) END;

  -- Registra transazione nella tabella dedicata code_purchase_transactions
  INSERT INTO public.code_purchase_transactions (
    buyer_team_id, seller_team_id, token_cost, digits_received
  )
  VALUES (
    v_buyer_id, COALESCE(v_match.seller_team_id, v_buyer_id), v_cost, v_digits
  )
  ON CONFLICT (buyer_team_id) DO NOTHING;

  -- Registra log attività
  INSERT INTO public.activity_log (team_id, target_team_id, tipo_evento, dettagli)
  VALUES (
    v_buyer_id, 
    v_match.seller_team_id, 
    'buy_secret_code_part', 
    jsonb_build_object('cost', v_cost, 'digits', v_digits)
  );

  RETURN jsonb_build_object('success', true, 'digits', v_digits, 'cost', v_cost);
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_final_game_results(p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_report JSONB;
  v_calculated_at TIMESTAMPTZ := now();
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NULL
     OR NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  WITH
  active_teams AS (
    SELECT
      t.id,
      t.nome_squadra,
      t.avatar_url,
      COALESCE(t.colore, t.color) AS color,
      t.motto,
      t.created_at,
      COALESCE(t.token_balance, 0) AS token_balance
    FROM public.teams t
    WHERE COALESCE(t.active, true)
  ),

  score_totals AS (
    SELECT
      s.team_id,
      COALESCE(SUM(s.punti), 0)::INTEGER AS total_score,
      COALESCE(
        SUM(CASE WHEN s.challenge_id IS NOT NULL THEN s.punti ELSE 0 END),
        0
      )::INTEGER AS challenges_points,
      COALESCE(
        SUM(CASE WHEN s.challenge_id IS NULL THEN s.punti ELSE 0 END),
        0
      )::INTEGER AS modifier_points
    FROM public.scores s
    GROUP BY s.team_id
  ),

  cattiveria_totals AS (
    SELECT
      c.team_id,
      COALESCE(SUM(c.punti), 0)::INTEGER AS cattiveria_points
    FROM public.cattiveria_ledger c
    GROUP BY c.team_id
  ),

  completed_totals AS (
    SELECT
      tp.team_id,
      COUNT(*) FILTER (
        WHERE tp.stato IN ('completed', 'completata', 'done')
      )::INTEGER AS completed_challenges,
      MAX(tp.completata_il) AS last_completion
    FROM public.team_progress tp
    GROUP BY tp.team_id
  ),

  session_totals AS (
    SELECT
      rs.team_id,
      COALESCE(SUM(rs.duration_seconds), 0)::BIGINT AS session_seconds
    FROM public.race_sessions rs
    WHERE rs.duration_seconds IS NOT NULL
    GROUP BY rs.team_id
  ),

  penalty_totals AS (
    SELECT
      tp.team_id,
      COALESCE(SUM(tp.minuti_penalita * 60), 0)::BIGINT AS penalty_seconds
    FROM public.time_penalties tp
    GROUP BY tp.team_id
  ),

  early_start_totals AS (
    SELECT
      mt.team_id,
      COUNT(*)::INTEGER AS early_start_count
    FROM public.marketplace_transactions mt
    JOIN public.marketplace_items mi
      ON mi.id = mt.marketplace_item_id
    WHERE LOWER(COALESCE(mi.id::TEXT, '')) = 'partenza_anticipata'
       OR LOWER(COALESCE(mi.nome, '')) LIKE '%partenza anticipata%'
    GROUP BY mt.team_id
  ),

  team_base AS (
    SELECT
      t.id,
      t.nome_squadra,
      t.avatar_url,
      t.color,
      t.motto,
      t.created_at,
      t.token_balance,

      COALESCE(st.total_score, 0)
        + COALESCE(ct.cattiveria_points, 0)
        AS base_score,

      COALESCE(st.challenges_points, 0) AS challenges_points,
      COALESCE(st.modifier_points, 0) AS modifier_points,
      COALESCE(ct.cattiveria_points, 0) AS cattiveria_points,

      COALESCE(comp.completed_challenges, 0)
        AS completed_challenges,

      comp.last_completion,

      CASE
        WHEN COALESCE(ss.session_seconds, 0) > 0
          THEN ss.session_seconds
        WHEN comp.last_completion IS NOT NULL
          THEN GREATEST(
            0,
            EXTRACT(
              EPOCH
              FROM (comp.last_completion - t.created_at)
            )::BIGINT
          )
        ELSE 0
      END
      + COALESCE(pt.penalty_seconds, 0)
      - (COALESCE(es.early_start_count, 0) * 120)
      AS total_time_seconds,

      COALESCE(es.early_start_count, 0) AS early_start_count,
      COALESCE(ss.session_seconds, 0) AS race_session_seconds,
      COALESCE(pt.penalty_seconds, 0) AS penalty_seconds

    FROM active_teams t
    LEFT JOIN score_totals st ON st.team_id = t.id
    LEFT JOIN cattiveria_totals ct ON ct.team_id = t.id
    LEFT JOIN completed_totals comp ON comp.team_id = t.id
    LEFT JOIN session_totals ss ON ss.team_id = t.id
    LEFT JOIN penalty_totals pt ON pt.team_id = t.id
    LEFT JOIN early_start_totals es ON es.team_id = t.id
  ),

  ranked_by_time AS (
    SELECT
      tb.*,
      DENSE_RANK() OVER (
        ORDER BY
          tb.total_time_seconds ASC,
          tb.last_completion ASC NULLS LAST,
          tb.created_at ASC
      )::INTEGER AS time_rank
    FROM team_base tb
  ),

  scored AS (
    SELECT
      r.*,
      public._get_time_bonus_points(r.time_rank) AS time_bonus,
      FLOOR(r.token_balance / 5)::INTEGER AS token_efficiency_bonus
    FROM ranked_by_time r
  ),

  final_ranked AS (
    SELECT
      s.*,
      (
        s.base_score
        + s.time_bonus
        + s.token_efficiency_bonus
      )::INTEGER AS final_score
    FROM scored s
  ),

  final_positions AS (
    SELECT
      f.*,
      ROW_NUMBER() OVER (
        ORDER BY
          f.final_score DESC,
          f.completed_challenges DESC,
          f.total_time_seconds ASC,
          f.last_completion ASC NULLS LAST,
          f.created_at ASC
      )::INTEGER AS final_rank
    FROM final_ranked f
  )

  SELECT jsonb_build_object(
    'teams',
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', fp.id,
          'team_id', fp.id,
          'name', fp.nome_squadra,
          'team_name', fp.nome_squadra,
          'nome_squadra', fp.nome_squadra,
          'avatar_url', fp.avatar_url,
          'color', fp.color,
          'motto', fp.motto,
          'rank', fp.final_rank,
          'position', fp.final_rank,
          'final_rank', fp.final_rank,
          'time_rank', fp.time_rank,
          'completed_challenges', fp.completed_challenges,
          'challenges_points', fp.challenges_points,
          'modifier_points', fp.modifier_points,
          'cattiveria_points', fp.cattiveria_points,
          'base_score', fp.base_score,
          'total_score_before_final_bonuses', fp.base_score,
          'time_bonus', fp.time_bonus,
          'bonus_tempo', fp.time_bonus,
          'token_balance', fp.token_balance,
          'token_efficiency_bonus', fp.token_efficiency_bonus,
          'final_score', fp.final_score,
          'total_points', fp.final_score,
          'total_duration_seconds', fp.total_time_seconds,
          'total_time_seconds', fp.total_time_seconds,
          'race_session_seconds', fp.race_session_seconds,
          'penalty_seconds', fp.penalty_seconds,
          'partenza_anticipata_count', fp.early_start_count,
          'partenza_anticipata', (fp.early_start_count > 0),
          'last_completion', fp.last_completion
        )
        ORDER BY fp.final_rank
      ),
      '[]'::jsonb
    ),
    'stages',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', st.id,
            'name', st.titolo,
            'order', st.numero_tappa,
            'status', st.stato,
            'challenges_count',
              (
                SELECT COUNT(*)
                FROM public.challenges c
                WHERE c.stage_id = st.id
              )
          )
          ORDER BY st.numero_tappa
        )
        FROM public.stages st
      ),
      '[]'::jsonb
    )
  )
  INTO v_report
  FROM final_positions fp;

  UPDATE public.game_report
  SET snapshot = v_report,
      updated_at = v_calculated_at
  WHERE id = 'current';

  IF NOT FOUND THEN
    INSERT INTO public.game_report (
      id,
      state,
      published_at,
      published_by,
      snapshot,
      updated_at
    )
    VALUES (
      'current',
      'PRIVATE_LIVE',
      NULL,
      NULL,
      v_report,
      v_calculated_at
    );
  END IF;

  INSERT INTO public.activity_log (
    id,
    tipo_evento,
    team_id,
    target_team_id,
    dettagli,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'CALCULATE_FINAL_RESULTS',
    NULL,
    NULL,
    jsonb_build_object(
      'admin_id', p_admin_id,
      'calculated_at', v_calculated_at
    ),
    v_calculated_at
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'CALCULATED',
    'calculated_at', v_calculated_at,
    'report', v_report
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_stage(p_stage_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_stage RECORD;
  v_stage_reward INTEGER;
  v_team RECORD;
  v_already_rewarded BOOLEAN;
  v_rewarded_count INTEGER := 0;
BEGIN
  SELECT (public.has_role(auth.uid(), 'admin') OR auth.role() = 'service_role') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_stage FROM public.stages WHERE id = p_stage_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tappa non trovata';
  END IF;

  v_stage_reward := CASE WHEN v_stage.numero_tappa = 5 THEN 20 ELSE 10 END;

  UPDATE public.stages SET stato = 'closed' WHERE id = p_stage_id;

  FOR v_team IN SELECT * FROM public.teams WHERE active = true LOOP
    IF (SELECT COUNT(*) FROM public.challenges WHERE stage_id = p_stage_id) > 0 AND
       (SELECT COUNT(*) FROM public.team_progress tp JOIN public.challenges c ON c.id = tp.challenge_id WHERE tp.team_id = v_team.id AND c.stage_id = p_stage_id AND tp.stato = 'completed') >= (SELECT COUNT(*) FROM public.challenges WHERE stage_id = p_stage_id) THEN
       
       SELECT EXISTS (
         SELECT 1 FROM public.marketplace_transactions
         WHERE team_id = v_team.id
           AND stage_id = p_stage_id
           AND (marketplace_item_id = 'reward_stage' OR (dettagli->>'stage_reward')::boolean = true)
       ) INTO v_already_rewarded;

       IF NOT v_already_rewarded THEN
         UPDATE public.teams SET token_balance = COALESCE(token_balance, 50) + v_stage_reward WHERE id = v_team.id;

         INSERT INTO public.marketplace_transactions (
           id, team_id, marketplace_item_id, costo_token, stato, data_acquisto, stage_id, dettagli
         ) VALUES (
           gen_random_uuid(),
           v_team.id,
           'reward_stage',
           -v_stage_reward,
           'completed',
           now(),
           p_stage_id,
           jsonb_build_object(
             'stage_reward', true,
             'stage_id', p_stage_id,
             'stage_name', v_stage.titolo,
             'stage_index', v_stage.numero_tappa,
             'reward_tokens', v_stage_reward
           )
         );

         v_rewarded_count := v_rewarded_count + 1;
       END IF;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'stage_id', p_stage_id, 'rewarded_teams', v_rewarded_count);
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
BEGIN
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
    AND marketplace_item_id = 'moltiplicatore_2x'
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
  WHERE stage_id = v_challenge.stage_id;

  SELECT COUNT(DISTINCT challenge_id) INTO v_completed_challenges_count
  FROM public.team_progress
  WHERE team_id = v_team_id
    AND challenge_id IN (SELECT id FROM public.challenges WHERE stage_id = v_challenge.stage_id)
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
    WHERE id = v_team_id;

    INSERT INTO public.marketplace_transactions (team_id, stage_id, marketplace_item_id, costo_token, stato, dettagli)
    VALUES (
      v_team_id, v_challenge.stage_id, 'reward_stage', -v_stage_reward, 'completed',
      jsonb_build_object(
        'stage_id', v_challenge.stage_id,
        'stage_index', v_stage_number,
        'position', v_stage_arrival_pos,
        'reward_tokens', v_stage_reward
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

CREATE OR REPLACE FUNCTION public.confirm_photo_score(p_submission_id uuid, p_points integer, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_sub RECORD;
  v_stage_id UUID;
  v_challenge RECORD;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = v_sub.challenge_id;
  v_stage_id := v_challenge.stage_id;

  -- Aggiorna stato approvazione su submissions a 'confirmed'
  UPDATE public.submissions 
  SET stato_approvazione = 'confirmed' 
  WHERE id = p_submission_id;

  -- Segna progresso come completed
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la stessa sfida e inserisce quello nuovo confermato
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_sub.challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, v_stage_id, p_points, 'challenge_points', 'Valutazione foto: ' || COALESCE(v_challenge.titolo, 'Foto'));

  RETURN jsonb_build_object('success', true, 'points', p_points, 'submission_id', p_submission_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.consume_marketplace_transaction(p_transaction_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_team_id UUID;
  v_is_admin BOOLEAN;
  v_tx RECORD;
BEGIN
  IF auth.uid() IS NULL AND auth.role() <> 'service_role' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;
  v_team_id := public.current_team_id();
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;

  SELECT * INTO v_tx
  FROM public.marketplace_transactions
  WHERE id = p_transaction_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  -- Verifica autorizzazione: acquirente, bersaglio o admin
  IF NOT COALESCE(v_is_admin, false) AND v_team_id IS NOT NULL AND v_tx.team_id != v_team_id AND (v_tx.target_team_id IS NULL OR v_tx.target_team_id != v_team_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autorizzato');
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used',
      data_utilizzo = now()
  WHERE id = p_transaction_id;

  -- Se era un freeze_2min, ripuliamo freeze sulla squadra bersaglio
  -- (solo se non restano altri freeze in coda per la stessa squadra: i freeze si scontano uno dopo l'altro)
  IF v_tx.marketplace_item_id = 'freeze_2min' AND v_tx.target_team_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM public.marketplace_transactions
       WHERE target_team_id = v_tx.target_team_id
         AND marketplace_item_id = 'freeze_2min'
         AND stato = 'completed'
         AND id <> p_transaction_id
     ) THEN
    UPDATE public.teams
    SET freeze_expires_at = NULL,
        freeze_started_at = NULL,
        freeze_duration_seconds = 0
    WHERE id = v_tx.target_team_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'transaction_id', p_transaction_id, 'new_status', 'used');
END;
$function$;

CREATE OR REPLACE FUNCTION public.current_team_id()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
BEGIN
  SELECT team_id INTO v_team_id
  FROM public.user_roles
  WHERE user_id = auth.uid() AND role = 'team'
  LIMIT 1;
  
  RETURN v_team_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_team_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF OLD.owner_id IS NOT NULL THEN
    DELETE FROM public.user_roles WHERE user_id = OLD.owner_id;
    DELETE FROM auth.users WHERE id = OLD.owner_id;
  END IF;
  RETURN OLD;
END;
$function$;

CREATE OR REPLACE FUNCTION public.end_global_race(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_now TIMESTAMPTZ := now();
BEGIN
  PERFORM public.assert_admin_caller();
  UPDATE public.game_settings
  SET
    race_status = 'completed',
    race_ended_at = v_now
  WHERE id = 'settings_01';

  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'race_ended',
    jsonb_build_object('message', '🏆 LA GARA È CONCLUSA! Il tempo finale è stato registrato.', 'ended_at', v_now)
  );

  RETURN jsonb_build_object('success', true, 'race_status', 'completed', 'race_ended_at', v_now);
END;
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_poster(p_submission_id uuid, p_voto integer, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_sub RECORD;
  v_challenge RECORD;
  v_stage RECORD;
  v_stage_id UUID;
  v_total INTEGER := 0;
  v_completed INTEGER := 0;
  v_already_rewarded BOOLEAN := false;
  v_stage_reward INTEGER := 0;
  v_team_name TEXT;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = v_sub.challenge_id;
  v_stage_id := v_challenge.stage_id;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_sub.team_id;

  -- Aggiorna submission
  UPDATE public.submissions
  SET voto = p_voto,
      stato_approvazione = 'confirmed'
  WHERE id = p_submission_id;

  -- Aggiorna progresso team
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la stessa sfida e inserisce quello nuovo
  DELETE FROM public.scores
  WHERE team_id = v_sub.team_id AND challenge_id = v_sub.challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, v_stage_id, p_voto, 'challenge_points', 'Valutazione Locandina Vivente (' || p_voto || '/15 PT)');

  -- Controlla se con questa approvazione la tappa è completata
  SELECT COUNT(*)::INTEGER INTO v_total FROM public.challenges WHERE stage_id = v_stage_id;

  SELECT COUNT(*)::INTEGER INTO v_completed
  FROM public.team_progress tp
  JOIN public.challenges c ON c.id = tp.challenge_id
  WHERE tp.team_id = v_sub.team_id AND c.stage_id = v_stage_id AND tp.stato = 'completed';

  IF v_total > 0 AND v_completed >= v_total THEN
    SELECT EXISTS (
      SELECT 1 FROM public.marketplace_transactions
      WHERE team_id = v_sub.team_id
        AND stage_id = v_stage_id
        AND (marketplace_item_id = 'reward_stage' OR (dettagli->>'stage_reward')::boolean = true)
    ) INTO v_already_rewarded;

    IF NOT v_already_rewarded THEN
      SELECT * INTO v_stage FROM public.stages WHERE id = v_stage_id;
      v_stage_reward := CASE WHEN v_stage.numero_tappa = 5 THEN 20 ELSE 10 END;

      UPDATE public.teams
      SET token_balance = COALESCE(token_balance, 50) + v_stage_reward
      WHERE id = v_sub.team_id;

      INSERT INTO public.marketplace_transactions (
        id, team_id, marketplace_item_id, costo_token, stato, data_acquisto, stage_id, dettagli
      ) VALUES (
        gen_random_uuid(),
        v_sub.team_id,
        'reward_stage',
        -v_stage_reward,
        'completed',
        now(),
        v_stage_id,
        jsonb_build_object(
          'stage_reward', true,
          'stage_id', v_stage_id,
          'stage_name', v_stage.titolo,
          'stage_index', v_stage.numero_tappa,
          'reward_tokens', v_stage_reward
        )
      );

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES (
        'stage_reward_credited',
        v_sub.team_id,
        jsonb_build_object(
          'message', 'La squadra  || COALESCE(v_team_name, ) ||  ha completato la Tappa ' || v_stage.numero_tappa || ' e ha ricevuto +' || v_stage_reward || ' Token! 🪙',
          'stage_id', v_stage_id,
          'tokens_added', v_stage_reward
        )
      );
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'voto', p_voto, 'submission_id', p_submission_id, 'stage_reward', v_stage_reward);
END;
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_social_challenge(p_submission_id uuid, p_voto integer, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_sub RECORD;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
  v_stage_id UUID;
BEGIN
  PERFORM public.assert_admin_caller();
  -- Cerca prima in team_social_submissions
  SELECT * INTO v_sub FROM public.team_social_submissions WHERE id = p_submission_id;
  
  IF NOT FOUND THEN
    -- Fallback se passato id da submissions
    SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Sottomissione social non trovata';
    END IF;
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  -- Aggiorna team_social_submissions
  UPDATE public.team_social_submissions 
  SET status = 'approved',
      stato_approvazione = 'confirmed',
      admin_score = p_voto
  WHERE id = p_submission_id OR (team_id = v_sub.team_id AND challenge_id = v_challenge_id);

  -- Aggiorna anche submissions principale se presente
  UPDATE public.submissions 
  SET stato_approvazione = 'confirmed',
      voto = p_voto
  WHERE team_id = v_sub.team_id AND challenge_id = v_challenge_id;

  -- Segna progresso come completato
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la missione social e inserisce il voto confermato
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_challenge_id, v_stage_id, p_voto, 'challenge_points', 'Valutazione Missione Social (' || p_voto || '/20 PT)');

  RETURN jsonb_build_object('success', true, 'voto', p_voto, 'submission_id', p_submission_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_boxe_tournament(p_admin_id uuid DEFAULT NULL::uuid, p_special_bye_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';

  v_bye_team UUID;
  v_team_ids UUID[];
  v_count INTEGER;
  v_main_size INTEGER;
  v_prelim_matches INTEGER;

  v_prelim_teams UUID[];
  v_direct_teams UUID[];

  v_index INTEGER;
  v_match_index INTEGER;
  v_round INTEGER;
  v_round_matches INTEGER;

  v_team1 UUID;
  v_team2 UUID;
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NOT NULL
     AND NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT boxe_special_bye_team_id
  INTO v_bye_team
  FROM public.game_settings
  WHERE id = 'settings_01';

  v_bye_team := COALESCE(p_special_bye_team_id, v_bye_team);

  SELECT ARRAY_AGG(id ORDER BY created_at, id)
  INTO v_team_ids
  FROM public.teams
  WHERE COALESCE(active, true);

  v_count := COALESCE(array_length(v_team_ids, 1), 0);

  IF v_count < 2 THEN
    RAISE EXCEPTION 'Servono almeno 2 squadre attive';
  END IF;

  DELETE FROM public.boxe_matches
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.scores
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.team_progress
  WHERE challenge_id = v_challenge_id;

  IF v_bye_team IS NOT NULL
     AND NOT (v_bye_team = ANY(v_team_ids)) THEN
    v_bye_team := NULL;
  END IF;

  UPDATE public.game_settings
  SET boxe_special_bye_team_id = v_bye_team
  WHERE id = 'settings_01';

  v_main_size := 1;

  WHILE v_main_size * 2 <= v_count LOOP
    v_main_size := v_main_size * 2;
  END LOOP;

  v_prelim_matches := v_count - v_main_size;

  IF v_prelim_matches = 0 THEN

    v_match_index := 0;
    v_index := 1;

    WHILE v_index <= v_count LOOP
      INSERT INTO public.boxe_matches (
        id, challenge_id, round, match_index,
        team1_id, team2_id, winner_id, status, completed_at
      )
      VALUES (
        gen_random_uuid(),
        v_challenge_id,
        0,
        v_match_index,
        v_team_ids[v_index],
        v_team_ids[v_index + 1],
        NULL,
        'ready',
        NULL
      );

      v_match_index := v_match_index + 1;
      v_index := v_index + 2;
    END LOOP;

    v_round := 1;
    v_round_matches := v_main_size / 2;

    WHILE v_round_matches >= 1 LOOP
      FOR v_match_index IN 0..v_round_matches - 1 LOOP
        INSERT INTO public.boxe_matches (
          id, challenge_id, round, match_index,
          team1_id, team2_id, winner_id, status, completed_at
        )
        VALUES (
          gen_random_uuid(),
          v_challenge_id,
          v_round,
          v_match_index,
          NULL,
          NULL,
          NULL,
          'pending',
          NULL
        );
      END LOOP;

      EXIT WHEN v_round_matches = 1;
      v_round_matches := v_round_matches / 2;
      v_round := v_round + 1;
    END LOOP;

  ELSE

    v_prelim_teams := ARRAY[]::UUID[];
    v_direct_teams := ARRAY[]::UUID[];

    IF v_bye_team IS NOT NULL THEN
      v_direct_teams := array_append(v_direct_teams, v_bye_team);
    END IF;

    FOR v_index IN 1..v_count LOOP
      IF v_team_ids[v_index] <> v_bye_team THEN
        IF array_length(v_direct_teams, 1) IS NOT NULL
           AND array_length(v_direct_teams, 1) < v_main_size THEN
          v_direct_teams := array_append(
            v_direct_teams,
            v_team_ids[v_index]
          );
        ELSE
          v_prelim_teams := array_append(
            v_prelim_teams,
            v_team_ids[v_index]
          );
        END IF;
      END IF;
    END LOOP;

    WHILE COALESCE(array_length(v_prelim_teams, 1), 0)
          > (2 * v_prelim_matches) LOOP
      v_direct_teams := array_append(
        v_direct_teams,
        v_prelim_teams[array_length(v_prelim_teams, 1)]
      );

      v_prelim_teams := v_prelim_teams[
        1:array_length(v_prelim_teams, 1) - 1
      ];
    END LOOP;

    WHILE COALESCE(array_length(v_prelim_teams, 1), 0)
          < (2 * v_prelim_matches) LOOP
      v_direct_teams := v_direct_teams[
        1:array_length(v_direct_teams, 1) - 1
      ];

      v_prelim_teams := array_append(
        v_prelim_teams,
        v_direct_teams[array_length(v_direct_teams, 1)]
      );
    END LOOP;

    v_match_index := 0;
    v_index := 1;

    WHILE v_match_index < v_prelim_matches LOOP
      INSERT INTO public.boxe_matches (
        id, challenge_id, round, match_index,
        team1_id, team2_id, winner_id, status, completed_at
      )
      VALUES (
        gen_random_uuid(),
        v_challenge_id,
        0,
        v_match_index,
        v_prelim_teams[v_index],
        v_prelim_teams[v_index + 1],
        NULL,
        'ready',
        NULL
      );

      v_match_index := v_match_index + 1;
      v_index := v_index + 2;
    END LOOP;

    v_round_matches := v_main_size / 2;

    FOR v_match_index IN 0..v_round_matches - 1 LOOP
      v_team1 := NULL;
      v_team2 := NULL;

      IF v_match_index >= v_prelim_matches THEN
        v_index :=
          1 + 2 * (v_match_index - v_prelim_matches);

        IF v_index <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team1 := v_direct_teams[v_index];
        END IF;

        IF v_index + 1 <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team2 := v_direct_teams[v_index + 1];
        END IF;
      END IF;

      INSERT INTO public.boxe_matches (
        id, challenge_id, round, match_index,
        team1_id, team2_id, winner_id, status, completed_at
      )
      VALUES (
        gen_random_uuid(),
        v_challenge_id,
        1,
        v_match_index,
        v_team1,
        v_team2,
        NULL,
        CASE
          WHEN v_team1 IS NOT NULL AND v_team2 IS NOT NULL
            THEN 'ready'
          ELSE 'pending'
        END,
        NULL
      );
    END LOOP;

    UPDATE public.boxe_matches
    SET
      winner_id = team1_id,
      status = 'completed',
      completed_at = now()
    WHERE challenge_id = v_challenge_id
      AND round = 1
      AND team1_id IS NOT NULL
      AND team2_id IS NULL;

    v_round := 2;
    v_round_matches := v_main_size / 4;

    WHILE v_round_matches >= 1 LOOP
      FOR v_match_index IN 0..v_round_matches - 1 LOOP
        INSERT INTO public.boxe_matches (
          id, challenge_id, round, match_index,
          team1_id, team2_id, winner_id, status, completed_at
        )
        VALUES (
          gen_random_uuid(),
          v_challenge_id,
          v_round,
          v_match_index,
          NULL,
          NULL,
          NULL,
          'pending',
          NULL
        );
      END LOOP;

      EXIT WHEN v_round_matches = 1;
      v_round_matches := v_round_matches / 2;
      v_round := v_round + 1;
    END LOOP;

  END IF;

  INSERT INTO public.activity_log (
    id, tipo_evento, team_id, target_team_id,
    dettagli, created_at
  )
  VALUES (
    gen_random_uuid(),
    'BOXE_GENERATED',
    NULL,
    NULL,
    jsonb_build_object(
      'admin_id', p_admin_id,
      'teams_count', v_count,
      'special_bye_team_id', v_bye_team
    ),
    now()
  );

  RETURN public.get_boxe_tournament();
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_cornhole_tournament(p_admin_id uuid DEFAULT NULL::uuid, p_special_bye_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';

  v_bye_team UUID;
  v_team_ids UUID[];
  v_count INTEGER;
  v_main_size INTEGER;
  v_prelim_matches INTEGER;

  v_prelim_teams UUID[];
  v_direct_teams UUID[];

  v_index INTEGER;
  v_match_index INTEGER;
  v_round INTEGER;
  v_round_matches INTEGER;

  v_team1 UUID;
  v_team2 UUID;
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NOT NULL
     AND NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT cornhole_special_bye_team_id
  INTO v_bye_team
  FROM public.game_settings
  WHERE id = 'settings_01';

  v_bye_team := COALESCE(p_special_bye_team_id, v_bye_team);

  SELECT ARRAY_AGG(id ORDER BY created_at, id)
  INTO v_team_ids
  FROM public.teams
  WHERE COALESCE(active, true);

  v_count := COALESCE(array_length(v_team_ids, 1), 0);

  IF v_count < 2 THEN
    RAISE EXCEPTION 'Servono almeno 2 squadre attive';
  END IF;

  DELETE FROM public.cornhole_matches
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.scores
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.team_progress
  WHERE challenge_id = v_challenge_id;

  IF v_bye_team IS NOT NULL
     AND NOT (v_bye_team = ANY(v_team_ids)) THEN
    v_bye_team := NULL;
  END IF;

  UPDATE public.game_settings
  SET cornhole_special_bye_team_id = v_bye_team
  WHERE id = 'settings_01';

  v_main_size := 1;

  WHILE v_main_size * 2 <= v_count LOOP
    v_main_size := v_main_size * 2;
  END LOOP;

  v_prelim_matches := v_count - v_main_size;

  /*
   * N è una potenza di due:
   * nessun preliminare.
   */
  IF v_prelim_matches = 0 THEN
    v_match_index := 0;
    v_index := 1;

    WHILE v_index <= v_count LOOP
      INSERT INTO public.cornhole_matches (
        id, challenge_id, round, match_index,
        team1_id, team2_id, winner_id, status, completed_at
      )
      VALUES (
        gen_random_uuid(),
        v_challenge_id,
        0,
        v_match_index,
        v_team_ids[v_index],
        v_team_ids[v_index + 1],
        NULL,
        'ready',
        NULL
      );

      v_match_index := v_match_index + 1;
      v_index := v_index + 2;
    END LOOP;

    v_round := 1;
    v_round_matches := v_main_size / 2;

    WHILE v_round_matches >= 1 LOOP
      FOR v_match_index IN 0..v_round_matches - 1 LOOP
        INSERT INTO public.cornhole_matches (
          id, challenge_id, round, match_index,
          team1_id, team2_id, winner_id, status, completed_at
        )
        VALUES (
          gen_random_uuid(),
          v_challenge_id,
          v_round,
          v_match_index,
          NULL,
          NULL,
          NULL,
          'pending',
          NULL
        );
      END LOOP;

      EXIT WHEN v_round_matches = 1;
      v_round_matches := v_round_matches / 2;
      v_round := v_round + 1;
    END LOOP;

  ELSE
    /*
     * Per N non-potenza-di-2:
     * i primi 2*P team giocano P preliminari.
     * I restanti team entrano direttamente nel round 1.
     */
    v_prelim_teams := ARRAY[]::UUID[];
    v_direct_teams := ARRAY[]::UUID[];

    /*
     * Il bye speciale viene forzato tra gli ingressi diretti.
     * In questo modo non consuma un match preliminare.
     */
    IF v_bye_team IS NOT NULL THEN
      v_direct_teams := array_append(v_direct_teams, v_bye_team);
    END IF;

    FOR v_index IN 1..v_count LOOP
      IF v_team_ids[v_index] <> v_bye_team THEN
        IF array_length(v_direct_teams, 1) IS NOT NULL
           AND array_length(v_direct_teams, 1) < v_main_size THEN
          v_direct_teams := array_append(
            v_direct_teams,
            v_team_ids[v_index]
          );
        ELSE
          v_prelim_teams := array_append(
            v_prelim_teams,
            v_team_ids[v_index]
          );
        END IF;
      END IF;
    END LOOP;

    /*
     * Assicura esattamente 2*P squadre nei preliminari.
     */
    WHILE COALESCE(array_length(v_prelim_teams, 1), 0)
          > (2 * v_prelim_matches) LOOP
      v_direct_teams := array_append(
        v_direct_teams,
        v_prelim_teams[
          array_length(v_prelim_teams, 1)
        ]
      );

      v_prelim_teams := v_prelim_teams[
        1:
        array_length(v_prelim_teams, 1) - 1
      ];
    END LOOP;

    WHILE COALESCE(array_length(v_prelim_teams, 1), 0)
          < (2 * v_prelim_matches) LOOP
      v_direct_teams := v_direct_teams[
        1:
        array_length(v_direct_teams, 1) - 1
      ];

      v_prelim_teams := array_append(
        v_prelim_teams,
        v_direct_teams[
          array_length(v_direct_teams, 1)
        ]
      );
    END LOOP;

    /*
     * Preliminari.
     */
    v_match_index := 0;
    v_index := 1;

    WHILE v_match_index < v_prelim_matches LOOP
      v_team1 := v_prelim_teams[v_index];
      v_team2 := v_prelim_teams[v_index + 1];

      INSERT INTO public.cornhole_matches (
        id, challenge_id, round, match_index,
        team1_id, team2_id, winner_id, status, completed_at
      )
      VALUES (
        gen_random_uuid(),
        v_challenge_id,
        0,
        v_match_index,
        v_team1,
        v_team2,
        NULL,
        'ready',
        NULL
      );

      v_match_index := v_match_index + 1;
      v_index := v_index + 2;
    END LOOP;

    /*
     * Round 1:
     * gli slot 0..P-1 ricevono i vincitori dei preliminari.
     * Gli altri slot ricevono gli ingressi diretti a coppie.
     */
    v_round_matches := v_main_size / 2;

    FOR v_match_index IN 0..v_round_matches - 1 LOOP
      v_team1 := NULL;
      v_team2 := NULL;

      IF v_match_index < v_prelim_matches THEN
        NULL;
      ELSE
        v_index :=
          1 + 2 * (v_match_index - v_prelim_matches);

        IF v_index <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team1 := v_direct_teams[v_index];
        END IF;

        IF v_index + 1 <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team2 := v_direct_teams[v_index + 1];
        END IF;
      END IF;

      INSERT INTO public.cornhole_matches (
        id, challenge_id, round, match_index,
        team1_id, team2_id, winner_id, status, completed_at
      )
      VALUES (
        gen_random_uuid(),
        v_challenge_id,
        1,
        v_match_index,
        v_team1,
        v_team2,
        NULL,
        CASE
          WHEN v_team1 IS NOT NULL AND v_team2 IS NOT NULL
            THEN 'ready'
          ELSE 'pending'
        END,
        NULL
      );
    END LOOP;

    /*
     * Se un ingresso diretto è solo e non ha avversario,
     * diventa automaticamente vincitore.
     */
    UPDATE public.cornhole_matches
    SET
      winner_id = team1_id,
      status = 'completed',
      completed_at = now()
    WHERE challenge_id = v_challenge_id
      AND round = 1
      AND team1_id IS NOT NULL
      AND team2_id IS NULL;

    /*
     * Round successivi vuoti.
     */
    v_round := 2;
    v_round_matches := v_main_size / 4;

    WHILE v_round_matches >= 1 LOOP
      FOR v_match_index IN 0..v_round_matches - 1 LOOP
        INSERT INTO public.cornhole_matches (
          id, challenge_id, round, match_index,
          team1_id, team2_id, winner_id, status, completed_at
        )
        VALUES (
          gen_random_uuid(),
          v_challenge_id,
          v_round,
          v_match_index,
          NULL,
          NULL,
          NULL,
          'pending',
          NULL
        );
      END LOOP;

      EXIT WHEN v_round_matches = 1;
      v_round_matches := v_round_matches / 2;
      v_round := v_round + 1;
    END LOOP;
  END IF;

  INSERT INTO public.activity_log (
    id, tipo_evento, team_id, target_team_id,
    dettagli, created_at
  )
  VALUES (
    gen_random_uuid(),
    'CORNHOLE_GENERATED',
    NULL,
    NULL,
    jsonb_build_object(
      'admin_id', p_admin_id,
      'teams_count', v_count,
      'special_bye_team_id', v_bye_team
    ),
    now()
  );

  RETURN public.get_cornhole_tournament();
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_auth_context_by_username(p_username text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_email TEXT;
  v_role TEXT;
BEGIN
  SELECT u.email, ur.role INTO v_email, v_role
  FROM auth.users u
  JOIN public.user_roles ur ON u.id = ur.user_id
  WHERE LOWER(ur.username) = LOWER(TRIM(p_username));
  
  IF v_email IS NOT NULL THEN
    RETURN jsonb_build_object('email', v_email, 'role', v_role);
  END IF;
  
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_bank_state(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.get_boxe_settings()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_cornhole_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_special_bye_team_id UUID;
  v_has_started BOOLEAN;
  v_first_place_team_id UUID;
BEGIN
  SELECT boxe_special_bye_team_id INTO v_special_bye_team_id
  FROM public.game_settings
  LIMIT 1;

  SELECT EXISTS(
    SELECT 1 FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  SELECT winner_id INTO v_first_place_team_id
  FROM public.cornhole_matches
  WHERE challenge_id = v_cornhole_challenge_id AND round = (SELECT MAX(round) FROM public.cornhole_matches WHERE challenge_id = v_cornhole_challenge_id)
  LIMIT 1;

  RETURN jsonb_build_object(
    'special_bye_team_id', v_special_bye_team_id,
    'started', v_has_started,
    'first_place_stage4_3', v_first_place_team_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_boxe_tournament()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_res JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;
  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_cornhole_settings()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_enigma3_id UUID := 'e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9';
  v_special_bye_team_id UUID;
  v_has_started BOOLEAN;
  v_first_place_team_id UUID;
BEGIN
  SELECT cornhole_special_bye_team_id INTO v_special_bye_team_id
  FROM public.game_settings
  LIMIT 1;

  SELECT EXISTS(
    SELECT 1 FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  SELECT team_id INTO v_first_place_team_id
  FROM public.team_progress
  WHERE challenge_id = v_enigma3_id AND stato = 'completed'
  ORDER BY completata_il ASC
  LIMIT 1;

  RETURN jsonb_build_object(
    'special_bye_team_id', v_special_bye_team_id,
    'started', v_has_started,
    'first_place_stage4_3', v_first_place_team_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_cornhole_tournament()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';

  v_result JSONB;
BEGIN
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', cm.id,
        'challenge_id', cm.challenge_id,
        'round', cm.round,
        'match_index', cm.match_index,
        'team1_id', cm.team1_id,
        'team2_id', cm.team2_id,
        'winner_id', cm.winner_id,
        'status', cm.status,
        'completed_at', cm.completed_at,
        'team1_name', t1.nome_squadra,
        'team2_name', t2.nome_squadra,
        'winner_name', tw.nome_squadra
      )
      ORDER BY cm.round, cm.match_index
    ),
    '[]'::jsonb
  )
  INTO v_result
  FROM public.cornhole_matches cm
  LEFT JOIN public.teams t1 ON t1.id = cm.team1_id
  LEFT JOIN public.teams t2 ON t2.id = cm.team2_id
  LEFT JOIN public.teams tw ON tw.id = cm.winner_id
  WHERE cm.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_enigma_state(p_challenge_id uuid, p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_attempts JSONB;
  v_is_completed BOOLEAN;
  v_prog RECORD;
BEGIN
  -- Admin può passare p_team_id, il team usa il proprio id
  v_team_id := COALESCE(p_team_id, public.current_team_id());
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_prog FROM public.team_progress
  WHERE team_id = v_team_id AND challenge_id = p_challenge_id;

  v_is_completed := (FOUND AND v_prog.stato = 'completed');

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', ea.id,
      'attempt_number', ea.attempt_number,
      'answer', ea.answer,
      'is_correct', ea.is_correct,
      'submitted_at', ea.submitted_at
    ) ORDER BY ea.attempt_number
  ), '[]'::jsonb)
  INTO v_attempts
  FROM public.enigma_attempts ea
  WHERE ea.team_id = v_team_id AND ea.challenge_id = p_challenge_id;

  RETURN jsonb_build_object(
    'attempts', v_attempts,
    'attempt_count', jsonb_array_length(v_attempts),
    'is_completed', v_is_completed,
    'completed_at', CASE WHEN v_is_completed THEN v_prog.completata_il ELSE NULL END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_game_report(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_is_admin BOOLEAN := false;
  v_report RECORD;
BEGIN
  v_caller_id := auth.uid();

  -- Check if caller is admin
  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
  END IF;

  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';

  -- IF NOT ADMIN:
  IF NOT COALESCE(v_is_admin, false) THEN
    -- If not published, strictly return null/locked status
    IF COALESCE(v_report.status, 'NOT_CALCULATED') != 'PUBLISHED' THEN
      RETURN jsonb_build_object(
        'is_published', false,
        'status', 'NOT_PUBLISHED',
        'published_at', NULL,
        'report', NULL
      );
    END IF;

    -- If published, return the frozen snapshot
    RETURN jsonb_build_object(
      'is_published', true,
      'status', 'PUBLISHED',
      'published_at', v_report.published_at,
      'report', v_report.snapshot
    );
  END IF;

  -- IF ADMIN:
  IF v_report.status = 'PUBLISHED' THEN
    RETURN jsonb_build_object(
      'is_published', true,
      'status', 'PUBLISHED',
      'calculated_at', v_report.calculated_at,
      'published_at', v_report.published_at,
      'report', COALESCE(v_report.snapshot, v_report.calculated_snapshot)
    );
  ELSIF v_report.status = 'CALCULATED' THEN
    RETURN jsonb_build_object(
      'is_published', false,
      'status', 'CALCULATED',
      'calculated_at', v_report.calculated_at,
      'published_at', NULL,
      'report', v_report.calculated_snapshot
    );
  ELSE
    RETURN jsonb_build_object(
      'is_published', false,
      'status', 'NOT_CALCULATED',
      'calculated_at', NULL,
      'published_at', NULL,
      'report', NULL
    );
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_jackpot_plays(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_res JSONB;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT COALESCE(jsonb_agg(row_to_json(p)), '[]'::jsonb) INTO v_res
  FROM (
    SELECT * FROM public.jackpot_plays
    WHERE challenge_id = v_challenge_id
    ORDER BY timestamp DESC
  ) p;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_jackpot_state(p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_play RECORD;
  v_current_score INTEGER := 0;
BEGIN
  v_team_id := COALESCE(p_team_id, public.current_team_id());

  IF v_team_id IS NOT NULL THEN
    SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_current_score
    FROM public.scores
    WHERE team_id = v_team_id;

    SELECT * INTO v_play
    FROM public.jackpot_plays
    WHERE team_id = v_team_id AND challenge_id = v_challenge_id
    ORDER BY timestamp DESC
    LIMIT 1;

    IF v_play.id IS NOT NULL THEN
      RETURN jsonb_build_object(
        'played', true,
        'play', row_to_json(v_play),
        'current_score', v_current_score
      );
    ELSE
      RETURN jsonb_build_object(
        'played', false,
        'play', NULL,
        'current_score', v_current_score
      );
    END IF;
  ELSE
    RETURN jsonb_build_object(
      'played', false,
      'play', NULL,
      'current_score', 0
    );
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_or_assign_poster(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_team_id UUID;
  v_poster RECORD;
  v_assigned RECORD;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  -- 1. Controlla se ha già un poster assegnato
  SELECT * INTO v_assigned FROM public.team_posters WHERE team_id = p_team_id LIMIT 1;
  IF FOUND THEN
    SELECT * INTO v_poster FROM public.posters WHERE id = v_assigned.poster_id;
    RETURN jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo);
  END IF;

  -- 2. Altrimenti seleziona il poster con meno assegnazioni. 
  --    In caso di parità, scegli quello con ID minore (deterministico).
  SELECT p.* INTO v_poster
  FROM public.posters p
  LEFT JOIN public.team_posters tp ON tp.poster_id = p.id
  WHERE p.active = true
  GROUP BY p.id, p.file_name, p.titolo
  ORDER BY COUNT(tp.id) ASC, p.id ASC
  LIMIT 1;

  IF FOUND THEN
    -- Inserimento sicuro con ON CONFLICT per prevenire race conditions
    INSERT INTO public.team_posters (team_id, poster_id) 
    VALUES (p_team_id, v_poster.id)
    ON CONFLICT (team_id) DO NOTHING;
    
    -- Rileggiamo in caso un'altra transazione abbia inserito nel frattempo (race condition vinta dall'altra transazione)
    SELECT p.* INTO v_poster 
    FROM public.posters p 
    JOIN public.team_posters tp ON tp.poster_id = p.id 
    WHERE tp.team_id = p_team_id;

    RETURN jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo);
  END IF;

  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_report_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_report RECORD;
BEGIN
  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';
  RETURN jsonb_build_object(
    'status', COALESCE(v_report.status, 'NOT_CALCULATED'),
    'is_calculated', (v_report.status IN ('CALCULATED', 'PUBLISHED')),
    'is_published', (v_report.status = 'PUBLISHED'),
    'calculated_at', v_report.calculated_at,
    'published_at', v_report.published_at
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_secret_code_state(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_team_id UUID;
  v_full_code TEXT;
  v_destination TEXT;
  v_part RECORD;
  v_match RECORD;
  v_seller_name TEXT := 'Regia';
  v_first5 TEXT;
  v_last5 TEXT;
  v_has_purchased BOOLEAN := false;
  v_purchased_digits TEXT := NULL;
  v_completed BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_other_team RECORD;
  v_team_idx INTEGER := 0;
  v_part_type TEXT;
  v_code_val TEXT;
  v_cost INTEGER := 4;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  SELECT full_code, next_stage_destination 
  INTO v_full_code, v_destination 
  FROM public.game_final_code 
  WHERE id = 'current' 
  LIMIT 1;

  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;
  IF v_destination IS NULL THEN v_destination := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'; END IF;

  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- 1. Assegna/Recupera frammento per il team
  SELECT * INTO v_part FROM public.team_code_parts WHERE team_id = p_team_id;
  IF NOT FOUND THEN
    SELECT (COUNT(*) % 2) INTO v_team_idx FROM public.team_code_parts;
    IF v_team_idx = 1 THEN
      v_part_type := 'LAST_5';
      v_code_val := v_last5;
    ELSE
      v_part_type := 'FIRST_5';
      v_code_val := v_first5;
    END IF;

    INSERT INTO public.team_code_parts (team_id, code_part, part_type)
    VALUES (p_team_id, v_code_val, v_part_type)
    ON CONFLICT (team_id) DO NOTHING;

    SELECT * INTO v_part FROM public.team_code_parts WHERE team_id = p_team_id;
  END IF;

  -- 2. Assegna/Recupera match (partner e costo tra 3 e 5 token, default 4)
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  IF NOT FOUND THEN
    SELECT * INTO v_other_team 
    FROM public.teams 
    WHERE id <> p_team_id AND active = true 
    ORDER BY created_at ASC 
    LIMIT 1;

    v_cost := 4;
    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (
      p_team_id, 
      COALESCE(v_other_team.id, p_team_id), 
      CASE WHEN v_part.part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END,
      v_cost
    )
    ON CONFLICT (buyer_team_id) DO NOTHING;

    SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  END IF;

  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> p_team_id THEN
    SELECT COALESCE(nome_squadra, 'Altra Squadra') INTO v_seller_name FROM public.teams WHERE id = v_match.seller_team_id;
  ELSE
    v_seller_name := 'Regia';
  END IF;

  -- 3. Controlla se ha acquistato il frammento
  SELECT EXISTS(
    SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = p_team_id
  ) INTO v_has_purchased;

  IF v_has_purchased THEN
    SELECT digits_received INTO v_purchased_digits 
    FROM public.code_purchase_transactions 
    WHERE buyer_team_id = p_team_id 
    LIMIT 1;

    IF v_purchased_digits IS NULL THEN
      v_purchased_digits := CASE WHEN v_part.part_type = 'FIRST_5' THEN v_last5 ELSE v_first5 END;
    END IF;
  END IF;

  -- 4. Controlla completamento
  SELECT EXISTS(
    SELECT 1 FROM public.team_progress
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND stato = 'completed'
  ) INTO v_completed;

  RETURN jsonb_build_object(
    'part', jsonb_build_object('code_part', v_part.code_part, 'part_type', v_part.part_type),
    'match', CASE WHEN v_match.id IS NOT NULL THEN jsonb_build_object(
      'seller_team_id', v_match.seller_team_id,
      'seller_name', v_seller_name,
      'required_part', v_match.required_part,
      'token_cost', COALESCE(v_match.token_cost, 4)
    ) ELSE NULL END,
    'has_purchased', v_has_purchased,
    'purchased_digits', v_purchased_digits,
    'completed', v_completed,
    'destination', v_destination
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_secure_leaderboard()
 RETURNS TABLE(team_id uuid, name text, color text, avatar_url text, motto text, challenges_points numeric, modifier_points numeric, cattiveria_points numeric, total_points numeric, completed_challenges bigint, total_duration_seconds numeric, last_completion timestamp with time zone, active boolean, freeze_started_at timestamp with time zone, freeze_expires_at timestamp with time zone, rank integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_caller_team_id UUID;
  v_is_admin BOOLEAN := false;
  v_has_bonus BOOLEAN := false;
  v_report_status TEXT;
BEGIN
  v_caller_id := auth.uid();
  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
    SELECT t.id INTO v_caller_team_id
    FROM public.teams t
    WHERE t.owner_id = v_caller_id;
  END IF;

  SELECT status INTO v_report_status FROM public.game_report WHERE id = 'current';

  IF COALESCE(v_is_admin, false) OR COALESCE(v_report_status, 'NOT_CALCULATED') = 'PUBLISHED' THEN
    v_has_bonus := true;
  ELSIF v_caller_team_id IS NOT NULL THEN
    SELECT EXISTS(
      SELECT 1 FROM public.marketplace_transactions mt
      WHERE mt.team_id = v_caller_team_id
        AND mt.marketplace_item_id = 'bonus_classifica'
        AND mt.stato IN ('completed', 'viewing')
    ) INTO v_has_bonus;
  END IF;

  RETURN QUERY
  WITH raw_leaderboard AS (
    SELECT
      t.id AS l_team_id,
      t.nome_squadra AS l_name,
      t.colore AS l_color,
      t.avatar_url AS l_avatar_url,
      t.motto AS l_motto,
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id AND s.challenge_id IS NOT NULL), 0)::NUMERIC AS l_ch_pts,
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id AND s.challenge_id IS NULL), 0)::NUMERIC AS l_mod_pts,
      CASE WHEN v_is_admin THEN COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)::NUMERIC ELSE 0::NUMERIC END AS l_catt_pts,
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0)::NUMERIC AS l_tot_pts,
      (SELECT COUNT(DISTINCT tp.challenge_id) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed') AS l_comp_ch,
      GREATEST(0, (
        COALESCE((
          SELECT SUM(rs.duration_seconds) FROM public.race_sessions rs WHERE rs.team_id = t.id
        ), EXTRACT(EPOCH FROM (
          COALESCE((SELECT MAX(tp.completata_il) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed'), t.created_at) - t.created_at
        )))::NUMERIC +
        COALESCE((
          SELECT (SUM(tp.minuti_penalita) * 60)::NUMERIC FROM public.time_penalties tp WHERE tp.team_id = t.id
        ), 0)::NUMERIC
      ))::NUMERIC AS l_duration,
      (SELECT MAX(tp.completata_il) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed') AS l_last_comp,
      t.active AS l_active,
      t.freeze_started_at AS l_freeze_start,
      t.freeze_expires_at AS l_freeze_exp
    FROM public.teams t
  ),
  ranked_leaderboard AS (
    SELECT
      rb.*,
      ROW_NUMBER() OVER (
        ORDER BY rb.l_active DESC, rb.l_comp_ch DESC, rb.l_tot_pts DESC, rb.l_duration ASC, rb.l_last_comp ASC NULLS LAST
      )::INTEGER AS l_rank
    FROM raw_leaderboard rb
  )
  SELECT
    rl.l_team_id, rl.l_name, rl.l_color, rl.l_avatar_url, rl.l_motto, rl.l_ch_pts, rl.l_mod_pts, rl.l_catt_pts, rl.l_tot_pts, rl.l_comp_ch, rl.l_duration, rl.l_last_comp, rl.l_active, rl.l_freeze_start, rl.l_freeze_exp, rl.l_rank
  FROM ranked_leaderboard rl
  WHERE v_has_bonus = true OR rl.l_team_id = v_caller_team_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_social_submission()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_sub RECORD;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_sub FROM public.team_social_submissions WHERE team_id = v_team_id LIMIT 1;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'id', v_sub.id,
    'team_id', v_sub.team_id,
    'challenge_id', v_sub.challenge_id,
    'image_1_url', COALESCE(v_sub.image_1_url, v_sub.social_url),
    'image_2_url', v_sub.image_2_url,
    'status', COALESCE(v_sub.status, 'submitted'),
    'stato_approvazione', v_sub.stato_approvazione,
    'admin_score', v_sub.admin_score,
    'uploaded_at', COALESCE(v_sub.uploaded_at, v_sub.created_at)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_has BOOLEAN := false;
BEGIN
  -- Admin bypass speciale
  IF _user_id = '11111111-1111-1111-1111-111111111111'::UUID THEN
    RETURN true;
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  ) INTO v_has;

  RETURN v_has;
END;
$function$;

CREATE OR REPLACE FUNCTION public.initialize_secret_code_challenge()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_teams UUID[];
  v_count INTEGER;
  v_i INTEGER;
  v_full_code TEXT := '4829167305';
  v_first5 TEXT;
  v_last5 TEXT;
  v_buyer_id UUID;
  v_seller_id UUID;
  v_part_type TEXT;
  v_required_type TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current';
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- Collect active teams
  SELECT array_agg(id ORDER BY created_at ASC) INTO v_teams
  FROM public.teams
  WHERE active = true;

  v_count := COALESCE(array_length(v_teams, 1), 0);
  IF v_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nessuna squadra attiva trovata.');
  END IF;

  -- Clear previous assignments if regenerating
  DELETE FROM public.team_code_matches;
  DELETE FROM public.team_code_parts;

  -- Assign parts: alternating FIRST_5 and LAST_5
  FOR v_i IN 1..v_count LOOP
    v_buyer_id := v_teams[v_i];
    
    IF v_i % 2 = 1 THEN
      v_part_type := 'FIRST_5';
      v_required_type := 'LAST_5';
      INSERT INTO public.team_code_parts (team_id, code_part, part_type)
      VALUES (v_buyer_id, v_first5, 'FIRST_5')
      ON CONFLICT (team_id) DO UPDATE SET code_part = v_first5, part_type = 'FIRST_5';
    ELSE
      v_part_type := 'LAST_5';
      v_required_type := 'FIRST_5';
      INSERT INTO public.team_code_parts (team_id, code_part, part_type)
      VALUES (v_buyer_id, v_last5, 'LAST_5')
      ON CONFLICT (team_id) DO UPDATE SET code_part = v_last5, part_type = 'LAST_5';
    END IF;

    -- Pair with next team in circle (cyclic matching)
    IF v_count > 1 THEN
      IF v_i < v_count THEN
        v_seller_id := v_teams[v_i + 1];
      ELSE
        v_seller_id := v_teams[1];
      END IF;
    ELSE
      v_seller_id := v_buyer_id;
    END IF;

    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (v_buyer_id, v_seller_id, v_required_type, 4)
    ON CONFLICT (buyer_team_id) 
    DO UPDATE SET seller_team_id = v_seller_id, required_part = v_required_type, token_cost = 4;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'message', 'Abbinamenti e frammenti codice segreto configurati per ' || v_count || ' squadre.');
END;
$function$;

CREATE OR REPLACE FUNCTION public.mark_partenza_used(p_transaction_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_team_id UUID;
  v_tx RECORD;
BEGIN
  v_is_admin := public.has_role(auth.uid(), 'admin');
  v_team_id := public.current_team_id();

  SELECT * INTO v_tx FROM public.marketplace_transactions WHERE id = p_transaction_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  IF NOT v_is_admin AND (v_team_id IS NULL OR v_tx.team_id != v_team_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autorizzato');
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used', data_utilizzo = now()
  WHERE id = p_transaction_id;

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.open_classifica_bonus(p_transaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_tx RECORD;
  v_snapshot JSONB;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE id = p_transaction_id AND team_id = v_team_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transazione non trovata';
  END IF;

  IF v_tx.marketplace_item_id != 'bonus_classifica' THEN
    RAISE EXCEPTION 'Transazione non abbinata al bonus classifica';
  END IF;

  IF v_tx.stato = 'completed' THEN
    -- Generate snapshot of current live leaderboard based EXCLUSIVELY on public.scores
    SELECT jsonb_agg(jsonb_build_object(
      'team_id', t.id,
      'name', t.nome_squadra,
      'nome_squadra', t.nome_squadra,
      'color', t.colore,
      'avatar_url', t.avatar_url,
      'total_points', COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0)
    ) ORDER BY COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) DESC)
    INTO v_snapshot
    FROM public.teams t
    WHERE t.active = true;

    UPDATE public.marketplace_transactions
    SET
      stato = 'viewing',
      data_utilizzo = now(),
      dettagli = jsonb_build_object('snapshot', v_snapshot, 'snapshot_timestamp', now())
    WHERE id = p_transaction_id;
  END IF;
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

CREATE OR REPLACE FUNCTION public.publish_game_report(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_is_admin BOOLEAN := false;
  v_report RECORD;
  v_snapshot JSONB;
BEGIN
  v_caller_id := auth.uid();

  -- Check Admin Authorization
  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
  END IF;

  IF NOT COALESCE(v_is_admin, false) THEN
    RAISE EXCEPTION 'Access Denied: Only Admin can publish final results.';
  END IF;

  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';

  -- Enforce calculation before publication
  IF v_report.status = 'NOT_CALCULATED' OR v_report.calculated_snapshot IS NULL THEN
    -- Auto-calculate before publish if not yet done
    PERFORM public.calculate_final_game_results(v_caller_id);
    SELECT * INTO v_report FROM public.game_report WHERE id = 'current';
  END IF;

  v_snapshot := v_report.calculated_snapshot;

  -- Update to PUBLISHED status
  UPDATE public.game_report
  SET 
    status = 'PUBLISHED',
    state = 'PUBLISHED_FINAL',
    published_at = now(),
    published_by = v_caller_id,
    snapshot = v_snapshot,
    updated_at = now()
  WHERE id = 'current';

  -- Audit Log
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'PUBLISH_FINAL_RESULTS',
    jsonb_build_object(
      'admin_id', v_caller_id,
      'published_at', now()
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'PUBLISHED',
    'published_at', now()
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.reopen_stage(p_stage_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.stages SET stato = 'open' WHERE id = p_stage_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reset_boxe_tournament(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NOT NULL
     AND NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.boxe_matches
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.scores
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.team_progress
  WHERE challenge_id = v_challenge_id;

  UPDATE public.game_settings
  SET boxe_special_bye_team_id = NULL;

  IF p_admin_id IS NOT NULL THEN
    INSERT INTO public.activity_log (
      id, tipo_evento, team_id, target_team_id,
      dettagli, created_at
    )
    VALUES (
      gen_random_uuid(),
      'BOXE_RESET',
      NULL,
      NULL,
      jsonb_build_object('admin_id', p_admin_id),
      now()
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.reset_cornhole_tournament(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NOT NULL
     AND NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.cornhole_matches
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.scores
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.team_progress
  WHERE challenge_id = v_challenge_id;

  UPDATE public.game_settings
  SET cornhole_special_bye_team_id = NULL;

  IF p_admin_id IS NOT NULL THEN
    INSERT INTO public.activity_log (
      id,
      tipo_evento,
      team_id,
      target_team_id,
      dettagli,
      created_at
    )
    VALUES (
      gen_random_uuid(),
      'CORNHOLE_RESET',
      NULL,
      NULL,
      jsonb_build_object('admin_id', p_admin_id),
      now()
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.reset_global_race(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  PERFORM public.assert_admin_caller();
  UPDATE public.game_settings
  SET
    race_status = 'not_started',
    race_started_at = NULL,
    race_ended_at = NULL
  WHERE id = 'settings_01';

  RETURN jsonb_build_object('success', true, 'race_status', 'not_started');
END;
$function$;

CREATE OR REPLACE FUNCTION public.respond_passaparola_request(p_transaction_id uuid, p_response text, p_nota_interna text DEFAULT NULL::text, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_tx RECORD;
  v_team_name TEXT;
BEGIN
  v_is_admin := public.has_role(auth.uid(), 'admin');
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autorizzato');
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  IF v_tx.stato != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'La richiesta non è in attesa di risposta');
  END IF;

  UPDATE public.marketplace_transactions
  SET 
    stato = 'used',
    data_utilizzo = now(),
    dettagli = COALESCE(dettagli, '{}'::jsonb) || jsonb_build_object(
      'response_text', p_response, 
      'nota_interna', p_nota_interna, 
      'response_timestamp', now()
    )
  WHERE id = p_transaction_id;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_tx.team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('passaparola_responded', v_tx.team_id, jsonb_build_object('message', 'La Regia ha risposto alla richiesta Passaparola di "' || COALESCE(v_team_name, 'Sconosciuta') || '": "' || p_response || '"'));

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.rollback_boxe_match_result(p_match_id text, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_max_round INTEGER;
  v_next_match RECORD;
  v_next_match_idx INTEGER;
  v_res JSONB;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT * INTO v_match FROM public.boxe_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.status <> 'completed' THEN
    SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
    FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;
    RETURN v_res;
  END IF;

  SELECT MAX(round)::INTEGER INTO v_max_round 
  FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    v_next_match_idx := (v_match.match_index / 2)::INTEGER;
    SELECT * INTO v_next_match FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;

    IF v_next_match.status = 'completed' THEN
      RAISE EXCEPTION 'Impossibile annullare: il turno successivo è già stato disputato. Annulla prima quel match.';
    END IF;

    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.boxe_matches SET team1_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    ELSE
      UPDATE public.boxe_matches SET team2_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    END IF;
  ELSE
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;
    UPDATE public.team_progress SET stato = 'in_progress', completata_il = NULL WHERE challenge_id = v_challenge_id;
  END IF;

  UPDATE public.boxe_matches
  SET winner_id = NULL, status = 'ready', completed_at = NULL
  WHERE id = v_match.id;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.rollback_cornhole_match_result(p_match_id text, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_max_round INTEGER;
  v_next_match RECORD;
  v_next_match_idx INTEGER;
  v_res JSONB;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT * INTO v_match FROM public.cornhole_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.status <> 'completed' THEN
    SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
    FROM (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;
    RETURN v_res;
  END IF;

  SELECT MAX(round)::INTEGER INTO v_max_round 
  FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    v_next_match_idx := (v_match.match_index / 2)::INTEGER;
    SELECT * INTO v_next_match FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;

    IF v_next_match.status = 'completed' THEN
      RAISE EXCEPTION 'Impossibile annullare: il turno successivo è già stato disputato. Annulla prima quel match.';
    END IF;

    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.cornhole_matches SET team1_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    ELSE
      UPDATE public.cornhole_matches SET team2_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    END IF;
  ELSE
    -- Rollback della finale: cancella i punteggi
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;
    UPDATE public.team_progress SET stato = 'in_progress', completata_il = NULL WHERE challenge_id = v_challenge_id;
  END IF;

  UPDATE public.cornhole_matches
  SET winner_id = NULL, status = 'ready', completed_at = NULL
  WHERE id = v_match.id;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_boxe_special_bye(p_team_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_has_started BOOLEAN;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT EXISTS(
    SELECT 1 FROM public.boxe_matches
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  IF v_has_started THEN
    RAISE EXCEPTION 'Impossibile modificare il vantaggio: il torneo è già iniziato.';
  END IF;

  UPDATE public.game_settings
  SET boxe_special_bye_team_id = p_team_id
  WHERE true;

  DELETE FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  RETURN jsonb_build_object('success', true, 'special_bye_team_id', p_team_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_cornhole_special_bye(p_team_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_has_started BOOLEAN;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT EXISTS(
    SELECT 1 FROM public.cornhole_matches
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  IF v_has_started THEN
    RAISE EXCEPTION 'Impossibile modificare il vantaggio: il torneo è già iniziato.';
  END IF;

  UPDATE public.game_settings
  SET cornhole_special_bye_team_id = p_team_id
  WHERE true;

  DELETE FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  RETURN jsonb_build_object('success', true, 'special_bye_team_id', p_team_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.spin_unlucky_wheel(p_transaction_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_tx RECORD;
  v_roll INTEGER;
  v_outcome_id TEXT;
  v_outcome_label TEXT;
  v_points INTEGER := 0;
  v_tokens INTEGER := 0;
  v_minutes INTEGER := 0;
  v_freeze_seconds INTEGER := 0;
  v_outcome JSONB;
BEGIN
  -- CONTROLLO GARA TERMINATA
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile compiere azioni.';
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

  IF p_transaction_id IS NOT NULL THEN
    SELECT * INTO v_tx
    FROM public.marketplace_transactions
    WHERE id = p_transaction_id
      AND target_team_id = v_team_id
      AND marketplace_item_id = 'ruota_sfortunata'
      AND stato = 'completed'
    FOR UPDATE;
  ELSE
    SELECT * INTO v_tx
    FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id
      AND marketplace_item_id = 'ruota_sfortunata'
      AND stato = 'completed'
    ORDER BY data_acquisto ASC
    LIMIT 1
    FOR UPDATE;
  END IF;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Nessuna Ruota Sfortunata attiva trovata per questa squadra';
  END IF;

  v_roll := floor(random() * 100 + 1)::integer;

  IF v_roll <= 20 THEN
    v_outcome_id := 'freeze_2min';
    v_outcome_label := '❄️ CONGELAMENTO 2 MINUTI';
    v_freeze_seconds := 120;
  ELSIF v_roll <= 36 THEN
    v_outcome_id := 'minus_15_points';
    v_outcome_label := '📉 PENALITÀ -15 PUNTI';
    v_points := 15;
  ELSIF v_roll <= 52 THEN
    v_outcome_id := 'minus_10_tokens';
    v_outcome_label := '🪙 PERDITA 10 TOKEN';
    v_tokens := 10;
  ELSIF v_roll <= 68 THEN
    v_outcome_id := 'plus_2_min';
    v_outcome_label := '⏱️ PENALITÀ TEMPO +2 MINUTI';
    v_minutes := 2;
  ELSIF v_roll <= 84 THEN
    v_outcome_id := 'heavy_backpack';
    v_outcome_label := '🎒 ZAINO PESANTE (+3 MIN)';
    v_minutes := 3;
  ELSE
    v_outcome_id := 'minus_10_points_minus_5_tokens';
    v_outcome_label := '💥 -10 PUNTI & -5 TOKEN';
    v_points := 10;
    v_tokens := 5;
  END IF;

  v_outcome := jsonb_build_object(
    'id', v_outcome_id,
    'label', v_outcome_label,
    'points', v_points,
    'tokens', v_tokens,
    'minutes', v_minutes,
    'freeze_seconds', v_freeze_seconds,
    'roll', v_roll
  );

  -- Apply penalties with CUMULATIVE freeze support
  IF v_freeze_seconds > 0 THEN
    UPDATE public.teams
    SET
      freeze_started_at = COALESCE(
        CASE WHEN freeze_expires_at > now() THEN freeze_started_at ELSE now() END,
        now()
      ),
      freeze_expires_at = GREATEST(now(), COALESCE(freeze_expires_at, now())) + (v_freeze_seconds || ' seconds')::interval,
      freeze_duration_seconds = COALESCE(freeze_duration_seconds, 0) + v_freeze_seconds
    WHERE id = v_team_id;
  END IF;

  IF v_points > 0 THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, -v_points, 'penalty', 'Ruota Sfortunata: ' || v_outcome_label);
  END IF;

  IF v_tokens > 0 THEN
    UPDATE public.teams
    SET token_balance = GREATEST(0, token_balance - v_tokens)
    WHERE id = v_team_id;
  END IF;

  IF v_minutes > 0 THEN
    INSERT INTO public.time_penalties (team_id, minuti_penalita, motivo)
    VALUES (v_team_id, v_minutes, 'Ruota Sfortunata: ' || v_outcome_label);
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used',
      data_utilizzo = now(),
      dettagli = jsonb_build_object('outcome', v_outcome)
  WHERE id = v_tx.id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES (
    'ruota_sfortunata_spin', v_team_id,
    jsonb_build_object('message', 'La squadra ha girato la Ruota Sfortunata ed ha subito: ' || v_outcome_label)
  );

  RETURN jsonb_build_object(
    'success', true,
    'outcome', v_outcome
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.start_challenge(p_challenge uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_row RECORD;
  v_prev_incomplete BOOLEAN;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato come team';
  END IF;

  -- Verifica esistenza della challenge
  SELECT * INTO v_challenge_row FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sfida non esistente';
  END IF;

  -- Controllo progressione della tappa (challenge con ordine_sfida inferiore nello stesso stage)
  SELECT EXISTS(
    SELECT 1 FROM public.challenges c
    LEFT JOIN public.team_progress tp ON tp.challenge_id = c.id AND tp.team_id = v_team_id
    WHERE c.stage_id = v_challenge_row.stage_id 
      AND c.ordine_sfida < v_challenge_row.ordine_sfida
      AND (tp.stato IS NULL OR tp.stato != 'completed')
  ) INTO v_prev_incomplete;

  IF v_prev_incomplete THEN
    RAISE EXCEPTION 'Devi prima completare le sfide precedenti di questa tappa';
  END IF;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, created_at)
  VALUES (v_team_id, p_challenge, 'in_progress', now())
  ON CONFLICT (team_id, challenge_id) DO NOTHING;
END;
$function$;

CREATE OR REPLACE FUNCTION public.start_global_race(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_now TIMESTAMPTZ := now();
BEGIN
  PERFORM public.assert_admin_caller();
  UPDATE public.game_settings
  SET
    race_status = 'in_progress',
    race_started_at = v_now,
    race_ended_at = NULL,
    activated_at = COALESCE(activated_at, v_now),
    activated_by = COALESCE(p_admin_id, activated_by)
  WHERE id = 'settings_01';

  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'race_started',
    jsonb_build_object('message', '🏁 LA GARA È UFFICIALMENTE INIZIATA! Il timer globale è attivo.', 'started_at', v_now)
  );

  RETURN jsonb_build_object('success', true, 'race_status', 'in_progress', 'race_started_at', v_now);
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
$function$;

CREATE OR REPLACE FUNCTION public.submit_boxe_match_result(p_match_id uuid, p_winner_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_stage_id UUID;
  v_match RECORD;
  v_max_round INTEGER;
  v_r0_count INTEGER;
  v_r1_count INTEGER;
  v_next_match_idx INTEGER;
  v_team RECORD;
  v_res JSONB;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;
  IF v_stage_id IS NULL THEN
    v_stage_id := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  END IF;

  SELECT * INTO v_match FROM public.boxe_matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.status = 'completed' THEN
    RAISE EXCEPTION 'Il match è già stato completato.';
  END IF;

  IF v_match.team1_id <> p_winner_id AND v_match.team2_id <> p_winner_id THEN
    RAISE EXCEPTION 'La squadra vincitrice deve far parte del match.';
  END IF;

  UPDATE public.boxe_matches
  SET winner_id = p_winner_id, status = 'completed', completed_at = now()
  WHERE id = v_match.id;

  SELECT MAX(round)::INTEGER INTO v_max_round
  FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    SELECT count(*)::INTEGER INTO v_r0_count FROM public.boxe_matches WHERE challenge_id = v_challenge_id AND round = 0;
    SELECT count(*)::INTEGER INTO v_r1_count FROM public.boxe_matches WHERE challenge_id = v_challenge_id AND round = 1;

    IF v_match.round = 0 AND v_max_round >= 2 AND v_r0_count < v_r1_count THEN
      UPDATE public.boxe_matches SET team2_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = 1 AND match_index = v_match.match_index;

      UPDATE public.boxe_matches SET status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = 1 AND match_index = v_match.match_index AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
    ELSE
      v_next_match_idx := (v_match.match_index / 2)::INTEGER;
      IF v_match.match_index % 2 = 0 THEN
        UPDATE public.boxe_matches SET team1_id = p_winner_id
        WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
      ELSE
        UPDATE public.boxe_matches SET team2_id = p_winner_id
        WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
      END IF;

      UPDATE public.boxe_matches SET status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
    END IF;
  ELSE
    -- Finale
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (p_winner_id, v_challenge_id, v_stage_id, 20, 'challenge_points', 'Vincitore Torneo Boxe Gonfiabile (Tappa 5)');

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true AND id <> p_winner_id) LOOP
      INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team.id, v_challenge_id, v_stage_id, 10, 'challenge_points', 'Partecipazione Torneo Boxe Gonfiabile (Tappa 5)');
    END LOOP;

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true) LOOP
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team.id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());
    END LOOP;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_cornhole_match_result(p_match_id uuid, p_winner_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_stage_id UUID;
  v_match RECORD;
  v_max_round INTEGER;
  v_r0_count INTEGER;
  v_r1_count INTEGER;
  v_next_match_idx INTEGER;
  v_team RECORD;
  v_res JSONB;
BEGIN
  PERFORM public.assert_admin_caller();
  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;
  IF v_stage_id IS NULL THEN
    v_stage_id := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  END IF;

  SELECT * INTO v_match FROM public.cornhole_matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.status = 'completed' THEN
    RAISE EXCEPTION 'Il match è già stato completato.';
  END IF;

  IF v_match.team1_id <> p_winner_id AND v_match.team2_id <> p_winner_id THEN
    RAISE EXCEPTION 'La squadra vincitrice deve far parte del match.';
  END IF;

  UPDATE public.cornhole_matches
  SET winner_id = p_winner_id, status = 'completed', completed_at = now()
  WHERE id = v_match.id;

  SELECT MAX(round)::INTEGER INTO v_max_round
  FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    SELECT count(*)::INTEGER INTO v_r0_count FROM public.cornhole_matches WHERE challenge_id = v_challenge_id AND round = 0;
    SELECT count(*)::INTEGER INTO v_r1_count FROM public.cornhole_matches WHERE challenge_id = v_challenge_id AND round = 1;

    IF v_match.round = 0 AND v_max_round >= 2 AND v_r0_count < v_r1_count THEN
      -- In preliminary round, winner feeds into Round 1 match_index
      UPDATE public.cornhole_matches SET team2_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = 1 AND match_index = v_match.match_index;

      UPDATE public.cornhole_matches SET status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = 1 AND match_index = v_match.match_index AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
    ELSE
      v_next_match_idx := (v_match.match_index / 2)::INTEGER;
      IF v_match.match_index % 2 = 0 THEN
        UPDATE public.cornhole_matches SET team1_id = p_winner_id
        WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
      ELSE
        UPDATE public.cornhole_matches SET team2_id = p_winner_id
        WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
      END IF;

      UPDATE public.cornhole_matches SET status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
    END IF;
  ELSE
    -- Finale
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (p_winner_id, v_challenge_id, v_stage_id, 20, 'challenge_points', 'Vincitore Torneo Cornhole (Tappa 5)');

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true AND id <> p_winner_id) LOOP
      INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team.id, v_challenge_id, v_stage_id, 10, 'challenge_points', 'Partecipazione Torneo Cornhole (Tappa 5)');
    END LOOP;

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true) LOOP
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team.id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());
    END LOOP;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
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

CREATE OR REPLACE FUNCTION public.submit_enigma_extra_answer(p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_tx RECORD;
  v_is_correct BOOLEAN := false;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Controlla se c'è enigma extra acquistato e non ancora consumato
  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE target_team_id = v_team_id AND marketplace_item_id = 'enigma_extra' AND stato = 'completed'
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Nessun enigma extra attivo');
  END IF;

  v_is_correct := (LOWER(TRIM(p_answer)) = 'lanterna'); -- Soluzione fissa

  IF v_is_correct THEN
    UPDATE public.marketplace_transactions SET stato = 'used', data_utilizzo = now() WHERE id = v_tx.id;
  END IF;

  RETURN jsonb_build_object('is_correct', v_is_correct);
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_passaparola_request(p_transaction_id uuid, p_request_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_team_name TEXT;
  v_tx RECORD;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE id = p_transaction_id AND team_id = v_team_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  IF v_tx.marketplace_item_id != 'passaparola' OR v_tx.stato != 'completed' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Richiesta non valida o già inoltrata');
  END IF;

  -- Aggiorna stato a pending e salva testo della richiesta
  UPDATE public.marketplace_transactions
  SET stato = 'pending', dettagli = jsonb_build_object('request_text', p_request_text, 'requested_at', now())
  WHERE id = p_transaction_id;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('passaparola_request', v_team_id,
    jsonb_build_object('message', 'La squadra "' || v_team_name || '" ha inoltrato una richiesta Passaparola: "' || p_request_text || '"'));

  RETURN jsonb_build_object('success', true);
END;
$function$;

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
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_question FROM public.quiz_questions WHERE id = p_question;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('correct', false, 'points', 0, 'error', 'Domanda non trovata');
  END IF;

  v_correct := (p_selected = v_question.correct_answer_index);
  v_points := CASE WHEN v_correct THEN v_question.points ELSE 0 END;

  -- Upsert risposta (UNIQUE su team_id, question_id)
  INSERT INTO public.team_answers (team_id, question_id, selected_answer, correct)
  VALUES (v_team_id, p_question, p_selected, v_correct)
  ON CONFLICT (team_id, question_id) DO UPDATE
    SET selected_answer = EXCLUDED.selected_answer, correct = EXCLUDED.correct;

  -- Assegna punti se corretto
  IF v_correct AND v_points > 0 THEN
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_question.challenge_id, v_points, 'challenge_points', 'Risposta corretta al quiz');
  END IF;

  RETURN jsonb_build_object('correct', v_correct, 'points', v_points);
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
BEGIN
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
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, v_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, 30, 'challenge_points', 'Sfida PIN superata')
    ON CONFLICT DO NOTHING;
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

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_team_to_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp', 'extensions'
AS $function$
DECLARE
  v_user_id UUID;
  v_email TEXT;
  v_encrypted_pass TEXT;
BEGIN
  IF NEW.username IS NULL OR NEW.password_plain IS NULL THEN
    RETURN NEW;
  END IF;

  v_encrypted_pass := extensions.crypt(NEW.password_plain, extensions.gen_salt('bf', 10));

  IF OLD.owner_id IS NOT NULL THEN
    v_user_id := OLD.owner_id;
    UPDATE auth.users 
    SET encrypted_password = v_encrypted_pass, updated_at = now()
    WHERE id = v_user_id;
  ELSE
    v_user_id := gen_random_uuid();
    v_email := v_user_id || '@auth.local';

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
      v_email, v_encrypted_pass, now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
      now(), now(), '', '', '', ''
    );
  END IF;

  NEW.owner_id := v_user_id;
  
  -- Sicurezza: non salviamo la password in chiaro nel database
  NEW.password_plain := NULL;
  
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.toggle_marketplace(p_active boolean, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN RAISE EXCEPTION 'Non autorizzato'; END IF;
  UPDATE public.game_settings SET
    marketplace_active = p_active,
    activated_at = CASE WHEN p_active THEN now() ELSE NULL END,
    activated_by = CASE WHEN p_active THEN p_admin_id ELSE NULL END
  WHERE id = (SELECT id FROM public.game_settings LIMIT 1);
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_team_profile(p_motto text DEFAULT NULL::text, p_color text DEFAULT NULL::text, p_avatar_url text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_updated_team RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Trova il team associato all'utente
  SELECT team_id INTO v_team_id
  FROM public.user_roles
  WHERE user_id = v_user_id;

  IF v_team_id IS NULL THEN
    SELECT id INTO v_team_id
    FROM public.teams
    WHERE owner_id = v_user_id;
  END IF;

  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Nessuna squadra associata a questo account';
  END IF;

  UPDATE public.teams
  SET
    motto = COALESCE(p_motto, motto),
    color = COALESCE(p_color, color),
    colore = COALESCE(p_color, colore, color),
    avatar_url = COALESCE(p_avatar_url, avatar_url)
  WHERE id = v_team_id
  RETURNING * INTO v_updated_team;

  RETURN jsonb_build_object(
    'success', true,
    'team_id', v_team_id,
    'motto', v_updated_team.motto,
    'color', v_updated_team.color,
    'avatar_url', v_updated_team.avatar_url
  );
END;
$function$;

DROP FUNCTION IF EXISTS public.team_mandatory_finish(uuid);
DROP FUNCTION IF EXISTS public.team_race_seconds(uuid);
DROP FUNCTION IF EXISTS public.submit_emoji_movie_answer(integer, text);
