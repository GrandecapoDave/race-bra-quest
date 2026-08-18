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
  effet TEXT, -- Per compatibilità con schema production esistente
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

-- get_bank_state
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
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autenticato');
  END IF;

  -- LOCK concorrente sulla riga del team per prevenire race conditions
  SELECT * INTO v_team FROM public.teams WHERE id = v_team_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Squadra non trovata');
  END IF;

  SELECT * INTO v_item FROM public.marketplace_items WHERE id = p_item_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Item non trovato');
  END IF;

  IF v_team.token_balance < v_item.costo_token THEN
    RETURN jsonb_build_object('success', false, 'error', 'Token insufficienti');
  END IF;

  -- Detrazione atomica token
  UPDATE public.teams 
  SET token_balance = token_balance - v_item.costo_token 
  WHERE id = v_team_id;

  v_tx_id := gen_random_uuid();

  -- Se è un malus ad una squadra e c'è uno scudo attivo
  IF v_item.tipo = 'malus' AND p_target_team_id IS NOT NULL THEN
    SELECT * INTO v_shield_tx 
    FROM public.marketplace_transactions 
    WHERE team_id = p_target_team_id AND marketplace_item_id = 'bonus_scudo' AND stato = 'completed'
    LIMIT 1;

    IF FOUND THEN
      -- Lo scudo para il malus e si consuma
      UPDATE public.marketplace_transactions SET stato = 'used', data_utilizzo = now() WHERE id = v_shield_tx.id;
      
      INSERT INTO public.marketplace_transactions (id, team_id, marketplace_item_id, target_team_id, costo_token, stato)
      VALUES (v_tx_id, v_team_id, p_item_id, p_target_team_id, v_item.costo_token, 'expired');

      INSERT INTO public.cattiveria_ledger (team_id, tipo, punti, motivo, riferimento_transazione)
      VALUES (p_target_team_id, 'SCUDO_ATTIVATO', 0, 'Scudo attivato per parare il malus ' || v_item.nome, v_shield_tx.id);

      RETURN jsonb_build_object('success', true, 'shielded', true, 'new_balance', v_team.token_balance - v_item.costo_token);
    END IF;
  END IF;

  -- Inserimento transazione
  INSERT INTO public.marketplace_transactions (id, team_id, marketplace_item_id, target_team_id, costo_token, stato)
  VALUES (v_tx_id, v_team_id, p_item_id, p_target_team_id, v_item.costo_token, 'completed');

  -- Effetti immediati
  IF p_item_id = 'bonus_punti' THEN
    INSERT INTO public.scores (team_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, 20, 'bonus_punti', 'Bonus Punti acquistato (+20 PT)');
  END IF;

  IF v_item.tipo = 'malus' THEN
    INSERT INTO public.cattiveria_ledger (team_id, tipo, punti, motivo, riferimento_transazione)
    VALUES (v_team_id, 'MALUS_UTILIZZATO', 10, 'Malus ' || v_item.nome || ' attivato.', v_tx_id);
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

COMMIT;
