-- 24_race_pause_and_bank_gate.sql
-- 1) PAUSA/RIPRESA della gara (Regia): il cronometro si ferma per tutte le squadre insieme e ripartisce insieme;
--    durante la pausa le squadre non possono fare prove, risposte, acquisti (controllo sul server).
-- 2) BLOCCO BANCA: dopo aver risolto La Banca (Tappa 3, sfida 1) le squadre non possono avviare le sfide successive
--    (Tappa 3 dalla sfida 2 in poi, Tappe 4 e 5) finche' la Regia non sblocca; il blocco si puo' rimettere. Il tempo scorre.
-- 3) RPC di orologio per le squadre: get_race_clock (tempo di gara effettivo) e get_my_race_times (effettivo e ufficiale).

-- ---------------------------------------------------------------------------------------------
-- Dati
-- ---------------------------------------------------------------------------------------------
ALTER TABLE public.game_settings ADD COLUMN IF NOT EXISTS race_paused boolean NOT NULL DEFAULT false;
ALTER TABLE public.game_settings ADD COLUMN IF NOT EXISTS bank_gate_open boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.race_pauses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  started_by uuid,
  ended_by uuid
);
ALTER TABLE public.race_pauses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin Read Race Pauses" ON public.race_pauses;
CREATE POLICY "Admin Read Race Pauses" ON public.race_pauses
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::text));
REVOKE ALL ON public.race_pauses FROM anon;

-- ---------------------------------------------------------------------------------------------
-- Funzioni di supporto
-- ---------------------------------------------------------------------------------------------

-- secondi di pausa che cadono tra l'avvio gara e p_until
CREATE OR REPLACE FUNCTION public.race_paused_seconds_until(p_until timestamptz)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT COALESCE(SUM(GREATEST(0, EXTRACT(EPOCH FROM (
    LEAST(COALESCE(rp.ended_at, now()), p_until) - GREATEST(rp.started_at, gs.race_started_at)
  )))), 0)::numeric
  FROM public.race_pauses rp
  CROSS JOIN public.game_settings gs
  WHERE gs.id = 'settings_01' AND gs.race_started_at IS NOT NULL;
$function$;
REVOKE ALL ON FUNCTION public.race_paused_seconds_until(timestamptz) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.assert_race_not_paused()
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
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE id = 'settings_01' AND race_paused = true) THEN
    RAISE EXCEPTION 'La gara è in pausa. Attendete la ripresa comunicata dalla Regia.';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION public.assert_race_not_paused() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_race_not_paused() TO authenticated;

-- sfide bloccate dal punto di ritrovo alla banca: Tappa 3 dalla sfida 2 in poi e tutte le tappe successive
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

