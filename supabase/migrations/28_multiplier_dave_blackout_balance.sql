-- 28_multiplier_dave_blackout_balance.sql
-- 1) DOPPIO 2X SU UNA PROVA SCELTA: al momento dell'acquisto la squadra sceglie una prova ancora da fare (il Jackpot e' escluso).
--    Tutti i punti POSITIVI che quella prova assegna alla squadra vengono raddoppiati: quelli gia' ottenuti (accreditati subito)
--    e quelli futuri (risposte, completamento, voti della Regia arrivati dopo). Le penalita' non si raddoppiano.
--    L'id della prova viaggia nel parametro p_target_stage_id di buy_marketplace_item.
-- 2) AIUTO DAVE: l'esito "Aiuto Dave" della Ruota della Fortuna genera una parola d'ordine diversa per ogni squadra, salvata
--    nella transazione (la Regia la vede nella pagina Passaparola per riconoscere chi chiama).
-- 3) BLACKOUT: non si somma. Mentre una squadra e' sotto Blackout (6 minuti) e per i 3 minuti successivi (respiro) non puo' essere
--    colpita di nuovo; get_blackout_protection() dice alle squadre chi e' protetto e fino a quando.
-- 4) BILANCIAMENTO PUNTEGGIO FINALE: bonus tempo continuo 0-50 (prima 0-60) e bonus token 1 punto ogni 10 token, massimo +10 (prima 1 ogni 5, senza tetto).

-- ---------------------------------------------------------------------------------------------
-- 1) Doppio 2X: trigger sui punteggi
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tg_scores_multiplier_2x()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_tx_id uuid;
  v_title text;
