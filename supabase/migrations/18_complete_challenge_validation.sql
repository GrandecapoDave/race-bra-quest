-- 18_complete_challenge_validation.sql
-- complete_challenge si fidava del client: bastava chiamarla per incassare i punti di qualsiasi prova.
-- Ora verifica sul server che la prova sia stata svolta davvero (challenge_requirements_met):
--   team_setup      -> configurazione avviata (start_challenge)
--   quiz            -> risposto a tutte le domande della prova
--   photo/living_poster -> foto inviata per quella prova
--   emoji_movies    -> tutti gli 8 film risolti (giusti o 3 tentativi esauriti)
--   social          -> invio delle foto registrato
--   tutte le altre (banca, codice, enigmi, boxe, cornhole, jackpot) si completano da sole tramite le loro RPC:
--   complete_challenge resta idempotente (already=true) ma non puo' piu' assegnare punti per conto proprio.

CREATE OR REPLACE FUNCTION public.challenge_requirements_met(p_team_id uuid, p_challenge_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $fn$
DECLARE
  v_type text;
  v_total integer;
  v_done integer;
BEGIN
  SELECT tipo_sfida INTO v_type FROM public.challenges WHERE id = p_challenge_id;
  IF v_type IS NULL THEN RETURN false; END IF;

  IF v_type = 'team_setup' THEN
    -- i componenti restano salvati sul dispositivo (team_members non e' scrivibile dalle squadre):
    -- l'unica prova server e' che la squadra abbia avviato la configurazione (start_challenge)
    RETURN EXISTS (SELECT 1 FROM public.team_progress WHERE team_id = p_team_id AND challenge_id = p_challenge_id);

  ELSIF v_type = 'quiz' THEN
    SELECT COUNT(*) INTO v_total FROM public.quiz_questions WHERE challenge_id = p_challenge_id;
    SELECT COUNT(DISTINCT ta.question_id) INTO v_done
    FROM public.team_answers ta
    JOIN public.quiz_questions qq ON qq.id = ta.question_id
    WHERE ta.team_id = p_team_id AND qq.challenge_id = p_challenge_id;
    RETURN v_total > 0 AND v_done >= v_total;

  ELSIF v_type IN ('photo', 'living_poster') THEN
    RETURN EXISTS (SELECT 1 FROM public.submissions WHERE team_id = p_team_id AND challenge_id = p_challenge_id AND COALESCE(url, '') <> '');

  ELSIF v_type = 'emoji_movies' THEN
    SELECT COUNT(*) INTO v_done
    FROM public.team_emoji_movies
    WHERE team_id = p_team_id AND (is_correct OR attempts >= 3);
    RETURN v_done >= 8;

  ELSIF v_type = 'social' THEN
    RETURN EXISTS (SELECT 1 FROM public.team_social_submissions WHERE team_id = p_team_id AND challenge_id = p_challenge_id);
  END IF;

  RETURN false;
END;
$fn$;
REVOKE ALL ON FUNCTION public.challenge_requirements_met(uuid, uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.complete_challenge(p_challenge uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_team_name TEXT;
  v_challenge RECORD;
  v_already BOOLEAN := false;
  v_bonus INTEGER := 0;
  v_base_points INTEGER := 0;
  v_completed_challenges_count INTEGER := 0;
  v_total_challenges_count INTEGER := 0;
  v_stage_completed BOOLEAN := false;
  v_stage_reward INTEGER := 0;
  v_stage_arrival_pos INTEGER := 1;
  v_stage_number INTEGER := 1;
  v_active_2x RECORD;
  v_multiplier_2x_bonus INTEGER := 0;
  v_active_stage_dimezza RECORD;
  v_full_stage_score INTEGER := 0;
  v_stage_dimezza_penalty INTEGER := 0;
  v_active_polizza RECORD;
  v_polizza_refund INTEGER := 0;
  v_new_bal INTEGER := 0;
  v_stage_name TEXT;
BEGIN
  -- CONTROLLO GARA TERMINATA
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile completare sfide.';
  END IF;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT team_id INTO v_team_id
  FROM public.user_roles
  WHERE user_id = v_user_id;

  IF v_team_id IS NULL THEN
    SELECT id INTO v_team_id
    FROM public.teams
    WHERE owner_id = v_user_id;
  END IF;

  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Nessuna squadra associata all''utente';
  END IF;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_team_id;
  SELECT * INTO v_challenge FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sfida non trovata';
  END IF;

  SELECT numero_tappa INTO v_stage_number FROM public.stages WHERE id = v_challenge.stage_id;

  -- 1. VERIFICA IDEMPOTENZA (DOPPIO CLICK / COMPLETAMENTO DUPLICATO)
  IF EXISTS (
    SELECT 1 FROM public.team_progress
    WHERE team_id = v_team_id AND challenge_id = p_challenge AND stato = 'completed'
  ) THEN
    v_already := true;
    RETURN jsonb_build_object(
      'already', true,
      'points', 0,
      'base_points', 0,
      'stage_completed', false,
      'stage_reward', 0
    );
  END IF;

  -- 1b. VALIDAZIONE LATO SERVER: la prova deve essere stata realmente svolta
  IF NOT public.challenge_requirements_met(v_team_id, p_challenge) THEN
    RAISE EXCEPTION 'La prova non risulta ancora svolta: completa tutti i passaggi richiesti.';
  END IF;

  -- 2. REGISTRA COMPLETAMENTO PROVA
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_team_id, p_challenge, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  v_base_points := COALESCE(v_challenge.punteggio_massimo, 0);

  -- 3. CONTROLLO MOLTIPLICATORE 2X ATTIVO
  SELECT * INTO v_active_2x
  FROM public.marketplace_transactions
  WHERE team_id = v_team_id
    AND marketplace_item_id = 'moltiplicatore_2x'
    AND stato = 'completed'
  ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

  IF FOUND AND v_base_points > 0 THEN
    v_multiplier_2x_bonus := v_base_points;
    
    INSERT INTO public.scores (team_id, stage_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (
      v_team_id,
      v_challenge.stage_id,
      p_challenge,
      v_multiplier_2x_bonus,
      'bonus_moltiplicatore_2x',
      'Moltiplicatore 2X applicato alla prova ' || v_challenge.titolo || ' (+' || v_multiplier_2x_bonus::text || ' PT)'
    );

    UPDATE public.marketplace_transactions
    SET stato = 'used',
        data_utilizzo = now(),
        dettagli = jsonb_build_object(
          'applied_challenge_id', p_challenge,
          'challenge_title', v_challenge.titolo,
          'bonus_points_awarded', v_multiplier_2x_bonus
        )
    WHERE id = v_active_2x.id;
  END IF;

  -- 4. INSERISCI PUNTEGGIO BASE DELLA PROVA
  INSERT INTO public.scores (team_id, stage_id, challenge_id, punti, motivo)
  VALUES (
    v_team_id,
    v_challenge.stage_id,
    p_challenge,
    v_base_points,
    'Completamento prova: ' || v_challenge.titolo
  );

  -- 5. VERIFICA COMPLETAMENTO DELLA TAPPA
  SELECT COUNT(*) INTO v_total_challenges_count
  FROM public.challenges
  WHERE stage_id = v_challenge.stage_id AND tipo_sfida <> 'jackpot';

  SELECT COUNT(DISTINCT challenge_id) INTO v_completed_challenges_count
  FROM public.team_progress
  WHERE team_id = v_team_id
    AND challenge_id IN (SELECT id FROM public.challenges WHERE stage_id = v_challenge.stage_id AND tipo_sfida <> 'jackpot')
    AND stato = 'completed';

  IF v_completed_challenges_count = v_total_challenges_count THEN
    v_stage_completed := true;
    -- Serializza il calcolo della posizione di arrivo per tappa (evita posizioni duplicate)
    PERFORM pg_advisory_xact_lock(hashtext('stage_arrival:' || v_challenge.stage_id::text));

    -- Applicazione eventuale Malus DIMEZZA PUNTI TAPPA registrato per questa tappa
    SELECT * INTO v_active_stage_dimezza
    FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id
      AND marketplace_item_id = 'dimezza_punti'
      AND stage_id = v_challenge.stage_id
      AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      SELECT COALESCE(SUM(punti), 0)::integer INTO v_full_stage_score
      FROM public.scores
      WHERE team_id = v_team_id
        AND stage_id = v_challenge.stage_id
        AND (tipo_modificatore IS NULL OR tipo_modificatore != 'penalty_dimezza_tappa');

      IF v_full_stage_score > 0 THEN
        v_stage_dimezza_penalty := FLOOR(v_full_stage_score / 2.0)::integer;
        
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (
          v_team_id,
          v_challenge.stage_id,
          -v_stage_dimezza_penalty,
          'penalty_dimezza_tappa',
          'Malus Dimezza Punti Tappa ' || v_stage_number::text || ': penalità −' || v_stage_dimezza_penalty::text || ' PT (50% del punteggio complessivo della tappa)'
        );

        -- Controllo Polizza Diretta
        SELECT * INTO v_active_polizza
        FROM public.marketplace_transactions
        WHERE team_id = v_team_id
          AND marketplace_item_id = 'polizza_diretta'
          AND stato = 'completed'
        ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

        IF FOUND AND v_stage_dimezza_penalty > 0 THEN
          v_polizza_refund := CEIL(v_stage_dimezza_penalty / 2.0)::integer;
          IF v_polizza_refund > 0 THEN
            INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
            VALUES (
              v_team_id,
              v_challenge.stage_id,
              v_polizza_refund,
              'bonus_polizza',
              'Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+' || v_polizza_refund::text || ' PT)'
            );

            UPDATE public.marketplace_transactions
            SET stato = 'used',
                data_utilizzo = now(),
                dettagli = jsonb_build_object('refunded_points', v_polizza_refund, 'source_malus', 'dimezza_punti', 'target_stage_id', v_challenge.stage_id)
            WHERE id = v_active_polizza.id;
          END IF;
        END IF;
      ELSE
        v_stage_dimezza_penalty := 0;
      END IF;

      UPDATE public.marketplace_transactions
      SET stato = 'used',
          data_utilizzo = now(),
          dettagli = (COALESCE(dettagli, '{}'::jsonb) || jsonb_build_object(
            'stage_score_before', v_full_stage_score,
            'penalty_applied', v_stage_dimezza_penalty,
            'stage_score_after', v_full_stage_score - v_stage_dimezza_penalty,
            'applied_at_stage_completion', true
          ))
      WHERE id = v_active_stage_dimezza.id;
    END IF;

    -- CALCOLO ORDINE DI ARRIVO DINAMICO PER LA TAPPA (SCALA 12 SQUADRE)
    SELECT COUNT(*) + 1 INTO v_stage_arrival_pos
    FROM public.marketplace_transactions
    WHERE marketplace_item_id = 'reward_stage'
      AND stage_id = v_challenge.stage_id;

    IF v_stage_arrival_pos = 1 THEN v_stage_reward := 25;
    ELSIF v_stage_arrival_pos = 2 THEN v_stage_reward := 20;
    ELSIF v_stage_arrival_pos = 3 THEN v_stage_reward := 16;
    ELSIF v_stage_arrival_pos = 4 THEN v_stage_reward := 13;
    ELSIF v_stage_arrival_pos = 5 THEN v_stage_reward := 10;
    ELSIF v_stage_arrival_pos = 6 THEN v_stage_reward := 8;
    ELSIF v_stage_arrival_pos = 7 THEN v_stage_reward := 6;
    ELSIF v_stage_arrival_pos = 8 THEN v_stage_reward := 5;
    ELSIF v_stage_arrival_pos = 9 THEN v_stage_reward := 4;
    ELSIF v_stage_arrival_pos = 10 THEN v_stage_reward := 3;
    ELSIF v_stage_arrival_pos = 11 THEN v_stage_reward := 2;
    ELSE v_stage_reward := 1;
    END IF;

    -- Accredita i Token ricompensa alla squadra
    UPDATE public.teams
    SET token_balance = token_balance + v_stage_reward
    WHERE id = v_team_id
    RETURNING token_balance INTO v_new_bal;

    SELECT titolo INTO v_stage_name FROM public.stages WHERE id = v_challenge.stage_id;

    INSERT INTO public.marketplace_transactions (team_id, stage_id, marketplace_item_id, costo_token, stato, dettagli)
    VALUES (
      v_team_id, v_challenge.stage_id, 'reward_stage', -v_stage_reward, 'completed',
      jsonb_build_object(
        'stage_id', v_challenge.stage_id,
        'stage_index', v_stage_number,
        'position', v_stage_arrival_pos,
        'reward_tokens', v_stage_reward,
        'stage_name', v_stage_name,
        'old_balance', v_new_bal - v_stage_reward,
        'new_balance', v_new_bal
      )
    );

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES (
      'stage_reward_credited', v_team_id,
      jsonb_build_object(
        'message', 'La squadra ' || COALESCE(v_team_name, 'Squadra') || ' ha concluso la Tappa ' || v_stage_number || ' in ' || v_stage_arrival_pos || 'ª posizione e ha ricevuto +' || v_stage_reward || ' Token! 🪙',
        'stage_id', v_challenge.stage_id,
        'position', v_stage_arrival_pos,
        'tokens_added', v_stage_reward
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'already', v_already,
    'points', v_base_points + v_multiplier_2x_bonus - v_stage_dimezza_penalty + v_polizza_refund,
    'base_points', v_base_points,
    'multiplier_2x_bonus', v_multiplier_2x_bonus,
    'stage_dimezza_penalty', v_stage_dimezza_penalty,
    'polizza_refund', v_polizza_refund,
    'bonus', v_bonus,
    'stage_completed', v_stage_completed,
    'stage_reward', v_stage_reward,
    'position', v_stage_arrival_pos
  );
END;
$function$
;
