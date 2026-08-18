-- ============================================================================
-- PECHINO EXPRESS BRA — ALL-IN-ONE IDEMPOTENT PRODUCTION SETUP & RESTORE
-- File: supabase/migrations/02_pechino_bra_restore_hardened.sql
-- Target: PostgreSQL 15+ (Supabase)
-- Safe to run on empty DB or existing DB (No data loss)
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- STEP 1: CREAZIONE TABELLE DI BASE (SE MANCANTI) & COLONNE
-- ----------------------------------------------------------------------------

-- 1. SQUADRE (TEAMS)
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_squadra TEXT NOT NULL UNIQUE,
  colore TEXT NOT NULL DEFAULT '#ea580c',
  token_balance INTEGER NOT NULL DEFAULT 50 CHECK (token_balance >= 0),
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Aggiunta colonne a teams (se mancanti)
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '🏳️';
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS motto TEXT DEFAULT 'In corsa per la vittoria!';
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS owner_id UUID;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS freeze_started_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS freeze_expires_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS freeze_duration_seconds INTEGER DEFAULT 0;

-- Sincronizzazione colonne colore/color
UPDATE public.teams SET color = colore WHERE color IS NULL;

-- 2. TAPPE (STAGES)
CREATE TABLE IF NOT EXISTS public.stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_tappa INTEGER NOT NULL UNIQUE,
  titolo TEXT NOT NULL,
  descrizione TEXT,
  latitude NUMERIC(10, 7) DEFAULT NULL,
  longitude NUMERIC(10, 7) DEFAULT NULL,
  stato TEXT NOT NULL DEFAULT 'open' CHECK (stato IN ('locked', 'open', 'in_progress', 'completed', 'closed')),
  outcome JSONB DEFAULT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure stages columns exist
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 7) DEFAULT NULL;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS longitude NUMERIC(10, 7) DEFAULT NULL;
ALTER TABLE public.stages ADD COLUMN IF NOT EXISTS outcome JSONB DEFAULT NULL;

-- 3. SFIDE (CHALLENGES)
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stage_id UUID NOT NULL REFERENCES public.stages(id) ON DELETE CASCADE,
  titolo TEXT NOT NULL,
  descrizione TEXT,
  tipo_sfida TEXT NOT NULL,
  punteggio_massimo INTEGER NOT NULL DEFAULT 100,
  ordine_sfida INTEGER NOT NULL,
  configurazione JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. PROGRESSO SQUADRE (TEAM PROGRESS)
CREATE TABLE IF NOT EXISTS public.team_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  stato TEXT NOT NULL DEFAULT 'locked' CHECK (stato IN ('locked', 'in_progress', 'completed')),
  completata_il TIMESTAMPTZ DEFAULT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (team_id, challenge_id)
);

-- 5. PUNTEGGI & MODIFICATORI (SCORES)
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

ALTER TABLE public.marketplace_items ADD COLUMN IF NOT EXISTS effetto TEXT;

-- 7. MARKETPLACE TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.marketplace_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  marketplace_item_id TEXT NOT NULL REFERENCES public.marketplace_items(id),
  target_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  costo_token INTEGER NOT NULL,
  stato TEXT NOT NULL DEFAULT 'completed' CHECK (stato IN ('completed', 'used', 'viewing', 'expired', 'pending')),
  data_acquisto TIMESTAMPTZ NOT NULL DEFAULT now(),
  data_utilizzo TIMESTAMPTZ DEFAULT NULL,
  dettagli JSONB DEFAULT '{}'::jsonb
);

-- 8. PUNTI CATTIVERIA LEDGER
CREATE TABLE IF NOT EXISTS public.cattiveria_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('MALUS_UTILIZZATO', 'SCUDO_ATTIVATO', 'MALUS_SUBITO_DIFESO', 'FINE_TAPPA_CATTIVERIA')),
  marketplace_item_id TEXT REFERENCES public.marketplace_items(id),
  riferimento_transazione UUID REFERENCES public.marketplace_transactions(id) ON DELETE SET NULL,
  punti INTEGER NOT NULL,
  motivo TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. JACKPOT DELLA REGIA
CREATE TABLE IF NOT EXISTS public.jackpot_plays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  puntata_punti INTEGER NOT NULL,
  esito_moltiplicatore NUMERIC NOT NULL,
  delta_punti INTEGER NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 10. SUBMISSIONS (FOTOGRAFIE & PROVE)
CREATE TABLE IF NOT EXISTS public.submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL,
  url TEXT NOT NULL,
  latitude NUMERIC(10, 7) DEFAULT NULL,
  longitude NUMERIC(10, 7) DEFAULT NULL,
  stato_approvazione TEXT NOT NULL DEFAULT 'pending' CHECK (stato_approvazione IN ('pending', 'approved', 'rejected')),
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

-- 12. AUDIT LOG (ACTIVITY LOG)
CREATE TABLE IF NOT EXISTS public.activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_evento TEXT NOT NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  target_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  dettagli JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 13. GAME REPORT (RESOCONTO GARA & SNAPSHOT)
CREATE TABLE IF NOT EXISTS public.game_report (
  id TEXT PRIMARY KEY DEFAULT 'current',
  state TEXT NOT NULL DEFAULT 'PRIVATE_LIVE' CHECK (state IN ('PRIVATE_LIVE', 'PUBLISHED_FINAL')),
  published_at TIMESTAMPTZ DEFAULT NULL,
  published_by UUID DEFAULT NULL,
  snapshot JSONB DEFAULT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 14. POSTERS & TEAM_POSTERS
CREATE TABLE IF NOT EXISTS public.posters (
  id TEXT PRIMARY KEY,
  file_name TEXT NOT NULL,
  titolo TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.team_posters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  poster_id TEXT NOT NULL REFERENCES public.posters(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 15. USER ROLES
CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'team')),
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 16. GAME SETTINGS
CREATE TABLE IF NOT EXISTS public.game_settings (
  id TEXT PRIMARY KEY DEFAULT 'current',
  marketplace_visible BOOLEAN NOT NULL DEFAULT false,
  marketplace_active BOOLEAN NOT NULL DEFAULT false,
  activated_at TIMESTAMPTZ DEFAULT NULL,
  activated_by UUID DEFAULT NULL,
  cornhole_special_bye_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  boxe_special_bye_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- STEP 2: CREAZIONE TABELLE MANCANTI (ENIGMI, SOCIAL, QUIZ, SESSIONS, TORNEI)
-- ----------------------------------------------------------------------------

-- quiz_questions
CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer_index INTEGER NOT NULL,
  order_index INTEGER NOT NULL,
  points INTEGER NOT NULL DEFAULT 5,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Vista quiz_questions_public per mascherare correct_answer_index al client
CREATE OR REPLACE VIEW public.quiz_questions_public AS
SELECT id, challenge_id, question, options, order_index, points, created_at
FROM public.quiz_questions;

-- team_answers
CREATE TABLE IF NOT EXISTS public.team_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
  selected_answer INTEGER NOT NULL,
  correct BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (team_id, question_id)
);

-- team_members
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- race_sessions
CREATE TABLE IF NOT EXISTS public.race_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  stage_id UUID REFERENCES public.stages(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ DEFAULT NULL,
  duration_seconds INTEGER DEFAULT NULL
);

-- team_social_submissions
CREATE TABLE IF NOT EXISTS public.team_social_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  social_url TEXT NOT NULL,
  stato_approvazione TEXT NOT NULL DEFAULT 'pending' CHECK (stato_approvazione IN ('pending', 'approved', 'rejected')),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (team_id, challenge_id)
);

-- enigma_solutions
CREATE TABLE IF NOT EXISTS public.enigma_solutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE UNIQUE,
  solution_type TEXT NOT NULL CHECK (solution_type IN ('notes', 'directions', 'coordinates', 'text')),
  solution JSONB NOT NULL,
  punteggio INTEGER NOT NULL DEFAULT 20,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- enigma_attempts
CREATE TABLE IF NOT EXISTS public.enigma_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL,
  answer JSONB NOT NULL,
  is_correct BOOLEAN NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (team_id, challenge_id, attempt_number)
);

-- Tabelle tornei Cornhole
CREATE TABLE IF NOT EXISTS public.cornhole_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  round INTEGER NOT NULL,
  match_index INTEGER NOT NULL,
  team1_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  team2_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  winner_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'ready', 'completed')),
  completed_at TIMESTAMPTZ DEFAULT NULL
);

-- Tabelle tornei Boxe
CREATE TABLE IF NOT EXISTS public.boxe_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  round INTEGER NOT NULL,
  match_index INTEGER NOT NULL,
  team1_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  team2_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  winner_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'ready', 'completed')),
  completed_at TIMESTAMPTZ DEFAULT NULL
);

-- INDICI
CREATE INDEX IF NOT EXISTS idx_scores_team_id ON public.scores(team_id);
CREATE INDEX IF NOT EXISTS idx_scores_stage_id ON public.scores(stage_id);
CREATE INDEX IF NOT EXISTS idx_team_progress_team ON public.team_progress(team_id, stato);
CREATE INDEX IF NOT EXISTS idx_cattiveria_team_stage ON public.cattiveria_ledger(team_id, stage_id);
CREATE INDEX IF NOT EXISTS idx_transactions_team ON public.marketplace_transactions(team_id);
CREATE INDEX IF NOT EXISTS idx_submissions_challenge ON public.submissions(challenge_id, team_id);

-- ----------------------------------------------------------------------------
-- STEP 3: FUNZIONI RPC DI BASE (AUTHENTICATION & IDENTIFICATION)
-- ----------------------------------------------------------------------------

-- current_team_id()
CREATE OR REPLACE FUNCTION public.current_team_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  SELECT team_id INTO v_team_id
  FROM public.user_roles
  WHERE user_id = auth.uid() AND role = 'team'
  LIMIT 1;
  
  RETURN v_team_id;
END;
$$;

-- has_role()
CREATE OR REPLACE FUNCTION public.has_role(
  _user_id UUID,
  _role TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_has BOOLEAN := false;
BEGIN
  -- Admin bypass speciale
  IF _user_id = '11111111-1111-1111-1111-111111111111'::UUID THEN
    RETURN true;
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  ) INTO v_has;

  RETURN v_has;
END;
$$;

-- ----------------------------------------------------------------------------
-- STEP 4: RPC APPLICATIVE DI GIOCO (GAME LOGIC & SEGREGATION)
-- ----------------------------------------------------------------------------

-- start_challenge
CREATE OR REPLACE FUNCTION public.start_challenge(p_challenge UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_challenge_row RECORD;
  v_prev_incomplete BOOLEAN;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato come team';
  END IF;

  -- Verifica esistenza della challenge
  SELECT * INTO v_challenge_row FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sfida non esistente';
  END IF;

  -- Controllo progressione della tappa (challenge con ordine_sfida inferiore nello stesso stage)
  SELECT EXISTS(
    SELECT 1 FROM public.challenges c
    LEFT JOIN public.team_progress tp ON tp.challenge_id = c.id AND tp.team_id = v_team_id
    WHERE c.stage_id = v_challenge_row.stage_id 
      AND c.ordine_sfida < v_challenge_row.ordine_sfida
      AND (tp.stato IS NULL OR tp.stato != 'completed')
  ) INTO v_prev_incomplete;

  IF v_prev_incomplete THEN
    RAISE EXCEPTION 'Devi prima completare le sfide precedenti di questa tappa';
  END IF;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, created_at)
  VALUES (v_team_id, p_challenge, 'in_progress', now())
  ON CONFLICT (team_id, challenge_id) DO NOTHING;
