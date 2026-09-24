-- 19_secret_code_dashboard_fix.sql
-- 'Ordine di Decifrazione' (admin Codice Segreto) includeva i completamenti di Missione Social (id fisso sbagliato):
-- ora conta solo la sfida di tipo 'codice', in ordine di completamento.

CREATE OR REPLACE FUNCTION public.admin_get_secret_code_dashboard()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_full_code TEXT := '4829167305';
  v_destination TEXT := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)';
  v_parts JSONB := '[]'::jsonb;
  v_matches JSONB := '[]'::jsonb;
  v_transactions JSONB := '[]'::jsonb;
  v_attempts JSONB := '[]'::jsonb;
  v_completed_teams JSONB := '[]'::jsonb;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code, next_stage_destination 
  INTO v_full_code, v_destination 
  FROM public.game_final_code 
  WHERE id = 'current' 
  LIMIT 1;

  -- 1. Parts
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', tcp.id,
    'team_id', tcp.team_id,
    'code_part', tcp.code_part,
    'part_type', tcp.part_type,
    'assigned_at', tcp.assigned_at
  )), '[]'::jsonb) INTO v_parts
  FROM public.team_code_parts tcp;

  -- 2. Matches
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'buyer_team_id', tcm.buyer_team_id,
    'seller_team_id', tcm.seller_team_id,
    'required_part', tcm.required_part,
    'token_cost', COALESCE(tcm.token_cost, 4),
    'created_at', tcm.created_at
  )), '[]'::jsonb) INTO v_matches
  FROM public.team_code_matches tcm;

  -- 3. Transactions
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', cpt.id,
    'buyer_team_id', cpt.buyer_team_id,
    'seller_team_id', cpt.seller_team_id,
    'token_cost', cpt.token_cost,
    'digits_received', cpt.digits_received,
    'timestamp', cpt.created_at
  )), '[]'::jsonb) INTO v_transactions
  FROM public.code_purchase_transactions cpt;

  -- 4. Attempts from activity_log or attempts table
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', al.id,
    'team_id', al.team_id,
    'inserted_code', COALESCE(al.dettagli->>'inserted_code', al.dettagli->>'code', '—'),
    'timestamp', al.created_at,
    'success', (al.tipo_evento = 'secret_code_solved')
  ) ORDER BY al.created_at DESC), '[]'::jsonb) INTO v_attempts
  FROM public.activity_log al
  WHERE al.tipo_evento IN ('secret_code_solved', 'secret_code_attempt');

  -- 5. Completed teams
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', tp.team_id,
    'nome_squadra', t.nome_squadra,
    'completed_at', tp.completata_il
  ) ORDER BY tp.completata_il ASC), '[]'::jsonb) INTO v_completed_teams
  FROM public.team_progress tp
  JOIN public.teams t ON t.id = tp.team_id
  WHERE tp.challenge_id IN (SELECT id FROM public.challenges WHERE tipo_sfida = 'codice')
    AND tp.stato = 'completed';

  RETURN jsonb_build_object(
    'full_code', COALESCE(v_full_code, '4829167305'),
    'destination', COALESCE(v_destination, 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'),
    'parts', v_parts,
    'matches', v_matches,
    'transactions', v_transactions,
    'attempts', v_attempts,
    'completed_teams', v_completed_teams
  );
END;
$function$;
