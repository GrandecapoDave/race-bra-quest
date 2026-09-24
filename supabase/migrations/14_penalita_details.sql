-- 14_penalita_details.sql
-- Penalità Punti: il dettaglio della transazione include punti del bersaglio prima/dopo e il rimborso della Polizza
-- (la pagina admin Penalità mostrava "Punti Bersaglio Prima/Dopo: PT" vuoti).

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

  -- Acquisti serializzati: nessuna corsa tra acquisti simultanei (Tassa di Passaggio, Trappola, ecc.)
  PERFORM pg_advisory_xact_lock(hashtext('marketplace_purchase'));

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

    IF NOT EXISTS (SELECT 1 FROM public.teams WHERE id = p_target_team_id AND COALESCE(active, true)) THEN
      RAISE EXCEPTION 'Squadra bersaglio non valida o non più in gara';
    END IF;

    SELECT nome_squadra INTO v_target_team_name FROM public.teams WHERE id = p_target_team_id;


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

      PERFORM public.add_cattiveria(
        p_target_team_id, public.team_current_stage_id(p_target_team_id), 'bonus', 'bonus_scudo', v_target_shield.id, -3,
        'Utilizzo Scudo (Malus ' || v_item.nome || ' bloccato)'
      );

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
    SELECT COALESCE(SUM(sc.punti), 0)::integer INTO v_target_points FROM public.scores sc WHERE sc.team_id = p_target_team_id;

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

    v_dettagli := jsonb_build_object(
      'target_team_id', p_target_team_id,
      'target_team_name', v_target_team_name,
      'points_deducted', 20,
      'refunded_points', v_refund,
      'target_points_before', v_target_points,
      'target_points_after', v_target_points - 20 + v_refund
    );

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

  -- 8b. PUNTI CATTIVERIA (solo all'utilizzo effettivo; la Ruota Sfortunata paga al giro della ruota)
  IF p_item_id = 'bonus_punti' THEN
    PERFORM public.add_cattiveria(v_team_id, public.team_current_stage_id(v_team_id), 'bonus', p_item_id, v_tx_id, -5, 'Utilizzo Bonus Punti (+20 PT)');
  ELSIF p_item_id = 'ruota_fortuna' THEN
    PERFORM public.add_cattiveria(v_team_id, public.team_current_stage_id(v_team_id), 'bonus', p_item_id, v_tx_id, -2, 'Utilizzo Ruota della Fortuna: ' || COALESCE(v_outcome_label, ''));
  ELSIF p_item_id = 'freeze_2min' THEN
    PERFORM public.add_cattiveria(v_team_id, public.team_current_stage_id(v_team_id), 'malus', p_item_id, v_tx_id, 8, 'Utilizzo Freeze contro ' || COALESCE(v_target_team_name, ''));
  ELSIF p_item_id = 'trappola' THEN
    PERFORM public.add_cattiveria(v_team_id, public.team_current_stage_id(v_team_id), 'malus', p_item_id, v_tx_id, 12, 'Utilizzo Trappola contro ' || COALESCE(v_target_team_name, ''));
  ELSIF p_item_id = 'penalita_punti' THEN
    PERFORM public.add_cattiveria(v_team_id, public.team_current_stage_id(v_team_id), 'malus', p_item_id, v_tx_id, 10, 'Utilizzo Penalità Punti contro ' || COALESCE(v_target_team_name, ''));
  ELSIF p_item_id = 'tassa_passaggio' THEN
    PERFORM public.add_cattiveria(v_team_id, public.team_current_stage_id(v_team_id), 'malus', p_item_id, v_tx_id, 15, 'Utilizzo Tassa di Passaggio contro ' || COALESCE(v_target_team_name, ''));
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
