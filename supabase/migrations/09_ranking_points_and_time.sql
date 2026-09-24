-- 09_ranking_points_and_time.sql
-- Classifica: tutte le prove sono obbligatorie tranne il Jackpot (facoltativo). Si contano i punti totalizzati e il minor tempo
-- impiegato per completare tutte le prove obbligatorie.
--  * tempo = ultima prova obbligatoria completata - avvio gara (game_settings.race_started_at, in mancanza creazione squadra)
--            + penalità di tempo - 2 minuti per ogni Partenza Anticipata acquistata; il Jackpot non conta per il tempo.
--  * classifica live: squadre attive, poi punti totali, poi prove obbligatorie completate, poi tempo minore.
--  * risultato finale: chi ha completato tutte le prove obbligatorie sta davanti a chi no; poi come prima (punti + bonus tempo + efficienza token) ma il bonus tempo spetta solo a chi ha completato
--    tutte le prove obbligatorie.

CREATE OR REPLACE FUNCTION public.team_mandatory_finish(p_team_id uuid)
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT CASE
    WHEN (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') =
         (SELECT COUNT(DISTINCT tp.challenge_id)
            FROM public.team_progress tp
            JOIN public.challenges c ON c.id = tp.challenge_id
           WHERE tp.team_id = p_team_id AND tp.stato = 'completed' AND c.tipo_sfida <> 'jackpot')
    THEN (SELECT MAX(tp.completata_il)
            FROM public.team_progress tp
            JOIN public.challenges c ON c.id = tp.challenge_id
           WHERE tp.team_id = p_team_id AND tp.stato = 'completed' AND c.tipo_sfida <> 'jackpot')
  END;
$function$;

CREATE OR REPLACE FUNCTION public.team_race_seconds(p_team_id uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT GREATEST(0, (
    EXTRACT(EPOCH FROM (
      COALESCE(public.team_mandatory_finish(p_team_id), gs.race_ended_at, now())
      - COALESCE(gs.race_started_at, t.created_at)
    ))
    + COALESCE((SELECT SUM(tp.minuti_penalita) * 60 FROM public.time_penalties tp WHERE tp.team_id = p_team_id), 0)
    - 120 * (SELECT COUNT(*) FROM public.marketplace_transactions mt
              WHERE mt.team_id = p_team_id AND mt.marketplace_item_id = 'partenza_anticipata')
  ))::numeric
  FROM public.teams t
  LEFT JOIN public.game_settings gs ON gs.id = 'settings_01'
  WHERE t.id = p_team_id;
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
      (SELECT COUNT(DISTINCT tp.challenge_id) FROM public.team_progress tp JOIN public.challenges ch ON ch.id = tp.challenge_id WHERE tp.team_id = t.id AND tp.stato = 'completed' AND ch.tipo_sfida <> 'jackpot') AS l_comp_ch,
      public.team_race_seconds(t.id)::NUMERIC AS l_duration,
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
        ORDER BY rb.l_active DESC, rb.l_tot_pts DESC, rb.l_comp_ch DESC, rb.l_duration ASC, rb.l_last_comp ASC NULLS LAST
      )::INTEGER AS l_rank
    FROM raw_leaderboard rb
  )
  SELECT
    rl.l_team_id, rl.l_name, rl.l_color, rl.l_avatar_url, rl.l_motto, rl.l_ch_pts, rl.l_mod_pts, rl.l_catt_pts, rl.l_tot_pts, rl.l_comp_ch, rl.l_duration, rl.l_last_comp, rl.l_active, rl.l_freeze_start, rl.l_freeze_exp, rl.l_rank
  FROM ranked_leaderboard rl
  WHERE v_has_bonus = true OR rl.l_team_id = v_caller_team_id;
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
    JOIN public.challenges ch ON ch.id = tp.challenge_id
    WHERE ch.tipo_sfida <> 'jackpot'
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
              FROM (comp.last_completion - COALESCE(gs.race_started_at, t.created_at))
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
    LEFT JOIN public.game_settings gs ON gs.id = 'settings_01'
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
          (CASE WHEN tb.completed_challenges < (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') THEN 1 ELSE 0 END) ASC,
          tb.total_time_seconds ASC,
          tb.last_completion ASC NULLS LAST,
          tb.created_at ASC
      )::INTEGER AS time_rank
    FROM team_base tb
  ),

  scored AS (
    SELECT
      r.*,
      (CASE WHEN r.completed_challenges < (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') THEN 0 ELSE public._get_time_bonus_points(r.time_rank) END) AS time_bonus,
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
          (CASE WHEN f.completed_challenges < (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') THEN 1 ELSE 0 END) ASC,
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
