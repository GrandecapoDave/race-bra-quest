-- 35_team_race_seconds_before_start.sql
-- Bug: prima che la Regia avvii la gara (race_started_at ancora NULL), team_race_seconds() usava come inizio
-- l'orario di CREAZIONE della squadra (t.created_at) invece di restare vuoto. Risultato: nella Classifica live
-- (Regia e squadre) il "Tempo" mostrava ore assurde, crescenti giorno dopo giorno, invece di "—".
-- Usata solo da get_secure_leaderboard (classifica live): il Resoconto finale ha un calcolo separato, non tocco.
-- Corretto: se la gara non e' ancora iniziata, restituisce NULL (l'app lo mostra gia' come "—"). Una volta avviata
-- la gara, il calcolo e' identico a prima: nessun cambiamento sul tempo ufficiale di gara.

CREATE OR REPLACE FUNCTION public.team_race_seconds(p_team_id uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT CASE WHEN gs.race_started_at IS NULL THEN NULL ELSE GREATEST(0, (
    EXTRACT(EPOCH FROM (fin.f - gs.race_started_at))
    - public.race_paused_seconds_until(fin.f)
    + COALESCE((SELECT SUM(tp.minuti_penalita) * 60 FROM public.time_penalties tp WHERE tp.team_id = p_team_id), 0)
    - 120 * (SELECT COUNT(*) FROM public.marketplace_transactions mt
              WHERE mt.team_id = p_team_id AND mt.marketplace_item_id = 'partenza_anticipata')
  ))::numeric END
  FROM public.teams t
  LEFT JOIN public.game_settings gs ON gs.id = 'settings_01'
  CROSS JOIN LATERAL (SELECT COALESCE(public.team_mandatory_finish(p_team_id), gs.race_ended_at, now()) AS f) fin
  WHERE t.id = p_team_id;
$function$;
REVOKE ALL ON FUNCTION public.team_race_seconds(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.team_race_seconds(uuid) TO authenticated;
