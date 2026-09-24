-- Rollback delle migrazioni 12-13: funzioni di Production come erano dopo la 11 (2026-09-24).
-- Poi: DROP delle funzioni nuove e ripristino del vincolo tipo della cattiveria.

CREATE OR REPLACE FUNCTION public.apply_completion_effects(p_team_id uuid, p_challenge_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge RECORD;
  v_team_name TEXT;
  v_stage_number INTEGER;
  v_base INTEGER := 0;
  v_active_2x RECORD;
  v_2x_bonus INTEGER := 0;
  v_total INTEGER := 0;
  v_done INTEGER := 0;
  v_dimezza RECORD;
  v_full_score INTEGER := 0;
  v_penalty INTEGER := 0;
  v_polizza RECORD;
  v_refund INTEGER := 0;
  v_pos INTEGER := 0;
  v_reward INTEGER := 0;
  v_stage_completed BOOLEAN := false;
BEGIN
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RETURN jsonb_build_object('skipped', 'race_completed');
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = p_challenge_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('skipped', 'challenge_not_found');
  END IF;

  SELECT numero_tappa INTO v_stage_number FROM public.stages WHERE id = v_challenge.stage_id;
  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = p_team_id;

  PERFORM pg_advisory_xact_lock(hashtext('stage_arrival:' || v_challenge.stage_id::text));

  -- 1. Moltiplicatore 2X: raddoppia i punti positivi ottenuti nella prova (una sola volta)
  SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_base
  FROM public.scores
  WHERE team_id = p_team_id
    AND challenge_id = p_challenge_id
    AND punti > 0
    AND COALESCE(tipo_modificatore, '') NOT IN ('bonus_moltiplicatore_2x', 'bonus_polizza');

  IF v_base > 0 AND NOT EXISTS (
    SELECT 1 FROM public.scores
    WHERE team_id = p_team_id AND challenge_id = p_challenge_id AND tipo_modificatore = 'bonus_moltiplicatore_2x'
  ) THEN
    SELECT * INTO v_active_2x
    FROM public.marketplace_transactions
    WHERE team_id = p_team_id
      AND marketplace_item_id = 'moltiplicatore_2x'
      AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      v_2x_bonus := v_base;
      INSERT INTO public.scores (team_id, stage_id, challenge_id, punti, tipo_modificatore, motivo)
      VALUES (
        p_team_id, v_challenge.stage_id, p_challenge_id, v_2x_bonus, 'bonus_moltiplicatore_2x',
        'Moltiplicatore 2X applicato alla prova ' || v_challenge.titolo || ' (+' || v_2x_bonus::text || ' PT)'
      );
      UPDATE public.marketplace_transactions
      SET stato = 'used',
          data_utilizzo = now(),
          dettagli = jsonb_build_object(
            'applied_challenge_id', p_challenge_id,
            'challenge_title', v_challenge.titolo,
            'bonus_points_awarded', v_2x_bonus
          )
      WHERE id = v_active_2x.id;
    END IF;
  END IF;

  -- 2. Tappa completata? (prove obbligatorie: il Jackpot e' facoltativo)
  SELECT COUNT(*) INTO v_total
  FROM public.challenges
  WHERE stage_id = v_challenge.stage_id AND tipo_sfida <> 'jackpot';

  SELECT COUNT(DISTINCT tp.challenge_id) INTO v_done
  FROM public.team_progress tp
  JOIN public.challenges c ON c.id = tp.challenge_id
  WHERE tp.team_id = p_team_id
    AND c.stage_id = v_challenge.stage_id
    AND c.tipo_sfida <> 'jackpot'
    AND tp.stato = 'completed';

  IF v_total > 0 AND v_done >= v_total AND v_stage_number BETWEEN 1 AND 4 THEN
    v_stage_completed := true;

    -- Malus Dimezza Punti Tappa registrato per questa tappa
    SELECT * INTO v_dimezza
    FROM public.marketplace_transactions
    WHERE target_team_id = p_team_id
      AND marketplace_item_id = 'dimezza_punti'
      AND stage_id = v_challenge.stage_id
      AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_full_score
      FROM public.scores
      WHERE team_id = p_team_id
        AND stage_id = v_challenge.stage_id
        AND (tipo_modificatore IS NULL OR tipo_modificatore != 'penalty_dimezza_tappa');

      IF v_full_score > 0 THEN
        v_penalty := FLOOR(v_full_score / 2.0)::INTEGER;
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (
          p_team_id, v_challenge.stage_id, -v_penalty, 'penalty_dimezza_tappa',
          'Malus Dimezza Punti Tappa ' || v_stage_number::text || ': penalità −' || v_penalty::text || ' PT (50% del punteggio complessivo della tappa)'
        );

        SELECT * INTO v_polizza
        FROM public.marketplace_transactions
        WHERE team_id = p_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
        ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

        IF FOUND AND v_penalty > 0 THEN
          v_refund := CEIL(v_penalty / 2.0)::INTEGER;
          IF v_refund > 0 THEN
            INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
            VALUES (
              p_team_id, v_challenge.stage_id, v_refund, 'bonus_polizza',
              'Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+' || v_refund::text || ' PT)'
            );
            UPDATE public.marketplace_transactions
            SET stato = 'used',
                data_utilizzo = now(),
                dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'dimezza_punti', 'target_stage_id', v_challenge.stage_id)
            WHERE id = v_polizza.id;
          END IF;
        END IF;
      ELSE
        v_penalty := 0;
      END IF;

      UPDATE public.marketplace_transactions
      SET stato = 'used',
          data_utilizzo = now(),
          dettagli = (COALESCE(dettagli, '{}'::jsonb) || jsonb_build_object(
            'stage_score_before', v_full_score,
            'penalty_applied', v_penalty,
            'stage_score_after', v_full_score - v_penalty,
            'applied_at_stage_completion', true
          ))
      WHERE id = v_dimezza.id;
    END IF;

    -- Ricompensa token per ordine di arrivo (una volta per squadra e tappa)
    IF NOT EXISTS (
      SELECT 1 FROM public.marketplace_transactions
      WHERE team_id = p_team_id
        AND stage_id = v_challenge.stage_id
        AND (marketplace_item_id = 'reward_stage' OR (dettagli->>'stage_reward')::boolean = true)
    ) THEN
      SELECT COUNT(*) + 1 INTO v_pos
      FROM public.marketplace_transactions
      WHERE marketplace_item_id = 'reward_stage'
        AND stage_id = v_challenge.stage_id;

      v_reward := CASE v_pos
        WHEN 1 THEN 25 WHEN 2 THEN 20 WHEN 3 THEN 16 WHEN 4 THEN 13 WHEN 5 THEN 10
        WHEN 6 THEN 8 WHEN 7 THEN 6 WHEN 8 THEN 5 WHEN 9 THEN 4 WHEN 10 THEN 3 WHEN 11 THEN 2
        ELSE 1
      END;

      UPDATE public.teams SET token_balance = token_balance + v_reward WHERE id = p_team_id;

      INSERT INTO public.marketplace_transactions (team_id, stage_id, marketplace_item_id, costo_token, stato, dettagli)
      VALUES (
        p_team_id, v_challenge.stage_id, 'reward_stage', -v_reward, 'completed',
        jsonb_build_object(
          'stage_id', v_challenge.stage_id,
          'stage_index', v_stage_number,
          'position', v_pos,
          'reward_tokens', v_reward
        )
      );

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES (
        'stage_reward_credited', p_team_id,
        jsonb_build_object(
          'message', 'La squadra ' || COALESCE(v_team_name, 'Squadra') || ' ha concluso la Tappa ' || v_stage_number || ' in ' || v_pos || 'ª posizione e ha ricevuto +' || v_reward || ' Token! 🪙',
          'stage_id', v_challenge.stage_id,
          'position', v_pos,
          'tokens_added', v_reward
        )
      );
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'multiplier_2x_bonus', v_2x_bonus,
    'stage_completed', v_stage_completed,
    'stage_dimezza_penalty', v_penalty,
    'polizza_refund', v_refund,
    'position', NULLIF(v_pos, 0),
    'stage_reward', v_reward
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.buy_marketplace_item(p_item_id text, p_target_team_id uuid DEFAULT NULL::uuid, p_target_stage_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp', 'extensions'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_team RECORD;
  v_item RECORD;
  v_target_team_name TEXT;
  v_target_shield RECORD;
  v_target_polizza RECORD;
  v_tx_id UUID;
  v_dettagli JSONB := '{}'::jsonb;
  v_roll INTEGER;
  v_outcome_id TEXT;
  v_outcome_label TEXT;
  v_outcome_pts INTEGER := 0;
  v_outcome_tokens INTEGER := 0;
  v_target_points INTEGER := 0;
  v_buyer_points INTEGER := 0;
  v_points_to_steal INTEGER := 0;
  v_stolen_points INTEGER := 0;
  v_refund INTEGER := 0;
  v_freeze_expires_at TIMESTAMPTZ;
  v_stage_tot_ch INTEGER := 0;
  v_stage_comp_ch INTEGER := 0;
  v_target_stage RECORD;
  v_full_stage_score INTEGER := 0;
  v_stage_penalty INTEGER := 0;
  v_polizza_refund INTEGER := 0;
BEGIN
  -- 1. IDENTIFICA UTENTE E SQUADRA
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
    RAISE EXCEPTION 'Nessuna squadra associata a questo account';
  END IF;

  -- 2. LOCK TEAM PER CONSISTENZA TOKEN
  SELECT * INTO v_team
  FROM public.teams
  WHERE id = v_team_id
  FOR UPDATE;

  -- 3. CONTROLLO GARA TERMINATA
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile effettuare acquisti al Marketplace.';
  END IF;

  -- 4. CONTROLLO MARKETPLACE ATTIVO
  IF NOT EXISTS (SELECT 1 FROM public.game_settings WHERE marketplace_active = true) THEN
    RAISE EXCEPTION 'Il Marketplace è attualmente chiuso dalla Regia!';
  END IF;

  -- 5. CONTROLLO BLACKOUT MERCATO
  IF EXISTS (
    SELECT 1 FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id
      AND marketplace_item_id = 'blackout_mercato'
      AND stato = 'completed'
      AND (data_acquisto + INTERVAL '6 minutes') > now()
  ) THEN
    RAISE EXCEPTION 'La tua squadra è sotto BLACKOUT MERCATO! Il Marketplace è bloccato.';
  END IF;

  -- 6. INFO ARTICOLO E CONTROLLO SALDO & MONOUSO
  SELECT * INTO v_item FROM public.marketplace_items WHERE id = p_item_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Articolo del Marketplace non valido: %', p_item_id;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.marketplace_transactions
    WHERE team_id = v_team_id
      AND marketplace_item_id = p_item_id
      AND stato != 'expired'
  ) THEN
    RAISE EXCEPTION 'Hai già acquistato questo articolo durante la gara! Ogni articolo è utilizzabile 1 sola volta.';
  END IF;

  IF v_team.token_balance < v_item.costo_token THEN
    RAISE EXCEPTION 'Token insufficienti! Costo: % 🪙, Saldo attuale: % 🪙', v_item.costo_token, v_team.token_balance;
  END IF;

  -- Deduce token
  UPDATE public.teams
  SET token_balance = token_balance - v_item.costo_token
  WHERE id = v_team_id;

  -- 7. GESTIONE BERSAGLIO E CONTROLLO SCUDO UNIVERSALE (PER MALUS)
  IF UPPER(COALESCE(v_item.tipo, '')) = 'MALUS' THEN
    IF p_target_team_id IS NULL THEN
      RAISE EXCEPTION 'È obbligatorio selezionare una squadra bersaglio per i Malus!';
    END IF;

    IF p_target_team_id = v_team_id THEN
      RAISE EXCEPTION 'Non puoi lanciare un Malus contro la tua stessa squadra!';
    END IF;

    SELECT nome_squadra INTO v_target_team_name FROM public.teams WHERE id = p_target_team_id;

    -- REGISTRAZIONE PRIVATA PREMIO CATTIVERIA (+10 PT) PER L'ADMIN E IL REPORT FINALE
    INSERT INTO public.cattiveria_ledger (team_id, tipo, marketplace_item_id, punti, motivo)
    VALUES (
      v_team_id,
      'MALUS_UTILIZZATO',
      p_item_id,
      10,
      'Lancio del malus ' || v_item.nome || ' contro ' || COALESCE(v_target_team_name, 'Squadra') || ' (+10 PT Cattiveria)'
    );

    -- CONTROLLO SCUDO UNIVERSALE
    SELECT * INTO v_target_shield
    FROM public.marketplace_transactions
    WHERE team_id = p_target_team_id
      AND marketplace_item_id = 'bonus_scudo'
      AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      UPDATE public.marketplace_transactions
      SET stato = 'used',
          data_utilizzo = now(),
          dettagli = jsonb_build_object(
            'blocked_malus', p_item_id,
            'blocked_malus_id', p_item_id,
            'blocked_malus_name', v_item.nome,
            'attacker_team_id', v_team_id,
            'attacker_name', v_team.nome_squadra,
            'blocked_at', now()
          )
      WHERE id = v_target_shield.id;

      INSERT INTO public.marketplace_transactions (
        team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
      ) VALUES (
        v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'expired', now(),
        jsonb_build_object(
          'blocked_by_shield', true,
          'blocked_by_shield_id', v_target_shield.id,
          'target_team_name', v_target_team_name,
          'blocked_at', now()
        )
      ) RETURNING id INTO v_tx_id;

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'malus_blocked_by_shield', v_team_id, p_target_team_id,
        jsonb_build_object(
          'message', 'Lo Scudo di ' || v_target_team_name || ' ha parato il Malus ' || v_item.nome || ' lanciato da ' || v_team.nome_squadra || '!',
          'malus_id', p_item_id
        )
      );

      RETURN jsonb_build_object(
        'success', true,
        'shielded', true,
        'blocked_by_shield', true,
        'transaction_id', v_tx_id,
        'message', 'Il Malus è stato parato dallo Scudo avversario!',
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    END IF;
  END IF;

  -- 8. ESECUZIONE SPECIFICA PER ITEM
  IF p_item_id = 'bonus_punti' THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, 20, 'bonus_punti', 'Acquisto Marketplace: +20 Punti Squadra');
    v_dettagli := jsonb_build_object('points_added', 20);

    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'ruota_fortuna' THEN
    v_roll := floor(random() * 100 + 1)::integer;
    IF v_roll <= 5 THEN
      v_outcome_id := 'jackpot';
      v_outcome_label := '🏆 JACKPOT (+20 PT)';
      v_outcome_pts := 20;
    ELSIF v_roll <= 15 THEN
      v_outcome_id := 'dave_help';
      v_outcome_label := '🧠 AIUTO DAVE';
    ELSIF v_roll <= 30 THEN
      v_outcome_id := 'mega_bonus';
      v_outcome_label := '💎 MEGA (+15 PT)';
      v_outcome_pts := 15;
    ELSIF v_roll <= 45 THEN
      v_outcome_id := 'bonus';
      v_outcome_label := '⭐ BONUS (+10 PT)';
      v_outcome_pts := 10;
    ELSIF v_roll <= 60 THEN
      v_outcome_id := 'piccolo_bonus';
      v_outcome_label := '🎁 PICCOLO (+5 PT)';
      v_outcome_pts := 5;
    ELSIF v_roll <= 75 THEN
      v_outcome_id := 'gettoni_bonus';
      v_outcome_label := '🪙 +10 TOKEN';
      v_outcome_tokens := 10;
    ELSIF v_roll <= 85 THEN
      v_outcome_id := 'doppio_premio';
      v_outcome_label := '🎯 DOPPIO (+5/+5)';
      v_outcome_pts := 5;
      v_outcome_tokens := 5;
    ELSIF v_roll <= 95 THEN
      v_outcome_id := 'fortuna';
      v_outcome_label := '🍀 +5 TOKEN';
      v_outcome_tokens := 5;
    ELSE
      v_outcome_id := 'sorpresa';
      v_outcome_label := '🎉 +3 PUNTI';
      v_outcome_pts := 3;
    END IF;

    IF v_outcome_pts > 0 THEN
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_outcome_pts, 'bonus_ruota', 'Ruota della Fortuna: ' || v_outcome_label);
    END IF;

    IF v_outcome_tokens > 0 THEN
      UPDATE public.teams
      SET token_balance = token_balance + v_outcome_tokens
      WHERE id = v_team_id;
    END IF;

    v_dettagli := jsonb_build_object(
      'id', v_outcome_id,
      'outcome_id', v_outcome_id,
      'outcome_label', v_outcome_label,
      'label', v_outcome_label,
      'points_awarded', v_outcome_pts,
      'tokens_awarded', v_outcome_tokens,
      'roll', v_roll
    );

    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'passaparola' THEN
    v_dettagli := jsonb_build_object('available', true);
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'bonus_classifica' THEN
    v_dettagli := jsonb_build_object('available', true);

    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'bonus_scudo' THEN
    v_dettagli := jsonb_build_object('activated_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'partenza_anticipata' THEN
    v_dettagli := jsonb_build_object('available_bonus_seconds', 120, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'moltiplicatore_2x' THEN
    v_dettagli := jsonb_build_object('multiplier', 2, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'polizza_diretta' THEN
    v_dettagli := jsonb_build_object('coverage_percent', 50, 'assigned_at', now());
    INSERT INTO public.marketplace_transactions (
      team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'penalita_punti' THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (p_target_team_id, -20, 'penalty', 'Penalità Punti subita da ' || v_team.nome_squadra || ' (−20 PT)');

    -- Controllo Polizza
    SELECT * INTO v_target_polizza
    FROM public.marketplace_transactions
    WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
    ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

    IF FOUND THEN
      v_refund := 10;
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, v_refund, 'bonus_polizza', 'Polizza Diretta: Rimborso 50% penalità (+' || v_refund::text || ' PT)');

      UPDATE public.marketplace_transactions
      SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'penalita_punti')
      WHERE id = v_target_polizza.id;
    END IF;

    v_dettagli := jsonb_build_object('target_team_id', p_target_team_id, 'target_team_name', v_target_team_name, 'points_deducted', 20);

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'trappola' THEN
    SELECT COALESCE(SUM(s.punti), 0)::integer INTO v_target_points
    FROM public.scores s WHERE s.team_id = p_target_team_id;
    
    v_points_to_steal := LEAST(30, GREATEST(0, v_target_points));
    v_stolen_points := v_points_to_steal;

    IF v_stolen_points > 0 THEN
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, -v_stolen_points, 'penalty', 'Trappola subita da ' || v_team.nome_squadra || ': −' || v_stolen_points::text || ' PT');

      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_stolen_points, 'bonus_punti', 'Punti rubati con Trappola a ' || v_target_team_name || ': +' || v_stolen_points::text || ' PT');

      -- Polizza rimborso 50%
      SELECT * INTO v_target_polizza
      FROM public.marketplace_transactions
      WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
      ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

      IF FOUND THEN
        v_refund := CEIL(v_stolen_points / 2.0)::integer;
        IF v_refund > 0 THEN
          INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
          VALUES (p_target_team_id, v_refund, 'bonus_polizza', 'Polizza Diretta: Rimborso 50% punti rubati (+' || v_refund::text || ' PT)');

          UPDATE public.marketplace_transactions
          SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'trappola')
          WHERE id = v_target_polizza.id;
        END IF;
      END IF;
    END IF;

    v_dettagli := jsonb_build_object('stolen_points', v_stolen_points, 'target_team_id', p_target_team_id, 'target_team_name', v_target_team_name);

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'tassa_passaggio' THEN
    -- Calcolo atomico ed esatto dei punteggi di gara LIVE (esclusivamente public.scores)
    SELECT COALESCE(SUM(s.punti), 0)::integer INTO v_buyer_points
    FROM public.scores s WHERE s.team_id = v_team_id;

    SELECT COALESCE(SUM(s.punti), 0)::integer INTO v_target_points
    FROM public.scores s WHERE s.team_id = p_target_team_id;

    -- Inserisce la compensazione esatta in scores per rendere Total_A_after = Total_B_before e viceversa
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, (v_target_points - v_buyer_points), 'switch_punti', 'Tassa di Passaggio: Switch punti con ' || v_target_team_name);

    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (p_target_team_id, (v_buyer_points - v_target_points), 'switch_punti', 'Tassa di Passaggio: Switch punti con ' || v_team.nome_squadra);

    -- Polizza Diretta rimborso per il bersaglio se perde punti nello switch
    IF v_buyer_points < v_target_points THEN
      SELECT * INTO v_target_polizza
      FROM public.marketplace_transactions
      WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
      ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

      IF FOUND THEN
        v_refund := CEIL((v_target_points - v_buyer_points) / 2.0)::integer;
        IF v_refund > 0 THEN
          INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
          VALUES (p_target_team_id, v_refund, 'bonus_polizza', 'Polizza Diretta: Rimborso 50% perdita switch (+' || v_refund::text || ' PT)');

          UPDATE public.marketplace_transactions
          SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('refunded_points', v_refund, 'source_malus', 'tassa_passaggio')
          WHERE id = v_target_polizza.id;
        END IF;
      END IF;
    END IF;

    v_dettagli := jsonb_build_object(
      'buyer_points_before', v_buyer_points,
      'target_points_before', v_target_points,
      'buyer_points_after', v_target_points,
      'target_points_after', v_buyer_points
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'freeze_2min' THEN
    UPDATE public.teams
    SET freeze_started_at = COALESCE(
          CASE WHEN freeze_expires_at > now() THEN freeze_started_at ELSE now() END,
          now()
        ),
        freeze_expires_at = GREATEST(now(), COALESCE(freeze_expires_at, now())) + INTERVAL '120 seconds',
        freeze_duration_seconds = COALESCE(freeze_duration_seconds, 0) + 120
    WHERE id = p_target_team_id
    RETURNING freeze_expires_at INTO v_freeze_expires_at;

    v_dettagli := jsonb_build_object(
      'duration_seconds', 120,
      'freeze_expires_at', v_freeze_expires_at,
      'attacker_id', v_team_id,
      'attacker_name', v_team.nome_squadra
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'blackout_mercato' THEN
    v_dettagli := jsonb_build_object(
      'duration_seconds', 360,
      'expires_at', now() + INTERVAL '6 minutes',
      'attacker_id', v_team_id,
      'attacker_name', v_team.nome_squadra
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;

  ELSIF p_item_id = 'dimezza_punti' THEN
    IF p_target_stage_id IS NULL THEN
      RAISE EXCEPTION 'È obbligatorio selezionare una tappa da colpire per il malus DIMEZZA PUNTI TAPPA.';
    END IF;

    SELECT * INTO v_target_stage FROM public.stages WHERE id = p_target_stage_id;
    IF NOT FOUND OR v_target_stage.numero_tappa < 1 OR v_target_stage.numero_tappa > 4 THEN
      RAISE EXCEPTION 'Tappa non valida. È possibile selezionare esclusivamente le Tappe 1, 2, 3 o 4.';
    END IF;

    SELECT COUNT(*) INTO v_stage_tot_ch FROM public.challenges WHERE stage_id = p_target_stage_id;
    SELECT COUNT(DISTINCT tp.challenge_id) INTO v_stage_comp_ch
    FROM public.team_progress tp
    JOIN public.challenges c ON c.id = tp.challenge_id
    WHERE tp.team_id = p_target_team_id AND c.stage_id = p_target_stage_id AND tp.stato = 'completed';

    IF v_stage_tot_ch > 0 AND v_stage_comp_ch >= v_stage_tot_ch THEN
      SELECT COALESCE(SUM(punti), 0)::integer INTO v_full_stage_score
      FROM public.scores
      WHERE team_id = p_target_team_id
        AND stage_id = p_target_stage_id
        AND (tipo_modificatore IS NULL OR tipo_modificatore != 'penalty_dimezza_tappa');

      IF v_full_stage_score > 0 THEN
        v_stage_penalty := FLOOR(v_full_stage_score / 2.0)::integer;
        
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (
          p_target_team_id,
          p_target_stage_id,
          -v_stage_penalty,
          'penalty_dimezza_tappa',
          'Malus Dimezza Punti Tappa ' || v_target_stage.numero_tappa::text || ': penalità −' || v_stage_penalty::text || ' PT (50% del punteggio complessivo della tappa)'
        );

        -- Polizza Diretta rimborso
        SELECT * INTO v_target_polizza
        FROM public.marketplace_transactions
        WHERE team_id = p_target_team_id AND marketplace_item_id = 'polizza_diretta' AND stato = 'completed'
        ORDER BY data_acquisto ASC LIMIT 1 FOR UPDATE;

        IF FOUND AND v_stage_penalty > 0 THEN
          v_polizza_refund := CEIL(v_stage_penalty / 2.0)::integer;
          IF v_polizza_refund > 0 THEN
            INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
            VALUES (
              p_target_team_id,
              p_target_stage_id,
              v_polizza_refund,
              'bonus_polizza',
              'Polizza Diretta: Rimborso 50% penalità Dimezza Tappa (+' || v_polizza_refund::text || ' PT)'
            );

            UPDATE public.marketplace_transactions
            SET stato = 'used',
                data_utilizzo = now(),
                dettagli = jsonb_build_object('refunded_points', v_polizza_refund, 'source_malus', 'dimezza_punti', 'target_stage_id', p_target_stage_id)
            WHERE id = v_target_polizza.id;
          END IF;
        END IF;
      ELSE
        v_stage_penalty := 0;
      END IF;

      v_dettagli := jsonb_build_object(
        'target_stage_id', p_target_stage_id,
        'stage_number', v_target_stage.numero_tappa,
        'stage_title', v_target_stage.titolo,
        'target_team_id', p_target_team_id,
        'target_team_name', v_target_team_name,
        'attacker_name', v_team.nome_squadra,
        'applied_mode', 'immediate_completed',
        'stage_status_at_purchase', 'completed',
        'stage_score_before', v_full_stage_score,
        'penalty_applied', v_stage_penalty,
        'stage_score_after', v_full_stage_score - v_stage_penalty
      );

      INSERT INTO public.marketplace_transactions (
        team_id, target_team_id, stage_id, marketplace_item_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
      ) VALUES (
        v_team_id, p_target_team_id, p_target_stage_id, p_item_id, v_item.costo_token, 'used', now(), now(), v_dettagli
      ) RETURNING id INTO v_tx_id;
    ELSE
      v_dettagli := jsonb_build_object(
        'target_stage_id', p_target_stage_id,
        'stage_number', v_target_stage.numero_tappa,
        'stage_title', v_target_stage.titolo,
        'target_team_id', p_target_team_id,
        'target_team_name', v_target_team_name,
        'attacker_name', v_team.nome_squadra,
        'applied_mode', 'pending_future',
        'stage_status_at_purchase', CASE WHEN v_stage_comp_ch > 0 THEN 'in_progress' ELSE 'not_started' END
      );

      INSERT INTO public.marketplace_transactions (
        team_id, target_team_id, stage_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
      ) VALUES (
        v_team_id, p_target_team_id, p_target_stage_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
      ) RETURNING id INTO v_tx_id;
    END IF;

  ELSIF p_item_id = 'enigma_extra' OR p_item_id = 'ruota_sfortunata' THEN
    v_dettagli := jsonb_build_object(
      'target_team_id', p_target_team_id,
      'target_team_name', v_target_team_name,
      'assigned_at', now(),
      'attacker_id', v_team_id,
      'attacker_name', v_team.nome_squadra
    );

    INSERT INTO public.marketplace_transactions (
      team_id, target_team_id, marketplace_item_id, costo_token, stato, data_acquisto, dettagli
    ) VALUES (
      v_team_id, p_target_team_id, p_item_id, v_item.costo_token, 'completed', now(), v_dettagli
    ) RETURNING id INTO v_tx_id;
  END IF;

  -- 9. REGISTRAZIONE LOG ATTIVITÀ
  INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
  VALUES (
    'marketplace_purchase', v_team_id, p_target_team_id,
    jsonb_build_object(
      'item_id', p_item_id,
      'item_name', v_item.nome,
      'buyer_team_name', v_team.nome_squadra,
      'target_team_name', v_target_team_name,
      'cost', v_item.costo_token,
      'outcome', v_dettagli
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'transaction_id', v_tx_id,
    'new_balance', v_team.token_balance - v_item.costo_token,
    'shielded', false,
    'outcome', v_dettagli
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_final_game_results(p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_report JSONB;
  v_calculated_at TIMESTAMPTZ := now();
BEGIN
  PERFORM public.assert_admin_caller();
  IF p_admin_id IS NULL
     OR NOT public.has_role(p_admin_id, 'admin') THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  WITH
  active_teams AS (
    SELECT
      t.id,
      t.nome_squadra,
      t.avatar_url,
      COALESCE(t.colore, t.color) AS color,
      t.motto,
      t.created_at,
      COALESCE(t.token_balance, 0) AS token_balance
    FROM public.teams t
    WHERE COALESCE(t.active, true)
  ),

  score_totals AS (
    SELECT
      s.team_id,
      COALESCE(SUM(s.punti), 0)::INTEGER AS total_score,
      COALESCE(
        SUM(CASE WHEN s.challenge_id IS NOT NULL THEN s.punti ELSE 0 END),
        0
      )::INTEGER AS challenges_points,
      COALESCE(
        SUM(CASE WHEN s.challenge_id IS NULL THEN s.punti ELSE 0 END),
        0
      )::INTEGER AS modifier_points
    FROM public.scores s
    GROUP BY s.team_id
  ),

  cattiveria_totals AS (
    SELECT
      c.team_id,
      COALESCE(SUM(c.punti), 0)::INTEGER AS cattiveria_points
    FROM public.cattiveria_ledger c
    GROUP BY c.team_id
  ),

  completed_totals AS (
    SELECT
      tp.team_id,
      COUNT(*) FILTER (
        WHERE tp.stato IN ('completed', 'completata', 'done')
      )::INTEGER AS completed_challenges,
      MAX(tp.completata_il) AS last_completion
    FROM public.team_progress tp
    JOIN public.challenges ch ON ch.id = tp.challenge_id
    WHERE ch.tipo_sfida <> 'jackpot'
    GROUP BY tp.team_id
  ),

  session_totals AS (
    SELECT
      rs.team_id,
      COALESCE(SUM(rs.duration_seconds), 0)::BIGINT AS session_seconds
    FROM public.race_sessions rs
    WHERE rs.duration_seconds IS NOT NULL
    GROUP BY rs.team_id
  ),

  penalty_totals AS (
    SELECT
      tp.team_id,
      COALESCE(SUM(tp.minuti_penalita * 60), 0)::BIGINT AS penalty_seconds
    FROM public.time_penalties tp
    GROUP BY tp.team_id
  ),

  early_start_totals AS (
    SELECT
      mt.team_id,
      COUNT(*)::INTEGER AS early_start_count
    FROM public.marketplace_transactions mt
    JOIN public.marketplace_items mi
      ON mi.id = mt.marketplace_item_id
    WHERE LOWER(COALESCE(mi.id::TEXT, '')) = 'partenza_anticipata'
       OR LOWER(COALESCE(mi.nome, '')) LIKE '%partenza anticipata%'
    GROUP BY mt.team_id
  ),

  team_base AS (
    SELECT
      t.id,
      t.nome_squadra,
      t.avatar_url,
      t.color,
      t.motto,
      t.created_at,
      t.token_balance,

      COALESCE(st.total_score, 0)
        + COALESCE(ct.cattiveria_points, 0)
        AS base_score,

      COALESCE(st.challenges_points, 0) AS challenges_points,
      COALESCE(st.modifier_points, 0) AS modifier_points,
      COALESCE(ct.cattiveria_points, 0) AS cattiveria_points,

      COALESCE(comp.completed_challenges, 0)
        AS completed_challenges,

      comp.last_completion,

      CASE
        WHEN COALESCE(ss.session_seconds, 0) > 0
          THEN ss.session_seconds
        WHEN comp.last_completion IS NOT NULL
          THEN GREATEST(
            0,
            EXTRACT(
              EPOCH
              FROM (comp.last_completion - COALESCE(gs.race_started_at, t.created_at))
            )::BIGINT
          )
        ELSE 0
      END
      + COALESCE(pt.penalty_seconds, 0)
      - (COALESCE(es.early_start_count, 0) * 120)
      AS total_time_seconds,

      COALESCE(es.early_start_count, 0) AS early_start_count,
      COALESCE(ss.session_seconds, 0) AS race_session_seconds,
      COALESCE(pt.penalty_seconds, 0) AS penalty_seconds

    FROM active_teams t
    LEFT JOIN public.game_settings gs ON gs.id = 'settings_01'
    LEFT JOIN score_totals st ON st.team_id = t.id
    LEFT JOIN cattiveria_totals ct ON ct.team_id = t.id
    LEFT JOIN completed_totals comp ON comp.team_id = t.id
    LEFT JOIN session_totals ss ON ss.team_id = t.id
    LEFT JOIN penalty_totals pt ON pt.team_id = t.id
    LEFT JOIN early_start_totals es ON es.team_id = t.id
  ),

  ranked_by_time AS (
    SELECT
      tb.*,
      DENSE_RANK() OVER (
        ORDER BY
          (CASE WHEN tb.completed_challenges < (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') THEN 1 ELSE 0 END) ASC,
          tb.total_time_seconds ASC,
          tb.last_completion ASC NULLS LAST,
          tb.created_at ASC
      )::INTEGER AS time_rank
    FROM team_base tb
  ),

  scored AS (
    SELECT
      r.*,
      (CASE WHEN r.completed_challenges < (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') THEN 0 ELSE public._get_time_bonus_points(r.time_rank) END) AS time_bonus,
      FLOOR(r.token_balance / 5)::INTEGER AS token_efficiency_bonus
    FROM ranked_by_time r
  ),

  final_ranked AS (
    SELECT
      s.*,
      (
        s.base_score
        + s.time_bonus
        + s.token_efficiency_bonus
      )::INTEGER AS final_score
    FROM scored s
  ),

  final_positions AS (
    SELECT
      f.*,
      ROW_NUMBER() OVER (
        ORDER BY
          (CASE WHEN f.completed_challenges < (SELECT COUNT(*) FROM public.challenges WHERE tipo_sfida <> 'jackpot') THEN 1 ELSE 0 END) ASC,
          f.final_score DESC,
          f.completed_challenges DESC,
          f.total_time_seconds ASC,
          f.last_completion ASC NULLS LAST,
          f.created_at ASC
      )::INTEGER AS final_rank
    FROM final_ranked f
  )

  SELECT jsonb_build_object(
    'teams',
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', fp.id,
          'team_id', fp.id,
          'name', fp.nome_squadra,
          'team_name', fp.nome_squadra,
          'nome_squadra', fp.nome_squadra,
          'avatar_url', fp.avatar_url,
          'color', fp.color,
          'motto', fp.motto,
          'rank', fp.final_rank,
          'position', fp.final_rank,
          'final_rank', fp.final_rank,
          'time_rank', fp.time_rank,
          'completed_challenges', fp.completed_challenges,
          'challenges_points', fp.challenges_points,
          'modifier_points', fp.modifier_points,
          'cattiveria_points', fp.cattiveria_points,
          'base_score', fp.base_score,
          'total_score_before_final_bonuses', fp.base_score,
          'time_bonus', fp.time_bonus,
          'bonus_tempo', fp.time_bonus,
          'token_balance', fp.token_balance,
          'token_efficiency_bonus', fp.token_efficiency_bonus,
          'final_score', fp.final_score,
          'total_points', fp.final_score,
          'total_duration_seconds', fp.total_time_seconds,
          'total_time_seconds', fp.total_time_seconds,
          'race_session_seconds', fp.race_session_seconds,
          'penalty_seconds', fp.penalty_seconds,
          'partenza_anticipata_count', fp.early_start_count,
          'partenza_anticipata', (fp.early_start_count > 0),
          'last_completion', fp.last_completion
        )
        ORDER BY fp.final_rank
      ),
      '[]'::jsonb
    ),
    'stages',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', st.id,
            'name', st.titolo,
            'order', st.numero_tappa,
            'status', st.stato,
            'challenges_count',
              (
                SELECT COUNT(*)
                FROM public.challenges c
                WHERE c.stage_id = st.id
              )
          )
          ORDER BY st.numero_tappa
        )
        FROM public.stages st
      ),
      '[]'::jsonb
    )
  )
  INTO v_report
  FROM final_positions fp;

  UPDATE public.game_report
  SET calculated_snapshot = v_report,
      calculated_at = v_calculated_at,
      calculated_by = p_admin_id,
      status = CASE WHEN status = 'PUBLISHED' THEN status ELSE 'CALCULATED' END,
      updated_at = v_calculated_at
  WHERE id = 'current';

  IF NOT FOUND THEN
    INSERT INTO public.game_report (
      id,
      state,
      published_at,
      published_by,
      snapshot,
      calculated_snapshot,
      calculated_at,
      calculated_by,
      status,
      updated_at
    )
    VALUES (
      'current',
      'PRIVATE_LIVE',
      NULL,
      NULL,
      NULL,
      v_report,
      v_calculated_at,
      p_admin_id,
      'CALCULATED',
      v_calculated_at
    );
  END IF;

  INSERT INTO public.activity_log (
    id,
    tipo_evento,
    team_id,
    target_team_id,
    dettagli,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'CALCULATE_FINAL_RESULTS',
    NULL,
    NULL,
    jsonb_build_object(
      'admin_id', p_admin_id,
      'calculated_at', v_calculated_at
    ),
    v_calculated_at
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'CALCULATED',
    'calculated_at', v_calculated_at,
    'report', v_report
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_stage(p_stage_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_stage RECORD;
  v_stage_reward INTEGER;
  v_team RECORD;
  v_already_rewarded BOOLEAN;
  v_rewarded_count INTEGER := 0;
BEGIN
  SELECT (public.has_role(auth.uid(), 'admin') OR auth.role() = 'service_role') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_stage FROM public.stages WHERE id = p_stage_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tappa non trovata';
  END IF;

  v_stage_reward := CASE WHEN v_stage.numero_tappa = 5 THEN 20 ELSE 10 END;

  UPDATE public.stages SET stato = 'closed' WHERE id = p_stage_id;

  FOR v_team IN SELECT * FROM public.teams WHERE active = true LOOP
    IF (SELECT COUNT(*) FROM public.challenges WHERE stage_id = p_stage_id) > 0 AND
       (SELECT COUNT(*) FROM public.team_progress tp JOIN public.challenges c ON c.id = tp.challenge_id WHERE tp.team_id = v_team.id AND c.stage_id = p_stage_id AND tp.stato = 'completed') >= (SELECT COUNT(*) FROM public.challenges WHERE stage_id = p_stage_id) THEN
       
       SELECT EXISTS (
         SELECT 1 FROM public.marketplace_transactions
         WHERE team_id = v_team.id
           AND stage_id = p_stage_id
           AND (marketplace_item_id = 'reward_stage' OR (dettagli->>'stage_reward')::boolean = true)
       ) INTO v_already_rewarded;

       IF NOT v_already_rewarded THEN
         UPDATE public.teams SET token_balance = COALESCE(token_balance, 50) + v_stage_reward WHERE id = v_team.id;

         INSERT INTO public.marketplace_transactions (
           id, team_id, marketplace_item_id, costo_token, stato, data_acquisto, stage_id, dettagli
         ) VALUES (
           gen_random_uuid(),
           v_team.id,
           'reward_stage',
           -v_stage_reward,
           'completed',
           now(),
           p_stage_id,
           jsonb_build_object(
             'stage_reward', true,
             'stage_id', p_stage_id,
             'stage_name', v_stage.titolo,
             'stage_index', v_stage.numero_tappa,
             'reward_tokens', v_stage_reward
           )
         );

         v_rewarded_count := v_rewarded_count + 1;
       END IF;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'stage_id', p_stage_id, 'rewarded_teams', v_rewarded_count);
END;
$function$;

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
    WHERE id = v_team_id;

    INSERT INTO public.marketplace_transactions (team_id, stage_id, marketplace_item_id, costo_token, stato, dettagli)
    VALUES (
      v_team_id, v_challenge.stage_id, 'reward_stage', -v_stage_reward, 'completed',
      jsonb_build_object(
        'stage_id', v_challenge.stage_id,
        'stage_index', v_stage_number,
        'position', v_stage_arrival_pos,
        'reward_tokens', v_stage_reward
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
$function$;

CREATE OR REPLACE FUNCTION public.mark_partenza_used(p_transaction_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_team_id UUID;
  v_tx RECORD;
BEGIN
  v_is_admin := public.has_role(auth.uid(), 'admin');
  v_team_id := public.current_team_id();

  SELECT * INTO v_tx FROM public.marketplace_transactions WHERE id = p_transaction_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  IF NOT v_is_admin AND (v_team_id IS NULL OR v_tx.team_id != v_team_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autorizzato');
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used', data_utilizzo = now()
  WHERE id = p_transaction_id;

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.open_classifica_bonus(p_transaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_tx RECORD;
  v_snapshot JSONB;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE id = p_transaction_id AND team_id = v_team_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transazione non trovata';
  END IF;

  IF v_tx.marketplace_item_id != 'bonus_classifica' THEN
    RAISE EXCEPTION 'Transazione non abbinata al bonus classifica';
  END IF;

  IF v_tx.stato = 'completed' THEN
    -- Generate snapshot of current live leaderboard based EXCLUSIVELY on public.scores
    SELECT jsonb_agg(jsonb_build_object(
      'team_id', t.id,
      'name', t.nome_squadra,
      'nome_squadra', t.nome_squadra,
      'color', t.colore,
      'avatar_url', t.avatar_url,
      'total_points', COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0)
    ) ORDER BY COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) DESC)
    INTO v_snapshot
    FROM public.teams t
    WHERE t.active = true;

    UPDATE public.marketplace_transactions
    SET
      stato = 'viewing',
      data_utilizzo = now(),
      dettagli = jsonb_build_object('snapshot', v_snapshot, 'snapshot_timestamp', now())
    WHERE id = p_transaction_id;
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.spin_unlucky_wheel(p_transaction_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
  v_team_id UUID;
  v_tx RECORD;
  v_roll INTEGER;
  v_outcome_id TEXT;
  v_outcome_label TEXT;
  v_points INTEGER := 0;
  v_tokens INTEGER := 0;
  v_minutes INTEGER := 0;
  v_freeze_seconds INTEGER := 0;
  v_outcome JSONB;
BEGIN
  -- CONTROLLO GARA TERMINATA
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile compiere azioni.';
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

  IF p_transaction_id IS NOT NULL THEN
    SELECT * INTO v_tx
    FROM public.marketplace_transactions
    WHERE id = p_transaction_id
      AND target_team_id = v_team_id
      AND marketplace_item_id = 'ruota_sfortunata'
      AND stato = 'completed'
    FOR UPDATE;
  ELSE
    SELECT * INTO v_tx
    FROM public.marketplace_transactions
    WHERE target_team_id = v_team_id
      AND marketplace_item_id = 'ruota_sfortunata'
      AND stato = 'completed'
    ORDER BY data_acquisto ASC
    LIMIT 1
    FOR UPDATE;
  END IF;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Nessuna Ruota Sfortunata attiva trovata per questa squadra';
  END IF;

  v_roll := floor(random() * 100 + 1)::integer;

  IF v_roll <= 20 THEN
    v_outcome_id := 'freeze_2min';
    v_outcome_label := '❄️ CONGELAMENTO 2 MINUTI';
    v_freeze_seconds := 120;
  ELSIF v_roll <= 36 THEN
    v_outcome_id := 'minus_15_points';
    v_outcome_label := '📉 PENALITÀ -15 PUNTI';
    v_points := 15;
  ELSIF v_roll <= 52 THEN
    v_outcome_id := 'minus_10_tokens';
    v_outcome_label := '🪙 PERDITA 10 TOKEN';
    v_tokens := 10;
  ELSIF v_roll <= 68 THEN
    v_outcome_id := 'plus_2_min';
    v_outcome_label := '⏱️ PENALITÀ TEMPO +2 MINUTI';
    v_minutes := 2;
  ELSIF v_roll <= 84 THEN
    v_outcome_id := 'heavy_backpack';
    v_outcome_label := '🎒 ZAINO PESANTE (+3 MIN)';
    v_minutes := 3;
  ELSE
    v_outcome_id := 'minus_10_points_minus_5_tokens';
    v_outcome_label := '💥 -10 PUNTI & -5 TOKEN';
    v_points := 10;
    v_tokens := 5;
  END IF;

  v_outcome := jsonb_build_object(
    'id', v_outcome_id,
    'label', v_outcome_label,
    'points', v_points,
    'tokens', v_tokens,
    'minutes', v_minutes,
    'freeze_seconds', v_freeze_seconds,
    'roll', v_roll
  );

  -- Apply penalties with CUMULATIVE freeze support
  IF v_freeze_seconds > 0 THEN
    UPDATE public.teams
    SET
      freeze_started_at = COALESCE(
        CASE WHEN freeze_expires_at > now() THEN freeze_started_at ELSE now() END,
        now()
      ),
      freeze_expires_at = GREATEST(now(), COALESCE(freeze_expires_at, now())) + (v_freeze_seconds || ' seconds')::interval,
      freeze_duration_seconds = COALESCE(freeze_duration_seconds, 0) + v_freeze_seconds
    WHERE id = v_team_id;
  END IF;

  IF v_points > 0 THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, -v_points, 'penalty', 'Ruota Sfortunata: ' || v_outcome_label);
  END IF;

  IF v_tokens > 0 THEN
    UPDATE public.teams
    SET token_balance = GREATEST(0, token_balance - v_tokens)
    WHERE id = v_team_id;
  END IF;

  IF v_minutes > 0 THEN
    INSERT INTO public.time_penalties (team_id, minuti_penalita, motivo)
    VALUES (v_team_id, v_minutes, 'Ruota Sfortunata: ' || v_outcome_label);
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used',
      data_utilizzo = now(),
      dettagli = jsonb_build_object('outcome', v_outcome)
  WHERE id = v_tx.id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES (
    'ruota_sfortunata_spin', v_team_id,
    jsonb_build_object('message', 'La squadra ha girato la Ruota Sfortunata ed ha subito: ' || v_outcome_label)
  );

  RETURN jsonb_build_object(
    'success', true,
    'outcome', v_outcome
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_passaparola_request(p_transaction_id uuid, p_request_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_team_name TEXT;
  v_tx RECORD;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE id = p_transaction_id AND team_id = v_team_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  IF v_tx.marketplace_item_id != 'passaparola' OR v_tx.stato != 'completed' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Richiesta non valida o già inoltrata');
  END IF;

  -- Aggiorna stato a pending e salva testo della richiesta
  UPDATE public.marketplace_transactions
  SET stato = 'pending', dettagli = jsonb_build_object('request_text', p_request_text, 'requested_at', now())
  WHERE id = p_transaction_id;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('passaparola_request', v_team_id,
    jsonb_build_object('message', 'La squadra "' || v_team_name || '" ha inoltrato una richiesta Passaparola: "' || p_request_text || '"'));

  RETURN jsonb_build_object('success', true);
END;
$function$;

DROP FUNCTION IF EXISTS public.team_current_stage_id(uuid);
DROP FUNCTION IF EXISTS public.add_cattiveria(uuid, uuid, text, text, uuid, integer, text);
DROP FUNCTION IF EXISTS public.team_stage_at(uuid, timestamptz);
-- Vincolo originale (eseguire solo se non esistono righe con i nuovi tipi 'bonus','malus','end_of_stage'):
-- ALTER TABLE public.cattiveria_ledger DROP CONSTRAINT cattiveria_ledger_tipo_check;
-- ALTER TABLE public.cattiveria_ledger ADD CONSTRAINT cattiveria_ledger_tipo_check CHECK (tipo = ANY (ARRAY['MALUS_UTILIZZATO','SCUDO_ATTIVATO','MALUS_SUBITO_DIFESO','FINE_TAPPA_CATTIVERIA']));
