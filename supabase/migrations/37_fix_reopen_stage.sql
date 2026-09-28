-- 37_fix_reopen_stage.sql
-- Bug 1 (blocca sempre): reopen_stage accettava solo p_stage_id, ma il pulsante "Riapri Tappa" invia anche
-- p_admin_id -> "Could not find the function ... in the schema cache", il pulsante non ha mai funzionato.
-- Bug 2 (piu' grave, silenzioso): il testo del pulsante avvisa che riaprendo la tappa vengono REVOCATI i Token
-- e i Punti Cattiveria di fine tappa assegnati da close_stage, ma il codice si limitava a riaprire la tappa
-- senza toccare ne' i token ne' la cattiveria: se mai usato, avrebbe lasciato quei dati sbagliati per sempre
-- (e alla richiusura successiva non si sarebbero ricalcolati, perche' close_stage/add_cattiveria sono idempotenti
-- e vedono le vecchie righe come gia' presenti).
-- Ora la funzione fa davvero quello che promette: toglie ai team i Token guadagnati per l'arrivo in quella tappa,
-- cancella le relative transazioni "reward_stage" e le righe di Punti Cattiveria "end_of_stage" di quella tappa,
-- cosi' una richiusura successiva ricalcola tutto da capo con i dati giusti.

CREATE OR REPLACE FUNCTION public.reopen_stage(p_stage_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_tx RECORD;
  v_reverted_tokens INTEGER := 0;
  v_reverted_cattiveria INTEGER := 0;
BEGIN
  SELECT (public.has_role(auth.uid(), 'admin') OR auth.role() = 'service_role') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.stages WHERE id = p_stage_id) THEN
    RAISE EXCEPTION 'Tappa non trovata';
  END IF;

  -- Revoca i Token di fine tappa assegnati da close_stage/apply_completion_effects
  FOR v_tx IN
    SELECT id, team_id, costo_token
    FROM public.marketplace_transactions
    WHERE stage_id = p_stage_id
      AND (marketplace_item_id = 'reward_stage' OR (dettagli->>'stage_reward')::boolean = true)
  LOOP
    UPDATE public.teams
    SET token_balance = GREATEST(0, COALESCE(token_balance, 50) + v_tx.costo_token)
    WHERE id = v_tx.team_id;
    DELETE FROM public.marketplace_transactions WHERE id = v_tx.id;
    v_reverted_tokens := v_reverted_tokens + 1;
  END LOOP;

  -- Revoca i Punti Cattiveria di fine tappa ("Chi non è cattivo paga")
  DELETE FROM public.cattiveria_ledger WHERE stage_id = p_stage_id AND tipo = 'end_of_stage';
  GET DIAGNOSTICS v_reverted_cattiveria = ROW_COUNT;

  UPDATE public.stages SET stato = 'open' WHERE id = p_stage_id;

  RETURN jsonb_build_object(
    'success', true,
    'stage_id', p_stage_id,
    'reverted_token_rewards', v_reverted_tokens,
    'reverted_cattiveria_rows', v_reverted_cattiveria
  );
END;
$function$;
REVOKE ALL ON FUNCTION public.reopen_stage(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reopen_stage(uuid, uuid) TO authenticated;
DROP FUNCTION IF EXISTS public.reopen_stage(uuid);
