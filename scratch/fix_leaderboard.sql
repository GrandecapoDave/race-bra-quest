BEGIN;

CREATE OR REPLACE FUNCTION public.get_secure_leaderboard()
RETURNS TABLE (
  team_id UUID,
  name TEXT,
  color TEXT,
  avatar_url TEXT,
  motto TEXT,
  challenges_points NUMERIC,
  modifier_points NUMERIC,
  cattiveria_points NUMERIC,
  total_points NUMERIC,
  completed_challenges BIGINT,
  total_duration_seconds NUMERIC,
  last_completion TIMESTAMPTZ,
  active BOOLEAN,
  freeze_started_at TIMESTAMPTZ,
  freeze_expires_at TIMESTAMPTZ,
  rank INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_has_bonus BOOLEAN := false;
  v_is_admin BOOLEAN := false;
BEGIN
  v_caller_team_id := public.current_team_id();
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;

  IF v_is_admin THEN
    v_has_bonus := true;
  ELSIF v_caller_team_id IS NOT NULL THEN
    SELECT EXISTS(
      SELECT 1 FROM public.marketplace_transactions mt
      WHERE mt.team_id = v_caller_team_id AND mt.marketplace_item_id = 'bonus_classifica' AND mt.stato = 'viewing'
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
      COALESCE((SELECT SUM(cl.punti) FROM public.cattiveria_ledger cl WHERE cl.team_id = t.id), 0)::NUMERIC AS l_catt_pts,
      (
        COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) +
        COALESCE((SELECT SUM(cl.punti) FROM public.cattiveria_ledger cl WHERE cl.team_id = t.id), 0)
      )::NUMERIC AS l_tot_pts,
      COALESCE((SELECT COUNT(*) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed'), 0)::BIGINT AS l_comp_ch,
      COALESCE((SELECT SUM(tpn.minuti_penalita * 60) FROM public.time_penalties tpn WHERE tpn.team_id = t.id), 0)::NUMERIC AS l_duration,
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
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
