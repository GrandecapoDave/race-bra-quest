-- Rollback della migrazione 37_fix_reopen_stage.sql: ripristina il comportamento precedente (rotto)
DROP FUNCTION IF EXISTS public.reopen_stage(uuid, uuid);

CREATE OR REPLACE FUNCTION public.reopen_stage(p_stage_id uuid)
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

  UPDATE public.stages SET stato = 'open' WHERE id = p_stage_id;
END;
$function$;
