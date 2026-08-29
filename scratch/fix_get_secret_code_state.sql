BEGIN;

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
  v_part RECORD;
  v_match RECORD;
  v_seller_name TEXT := 'Regia';
  v_first5 TEXT;
  v_last5 TEXT;
  v_has_purchased BOOLEAN := false;
  v_purchased_digits TEXT := NULL;
  v_completed BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_other_team RECORD;
  v_team_idx INTEGER := 0;
  v_part_type TEXT;
  v_code_val TEXT;
  v_cost INTEGER := 4;
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

  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;
  IF v_destination IS NULL THEN v_destination := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'; END IF;

  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- 1. Assegna/Recupera frammento per il team
  SELECT * INTO v_part FROM public.team_code_parts WHERE team_id = p_team_id;
  IF NOT FOUND THEN
    SELECT (COUNT(*) % 2) INTO v_team_idx FROM public.team_code_parts;
    IF v_team_idx = 1 THEN
      v_part_type := 'LAST_5';
      v_code_val := v_last5;
    ELSE
      v_part_type := 'FIRST_5';
      v_code_val := v_first5;
    END IF;

    INSERT INTO public.team_code_parts (team_id, code_part, part_type)
    VALUES (p_team_id, v_code_val, v_part_type)
    ON CONFLICT (team_id) DO NOTHING;

    SELECT * INTO v_part FROM public.team_code_parts WHERE team_id = p_team_id;
  END IF;

  -- 2. Assegna/Recupera match (partner e costo tra 3 e 5 token, default 4)
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  IF NOT FOUND THEN
    SELECT * INTO v_other_team 
    FROM public.teams 
    WHERE id <> p_team_id AND active = true 
    ORDER BY created_at ASC 
    LIMIT 1;

    v_cost := 4;
    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (
      p_team_id, 
      COALESCE(v_other_team.id, p_team_id), 
      CASE WHEN v_part.part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END,
      v_cost
    )
    ON CONFLICT (buyer_team_id) DO NOTHING;

    SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  END IF;

  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> p_team_id THEN
    SELECT COALESCE(nome_squadra, 'Altra Squadra') INTO v_seller_name FROM public.teams WHERE id = v_match.seller_team_id;
  ELSE
    v_seller_name := 'Regia';
  END IF;

  -- 3. Controlla se ha acquistato il frammento
  SELECT EXISTS(
    SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = p_team_id
  ) INTO v_has_purchased;

  IF v_has_purchased THEN
    SELECT digits_received INTO v_purchased_digits 
    FROM public.code_purchase_transactions 
    WHERE buyer_team_id = p_team_id 
    LIMIT 1;

    IF v_purchased_digits IS NULL THEN
      v_purchased_digits := CASE WHEN v_part.part_type = 'FIRST_5' THEN v_last5 ELSE v_first5 END;
    END IF;
  END IF;

  -- 4. Controlla completamento
  SELECT EXISTS(
    SELECT 1 FROM public.team_progress
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND stato = 'completed'
  ) INTO v_completed;

  RETURN jsonb_build_object(
    'part', jsonb_build_object('code_part', v_part.code_part, 'part_type', v_part.part_type),
    'match', CASE WHEN v_match.id IS NOT NULL THEN jsonb_build_object(
      'seller_team_id', v_match.seller_team_id,
      'seller_name', v_seller_name,
      'required_part', v_match.required_part,
      'token_cost', COALESCE(v_match.token_cost, 4)
    ) ELSE NULL END,
    'has_purchased', v_has_purchased,
    'purchased_digits', v_purchased_digits,
    'completed', v_completed,
    'destination', v_destination
  );
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
