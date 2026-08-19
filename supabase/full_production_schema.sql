-- ============================================================================
-- PECHINO EXPRESS BRA — FULL PRODUCTION SUPABASE POSTGRESQL SCHEMA & RPCs
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TEAMS
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_squadra TEXT NOT NULL UNIQUE,
  colore TEXT NOT NULL DEFAULT '#ea580c',
  token_balance INTEGER NOT NULL DEFAULT 50 CHECK (token_balance >= 0),
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS token_balance INTEGER NOT NULL DEFAULT 50;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;

-- 2. STAGES
CREATE TABLE IF NOT EXISTS public.stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_tappa INTEGER UNIQUE,
  titolo TEXT NOT NULL,
  descrizione TEXT,
  latitude NUMERIC(10, 7) DEFAULT NULL,
  longitude NUMERIC(10, 7) DEFAULT NULL,
  stato TEXT NOT NULL DEFAULT 'open',
  outcome JSONB DEFAULT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS numero_tappa INTEGER;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS titolo TEXT;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS descrizione TEXT;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 7) DEFAULT NULL;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 7) DEFAULT NULL;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS stato TEXT NOT NULL DEFAULT 'open';
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS outcome JSONB DEFAULT NULL;

-- 3. CHALLENGES
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stage_id UUID NOT NULL REFERENCES public.stages(id) ON DELETE CASCADE,
  titolo TEXT NOT NULL,
  descrizione TEXT,
  tipo_sfida TEXT NOT NULL,
  punteggio_massimo INTEGER NOT NULL DEFAULT 100,
  ordine_sfida INTEGER NOT NULL DEFAULT 1,
  configurazione JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS stage_id UUID REFERENCES public.stages(id) ON DELETE CASCADE;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS titolo TEXT;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS descrizione TEXT;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS tipo_sfida TEXT;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS punteggio_massimo INTEGER NOT NULL DEFAULT 100;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS ordine_sfida INTEGER NOT NULL DEFAULT 1;
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS configurazione JSONB DEFAULT '{}'::jsonb;

-- 4. TEAM PROGRESS
CREATE TABLE IF NOT EXISTS public.team_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  stato TEXT NOT NULL DEFAULT 'locked',
  completata_il TIMESTAMPTZ DEFAULT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (team_id, challenge_id)
);
ALTER TABLE public.team_progress ADD COLUMN IF NOT EXISTS stato TEXT NOT NULL DEFAULT 'locked';
ALTER TABLE public.team_progress ADD COLUMN IF NOT EXISTS completata_il TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.team_progress ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- 5. SCORES
CREATE TABLE IF NOT EXISTS public.scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  punti INTEGER NOT NULL,
  tipo_modificatore TEXT DEFAULT 'challenge_points',
  motivo TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.scores ADD COLUMN IF NOT EXISTS tipo_modificatore TEXT DEFAULT 'challenge_points';
ALTER TABLE public.scores ADD COLUMN IF NOT EXISTS motivo TEXT;

-- 6. MARKETPLACE ITEMS
CREATE TABLE IF NOT EXISTS public.marketplace_items (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('bonus', 'malus')),
  descrizione TEXT,
  costo_token INTEGER NOT NULL CHECK (costo_token >= 0),
  effetto TEXT,
  icona TEXT,
  disponibile BOOLEAN NOT NULL DEFAULT true,
  regole JSONB DEFAULT '{}'::jsonb
);

-- 7. MARKETPLACE TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.marketplace_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  marketplace_item_id TEXT NOT NULL REFERENCES public.marketplace_items(id),
  target_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  costo_token INTEGER NOT NULL,
  stato TEXT NOT NULL DEFAULT 'completed',
  data_acquisto TIMESTAMPTZ NOT NULL DEFAULT now(),
  data_utilizzo TIMESTAMPTZ DEFAULT NULL,
  dettagli JSONB DEFAULT '{}'::jsonb
);

-- 8. PUNTI CATTIVERIA LEDGER
CREATE TABLE IF NOT EXISTS public.cattiveria_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  tipo TEXT NOT NULL,
  marketplace_item_id TEXT REFERENCES public.marketplace_items(id),
  riferimento_transazione UUID REFERENCES public.marketplace_transactions(id) ON DELETE SET NULL,
  punti INTEGER NOT NULL,
  motivo TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. JACKPOT PLAYS