BEGIN
  IF NEW.challenge_id IS NULL OR NEW.punti <= 0 THEN
    RETURN NEW;
  END IF;
  IF COALESCE(NEW.tipo_modificatore, '') IN ('bonus_moltiplicatore_2x', 'bonus_polizza') THEN
    RETURN NEW;
  END IF;

  SELECT id INTO v_tx_id
  FROM public.marketplace_transactions
  WHERE team_id = NEW.team_id
    AND marketplace_item_id = 'moltiplicatore_2x'
    AND stato IN ('completed', 'used')
    AND dettagli->>'target_challenge_id' = NEW.challenge_id::text
  LIMIT 1;

  IF v_tx_id IS NOT NULL THEN
    SELECT titolo INTO v_title FROM public.challenges WHERE id = NEW.challenge_id;
    INSERT INTO public.scores (team_id, stage_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (NEW.team_id, NEW.stage_id, NEW.challenge_id, NEW.punti, 'bonus_moltiplicatore_2x',
            'Moltiplicatore 2X su ' || COALESCE(v_title, 'prova') || ' (+' || NEW.punti::text || ' PT)');
    UPDATE public.marketplace_transactions
    SET dettagli = dettagli || jsonb_build_object(
      'bonus_points_awarded', COALESCE((dettagli->>'bonus_points_awarded')::integer, 0) + NEW.punti)
    WHERE id = v_tx_id;
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION public.tg_scores_multiplier_2x() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_scores_multiplier_2x ON public.scores;
CREATE TRIGGER trg_scores_multiplier_2x
  AFTER INSERT ON public.scores
  FOR EACH ROW EXECUTE FUNCTION public.tg_scores_multiplier_2x();

-- quando la prova e' completata il 2X risulta usato (i punti che arrivano dopo, es. voti della Regia, vengono comunque raddoppiati)
CREATE OR REPLACE FUNCTION public.tg_progress_close_2x()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NEW.stato = 'completed' THEN
    UPDATE public.marketplace_transactions
    SET stato = 'used', data_utilizzo = now()
    WHERE team_id = NEW.team_id
      AND marketplace_item_id = 'moltiplicatore_2x'
      AND stato = 'completed'
      AND dettagli->>'target_challenge_id' = NEW.challenge_id::text;
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION public.tg_progress_close_2x() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_progress_close_2x ON public.team_progress;
CREATE TRIGGER trg_progress_close_2x
  AFTER INSERT OR UPDATE OF stato ON public.team_progress
  FOR EACH ROW EXECUTE FUNCTION public.tg_progress_close_2x();

-- ---------------------------------------------------------------------------------------------
-- Funzioni esistenti modificate
-- ---------------------------------------------------------------------------------------------
DO $patch$
DECLARE
  def text;
  newdef text;
BEGIN
  -- Vecchio raddoppio "alla prossima prova completata": disattivato (ora vale solo la prova scelta, con il trigger qui sopra)
  def := pg_get_functiondef('public.complete_challenge(uuid)'::regprocedure);
  IF position($a$marketplace_item_id = 'moltiplicatore_2x'$a$ IN def) > 0 THEN
    newdef := replace(def, $a$marketplace_item_id = 'moltiplicatore_2x'$a$, $b$marketplace_item_id = 'moltiplicatore_2x_disattivato'$b$);
    EXECUTE newdef;
  END IF;
  def := pg_get_functiondef('public.apply_completion_effects(uuid,uuid)'::regprocedure);
  IF position($a$marketplace_item_id = 'moltiplicatore_2x'$a$ IN def) > 0 THEN
    newdef := replace(def, $a$marketplace_item_id = 'moltiplicatore_2x'$a$, $b$marketplace_item_id = 'moltiplicatore_2x_disattivato'$b$);
    EXECUTE newdef;
  END IF;

  -- buy_marketplace_item
  def := pg_get_functiondef('public.buy_marketplace_item(text,uuid,uuid)'::regprocedure);
  newdef := def;

  IF position('v_2x_catchup' IN newdef) = 0 THEN
    newdef := replace(newdef,
      $a$DECLARE
  v_user_id UUID;$a$,
      $b$DECLARE
  v_2x_id UUID;
  v_2x_title TEXT;
  v_2x_type TEXT;
  v_2x_catchup INTEGER := 0;
  v_dave_word TEXT;
  v_user_id UUID;$b$);

    -- 1) Doppio 2X sulla prova scelta
    newdef := replace(newdef,
      $a$  ELSIF p_item_id = 'moltiplicatore_2x' THEN
    v_dettagli := jsonb_build_object('multiplier', 2, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;
$a$,
      $b$  ELSIF p_item_id = 'moltiplicatore_2x' THEN
    -- p_target_stage_id porta l'id della PROVA da raddoppiare
    IF p_target_stage_id IS NULL THEN
      RAISE EXCEPTION 'Seleziona la prova da raddoppiare.';
    END IF;
    SELECT c.id, c.titolo, c.tipo_sfida INTO v_2x_id, v_2x_title, v_2x_type
    FROM public.challenges c WHERE c.id = p_target_stage_id;
    IF v_2x_id IS NULL THEN
      RAISE EXCEPTION 'Prova non valida.';
    END IF;
    IF v_2x_type = 'jackpot' THEN
      RAISE EXCEPTION 'Il Jackpot è facoltativo e non può essere raddoppiato: scegli un''altra prova.';
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.team_progress
      WHERE team_id = v_team_id AND challenge_id = v_2x_id AND stato = 'completed'
    ) THEN
      RAISE EXCEPTION 'Hai già completato questa prova: scegli una prova ancora da fare.';
    END IF;

    SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_2x_catchup
    FROM public.scores
    WHERE team_id = v_team_id AND challenge_id = v_2x_id AND punti > 0
      AND COALESCE(tipo_modificatore, '') NOT IN ('bonus_moltiplicatore_2x', 'bonus_polizza');

    v_dettagli := jsonb_build_object(
      'multiplier', 2, 'assigned_at', now(),
      'target_challenge_id', v_2x_id, 'challenge_title', v_2x_title,
      'bonus_points_awarded', v_2x_catchup);
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

    IF v_2x_catchup > 0 THEN
      INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_2x_id, v_2x_catchup, 'bonus_moltiplicatore_2x',
              'Moltiplicatore 2X su ' || v_2x_title || ': punti già ottenuti (+' || v_2x_catchup::text || ' PT)');
    END IF;
$b$);

    -- 2) Aiuto Dave: parola d'ordine diversa per ogni squadra
    newdef := replace(newdef,
      $a$      'roll', v_roll
    );
