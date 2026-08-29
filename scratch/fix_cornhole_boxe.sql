BEGIN;

-- 1. Aggiungi colonne mancanti a cornhole_matches e boxe_matches
ALTER TABLE public.cornhole_matches ADD COLUMN IF NOT EXISTS stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL;
ALTER TABLE public.cornhole_matches ADD COLUMN IF NOT EXISTS is_special_bye BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.boxe_matches ADD COLUMN IF NOT EXISTS stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL;
ALTER TABLE public.boxe_matches ADD COLUMN IF NOT EXISTS is_special_bye BOOLEAN NOT NULL DEFAULT false;

-- 2. CORNHOLE SETTINGS RPC
DROP FUNCTION IF EXISTS public.get_cornhole_settings();
CREATE OR REPLACE FUNCTION public.get_cornhole_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

-- 3. SET CORNHOLE SPECIAL BYE RPC
DROP FUNCTION IF EXISTS public.set_cornhole_special_bye(UUID);
DROP FUNCTION IF EXISTS public.set_cornhole_special_bye(UUID, UUID);

CREATE OR REPLACE FUNCTION public.set_cornhole_special_bye(
  p_team_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_has_started BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  IF v_has_started THEN
    RAISE EXCEPTION 'Impossibile modificare il vantaggio: il torneo è già iniziato.';
  END IF;

  UPDATE public.game_settings
  SET cornhole_special_bye_team_id = p_team_id;

  -- Resetta i match per consentire rigenerazione con il nuovo bye
  DELETE FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  RETURN jsonb_build_object('success', true, 'special_bye_team_id', p_team_id);
END;
$$;

-- 4. GET CORNHOLE TOURNAMENT RPC
DROP FUNCTION IF EXISTS public.get_cornhole_tournament();
CREATE OR REPLACE FUNCTION public.get_cornhole_tournament()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_existing_count INTEGER;
  v_special_bye_team_id UUID;
  v_active_teams UUID[];
  v_sorted_teams UUID[];
  v_team UUID;
  v_n INTEGER;
  v_virtual_n INTEGER;
  v_k INTEGER;
  v_num_matches INTEGER;
  v_num_byes INTEGER;
  v_num_tech_byes INTEGER;
  v_total_rounds INTEGER;
  v_round INTEGER;
  v_matches_in_round INTEGER;
  v_m INTEGER;
  v_team_idx INTEGER;
  v_match_id UUID;
  v_res JSONB;
  v_cm RECORD;
  v_next_match_idx INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_existing_count 
  FROM public.cornhole_matches 
  WHERE challenge_id = v_challenge_id;

  IF v_existing_count = 0 THEN
    -- Recupera squadre attive
    SELECT ARRAY_AGG(id ORDER BY nome_squadra ASC) INTO v_active_teams
    FROM public.teams
    WHERE active = true;

    v_n := COALESCE(array_length(v_active_teams, 1), 0);
    IF v_n = 0 THEN
      RETURN '[]'::jsonb;
    END IF;

    SELECT cornhole_special_bye_team_id INTO v_special_bye_team_id
    FROM public.game_settings LIMIT 1;

    -- Se presente special bye valido, mettilo come primo
    v_sorted_teams := ARRAY[]::UUID[];
    IF v_special_bye_team_id IS NOT NULL AND v_special_bye_team_id = ANY(v_active_teams) THEN
      v_sorted_teams := array_append(v_sorted_teams, v_special_bye_team_id);
      FOREACH v_team IN ARRAY v_active_teams LOOP
        IF v_team <> v_special_bye_team_id THEN
          v_sorted_teams := array_append(v_sorted_teams, v_team);
        END IF;
      END LOOP;
      v_virtual_n := v_n + 1;
    ELSE
      v_sorted_teams := v_active_teams;
      v_virtual_n := v_n;
      v_special_bye_team_id := NULL;
    END IF;

    -- Calcolo dimensione tabellone K (potenza di 2)
    v_k := 2;
    WHILE v_k < v_virtual_n LOOP
      v_k := v_k * 2;
    END LOOP;

    v_num_matches := v_k / 2;
    v_num_byes := v_k - v_n;
    IF v_special_bye_team_id IS NOT NULL THEN
      v_num_tech_byes := GREATEST(0, v_num_byes - 1);
    ELSE
      v_num_tech_byes := v_num_byes;
    END IF;

    v_total_rounds := (ln(v_k) / ln(2))::INTEGER;

    -- Inserisci tutti i match vuoti
    FOR v_round IN 0..(v_total_rounds - 1) LOOP
      v_matches_in_round := (v_k / (2 ^ (v_round + 1)))::INTEGER;
      FOR v_m IN 0..(v_matches_in_round - 1) LOOP
        INSERT INTO public.cornhole_matches (
          id, stage_id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, is_special_bye
        ) VALUES (
          gen_random_uuid(), v_stage_id, v_challenge_id, v_round, v_m, NULL, NULL, NULL, 'pending', NULL, false
        );
      END LOOP;
    END LOOP;

    -- Popola Round 0
    v_team_idx := 1;
    FOR v_m IN 0..(v_num_matches - 1) LOOP
      IF v_m = 0 AND v_special_bye_team_id IS NOT NULL THEN
        UPDATE public.cornhole_matches
        SET team1_id = v_special_bye_team_id,
            team2_id = NULL,
            winner_id = v_special_bye_team_id,
            status = 'completed',
            completed_at = now(),
            is_special_bye = true
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = 0;
        v_team_idx := v_team_idx + 1;
      ELSIF v_m > 0 AND v_m <= v_num_tech_byes THEN
        UPDATE public.cornhole_matches
        SET team1_id = v_sorted_teams[v_team_idx],
            team2_id = NULL,
            winner_id = v_sorted_teams[v_team_idx],
            status = 'completed',
            completed_at = now()
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
        v_team_idx := v_team_idx + 1;
      ELSE
        UPDATE public.cornhole_matches
        SET team1_id = v_sorted_teams[v_team_idx],
            team2_id = v_sorted_teams[v_team_idx + 1],
            status = 'ready'
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
        v_team_idx := v_team_idx + 2;
      END IF;
    END LOOP;

    -- Propaga i vincitori dei bye al Round 1
    FOR v_round IN 0..(v_total_rounds - 2) LOOP
      FOR v_cm IN (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id AND round = v_round AND status = 'completed' AND winner_id IS NOT NULL) LOOP
        v_next_match_idx := (v_cm.match_index / 2)::INTEGER;
        IF v_cm.match_index % 2 = 0 THEN
          UPDATE public.cornhole_matches SET team1_id = v_cm.winner_id
          WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
        ELSE
          UPDATE public.cornhole_matches SET team2_id = v_cm.winner_id
          WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
        END IF;

        UPDATE public.cornhole_matches SET status = 'ready'
        WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
      END LOOP;
    END LOOP;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (
    SELECT * FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id 
    ORDER BY round ASC, match_index ASC
  ) m;

  RETURN v_res;
END;
$$;

-- 5. SUBMIT CORNHOLE MATCH RESULT RPC
DROP FUNCTION IF EXISTS public.submit_cornhole_match_result(TEXT, UUID, UUID);
DROP FUNCTION IF EXISTS public.submit_cornhole_match_result(UUID, UUID, UUID);

CREATE OR REPLACE FUNCTION public.submit_cornhole_match_result(
  p_match_id TEXT,
  p_winner_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_max_round INTEGER;
  v_next_match_idx INTEGER;
  v_team RECORD;
  v_res JSONB;
BEGIN
  SELECT * INTO v_match FROM public.cornhole_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
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
  ELSE
    -- Finale completata: assegna 20 punti al vincitore e 10 a tutti gli altri team attivi
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (p_winner_id, v_challenge_id, v_stage_id, 20, 'challenge_points', 'Vincitore Torneo Cornhole (Tappa 5)');

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true AND id <> p_winner_id) LOOP
      INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team.id, v_challenge_id, v_stage_id, 10, 'challenge_points', 'Partecipazione Torneo Cornhole (Tappa 5)');
    END LOOP;

    -- Segna completata in team_progress per tutti i team attivi
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
$$;

