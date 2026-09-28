-- Rollback della migrazione 44_fix_enigma_jackpot_state_leak.sql: ripristina il comportamento precedente
-- (p_team_id passato dal chiamante ha priorita' su current_team_id() - la falla torna aperta)

CREATE OR REPLACE FUNCTION public.get_enigma_state(p_challenge_id uuid, p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_attempts JSONB;
  v_is_completed BOOLEAN;
  v_prog RECORD;
BEGIN
  v_team_id := COALESCE(p_team_id, public.current_team_id());
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_prog FROM public.team_progress
  WHERE team_id = v_team_id AND challenge_id = p_challenge_id;

  v_is_completed := (FOUND AND v_prog.stato = 'completed');

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', ea.id,
      'attempt_number', ea.attempt_number,
      'answer', ea.answer,
      'is_correct', ea.is_correct,
      'submitted_at', ea.submitted_at
    ) ORDER BY ea.attempt_number
  ), '[]'::jsonb)
  INTO v_attempts
  FROM public.enigma_attempts ea
  WHERE ea.team_id = v_team_id AND ea.challenge_id = p_challenge_id;

  RETURN jsonb_build_object(
    'attempts', v_attempts,
    'attempt_count', jsonb_array_length(v_attempts),
    'is_completed', v_is_completed,
    'completed_at', CASE WHEN v_is_completed THEN v_prog.completata_il ELSE NULL END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_jackpot_state(p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_play RECORD;
  v_current_score INTEGER := 0;
BEGIN
  v_team_id := COALESCE(p_team_id, public.current_team_id());

  IF v_team_id IS NOT NULL THEN
    SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_current_score
    FROM public.scores
    WHERE team_id = v_team_id;

    SELECT * INTO v_play
    FROM public.jackpot_plays
    WHERE team_id = v_team_id AND challenge_id = v_challenge_id
    ORDER BY timestamp DESC
    LIMIT 1;

    IF v_play.id IS NOT NULL THEN
      RETURN jsonb_build_object('played', true, 'play', row_to_json(v_play), 'current_score', v_current_score);
    ELSE
      RETURN jsonb_build_object('played', false, 'play', NULL, 'current_score', v_current_score);
    END IF;
  ELSE
    RETURN jsonb_build_object('played', false, 'play', NULL, 'current_score', 0);
  END IF;
END;
$function$;
