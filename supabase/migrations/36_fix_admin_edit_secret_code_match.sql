-- 36_fix_admin_edit_secret_code_match.sql
-- Bug: admin_edit_secret_code_match era rimasta una funzione "finta" (commento originale: "Logica fittizia per
-- evitare errori"), con firma diversa (3 argomenti) da quella che il pulsante "Modifica" della pagina Regia >
-- Codice Segreto prova a chiamare (5 argomenti: squadra acquirente, venditrice, tipo frammento, costo, admin).
-- Risultato: il salvataggio falliva sempre con "Could not find the function ... in the schema cache".
-- Ora la funzione scrive davvero l'abbinamento: assegna alla squadra acquirente il frammento richiesto (le 5
-- cifre giuste prese da game_final_code), imposta da chi deve comprare l'altra meta' e a che costo.

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_match(
  p_buyer_team_id uuid,
  p_seller_team_id uuid,
  p_assigned_part_type text,
  p_token_cost integer,
  p_admin_id uuid DEFAULT NULL::uuid
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_full_code text;
  v_first5 text;
  v_last5 text;
  v_code_part text;
  v_required_part text;
BEGIN
  PERFORM public.assert_admin_caller();

  IF p_assigned_part_type NOT IN ('FIRST_5', 'LAST_5') THEN
    RAISE EXCEPTION 'Tipo di frammento non valido: %', p_assigned_part_type;
  END IF;
  IF p_token_cost IS NULL OR p_token_cost < 1 OR p_token_cost > 6 THEN
    RAISE EXCEPTION 'Il costo del frammento deve essere tra 1 e 6 token';
  END IF;
  IF p_buyer_team_id IS NULL OR p_seller_team_id IS NULL THEN
    RAISE EXCEPTION 'Squadra acquirente e venditrice sono obbligatorie';
  END IF;
  IF p_buyer_team_id = p_seller_team_id THEN
    RAISE EXCEPTION 'Una squadra non puo'' essere venditrice di se stessa';
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current';
  IF v_full_code IS NULL OR length(v_full_code) <> 10 THEN
    RAISE EXCEPTION 'Codice PIN globale non configurato correttamente (servono 10 cifre)';
  END IF;
  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  v_code_part := CASE WHEN p_assigned_part_type = 'FIRST_5' THEN v_first5 ELSE v_last5 END;
  v_required_part := CASE WHEN p_assigned_part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END;

  INSERT INTO public.team_code_parts (team_id, code_part, part_type)
  VALUES (p_buyer_team_id, v_code_part, p_assigned_part_type)
  ON CONFLICT (team_id) DO UPDATE
    SET code_part = EXCLUDED.code_part, part_type = EXCLUDED.part_type;

  INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
  VALUES (p_buyer_team_id, p_seller_team_id, v_required_part, p_token_cost)
  ON CONFLICT (buyer_team_id) DO UPDATE
    SET seller_team_id = EXCLUDED.seller_team_id, required_part = EXCLUDED.required_part, token_cost = EXCLUDED.token_cost;

  RETURN jsonb_build_object('success', true, 'code_part', v_code_part, 'required_part', v_required_part);
END;
$function$;
REVOKE ALL ON FUNCTION public.admin_edit_secret_code_match(uuid, uuid, text, integer, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_edit_secret_code_match(uuid, uuid, text, integer, uuid) TO authenticated;

-- La vecchia funzione finta aveva una firma diversa (3 argomenti): la rimuovo per non lasciarla in giro.
DROP FUNCTION IF EXISTS public.admin_edit_secret_code_match(uuid, uuid, uuid);