-- 6. ROLLBACK CORNHOLE MATCH RESULT RPC
DROP FUNCTION IF EXISTS public.rollback_cornhole_match_result(TEXT, UUID);
DROP FUNCTION IF EXISTS public.rollback_cornhole_match_result(UUID, UUID);

CREATE OR REPLACE FUNCTION public.rollback_cornhole_match_result(
  p_match_id TEXT,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_max_round INTEGER;
  v_next_match RECORD;
  v_next_match_idx INTEGER;
  v_res JSONB;
BEGIN
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
$$;

-- 7. BOXE SETTINGS RPC
DROP FUNCTION IF EXISTS public.get_boxe_settings();
CREATE OR REPLACE FUNCTION public.get_boxe_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

-- 8. SET BOXE SPECIAL BYE RPC
DROP FUNCTION IF EXISTS public.set_boxe_special_bye(UUID);
DROP FUNCTION IF EXISTS public.set_boxe_special_bye(UUID, UUID);

CREATE OR REPLACE FUNCTION public.set_boxe_special_bye(
  p_team_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_has_started BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  IF v_has_started THEN
    RAISE EXCEPTION 'Impossibile modificare il vantaggio: il torneo è già iniziato.';
  END IF;

  UPDATE public.game_settings
  SET boxe_special_bye_team_id = p_team_id;

  DELETE FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  RETURN jsonb_build_object('success', true, 'special_bye_team_id', p_team_id);
END;
$$;

-- 9. GET BOXE TOURNAMENT RPC
DROP FUNCTION IF EXISTS public.get_boxe_tournament();
CREATE OR REPLACE FUNCTION public.get_boxe_tournament()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_res JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (
    SELECT * FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id 
    ORDER BY round ASC, match_index ASC
  ) m;

  RETURN v_res;
END;
$$;

-- 10. GENERATE BOXE TOURNAMENT RPC
DROP FUNCTION IF EXISTS public.generate_boxe_tournament(UUID);
CREATE OR REPLACE FUNCTION public.generate_boxe_tournament(
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_existing_count INTEGER;
  v_special_bye_team_id UUID;
  v_active_teams UUID[];
  v_sorted_teams UUID[];
  v_team UUID;
  v_n INTEGER;
  v_virtual_n INTEGER;
  v_k INTEGER;
  v_num_matches INTEGER;
  v_num_byes INTEGER;
  v_num_tech_byes INTEGER;
  v_total_rounds INTEGER;
  v_round INTEGER;
  v_matches_in_round INTEGER;
  v_m INTEGER;
  v_team_idx INTEGER;
  v_res JSONB;
  v_cm RECORD;
  v_next_match_idx INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_existing_count FROM public.boxe_matches WHERE challenge_id = v_challenge_id;
  IF v_existing_count > 0 THEN
    RAISE EXCEPTION 'Il torneo è già stato generato.';
  END IF;

  SELECT ARRAY_AGG(id ORDER BY random()) INTO v_active_teams
  FROM public.teams WHERE active = true;

  v_n := COALESCE(array_length(v_active_teams, 1), 0);
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Nessuna squadra attiva per generare il torneo.';
  END IF;

  SELECT boxe_special_bye_team_id INTO v_special_bye_team_id
  FROM public.game_settings LIMIT 1;

  v_sorted_teams := ARRAY[]::UUID[];
  IF v_special_bye_team_id IS NOT NULL AND v_special_bye_team_id = ANY(v_active_teams) THEN
    v_sorted_teams := array_append(v_sorted_teams, v_special_bye_team_id);
    FOREACH v_team IN ARRAY v_active_teams LOOP
      IF v_team <> v_special_bye_team_id THEN
        v_sorted_teams := array_append(v_sorted_teams, v_team);
      END IF;
    END LOOP;
    v_virtual_n := v_n + 1;
  ELSE
    v_sorted_teams := v_active_teams;
    v_virtual_n := v_n;
    v_special_bye_team_id := NULL;
  END IF;

  v_k := 2;
  WHILE v_k < v_virtual_n LOOP
    v_k := v_k * 2;
  END LOOP;

  v_num_matches := v_k / 2;
  v_num_byes := v_k - v_n;
  IF v_special_bye_team_id IS NOT NULL THEN
    v_num_tech_byes := GREATEST(0, v_num_byes - 1);
  ELSE
    v_num_tech_byes := v_num_byes;
  END IF;

  v_total_rounds := (ln(v_k) / ln(2))::INTEGER;

  FOR v_round IN 0..(v_total_rounds - 1) LOOP
    v_matches_in_round := (v_k / (2 ^ (v_round + 1)))::INTEGER;
    FOR v_m IN 0..(v_matches_in_round - 1) LOOP
      INSERT INTO public.boxe_matches (
        id, stage_id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, is_special_bye
      ) VALUES (
        gen_random_uuid(), v_stage_id, v_challenge_id, v_round, v_m, NULL, NULL, NULL, 'pending', NULL, false
      );
    END LOOP;
  END LOOP;

  v_team_idx := 1;
  FOR v_m IN 0..(v_num_matches - 1) LOOP
    IF v_m = 0 AND v_special_bye_team_id IS NOT NULL THEN
      UPDATE public.boxe_matches
      SET team1_id = v_special_bye_team_id,
          team2_id = NULL,
          winner_id = v_special_bye_team_id,
          status = 'completed',
          completed_at = now(),
          is_special_bye = true
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = 0;
      v_team_idx := v_team_idx + 1;
    ELSIF v_m > 0 AND v_m <= v_num_tech_byes THEN
      UPDATE public.boxe_matches
      SET team1_id = v_sorted_teams[v_team_idx],
          team2_id = NULL,
          winner_id = v_sorted_teams[v_team_idx],
          status = 'completed',
          completed_at = now()
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
      v_team_idx := v_team_idx + 1;
    ELSE
      UPDATE public.boxe_matches
      SET team1_id = v_sorted_teams[v_team_idx],
          team2_id = v_sorted_teams[v_team_idx + 1],
          status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
      v_team_idx := v_team_idx + 2;
    END IF;
  END LOOP;

  FOR v_round IN 0..(v_total_rounds - 2) LOOP
    FOR v_cm IN (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id AND round = v_round AND status = 'completed' AND winner_id IS NOT NULL) LOOP
      v_next_match_idx := (v_cm.match_index / 2)::INTEGER;
      IF v_cm.match_index % 2 = 0 THEN
        UPDATE public.boxe_matches SET team1_id = v_cm.winner_id
        WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
      ELSE
        UPDATE public.boxe_matches SET team2_id = v_cm.winner_id
        WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
      END IF;

      UPDATE public.boxe_matches SET status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
    END LOOP;
  END LOOP;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$$;

-- 11. SUBMIT BOXE MATCH RESULT RPC
DROP FUNCTION IF EXISTS public.submit_boxe_match_result(TEXT, UUID, UUID);
DROP FUNCTION IF EXISTS public.submit_boxe_match_result(UUID, UUID, UUID);

CREATE OR REPLACE FUNCTION public.submit_boxe_match_result(
  p_match_id TEXT,
  p_winner_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_max_round INTEGER;
  v_next_match_idx INTEGER;
  v_team RECORD;
  v_res JSONB;
BEGIN
  SELECT * INTO v_match FROM public.boxe_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
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
  ELSE
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
$$;

-- 12. ROLLBACK BOXE MATCH RESULT RPC
DROP FUNCTION IF EXISTS public.rollback_boxe_match_result(TEXT, UUID);
DROP FUNCTION IF EXISTS public.rollback_boxe_match_result(UUID, UUID);

CREATE OR REPLACE FUNCTION public.rollback_boxe_match_result(
  p_match_id TEXT,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_max_round INTEGER;
  v_next_match RECORD;
  v_next_match_idx INTEGER;
  v_res JSONB;
BEGIN
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
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