CREATE TABLE IF NOT EXISTS public.jackpot_plays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  puntata_punti INTEGER NOT NULL,
  esito_moltiplicatore NUMERIC NOT NULL,
  delta_punti INTEGER NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 10. SUBMISSIONS (PHOTO & EVIDENCE)
CREATE TABLE IF NOT EXISTS public.submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL,
  url TEXT NOT NULL,
  latitude NUMERIC(10, 7) DEFAULT NULL,
  longitude NUMERIC(10, 7) DEFAULT NULL,
  stato_approvazione TEXT NOT NULL DEFAULT 'pending',
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 11. TIME PENALTIES
CREATE TABLE IF NOT EXISTS public.time_penalties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  minuti_penalita NUMERIC NOT NULL DEFAULT 0,
  motivo TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 12. AUDIT LOG
CREATE TABLE IF NOT EXISTS public.activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_evento TEXT NOT NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  target_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  dettagli JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 13. GAME REPORT
CREATE TABLE IF NOT EXISTS public.game_report (
  id TEXT PRIMARY KEY DEFAULT 'current',
  state TEXT NOT NULL DEFAULT 'PRIVATE_LIVE',
  published_at TIMESTAMPTZ DEFAULT NULL,
  published_by UUID DEFAULT NULL,
  snapshot JSONB DEFAULT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 14. GAME SETTINGS
CREATE TABLE IF NOT EXISTS public.game_settings (
  id TEXT PRIMARY KEY DEFAULT 'settings_01',
  marketplace_visible BOOLEAN NOT NULL DEFAULT false,
  marketplace_active BOOLEAN NOT NULL DEFAULT false,
  activated_at TIMESTAMPTZ DEFAULT NULL,
  activated_by UUID DEFAULT NULL,
  cornhole_special_bye_team_id UUID DEFAULT NULL,
  boxe_special_bye_team_id UUID DEFAULT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 15. POSTERS
CREATE TABLE IF NOT EXISTS public.posters (
  id TEXT PRIMARY KEY,
  file_name TEXT NOT NULL,
  titolo TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.team_posters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  poster_id TEXT NOT NULL REFERENCES public.posters(id),
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(team_id)
);

-- 16. USER ROLES (FOR AUTH RLS)
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'team')),
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, role)
);

-- ============================================================================
-- ATOMIC TRANSACTIONAL RPC FUNCTIONS (POSTGRESQL)
-- ============================================================================

-- Function: has_role
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Admin bypass check
  IF _user_id = '11111111-1111-1111-1111-111111111111'::UUID AND _role = 'admin' THEN
    RETURN TRUE;
  END IF;
  
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = _user_id AND role = _role
  );
END;
$$;

