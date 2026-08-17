-- ============================================================================
-- PECHINO EXPRESS BRA — MASTER DATABASE SCHEMA & MIGRATION SCRIPT
-- Target: PostgreSQL 15+ (Supabase)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. SQUADRE (TEAMS)
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_squadra TEXT NOT NULL UNIQUE,
  colore TEXT NOT NULL DEFAULT '#ea580c',
  token_balance INTEGER NOT NULL DEFAULT 50 CHECK (token_balance >= 0),
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

-- 7. MARKETPLACE TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.marketplace_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  marketplace_item_id TEXT NOT NULL REFERENCES public.marketplace_items(id),
  target_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  stage_id UUID REFERENCES public.stages(id) ON DELETE SET NULL,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  costo_token INTEGER NOT NULL,
  stato TEXT NOT NULL DEFAULT 'completed' CHECK (stato IN ('completed', 'used', 'viewing', 'expired')),
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

-- 9. JACKPOT DELLA REGIA (SFIDA 5.3)
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

-- INDEXES FOR PERFORMANCE & FAST LEADERBOARD CALCULATIONS
CREATE INDEX IF NOT EXISTS idx_scores_team_id ON public.scores(team_id);
CREATE INDEX IF NOT EXISTS idx_scores_stage_id ON public.scores(stage_id);
CREATE INDEX IF NOT EXISTS idx_team_progress_team ON public.team_progress(team_id, stato);
CREATE INDEX IF NOT EXISTS idx_cattiveria_team_stage ON public.cattiveria_ledger(team_id, stage_id);
CREATE INDEX IF NOT EXISTS idx_transactions_team ON public.marketplace_transactions(team_id);
CREATE INDEX IF NOT EXISTS idx_submissions_challenge ON public.submissions(challenge_id, team_id);

-- ROW LEVEL SECURITY (RLS) POLICIES
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

-- Public read access for active game participants
CREATE POLICY "Public Read Stages" ON public.stages FOR SELECT USING (true);
CREATE POLICY "Public Read Challenges" ON public.challenges FOR SELECT USING (true);
CREATE POLICY "Public Read Marketplace Items" ON public.marketplace_items FOR SELECT USING (true);
CREATE POLICY "Public Read Teams" ON public.teams FOR SELECT USING (true);
CREATE POLICY "Public Read Progress" ON public.team_progress FOR SELECT USING (true);
CREATE POLICY "Public Read Scores" ON public.scores FOR SELECT USING (true);
CREATE POLICY "Public Read Transactions" ON public.marketplace_transactions FOR SELECT USING (true);
CREATE POLICY "Public Read Cattiveria" ON public.cattiveria_ledger FOR SELECT USING (true);
CREATE POLICY "Public Read Submissions" ON public.submissions FOR SELECT USING (true);
CREATE POLICY "Public Read Report" ON public.game_report FOR SELECT USING (true);

-- STORAGE BUCKETS CONFIGURATION FOR FOTO & PROVE (SUPABASE STORAGE)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('team-media', 'team-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

CREATE POLICY "Public Read Team Media" ON storage.objects FOR SELECT USING (bucket_id = 'team-media');
CREATE POLICY "Authenticated/Anon Insert Team Media" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'team-media');

