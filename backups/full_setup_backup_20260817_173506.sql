-- ============================================================================
-- PECHINO EXPRESS BRA — ALL-IN-ONE SUPABASE DATABASE SETUP & SEED
-- Copy and paste this ENTIRE file into the Supabase SQL Editor and click RUN.
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
  stato TEXT NOT NULL DEFAULT 'open',
  outcome JSONB DEFAULT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure columns exist if table was previously created
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
  ordine_sfida INTEGER NOT NULL DEFAULT 1,
  configurazione JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. PROGRESSO SQUADRE (TEAM PROGRESS)
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
  state TEXT NOT NULL DEFAULT 'PRIVATE_LIVE',
  published_at TIMESTAMPTZ DEFAULT NULL,
  published_by UUID DEFAULT NULL,
  snapshot JSONB DEFAULT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- INDEXES
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

-- Drop existing policies if already defined to prevent collision on re-run
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Public Read Stages" ON public.stages;
  DROP POLICY IF EXISTS "Public Read Challenges" ON public.challenges;
  DROP POLICY IF EXISTS "Public Read Marketplace Items" ON public.marketplace_items;
  DROP POLICY IF EXISTS "Public Read Teams" ON public.teams;
  DROP POLICY IF EXISTS "Public Read Progress" ON public.team_progress;
  DROP POLICY IF EXISTS "Public Read Scores" ON public.scores;
  DROP POLICY IF EXISTS "Public Read Transactions" ON public.marketplace_transactions;
  DROP POLICY IF EXISTS "Public Read Cattiveria" ON public.cattiveria_ledger;
  DROP POLICY IF EXISTS "Public Read Submissions" ON public.submissions;
  DROP POLICY IF EXISTS "Public Read Report" ON public.game_report;
  DROP POLICY IF EXISTS "Public Read Team Media" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated/Anon Insert Team Media" ON storage.objects;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

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

-- STORAGE BUCKETS CONFIGURATION (SUPABASE STORAGE)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('team-media', 'team-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

CREATE POLICY "Public Read Team Media" ON storage.objects FOR SELECT USING (bucket_id = 'team-media');
CREATE POLICY "Authenticated/Anon Insert Team Media" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'team-media');

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- TEAMS
INSERT INTO public.teams (id, nome_squadra, colore, token_balance, active) VALUES ('676dfae3-e0c8-4d50-8555-b5a61472522a', 'Fost & Loud', '#f97316', 80, true) ON CONFLICT (id) DO UPDATE SET token_balance = EXCLUDED.token_balance;
INSERT INTO public.teams (id, nome_squadra, colore, token_balance, active) VALUES ('155e40fe-29ea-47dc-8f23-37f3fa560049', 'Ciccioni Bislunghi', '#84cc16', 80, true) ON CONFLICT (id) DO UPDATE SET token_balance = EXCLUDED.token_balance;