-- Function: buy_marketplace_item (ATOMIC WITH LOCK AND FULL EFFECTS)
CREATE OR REPLACE FUNCTION public.buy_marketplace_item(
  p_item_id text, 
  p_target_team_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_team_id UUID;
  v_team RECORD;
  v_item RECORD;
  v_settings RECORD;
  v_target_shield RECORD;
  v_target_team_name TEXT;
  v_stage_id UUID;
  v_roll INTEGER;
  v_label TEXT := '';
  v_points INTEGER := 0;
  v_tokens INTEGER := 0;
  v_dave_help BOOLEAN := false;
  v_dettagli JSONB := '{}'::jsonb;
  v_tx_id UUID := gen_random_uuid();
  v_target_points INTEGER := 0;
  v_buyer_points INTEGER := 0;
  v_points_stolen INTEGER := 0;
  v_points_deducted INTEGER := 0;
  v_buyer_diff INTEGER := 0;
  v_target_diff INTEGER := 0;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_team FROM public.teams WHERE id = v_team_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Squadra non trovata';
  END IF;

  SELECT * INTO v_settings FROM public.game_settings LIMIT 1;
  IF FOUND AND (NOT v_settings.marketplace_active OR NOT v_settings.marketplace_visible) THEN
    RAISE EXCEPTION 'Il Marketplace è attualmente chiuso';
  END IF;

  SELECT * INTO v_item FROM public.marketplace_items WHERE id = p_item_id AND disponibile = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Articolo non disponibile o inesistente';
  END IF;

  IF v_team.token_balance < v_item.costo_token THEN
    RAISE EXCEPTION 'Token insufficienti';
  END IF;

  SELECT id INTO v_stage_id 
  FROM public.stages 
  WHERE stato IN ('open', 'in_progress') 
  ORDER BY numero_tappa 
  LIMIT 1;

  IF v_stage_id IS NULL THEN
    SELECT id INTO v_stage_id 
    FROM public.stages 
    ORDER BY numero_tappa 
    LIMIT 1;
  END IF;

  IF LOWER(v_item.tipo) = 'malus' THEN
    IF p_target_team_id IS NULL THEN
      RAISE EXCEPTION 'Devi selezionare una squadra bersaglio per questo Malus';
    END IF;
    IF p_target_team_id = v_team_id THEN
      RAISE EXCEPTION 'Non puoi lanciare un Malus contro la tua stessa squadra';
    END IF;

    SELECT nome_squadra INTO v_target_team_name 
    FROM public.teams 
    WHERE id = p_target_team_id AND active = true;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Squadra bersaglio non trovata o non attiva';
    END IF;
  END IF;

  UPDATE public.teams
  SET token_balance = token_balance - v_item.costo_token
  WHERE id = v_team_id;

  IF LOWER(v_item.tipo) = 'malus' THEN
    SELECT * INTO v_target_shield
    FROM public.marketplace_transactions
    WHERE team_id = p_target_team_id
      AND marketplace_item_id = 'bonus_scudo'
      AND stato = 'completed'
    ORDER BY data_acquisto ASC
    LIMIT 1;

    IF FOUND THEN
      UPDATE public.marketplace_transactions
      SET stato = 'used', 
          data_utilizzo = now(),
          dettagli = jsonb_build_object('consumed_at', now(), 'blocked_attacker_id', v_team_id)
      WHERE id = v_target_shield.id;

      INSERT INTO public.marketplace_transactions (
        id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
      )
      VALUES (
        v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'blocked', now(), now(), 
        jsonb_build_object('blocked_by_shield', true, 'target_team_id', p_target_team_id)
      );

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'malus_blocked', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'Il Malus "' || v_item.nome || '" lanciato da "' || v_team.nome_squadra || '" contro "' || v_target_team_name || '" è stato BLOCCATO dallo Scudo.')
      );

      RETURN jsonb_build_object(
        'success', true, 
        'blockedByShield', true, 
        'shielded', true, 
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    END IF;
  END IF;

  IF p_item_id = 'ruota_fortuna' THEN
    v_roll := floor(random() * 100) + 1;

    IF v_roll <= 3 THEN
      v_outcome_id := 'jackpot'; v_label := '🏆 JACKPOT (+20 PT)'; v_points := 20;
    ELSIF v_roll <= 6 THEN
      v_outcome_id := 'dave_help'; v_label := '🧠 AIUTO DAVE 📞'; v_dave_help := true;
    ELSIF v_roll <= 13 THEN
      v_outcome_id := 'mega_bonus'; v_label := '💎 MEGA (+15 PT)'; v_points := 15;
    ELSIF v_roll <= 25 THEN
      v_outcome_id := 'bonus'; v_label := '⭐ BONUS (+10 PT)'; v_points := 10;
    ELSIF v_roll <= 45 THEN
      v_outcome_id := 'piccolo_bonus'; v_label := '🎁 PICCOLO (+5 PT)'; v_points := 5;
    ELSIF v_roll <= 55 THEN
      v_outcome_id := 'gettoni_bonus'; v_label := '🪙 GETTONI (+10 TK)'; v_tokens := 10;
    ELSIF v_roll <= 65 THEN
      v_outcome_id := 'doppio_premio'; v_label := '🎯 DOPPIO (+5/5)'; v_points := 5; v_tokens := 5;
    ELSIF v_roll <= 80 THEN
      v_outcome_id := 'fortuna'; v_label := '🍀 FORTUNA (+5 TK)'; v_tokens := 5;
    ELSE
      v_outcome_id := 'sorpresa'; v_label := '🎉 SORPRESA (+3 PT)'; v_points := 3;
    END IF;

    v_dettagli := jsonb_build_object(
      'id', v_outcome_id,
      'roll', v_roll,
      'outcome_label', v_label,
      'outcome_points', v_points,
      'outcome_tokens', v_tokens,
      'dave_help', v_dave_help
    );
  ELSIF p_item_id = 'enigma_extra' THEN
    v_dettagli := jsonb_build_object(
      'enigma_name', 'Il Codice del Viaggiatore',
      'assigned_at', now(),
      'solution', 'LANTERNA',
      'solved_at', NULL
    );
  END IF;

  INSERT INTO public.marketplace_transactions (
    id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, dettagli
  )
  VALUES (
    v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'completed', now(), v_dettagli
  );

  IF p_item_id = 'bonus_punti' THEN
    INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_stage_id, 20, 'bonus_punti', 'Bonus Punti acquistato (+20 PT)');
  END IF;

  IF p_item_id = 'ruota_fortuna' THEN
    IF v_points > 0 THEN
      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_stage_id, v_points, 'bonus_punti', 'Ruota della Fortuna: ' || v_label);
    END IF;
    IF v_tokens > 0 THEN
      UPDATE public.teams
      SET token_balance = token_balance + v_tokens
      WHERE id = v_team_id;
    END IF;

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES (
      'ruota_fortuna_spin', v_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha girato la Ruota della Fortuna ed ha ottenuto: ' || v_label)
    );

    RETURN jsonb_build_object(
      'success', true, 
      'outcome', jsonb_build_object(
        'id', v_outcome_id,
        'roll', v_roll,
        'outcome_label', v_label,
        'outcome_points', v_points,
        'outcome_tokens', v_tokens,
        'dave_help', v_dave_help
      ),
      'new_balance', v_team.token_balance - v_item.costo_token + v_tokens
    );
  END IF;

  IF LOWER(v_item.tipo) = 'malus' THEN
    INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
    VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Malus ' || v_item.nome || ' attivato.', v_tx_id, p_item_id);

    IF p_item_id = 'freeze_2min' THEN
      UPDATE public.teams
      SET 
        freeze_started_at = now(),
        freeze_expires_at = now() + INTERVAL '120 seconds',
        freeze_duration_seconds = 120
      WHERE id = p_target_team_id;

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'team_frozen', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'La squadra "' || v_target_team_name || '" è stata congelata da "' || v_team.nome_squadra || '" per 120 secondi!')
      );
    ELSIF p_item_id = 'enigma_extra' THEN
      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'enigma_extra_assigned', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'La squadra "' || v_target_team_name || '" ha ricevuto un Enigma Extra da "' || v_team.nome_squadra || '"!')
      );
    ELSIF p_item_id = 'ruota_sfortunata' THEN
      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'ruota_sfortunata_assigned', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'La squadra "' || v_target_team_name || '" ha subito un Malus Ruota Sfortunata da "' || v_team.nome_squadra || '"!')
      );
    ELSIF p_item_id = 'trappola' THEN
      SELECT COALESCE(SUM(punti), 0) INTO v_target_points FROM public.scores WHERE team_id = p_target_team_id;
      SELECT COALESCE(SUM(punti), 0) INTO v_buyer_points FROM public.scores WHERE team_id = v_team_id;
      v_points_stolen := LEAST(30, GREATEST(0, v_target_points));

      IF v_points_stolen > 0 THEN
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (p_target_team_id, v_stage_id, -v_points_stolen, 'penalty', 'Malus Trappola: sottratti −' || v_points_stolen::text || ' PT da ' || v_team.nome_squadra);

        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (v_team_id, v_stage_id, v_points_stolen, 'bonus_punti', 'Malus Trappola: rubati +' || v_points_stolen::text || ' PT a ' || v_target_team_name);
      END IF;

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'trappola_used', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha attivato la TRAPPOLA contro "' || v_target_team_name || '" rubando ' || v_points_stolen::text || ' PT.')
      );

      RETURN jsonb_build_object(
        'success', true, 
        'outcome', jsonb_build_object(
          'points_stolen', v_points_stolen,
          'target_points_before', v_target_points,
          'target_points_after', GREATEST(0, v_target_points - v_points_stolen),
          'buyer_points_before', v_buyer_points,
          'buyer_points_after', v_buyer_points + v_points_stolen
        ),
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    ELSIF p_item_id = 'penalita_punti' THEN
      SELECT COALESCE(SUM(punti), 0) INTO v_target_points FROM public.scores WHERE team_id = p_target_team_id;
      v_points_deducted := LEAST(20, GREATEST(0, v_target_points));

      IF v_points_deducted > 0 THEN
        INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (p_target_team_id, v_stage_id, -v_points_deducted, 'penalty', 'Malus Penalità Punti: sottratti −' || v_points_deducted::text || ' PT da ' || v_team.nome_squadra);
      END IF;

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'penalita_punti_used', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha inflitto una PENALITÀ PUNTI contro "' || v_target_team_name || '" sottraendo ' || v_points_deducted::text || ' PT.')
      );

      RETURN jsonb_build_object(
        'success', true, 
        'outcome', jsonb_build_object(
          'points_deducted', v_points_deducted,
          'target_points_before', v_target_points,
          'target_points_after', GREATEST(0, v_target_points - v_points_deducted)
        ),
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    ELSIF p_item_id = 'tassa_passaggio' THEN
      SELECT COALESCE(SUM(punti), 0) INTO v_buyer_points FROM public.scores WHERE team_id = v_team_id;
      SELECT COALESCE(SUM(punti), 0) INTO v_target_points FROM public.scores WHERE team_id = p_target_team_id;

      v_buyer_diff := v_target_points - v_buyer_points;
      v_target_diff := v_buyer_points - v_target_points;

      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_stage_id, v_buyer_diff, 'bonus_punti', 'Tassa di Passaggio: scambiati ' || v_buyer_points::text || ' PT con ' || v_target_points::text || ' PT di ' || v_target_team_name);

      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, v_stage_id, v_target_diff, 'penalty', 'Tassa di Passaggio: scambiati ' || v_target_points::text || ' PT con ' || v_buyer_points::text || ' PT di ' || v_team.nome_squadra);

      INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
      VALUES (
        'tassa_passaggio_used', v_team_id, p_target_team_id, 
        jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha attivato la TASSA DI PASSAGGIO scambiando i suoi ' || v_buyer_points::text || ' PT con i ' || v_target_points::text || ' PT di "' || v_target_team_name || '".')
      );

      RETURN jsonb_build_object(
        'success', true, 
        'outcome', jsonb_build_object(
          'buyer_points_before', v_buyer_points,
          'buyer_points_after', v_target_points,
          'target_points_before', v_target_points,
          'target_points_after', v_buyer_points
        ),
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'shielded', false, 'new_balance', v_team.token_balance - v_item.costo_token);
END;
$$;

