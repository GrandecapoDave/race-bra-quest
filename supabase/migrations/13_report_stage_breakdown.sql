-- 13_report_stage_breakdown.sql
-- Resoconto finale (Regia): dettaglio per tappa di ogni squadra (prove con punti, bonus acquistati, malus sferrati con punti
-- cattiveria, malus subiti, registro cattiveria). Il resoconto admin lo mostrava vuoto perche' il report non conteneva
-- `stages_breakdown`.

CREATE OR REPLACE FUNCTION public.team_stage_at(p_team_id uuid, p_at timestamptz)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT COALESCE(
    (SELECT s.id
       FROM public.stages s
      WHERE EXISTS (SELECT 1 FROM public.challenges c WHERE c.stage_id = s.id AND c.tipo_sfida <> 'jackpot')
        AND (SELECT COUNT(*) FROM public.challenges c WHERE c.stage_id = s.id AND c.tipo_sfida <> 'jackpot') >
            (SELECT COUNT(DISTINCT tp.challenge_id)
               FROM public.team_progress tp
               JOIN public.challenges c ON c.id = tp.challenge_id
              WHERE tp.team_id = p_team_id AND c.stage_id = s.id AND c.tipo_sfida <> 'jackpot'
                AND tp.stato = 'completed' AND COALESCE(tp.completata_il, now()) <= p_at)
      ORDER BY s.numero_tappa ASC
      LIMIT 1),
    (SELECT s.id FROM public.stages s ORDER BY s.numero_tappa DESC LIMIT 1)
  );
$function$;
REVOKE ALL ON FUNCTION public.team_stage_at(uuid, timestamptz) FROM PUBLIC, anon, authenticated;

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
          'last_completion', fp.last_completion,
          'stages_breakdown',
          COALESCE(
            (
              SELECT jsonb_agg(
                jsonb_build_object(
                  'stage_id', st.id,
                  'stage_order', st.numero_tappa,
                  'stage_name', st.titolo,
                  'stage_total_points',
                    COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = fp.id AND s.stage_id = st.id), 0),
                  'challenges',
                    COALESCE((
                      SELECT jsonb_agg(
                        jsonb_build_object(
                          'challenge_id', c.id,
                          'title', c.titolo,
                          'max_points', c.punteggio_massimo,
                          'completed', EXISTS (
                            SELECT 1 FROM public.team_progress tp
                            WHERE tp.team_id = fp.id AND tp.challenge_id = c.id AND tp.stato = 'completed'
                          ),
                          'points_awarded',
                            COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = fp.id AND s.challenge_id = c.id), 0)
                        )
                        ORDER BY c.ordine_sfida
                      )
                      FROM public.challenges c
                      WHERE c.stage_id = st.id
                    ), '[]'::jsonb),
                  'bonuses_used',
                    COALESCE((
                      SELECT jsonb_agg(
                        jsonb_build_object(
                          'transaction_id', mt.id,
                          'name', mi.nome,
                          'cost_tokens', mt.costo_token
                        )
                        ORDER BY mt.data_acquisto
                      )
                      FROM public.marketplace_transactions mt
                      JOIN public.marketplace_items mi ON mi.id = mt.marketplace_item_id
                      WHERE mt.team_id = fp.id
                        AND UPPER(COALESCE(mi.tipo, '')) = 'BONUS'
                        AND mt.marketplace_item_id <> 'reward_stage'
                        AND COALESCE(mt.stage_id, public.team_stage_at(fp.id, mt.data_acquisto)) = st.id
                    ), '[]'::jsonb),
                  'maluses_used',
                    COALESCE((
                      SELECT jsonb_agg(
                        jsonb_build_object(
                          'transaction_id', mt.id,
                          'name', mi.nome,
                          'cost_tokens', mt.costo_token,
                          'target_team_name', (SELECT tt.nome_squadra FROM public.teams tt WHERE tt.id = mt.target_team_id),
                          'blocked_by_shield', (mt.stato = 'expired'),
                          'cattiveria_delta',
                            COALESCE((SELECT SUM(cl.punti) FROM public.cattiveria_ledger cl WHERE cl.team_id = fp.id AND cl.riferimento_transazione = mt.id AND cl.punti > 0), 0)
                        )
                        ORDER BY mt.data_acquisto
                      )
                      FROM public.marketplace_transactions mt
                      JOIN public.marketplace_items mi ON mi.id = mt.marketplace_item_id
                      WHERE mt.team_id = fp.id
                        AND UPPER(COALESCE(mi.tipo, '')) = 'MALUS'
                        AND COALESCE(mt.stage_id, public.team_stage_at(fp.id, mt.data_acquisto)) = st.id
                    ), '[]'::jsonb),
                  'maluses_suffered',
                    COALESCE((
                      SELECT jsonb_agg(
                        jsonb_build_object(
                          'transaction_id', mt.id,
                          'name', mi.nome,
                          'attacker_team_name', (SELECT at2.nome_squadra FROM public.teams at2 WHERE at2.id = mt.team_id),
                          'blocked_by_shield', (mt.stato = 'expired')
                        )
                        ORDER BY mt.data_acquisto
                      )
                      FROM public.marketplace_transactions mt
                      JOIN public.marketplace_items mi ON mi.id = mt.marketplace_item_id
                      WHERE mt.target_team_id = fp.id
                        AND UPPER(COALESCE(mi.tipo, '')) = 'MALUS'
                        AND COALESCE(mt.stage_id, public.team_stage_at(fp.id, mt.data_acquisto)) = st.id
                    ), '[]'::jsonb),
                  'cattiveria_entries',
                    COALESCE((
                      SELECT jsonb_agg(
                        jsonb_build_object('id', cl.id, 'punti', cl.punti, 'motivo', cl.motivo, 'tipo', cl.tipo)
                        ORDER BY cl.timestamp
                      )
                      FROM public.cattiveria_ledger cl
                      WHERE cl.team_id = fp.id AND cl.stage_id = st.id
                    ), '[]'::jsonb)
                )
                ORDER BY st.numero_tappa
              )
              FROM public.stages st
            ),
            '[]'::jsonb
          )
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
