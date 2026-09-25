-- 27_marketplace_fixes.sql
--  * Passaparola: la richiesta vuota o troppo corta veniva accettata (e consumava il bonus): ora serve una domanda di almeno 3 caratteri (massimo 300).
--  * Bonus Classifica: la squadra deve vedere l'ISTANTANEA della classifica (fotografata all'apertura), non i dati in tempo reale:
--    prima get_secure_leaderboard restituiva la classifica completa live finche' la transazione non veniva "chiusa" dal telefono.

DO $patch$
DECLARE
  def text;
  newdef text;
BEGIN
  -- Passaparola
  def := pg_get_functiondef('public.submit_passaparola_request(uuid,text)'::regprocedure);
  IF position('minimo 3 caratteri' IN def) = 0 THEN
    newdef := replace(def,
      E'  -- Aggiorna stato a pending e salva testo della richiesta\n',
      E'  p_request_text := left(trim(COALESCE(p_request_text, '''')), 300);\n  IF length(p_request_text) < 3 THEN\n    RETURN jsonb_build_object(''success'', false, ''error'', ''Scrivi la domanda per la Regia (minimo 3 caratteri).'');\n  END IF;\n\n  -- Aggiorna stato a pending e salva testo della richiesta\n');
    IF newdef = def THEN RAISE EXCEPTION 'passaparola: punto di inserimento non trovato'; END IF;
    EXECUTE newdef;
  END IF;

  -- Classifica: solo Regia o report pubblicato vedono tutte le squadre (il Bonus Classifica passa dall'istantanea)
  def := pg_get_functiondef('public.get_secure_leaderboard()'::regprocedure);
  IF position('INTO v_has_bonus' IN def) > 0 THEN
    newdef := regexp_replace(def, E'(?s)\n  ELSIF v_caller_team_id IS NOT NULL THEN.*?INTO v_has_bonus;\n', E'\n');
    IF newdef = def OR position('INTO v_has_bonus' IN newdef) > 0 THEN RAISE EXCEPTION 'classifica: blocco bonus non rimosso'; END IF;
    EXECUTE newdef;
  END IF;
END
$patch$;
