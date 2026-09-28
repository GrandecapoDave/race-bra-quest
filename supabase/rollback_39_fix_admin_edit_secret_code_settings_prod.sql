-- Rollback della migrazione 39_fix_admin_edit_secret_code_settings.sql: ripristina la funzione finta originale
CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_settings(p_full_code text, p_destination text, p_admin_id uuid)
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