END;
$$;

-- complete_challenge (SOLO ADMIN)
CREATE OR REPLACE FUNCTION public.complete_challenge(
  p_challenge UUID,
  p_team_id UUID,
  p_score INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_stage_id UUID;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = p_challenge;

  -- Aggiorna progress
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (p_team_id, p_challenge, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = now();

  -- Assegna punteggio
  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, p_challenge, v_stage_id, p_score, 'challenge_points', 'Sfida validata dalla Regia');
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_challenge(
  p_challenge UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_team RECORD;
  v_challenge RECORD;
  v_prog RECORD;
  v_already BOOLEAN := false;
  v_is_photo BOOLEAN := false;
  v_points INTEGER := 0;
  v_bonus INTEGER := 0;
  v_stage_completed BOOLEAN := false;
  v_total_stage_challenges INTEGER;
  v_completed_stage_challenges INTEGER;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_team FROM public.teams WHERE id = v_team_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Squadra non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sfida non trovata';
  END IF;

  SELECT * INTO v_prog FROM public.team_progress 
  WHERE team_id = v_team_id AND challenge_id = p_challenge;

  IF FOUND THEN
    IF v_prog.stato = 'completed' THEN
      v_already := true;
    ELSE
      UPDATE public.team_progress 
      SET stato = 'completed', completata_il = now()
      WHERE team_id = v_team_id AND challenge_id = p_challenge;
    END IF;
  ELSE
    INSERT INTO public.team_progress (team_id, stage_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, v_challenge.stage_id, p_challenge, 'completed', now());
  END IF;

  v_is_photo := (v_challenge.tipo_sfida = 'photo' OR v_challenge.tipo_sfida = 'living_poster' OR v_challenge.tipo_sfida = 'social');

  IF NOT v_is_photo THEN
    v_points := COALESCE(v_challenge.punteggio_massimo, 0);
    IF v_challenge.tipo_sfida = 'emoji_movies' THEN
      v_points := 7;
    END IF;
  END IF;

  IF NOT v_already THEN
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (
      v_team_id, 
      p_challenge, 
      v_points, 
      CASE WHEN v_is_photo THEN 'pending_approval' ELSE 'challenge_points' END, 
      CASE WHEN v_is_photo THEN 'Foto consegnata — in attesa di valutazione: ' || v_challenge.titolo ELSE 'Completamento prova: ' || v_challenge.titolo END
    );

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES (
      'challenge_completed', 
      v_team_id, 
      jsonb_build_object(
        'message', 
        CASE 
          WHEN v_is_photo THEN 'Squadra "' || v_team.nome_squadra || '" ha consegnato la prova "' || v_challenge.titolo || '" — in attesa di valutazione dalla Regia.'
          ELSE 'Squadra "' || v_team.nome_squadra || '" ha completato la prova "' || v_challenge.titolo || '".'
        END,
        'points', v_points
      )
    );

    IF p_challenge = '0147e750-f0a3-4b72-8e76-a003fe2ef143' THEN
      UPDATE public.game_settings 
      SET marketplace_visible = true 
      WHERE id = 'settings_01';

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('marketplace_discovered', NULL, jsonb_build_object('message', 'Il Marketplace è stato SCOPERTO! La voce è ora visibile a tutti i partecipanti.'));
    END IF;
  END IF;

  SELECT COUNT(*)::INTEGER INTO v_total_stage_challenges 
  FROM public.challenges 
  WHERE stage_id = v_challenge.stage_id;

  SELECT COUNT(*)::INTEGER INTO v_completed_stage_challenges 
  FROM public.team_progress 
  WHERE team_id = v_team_id AND stage_id = v_challenge.stage_id AND stato = 'completed';

  IF v_total_stage_challenges > 0 AND v_completed_stage_challenges >= v_total_stage_challenges THEN
    v_stage_completed := true;
  END IF;

  RETURN jsonb_build_object(
    'already', v_already,
    'points', v_points,
    'bonus', v_bonus,
    'stage_completed', v_stage_completed
  );
END;
$$;
CREATE OR REPLACE FUNCTION public.get_bank_state(p_team_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_answers JSONB;
  v_questions JSONB;
  v_progress RECORD;
BEGIN
  v_caller_team_id := public.current_team_id();
  -- Gli admin possono leggere lo stato di qualsiasi team, altrimenti si forza il proprio team
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  -- Risposte date
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'question_number', question_id,
    'answer', selected_answer,
    'extracted_letter', SUBSTRING(selected_answer FROM 1 FOR 1)
  )), '[]'::jsonb) INTO v_answers
  FROM public.team_answers
  WHERE team_id = p_team_id;

  -- Domande del quiz della banca
  v_questions := '[
    {"question_number": 1, "question_text": "Ha le corna ma non è un toro (6 lettere)", "length": 6},
    {"question_number": 2, "question_text": "Ci si mette sopra chi vuole riposare (7 lettere)", "length": 7},
    {"question_number": 3, "question_text": "Si lancia per fare canestro (5 lettere)", "length": 5},
    {"question_number": 4, "question_text": "In mezzo alla faccia (4 lettere)", "length": 4}
  ]'::jsonb;

  SELECT * INTO v_progress FROM public.team_progress
  WHERE team_id = p_team_id AND challenge_id = 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';

  RETURN jsonb_build_object(
    'progress', jsonb_build_object('status', COALESCE(v_progress.stato, 'locked')),
    'answers', v_answers,
    'all_questions', v_questions
  );
END;
$$;

