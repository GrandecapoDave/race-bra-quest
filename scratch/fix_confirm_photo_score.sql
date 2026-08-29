BEGIN;

-- ==========================================================
-- AGGIORNAMENTO RPC CONFIRM_PHOTO_SCORE PER ADMIN
-- ==========================================================

DROP FUNCTION IF EXISTS public.confirm_photo_score(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.confirm_photo_score(UUID, INTEGER, UUID);

CREATE OR REPLACE FUNCTION public.confirm_photo_score(
  p_submission_id UUID,
  p_points INTEGER,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_sub RECORD;
  v_stage_id UUID;
  v_team RECORD;
  v_challenge RECORD;
BEGIN
  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = v_sub.challenge_id;
  v_stage_id := v_challenge.stage_id;

  -- Aggiorna stato approvazione su submissions a 'confirmed'
  UPDATE public.submissions 
  SET stato_approvazione = 'confirmed' 
  WHERE id = p_submission_id;

  -- Segna progresso come completed se non già fatto
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Registra / Aggiorna punteggio in scores
  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, v_stage_id, p_points, 'challenge_points', 'Valutazione foto: ' || COALESCE(v_challenge.titolo, 'Foto'))
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET punti = EXCLUDED.punti, stage_id = EXCLUDED.stage_id, motivo = EXCLUDED.motivo;

  RETURN jsonb_build_object('success', true, 'points', p_points, 'submission_id', p_submission_id);
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
