-- 20_secret_code_circular_barter.sql
-- Codice Segreto: ogni squadra paga una squadra DIVERSA (catena circolare, nessun venditore ripetuto, funziona anche con squadre dispari),
-- costo casuale 1-6 token fissato all'avvio della gara. Se mancano token: BARATTO (paga i token che ha, il resto in punti: 3 PT per token mancante).
-- Prima tutti pagavano la squadra piu' vecchia (costo fisso 4).

CREATE OR REPLACE FUNCTION public.build_secret_code_matches()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_teams UUID[];
  v_count INTEGER;
  v_i INTEGER;
  v_full_code TEXT;
  v_first5 TEXT;
  v_last5 TEXT;
  v_buyer_id UUID;
  v_seller_id UUID;
  v_required_type TEXT;
  v_cost INTEGER;
BEGIN
  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current';
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;
  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- ordine casuale delle squadre attive: la catena A->B->C->...->A non segue l'ordine di iscrizione
  SELECT array_agg(id ORDER BY random()) INTO v_teams FROM public.teams WHERE active = true;
  v_count := COALESCE(array_length(v_teams, 1), 0);
  IF v_count = 0 THEN RETURN 0; END IF;

  DELETE FROM public.team_code_matches WHERE true;
  DELETE FROM public.team_code_parts WHERE true;

  FOR v_i IN 1..v_count LOOP
    v_buyer_id := v_teams[v_i];
    IF v_i % 2 = 1 THEN
      INSERT INTO public.team_code_parts (team_id, code_part, part_type) VALUES (v_buyer_id, v_first5, 'FIRST_5');
      v_required_type := 'LAST_5';
    ELSE
      INSERT INTO public.team_code_parts (team_id, code_part, part_type) VALUES (v_buyer_id, v_last5, 'LAST_5');
      v_required_type := 'FIRST_5';
    END IF;

    -- catena circolare: ogni squadra paga la successiva e incassa dalla precedente (nessun venditore ripetuto).
    -- Con una sola squadra il venditore e' la Regia (se stessa).
    IF v_count = 1 THEN
      v_seller_id := v_buyer_id;
    ELSIF v_i < v_count THEN
      v_seller_id := v_teams[v_i + 1];
    ELSE
      v_seller_id := v_teams[1];
    END IF;

    v_cost := 1 + floor(random() * 6)::integer;  -- 1..6 token

    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (v_buyer_id, v_seller_id, v_required_type, v_cost);
  END LOOP;

  RETURN v_count;
END;
$function$;
REVOKE ALL ON FUNCTION public.build_secret_code_matches() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.initialize_secret_code_challenge()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_count INTEGER;
BEGIN
  PERFORM public.assert_admin_caller();
  v_count := public.build_secret_code_matches();
  IF v_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nessuna squadra attiva trovata.');
  END IF;
  RETURN jsonb_build_object('success', true, 'message', 'Abbinamenti e frammenti codice segreto configurati per ' || v_count || ' squadre.');
END;
$function$;

CREATE OR REPLACE FUNCTION public.buy_secret_code_part()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_buyer_id UUID;
  v_match RECORD;
  v_buyer RECORD;
  v_cost INTEGER;
  v_paid_tokens INTEGER;
  v_missing_tokens INTEGER;
  v_barter_points INTEGER := 0;
  v_full_code TEXT;
  v_digits TEXT;
