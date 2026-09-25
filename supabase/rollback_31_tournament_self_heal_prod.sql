-- rollback_31_tournament_self_heal_prod.sql
-- Ripristina start_challenge come era prima della migrazione 31 (definizione presa da Production il 2026-09-25).

CREATE OR REPLACE FUNCTION public.start_challenge(p_challenge uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_row RECORD;
  v_prev_incomplete BOOLEAN;
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open(p_challenge);
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato come team';
  END IF;

  -- Verifica esistenza della challenge
  SELECT * INTO v_challenge_row FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sfida non esistente';
  END IF;

  -- Controllo progressione della tappa (challenge con ordine_sfida inferiore nello stesso stage)
  SELECT EXISTS(
    SELECT 1 FROM public.challenges c
    LEFT JOIN public.team_progress tp ON tp.challenge_id = c.id AND tp.team_id = v_team_id
    WHERE c.stage_id = v_challenge_row.stage_id 
      AND c.ordine_sfida < v_challenge_row.ordine_sfida
      AND (tp.stato IS NULL OR tp.stato != 'completed')
  ) INTO v_prev_incomplete;

  IF v_prev_incomplete THEN
    RAISE EXCEPTION 'Devi prima completare le sfide precedenti di questa tappa';
  END IF;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, created_at)
  VALUES (v_team_id, p_challenge, 'in_progress', now())
  ON CONFLICT (team_id, challenge_id) DO NOTHING;
END;
$function$;
