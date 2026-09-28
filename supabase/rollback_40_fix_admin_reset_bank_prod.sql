-- Rollback della migrazione 40_fix_admin_reset_bank.sql: ripristina il comportamento precedente (rotto)
CREATE OR REPLACE FUNCTION public.admin_reset_bank(p_team_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.team_answers WHERE team_id = p_team_id;
  DELETE FROM public.team_progress WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
  DELETE FROM public.scores WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
END;
$function$;