BEGIN
  v_buyer_id := public.current_team_id();
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext('secret_code_buy:' || v_buyer_id::text));

  -- Verifica se gia' acquistato
  IF EXISTS (SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = v_buyer_id) THEN
    RETURN jsonb_build_object('success', true, 'message', 'Frammento già acquistato');
  END IF;

  -- Assicura match
  PERFORM public.get_secret_code_state(v_buyer_id);
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = v_buyer_id;

  v_cost := COALESCE(v_match.token_cost, 4);

  SELECT * INTO v_buyer FROM public.teams WHERE id = v_buyer_id FOR UPDATE;

  -- BARATTO: se mancano token si paga quello che si ha e il resto in punti (3 PT per ogni token mancante)
  v_paid_tokens := LEAST(v_cost, v_buyer.token_balance);
  v_missing_tokens := v_cost - v_paid_tokens;
  IF v_missing_tokens > 0 THEN
    v_barter_points := v_missing_tokens * 3;
  END IF;

  UPDATE public.teams SET token_balance = token_balance - v_paid_tokens WHERE id = v_buyer_id;

  IF v_barter_points > 0 THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_buyer_id, -v_barter_points, 'penalty',
            'Baratto Codice Segreto: ' || v_missing_tokens::text || ' token mancanti pagati in punti (−' || v_barter_points::text || ' PT)');
  END IF;

  -- Il venditore incassa sempre l'importo intero (token). Se il venditore e' la Regia i token spariscono.
  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> v_buyer_id THEN
    UPDATE public.teams SET token_balance = token_balance + v_cost WHERE id = v_match.seller_team_id;
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_digits := CASE WHEN v_match.required_part = 'FIRST_5' THEN SUBSTRING(v_full_code FROM 1 FOR 5) ELSE SUBSTRING(v_full_code FROM 6 FOR 5) END;

  INSERT INTO public.code_purchase_transactions (buyer_team_id, seller_team_id, token_cost, digits_received)
  VALUES (v_buyer_id, COALESCE(v_match.seller_team_id, v_buyer_id), v_cost, v_digits)
  ON CONFLICT (buyer_team_id) DO NOTHING;

  INSERT INTO public.activity_log (team_id, target_team_id, tipo_evento, dettagli)
  VALUES (
    v_buyer_id,
    v_match.seller_team_id,
    'buy_secret_code_part',
    jsonb_build_object('cost', v_cost, 'tokens_paid', v_paid_tokens, 'missing_tokens', v_missing_tokens, 'barter_points', v_barter_points, 'digits', v_digits)
  );

  RETURN jsonb_build_object('success', true, 'digits', v_digits, 'cost', v_cost,
                            'tokens_paid', v_paid_tokens, 'missing_tokens', v_missing_tokens, 'barter_points', v_barter_points);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_secret_code_state(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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

  -- 2. Assegna/Recupera match: normalmente creato all'avvio gara (catena circolare, venditori tutti diversi).
  --    Ripiego per squadre aggiunte dopo l'avvio: pagano la Regia (seller = se stessa) con costo casuale 1-6.
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  IF NOT FOUND THEN
    IF NOT EXISTS (SELECT 1 FROM public.team_code_matches) THEN
      PERFORM public.build_secret_code_matches();
    ELSE
      INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
      VALUES (
        p_team_id,
        p_team_id,
        CASE WHEN v_part.part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END,
        1 + floor(random() * 6)::integer
      )
      ON CONFLICT (buyer_team_id) DO NOTHING;
    END IF;
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
$function$;

CREATE OR REPLACE FUNCTION public.start_global_race(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_now TIMESTAMPTZ := now();
BEGIN
  PERFORM public.assert_admin_caller();
  UPDATE public.game_settings
  SET
    race_status = 'in_progress',
    race_started_at = v_now,
    race_ended_at = NULL,
    activated_at = COALESCE(activated_at, v_now),
    activated_by = COALESCE(p_admin_id, activated_by)
  WHERE id = 'settings_01';

  -- Codice Segreto: catena circolare di venditori e costi casuali 1-6, creata una sola volta a inizio gara
  IF NOT EXISTS (SELECT 1 FROM public.team_code_matches) THEN
    PERFORM public.build_secret_code_matches();
  END IF;

  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'race_started',
    jsonb_build_object('message', '🏁 LA GARA È UFFICIALMENTE INIZIATA! Il timer globale è attivo.', 'started_at', v_now)
  );

  RETURN jsonb_build_object('success', true, 'race_status', 'in_progress', 'race_started_at', v_now);
END;
$function$;
