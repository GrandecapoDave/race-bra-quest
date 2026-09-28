-- 39_fix_admin_edit_secret_code_settings.sql
-- Bug (silenzioso, nessun errore): come admin_edit_secret_code_match, era rimasta una funzione finta che
-- controllava solo il ruolo admin e non scriveva nulla. Il modulo "Configurazione PIN Globale" nella pagina
-- Codice Segreto mostrava "Impostazioni globali aggiornate!" ma il PIN e la destinazione su game_final_code
-- restavano quelli di prima: chi avesse provato a correggerli non se ne sarebbe accorto.
-- Ora la funzione scrive davvero su game_final_code, con un controllo minimo sul formato del PIN.

-- La funzione finta restituiva void: serve DROP prima di ricrearla con un tipo di ritorno diverso (jsonb).
DROP FUNCTION IF EXISTS public.admin_edit_secret_code_settings(text, text, uuid);

CREATE FUNCTION public.admin_edit_secret_code_settings(p_full_code text, p_destination text, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
  IF p_full_code IS NULL OR p_full_code !~ '^[0-9]{10}$' THEN
    RAISE EXCEPTION 'Il PIN deve essere composto esattamente da 10 cifre';
  END IF;
  IF p_destination IS NULL OR length(trim(p_destination)) = 0 THEN
    RAISE EXCEPTION 'La destinazione non può essere vuota';
  END IF;

  INSERT INTO public.game_final_code (id, full_code, next_stage_destination)
  VALUES ('current', p_full_code, p_destination)
  ON CONFLICT (id) DO UPDATE
    SET full_code = EXCLUDED.full_code, next_stage_destination = EXCLUDED.next_stage_destination;

  RETURN jsonb_build_object('success', true, 'full_code', p_full_code, 'destination', p_destination);
END;
$function$;
REVOKE ALL ON FUNCTION public.admin_edit_secret_code_settings(text, text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_edit_secret_code_settings(text, text, uuid) TO authenticated;