-- Function: execute_switch_punti (ATOMIC SCORE SWAP)
CREATE OR REPLACE FUNCTION public.execute_switch_punti(
  p_actor_team_id UUID,
  p_target_team_id UUID,
  p_stage_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_score_a INTEGER := 0;
  v_score_b INTEGER := 0;
  v_catt_a INTEGER := 0;
  v_catt_b INTEGER := 0;
  v_total_a INTEGER := 0;
  v_total_b INTEGER := 0;
  v_delta_a INTEGER := 0;
  v_delta_b INTEGER := 0;
  v_name_a TEXT;
  v_name_b TEXT;
BEGIN
  -- Lock both teams
  SELECT nome_squadra INTO v_name_a FROM public.teams WHERE id = p_actor_team_id FOR UPDATE;
  SELECT nome_squadra INTO v_name_b FROM public.teams WHERE id = p_target_team_id FOR UPDATE;

  -- Calculate Total A
  SELECT COALESCE(SUM(punti), 0) INTO v_score_a FROM public.scores WHERE team_id = p_actor_team_id;
  SELECT COALESCE(SUM(punti), 0) INTO v_catt_a FROM public.cattiveria_ledger WHERE team_id = p_actor_team_id;
  v_total_a := GREATEST(0, v_score_a + v_catt_a);

  -- Calculate Total B
  SELECT COALESCE(SUM(punti), 0) INTO v_score_b FROM public.scores WHERE team_id = p_target_team_id;
  SELECT COALESCE(SUM(punti), 0) INTO v_catt_b FROM public.cattiveria_ledger WHERE team_id = p_target_team_id;
  v_total_b := GREATEST(0, v_score_b + v_catt_b);

  v_delta_a := v_total_b - v_total_a;
  v_delta_b := v_total_a - v_total_b;

  -- Insert compensating scores
  INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_actor_team_id, p_stage_id, v_delta_a, 'switch_punti', 'Switch eseguito contro ' || v_name_b);

  INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_target_team_id, p_stage_id, v_delta_b, 'switch_punti', 'Punteggio scambiato da ' || v_name_a);

  RETURN jsonb_build_object(
    'success', true,
    'actor_old_total', v_total_a,
    'actor_new_total', v_total_b,
    'target_old_total', v_total_b,
    'target_new_total', v_total_a
  );