-- ---------------------------------------------------------------------------------------------
-- Comandi della Regia
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pause_global_race(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_status text;
BEGIN
  PERFORM public.assert_admin_caller();
  PERFORM pg_advisory_xact_lock(hashtext('race_pause'));
  SELECT race_status INTO v_status FROM public.game_settings WHERE id = 'settings_01';
  IF v_status IS DISTINCT FROM 'in_progress' THEN
    RAISE EXCEPTION 'La gara non è in corso: non si può mettere in pausa.';
  END IF;
  IF EXISTS (SELECT 1 FROM public.race_pauses WHERE ended_at IS NULL) THEN
    RETURN jsonb_build_object('success', true, 'paused', true, 'message', 'Gara già in pausa');
  END IF;
  INSERT INTO public.race_pauses (started_at, started_by) VALUES (now(), COALESCE(p_admin_id, auth.uid()));
  UPDATE public.game_settings SET race_paused = true WHERE id = 'settings_01';
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES ('race_paused', jsonb_build_object('message', '⏸️ GARA IN PAUSA: il tempo è fermo per tutte le squadre.'));
  RETURN jsonb_build_object('success', true, 'paused', true);
END;
$function$;
REVOKE ALL ON FUNCTION public.pause_global_race(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pause_global_race(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.resume_global_race(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  PERFORM public.assert_admin_caller();
  PERFORM pg_advisory_xact_lock(hashtext('race_pause'));
  UPDATE public.race_pauses SET ended_at = now(), ended_by = COALESCE(p_admin_id, auth.uid()) WHERE ended_at IS NULL;
  UPDATE public.game_settings SET race_paused = false WHERE id = 'settings_01';
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES ('race_resumed', jsonb_build_object('message', '▶️ GARA RIPRESA: il tempo riparte per tutte le squadre.'));
  RETURN jsonb_build_object('success', true, 'paused', false);
END;
$function$;
REVOKE ALL ON FUNCTION public.resume_global_race(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resume_global_race(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_bank_gate(p_open boolean, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  PERFORM public.assert_admin_caller();
  UPDATE public.game_settings SET bank_gate_open = COALESCE(p_open, false) WHERE id = 'settings_01';
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    CASE WHEN p_open THEN 'bank_gate_opened' ELSE 'bank_gate_closed' END,
    jsonb_build_object('message', CASE WHEN p_open THEN '🔓 Via libera dalla banca BPER: le prove successive sono sbloccate.' ELSE '🔒 Sfide successive alla banca bloccate dalla Regia.' END)
  );
  RETURN jsonb_build_object('success', true, 'bank_gate_open', COALESCE(p_open, false));
END;
$function$;
REVOKE ALL ON FUNCTION public.set_bank_gate(boolean, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_bank_gate(boolean, uuid) TO authenticated;

-- ---------------------------------------------------------------------------------------------
-- Orologio per le squadre
-- ---------------------------------------------------------------------------------------------
-- tempo di gara effettivo (senza pause), uguale per tutte le squadre
CREATE OR REPLACE FUNCTION public.get_race_clock()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT jsonb_build_object(
    'status', gs.race_status,
    'paused', gs.race_paused,
    'started_at', gs.race_started_at,
    'ended_at', gs.race_ended_at,
    'server_now', now(),
    'elapsed_seconds', CASE WHEN gs.race_started_at IS NULL THEN 0 ELSE
      GREATEST(0, EXTRACT(EPOCH FROM (COALESCE(gs.race_ended_at, now()) - gs.race_started_at))
                 - public.race_paused_seconds_until(COALESCE(gs.race_ended_at, now())))::bigint END
  )
  FROM public.game_settings gs WHERE gs.id = 'settings_01';
$function$;
REVOKE ALL ON FUNCTION public.get_race_clock() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_race_clock() TO authenticated;

-- ---------------------------------------------------------------------------------------------
-- Controlli inseriti all'inizio delle funzioni delle squadre (idempotente: non raddoppia se gia' presenti)
-- ---------------------------------------------------------------------------------------------
DO $patch$
DECLARE
  r record;
  def text;
  newdef text;
  guard text;
BEGIN
  FOR r IN
    SELECT p.oid, p.proname
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname IN (
        'start_challenge','complete_challenge','buy_marketplace_item','submit_quiz_answer','submit_bank_answer',
        'submit_emoji_movie_answer','submit_enigma_answer','submit_enigma_extra_answer','submit_social_challenge',
        'submit_secret_code_pin','buy_secret_code_part','play_jackpot','spin_unlucky_wheel',
        'submit_passaparola_request','open_classifica_bonus','consume_marketplace_transaction')
  LOOP
    def := pg_get_functiondef(r.oid);
    guard := '';
    IF position('assert_race_not_paused' IN def) = 0 THEN
      guard := guard || E'  PERFORM public.assert_race_not_paused();\n';
    END IF;
    IF position('assert_gate_open' IN def) = 0 THEN
      guard := guard || CASE r.proname
        WHEN 'start_challenge'         THEN E'  PERFORM public.assert_gate_open(p_challenge);\n'
        WHEN 'complete_challenge'      THEN E'  PERFORM public.assert_gate_open(p_challenge);\n'
        WHEN 'submit_enigma_answer'    THEN E'  PERFORM public.assert_gate_open(p_challenge_id);\n'
        WHEN 'submit_social_challenge' THEN E'  PERFORM public.assert_gate_open(''c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7''::uuid);\n'
        WHEN 'submit_secret_code_pin'  THEN E'  PERFORM public.assert_gate_open(''d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8''::uuid);\n'
        WHEN 'buy_secret_code_part'    THEN E'  PERFORM public.assert_gate_open(''d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8''::uuid);\n'
        WHEN 'play_jackpot'            THEN E'  PERFORM public.assert_gate_open(''f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0''::uuid);\n'
        ELSE '' END;
    END IF;
    IF guard = '' THEN CONTINUE; END IF;
    newdef := regexp_replace(def, E'\nBEGIN\n', E'\nBEGIN\n' || replace(guard, '\', '\\'));
    IF newdef = def THEN
      RAISE EXCEPTION 'Impossibile inserire i controlli in %', r.proname;
    END IF;
    EXECUTE newdef;
  END LOOP;
END
$patch$;

-- avvio / fine / azzeramento gara: gestione delle pause
DO $patch2$
DECLARE
  def text;
  newdef text;
BEGIN
  -- fine gara: chiude l'eventuale pausa aperta, cosi' il tempo non continua a essere sottratto
  def := pg_get_functiondef('public.end_global_race(uuid)'::regprocedure);
  IF position('race_pauses' IN def) = 0 THEN
    newdef := regexp_replace(def, E'\nBEGIN\n', E'\nBEGIN\n  UPDATE public.race_pauses SET ended_at = now() WHERE ended_at IS NULL;\n  UPDATE public.game_settings SET race_paused = false WHERE id = ''settings_01'';\n');
    IF newdef = def THEN RAISE EXCEPTION 'end_global_race non modificabile'; END IF;
    EXECUTE newdef;
  END IF;

  -- azzeramento e nuovo avvio: nessuna pausa residua di una gara precedente
  FOREACH def IN ARRAY ARRAY[pg_get_functiondef('public.reset_global_race(uuid)'::regprocedure), pg_get_functiondef('public.start_global_race(uuid)'::regprocedure)] LOOP
    IF position('race_pauses' IN def) = 0 THEN
      newdef := regexp_replace(def, E'\nBEGIN\n', E'\nBEGIN\n  DELETE FROM public.race_pauses WHERE true;\n  UPDATE public.game_settings SET race_paused = false WHERE id = ''settings_01'';\n');
      IF newdef = def THEN RAISE EXCEPTION 'funzione di avvio/azzeramento non modificabile'; END IF;
      EXECUTE newdef;
    END IF;
  END LOOP;
END
$patch2$;
