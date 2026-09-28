-- Rollback della migrazione 41_fix_admin_update_enigma_solution.sql: ripristina il comportamento precedente (rotto)
CREATE OR REPLACE FUNCTION public.admin_update_enigma_solution(p_challenge_id uuid, p_solution jsonb, p_admin_id uuid)
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

  INSERT INTO public.enigma_solutions (challenge_id, solution, solution_type)
  VALUES (p_challenge_id, p_solution, 'text')
  ON CONFLICT (challenge_id) 
  DO UPDATE SET solution = EXCLUDED.solution;
END;
$function$;
