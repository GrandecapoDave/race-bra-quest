-- 26_malus_server_enforcement.sql
-- I malus che bloccano una squadra (Freeze, Ruota Sfortunata da girare, Enigma Extra da risolvere) e il Blackout erano fatti
-- rispettare solo dalla schermata: un giocatore poteva aggirarli chiamando direttamente le funzioni del server.
--  * assert_team_not_blocked(): le azioni di gioco sono rifiutate mentre la squadra e' congelata o ha una Ruota Sfortunata / un Enigma Extra in sospeso.
--  * consume_marketplace_transaction: il bersaglio NON puo' piu' chiudere da solo una Ruota Sfortunata o un Enigma Extra (si risolvono
--    solo con spin_unlucky_wheel / submit_enigma_extra_answer); il Freeze si azzera solo quando e' davvero scaduto.
--  * Blackout Mercato: dura 6 minuti dall'acquisto anche se la transazione viene marcata 'used'.

CREATE OR REPLACE FUNCTION public.assert_team_not_blocked()
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id uuid;
  v_freeze timestamptz;
BEGIN
  IF public.has_role(auth.uid(), 'admin'::text) THEN
    RETURN;
  END IF;
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN;
  END IF;

  SELECT freeze_expires_at INTO v_freeze FROM public.teams WHERE id = v_team_id;
  IF v_freeze IS NOT NULL AND v_freeze > now() THEN
    RAISE EXCEPTION 'La tua squadra è congelata: attendi la fine del Freeze per compiere azioni.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id AND stato = 'completed'
      AND marketplace_item_id IN ('ruota_sfortunata', 'enigma_extra')
  ) THEN
    RAISE EXCEPTION 'Hai un malus da risolvere (Ruota Sfortunata o Enigma Extra): completalo per continuare.';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION public.assert_team_not_blocked() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_team_not_blocked() TO authenticated;

-- controllo inserito all'inizio delle funzioni di azione (NON in spin_unlucky_wheel, submit_enigma_extra_answer, consume: sono quelle che risolvono i malus)
DO $patch$
DECLARE
  r record;
  def text;
  newdef text;
BEGIN
  FOR r IN
    SELECT p.oid, p.proname
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname IN (
        'start_challenge','complete_challenge','buy_marketplace_item','submit_quiz_answer','submit_bank_answer',
        'submit_emoji_movie_answer','submit_enigma_answer','submit_social_challenge','submit_secret_code_pin',
        'buy_secret_code_part','play_jackpot','submit_passaparola_request','open_classifica_bonus')
  LOOP
    def := pg_get_functiondef(r.oid);
    IF position('assert_team_not_blocked' IN def) > 0 THEN CONTINUE; END IF;
    newdef := regexp_replace(def, E'\nBEGIN\n', E'\nBEGIN\n  PERFORM public.assert_team_not_blocked();\n');
    IF newdef = def THEN RAISE EXCEPTION 'Impossibile inserire il controllo in %', r.proname; END IF;
    EXECUTE newdef;
  END LOOP;
END
$patch$;

-- Blackout: vale per 6 minuti dall'acquisto anche se la transazione e' stata marcata 'used' (prima bastava "consumarla" per annullarlo)
DO $patch3$
DECLARE
  def text;
  newdef text;
BEGIN
  def := pg_get_functiondef('public.buy_marketplace_item(text,uuid,uuid)'::regprocedure);
  IF position('stato IN (''completed'', ''used'')' IN def) = 0 THEN
    newdef := replace(def,
      E'      AND marketplace_item_id = ''blackout_mercato''\n      AND stato = ''completed''\n      AND (data_acquisto + INTERVAL ''6 minutes'') > now()',
      E'      AND marketplace_item_id = ''blackout_mercato''\n      AND stato IN (''completed'', ''used'')\n      AND (data_acquisto + INTERVAL ''6 minutes'') > now()');
    IF newdef = def THEN RAISE EXCEPTION 'controllo blackout non trovato'; END IF;
    EXECUTE newdef;
  END IF;
END
$patch3$;

-- consume_marketplace_transaction con le nuove regole
CREATE OR REPLACE FUNCTION public.consume_marketplace_transaction(p_transaction_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_team_id UUID;
  v_is_admin BOOLEAN;
  v_tx RECORD;
  v_freeze timestamptz;
BEGIN
  PERFORM public.assert_race_not_paused();
  IF auth.uid() IS NULL AND auth.role() <> 'service_role' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;
  v_team_id := public.current_team_id();
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;

  SELECT * INTO v_tx
  FROM public.marketplace_transactions
  WHERE id = p_transaction_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  -- Verifica autorizzazione: acquirente, bersaglio o admin
  IF NOT COALESCE(v_is_admin, false) AND v_team_id IS NOT NULL AND v_tx.team_id != v_team_id AND (v_tx.target_team_id IS NULL OR v_tx.target_team_id != v_team_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autorizzato');
  END IF;

  -- Ruota Sfortunata ed Enigma Extra si chiudono solo girando la ruota / risolvendo l'enigma: il bersaglio non puo' saltarli
  IF NOT COALESCE(v_is_admin, false)
     AND v_tx.stato = 'completed'
     AND v_tx.marketplace_item_id IN ('ruota_sfortunata', 'enigma_extra')
     AND v_tx.target_team_id IS NOT DISTINCT FROM v_team_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Questo malus si risolve solo completandolo (ruota o enigma).');
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used',
      data_utilizzo = now()
  WHERE id = p_transaction_id;

  -- Freeze: si azzera sulla squadra solo se e' davvero scaduto (con 15 secondi di tolleranza per l'orologio del telefono)
  IF v_tx.marketplace_item_id = 'freeze_2min' AND v_tx.target_team_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM public.marketplace_transactions
       WHERE target_team_id = v_tx.target_team_id
         AND marketplace_item_id = 'freeze_2min'
         AND stato = 'completed'
         AND id <> p_transaction_id
     ) THEN
    SELECT freeze_expires_at INTO v_freeze FROM public.teams WHERE id = v_tx.target_team_id;
    IF v_freeze IS NULL OR v_freeze <= now() + INTERVAL '15 seconds' OR COALESCE(v_is_admin, false) THEN
      UPDATE public.teams
      SET freeze_expires_at = NULL,
          freeze_started_at = NULL,
          freeze_duration_seconds = 0
      WHERE id = v_tx.target_team_id;
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'transaction_id', p_transaction_id, 'new_status', 'used');
END;
$function$;
