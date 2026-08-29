BEGIN;

-- ==========================================================
-- RPC GET_SECRET_CODE_STATE E SUBMIT_SECRET_CODE_PIN
-- ==========================================================

CREATE OR REPLACE FUNCTION public.get_secret_code_state(p_team_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_full_code TEXT;
  v_destination TEXT;
  v_part TEXT;
  v_part_type TEXT;
  v_has_purchased BOOLEAN := false;
  v_purchased_digits TEXT := NULL;
  v_completed BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_team_idx INTEGER := 0;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  SELECT full_code, next_stage_destination 
  INTO v_full_code, v_destination 
  FROM public.game_final_code 
  WHERE id = 'current' 
  LIMIT 1;

  IF v_full_code IS NULL THEN
    v_full_code := '4829167305';
  END IF;
  IF v_destination IS NULL THEN
    v_destination := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)';
  END IF;

  -- Assegna FIRST_5 o LAST_5 in modo deterministico
  SELECT (ROW_NUMBER() OVER (ORDER BY created_at, id) - 1) INTO v_team_idx
  FROM public.teams
  WHERE id = p_team_id;

  IF COALESCE(v_team_idx, 0) % 2 = 1 THEN
    v_part_type := 'LAST_5';
    v_part := SUBSTRING(v_full_code FROM 6 FOR 5);
  ELSE
    v_part_type := 'FIRST_5';
    v_part := SUBSTRING(v_full_code FROM 1 FOR 5);
  END IF;

  -- Verifica se ha acquistato il frammento
  SELECT EXISTS(
    SELECT 1 FROM public.marketplace_transactions
    WHERE team_id = p_team_id AND marketplace_item_id = 'secret_code_part' AND stato = 'completed'
  ) INTO v_has_purchased;

  -- Se acquistato, le cifre mancanti sono l'altra metà
  IF v_has_purchased THEN
    IF v_part_type = 'FIRST_5' THEN
      v_purchased_digits := SUBSTRING(v_full_code FROM 6 FOR 5);
    ELSE
      v_purchased_digits := SUBSTRING(v_full_code FROM 1 FOR 5);
    END IF;
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.team_progress
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND stato = 'completed'
  ) INTO v_completed;

  RETURN jsonb_build_object(
    'part', jsonb_build_object('code_part', v_part, 'part_type', v_part_type),
    'match', jsonb_build_object(
      'seller_name', 'Regia / Altra Squadra',
      'token_cost', 15,
      'required_part', CASE WHEN v_part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END
    ),
    'has_purchased', v_has_purchased,
    'purchased_digits', v_purchased_digits,
    'completed', v_completed,
    'destination', v_destination
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_secret_code_pin(p_inserted_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_correct_pin TEXT;
  v_correct BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_stage_id UUID;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT full_code INTO v_correct_pin FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_correct_pin IS NULL THEN
    v_correct_pin := '4829167305';
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  v_correct := (TRIM(p_inserted_code) = TRIM(v_correct_pin));

  IF v_correct THEN
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, v_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, 30, 'challenge_points', 'Sfida PIN superata')
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN jsonb_build_object(
    'success', v_correct,
    'message', CASE WHEN v_correct THEN 'Sbloccato!' ELSE 'Codice errato. Controlla attentamente le cifre.' END
  );
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
