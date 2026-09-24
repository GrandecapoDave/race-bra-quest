-- 21_privacy_additive.sql  (PASSO 1 di 2 - additivo, sicuro da applicare PRIMA del nuovo frontend)
-- Aggiunge cio' che il nuovo frontend usa al posto delle letture dirette sulle altre squadre:
--   * vista teams_public: nome, colore, avatar, motto (senza token, freeze, credenziali)
--   * RPC get_target_stage_summary: riepilogo per tappa della squadra bersaglio (finestra Dimezza Punti Tappa)
-- Non toglie nessun permesso: l'app attuale continua a funzionare identica.

CREATE OR REPLACE VIEW public.teams_public AS
  SELECT id, nome_squadra, colore, color, avatar_url, motto, active, created_at
  FROM public.teams;
REVOKE ALL ON public.teams_public FROM PUBLIC, anon;
GRANT SELECT ON public.teams_public TO authenticated;

-- 8) Dimezza Punti Tappa: la finestra di scelta mostrava punti e progressi grezzi della squadra bersaglio.
--    Ora un riepilogo per tappa (prove completate e punti guadagnati), senza il dettaglio delle righe.
CREATE OR REPLACE FUNCTION public.get_target_stage_summary(p_target_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;
  IF public.current_team_id() IS NULL AND NOT public.has_role(auth.uid(), 'admin'::text) THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'stage_id', s.id,
      'completed_challenges', (
        SELECT COUNT(DISTINCT tp.challenge_id)
        FROM public.team_progress tp
        JOIN public.challenges c ON c.id = tp.challenge_id
        WHERE tp.team_id = p_target_team_id AND c.stage_id = s.id AND tp.stato = 'completed'
      ),
      'earned_points', (
        SELECT COALESCE(SUM(sc.punti), 0)
        FROM public.scores sc
        WHERE sc.team_id = p_target_team_id AND sc.stage_id = s.id
          AND (sc.tipo_modificatore IS NULL OR sc.tipo_modificatore <> 'penalty_dimezza_tappa')
      )
    ) ORDER BY s.numero_tappa)
    FROM public.stages s
  ), '[]'::jsonb);
END;
$function$;
REVOKE ALL ON FUNCTION public.get_target_stage_summary(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_target_stage_summary(uuid) TO authenticated;
