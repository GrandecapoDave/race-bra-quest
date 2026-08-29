BEGIN;

-- ==========================================================
-- 1. TABELLE ORIGINALI PER CODICE SEGRETO
-- ==========================================================

CREATE TABLE IF NOT EXISTS public.team_code_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  code_part TEXT NOT NULL,
  part_type TEXT NOT NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT team_code_parts_team_id_key UNIQUE (team_id)
);

CREATE TABLE IF NOT EXISTS public.team_code_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  seller_team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  required_part TEXT NOT NULL,
  token_cost INTEGER NOT NULL DEFAULT 4,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT team_code_matches_buyer_key UNIQUE (buyer_team_id)
);

CREATE TABLE IF NOT EXISTS public.code_purchase_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  seller_team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  token_cost INTEGER NOT NULL,
  digits_received TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT code_purchase_transactions_buyer_key UNIQUE (buyer_team_id)
);

ALTER TABLE public.team_code_parts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Code Parts" ON public.team_code_parts;
CREATE POLICY "Public Read Code Parts" ON public.team_code_parts FOR SELECT USING (true);

ALTER TABLE public.team_code_matches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Code Matches" ON public.team_code_matches;
CREATE POLICY "Public Read Code Matches" ON public.team_code_matches FOR SELECT USING (true);

ALTER TABLE public.code_purchase_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Code Purchases" ON public.code_purchase_transactions;
CREATE POLICY "Public Read Code Purchases" ON public.code_purchase_transactions FOR SELECT USING (true);

-- ==========================================================
-- 2. RPC GET_SECRET_CODE_STATE (RANGE 3-5 TOKEN COME IN LOCALHOST)
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
  v_part RECORD;
  v_match RECORD;
  v_seller_team RECORD;
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
  v_cost INTEGER;
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

  -- 2. Assegna/Recupera match (partner e costo 3-5 token)
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  IF NOT FOUND THEN
    -- Cerca un'altra squadra attiva
    SELECT * INTO v_other_team 
    FROM public.teams 
    WHERE id <> p_team_id AND active = true 
    ORDER BY created_at ASC 
    LIMIT 1;

    IF FOUND THEN
      -- Costo tra 3 e 5 Token (default 4)
      v_cost := 4;
      INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
      VALUES (
        p_team_id, 
        v_other_team.id, 
        CASE WHEN v_part.part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END,
        v_cost
      )
      ON CONFLICT (buyer_team_id) DO NOTHING;

      SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
    END IF;
  END IF;

  IF v_match.seller_team_id IS NOT NULL THEN
    SELECT * INTO v_seller_team FROM public.teams WHERE id = v_match.seller_team_id;
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
      'seller_name', COALESCE(v_seller_team.nome_squadra, 'Regia'),
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

DROP FUNCTION IF EXISTS public.buy_secret_code_part();
CREATE OR REPLACE FUNCTION public.buy_secret_code_part()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_buyer_id UUID;
  v_match RECORD;
  v_buyer RECORD;
  v_seller RECORD;
  v_cost INTEGER;
  v_full_code TEXT;
  v_digits TEXT;
BEGIN
  v_buyer_id := public.current_team_id();
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Verifica se già acquistato
  IF EXISTS (SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = v_buyer_id) THEN
    RETURN jsonb_build_object('success', true, 'message', 'Frammento già acquistato');
  END IF;

  -- Assicura match
  PERFORM public.get_secret_code_state(v_buyer_id);
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = v_buyer_id;

  v_cost := COALESCE(v_match.token_cost, 4);

  SELECT * INTO v_buyer FROM public.teams WHERE id = v_buyer_id FOR UPDATE;
  IF (v_buyer.token_balance < v_cost) THEN
    RAISE EXCEPTION 'Token insufficienti (Costo: % Token, Tuo saldo: %)', v_cost, v_buyer.token_balance;
  END IF;

  -- Scala token al compratore
  UPDATE public.teams SET token_balance = token_balance - v_cost WHERE id = v_buyer_id;

  -- Accredita token al venditore se presente
  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> v_buyer_id THEN
    UPDATE public.teams SET token_balance = token_balance + v_cost WHERE id = v_match.seller_team_id;
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_digits := CASE WHEN v_match.required_part = 'FIRST_5' THEN SUBSTRING(v_full_code FROM 1 FOR 5) ELSE SUBSTRING(v_full_code FROM 6 FOR 5) END;

  -- Registra transazione nella tabella dedicata code_purchase_transactions
  INSERT INTO public.code_purchase_transactions (
    buyer_team_id, seller_team_id, token_cost, digits_received
  )
  VALUES (
    v_buyer_id, COALESCE(v_match.seller_team_id, v_buyer_id), v_cost, v_digits
  )
  ON CONFLICT (buyer_team_id) DO NOTHING;

  -- Registra log attività
  INSERT INTO public.activity_log (team_id, target_team_id, tipo_evento, dettagli)
  VALUES (
    v_buyer_id, 
    v_match.seller_team_id, 
    'buy_secret_code_part', 
    jsonb_build_object('cost', v_cost, 'digits', v_digits)
  );

  RETURN jsonb_build_object('success', true, 'digits', v_digits, 'cost', v_cost);
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
