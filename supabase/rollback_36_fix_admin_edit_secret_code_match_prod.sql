-- Rollback della migrazione 36_fix_admin_edit_secret_code_match.sql: ripristina la funzione finta originale
-- (esisteva gia' rotta prima della migrazione: il pulsante "Modifica" tornera' a dare errore come prima).

DROP FUNCTION IF EXISTS public.admin_edit_secret_code_match(uuid, uuid, text, integer, uuid);

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_match(p_team_id uuid, p_partner_id uuid, p_admin_id uuid)
 RETURNS void
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
  -- Logica fittizia per evitare errori
END;
$function$;