END;
$$;

-- Function: play_jackpot (ATOMIC SLOT MULTIPLIER)
CREATE OR REPLACE FUNCTION public.play_jackpot(
  p_team_id UUID,
  p_bet_points INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rand NUMERIC;
  v_mult NUMERIC;
  v_delta INTEGER;
BEGIN
  IF p_bet_points <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Puntata non valida');
  END IF;

  v_rand := random();
  IF v_rand < 0.30 THEN
    v_mult := 0.0;
  ELSIF v_rand < 0.70 THEN
    v_mult := 0.5;
  ELSIF v_rand < 0.90 THEN
    v_mult := 1.5;
  ELSIF v_rand < 0.98 THEN
    v_mult := 2.0;
  ELSE
    v_mult := 3.0;
  END IF;

  v_delta := round(p_bet_points * v_mult) - p_bet_points;

  -- Record play
  INSERT INTO public.jackpot_plays (team_id, puntata_punti, esito_moltiplicatore, delta_punti)
  VALUES (p_team_id, p_bet_points, v_mult, v_delta);

  -- Record score delta
  INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, v_delta, 'jackpot', 'Jackpot Slot Machine (' || v_mult || 'x)');

  RETURN jsonb_build_object(
    'success', true,
    'multiplier', v_mult,
    'delta', v_delta,
    'bet', p_bet_points
  );
