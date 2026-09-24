-- 06_security_and_stage_arrival.sql
-- 1) Le RPC di regia richiedono un chiamante admin autenticato (auth.uid()), non un p_admin_id passato dal client.
-- 2) complete_challenge serializza il calcolo della posizione di arrivo per tappa (advisory lock).
-- 3) consume_marketplace_transaction rifiuta chiamanti non autenticati; play_jackpot non permette di giocare per un'altra squadra.

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
REVOKE ALL ON FUNCTION public.assert_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assert_admin_caller() TO anon, authenticated, service_role;

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