-- submit_bank_answer
CREATE OR REPLACE FUNCTION public.submit_bank_answer(
  p_question_number INTEGER,
  p_answer TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_correct_answer TEXT;
  v_correct BOOLEAN := false;
  v_letter CHAR(1);
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Soluzioni predefinite degli enigmi della banca:
  -- 1: LUMACA (L)
  -- 2: DIVANO (D)
  -- 3: PALLA (P)
  -- 4: NASO (N)
  IF p_question_number = 1 THEN v_correct_answer := 'LUMACA';
  ELSIF p_question_number = 2 THEN v_correct_answer := 'DIVANO';
  ELSIF p_question_number = 3 THEN v_correct_answer := 'PALLA';
  ELSIF p_question_number = 4 THEN v_correct_answer := 'NASO';
  ELSE RAISE EXCEPTION 'Numero domanda non valido';
  END IF;

  v_correct := (UPPER(TRIM(p_answer)) = v_correct_answer);
  v_letter := SUBSTRING(v_correct_answer FROM 1 FOR 1);

  RETURN jsonb_build_object(
    'correct', v_correct,
    'letter', v_letter,
    'challenge_completed', false
  );
END;
$$;

-- get_secret_code_state
CREATE OR REPLACE FUNCTION public.get_secret_code_state(p_team_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_part TEXT := '12345';
  v_part_type TEXT := 'FIRST_5';
  v_has_purchased BOOLEAN := false;
  v_purchased_digits TEXT := NULL;
  v_completed BOOLEAN := false;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  -- Controlla se ha acquistato frammento
  SELECT EXISTS(
    SELECT 1 FROM public.marketplace_transactions
    WHERE team_id = p_team_id AND marketplace_item_id = 'secret_code_part' AND stato = 'completed'
  ) INTO v_has_purchased;

  SELECT EXISTS(
    SELECT 1 FROM public.team_progress
    WHERE team_id = p_team_id AND challenge_id = 'c1c2c3c4-c5c6-c7c8-c9c0-c1c2c3c4c5c6' AND stato = 'completed'
  ) INTO v_completed;

  RETURN jsonb_build_object(
    'part', jsonb_build_object('code_part', v_part, 'part_type', v_part_type),
    'match', NULL,
    'has_purchased', v_has_purchased,
    'purchased_digits', CASE WHEN v_has_purchased THEN '67890' ELSE NULL END,
    'completed', v_completed,
    'destination', 'Traguardo Finale: Piazza'
  );
END;
$$;

-- buy_secret_code_part
CREATE OR REPLACE FUNCTION public.buy_secret_code_part()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_team RECORD;
  v_cost INTEGER := 15;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_team FROM public.teams WHERE id = v_team_id FOR UPDATE;
  IF v_team.token_balance < v_cost THEN
    RAISE EXCEPTION 'Token insufficienti (Costo: 15)';
  END IF;

  UPDATE public.teams SET token_balance = token_balance - v_cost WHERE id = v_team_id;

  INSERT INTO public.marketplace_transactions (team_id, marketplace_item_id, costo_token, stato)
  VALUES (v_team_id, 'secret_code_part', v_cost, 'completed');
END;
$$;

-- submit_secret_code_pin
CREATE OR REPLACE FUNCTION public.submit_secret_code_pin(p_inserted_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_correct_pin TEXT := '1234567890'; -- Esempio
  v_correct BOOLEAN := false;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  v_correct := (p_inserted_code = v_correct_pin);

  IF v_correct THEN
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, 'c1c2c3c4-c5c6-c7c8-c9c0-c1c2c3c4c5c6', 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, 'c1c2c3c4-c5c6-c7c8-c9c0-c1c2c3c4c5c6', 30, 'challenge_points', 'Sfida PIN superata');
  END IF;

  RETURN jsonb_build_object('success', v_correct, 'message', CASE WHEN v_correct THEN 'Sbloccato!' ELSE 'Codice errato' END);
END;
$$;

-- get_social_submission
CREATE OR REPLACE FUNCTION public.get_social_submission()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_sub RECORD;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_sub FROM public.team_social_submissions WHERE team_id = v_team_id LIMIT 1;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'id', v_sub.id,
    'social_url', v_sub.social_url,
    'stato_approvazione', v_sub.stato_approvazione,
    'note', v_sub.note,
    'created_at', v_sub.created_at
  );
END;
$$;

-- submit_social_challenge
CREATE OR REPLACE FUNCTION public.submit_social_challenge(
  p_challenge_id UUID,
  p_url TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  INSERT INTO public.team_social_submissions (team_id, challenge_id, social_url, stato_approvazione)
  VALUES (v_team_id, p_challenge_id, p_url, 'pending')
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET social_url = p_url, stato_approvazione = 'pending';
END;
$$;

-- evaluate_social_challenge (SOLO ADMIN)
CREATE OR REPLACE FUNCTION public.evaluate_social_challenge(
  p_submission_id UUID,
  p_approved BOOLEAN,
  p_score INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_sub RECORD;
  v_challenge_row RECORD;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_sub FROM public.team_social_submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge_row FROM public.challenges WHERE id = v_sub.challenge_id;

  IF p_approved THEN
    UPDATE public.team_social_submissions 
    SET stato_approvazione = 'approved' 
    WHERE id = p_submission_id;

    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_sub.team_id, v_sub.challenge_id, v_challenge_row.stage_id, p_score, 'challenge_points', 'Sfida social approvata');
  ELSE
    UPDATE public.team_social_submissions 
    SET stato_approvazione = 'rejected' 
    WHERE id = p_submission_id;
  END IF;
END;
$$;

-- get_or_assign_poster
CREATE OR REPLACE FUNCTION public.get_or_assign_poster(p_team_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_poster RECORD;
  v_assigned RECORD;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  -- Controlla se ha già un poster assegnato
  SELECT * INTO v_assigned FROM public.team_posters WHERE team_id = p_team_id LIMIT 1;
  IF FOUND THEN
    SELECT * INTO v_poster FROM public.posters WHERE id = v_assigned.poster_id;
    RETURN jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo);
  END IF;

  -- Altrimenti assegna il primo poster disponibile
  SELECT p.* INTO v_poster
  FROM public.posters p
  LEFT JOIN public.team_posters tp ON tp.poster_id = p.id
  WHERE p.active = true
  GROUP BY p.id, p.file_name, p.titolo
  ORDER BY COUNT(tp.id) ASC
  LIMIT 1;

  IF FOUND THEN
    INSERT INTO public.team_posters (team_id, poster_id) VALUES (p_team_id, v_poster.id);
    RETURN jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo);
  END IF;

  RETURN NULL;
END;
$$;

-- evaluate_poster (SOLO ADMIN)
CREATE OR REPLACE FUNCTION public.evaluate_poster(
  p_submission_id UUID,
  p_approved BOOLEAN,
  p_score INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_sub RECORD;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  IF p_approved THEN
    UPDATE public.submissions 
    SET stato_approvazione = 'approved', note = 'Voto locandina: ' || p_score::text
    WHERE id = p_submission_id;

    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_sub.team_id, v_sub.challenge_id, p_score, 'challenge_points', 'Valutazione Locandina Vivente');
  ELSE
    UPDATE public.submissions 
    SET stato_approvazione = 'rejected'
    WHERE id = p_submission_id;
  END IF;
END;
$$;

-- confirm_photo_score (SOLO ADMIN)
CREATE OR REPLACE FUNCTION public.confirm_photo_score(
  p_submission_id UUID,
  p_score INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_sub RECORD;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  UPDATE public.submissions SET stato_approvazione = 'approved' WHERE id = p_submission_id;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = now();

  INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, p_score, 'challenge_points', 'Punteggio foto confermato');
END;
$$;

-- submit_enigma_answer
CREATE OR REPLACE FUNCTION public.submit_enigma_answer(
  p_challenge_id UUID,
  p_answer JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_solution RECORD;
  v_already_completed BOOLEAN;
  v_attempt_count INTEGER;
  v_is_correct BOOLEAN := false;
  v_penalty INTEGER := -8;
  v_team_name TEXT;
  v_challenge_title TEXT;
  v_stage_id UUID;
  v_notes_correct TEXT[];
  v_notes_submitted TEXT[];
  v_dirs_correct TEXT[];
  v_dirs_submitted TEXT[];
  v_lat_correct TEXT;
  v_lng_correct TEXT;
  v_lat_submitted TEXT;
  v_lng_submitted TEXT;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato come team');
  END IF;

  SELECT * INTO v_solution FROM public.enigma_solutions WHERE challenge_id = p_challenge_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Enigma non configurato');
  END IF;

  SELECT titolo, stage_id INTO v_challenge_title, v_stage_id FROM public.challenges WHERE id = p_challenge_id;

  SELECT EXISTS(
    SELECT 1 FROM public.team_progress 
    WHERE team_id = v_team_id AND challenge_id = p_challenge_id AND stato = 'completed'
  ) INTO v_already_completed;

  IF v_already_completed THEN
    RETURN jsonb_build_object(
      'is_correct', true,
      'already_completed', true,
      'attempt_number', 0,
      'points', v_solution.punteggio
    );
  END IF;

  -- Lock concorrente sul team
  PERFORM 1 FROM public.teams WHERE id = v_team_id FOR UPDATE;

  SELECT COUNT(*) INTO v_attempt_count FROM public.enigma_attempts
  WHERE team_id = v_team_id AND challenge_id = p_challenge_id;
  v_attempt_count := v_attempt_count + 1;

  -- Valutazione a seconda del tipo
  IF v_solution.solution_type = 'notes' THEN
    SELECT ARRAY(SELECT jsonb_array_elements_text(v_solution.solution)) INTO v_notes_correct;
    SELECT ARRAY(SELECT jsonb_array_elements_text(p_answer)) INTO v_notes_submitted;
    
    IF array_length(v_notes_correct, 1) = array_length(v_notes_submitted, 1) THEN
      v_is_correct := true;
      FOR i IN 1..array_length(v_notes_correct, 1) LOOP
        IF LOWER(v_notes_correct[i]) != LOWER(v_notes_submitted[i]) THEN
          v_is_correct := false;
        END IF;
      END LOOP;
    END IF;

  ELSIF v_solution.solution_type = 'directions' THEN
    SELECT ARRAY(SELECT jsonb_array_elements_text(v_solution.solution)) INTO v_dirs_correct;
    SELECT ARRAY(SELECT jsonb_array_elements_text(p_answer)) INTO v_dirs_submitted;

    IF array_length(v_dirs_correct, 1) = array_length(v_dirs_submitted, 1) THEN
      v_is_correct := true;
      FOR i IN 1..array_length(v_dirs_correct, 1) LOOP
        IF LOWER(v_dirs_correct[i]) != LOWER(v_dirs_submitted[i]) THEN
          v_is_correct := false;
        END IF;
      END LOOP;
    END IF;

  ELSIF v_solution.solution_type = 'coordinates' THEN
    v_lat_correct := REPLACE(TRIM(v_solution.solution->>'lat'), ',', '.');
    v_lng_correct := REPLACE(TRIM(v_solution.solution->>'lng'), ',', '.');
    v_lat_submitted := REPLACE(TRIM(p_answer->>'lat'), ',', '.');
    v_lng_submitted := REPLACE(TRIM(p_answer->>'lng'), ',', '.');

    v_is_correct := (v_lat_correct = v_lat_submitted AND v_lng_correct = v_lng_submitted);
  ELSE
    v_is_correct := (LOWER(REGEXP_REPLACE(v_solution.solution->>0, '\s+', '', 'g')) = LOWER(REGEXP_REPLACE(p_answer->>0, '\s+', '', 'g')));
  END IF;

  -- Registra tentativo
  INSERT INTO public.enigma_attempts (team_id, challenge_id, attempt_number, answer, is_correct)
  VALUES (v_team_id, p_challenge_id, v_attempt_count, p_answer, v_is_correct);

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_team_id;

  IF v_is_correct THEN
    -- Completa sfida
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, p_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    -- Assegna punti (+20)
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, p_challenge_id, v_stage_id, v_solution.punteggio, 'challenge_points', 'Enigma risolto: ' || v_challenge_title);

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES ('enigma_solved', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team_name || '" ha risolto l''enigma "' || v_challenge_title || '" al tentativo #' || v_attempt_count, 'punti', v_solution.punteggio));
  ELSE
    -- Detrae punti (-8)
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, p_challenge_id, v_stage_id, v_penalty, 'penalty', 'Risposta enigma errata: ' || v_challenge_title);

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES ('enigma_failed', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team_name || '" ha risposto in modo errato all''enigma "' || v_challenge_title || '", subendo ' || v_penalty || ' PT.', 'punti', v_penalty));
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'is_correct', v_is_correct,
    'attempt_number', v_attempt_count,
    'points', CASE WHEN v_is_correct THEN v_solution.punteggio ELSE v_penalty END,
    'already_completed', false
  );
END;
$$;

-- submit_enigma_extra_answer
CREATE OR REPLACE FUNCTION public.submit_enigma_extra_answer(p_answer TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_tx RECORD;
  v_is_correct BOOLEAN := false;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Controlla se c'è enigma extra acquistato e non ancora consumato
  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE target_team_id = v_team_id AND marketplace_item_id = 'enigma_extra' AND stato = 'completed'
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Nessun enigma extra attivo');
  END IF;

  v_is_correct := (LOWER(TRIM(p_answer)) = 'lanterna'); -- Soluzione fissa

  IF v_is_correct THEN
    UPDATE public.marketplace_transactions SET stato = 'used', data_utilizzo = now() WHERE id = v_tx.id;
  END IF;

  RETURN jsonb_build_object('is_correct', v_is_correct);
END;
$$;

-- spin_unlucky_wheel
CREATE OR REPLACE FUNCTION public.spin_unlucky_wheel()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_tx RECORD;
  v_roll INTEGER;
  v_result TEXT;
  v_points_penalty INTEGER := 0;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE target_team_id = v_team_id AND marketplace_item_id = 'ruota_sfortunata' AND stato = 'completed'
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Nessuna ruota sfortunata in sospeso');
  END IF;

  -- Genera un esito casuale server-side (1-100)
  v_roll := floor(random() * 100) + 1;

  IF v_roll <= 30 THEN
    v_result := 'PENALITA_PUNTI_LIEVE';
    v_points_penalty := -10;
  ELSIF v_roll <= 60 THEN
    v_result := 'PENALITA_PUNTI_MEDIA';
    v_points_penalty := -20;
  ELSIF v_roll <= 80 THEN
    v_result := 'BLOCCO_PUNTI_GRAVE';
    v_points_penalty := -30;
  ELSE
    v_result := 'AIUTO_EXTRA_DAVE'; -- Premio speciale, Dave aiuta
  END IF;

  -- Registra esito ed elimina transazione
  UPDATE public.marketplace_transactions 
  SET stato = 'used', data_utilizzo = now(), dettagli = jsonb_build_object('roll', v_roll, 'result', v_result, 'penalty', v_points_penalty)
  WHERE id = v_tx.id;

  IF v_points_penalty != 0 THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_points_penalty, 'penalty', 'Esito Ruota Sfortunata (' || v_result || ')');
  END IF;

  RETURN jsonb_build_object('success', true, 'roll', v_roll, 'result', v_result, 'penalty', v_points_penalty);
END;
$$;