END;
$$;

-- ============================================================================
-- RLS POLICIES & PERMISSIONS
-- ============================================================================
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cattiveria_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jackpot_plays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_penalties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_report ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_posters ENABLE ROW LEVEL SECURITY;

-- Grant broad SELECT and controlled INSERT/UPDATE for game operations
DROP POLICY IF EXISTS "Public Read All" ON public.teams;
CREATE POLICY "Public Read All" ON public.teams FOR SELECT USING (true);
CREATE POLICY "Public Update Teams" ON public.teams FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Stages" ON public.stages;
CREATE POLICY "Public Stages" ON public.stages FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Challenges" ON public.challenges;
CREATE POLICY "Public Challenges" ON public.challenges FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Progress" ON public.team_progress;
CREATE POLICY "Public Progress" ON public.team_progress FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Scores" ON public.scores;
CREATE POLICY "Public Scores" ON public.scores FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Marketplace Items" ON public.marketplace_items;
CREATE POLICY "Public Marketplace Items" ON public.marketplace_items FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Marketplace Tx" ON public.marketplace_transactions;
CREATE POLICY "Public Marketplace Tx" ON public.marketplace_transactions FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Cattiveria" ON public.cattiveria_ledger;
CREATE POLICY "Public Cattiveria" ON public.cattiveria_ledger FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Jackpot" ON public.jackpot_plays;
CREATE POLICY "Public Jackpot" ON public.jackpot_plays FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Submissions" ON public.submissions;
CREATE POLICY "Public Submissions" ON public.submissions FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Penalties" ON public.time_penalties;
CREATE POLICY "Public Penalties" ON public.time_penalties FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Log" ON public.activity_log;
CREATE POLICY "Public Log" ON public.activity_log FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Report" ON public.game_report;
CREATE POLICY "Public Report" ON public.game_report FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Settings" ON public.game_settings;
CREATE POLICY "Public Settings" ON public.game_settings FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Posters" ON public.posters;
CREATE POLICY "Public Posters" ON public.posters FOR ALL USING (true);

DROP POLICY IF EXISTS "Public Team Posters" ON public.team_posters;
CREATE POLICY "Public Team Posters" ON public.team_posters FOR ALL USING (true);

