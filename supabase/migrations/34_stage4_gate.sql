-- 34_stage4_gate.sql
-- La Tappa 4 (Enigmi: Rebus Musicale, Lucchetto Direzionale, Le Coordinate Finali) si blocca come La Banca, ma con
-- un evento INDIPENDENTE: la Regia la sblocca con un comando suo, separato dal blocco della Banca. I due blocchi
-- non dipendono l'uno dall'altro: sbloccare la Banca non tocca la Tappa 4 e viceversa.
-- La Tappa 4 esce dal blocco della Banca (che prima la includeva insieme alla Tappa 5) e passa sotto questo nuovo
-- blocco, unico e proprio. Tappa 3 (fino al Codice Segreto) e Tappa 5 restano sotto il blocco della Banca, invariate.

ALTER TABLE public.game_settings ADD COLUMN IF NOT EXISTS stage4_gate_open boolean NOT NULL DEFAULT false;

-- La Tappa 4 non fa piu' parte del blocco della Banca (prima era inclusa insieme alla Tappa 5 in "numero_tappa > 3").
CREATE OR REPLACE FUNCTION public.is_bank_gated_challenge(p_challenge_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT COALESCE((
    SELECT (s.numero_tappa = 3 AND c.ordine_sfida > 1) OR s.numero_tappa = 5
    FROM public.challenges c
    JOIN public.stages s ON s.id = c.stage_id
    WHERE c.id = p_challenge_id
  ), false);
$function$;
REVOKE ALL ON FUNCTION public.is_bank_gated_challenge(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_bank_gated_challenge(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.is_stage4_gated_challenge(p_challenge_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT COALESCE((
    SELECT s.numero_tappa = 4
    FROM public.challenges c
    JOIN public.stages s ON s.id = c.stage_id
    WHERE c.id = p_challenge_id
  ), false);
$function$;
REVOKE ALL ON FUNCTION public.is_stage4_gated_challenge(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_stage4_gated_challenge(uuid) TO authenticated;

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
  IF public.is_stage4_gated_challenge(p_challenge_id)
     AND NOT EXISTS (SELECT 1 FROM public.game_settings WHERE id = 'settings_01' AND stage4_gate_open = true) THEN
    RAISE EXCEPTION 'La Tappa 4 (Enigmi) non è ancora aperta: attendete il via della Regia.';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION public.assert_gate_open(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_gate_open(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_stage4_gate(p_open boolean, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  PERFORM public.assert_admin_caller();
  UPDATE public.game_settings SET stage4_gate_open = COALESCE(p_open, false) WHERE id = 'settings_01';
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    CASE WHEN p_open THEN 'stage4_gate_opened' ELSE 'stage4_gate_closed' END,
    jsonb_build_object('message', CASE WHEN p_open THEN '🔓 Tappa 4 (Enigmi) sbloccata dalla Regia.' ELSE '🔒 Tappa 4 (Enigmi) bloccata dalla Regia.' END)
  );
  RETURN jsonb_build_object('success', true, 'stage4_gate_open', COALESCE(p_open, false));
END;
$function$;
REVOKE ALL ON FUNCTION public.set_stage4_gate(boolean, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_stage4_gate(boolean, uuid) TO authenticated;
