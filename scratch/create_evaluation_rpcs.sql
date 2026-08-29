BEGIN;

-- 1. Aggiungi colonna voto a submissions se non esiste
ALTER TABLE public.submissions ADD COLUMN IF NOT EXISTS voto INTEGER DEFAULT NULL;

-- 2. Crea/Sostituisci evaluate_poster
DROP FUNCTION IF EXISTS public.evaluate_poster(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.evaluate_poster(UUID, INTEGER, UUID);

CREATE OR REPLACE FUNCTION public.evaluate_poster(
  p_submission_id UUID,
  p_voto INTEGER,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_sub RECORD;
  v_challenge RECORD;
  v_stage_id UUID;
BEGIN
  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = v_sub.challenge_id;
  v_stage_id := v_challenge.stage_id;

  -- Aggiorna submission
  UPDATE public.submissions 
  SET voto = p_voto, 
      stato_approvazione = 'confirmed'
  WHERE id = p_submission_id;

  -- Aggiorna progresso team
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la stessa sfida e inserisce quello nuovo
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_sub.challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, v_stage_id, p_voto, 'challenge_points', 'Valutazione Locandina Vivente (' || p_voto || '/15 PT)');

  -- Sblocca visibilità Marketplace nei game_settings se non già visibile
  UPDATE public.game_settings 
  SET marketplace_visible = true 
  WHERE id = 'current' AND marketplace_visible = false;

  RETURN jsonb_build_object('success', true, 'voto', p_voto, 'submission_id', p_submission_id);
END;
$$;

-- 3. Crea/Sostituisci evaluate_social_challenge
DROP FUNCTION IF EXISTS public.evaluate_social_challenge(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.evaluate_social_challenge(UUID, INTEGER, UUID);

CREATE OR REPLACE FUNCTION public.evaluate_social_challenge(
  p_submission_id UUID,
  p_voto INTEGER,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_sub RECORD;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
  v_stage_id UUID;
BEGIN
  -- Cerca prima in team_social_submissions
  SELECT * INTO v_sub FROM public.team_social_submissions WHERE id = p_submission_id;
  
  IF NOT FOUND THEN
    SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Sottomissione social non trovata';
    END IF;
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  -- Aggiorna team_social_submissions
  UPDATE public.team_social_submissions 
  SET status = 'approved',
      stato_approvazione = 'confirmed',
      admin_score = p_voto
  WHERE id = p_submission_id OR (team_id = v_sub.team_id AND challenge_id = v_challenge_id);

  -- Aggiorna anche submissions principale se presente
  UPDATE public.submissions 
  SET stato_approvazione = 'confirmed',
      voto = p_voto
  WHERE team_id = v_sub.team_id AND challenge_id = v_challenge_id;

  -- Segna progresso come completato
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la missione social e inserisce il voto confermato
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_challenge_id, v_stage_id, p_voto, 'challenge_points', 'Valutazione Missione Social (' || p_voto || '/20 PT)');

  RETURN jsonb_build_object('success', true, 'voto', p_voto, 'submission_id', p_submission_id);
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
