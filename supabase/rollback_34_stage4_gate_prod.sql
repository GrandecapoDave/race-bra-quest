-- Rollback della migrazione 34_stage4_gate.sql

CREATE OR REPLACE FUNCTION public.is_bank_gated_challenge(p_challenge_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT COALESCE((
    SELECT (s.numero_tappa = 3 AND c.ordine_sfida > 1) OR s.numero_tappa > 3
    FROM public.challenges c
    JOIN public.stages s ON s.id = c.stage_id
    WHERE c.id = p_challenge_id
  ), false);
$function$;
REVOKE ALL ON FUNCTION public.is_bank_gated_challenge(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_bank_gated_challenge(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.assert_gate_open(p_challenge_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF public.has_role(auth.uid(), 'admin'::text) THEN
    RETURN;
  END IF;
  IF public.is_bank_gated_challenge(p_challenge_id)
     AND NOT EXISTS (SELECT 1 FROM public.game_settings WHERE id = 'settings_01' AND bank_gate_open = true) THEN
    RAISE EXCEPTION 'In attesa della Regia: recatevi presso la banca BPER e attendete il via per proseguire con le prove.';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION public.assert_gate_open(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_gate_open(uuid) TO authenticated;

DROP FUNCTION IF EXISTS public.set_stage4_gate(boolean, uuid);
DROP FUNCTION IF EXISTS public.is_stage4_gated_challenge(uuid);
ALTER TABLE public.game_settings DROP COLUMN IF EXISTS stage4_gate_open;
