-- ============================================================
-- PECHINO EXPRESS BRA
-- Migration 05: Admin RPC / DB alignment
-- STAGING ONLY
-- ============================================================

-- ============================================================
-- 1. TIME BONUS
-- ============================================================

CREATE OR REPLACE FUNCTION public._get_time_bonus_points(
  p_rank INTEGER
)
RETURNS INTEGER
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


-- ============================================================
-- 2. ADMIN: ADJUST SCORE
-- ============================================================

CREATE OR REPLACE FUNCTION public.admin_adjust_team_score(
  p_team_id UUID,
  p_punti INTEGER,
  p_motivo TEXT,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_score_id UUID;
  v_team_name TEXT;
BEGIN
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


-- ============================================================
-- 3. ADMIN: DELETE SCORE
-- ============================================================

CREATE OR REPLACE FUNCTION public.admin_delete_team_score(
  p_score_id UUID,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_team_id UUID;
  v_points INTEGER;
  v_reason TEXT;
BEGIN
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


-- ============================================================
-- 4. FINAL RESULTS
-- ============================================================

DROP FUNCTION IF EXISTS public.calculate_final_game_results(uuid);
CREATE OR REPLACE FUNCTION public.calculate_final_game_results(
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_report JSONB;
  v_calculated_at TIMESTAMPTZ := now();
BEGIN
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


-- ============================================================
-- 5. REOPEN FINAL RESULTS
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_reopen_game_results(uuid);
CREATE OR REPLACE FUNCTION public.admin_reopen_game_results(
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
BEGIN
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


-- ============================================================
-- 6. CORNHOLE RESET
-- ============================================================

CREATE OR REPLACE FUNCTION public.reset_cornhole_tournament(
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_challenge_id UUID :=
    'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
BEGIN
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


-- ============================================================
-- 7. CORNHOLE GENERATION
--
-- round 0 = preliminari
-- round 1+ = tabellone principale
--
-- I match del round successivo vengono creati in anticipo.
-- submit_* riempie gli slot con i vincitori.
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_cornhole_tournament(
  p_admin_id UUID DEFAULT NULL,
  p_special_bye_team_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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


-- ============================================================
-- 8. CORNHOLE GET
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_cornhole_tournament()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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


-- ============================================================
-- 9. BOXE RESET
-- ============================================================

CREATE OR REPLACE FUNCTION public.reset_boxe_tournament(
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_challenge_id UUID :=
    'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
BEGIN
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


-- ============================================================
-- 10. BOXE GENERATION
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_boxe_tournament(
  p_admin_id UUID DEFAULT NULL,
  p_special_bye_team_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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


-- ============================================================
-- 11. GRANTS
-- ============================================================

GRANT EXECUTE ON FUNCTION public._get_time_bonus_points(INTEGER)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_adjust_team_score(
  UUID, INTEGER, TEXT, UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_delete_team_score(
  UUID, UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.calculate_final_game_results(
  UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_reopen_game_results(
  UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.generate_cornhole_tournament(
  UUID, UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_cornhole_tournament()
TO authenticated;

GRANT EXECUTE ON FUNCTION public.reset_cornhole_tournament(
  UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.generate_boxe_tournament(
  UUID, UUID
)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.reset_boxe_tournament(
  UUID
)
TO authenticated;