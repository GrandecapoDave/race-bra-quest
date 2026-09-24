-- 15_safeupdate_fixes.sql
-- Supabase rifiuta UPDATE/DELETE senza WHERE ("UPDATE requires a WHERE clause"): "Reset Torneo" (Boxe e Cornhole) e
-- "Inizializza Codice Segreto" fallivano sempre. Aggiunto WHERE esplicito, stessa logica.

CREATE OR REPLACE FUNCTION public.initialize_secret_code_challenge()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_teams UUID[];
  v_count INTEGER;
  v_i INTEGER;
  v_full_code TEXT := '4829167305';
  v_first5 TEXT;
  v_last5 TEXT;
  v_buyer_id UUID;
  v_seller_id UUID;
  v_part_type TEXT;
  v_required_type TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current';
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- Collect active teams
  SELECT array_agg(id ORDER BY created_at ASC) INTO v_teams
  FROM public.teams
  WHERE active = true;

  v_count := COALESCE(array_length(v_teams, 1), 0);
  IF v_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nessuna squadra attiva trovata.');
  END IF;

  -- Clear previous assignments if regenerating
  DELETE FROM public.team_code_matches WHERE true;
  DELETE FROM public.team_code_parts WHERE true;

  -- Assign parts: alternating FIRST_5 and LAST_5
  FOR v_i IN 1..v_count LOOP
    v_buyer_id := v_teams[v_i];
    
    IF v_i % 2 = 1 THEN
      v_part_type := 'FIRST_5';
      v_required_type := 'LAST_5';
      INSERT INTO public.team_code_parts (team_id, code_part, part_type)
      VALUES (v_buyer_id, v_first5, 'FIRST_5')
      ON CONFLICT (team_id) DO UPDATE SET code_part = v_first5, part_type = 'FIRST_5';
    ELSE
      v_part_type := 'LAST_5';
      v_required_type := 'FIRST_5';
      INSERT INTO public.team_code_parts (team_id, code_part, part_type)
      VALUES (v_buyer_id, v_last5, 'LAST_5')
      ON CONFLICT (team_id) DO UPDATE SET code_part = v_last5, part_type = 'LAST_5';
    END IF;

    -- Pair with next team in circle (cyclic matching)
    IF v_count > 1 THEN
      IF v_i < v_count THEN
        v_seller_id := v_teams[v_i + 1];
      ELSE
        v_seller_id := v_teams[1];
      END IF;
    ELSE
      v_seller_id := v_buyer_id;
    END IF;

    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (v_buyer_id, v_seller_id, v_required_type, 4)
    ON CONFLICT (buyer_team_id) 
    DO UPDATE SET seller_team_id = v_seller_id, required_part = v_required_type, token_cost = 4;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'message', 'Abbinamenti e frammenti codice segreto configurati per ' || v_count || ' squadre.');
END;
$function$;

CREATE OR REPLACE FUNCTION public.reset_boxe_tournament(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NOT NULL
     AND NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.boxe_matches
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.scores
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.team_progress
  WHERE challenge_id = v_challenge_id;

  UPDATE public.game_settings
  SET boxe_special_bye_team_id = NULL
  WHERE true;

  IF p_admin_id IS NOT NULL THEN
    INSERT INTO public.activity_log (
      id, tipo_evento, team_id, target_team_id,
      dettagli, created_at
    )
    VALUES (
      gen_random_uuid(),
      'BOXE_RESET',
      NULL,
      NULL,
      jsonb_build_object('admin_id', p_admin_id),
      now()
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.reset_cornhole_tournament(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID :=
    'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NOT NULL
     AND NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.cornhole_matches
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.scores
  WHERE challenge_id = v_challenge_id;

  DELETE FROM public.team_progress
  WHERE challenge_id = v_challenge_id;

  UPDATE public.game_settings
  SET cornhole_special_bye_team_id = NULL
  WHERE true;

  IF p_admin_id IS NOT NULL THEN
    INSERT INTO public.activity_log (
      id,
      tipo_evento,
      team_id,
      target_team_id,
      dettagli,
      created_at
    )
    VALUES (
      gen_random_uuid(),
      'CORNHOLE_RESET',
      NULL,
      NULL,
      jsonb_build_object('admin_id', p_admin_id),
      now()
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$function$;
