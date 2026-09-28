-- Rollback della migrazione 35_team_race_seconds_before_start.sql: ripristina il comportamento precedente
-- (usa t.created_at come inizio quando race_started_at e' NULL).

CREATE OR REPLACE FUNCTION public.team_race_seconds(p_team_id uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT GREATEST(0, (
    EXTRACT(EPOCH FROM (fin.f - COALESCE(gs.race_started_at, t.created_at)))
    - public.race_paused_seconds_until(fin.f)
    + COALESCE((SELECT SUM(tp.minuti_penalita) * 60 FROM public.time_penalties tp WHERE tp.team_id = p_team_id), 0)
    - 120 * (SELECT COUNT(*) FROM public.marketplace_transactions mt
              WHERE mt.team_id = p_team_id AND mt.marketplace_item_id = 'partenza_anticipata')
  ))::numeric
  FROM public.teams t
  LEFT JOIN public.game_settings gs ON gs.id = 'settings_01'
  CROSS JOIN LATERAL (SELECT COALESCE(public.team_mandatory_finish(p_team_id), gs.race_ended_at, now()) AS f) fin
  WHERE t.id = p_team_id;
$function$;
REVOKE ALL ON FUNCTION public.team_race_seconds(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.team_race_seconds(uuid) TO authenticated;