-- STORAGE BUCKET
INSERT INTO storage.buckets (id, name, public) 
VALUES ('team-media', 'team-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public Read Team Media" ON storage.objects;
CREATE POLICY "Public Read Team Media" ON storage.objects FOR SELECT USING (bucket_id = 'team-media');
DROP POLICY IF EXISTS "Authenticated/Anon Insert Team Media" ON storage.objects;
CREATE POLICY "Authenticated/Anon Insert Team Media" ON storage.objects FOR ALL USING (bucket_id = 'team-media');

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- TEAMS
INSERT INTO public.teams (id, nome_squadra, colore, token_balance, active) VALUES 
('676dfae3-e0c8-4d50-8555-b5a61472522a', 'Fost & Loud', '#f97316', 80, true),
('155e40fe-29ea-47dc-8f23-37f3fa560049', 'Ciccioni Bislunghi', '#84cc16', 80, true)
ON CONFLICT (id) DO UPDATE SET token_balance = EXCLUDED.token_balance;

-- STAGES
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES 
('4a57212e-7e83-430c-b5fe-6cf38db7be2e', 1, 'Il Passaporto di Bra', 'Piazza Caduti per la Libertà, 14', 44.6982, 7.8507, 'open', NULL),
('dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 2, 'Il Rebus Visivo', 'Via Mendicità Istruita, 12', 44.6976, 7.8544, 'open', NULL),
('3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 3, 'La Banca', 'Stazione Ferroviaria di Bra', 44.6946, 7.8542, 'open', NULL),
('4b4b4c4d-5e5f-6061-7172-838485868788', 4, 'Enigmi', 'Risolvi gli enigmi e inserisci le soluzioni per avanzare.', NULL, NULL, 'open', NULL),
('5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 5, 'Tappa Finale', 'Traguardo finale della gara! Raggiungete la destinazione.', 44.71631488741777, 7.842901351857487, 'open', NULL)
ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, numero_tappa = EXCLUDED.numero_tappa;

-- CHALLENGES
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES 
('81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Creazione squadra', 'Scegliete nome, motto, avatar e colore della vostra squadra.', 'team_setup', 5, 1, '{}'::jsonb),
('c4e6c385-69ba-4f17-a6d0-36b78776d527', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Quiz Bra', 'Rispondete alle domande sulla città di Bra.', 'quiz', 15, 2, '{}'::jsonb),
('0147e750-f0a3-4b72-8e76-a003fe2ef143', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Foto ufficiale', 'Scattate la foto ufficiale della squadra.', 'photo', 10, 3, '{}'::jsonb),
('999f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Il Rebus Visivo', 'Raggiungete il luogo rappresentato dal simbolo.', 'photo', 25, 1, '{}'::jsonb),
('777f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Indovina il film dalle emoji', 'Viaggiatori, si spengono le luci, si alza il sipario: benvenuti nella sala più insolita della caccia!', 'emoji_movies', 15, 2, '{}'::jsonb),
('555f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'La locandina vivente', 'La vostra squadra ha appena ricevuto la locandina di un film iconico.', 'living_poster', 15, 3, '{}'::jsonb),
('b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'La Banca', 'Quattro indizi, quattro parole, Viaggiatori.', 'banca', 25, 1, '{}'::jsonb),
('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Missione Social', 'Dimostrate di saper comunicare con persone mai incontrate prima.', 'social', 20, 2, '{}'::jsonb),
('d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Il Codice Segreto', 'Sbloccate la destinazione finale della gara inserendo il PIN a 10 cifre.', 'codice', 15, 3, '{}'::jsonb),
('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Rebus Musicale', 'Ricevete il rebus cartaceo, scoprite le 3 note e inseritele nell''ordine corretto.', 'enigma_musicale', 5, 1, '{}'::jsonb),
('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Lucchetto Direzionale', 'Risolvete l''enigma cartaceo e ricavate la sequenza di 4 direzioni.', 'lucchetto_direzionale', 5, 2, '{}'::jsonb),
('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Le Coordinate Finali', 'Risolvete l''enigma cartaceo per ricavare le coordinate finali.', 'enigma_coordinate', 5, 3, '{}'::jsonb),
('c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Sfida Cornhole', 'Torneo fisico di Cornhole 1vs1 gestito dalla regia.', 'cornhole', 20, 1, '{}'::jsonb),
('d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Boxe Gonfiabile', 'Torneo fisico a eliminazione diretta di Boxe Gonfiabile 1vs1.', 'boxe', 20, 2, '{}'::jsonb),
('f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Jackpot della Regia', 'Sfida Bonus opzionale. Sfida la fortuna alla slot machine scommettendo i tuoi punti.', 'jackpot', 20, 3, '{}'::jsonb)
ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;

-- MARKETPLACE ITEMS
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES 
('bonus_punti', 'BONUS PUNTI', 'bonus', 'Un grande vantaggio per scalare la classifica. Usa questo bonus nel momento decisivo.', 40, '', '', true, '{}'::jsonb),
('bonus_scudo', 'BONUS SCUDO', 'bonus', 'Uno scudo invisibile protegge il vostro viaggio dagli attacchi degli avversari.', 35, '', '', true, '{}'::jsonb),
('ruota_fortuna', 'RUOTA DELLA FORTUNA', 'bonus', 'La fortuna decide il vostro destino. Siete pronti a rischiare?', 25, '', '', true, '{}'::jsonb),
('passaparola', 'PASSAPAROLA', 'bonus', 'Permette di chiamare l''organizzatore una volta per ricevere un indizio extra SÌ/NO su qualsiasi enigma bloccato.', 20, '', '', true, '{}'::jsonb),
('bonus_classifica', 'BONUS CLASSIFICA', 'bonus', 'Visualizza temporaneamente la classifica generale.', 30, '', '', true, '{}'::jsonb),
('partenza_anticipata', 'PARTENZA ANTICIPATA', 'bonus', '-2 minuti sulla partenza. Comunica alla Regia per utilizzarlo.', 35, '', '', true, '{}'::jsonb),
('freeze_2min', 'FREEZE 2 MINUTI', 'malus', 'Il tempo si ferma per i vostri rivali.', 20, '', '', true, '{}'::jsonb),
('enigma_extra', 'ENIGMA EXTRA', 'malus', 'Un ostacolo mentale per rallentare chi vi precede.', 25, '', '', true, '{}'::jsonb),
('ruota_sfortunata', 'RUOTA SFORTUNATA', 'malus', 'La sfortuna colpisce duro. Fate girare la ruota a chi vi sta davanti.', 20, '', '', true, '{}'::jsonb),
('trappola', 'TRAPPOLA', 'malus', 'Una trappola invisibile per far inciampare gli avversari.', 40, '', '', true, '{}'::jsonb),
('penalita_punti', 'PENALITÀ PUNTI', 'malus', 'Sottrae 20 punti all''avversario.', 30, '', '', true, '{}'::jsonb),
('tassa_passaggio', 'TASSA DI PASSAGGIO', 'malus', 'Scambia i punti della tua squadra con quelli di un''altra squadra.', 70, '', '', true, '{}'::jsonb)
ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;

-- POSTERS
INSERT INTO public.posters (id, file_name, titolo, active) VALUES
('poster_01', 'Poster1.jpg', 'Indiana Jones', true),
('poster_02', 'Poster2.jpg', 'Back to the Future', true),
('poster_03', 'Poster3.jpg', 'Star Wars', true),
('poster_04', 'Poster4.jpg', 'Jurassic Park', true),
('poster_05', 'Poster5.jpg', 'Titanic', true),
('poster_06', 'Poster6.jpg', 'Pulp Fiction', true),
('poster_07', 'Poster7.jpg', 'The Matrix', true),
('poster_08', 'Poster8.jpg', 'Forrest Gump', true),
('poster_09', 'Poster9.jpg', 'E.T.', true),
('poster_10', 'Poster10.jpg', 'The Godfather', true)
ON CONFLICT (id) DO UPDATE SET file_name = EXCLUDED.file_name, titolo = EXCLUDED.titolo;

-- GAME REPORT
INSERT INTO public.game_report (id, state, published_at, published_by, snapshot) 
VALUES ('current', 'PRIVATE_LIVE', NULL, NULL, NULL) 
ON CONFLICT (id) DO NOTHING;

-- GAME SETTINGS
INSERT INTO public.game_settings (id, marketplace_visible, marketplace_active) 
VALUES ('settings_01', false, false) 
ON CONFLICT (id) DO NOTHING;