-- STAGES
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('4a57212e-7e83-430c-b5fe-6cf38db7be2e', 1, 'Il Passaporto di Bra', 'Piazza Caduti per la Libertà, 14', 44.6982, 7.8507, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 2, 'Il Rebus Visivo', 'Via Mendicità Istruita, 12', 44.6976, 7.8544, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 3, 'La Banca', 'Stazione Ferroviaria di Bra', 44.6946, 7.8542, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('4b4b4c4d-5e5f-6061-7172-838485868788', 4, 'Enigmi', 'Risolvi gli enigmi e inserisci le soluzioni per avanzare.', NULL, NULL, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome) VALUES ('5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 5, 'Tappa Finale', 'Traguardo finale della gara! Raggiungete la destinazione.', 44.71631488741777, 7.842901351857487, 'open', NULL) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;

-- CHALLENGES
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Creazione squadra', 'Scegliete nome, motto, avatar e colore della vostra squadra.', 'team_setup', 5, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('c4e6c385-69ba-4f17-a6d0-36b78776d527', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Quiz Bra', 'Rispondete alle domande sulla città di Bra.', 'quiz', 15, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('0147e750-f0a3-4b72-8e76-a003fe2ef143', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Foto ufficiale', 'Scattate la foto ufficiale della squadra.', 'photo', 10, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('999f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Il Rebus Visivo', 'Raggiungete il luogo rappresentato dal simbolo.', 'photo', 25, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('777f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Indovina il film dalle emoji', 'Viaggiatori, si spengono le luci, si alza il sipario: benvenuti nella sala più insolita della caccia!', 'emoji_movies', 15, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('555f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'La locandina vivente', 'La vostra squadra ha appena ricevuto la locandina di un film iconico.', 'living_poster', 15, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'La Banca', 'Quattro indizi, quattro parole, Viaggiatori. Risolveteli come veri enigmisti da settimana enigmistica: una definizione, una risposta, una sola lettera che conta davvero — la prima.', 'banca', 25, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Missione Social', 'Viaggiatori, questa volta la sfida non è contro il tempo, ma contro la vostra capacità di entrare in contatto con il mondo. Dimostrate di saper comunicare, convincere e creare un legame con persone mai incontrate prima.', 'social', 20, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Il Codice Segreto', 'Viaggiatori, per sbloccare la destinazione finale della gara dovete inserire il PIN a 10 cifre. Ma ricordate: voi avete solo mezza chiave. Dovete trovare il vostro partner economico e acquistare il frammento mancante usando i vostri Token.', 'codice', 15, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Rebus Musicale', 'Ricevete il rebus cartaceo, scoprite le 3 note e inseritele nell''ordine corretto.', 'enigma_musicale', 5, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Lucchetto Direzionale', 'Risolvete l''enigma cartaceo e ricavate la sequenza di 4 direzioni.', 'lucchetto_direzionale', 5, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Le Coordinate Finali', 'Risolvete l''enigma cartaceo per ricavare le coordinate finali.', 'enigma_coordinate', 5, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Sfida Cornhole', 'Torneo fisico di Cornhole 1vs1 gestito dalla regia.', 'cornhole', 20, 1, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Boxe Gonfiabile', 'Torneo fisico a eliminazione diretta di Boxe Gonfiabile 1vs1.', 'boxe', 20, 2, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione) VALUES ('f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Jackpot della Regia', 'Sfida Bonus opzionale. Sfida la fortuna alla slot machine scommettendo i tuoi punti.', 'jackpot', 20, 3, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET titolo = EXCLUDED.titolo, descrizione = EXCLUDED.descrizione, tipo_sfida = EXCLUDED.tipo_sfida, punteggio_massimo = EXCLUDED.punteggio_massimo;

-- MARKETPLACE ITEMS
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('bonus_punti', 'BONUS PUNTI', 'bonus', 'Un grande vantaggio per scalare la classifica. Usa questo bonus nel momento decisivo.', 40, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('bonus_scudo', 'BONUS SCUDO', 'bonus', 'Uno scudo invisibile protegge il vostro viaggio dagli attacchi degli avversari.', 35, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('ruota_fortuna', 'RUOTA DELLA FORTUNA', 'bonus', 'La fortuna decide il vostro destino. Siete pronti a rischiare?', 25, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('passaparola', 'PASSAPAROLA', 'bonus', 'Permette di chiamare l''organizzatore una volta per ricevere un indizio extra SÌ/NO su qualsiasi enigma bloccato.', 20, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('bonus_classifica', 'BONUS CLASSIFICA', 'bonus', 'Visualizza temporaneamente la classifica generale.', 30, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('partenza_anticipata', 'PARTENZA ANTICIPATA', 'bonus', '-2 minuti sulla partenza. Comunica alla Regia per utilizzarlo.', 35, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('freeze_2min', 'FREEZE 2 MINUTI', 'malus', 'Il tempo si ferma per i vostri rivali.', 20, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('enigma_extra', 'ENIGMA EXTRA', 'malus', 'Un ostacolo mentale per rallentare chi vi precede.', 25, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('ruota_sfortunata', 'RUOTA SFORTUNATA', 'malus', 'La sfortuna colpisce duro. Fate girare la ruota a chi vi sta davanti.', 20, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('trappola', 'TRAPPOLA', 'malus', 'Una trappola invisibile per far inciampare gli avversari.', 40, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('penalita_punti', 'PENALITÀ PUNTI', 'malus', 'Sottrae 20 punti all''avversario.', 30, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('tassa_passaggio', 'TASSA DI PASSAGGIO', 'malus', 'Scambia i punti della tua squadra con quelli di un''altra squadra.', 70, '', '', true, '{}'::jsonb) ON CONFLICT (id) DO UPDATE SET costo_token = EXCLUDED.costo_token, nome = EXCLUDED.nome, descrizione = EXCLUDED.descrizione;

-- GAME REPORT INITIAL STATE
INSERT INTO public.game_report (id, state, published_at, published_by, snapshot) VALUES ('current', 'PRIVATE_LIVE', NULL, NULL, NULL) ON CONFLICT (id) DO NOTHING;
