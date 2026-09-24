-- 07_tournament_and_idempotency_fixes.sql
-- 1) Cornhole/Boxe: bracket corretto con numero di squadre non potenza di 2 (15 squadre) e senza bye speciale.
--    - il confronto con il bye NULL escludeva tutte le squadre dal tabellone
--    - i vincitori dei preliminari entrano nel round 1 negli slot 0..P-1 (2m -> team1, 2m+1 -> team2),
--      gli ingressi diretti occupano gli slot successivi; la propagazione dei risultati usa la regola generica
--      (match_index/2, pari -> team1), coerente con il rollback.
--    - con bye speciale una squadra andava persa e un'altra duplicata (spostamento dai diretti ai preliminari)
--    - con N potenza di 2 (8, 16) veniva creato un round 1 con troppi incontri e il torneo non terminava mai
-- 3) Resoconto finale: il calcolo scriveva nello snapshot pubblico invece che in calculated_snapshot, quindi la pubblicazione
--    mostrava alle squadre un report vuoto/obsoleto; la riapertura non ritirava il report pubblicato.
-- 4) Indici univoci sugli username.
-- 2) Quiz, Banca e PIN Codice Segreto: i punti si assegnano una sola volta (doppio click / richieste ripetute).

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
    v_round_matches := v_main_size / 4;  -- N potenza di 2: il round 0 ha già N/2 incontri, il round 1 ne ha N/4

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
      IF v_bye_team IS NULL OR v_team_ids[v_index] <> v_bye_team THEN
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
      -- sposta l'ultimo ingresso diretto tra i preliminari (prima lo copia, poi lo rimuove: nessuna squadra persa o duplicata)
      v_prelim_teams := array_append(
        v_prelim_teams,
        v_direct_teams[array_length(v_direct_teams, 1)]
      );

      v_direct_teams := v_direct_teams[1:array_length(v_direct_teams, 1) - 1];
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

      -- Slot del round 1: i primi P slot attendono i vincitori dei preliminari, poi gli ingressi diretti
      IF 2 * v_match_index >= v_prelim_matches THEN
        v_index := 1 + (2 * v_match_index - v_prelim_matches);
        IF v_index <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team1 := v_direct_teams[v_index];
        END IF;
      END IF;

      IF 2 * v_match_index + 1 >= v_prelim_matches THEN
        v_index := 1 + (2 * v_match_index + 1 - v_prelim_matches);
        IF v_index <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team2 := v_direct_teams[v_index];
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

    IF FALSE THEN -- i preliminari usano la regola generica (match_index/2)
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
    v_round_matches := v_main_size / 4;  -- N potenza di 2: il round 0 ha già N/2 incontri, il round 1 ne ha N/4

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
      IF v_bye_team IS NULL OR v_team_ids[v_index] <> v_bye_team THEN
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
      -- sposta l'ultimo ingresso diretto tra i preliminari (prima lo copia, poi lo rimuove: nessuna squadra persa o duplicata)
      v_prelim_teams := array_append(
        v_prelim_teams,
        v_direct_teams[array_length(v_direct_teams, 1)]
      );

      v_direct_teams := v_direct_teams[1:array_length(v_direct_teams, 1) - 1];
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

      -- Slot del round 1: i primi P slot attendono i vincitori dei preliminari, poi gli ingressi diretti
      IF 2 * v_match_index >= v_prelim_matches THEN
        v_index := 1 + (2 * v_match_index - v_prelim_matches);
        IF v_index <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team1 := v_direct_teams[v_index];
        END IF;
      END IF;

      IF 2 * v_match_index + 1 >= v_prelim_matches THEN
        v_index := 1 + (2 * v_match_index + 1 - v_prelim_matches);
        IF v_index <= COALESCE(array_length(v_direct_teams, 1), 0) THEN
          v_team2 := v_direct_teams[v_index];
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

    IF FALSE THEN -- i preliminari usano la regola generica (match_index/2)
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
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'correct', v_correct,
    'letter', v_extracted_letter,
    'challenge_completed', v_challenge_completed
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
  END IF;

  RETURN jsonb_build_object(
    'success', v_correct,
    'message', CASE WHEN v_correct THEN 'Sbloccato!' ELSE 'Codice errato. Controlla attentamente le cifre.' END
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
  SET calculated_snapshot = v_report,
      calculated_at = v_calculated_at,
      calculated_by = p_admin_id,
      status = CASE WHEN status = 'PUBLISHED' THEN status ELSE 'CALCULATED' END,
      updated_at = v_calculated_at
  WHERE id = 'current';

  IF NOT FOUND THEN
    INSERT INTO public.game_report (
      id,
      state,
      published_at,
      published_by,
      snapshot,
      calculated_snapshot,
      calculated_at,
      calculated_by,
      status,
      updated_at
    )
    VALUES (
      'current',
      'PRIVATE_LIVE',
      NULL,
      NULL,
      NULL,
      v_report,
      v_calculated_at,
      p_admin_id,
      'CALCULATED',
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
    status = CASE WHEN calculated_snapshot IS NOT NULL THEN 'CALCULATED' ELSE 'NOT_CALCULATED' END,
    published_at = NULL,
    published_by = NULL,
    snapshot = NULL,
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

-- 4) Username univoci (una creazione con username già esistente rendeva il login ambiguo)
CREATE UNIQUE INDEX IF NOT EXISTS teams_username_lower_unique ON public.teams (lower(username)) WHERE username IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS user_roles_username_lower_unique ON public.user_roles (lower(username)) WHERE username IS NOT NULL;