$a$,
      $b$      'roll', v_roll
    );
    IF v_outcome_id = 'dave_help' THEN
      SELECT w INTO v_dave_word
      FROM unnest(ARRAY['TARTUFO','NEBBIOLO','GRISSINO','BAROLO','FASSONA','AGNOLOTTO','BAGNACAUDA','NOCCIOLA','GIANDUIA','ROBIOLA',
                        'TORRONE','ARNEIS','DOLCETTO','CARDO','PORCINO','LANGHE','ROERO','MONVISO','BRICCO','VENDEMMIA',
                        'CASTAGNA','ZABAIONE','BRACHETTO','FONTINA']) AS w
      WHERE NOT EXISTS (
        SELECT 1 FROM public.marketplace_transactions x
        WHERE x.marketplace_item_id = 'ruota_fortuna' AND x.dettagli->>'dave_code' = w)
      ORDER BY random() LIMIT 1;
      v_dave_word := COALESCE(v_dave_word, 'PECHINO' || (floor(random() * 90) + 10)::integer::text);
      v_dettagli := v_dettagli || jsonb_build_object('dave_code', v_dave_word);
    END IF;
$b$);

    -- 3) Blackout: nessuna somma + respiro di 3 minuti dopo la fine
    newdef := replace(newdef,
      $a$    SELECT nome_squadra INTO v_target_team_name FROM public.teams WHERE id = p_target_team_id;
$a$,
      $b$    SELECT nome_squadra INTO v_target_team_name FROM public.teams WHERE id = p_target_team_id;

    IF p_item_id = 'blackout_mercato' AND EXISTS (
      SELECT 1 FROM public.marketplace_transactions
      WHERE target_team_id = p_target_team_id
        AND marketplace_item_id = 'blackout_mercato'
        AND stato IN ('completed', 'used')
        AND (data_acquisto + INTERVAL '9 minutes') > now()
    ) THEN
      RAISE EXCEPTION '% è già sotto Blackout o nel periodo di respiro di 3 minuti dopo il blocco: potrà essere colpita di nuovo tra poco.', v_target_team_name;
    END IF;
$b$);

    IF position('v_2x_catchup' IN newdef) = 0 OR position('dave_code' IN newdef) = 0 OR position('respiro di 3 minuti' IN newdef) = 0 THEN
      RAISE EXCEPTION 'buy_marketplace_item: una modifica non e'' stata applicata';
    END IF;
    EXECUTE newdef;
  END IF;

  -- 4) Bilanciamento del punteggio finale
  def := pg_get_functiondef('public.calculate_final_game_results(uuid)'::regprocedure);
  IF position('ROUND(60.0 *' IN def) > 0 THEN
    newdef := replace(def, 'ROUND(60.0 *', 'ROUND(50.0 *');
    newdef := replace(newdef, E'             60)::INTEGER', E'             50)::INTEGER');
    newdef := replace(newdef, 'FLOOR(r.token_balance / 5)::INTEGER AS token_efficiency_bonus', 'LEAST(10, FLOOR(r.token_balance / 10.0))::INTEGER AS token_efficiency_bonus');
    IF position('ROUND(50.0 *' IN newdef) = 0 OR position('LEAST(10, FLOOR(r.token_balance / 10.0))' IN newdef) = 0 THEN
      RAISE EXCEPTION 'calcolo finale: bilanciamento non applicato';
    END IF;
    EXECUTE newdef;
  END IF;
END
$patch$;

-- ---------------------------------------------------------------------------------------------
-- 3) Blackout: chi e' protetto e fino a quando (per l'elenco dei bersagli)
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_blackout_protection()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'team_id', s.target_team_id,
      'blocked_until', s.last_at + INTERVAL '6 minutes',
      'protected_until', s.last_at + INTERVAL '9 minutes')), '[]'::jsonb)
  FROM (
    SELECT target_team_id, MAX(data_acquisto) AS last_at
    FROM public.marketplace_transactions
    WHERE marketplace_item_id = 'blackout_mercato'
      AND stato IN ('completed', 'used')
      AND target_team_id IS NOT NULL
      AND data_acquisto + INTERVAL '9 minutes' > now()
    GROUP BY target_team_id
  ) s;
$function$;
REVOKE ALL ON FUNCTION public.get_blackout_protection() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_blackout_protection() TO authenticated;

-- descrizioni degli oggetti
UPDATE public.marketplace_items
SET descrizione = 'Blocca il Marketplace della squadra bersaglio per 6 minuti. Non si somma: dopo il blocco la squadra è protetta per altri 3 minuti.'
WHERE id = 'blackout_mercato';
UPDATE public.marketplace_items
SET nome = 'MOLTIPLICATORE 2X SU UNA PROVA',
    effetto = 'Raddoppia x2 i punti di una prova a tua scelta',
    descrizione = 'Scegli una prova ancora da fare: tutti i punti che assegna alla tua squadra vengono raddoppiati (x2).'
WHERE id = 'moltiplicatore_2x';
