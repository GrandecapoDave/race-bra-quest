-- 33_marketplace_after_stage1.sql
-- Le squadre possono comprare al Marketplace SOLO dopo aver completato la Tappa 1 (tutte le sue prove).
-- L'app gia' nasconde la voce e blocca la pagina; ora lo impone anche il database, cosi' chi chiama buy_marketplace_item
-- "a mano" non puo' aggirarlo. Il pulsante generale della Regia (Marketplace aperto/chiuso) resta il comando principale.
-- Ripetibile: se gia' applicata non fa nulla.

DO $patch$
DECLARE
  def text;
  newdef text;
  v_anchor text := E'  -- 5. CONTROLLO BLACKOUT MERCATO\n';
  v_check text := $chk$
  -- 4b. MARKETPLACE SBLOCCATO SOLO DOPO LA TAPPA 1 (tutte le prove della Tappa 1 completate)
  IF EXISTS (
    SELECT 1
    FROM public.challenges c
    JOIN public.stages s ON s.id = c.stage_id
    WHERE s.numero_tappa = 1
      AND c.tipo_sfida <> 'jackpot'
      AND NOT EXISTS (
        SELECT 1 FROM public.team_progress tp
        WHERE tp.team_id = v_team_id AND tp.challenge_id = c.id AND tp.stato = 'completed'
      )
  ) THEN
    RAISE EXCEPTION 'Il Marketplace si sblocca dopo aver completato la Tappa 1.';
  END IF;

$chk$;
BEGIN
  def := pg_get_functiondef('public.buy_marketplace_item(text,uuid,uuid)'::regprocedure);
  IF position('MARKETPLACE SBLOCCATO SOLO DOPO LA TAPPA 1' IN def) > 0 THEN
    RETURN; -- gia' applicata
  END IF;
  IF position(v_anchor IN def) = 0 THEN
    RAISE EXCEPTION 'buy_marketplace_item: punto di inserimento non trovato';
  END IF;
  newdef := replace(def, v_anchor, v_check || v_anchor);
  IF newdef = def THEN
    RAISE EXCEPTION 'buy_marketplace_item: modifica non applicata';
  END IF;
  EXECUTE newdef;
END
$patch$;