-- buy_marketplace_item (LOCK transazionale concorrente)
CREATE OR REPLACE FUNCTION public.buy_marketplace_item(
  p_item_id TEXT,
  p_target_team_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_team RECORD;
  v_item RECORD;
  v_tx_id UUID;
  v_shield_tx RECORD;
  
  v_roll INTEGER;
  v_label TEXT;
  v_points INTEGER := 0;
  v_tokens INTEGER := 0;
  v_dave_help BOOLEAN := false;
  v_dettagli JSONB := '{}'::jsonb;
  
  v_buyer_points INTEGER;
  v_target_points INTEGER;
  v_points_stolen INTEGER;
  v_points_deducted INTEGER;
  v_buyer_diff INTEGER;
  v_target_diff INTEGER;
  v_target_team_name TEXT;
  v_stage_id UUID;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;

  SELECT * INTO v_team FROM public.teams WHERE id = v_team_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Squadra non trovata');
  END IF;

  SELECT * INTO v_item FROM public.marketplace_items WHERE id = p_item_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Prodotto non trovato');
  END IF;

  IF v_team.token_balance < v_item.costo_token THEN
    RETURN jsonb_build_object('success', false, 'error', 'Token insufficienti');
  END IF;

  IF v_item.categoria = 'MALUS' THEN
    IF p_target_team_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'Scegli la squadra avversaria da colpire');
    END IF;
    IF p_target_team_id = v_team_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'Non puoi colpire la tua stessa squadra!');
    END IF;
    
    SELECT nome_squadra INTO v_target_team_name FROM public.teams WHERE id = p_target_team_id;
    IF NOT FOUND THEN
      RETURN jsonb_build_object('success', false, 'error', 'Squadra bersaglio non trovata.');
    END IF;

    IF p_item_id = 'freeze_2min' THEN
      IF EXISTS(SELECT 1 FROM public.teams WHERE id = p_target_team_id AND freeze_expires_at > now()) THEN
        RETURN jsonb_build_object('success', false, 'error', 'La squadra bersaglio è già congelata!');
      END IF;
    END IF;

    IF p_item_id = 'enigma_extra' THEN
      IF EXISTS(SELECT 1 FROM public.marketplace_transactions WHERE target_team_id = p_target_team_id AND marketplace_item_id = 'enigma_extra' AND stato = 'completed') THEN
        RETURN jsonb_build_object('success', false, 'error', 'La squadra bersaglio ha già un Enigma Extra attivo!');
      END IF;
    END IF;

    IF p_item_id = 'ruota_sfortunata' THEN
      IF EXISTS(SELECT 1 FROM public.marketplace_transactions WHERE target_team_id = p_target_team_id AND marketplace_item_id = 'ruota_sfortunata' AND stato = 'completed') THEN
        RETURN jsonb_build_object('success', false, 'error', 'La squadra bersaglio ha già una Ruota Sfortunata da girare!');
      END IF;
    END IF;
  END IF;

  UPDATE public.teams 
  SET token_balance = token_balance - v_item.costo_token 
  WHERE id = v_team_id;

  v_tx_id := gen_random_uuid();

  SELECT id INTO v_stage_id FROM public.stages WHERE active = true ORDER BY ordine LIMIT 1;

  IF v_item.categoria = 'MALUS' AND p_target_team_id IS NOT NULL THEN
    SELECT * INTO v_shield_tx 
    FROM public.marketplace_transactions 
    WHERE team_id = p_target_team_id AND marketplace_item_id = 'bonus_scudo' AND stato = 'completed'
    ORDER BY data_acquisto ASC
    LIMIT 1;

    IF FOUND THEN
      UPDATE public.marketplace_transactions 
      SET stato = 'used', data_utilizzo = now() 
      WHERE id = v_shield_tx.id;

      INSERT INTO public.marketplace_transactions (id, team_id, marketplace_item_id, target_team_id, costo_token, stato, dettagli)
      VALUES (v_tx_id, v_team_id, p_item_id, p_target_team_id, v_item.costo_token, 'expired', jsonb_build_object('blocked_by_shield_id', v_shield_tx.id));

      INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
      VALUES (p_target_team_id, v_stage_id, 'SCUDO_ATTIVATO', -3, 'Scudo attivato per parare il malus ' || v_item.nome, v_shield_tx.id, 'bonus_scudo');

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('malus_blocked', v_team_id, jsonb_build_object('message', 'Il Malus "' || v_item.nome || '" lanciato da "' || v_team.nome_squadra || '" contro "' || v_target_team_name || '" è stato BLOCCATO dallo Scudo.'));

      RETURN jsonb_build_object('success', true, 'shielded', true, 'new_balance', v_team.token_balance - v_item.costo_token);
    END IF;
  END IF;

  IF p_item_id = 'ruota_fortuna' THEN
    v_roll := floor(random() * 100) + 1;
    
    IF v_roll <= 3 THEN
      v_label := '🏆 JACKPOT'; v_points := 20;
    ELSIF v_roll <= 6 THEN
      v_label := '🧠 AIUTO EXTRA DI DAVE'; v_dave_help := true;
    ELSIF v_roll <= 13 THEN
      v_label := '💎 MEGA BONUS'; v_points := 15;
    ELSIF v_roll <= 25 THEN
      v_label := '⭐ BONUS'; v_points := 10;
    ELSIF v_roll <= 45 THEN
      v_label := '🎁 PICCOLO BONUS'; v_points := 5;
    ELSIF v_roll <= 55 THEN
      v_label := '🪙 GETTONI BONUS'; v_tokens := 10;
    ELSIF v_roll <= 65 THEN
      v_label := '🎯 DOPPIO PREMIO'; v_points := 5; v_tokens := 5;
    ELSIF v_roll <= 80 THEN
      v_label := '🍀 FORTUNA'; v_tokens := 5;
    ELSE
      v_label := '🎉 SORPRESA'; v_points := 3;
    END IF;

    v_dettagli := jsonb_build_object(
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

  INSERT INTO public.marketplace_transactions (id, team_id, marketplace_item_id, target_team_id, costo_token, stato, dettagli)
  VALUES (v_tx_id, v_team_id, p_item_id, p_target_team_id, v_item.costo_token, 'completed', v_dettagli);

  IF p_item_id = 'bonus_punti' THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, 20, 'bonus_punti', 'Bonus Punti acquistato (+20 PT)');
  END IF;

  IF p_item_id = 'ruota_fortuna' THEN
    IF v_points > 0 THEN
      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_points, 'bonus_punti', 'Ruota della Fortuna: ' || v_label);
    END IF;
    IF v_tokens > 0 THEN
      UPDATE public.teams 
      SET token_balance = token_balance + v_tokens 
      WHERE id = v_team_id;
    END IF;
    
    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES ('ruota_fortuna_spin', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha girato la Ruota della Fortuna ed ha ottenuto: ' || v_label));
  END IF;

  IF v_item.categoria = 'MALUS' THEN
    INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
    VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Malus ' || v_item.nome || ' attivato.', v_tx_id, p_item_id);

    IF p_item_id = 'freeze_2min' THEN
      UPDATE public.teams 
      SET 
        freeze_started_at = now(),
        freeze_expires_at = now() + INTERVAL '120 seconds',
        freeze_duration_seconds = 120
      WHERE id = p_target_team_id;

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('team_frozen', p_target_team_id, jsonb_build_object('message', 'La squadra "' || v_target_team_name || '" è stata congelata da "' || v_team.nome_squadra || '" per 120 secondi!'));
    
    ELSIF p_item_id = 'enigma_extra' THEN
      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('enigma_extra_assigned', p_target_team_id, jsonb_build_object('message', 'La squadra "' || v_target_team_name || '" ha ricevuto un Enigma Extra da "' || v_team.nome_squadra || '"!'));

    ELSIF p_item_id = 'ruota_sfortunata' THEN
      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('ruota_sfortunata_assigned', p_target_team_id, jsonb_build_object('message', 'La squadra "' || v_target_team_name || '" ha subito un Malus Ruota Sfortunata da "' || v_team.nome_squadra || '"!'));

    ELSIF p_item_id = 'trappola' THEN
      SELECT COALESCE(SUM(punti), 0) INTO v_target_points FROM public.scores WHERE team_id = p_target_team_id;
      v_points_stolen := LEAST(30, GREATEST(0, v_target_points));

      IF v_points_stolen > 0 THEN
        INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
        VALUES (p_target_team_id, -v_points_stolen, 'penalty', 'Malus Trappola: sottratti −' || v_points_stolen::text || ' PT da ' || v_team.nome_squadra);

        INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
        VALUES (v_team_id, v_points_stolen, 'bonus_punti', 'Malus Trappola: rubati +' || v_points_stolen::text || ' PT a ' || v_target_team_name);
      END IF;

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('trappola_used', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha attivato la TRAPPOLA contro "' || v_target_team_name || '" rubando ' || v_points_stolen::text || ' PT.'));

    ELSIF p_item_id = 'penalita_punti' THEN
      SELECT COALESCE(SUM(punti), 0) INTO v_target_points FROM public.scores WHERE team_id = p_target_team_id;
      v_points_deducted := LEAST(20, GREATEST(0, v_target_points));

      IF v_points_deducted > 0 THEN
        INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
        VALUES (p_target_team_id, -v_points_deducted, 'penalty', 'Malus Penalità Punti: sottratti −' || v_points_deducted::text || ' PT da ' || v_team.nome_squadra);
      END IF;

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('penalita_punti_used', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha inflitto una PENALITÀ PUNTI contro "' || v_target_team_name || '" sottraendo ' || v_points_deducted::text || ' PT.'));

    ELSIF p_item_id = 'tassa_passaggio' THEN
      SELECT COALESCE(SUM(punti), 0) INTO v_buyer_points FROM public.scores WHERE team_id = v_team_id;
      SELECT COALESCE(SUM(punti), 0) INTO v_target_points FROM public.scores WHERE team_id = p_target_team_id;

      v_buyer_diff := v_target_points - v_buyer_points;
      v_target_diff := v_buyer_points - v_target_points;

      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_buyer_diff, 'bonus_punti', 'Tassa di Passaggio: scambiati ' || v_buyer_points::text || ' PT con ' || v_target_points::text || ' PT di ' || v_target_team_name);

      INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, v_target_diff, 'penalty', 'Tassa di Passaggio: scambiati ' || v_target_points::text || ' PT con ' || v_buyer_points::text || ' PT di ' || v_team.nome_squadra);

      INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
      VALUES ('tassa_passaggio_used', v_team_id, jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha attivato la TASSA DI PASSAGGIO scambiando i suoi ' || v_buyer_points::text || ' PT con i ' || v_target_points::text || ' PT di "' || v_target_team_name || '".'));
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'shielded', false, 'new_balance', v_team.token_balance - v_item.costo_token);
END;
$$;

-- open_classifica_bonus
CREATE OR REPLACE FUNCTION public.open_classifica_bonus(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_tx RECORD;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions
  WHERE id = p_transaction_id AND team_id = v_team_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transazione non trovata';
  END IF;

  IF v_tx.marketplace_item_id != 'bonus_classifica' THEN
    RAISE EXCEPTION 'Transazione non abbinata al bonus classifica';
  END IF;

  IF v_tx.stato = 'completed' THEN
    UPDATE public.marketplace_transactions
    SET stato = 'viewing', data_utilizzo = now()
    WHERE id = p_transaction_id;
  END IF;
END;
$$;

-- consume_marketplace_transaction
CREATE OR REPLACE FUNCTION public.consume_marketplace_transaction(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used', data_utilizzo = now()
  WHERE id = p_transaction_id AND team_id = v_team_id AND stato = 'viewing';
END;
$$;

-- mark_partenza_used
CREATE OR REPLACE FUNCTION public.mark_partenza_used(p_transaction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  UPDATE public.marketplace_transactions
  SET stato = 'used', data_utilizzo = now()
  WHERE id = p_transaction_id AND team_id = v_team_id AND stato = 'completed';
END;
$$;

-- play_jackpot
CREATE OR REPLACE FUNCTION public.play_jackpot(p_puntata INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_team_points INTEGER;
  v_s1 INTEGER;
  v_s2 INTEGER;
  v_s3 INTEGER;
  v_win BOOLEAN := false;
  v_delta INTEGER;
  v_already_played BOOLEAN;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;

  IF p_puntata < 5 OR p_puntata > 20 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Puntata consentita tra 5 e 20 punti');
  END IF;

  -- Lock concorrente sul team
  PERFORM 1 FROM public.teams WHERE id = v_team_id FOR UPDATE;

  -- Verifica se ha già giocato
  SELECT EXISTS(
    SELECT 1 FROM public.jackpot_plays WHERE team_id = v_team_id
  ) INTO v_already_played;

  IF v_already_played THEN
    RETURN jsonb_build_object('success', false, 'error', 'La tua squadra ha già tentato il Jackpot della Regia');
  END IF;

  -- Calcola i punti totali del team
  SELECT COALESCE(SUM(punti), 0) INTO v_team_points FROM public.scores WHERE team_id = v_team_id;
  IF v_team_points < p_puntata THEN
    RETURN jsonb_build_object('success', false, 'error', 'Punteggio insufficiente');
  END IF;

  -- Genera tre simboli casuali (1-5)
  v_s1 := floor(random() * 5) + 1;
  v_s2 := floor(random() * 5) + 1;
  v_s3 := floor(random() * 5) + 1;

  v_win := (v_s1 = v_s2 AND v_s2 = v_s3);

  IF v_win THEN
    v_delta := p_puntata; -- Vince raddoppio puntata (+p_puntata netti)
  ELSE
    v_delta := -p_puntata; -- Perde la puntata
  END IF;

  -- Registra giocata
  INSERT INTO public.jackpot_plays (team_id, puntata_punti, esito_moltiplicatore, delta_punti)
  VALUES (v_team_id, p_puntata, CASE WHEN v_win THEN 2.0 ELSE 0.0 END, v_delta);

  -- Salva punteggio
  INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
  VALUES (v_team_id, v_delta, 'jackpot', 'Slot Jackpot della Regia');

  RETURN jsonb_build_object(
    'success', true,
    'win', v_win,
    'symbols', jsonb_build_array(v_s1, v_s2, v_s3),
    'delta', v_delta
  );
END;
$$;

-- get_secure_leaderboard
CREATE OR REPLACE FUNCTION public.get_secure_leaderboard()
RETURNS TABLE (
  team_id UUID,
  name TEXT,
  color TEXT,
  avatar_url TEXT,
  motto TEXT,
  challenges_points NUMERIC,
  modifier_points NUMERIC,
  cattiveria_points NUMERIC,
  total_points NUMERIC,
  completed_challenges BIGINT,
  total_duration_seconds NUMERIC,
  last_completion TIMESTAMPTZ,
  active BOOLEAN,
  freeze_started_at TIMESTAMPTZ,
  freeze_expires_at TIMESTAMPTZ,
  rank INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller_team_id UUID;
  v_has_bonus BOOLEAN := false;
  v_is_admin BOOLEAN := false;
BEGIN
  v_caller_team_id := public.current_team_id();
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;

  IF v_is_admin THEN
    v_has_bonus := true;
  ELSIF v_caller_team_id IS NOT NULL THEN
    -- Controlla se ha bonus classifica attivo
    SELECT EXISTS(
      SELECT 1 FROM public.marketplace_transactions
      WHERE team_id = v_caller_team_id AND marketplace_item_id = 'bonus_classifica' AND stato = 'viewing'
    ) INTO v_has_bonus;
  END IF;

  RETURN QUERY
  WITH raw_leaderboard AS (
    SELECT 
      t.id AS l_team_id,
      t.nome_squadra AS l_name,
      t.colore AS l_color,
      t.avatar_url AS l_avatar_url,
      t.motto AS l_motto,
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id AND s.challenge_id IS NOT NULL), 0)::NUMERIC AS l_ch_pts,
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id AND s.challenge_id IS NULL), 0)::NUMERIC AS l_mod_pts,
      COALESCE((SELECT SUM(cl.punti) FROM public.cattiveria_ledger cl WHERE cl.team_id = t.id), 0)::NUMERIC AS l_catt_pts,
      (
        COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) +
        COALESCE((SELECT SUM(cl.punti) FROM public.cattiveria_ledger cl WHERE cl.team_id = t.id), 0)
      )::NUMERIC AS l_tot_pts,
      COALESCE((SELECT COUNT(*) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed'), 0)::BIGINT AS l_comp_ch,
      COALESCE((SELECT SUM(minuti_penalita * 60) FROM public.time_penalties WHERE team_id = t.id), 0)::NUMERIC AS l_duration,
      (SELECT MAX(completata_il) FROM public.team_progress WHERE team_id = t.id AND stato = 'completed') AS l_last_comp,
      t.active AS l_active,
      t.freeze_started_at AS l_freeze_start,
      t.freeze_expires_at AS l_freeze_exp
    FROM public.teams t
  ),
  ranked_leaderboard AS (
    SELECT 
      *,
      ROW_NUMBER() OVER (
        ORDER BY l_active DESC, l_comp_ch DESC, l_tot_pts DESC, l_duration ASC, l_last_comp ASC NULLS LAST
      )::INTEGER AS l_rank
    FROM raw_leaderboard
  )
  SELECT 
    l_team_id, l_name, l_color, l_avatar_url, l_motto, l_ch_pts, l_mod_pts, l_catt_pts, l_tot_pts, l_comp_ch, l_duration, l_last_comp, l_active, l_freeze_start, l_freeze_exp, l_rank
  FROM ranked_leaderboard
  WHERE v_has_bonus = true OR l_team_id = v_caller_team_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- STEP 6: RPC DI AMMINISTRAZIONE (ADMIN OPERATIONS)
-- ----------------------------------------------------------------------------

-- admin_add_points
CREATE OR REPLACE FUNCTION public.admin_add_points(
  p_team_id UUID,
  p_stage_id UUID,
  p_points INTEGER,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, p_stage_id, p_points, 'bonus', p_reason);
END;
$$;

-- admin_remove_points
CREATE OR REPLACE FUNCTION public.admin_remove_points(
  p_team_id UUID,
  p_stage_id UUID,
  p_points INTEGER,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, p_stage_id, -ABS(p_points), 'penalty', p_reason);
END;
$$;

-- admin_add_tokens
CREATE OR REPLACE FUNCTION public.admin_add_tokens(
  p_team_id UUID,
  p_tokens INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.teams 
  SET token_balance = token_balance + p_tokens 
  WHERE id = p_team_id;
END;
$$;

-- admin_remove_tokens
CREATE OR REPLACE FUNCTION public.admin_remove_tokens(
  p_team_id UUID,
  p_tokens INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_current_tokens INTEGER;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT token_balance INTO v_current_tokens FROM public.teams WHERE id = p_team_id FOR UPDATE;
  
  UPDATE public.teams 
  SET token_balance = GREATEST(0, v_current_tokens - p_tokens)
  WHERE id = p_team_id;
END;
$$;

-- close_stage
CREATE OR REPLACE FUNCTION public.close_stage(p_stage_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.stages SET stato = 'closed' WHERE id = p_stage_id;
END;
$$;

-- reopen_stage
CREATE OR REPLACE FUNCTION public.reopen_stage(p_stage_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.stages SET stato = 'open' WHERE id = p_stage_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- STEP 7: ROW LEVEL SECURITY POLICIES (TEAM SEGREGATION & PRIVACY)
-- ----------------------------------------------------------------------------

-- Rimuoviamo le vecchie policy permissive di SELECT per le tabelle sensibili
DROP POLICY IF EXISTS "Public Read Progress" ON public.team_progress;
DROP POLICY IF EXISTS "Public Read Scores" ON public.scores;
DROP POLICY IF EXISTS "Public Read Transactions" ON public.marketplace_transactions;
DROP POLICY IF EXISTS "Public Read Cattiveria" ON public.cattiveria_ledger;
DROP POLICY IF EXISTS "Public Read Submissions" ON public.submissions;

-- Nuove policy di SELECT basate sul team autenticato ed admin
CREATE POLICY "Secure SELECT Progress" ON public.team_progress
  FOR SELECT USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Secure SELECT Scores" ON public.scores
  FOR SELECT USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Secure SELECT Transactions" ON public.marketplace_transactions
  FOR SELECT USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Secure SELECT Cattiveria" ON public.cattiveria_ledger
  FOR SELECT USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Secure SELECT Submissions" ON public.submissions
  FOR SELECT USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'));

-- Policy speciali di inserimento per il team autenticato
CREATE POLICY "Team INSERT Submissions" ON public.submissions
  FOR INSERT WITH CHECK (team_id = public.current_team_id());

CREATE POLICY "Team INSERT Progress" ON public.team_progress
  FOR INSERT WITH CHECK (team_id = public.current_team_id());

-- ----------------------------------------------------------------------------
-- STEP 8: INSERIMENTO DATI DI SEED COMPLETI (MANDATORY SEED)
-- ----------------------------------------------------------------------------

-- 1. STAGES SEED
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES 
('4a57212e-7e83-430c-b5fe-6cf38db7be2e', 1, 'Il Passaporto di Bra', 'Piazza Caduti per la Libertà, 14', 44.6982, 7.8507, 'open', NULL),
('dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 2, 'Il Rebus Visivo', 'Via Mendicità Istruita, 12', 44.6976, 7.8544, 'open', NULL),
('3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 3, 'La Banca', 'Stazione Ferroviaria di Bra', 44.6946, 7.8542, 'open', NULL),
('4b4b4c4d-5e5f-6061-7172-838485868788', 4, 'Enigmi', 'Risolvi gli enigmi e inserisci le soluzioni per avanzare.', NULL, NULL, 'open', NULL),
('5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 5, 'Tappa Finale', 'Traguardo finale della gara! Raggiungete la destinazione.', 44.71631488741777, 7.842901351857487, 'open', NULL)
ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;

-- 2. CHALLENGES SEED
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES 
('81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Creazione squadra', 'Scegliete nome, motto, avatar e colore della vostra squadra.', 'team_setup', 5, 1, '{}'::jsonb),
('c4e6c385-69ba-4f17-a6d0-36b78776d527', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Quiz Bra', 'Rispondete alle domande sulla città di Bra.', 'quiz', 15, 2, '{}'::jsonb),
('0147e750-f0a3-4b72-8e76-a003fe2ef143', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Foto ufficiale', 'Scattate la foto ufficiale della squadra.', 'photo', 10, 3, '{}'::jsonb),
('999f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Il Rebus Visivo', 'Raggiungete il luogo rappresentato dal simbolo.', 'photo', 25, 1, '{}'::jsonb),
('777f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Indovina il film dalle emoji', 'benvenuti nella sala più insolita della caccia!', 'emoji_movies', 15, 2, '{}'::jsonb),
('555f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'La locandina vivente', 'La vostra squadra ha appena ricevuto la locandina di un film iconico.', 'living_poster', 15, 3, '{}'::jsonb),
('b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'La Banca', 'Risolvete gli enigmi come veri enigmisti.', 'banca', 25, 1, '{}'::jsonb),
('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Missione Social', 'Capacità di comunicare e creare relazioni.', 'social', 20, 2, '{}'::jsonb),
('d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Il Codice Segreto', 'Sbloccate la destinazione finale con il PIN a 10 cifre.', 'codice', 15, 3, '{}'::jsonb),
('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Rebus Musicale', 'Scoprite le 3 note e inseritele nell''ordine corretto.', 'enigma_musicale', 20, 1, '{}'::jsonb),
('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Lucchetto Direzionale', 'Sequenza di 4 direzioni.', 'lucchetto_direzionale', 20, 2, '{}'::jsonb),
('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Le Coordinate Finali', 'Coordinate finali.', 'enigma_coordinate', 20, 3, '{}'::jsonb),
('c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Sfida Cornhole', 'Torneo fisico di Cornhole 1vs1.', 'cornhole', 20, 1, '{}'::jsonb),
('d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Boxe Gonfiabile', 'Torneo a eliminazione diretta di Boxe Gonfiabile.', 'boxe', 20, 2, '{}'::jsonb),
('f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Jackpot della Regia', 'Sfida Bonus Slot Machine.', 'jackpot', 20, 3, '{}'::jsonb)
ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;

-- 3. MARKETPLACE ITEMS SEED
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES 
('bonus_punti', 'BONUS PUNTI (+20 PT)', 'bonus', 'Aggiunge +20 PT alla classifica della squadra.', 40, '', 'Sparkles', true, '{}'::jsonb),
('bonus_scudo', 'BONUS SCUDO', 'bonus', 'Protegge la squadra da un malus attivo.', 35, '', 'Shield', true, '{}'::jsonb),
('ruota_fortuna', 'RUOTA DELLA FORTUNA', 'bonus', 'Gira la ruota per vincere premi o subire perdite casuali.', 25, '', 'Compass', true, '{}'::jsonb),
('passaparola', 'PASSAPAROLA', 'bonus', 'Ricevi un aiuto dalla regia.', 20, '', 'HelpCircle', true, '{}'::jsonb),
('bonus_classifica', 'BONUS CLASSIFICA', 'bonus', 'Permette di sbirciare la classifica.', 30, '', 'ListOrdered', true, '{}'::jsonb),
('partenza_anticipata', 'PARTENZA ANTICIPATA', 'bonus', 'Riduce di 2 minuti il tempo di partenza.', 35, '', 'Zap', true, '{}'::jsonb),
('freeze_2min', 'FREEZE 2 MINUTI', 'malus', 'Blocca una squadra avversaria per 2 minuti.', 20, '', 'Flame', true, '{}'::jsonb),
('enigma_extra', 'ENIGMA EXTRA', 'malus', 'Obbliga gli avversari a risolvere un enigma aggiuntivo.', 25, '', 'AlertTriangle', true, '{}'::jsonb),
('ruota_sfortunata', 'RUOTA SFORTUNATA', 'malus', 'Obbliga gli avversari a fare uno spin sfortunato.', 20, '', 'Skull', true, '{}'::jsonb),
('trappola', 'TRAPPOLA PUNTI', 'malus', 'Ruba 30 punti alla squadra bersaglio.', 40, '', 'Target', true, '{}'::jsonb),
('penalita_punti', 'PENALITÀ PUNTI (-20 PT)', 'malus', 'Sottrae 20 punti ad una squadra avversaria.', 30, '', 'MinusCircle', true, '{}'::jsonb),
('tassa_passaggio', 'TASSA DI PASSAGGIO', 'malus', 'Scambia i punti con quelli di un''altra squadra.', 70, '', 'TrendingUp', true, '{}'::jsonb)
ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;

-- 4. DEFAULT POSTERS FOR LIVING POSTER CHALLENGE
INSERT INTO public.posters (id, file_name, titolo, active) VALUES
('padrino', 'il_padrino.jpg', 'Il Padrino', true),
('pulp_fiction', 'pulp_fiction.jpg', 'Pulp Fiction', true),
('forrest_gump', 'forrest_gump.jpg', 'Forrest Gump', true),
('matrix', 'matrix.jpg', 'Matrix', true)
ON CONFLICT (id) DO NOTHING;

-- 5. DEFAULT GAME REPORT ROW
INSERT INTO public.game_report (id, state, published_at, published_by, snapshot) 
VALUES ('current', 'PRIVATE_LIVE', NULL, NULL, NULL) 
ON CONFLICT (id) DO NOTHING;

-- 6. DEFAULT GAME SETTINGS ROW
INSERT INTO public.game_settings (id, marketplace_visible, marketplace_active)
VALUES ('current', false, false)
ON CONFLICT (id) DO NOTHING;

-- 7. DEFAULT ENIGMI SOLUTIONS FOR STAGE 4
INSERT INTO public.enigma_solutions (challenge_id, solution_type, solution, punteggio) VALUES
('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', 'notes', '["La", "Do", "Re"]'::jsonb, 20),
('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', 'directions', '["nord-ovest", "sud", "ovest", "est"]'::jsonb, 20),
('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', 'coordinates', '{"lat": "44.71", "lng": "7.84"}'::jsonb, 20)
ON CONFLICT (challenge_id) DO UPDATE SET solution = EXCLUDED.solution, solution_type = EXCLUDED.solution_type, punteggio = EXCLUDED.punteggio;

-- ----------------------------------------------------------------------------
-- STEP 9: TABELLA SETTINGS & RPC AMMINISTRAZIONE EXTRA
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.settings (
  id TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.settings (id, value)
VALUES 
('game_status', 'Gara attiva'),
('game_started_at', now()::text)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Settings" ON public.settings;
DROP POLICY IF EXISTS "Admin Write Settings" ON public.settings;

CREATE POLICY "Public Read Settings" ON public.settings FOR SELECT USING (true);
CREATE POLICY "Admin Write Settings" ON public.settings FOR ALL USING (public.has_role(auth.uid(), 'admin'));

CREATE OR REPLACE FUNCTION public.toggle_marketplace(
  p_active BOOLEAN,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.game_settings 
  SET 
    marketplace_active = p_active,
    activated_at = CASE WHEN p_active THEN now() ELSE NULL END,
    activated_by = CASE WHEN p_active THEN p_admin_id ELSE NULL END
  WHERE id = 'settings_01';
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_force_complete_bank(
  p_team_id UUID,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (p_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, v_challenge_id, 25, 'challenge_points', 'Sfida Banca forzata da Admin');
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_reset_bank(
  p_team_id UUID,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.team_answers WHERE team_id = p_team_id;
  DELETE FROM public.team_progress WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
  DELETE FROM public.scores WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_edit_bank_answer(
  p_team_id UUID,
  p_question_id INTEGER,
  p_answer TEXT,
  p_correct BOOLEAN,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_real_q_id UUID;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT id INTO v_real_q_id FROM public.quiz_questions WHERE question = 'Banca Q' || p_question_id::text LIMIT 1;
  IF NOT FOUND THEN
    INSERT INTO public.quiz_questions (challenge_id, question, options, correct_answer_index, order_index, points)
    VALUES (v_challenge_id, 'Banca Q' || p_question_id::text, '[]'::jsonb, 0, p_question_id, 5)
    RETURNING id INTO v_real_q_id;
  END IF;

  INSERT INTO public.team_answers (team_id, question_id, selected_answer, correct)
  VALUES (p_team_id, v_real_q_id, 0, p_correct)
  ON CONFLICT (team_id, question_id)
  DO UPDATE SET correct = p_correct;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_force_complete_secret_code(
  p_team_id UUID,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (p_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, v_challenge_id, 15, 'challenge_points', 'Codice Segreto sbloccato da Admin');
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_match(
  p_team_id UUID,
  p_partner_id UUID,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_settings(
  p_full_code TEXT,
  p_destination TEXT,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_secret_code_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_completed_teams JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', tp.team_id,
    'nome_squadra', t.nome_squadra,
    'completed_at', tp.completata_il
  )), '[]'::jsonb) INTO v_completed_teams
  FROM public.team_progress tp
  JOIN public.teams t ON t.id = tp.team_id
  WHERE tp.challenge_id = 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7' AND tp.stato = 'completed';

  RETURN jsonb_build_object(
    'full_code', '4829167305',
    'destination', 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)',
    'parts', '[]'::jsonb,
    'matches', '[]'::jsonb,
    'transactions', '[]'::jsonb,
    'attempts', '[]'::jsonb,
    'completed_teams', v_completed_teams
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- STEP 10: TRIGGER DI SINCRONIZZAZIONE TEAMS (BEFORE + AFTER)
-- ----------------------------------------------------------------------------

ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS username TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS password_plain TEXT;

CREATE OR REPLACE FUNCTION public.sync_team_to_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_email TEXT;
  v_encrypted_pass TEXT;
BEGIN
  IF NEW.username IS NULL OR NEW.password_plain IS NULL THEN
    RETURN NEW;
  END IF;

  v_email := LOWER(TRIM(NEW.username)) || '@pechino.it';
  v_encrypted_pass := extensions.crypt(NEW.password_plain, extensions.gen_salt('bf', 10));

  SELECT id INTO v_user_id 
  FROM auth.users 
  WHERE email = v_email;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      v_encrypted_pass,
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb,
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  ELSE
    UPDATE auth.users 
    SET encrypted_password = v_encrypted_pass, updated_at = now()
    WHERE id = v_user_id;
  END IF;

  NEW.owner_id := v_user_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_team_to_auth_user ON public.teams;
CREATE TRIGGER trg_sync_team_to_auth_user
BEFORE INSERT OR UPDATE OF username, password_plain ON public.teams
FOR EACH ROW
EXECUTE FUNCTION public.sync_team_to_auth_user();

CREATE OR REPLACE FUNCTION public.after_sync_team_to_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.owner_id IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role, team_id)
    VALUES (NEW.owner_id, 'team', NEW.id)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_sync_team_to_user ON public.teams;
CREATE TRIGGER trg_after_sync_team_to_user
AFTER INSERT OR UPDATE OF owner_id ON public.teams
FOR EACH ROW
EXECUTE FUNCTION public.after_sync_team_to_user();

CREATE OR REPLACE FUNCTION public.delete_team_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF OLD.owner_id IS NOT NULL THEN
    DELETE FROM public.user_roles WHERE user_id = OLD.owner_id;
    DELETE FROM auth.users WHERE id = OLD.owner_id;
  END IF;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_delete_team_auth_user ON public.teams;
CREATE TRIGGER trg_delete_team_auth_user
AFTER DELETE ON public.teams
FOR EACH ROW
EXECUTE FUNCTION public.delete_team_auth_user();

-- ----------------------------------------------------------------------------
-- STEP 11: INSERIMENTO RIGHE IN GAME_SETTINGS & RLS POLICIES
-- ----------------------------------------------------------------------------

ALTER TABLE public.game_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Game Settings" ON public.game_settings;
DROP POLICY IF EXISTS "Admin Write Game Settings" ON public.game_settings;

CREATE POLICY "Public Read Game Settings" ON public.game_settings FOR SELECT USING (true);
CREATE POLICY "Admin Write Game Settings" ON public.game_settings FOR ALL USING (public.has_role(auth.uid(), 'admin'));

INSERT INTO public.game_settings (id, marketplace_visible, marketplace_active) VALUES 
('settings_01', false, false)
ON CONFLICT (id) DO UPDATE SET 
  marketplace_visible = EXCLUDED.marketplace_visible,
  marketplace_active = EXCLUDED.marketplace_active;

-- RLS policies su teams
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin All Teams" ON public.teams;
DROP POLICY IF EXISTS "Team Update Self Team" ON public.teams;

CREATE POLICY "Admin All Teams" ON public.teams
  FOR ALL USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Team Update Self Team" ON public.teams
  FOR UPDATE USING (id = public.current_team_id()) WITH CHECK (id = public.current_team_id());

-- ----------------------------------------------------------------------------
-- STEP 12: TABELLE & RPC EXTRA PER SOTTOROTTE AMMINISTRAZIONE
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.team_code_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  code_part TEXT NOT NULL,
  part_type TEXT NOT NULL CHECK (part_type IN ('FIRST_5', 'LAST_5')),
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (team_id)
);

CREATE TABLE IF NOT EXISTS public.game_final_code (
  id TEXT PRIMARY KEY DEFAULT 'current',
  full_code TEXT NOT NULL DEFAULT '4829167305',
  next_stage_destination TEXT NOT NULL DEFAULT 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'
);

INSERT INTO public.game_final_code (id) VALUES ('current') ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.admin_get_enigma_dashboard(p_admin_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_stage4_id UUID := '4b4b4c4d-5e5f-6061-7172-838485868788';
  v_rows JSONB;
  v_solutions JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  WITH stage4_challenges AS (
    SELECT id, titolo, ordine_sfida 
    FROM public.challenges 
    WHERE stage_id = v_stage4_id
    ORDER BY ordine_sfida ASC
  ),
  team_enigma_progress AS (
    SELECT 
      t.id AS team_id,
      t.nome_squadra,
      t.active,
      sc.id AS challenge_id,
      sc.titolo,
      sc.ordine_sfida,
      COALESCE(tp.stato, 'not_started') AS stato,
      tp.created_at AS started_at,
      tp.completata_il AS completed_at,
      (SELECT COUNT(*)::INTEGER FROM public.enigma_attempts ea WHERE ea.team_id = t.id AND ea.challenge_id = sc.id) AS attempt_count
    FROM public.teams t
    CROSS JOIN stage4_challenges sc
    LEFT JOIN public.team_progress tp ON tp.team_id = t.id AND tp.challenge_id = sc.id
  ),
  aggregated_teams AS (
    SELECT 
      team_id,
      nome_squadra,
      active,
      bool_or(stato != 'not_started') AS started,
      count(*) FILTER (WHERE stato = 'completed') = (SELECT count(*) FROM stage4_challenges) AS completed_all,
      count(*) FILTER (WHERE stato = 'completed')::INTEGER AS enigmi_completati,
      (SELECT count(*)::INTEGER FROM stage4_challenges) AS enigmi_totali,
      jsonb_agg(jsonb_build_object(
        'challenge_id', challenge_id,
        'titolo', titolo,
        'ordine', ordine_sfida,
        'stato', stato,
        'started_at', started_at,
        'completed_at', completed_at,
        'attempt_count', attempt_count
      ) ORDER BY ordine_sfida) AS enigma_progress
    FROM team_enigma_progress
    GROUP BY team_id, nome_squadra, active
  )
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', team_id,
    'nome_squadra', nome_squadra,
    'active', active,
    'started', started,
    'completed_all', completed_all,
    'enigmi_completati', enigmi_completati,
    'enigmi_totali', enigmi_totali,
    'enigma_progress', enigma_progress
  )), '[]'::jsonb) INTO v_rows
  FROM aggregated_teams;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'challenge_id', challenge_id,
    'solution_type', solution_type,
    'hint', CASE 
      WHEN solution_type = 'text' THEN SUBSTRING(solution->>0 FROM 1 FOR 3) || '...'
      WHEN solution_type = 'directions' THEN '[lucchetto]'
      WHEN solution_type = 'coordinates' THEN 'Lat: 44.71, Lng: 7.84'
      ELSE '[note]'
    END
  )), '[]'::jsonb) INTO v_solutions
  FROM public.enigma_solutions;

  RETURN jsonb_build_object(
    'rows', v_rows,
    'enigma_solutions', v_solutions
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_enigma_solution(
  p_challenge_id UUID,
  p_solution JSONB,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  INSERT INTO public.enigma_solutions (challenge_id, solution, solution_type)
  VALUES (p_challenge_id, p_solution, 'text')
  ON CONFLICT (challenge_id) 
  DO UPDATE SET solution = EXCLUDED.solution;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_jackpot_plays(p_admin_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_plays JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', jp.id,
    'team_id', jp.team_id,
    'nome_squadra', t.nome_squadra,
    'puntata_punti', jp.puntata_punti,
    'esito_moltiplicatore', jp.esito_moltiplicatore,
    'delta_punti', jp.delta_punti,
    'timestamp', jp.timestamp
  )), '[]'::jsonb) INTO v_plays
  FROM public.jackpot_plays jp
  JOIN public.teams t ON t.id = jp.team_id;

  RETURN v_plays;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_report_status()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_report RECORD;
BEGIN
  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('state', 'PRIVATE_LIVE', 'is_published', false, 'published_at', NULL);
  END IF;

  RETURN jsonb_build_object(
    'state', v_report.state,
    'is_published', (v_report.state = 'PUBLISHED_FINAL'),
    'published_at', v_report.published_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_game_report(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_report RECORD;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';

  IF NOT v_is_admin AND COALESCE(v_report.state, 'PRIVATE_LIVE') != 'PUBLISHED_FINAL' THEN
    RAISE EXCEPTION 'Il Resoconto Gara non è ancora stato pubblicato dalla Regia.';
  END IF;

  IF v_report.snapshot IS NOT NULL THEN
    RETURN v_report.snapshot;
  END IF;

  RETURN jsonb_build_object(
    'state', COALESCE(v_report.state, 'PRIVATE_LIVE'),
    'published_at', v_report.published_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.respond_passaparola_request(
  p_transaction_id UUID,
  p_response TEXT,
  p_nota_interna TEXT,
  p_admin_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_tx RECORD;
  v_team_name TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transazione non trovata';
  END IF;

  IF v_tx.stato != 'pending' THEN
    RAISE EXCEPTION 'La richiesta non è in attesa di risposta';
  END IF;

  UPDATE public.marketplace_transactions 
  SET 
    stato = 'used', 
    data_utilizzo = now(), 
    dettagli = dettagli || jsonb_build_object('response_text', p_response, 'nota_interna', p_nota_interna, 'response_timestamp', now())
  WHERE id = p_transaction_id;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_tx.team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('passaparola_responded', v_tx.team_id, jsonb_build_object('message', 'La Regia ha risposto alla richiesta Passaparola di "' || COALESCE(v_team_name, 'Sconosciuta') || '": "' || p_response || '"'));
END;
$$;

CREATE OR REPLACE FUNCTION public.publish_game_report(p_admin_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_report RECORD;
  v_snapshot JSONB;
  v_published_at TIMESTAMPTZ := now();
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';
  IF FOUND AND v_report.state = 'PUBLISHED_FINAL' THEN
    RETURN jsonb_build_object('success', true, 'alreadyPublished', true, 'published_at', v_report.published_at);
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(l)), '[]'::jsonb) INTO v_snapshot
  FROM (
    SELECT * FROM public.get_secure_leaderboard()
  ) l;

  INSERT INTO public.game_report (id, state, published_at, published_by, snapshot)
  VALUES ('current', 'PUBLISHED_FINAL', v_published_at, p_admin_id, v_snapshot)
  ON CONFLICT (id)
  DO UPDATE SET 
    state = 'PUBLISHED_FINAL',
    published_at = v_published_at,
    published_by = p_admin_id,
    snapshot = v_snapshot;

  RETURN jsonb_build_object('success', true, 'alreadyPublished', false, 'published_at', v_published_at);
END;
$$;

CREATE OR REPLACE FUNCTION public.initialize_secret_code_challenge()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_team RECORD;
  v_index INTEGER := 0;
  v_full_code TEXT := '4829167305';
  v_first5 TEXT;
  v_last5 TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current';
  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  FOR v_team IN SELECT id FROM public.teams WHERE active = true LOOP
    INSERT INTO public.team_code_parts (team_id, code_part, part_type)
    VALUES (v_team.id, CASE WHEN v_index % 2 = 0 THEN v_first5 ELSE v_last5 END, CASE WHEN v_index % 2 = 0 THEN 'FIRST_5' ELSE 'LAST_5' END)
    ON CONFLICT (team_id) DO NOTHING;
    
    v_index := v_index + 1;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'message', 'Sfida codice segreto inizializzata per tutte le squadre attive.');
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_adjust_team_tokens(
  p_team_id UUID,
  p_amount INTEGER,
  p_reason TEXT,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_current_tokens INTEGER;
  v_new_balance INTEGER;
  v_team_name TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT token_balance, nome_squadra INTO v_current_tokens, v_team_name 
  FROM public.teams 
  WHERE id = p_team_id 
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Squadra non trovata';
  END IF;

  v_new_balance := GREATEST(0, v_current_tokens + p_amount);

  UPDATE public.teams 
  SET token_balance = v_new_balance 
  WHERE id = p_team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('admin_tokens_adjusted', p_team_id, jsonb_build_object(
    'message', 'La Regia ha ' || CASE WHEN p_amount >= 0 THEN 'aggiunto ' ELSE 'rimosso ' END || ABS(p_amount)::text || ' token alla squadra "' || v_team_name || '".' || CASE WHEN p_reason != '' THEN ' Motivazione: ' || p_reason ELSE '' END,
    'new_balance', v_new_balance
  ));

  RETURN jsonb_build_object('success', true, 'new_balance', v_new_balance);
END;
$$;

-- ----------------------------------------------------------------------------
-- STEP 13: CORNHOLE & BOXE TOURNAMENTS
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.cornhole_matches (
  id TEXT PRIMARY KEY,
  stage_id UUID NOT NULL REFERENCES public.stages(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  round INTEGER NOT NULL,
  match_index INTEGER NOT NULL,
  team1_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  team2_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  winner_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'ready', 'completed')),
  completed_at TIMESTAMPTZ DEFAULT NULL,
  is_special_bye BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.boxe_matches (
  id TEXT PRIMARY KEY,
  stage_id UUID NOT NULL REFERENCES public.stages(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  round INTEGER NOT NULL,
  match_index INTEGER NOT NULL,
  team1_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  team2_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  winner_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'ready', 'completed')),
  completed_at TIMESTAMPTZ DEFAULT NULL,
  is_special_bye BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE public.cornhole_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boxe_matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Cornhole Matches" ON public.cornhole_matches;
DROP POLICY IF EXISTS "Admin All Cornhole Matches" ON public.cornhole_matches;
DROP POLICY IF EXISTS "Public Read Boxe Matches" ON public.boxe_matches;
DROP POLICY IF EXISTS "Admin All Boxe Matches" ON public.boxe_matches;

CREATE POLICY "Public Read Cornhole Matches" ON public.cornhole_matches FOR SELECT USING (true);
CREATE POLICY "Admin All Cornhole Matches" ON public.cornhole_matches FOR ALL USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Public Read Boxe Matches" ON public.boxe_matches FOR SELECT USING (true);
CREATE POLICY "Admin All Boxe Matches" ON public.boxe_matches FOR ALL USING (public.has_role(auth.uid(), 'admin'));

ALTER TABLE public.game_settings ADD COLUMN IF NOT EXISTS cornhole_special_bye_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL;
ALTER TABLE public.game_settings ADD COLUMN IF NOT EXISTS boxe_special_bye_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.get_cornhole_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_settings RECORD;
BEGIN
  SELECT * INTO v_settings FROM public.game_settings WHERE id = 'settings_01';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('cornhole_special_bye_team_id', NULL);
  END IF;
  RETURN jsonb_build_object('cornhole_special_bye_team_id', v_settings.cornhole_special_bye_team_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_boxe_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_settings RECORD;
BEGIN
  SELECT * INTO v_settings FROM public.game_settings WHERE id = 'settings_01';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('boxe_special_bye_team_id', NULL);
  END IF;
  RETURN jsonb_build_object('boxe_special_bye_team_id', v_settings.boxe_special_bye_team_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_cornhole_special_bye(p_team_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.game_settings 
  SET cornhole_special_bye_team_id = p_team_id
  WHERE id = 'settings_01';
END;
$$;

CREATE OR REPLACE FUNCTION public.set_boxe_special_bye(p_team_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.game_settings 
  SET boxe_special_bye_team_id = p_team_id
  WHERE id = 'settings_01';
END;
$$;

CREATE OR REPLACE FUNCTION public.get_cornhole_tournament()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_count INTEGER;
  v_active_teams RECORD;
  v_special_bye_id UUID;
  v_teams_count INTEGER;
  v_virtual_pool INTEGER;
  v_k INTEGER;
  v_num_matches INTEGER;
  v_total_byes INTEGER;
  v_num_tech_byes INTEGER;
  v_rounds_count INTEGER;
  v_team_array UUID[];
  v_match_id TEXT;
  v_index INTEGER := 1;
  v_round INTEGER;
  v_match INTEGER;
  v_result JSONB;
BEGIN
  SELECT COUNT(*)::INTEGER INTO v_count FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;
  
  IF v_count = 0 THEN
    SELECT cornhole_special_bye_team_id INTO v_special_bye_id FROM public.game_settings WHERE id = 'settings_01';
    
    SELECT ARRAY(
      SELECT id FROM public.teams 
      WHERE active = true AND id IS DISTINCT FROM v_special_bye_id
      ORDER BY nome_squadra ASC
    ) INTO v_team_array;

    IF v_special_bye_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.teams WHERE id = v_special_bye_id AND active = true) THEN
      v_team_array := v_special_bye_id || v_team_array;
    END IF;

    v_teams_count := cardinality(v_team_array);
    IF v_teams_count = 0 THEN
      RETURN '[]'::jsonb;
    END IF;

    v_virtual_pool := CASE WHEN v_special_bye_id IS NOT NULL THEN v_teams_count + 1 ELSE v_teams_count END;
    v_k := POWER(2, CEIL(LOG(2, v_virtual_pool)))::INTEGER;
    v_num_matches := v_k / 2;
    v_total_byes := v_k - v_teams_count;
    v_num_tech_byes := CASE WHEN v_special_bye_id IS NOT NULL THEN GREATEST(0, v_total_byes - 1) ELSE v_total_byes END;
    v_rounds_count := LOG(2, v_k)::INTEGER;

    FOR v_round IN 0..(v_rounds_count - 1) LOOP
      v_num_matches := v_k / POWER(2, v_round + 1)::INTEGER;
      FOR v_match IN 0..(v_num_matches - 1) LOOP
        v_match_id := 'cornhole_' || v_round::text || '_' || v_match::text || '_' || SUBSTRING(gen_random_uuid()::text FROM 1 FOR 8);
        
        INSERT INTO public.cornhole_matches (id, stage_id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, is_special_bye)
        VALUES (v_match_id, v_stage_id, v_challenge_id, v_round, v_match, NULL, NULL, NULL, 'pending', NULL, false);
      END LOOP;
    END LOOP;

    v_num_matches := v_k / 2;
    FOR v_match IN 0..(v_num_matches - 1) LOOP
      IF v_match = 0 AND v_special_bye_id IS NOT NULL THEN
        UPDATE public.cornhole_matches 
        SET team1_id = v_special_bye_id, team2_id = NULL, winner_id = v_special_bye_id, status = 'completed', completed_at = now(), is_special_bye = true
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
        
        v_index := v_index + 1;
      ELSIF v_match > 0 AND v_match <= v_num_tech_byes THEN
        IF v_index <= v_teams_count THEN
          UPDATE public.cornhole_matches 
          SET team1_id = v_team_array[v_index], team2_id = NULL, winner_id = v_team_array[v_index], status = 'completed', completed_at = now()
          WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
          
          v_index := v_index + 1;
        END IF;
      ELSE
        IF v_index <= v_teams_count THEN
          UPDATE public.cornhole_matches SET team1_id = v_team_array[v_index], status = 'ready'
          WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
          v_index := v_index + 1;
        END IF;
        IF v_index <= v_teams_count THEN
          UPDATE public.cornhole_matches SET team2_id = v_team_array[v_index]
          WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
          v_index := v_index + 1;
        END IF;
      END IF;
    END LOOP;

    FOR v_round IN 0..(v_rounds_count - 2) LOOP
      FOR v_match IN SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id AND round = v_round AND status = 'completed' LOOP
        IF v_match.winner_id IS NOT NULL THEN
          IF v_match.match_index % 2 = 0 THEN
            UPDATE public.cornhole_matches SET team1_id = v_match.winner_id
            WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = (v_match.match_index / 2);
          ELSE
            UPDATE public.cornhole_matches SET team2_id = v_match.winner_id
            WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = (v_match.match_index / 2);
          END IF;
        END IF;
      END LOOP;
    END LOOP;

    UPDATE public.cornhole_matches 
    SET status = 'ready' 
    WHERE challenge_id = v_challenge_id AND status = 'pending' AND team1_id IS NOT NULL AND team2_id IS NOT NULL;

  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_result
  FROM public.cornhole_matches m
  WHERE m.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_boxe_tournament()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_challenge_id UUID := 'd6d6d6d6-e7e7-f8f8-a9a9-b0b0b0b0b0b0';
  v_count INTEGER;
  v_result JSONB;
BEGIN
  SELECT COUNT(*)::INTEGER INTO v_count FROM public.boxe_matches WHERE challenge_id = v_challenge_id;
  
  IF v_count = 0 THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_result
  FROM public.boxe_matches m
  WHERE m.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_boxe_tournament(p_admin_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_challenge_id UUID := 'd6d6d6d6-e7e7-f8f8-a9a9-b0b0b0b0b0b0';
  v_special_bye_id UUID;
  v_teams_count INTEGER;
  v_virtual_pool INTEGER;
  v_k INTEGER;
  v_num_matches INTEGER;
  v_total_byes INTEGER;
  v_num_tech_byes INTEGER;
  v_rounds_count INTEGER;
  v_team_array UUID[];
  v_match_id TEXT;
  v_index INTEGER := 1;
  v_round INTEGER;
  v_match INTEGER;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  DELETE FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  SELECT boxe_special_bye_team_id INTO v_special_bye_id FROM public.game_settings WHERE id = 'settings_01';
  
  SELECT ARRAY(
    SELECT id FROM public.teams 
    WHERE active = true AND id IS DISTINCT FROM v_special_bye_id
    ORDER BY nome_squadra ASC
  ) INTO v_team_array;

  IF v_special_bye_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.teams WHERE id = v_special_bye_id AND active = true) THEN
    v_team_array := v_special_bye_id || v_team_array;
  END IF;

  v_teams_count := cardinality(v_team_array);
  IF v_teams_count = 0 THEN
    RETURN;
  END IF;

  v_virtual_pool := CASE WHEN v_special_bye_id IS NOT NULL THEN v_teams_count + 1 ELSE v_teams_count END;
  v_k := POWER(2, CEIL(LOG(2, v_virtual_pool)))::INTEGER;
  v_num_matches := v_k / 2;
  v_total_byes := v_k - v_teams_count;
  v_num_tech_byes := CASE WHEN v_special_bye_id IS NOT NULL THEN GREATEST(0, v_total_byes - 1) ELSE v_total_byes END;
  v_rounds_count := LOG(2, v_k)::INTEGER;

  FOR v_round IN 0..(v_rounds_count - 1) LOOP
    v_num_matches := v_k / POWER(2, v_round + 1)::INTEGER;
    FOR v_match IN 0..(v_num_matches - 1) LOOP
      v_match_id := 'boxe_' || v_round::text || '_' || v_match::text || '_' || SUBSTRING(gen_random_uuid()::text FROM 1 FOR 8);
      
      INSERT INTO public.boxe_matches (id, stage_id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, is_special_bye)
      VALUES (v_match_id, v_stage_id, v_challenge_id, v_round, v_match, NULL, NULL, NULL, 'pending', NULL, false);
    END LOOP;
  END LOOP;

  v_num_matches := v_k / 2;
  FOR v_match IN 0..(v_num_matches - 1) LOOP
    IF v_match = 0 AND v_special_bye_id IS NOT NULL THEN
      UPDATE public.boxe_matches 
      SET team1_id = v_special_bye_id, team2_id = NULL, winner_id = v_special_bye_id, status = 'completed', completed_at = now(), is_special_bye = true
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
      
      v_index := v_index + 1;
    ELSIF v_match > 0 AND v_match <= v_num_tech_byes THEN
      IF v_index <= v_teams_count THEN
        UPDATE public.boxe_matches 
        SET team1_id = v_team_array[v_index], team2_id = NULL, winner_id = v_team_array[v_index], status = 'completed', completed_at = now()
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
        
        v_index := v_index + 1;
      END IF;
    ELSE
      IF v_index <= v_teams_count THEN
        UPDATE public.boxe_matches SET team1_id = v_team_array[v_index], status = 'ready'
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
        v_index := v_index + 1;
      END IF;
      IF v_index <= v_teams_count THEN
        UPDATE public.boxe_matches SET team2_id = v_team_array[v_index]
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_match;
        v_index := v_index + 1;
      END IF;
    END IF;
  END LOOP;

  FOR v_round IN 0..(v_rounds_count - 2) LOOP
    FOR v_match IN SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id AND round = v_round AND status = 'completed' LOOP
      IF v_match.winner_id IS NOT NULL THEN
        IF v_match.match_index % 2 = 0 THEN
          UPDATE public.boxe_matches SET team1_id = v_match.winner_id
          WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = (v_match.match_index / 2);
        ELSE
          UPDATE public.boxe_matches SET team2_id = v_match.winner_id
          WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = (v_match.match_index / 2);
        END IF;
      END IF;
    END LOOP;
  END LOOP;

  UPDATE public.boxe_matches 
  SET status = 'ready' 
  WHERE challenge_id = v_challenge_id AND status = 'pending' AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_cornhole_match_result(
  p_match_id TEXT,
  p_winner_id UUID,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_match RECORD;
  v_max_round INTEGER;
  v_points_assigned BOOLEAN;
  v_result JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_match FROM public.cornhole_matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  UPDATE public.cornhole_matches 
  SET winner_id = p_winner_id, status = 'completed', completed_at = now()
  WHERE id = p_match_id;

  SELECT MAX(round)::INTEGER INTO v_max_round FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.cornhole_matches SET team1_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = (v_match.match_index / 2);
    ELSE
      UPDATE public.cornhole_matches SET team2_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = (v_match.match_index / 2);
    END IF;

    UPDATE public.cornhole_matches 
    SET status = 'ready'
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = (v_match.match_index / 2) AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
  ELSE
    SELECT EXISTS(SELECT 1 FROM public.scores WHERE challenge_id = v_challenge_id) INTO v_points_assigned;
    IF NOT v_points_assigned THEN
      INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
      VALUES (p_winner_id, v_challenge_id, 20, 'challenge_points', 'Vincitore Torneo Cornhole');

      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (p_winner_id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = now();
    END IF;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_result
  FROM public.cornhole_matches m
  WHERE m.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$$;


CREATE OR REPLACE FUNCTION public.submit_boxe_match_result(
  p_match_id TEXT,
  p_winner_id UUID,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'd6d6d6d6-e7e7-f8f8-a9a9-b0b0b0b0b0b0';
  v_match RECORD;
  v_max_round INTEGER;
  v_points_assigned BOOLEAN;
  v_result JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT * INTO v_match FROM public.boxe_matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  UPDATE public.boxe_matches 
  SET winner_id = p_winner_id, status = 'completed', completed_at = now()
  WHERE id = p_match_id;

  SELECT MAX(round)::INTEGER INTO v_max_round FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.boxe_matches SET team1_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = (v_match.match_index / 2);
    ELSE
      UPDATE public.boxe_matches SET team2_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = (v_match.match_index / 2);
    END IF;

    UPDATE public.boxe_matches 
    SET status = 'ready'
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = (v_match.match_index / 2) AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
  ELSE
    SELECT EXISTS(SELECT 1 FROM public.scores WHERE challenge_id = v_challenge_id) INTO v_points_assigned;
    IF NOT v_points_assigned THEN
      INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
      VALUES (p_winner_id, v_challenge_id, 20, 'challenge_points', 'Vincitore Torneo Boxe');

      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (p_winner_id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = now();
    END IF;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_result
  FROM public.boxe_matches m
  WHERE m.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$$;


CREATE OR REPLACE FUNCTION public.rollback_cornhole_match_result(
  p_match_id TEXT,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_result JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.cornhole_matches 
  SET winner_id = NULL, status = 'ready', completed_at = NULL
  WHERE id = p_match_id;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_result
  FROM public.cornhole_matches m
  WHERE m.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$$;


CREATE OR REPLACE FUNCTION public.rollback_boxe_match_result(
  p_match_id TEXT,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'd6d6d6d6-e7e7-f8f8-a9a9-b0b0b0b0b0b0';
  v_result JSONB;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.boxe_matches 
  SET winner_id = NULL, status = 'ready', completed_at = NULL
  WHERE id = p_match_id;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_result
  FROM public.boxe_matches m
  WHERE m.challenge_id = v_challenge_id;

  RETURN v_result;
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;

