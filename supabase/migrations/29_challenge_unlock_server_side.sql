-- 29_challenge_unlock_server_side.sql
-- Una squadra puo' rispondere a una prova, incassare o perdere punti, o completarla SOLO se la prova e' sbloccata:
--   * la tappa precedente e' completata (le prove obbligatorie: il Jackpot e' facoltativo e non blocca), e
--   * tutte le prove precedenti della stessa tappa sono completate.
-- E' la stessa regola che l'app usa per mostrare i pulsanti; prima il database non la controllava e chi chiamava le funzioni
-- "a mano" poteva rispondere a un enigma della Tappa 4 avendo fatto solo la Tappa 1 (o giocare il Jackpot).
-- La Regia (admin) non e' vincolata. Le funzioni gia' patchate (rieseguendo la migrazione) vengono lasciate com'e'.

CREATE OR REPLACE FUNCTION public.assert_challenge_unlocked(p_challenge uuid)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id uuid;
  v_ch record;
  v_stage_number integer;
BEGIN
  IF public.has_role(auth.uid(), 'admin'::text) THEN
    RETURN;
  END IF;
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN; -- gli altri controlli delle funzioni gestiscono l'utente non associato a una squadra
  END IF;

  SELECT * INTO v_ch FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RETURN; -- prova inesistente: la gestisce la funzione chiamante
  END IF;

  -- 1) tappa precedente completata
  SELECT numero_tappa INTO v_stage_number FROM public.stages WHERE id = v_ch.stage_id;
  IF COALESCE(v_stage_number, 1) > 1 AND EXISTS (
    SELECT 1
    FROM public.challenges c
    JOIN public.stages s ON s.id = c.stage_id
    WHERE s.numero_tappa = v_stage_number - 1
      AND c.tipo_sfida <> 'jackpot'
      AND NOT EXISTS (
        SELECT 1 FROM public.team_progress tp
        WHERE tp.team_id = v_team_id AND tp.challenge_id = c.id AND tp.stato = 'completed'
      )
  ) THEN
    RAISE EXCEPTION 'Questa prova non è ancora sbloccata: completa prima la tappa precedente.';
  END IF;

  -- 2) prove precedenti della stessa tappa completate (il Jackpot non blocca nessuno)
  IF EXISTS (
    SELECT 1
    FROM public.challenges c
    WHERE c.stage_id = v_ch.stage_id
      AND c.ordine_sfida < v_ch.ordine_sfida
      AND c.tipo_sfida <> 'jackpot'
      AND NOT EXISTS (
        SELECT 1 FROM public.team_progress tp
        WHERE tp.team_id = v_team_id AND tp.challenge_id = c.id AND tp.stato = 'completed'
      )
  ) THEN
    RAISE EXCEPTION 'Questa prova non è ancora sbloccata: completa prima le prove precedenti.';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION public.assert_challenge_unlocked(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_challenge_unlocked(uuid) TO authenticated;

DO $patch$
DECLARE
  def text;
  newdef text;
  v_sig regprocedure;
  v_anchor text;
  v_insert text;
  v_item record;
BEGIN
  FOR v_item IN
    SELECT * FROM (VALUES
      ('public.submit_quiz_answer(uuid,integer)',
       E'  PERFORM pg_advisory_xact_lock(hashtext(''quiz:'' || v_team_id::text',
       E'  PERFORM public.assert_challenge_unlocked(v_question.challenge_id);\n'),
      ('public.submit_bank_answer(integer,text)',
       E'  PERFORM public.assert_race_not_paused();\n',
       E'  PERFORM public.assert_challenge_unlocked(''b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6''::uuid);\n'),
      ('public.submit_emoji_movie_answer(integer,text)',
       E'  PERFORM public.assert_race_not_paused();\n',
       E'  PERFORM public.assert_challenge_unlocked(''777f4e1f-7443-42e7-9d7a-115f2122888f''::uuid);\n'),
      ('public.submit_enigma_answer(uuid,jsonb)',
       E'  PERFORM public.assert_gate_open(p_challenge_id);\n',
       E'  PERFORM public.assert_challenge_unlocked(p_challenge_id);\n'),
      ('public.submit_secret_code_pin(text)',
       E'  PERFORM public.assert_gate_open(''d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8''::uuid);\n',
       E'  PERFORM public.assert_challenge_unlocked(''d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8''::uuid);\n'),
      ('public.submit_social_challenge(text,text)',
       E'  PERFORM public.assert_gate_open(''c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7''::uuid);\n',
       E'  PERFORM public.assert_challenge_unlocked(''c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7''::uuid);\n'),
      ('public.complete_challenge(uuid)',
       E'  PERFORM public.assert_gate_open(p_challenge);\n',
       E'  PERFORM public.assert_challenge_unlocked(p_challenge);\n'),
      ('public.play_jackpot(uuid,integer)',
       E'  PERFORM public.assert_gate_open(''f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0''::uuid);\n',
       E'  PERFORM public.assert_challenge_unlocked(''f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0''::uuid);\n')
    ) AS t(sig, anchor, ins)
  LOOP
    v_sig := v_item.sig::regprocedure;
    def := pg_get_functiondef(v_sig);
    IF position('assert_challenge_unlocked' IN def) > 0 THEN
      CONTINUE; -- gia' patchata
    END IF;
    v_anchor := v_item.anchor;
    v_insert := v_item.ins;
    IF position(v_anchor IN def) = 0 THEN
      RAISE EXCEPTION '% : punto di inserimento non trovato', v_item.sig;
    END IF;
    IF v_anchor LIKE '%hashtext(''quiz:''%' THEN
      -- il controllo va PRIMA del lock (la riga di ancoraggio resta dopo)
      newdef := replace(def, v_anchor, v_insert || v_anchor);
    ELSE
      -- il controllo va DOPO la riga di ancoraggio (che termina con \n)
      newdef := replace(def, v_anchor, v_anchor || v_insert);
    END IF;
    IF newdef = def THEN
      RAISE EXCEPTION '% : modifica non applicata', v_item.sig;
    END IF;
    EXECUTE newdef;
  END LOOP;
END
$patch$;
