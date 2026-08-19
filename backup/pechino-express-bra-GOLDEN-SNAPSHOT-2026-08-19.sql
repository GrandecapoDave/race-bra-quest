-- ============================================================================
-- PECHINO EXPRESS BRA — DATABASE SCHEMA SNAPSHOT
-- Date: 2026-08-19T14:59:27.465508
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.activity_log (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  tipo_evento text NOT NULL,
  team_id uuid,
  target_team_id uuid,
  dettagli jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.boxe_matches (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  challenge_id uuid NOT NULL,
  round integer NOT NULL,
  match_index integer NOT NULL,
  team1_id uuid,
  team2_id uuid,
  winner_id uuid,
  status text DEFAULT 'pending'::text NOT NULL,
  completed_at timestamp with time zone,
  stage_id uuid,
  is_special_bye boolean DEFAULT false NOT NULL
);
ALTER TABLE public.boxe_matches ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.cattiveria_ledger (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  stage_id uuid,
  tipo text NOT NULL,
  marketplace_item_id text,
  riferimento_transazione uuid,
  punti integer NOT NULL,
  motivo text NOT NULL,
  timestamp timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.cattiveria_ledger ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.challenges (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  stage_id uuid NOT NULL,
  titolo text NOT NULL,
  descrizione text,
  tipo_sfida text NOT NULL,
  punteggio_massimo integer DEFAULT 100 NOT NULL,
  ordine_sfida integer NOT NULL,
  configurazione jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.code_purchase_transactions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  buyer_team_id uuid NOT NULL,
  seller_team_id uuid NOT NULL,
  token_cost integer NOT NULL,
  digits_received text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.code_purchase_transactions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.cornhole_matches (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  challenge_id uuid NOT NULL,
  round integer NOT NULL,
  match_index integer NOT NULL,
  team1_id uuid,
  team2_id uuid,
  winner_id uuid,
  status text DEFAULT 'pending'::text NOT NULL,
  completed_at timestamp with time zone,
  stage_id uuid,
  is_special_bye boolean DEFAULT false NOT NULL
);
ALTER TABLE public.cornhole_matches ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.enigma_attempts (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  challenge_id uuid NOT NULL,
  attempt_number integer NOT NULL,
  answer jsonb NOT NULL,
  is_correct boolean NOT NULL,
  submitted_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.enigma_attempts ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.enigma_solutions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  challenge_id uuid NOT NULL,
  solution_type text NOT NULL,
  solution jsonb NOT NULL,
  punteggio integer DEFAULT 20 NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.enigma_solutions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.game_final_code (
  id text DEFAULT 'current'::text NOT NULL,
  full_code text DEFAULT '4829167305'::text NOT NULL,
  next_stage_destination text DEFAULT 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'::text NOT NULL
);
ALTER TABLE public.game_final_code ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.game_report (
  id text DEFAULT 'current'::text NOT NULL,
  state text DEFAULT 'PRIVATE_LIVE'::text NOT NULL,
  published_at timestamp with time zone,
  published_by uuid,
  snapshot jsonb,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  status text DEFAULT 'NOT_CALCULATED'::text NOT NULL,
  calculated_at timestamp with time zone,
  calculated_by uuid,
  calculated_snapshot jsonb
);
ALTER TABLE public.game_report ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.game_settings (
  id text DEFAULT 'current'::text NOT NULL,
  marketplace_visible boolean DEFAULT false NOT NULL,
  marketplace_active boolean DEFAULT false NOT NULL,
  activated_at timestamp with time zone,
  activated_by uuid,
  cornhole_special_bye_team_id uuid,
  boxe_special_bye_team_id uuid
);
ALTER TABLE public.game_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.jackpot_plays (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  puntata_punti integer,
  esito_moltiplicatore numeric,
  delta_punti integer,
  timestamp timestamp with time zone DEFAULT now() NOT NULL,
  challenge_id uuid DEFAULT 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0'::uuid,
  puntata integer,
  simboli text,
  risultato text,
  variazione integer,
  punteggio_precedente integer,
  punteggio_attuale integer
);
ALTER TABLE public.jackpot_plays ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.marketplace_items (
  id text NOT NULL,
  nome text NOT NULL,
  tipo text NOT NULL,
  descrizione text,
  costo_token integer NOT NULL,
  effetto text,
  icona text,
  disponibile boolean DEFAULT true NOT NULL,
  regole jsonb DEFAULT '{}'::jsonb
);
ALTER TABLE public.marketplace_items ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.marketplace_transactions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  marketplace_item_id text NOT NULL,
  target_team_id uuid,
  stage_id uuid,
  challenge_id uuid,
  costo_token integer NOT NULL,
  stato text DEFAULT 'completed'::text NOT NULL,
  data_acquisto timestamp with time zone DEFAULT now() NOT NULL,
  data_utilizzo timestamp with time zone,
  dettagli jsonb DEFAULT '{}'::jsonb
);
ALTER TABLE public.marketplace_transactions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.posters (
  id text NOT NULL,
  file_name text NOT NULL,
  titolo text NOT NULL,
  active boolean DEFAULT true NOT NULL
);
ALTER TABLE public.posters ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  challenge_id uuid NOT NULL,
  question text NOT NULL,
  options jsonb NOT NULL,
  correct_answer_index integer NOT NULL,
  order_index integer NOT NULL,
  points integer DEFAULT 5 NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.quiz_questions_public (
  id uuid,
  challenge_id uuid,
  question text,
  options jsonb,
  order_index integer,
  points integer,
  created_at timestamp with time zone
);
ALTER TABLE public.quiz_questions_public ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.race_sessions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  stage_id uuid,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone,
  duration_seconds integer
);
ALTER TABLE public.race_sessions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.scores (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  challenge_id uuid,
  stage_id uuid,
  punti integer NOT NULL,
  tipo_modificatore text DEFAULT 'challenge_points'::text,
  motivo text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.settings (
  id text NOT NULL,
  value text NOT NULL,
  updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.stages (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  numero_tappa integer NOT NULL,
  titolo text NOT NULL,
  descrizione text,
  latitude numeric DEFAULT NULL::numeric,
  longitude numeric DEFAULT NULL::numeric,
  stato text DEFAULT 'open'::text NOT NULL,
  outcome jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.stages ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.submissions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  challenge_id uuid NOT NULL,
  tipo text NOT NULL,
  url text NOT NULL,
  latitude numeric DEFAULT NULL::numeric,
  longitude numeric DEFAULT NULL::numeric,
  stato_approvazione text DEFAULT 'pending'::text NOT NULL,
  note text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  voto integer
);
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_answers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  question_id uuid NOT NULL,
  selected_answer integer NOT NULL,
  correct boolean NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.team_answers ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_bank_answers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  question_number integer NOT NULL,
  answer text NOT NULL,
  extracted_letter character NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.team_bank_answers ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_code_matches (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  buyer_team_id uuid NOT NULL,
  seller_team_id uuid NOT NULL,
  required_part text NOT NULL,
  token_cost integer DEFAULT 4 NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.team_code_matches ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_code_parts (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  code_part text NOT NULL,
  part_type text NOT NULL,
  assigned_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.team_code_parts ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_emoji_movies (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  movie_index integer NOT NULL,
  attempts integer DEFAULT 1 NOT NULL,
  last_answer text,
  is_correct boolean DEFAULT false NOT NULL,
  points integer DEFAULT 0 NOT NULL,
  letter character,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  timestamp timestamp with time zone DEFAULT now()
);
ALTER TABLE public.team_emoji_movies ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_members (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid
);
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_posters (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  poster_id text NOT NULL,
  assigned_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.team_posters ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_progress (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  challenge_id uuid NOT NULL,
  stato text DEFAULT 'locked'::text NOT NULL,
  completata_il timestamp with time zone,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.team_progress ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.team_social_submissions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  challenge_id uuid NOT NULL,
  social_url text NOT NULL,
  stato_approvazione text DEFAULT 'pending'::text NOT NULL,
  note text,
  created_at timestamp with time zone DEFAULT now(),
  image_1_url text,
  image_2_url text,
  admin_score integer,
  status text DEFAULT 'submitted'::text,
  uploaded_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.team_social_submissions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.teams (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  nome_squadra text NOT NULL,
  colore text DEFAULT '#ea580c'::text NOT NULL,
  token_balance integer DEFAULT 50 NOT NULL,
  active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  avatar_url text DEFAULT '🏳️'::text,
  motto text DEFAULT 'In corsa per la vittoria!'::text,
  color text,
  owner_id uuid,
  freeze_started_at timestamp with time zone,
  freeze_expires_at timestamp with time zone,
  freeze_duration_seconds integer DEFAULT 0,
  username text,
  password_plain text
);
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.time_penalties (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  team_id uuid NOT NULL,
  stage_id uuid,
  minuti_penalita numeric DEFAULT 0 NOT NULL,
  motivo text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.time_penalties ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL,
  role text NOT NULL,
  team_id uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- FUNCTIONS & RPCS
-- ============================================================================

CREATE OR REPLACE FUNCTION public._get_time_bonus_points(p_rank integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  RETURN CASE p_rank
    WHEN 1 THEN 30
    WHEN 2 THEN 25
    WHEN 3 THEN 20
    WHEN 4 THEN 17
    WHEN 5 THEN 14
    WHEN 6 THEN 11
    WHEN 7 THEN 8
    WHEN 8 THEN 5
    WHEN 9 THEN 3
    ELSE 0
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_points(p_team_id uuid, p_stage_id uuid, p_points integer, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_tokens(p_team_id uuid, p_tokens integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_adjust_team_tokens(p_team_id uuid, p_amount integer, p_reason text, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_edit_bank_answer(p_team_id uuid, p_question_id integer, p_answer text, p_correct boolean, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_real_q_id UUID;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  -- Cerchiamo se c'è una domanda fittizia
  -- Nella banca le domande sono logiche e registrate per numero. Per evitare FK errors, associamo ad una riga in quiz_questions se presente o la creiamo fittizia.
  SELECT id INTO v_real_q_id FROM public.quiz_questions WHERE question = 'Banca Q' || p_question_id::text LIMIT 1;
  IF NOT FOUND THEN
    INSERT INTO public.quiz_questions (challenge_id, question, options, correct_answer_index, order_index, points)
    VALUES (v_challenge_id, 'Banca Q' || p_question_id::text, '[]'::jsonb, 0, p_question_id, 5)
    RETURNING id INTO v_real_q_id;
  END IF;

  INSERT INTO public.team_answers (team_id, question_id, selected_answer, correct)
  VALUES (p_team_id, v_real_q_id, 0, p_correct) -- Selected index fittizio
  ON CONFLICT (team_id, question_id)
  DO UPDATE SET correct = p_correct;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_match(p_team_id uuid, p_partner_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
  -- Logica fittizia per evitare errori
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_edit_secret_code_settings(p_full_code text, p_destination text, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;
  -- Logica fittizia per evitare errori
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_force_complete_bank(p_team_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  -- Completa la sfida
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (p_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id)
  DO UPDATE SET stato = 'completed', completata_il = now();

  -- Assegna punteggio (25 punti)
  INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
  VALUES (p_team_id, v_challenge_id, 25, 'challenge_points', 'Sfida Banca forzata da Admin');
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_force_complete_secret_code(p_team_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7'; -- Codice Segreto
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_get_enigma_dashboard(p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_get_posters_overview()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_teams JSONB;
  v_posters JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', p.id,
    'titolo', p.titolo,
    'file_name', p.file_name,
    'active', p.active
  ) ORDER BY p.id), '[]'::jsonb) INTO v_posters
  FROM public.posters p;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', t.id,
    'nome_squadra', t.nome_squadra,
    'avatar_url', t.avatar_url,
    'colore', t.colore,
    'poster_id', tp.poster_id,
    'titolo', p.titolo,
    'file_name', p.file_name,
    'assigned_at', tp.assigned_at
  ) ORDER BY t.created_at), '[]'::jsonb) INTO v_teams
  FROM public.teams t
  LEFT JOIN public.team_posters tp ON tp.team_id = t.id
  LEFT JOIN public.posters p ON p.id = tp.poster_id
  WHERE t.active = true;

  RETURN jsonb_build_object(
    'posters', v_posters,
    'team_assignments', v_teams
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_get_secret_code_dashboard()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_full_code TEXT := '4829167305';
  v_destination TEXT := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)';
  v_parts JSONB := '[]'::jsonb;
  v_matches JSONB := '[]'::jsonb;
  v_transactions JSONB := '[]'::jsonb;
  v_attempts JSONB := '[]'::jsonb;
  v_completed_teams JSONB := '[]'::jsonb;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code, next_stage_destination 
  INTO v_full_code, v_destination 
  FROM public.game_final_code 
  WHERE id = 'current' 
  LIMIT 1;

  -- 1. Parts
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', tcp.id,
    'team_id', tcp.team_id,
    'code_part', tcp.code_part,
    'part_type', tcp.part_type,
    'assigned_at', tcp.assigned_at
  )), '[]'::jsonb) INTO v_parts
  FROM public.team_code_parts tcp;

  -- 2. Matches
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'buyer_team_id', tcm.buyer_team_id,
    'seller_team_id', tcm.seller_team_id,
    'required_part', tcm.required_part,
    'token_cost', COALESCE(tcm.token_cost, 4),
    'created_at', tcm.created_at
  )), '[]'::jsonb) INTO v_matches
  FROM public.team_code_matches tcm;

  -- 3. Transactions
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', cpt.id,
    'buyer_team_id', cpt.buyer_team_id,
    'seller_team_id', cpt.seller_team_id,
    'token_cost', cpt.token_cost,
    'digits_received', cpt.digits_received,
    'timestamp', cpt.created_at
  )), '[]'::jsonb) INTO v_transactions
  FROM public.code_purchase_transactions cpt;

  -- 4. Attempts from activity_log or attempts table
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', al.id,
    'team_id', al.team_id,
    'inserted_code', COALESCE(al.dettagli->>'inserted_code', al.dettagli->>'code', '—'),
    'timestamp', al.created_at,
    'success', (al.tipo_evento = 'secret_code_solved')
  ) ORDER BY al.created_at DESC), '[]'::jsonb) INTO v_attempts
  FROM public.activity_log al
  WHERE al.tipo_evento IN ('secret_code_solved', 'secret_code_attempt');

  -- 5. Completed teams
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'team_id', tp.team_id,
    'nome_squadra', t.nome_squadra,
    'completed_at', tp.completata_il
  )), '[]'::jsonb) INTO v_completed_teams
  FROM public.team_progress tp
  JOIN public.teams t ON t.id = tp.team_id
  WHERE (tp.challenge_id = v_challenge_id OR tp.challenge_id IN (SELECT id FROM public.challenges WHERE tipo_sfida = 'codice'))
    AND tp.stato = 'completed';

  RETURN jsonb_build_object(
    'full_code', COALESCE(v_full_code, '4829167305'),
    'destination', COALESCE(v_destination, 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'),
    'parts', v_parts,
    'matches', v_matches,
    'transactions', v_transactions,
    'attempts', v_attempts,
    'completed_teams', v_completed_teams
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_remove_points(p_team_id uuid, p_stage_id uuid, p_points integer, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_remove_tokens(p_team_id uuid, p_tokens integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.admin_reopen_game_results(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_is_admin BOOLEAN := false;
BEGIN
  v_caller_id := COALESCE(auth.uid(), p_admin_id);

  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
  END IF;

  IF NOT COALESCE(v_is_admin, false) THEN
    RAISE EXCEPTION 'Access Denied: Only Admin can reopen results.';
  END IF;

  UPDATE public.game_report
  SET 
    status = 'CALCULATED',
    state = 'PRIVATE_LIVE',
    published_at = NULL,
    published_by = NULL,
    updated_at = now()
  WHERE id = 'current';

  -- Audit Log
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'REOPEN_FINAL_RESULTS',
    jsonb_build_object(
      'admin_id', v_caller_id,
      'reopened_at', now()
    )
  );

  RETURN jsonb_build_object('success', true, 'status', 'CALCULATED');
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_reset_bank(p_team_id uuid, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  -- Elimina risposte
  DELETE FROM public.team_answers WHERE team_id = p_team_id;

  -- Resetta progresso
  DELETE FROM public.team_progress WHERE team_id = p_team_id AND challenge_id = v_challenge_id;

  -- Elimina punteggio associato
  DELETE FROM public.scores WHERE team_id = p_team_id AND challenge_id = v_challenge_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_enigma_solution(p_challenge_id uuid, p_solution jsonb, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.after_sync_team_to_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NEW.owner_id IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role, team_id)
    VALUES (NEW.owner_id, 'team', NEW.id)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.buy_marketplace_item(p_item_id text, p_target_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_team RECORD;
  v_item RECORD;
  v_tx_id UUID;
  v_target_shield RECORD;
  v_target_team_name TEXT;
  v_stage_id UUID;
  
  -- Variables for Ruota Fortuna
  v_roll INTEGER;
  v_outcome_id TEXT;
  v_label TEXT;
  v_points INTEGER := 0;
  v_tokens INTEGER := 0;
  v_dave_help BOOLEAN := false;
  v_outcome JSONB := '{}'::jsonb;
  v_dettagli JSONB := '{}'::jsonb;
  
  -- Variables for Tassa di Passaggio & Malus
  v_buyer_total INTEGER;
  v_target_total INTEGER;
  v_buyer_curr INTEGER;
  v_target_curr INTEGER;
  v_points_stolen INTEGER;
  v_points_deducted INTEGER;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato o nessuna squadra associata';
  END IF;

  -- Lock team row to prevent concurrency race conditions
  SELECT * INTO v_team 
  FROM public.teams 
  WHERE id = v_team_id AND active = true 
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Squadra non trovata o non attiva';
  END IF;

  SELECT * INTO v_item 
  FROM public.marketplace_items 
  WHERE id = p_item_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Articolo del marketplace non trovato: %', p_item_id;
  END IF;

  IF NOT COALESCE(v_item.disponibile, true) THEN
    RAISE EXCEPTION 'Questo articolo non è attualmente disponibile per l''acquisto';
  END IF;

  IF v_team.token_balance < v_item.costo_token THEN
    RAISE EXCEPTION 'Saldo token insufficiente (% disponibili, % richiesti)', v_team.token_balance, v_item.costo_token;
  END IF;

  -- Active stage for logging
  SELECT id INTO v_stage_id 
  FROM public.stages 
  WHERE stato = 'open' 
  ORDER BY numero_tappa ASC 
  LIMIT 1;

  IF LOWER(v_item.tipo) = 'malus' THEN
    IF p_target_team_id IS NULL THEN
      RAISE EXCEPTION 'È necessario selezionare una squadra bersaglio per questo Malus';
    END IF;

    IF p_target_team_id = v_team_id THEN
      RAISE EXCEPTION 'Non puoi bersagliare la tua stessa squadra con un Malus!';
    END IF;

    SELECT nome_squadra INTO v_target_team_name 
    FROM public.teams 
    WHERE id = p_target_team_id AND active = true;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Squadra bersaglio non trovata o non attiva';
    END IF;
  END IF;

  -- Deduct tokens
  UPDATE public.teams
  SET token_balance = token_balance - v_item.costo_token
  WHERE id = v_team_id;

  v_tx_id := gen_random_uuid();

  -- SHIELD CHECK FOR MALUS
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
          dettagli = jsonb_build_object('consumed_at', now(), 'blocked_attacker_id', v_team_id, 'blocked_malus_id', p_item_id)
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
        'transaction_id', v_tx_id,
        'new_balance', v_team.token_balance - v_item.costo_token
      );
    END IF;
  END IF;

  -- 1. RUOTA DELLA FORTUNA (BONUS)
  IF p_item_id = 'ruota_fortuna' THEN
    v_roll := floor(random() * 100) + 1;

    IF v_roll <= 3 THEN
      v_outcome_id := 'jackpot'; v_label := '🏆 JACKPOT (+20 PT)'; v_points := 20;
    ELSIF v_roll <= 6 THEN
      v_outcome_id := 'dave_help'; v_label := '🧠 AIUTO DAVE 📞'; v_dave_help := true;
    ELSIF v_roll <= 13 THEN
      v_outcome_id := 'mega_bonus'; v_label := '💎 MEGA BONUS (+15 PT)'; v_points := 15;
    ELSIF v_roll <= 25 THEN
      v_outcome_id := 'bonus'; v_label := '⭐ BONUS (+10 PT)'; v_points := 10;
    ELSIF v_roll <= 45 THEN
      v_outcome_id := 'piccolo_bonus'; v_label := '🎁 PICCOLO BONUS (+5 PT)'; v_points := 5;
    ELSIF v_roll <= 55 THEN
      v_outcome_id := 'gettoni_bonus'; v_label := '🪙 GETTONI BONUS (+10 TK)'; v_tokens := 10;
    ELSIF v_roll <= 65 THEN
      v_outcome_id := 'doppio_premio'; v_label := '🎯 DOPPIO PREMIO (+5PT / +5TK)'; v_points := 5; v_tokens := 5;
    ELSIF v_roll <= 80 THEN
      v_outcome_id := 'fortuna'; v_label := '🍀 FORTUNA (+5 TK)'; v_tokens := 5;
    ELSE
      v_outcome_id := 'sorpresa'; v_label := '🎉 SORPRESA (+3 PT)'; v_points := 3;
    END IF;

    v_outcome := jsonb_build_object(
      'id', v_outcome_id,
      'label', v_label,
      'points', v_points,
      'tokens', v_tokens,
      'dave_help', v_dave_help,
      'roll', v_roll
    );

    IF v_points > 0 THEN
      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_stage_id, v_points, 'bonus_punti', 'Ruota della Fortuna: ' || v_label);
    END IF;

    IF v_tokens > 0 THEN
      UPDATE public.teams
      SET token_balance = token_balance + v_tokens
      WHERE id = v_team_id;
    END IF;

    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, v_stage_id, v_item.costo_token, 'used', now(), now(), 
      jsonb_build_object('outcome', v_outcome)
    );

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES (
      'ruota_fortuna_spin', v_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha girato la Ruota della Fortuna ed ha ottenuto: ' || v_label)
    );

    RETURN jsonb_build_object(
      'success', true, 
      'outcome', v_outcome, 
      'transaction_id', v_tx_id,
      'new_balance', (v_team.token_balance - v_item.costo_token + v_tokens)
    );

  -- 2. BONUS PUNTI (+20 PT)
  ELSIF p_item_id = 'bonus_punti' THEN
    INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_stage_id, 20, 'bonus_punti', 'Acquisto Bonus Punti (+20 PT)');

    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, v_stage_id, v_item.costo_token, 'used', now(), now(), 
      jsonb_build_object('points_added', 20)
    );

    INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
    VALUES (
      'bonus_punti_purchased', v_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha acquistato il Bonus Punti (+20 PT).')
    );

    RETURN jsonb_build_object(
      'success', true, 
      'transaction_id', v_tx_id,
      'new_balance', v_team.token_balance - v_item.costo_token
    );

  -- 3. MALUS: TRAPPOLA (RUBA FINO A 30 PT)
  ELSIF p_item_id = 'trappola' THEN
    SELECT COALESCE(SUM(punti), 0) INTO v_target_total 
    FROM public.scores 
    WHERE team_id = p_target_team_id;
    
    v_points_stolen := LEAST(30, GREATEST(0, v_target_total));

    IF v_points_stolen > 0 THEN
      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, v_stage_id, -v_points_stolen, 'penalty', 'Malus Trappola: sottratti −' || v_points_stolen::text || ' PT da ' || v_team.nome_squadra);

      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team_id, v_stage_id, v_points_stolen, 'bonus_punti', 'Malus Trappola: rubati +' || v_points_stolen::text || ' PT a ' || v_target_team_name);
    END IF;

    -- Insert transaction FIRST for Foreign Key constraint
    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'used', now(), now(), 
      jsonb_build_object('points_stolen', v_points_stolen, 'target_team_id', p_target_team_id)
    );

    INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
    VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Malus Trappola attivato.', v_tx_id, p_item_id);

    INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
    VALUES (
      'trappola_used', v_team_id, p_target_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha attivato la TRAPPOLA contro "' || v_target_team_name || '" rubando ' || v_points_stolen::text || ' PT.')
    );

    RETURN jsonb_build_object(
      'success', true, 
      'outcome', jsonb_build_object(
        'points_stolen', v_points_stolen,
        'target_points_before', v_target_total,
        'target_points_after', GREATEST(0, v_target_total - v_points_stolen)
      ),
      'transaction_id', v_tx_id,
      'new_balance', v_team.token_balance - v_item.costo_token
    );

  -- 4. MALUS: PENALITÀ PUNTI (-20 PT)
  ELSIF p_item_id = 'penalita_punti' THEN
    SELECT COALESCE(SUM(punti), 0) INTO v_target_total 
    FROM public.scores 
    WHERE team_id = p_target_team_id;
    
    v_points_deducted := LEAST(20, GREATEST(0, v_target_total));

    IF v_points_deducted > 0 THEN
      INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (p_target_team_id, v_stage_id, -v_points_deducted, 'penalty', 'Malus Penalità: −' || v_points_deducted::text || ' PT da ' || v_team.nome_squadra);
    END IF;

    -- Insert transaction FIRST for Foreign Key constraint
    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'used', now(), now(), 
      jsonb_build_object('points_deducted', v_points_deducted, 'target_team_id', p_target_team_id)
    );

    INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
    VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Malus Penalità Punti attivato.', v_tx_id, p_item_id);

    INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
    VALUES (
      'penalita_punti_used', v_team_id, p_target_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha inflitto una PENALITÀ PUNTI a "' || v_target_team_name || '" di −' || v_points_deducted::text || ' PT.')
    );

    RETURN jsonb_build_object(
      'success', true, 
      'outcome', jsonb_build_object(
        'points_deducted', v_points_deducted,
        'target_points_before', v_target_total,
        'target_points_after', GREATEST(0, v_target_total - v_points_deducted)
      ),
      'transaction_id', v_tx_id,
      'new_balance', v_team.token_balance - v_item.costo_token
    );

  -- 5. MALUS: TASSA DI PASSAGGIO (PERFECT TOTAL POINTS SWITCH)
  ELSIF p_item_id = 'tassa_passaggio' THEN
    -- Calculate complete pre-switch total points (scores + cattiveria)
    SELECT (COALESCE((SELECT SUM(punti) FROM public.scores WHERE team_id = v_team_id), 0) +
            COALESCE((SELECT SUM(punti) FROM public.cattiveria_ledger WHERE team_id = v_team_id), 0))
    INTO v_buyer_total;

    SELECT (COALESCE((SELECT SUM(punti) FROM public.scores WHERE team_id = p_target_team_id), 0) +
            COALESCE((SELECT SUM(punti) FROM public.cattiveria_ledger WHERE team_id = p_target_team_id), 0))
    INTO v_target_total;

    -- Insert transaction FIRST for Foreign Key constraint
    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'used', now(), now(), 
      jsonb_build_object(
        'buyer_points_before', v_buyer_total,
        'buyer_points_after', v_target_total,
        'target_points_before', v_target_total,
        'target_points_after', v_buyer_total,
        'target_team_id', p_target_team_id
      )
    );

    -- Award Cattiveria points for executing Malus
    INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
    VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Tassa di Passaggio attivata.', v_tx_id, p_item_id);

    -- Calculate current total of buyer after cattiveria insertion
    SELECT (COALESCE((SELECT SUM(punti) FROM public.scores WHERE team_id = v_team_id), 0) +
            COALESCE((SELECT SUM(punti) FROM public.cattiveria_ledger WHERE team_id = v_team_id), 0))
    INTO v_buyer_curr;

    SELECT (COALESCE((SELECT SUM(punti) FROM public.scores WHERE team_id = p_target_team_id), 0) +
            COALESCE((SELECT SUM(punti) FROM public.cattiveria_ledger WHERE team_id = p_target_team_id), 0))
    INTO v_target_curr;

    -- Insert exact deltas in scores so that Buyer total becomes v_target_total and Target total becomes v_buyer_total
    INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_stage_id, (v_target_total - v_buyer_curr), 'bonus_punti', 'Tassa di Passaggio: scambiati ' || v_buyer_total::text || ' PT con ' || v_target_total::text || ' PT di ' || v_target_team_name);

    INSERT INTO public.scores (team_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (p_target_team_id, v_stage_id, (v_buyer_total - v_target_curr), 'penalty', 'Tassa di Passaggio: scambiati ' || v_target_total::text || ' PT con ' || v_buyer_total::text || ' PT di ' || v_team.nome_squadra);

    INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
    VALUES (
      'tassa_passaggio_used', v_team_id, p_target_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha attivato la TASSA DI PASSAGGIO scambiando i suoi ' || v_buyer_total::text || ' PT con i ' || v_target_total::text || ' PT di "' || v_target_team_name || '".')
    );

    RETURN jsonb_build_object(
      'success', true, 
      'outcome', jsonb_build_object(
        'buyer_points_before', v_buyer_total,
        'buyer_points_after', v_target_total,
        'target_points_before', v_target_total,
        'target_points_after', v_buyer_total
      ),
      'transaction_id', v_tx_id,
      'new_balance', v_team.token_balance - v_item.costo_token
    );

  -- 6. MALUS: FREEZE 2 MINUTI
  ELSIF p_item_id = 'freeze_2min' THEN
    UPDATE public.teams 
    SET 
      freeze_started_at = now(),
      freeze_expires_at = now() + INTERVAL '120 seconds',
      freeze_duration_seconds = 120
    WHERE id = p_target_team_id;

    -- Insert transaction FIRST for Foreign Key constraint
    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'completed', now(), NULL, 
      jsonb_build_object('target_team_id', p_target_team_id, 'duration_seconds', 120, 'freeze_expires_at', (now() + INTERVAL '120 seconds'))
    );

    INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
    VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Malus Freeze 2 Minuti attivato.', v_tx_id, p_item_id);

    INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
    VALUES (
      'team_frozen', v_team_id, p_target_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha congelato la squadra "' || v_target_team_name || '" per 120 secondi!')
    );

    RETURN jsonb_build_object(
      'success', true, 
      'transaction_id', v_tx_id,
      'new_balance', v_team.token_balance - v_item.costo_token
    );

  -- 7. ALL OTHER ITEMS (PASSAPAROLA, BONUS SCUDO, PARTENZA ANTICIPATA, ENIGMA EXTRA, RUOTA SFORTUNATA, ETC.)
  ELSE
    INSERT INTO public.marketplace_transactions (
      id, team_id, marketplace_item_id, target_team_id, stage_id, costo_token, stato, data_acquisto, data_utilizzo, dettagli
    )
    VALUES (
      v_tx_id, v_team_id, p_item_id, p_target_team_id, v_stage_id, v_item.costo_token, 'completed', now(), NULL, 
      jsonb_build_object('target_team_id', p_target_team_id)
    );

    IF LOWER(v_item.tipo) = 'malus' THEN
      INSERT INTO public.cattiveria_ledger (team_id, stage_id, tipo, punti, motivo, riferimento_transazione, marketplace_item_id)
      VALUES (v_team_id, v_stage_id, 'MALUS_UTILIZZATO', 10, 'Malus ' || v_item.nome || ' attivato.', v_tx_id, p_item_id);
    END IF;

    INSERT INTO public.activity_log (tipo_evento, team_id, target_team_id, dettagli)
    VALUES (
      'marketplace_purchase', v_team_id, p_target_team_id, 
      jsonb_build_object('message', 'La squadra "' || v_team.nome_squadra || '" ha acquistato "' || v_item.nome || '".')
    );

    RETURN jsonb_build_object(
      'success', true, 
      'transaction_id', v_tx_id,
      'new_balance', v_team.token_balance - v_item.costo_token
    );
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.buy_secret_code_part()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_buyer_id UUID;
  v_match RECORD;
  v_buyer RECORD;
  v_seller RECORD;
  v_cost INTEGER;
  v_full_code TEXT;
  v_digits TEXT;
BEGIN
  v_buyer_id := public.current_team_id();
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Verifica se già acquistato
  IF EXISTS (SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = v_buyer_id) THEN
    RETURN jsonb_build_object('success', true, 'message', 'Frammento già acquistato');
  END IF;

  -- Assicura match
  PERFORM public.get_secret_code_state(v_buyer_id);
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = v_buyer_id;

  v_cost := COALESCE(v_match.token_cost, 4);

  SELECT * INTO v_buyer FROM public.teams WHERE id = v_buyer_id FOR UPDATE;
  IF (v_buyer.token_balance < v_cost) THEN
    RAISE EXCEPTION 'Token insufficienti (Costo: % Token, Tuo saldo: %)', v_cost, v_buyer.token_balance;
  END IF;

  -- Scala token al compratore
  UPDATE public.teams SET token_balance = token_balance - v_cost WHERE id = v_buyer_id;

  -- Accredita token al venditore se presente
  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> v_buyer_id THEN
    UPDATE public.teams SET token_balance = token_balance + v_cost WHERE id = v_match.seller_team_id;
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_digits := CASE WHEN v_match.required_part = 'FIRST_5' THEN SUBSTRING(v_full_code FROM 1 FOR 5) ELSE SUBSTRING(v_full_code FROM 6 FOR 5) END;

  -- Registra transazione nella tabella dedicata code_purchase_transactions
  INSERT INTO public.code_purchase_transactions (
    buyer_team_id, seller_team_id, token_cost, digits_received
  )
  VALUES (
    v_buyer_id, COALESCE(v_match.seller_team_id, v_buyer_id), v_cost, v_digits
  )
  ON CONFLICT (buyer_team_id) DO NOTHING;

  -- Registra log attività
  INSERT INTO public.activity_log (team_id, target_team_id, tipo_evento, dettagli)
  VALUES (
    v_buyer_id, 
    v_match.seller_team_id, 
    'buy_secret_code_part', 
    jsonb_build_object('cost', v_cost, 'digits', v_digits)
  );

  RETURN jsonb_build_object('success', true, 'digits', v_digits, 'cost', v_cost);
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_final_game_results(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_is_admin BOOLEAN := false;
  v_teams_report JSONB;
  v_stages_report JSONB;
  v_full_report JSONB;
BEGIN
  v_caller_id := COALESCE(auth.uid(), p_admin_id);

  -- Check Admin Authorization
  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
  END IF;

  IF NOT COALESCE(v_is_admin, false) THEN
    RAISE EXCEPTION 'Access Denied: Only Admin can calculate final results.';
  END IF;

  -- 1. Stages report
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', s.id,
    'name', s.titolo,
    'order', s.numero_tappa,
    'status', s.stato,
    'challenges_count', (SELECT COUNT(*) FROM public.challenges c WHERE c.stage_id = s.id)
  ) ORDER BY s.numero_tappa ASC), '[]'::jsonb)
  INTO v_stages_report
  FROM public.stages s;

  -- 2. Teams calculation with Time (-120s per partenza_anticipata) & Token Bonuses
  WITH team_raw_data AS (
    SELECT 
      t.id AS team_id,
      t.nome_squadra AS team_name,
      t.avatar_url,
      t.colore AS color,
      t.motto,
      t.created_at AS team_created_at,
      t.token_balance AS current_tokens,
      -- Completed challenges
      (SELECT COUNT(DISTINCT tp.challenge_id) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed') AS completed_challenges,
      -- Points
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id AND s.challenge_id IS NOT NULL), 0)::INTEGER AS challenges_points,
      COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id AND s.challenge_id IS NULL), 0)::INTEGER AS modifier_points,
      COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)::INTEGER AS cattiveria_points,
      -- Total base score
      (
        COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) +
        COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)
      )::INTEGER AS base_score,
      -- Partenza anticipata bonus count (each -120 seconds)
      COALESCE((
        SELECT COUNT(*) 
        FROM public.marketplace_transactions mt 
        WHERE mt.team_id = t.id 
          AND mt.marketplace_item_id = 'partenza_anticipata' 
          AND mt.stato != 'blocked'
      ), 0)::INTEGER AS count_partenza_anticipata,
      -- Time & Penalties - (Partenza Anticipata * 120s)
      GREATEST(0, (
        COALESCE((
          SELECT SUM(rs.duration_seconds) FROM public.race_sessions rs WHERE rs.team_id = t.id
        ), EXTRACT(EPOCH FROM (
          COALESCE((SELECT MAX(tp.completata_il) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed'), t.created_at) - t.created_at
        )))::INTEGER + 
        COALESCE((
          SELECT (SUM(tp.minuti_penalita) * 60)::INTEGER FROM public.time_penalties tp WHERE tp.team_id = t.id
        ), 0) -
        (
          COALESCE((
            SELECT COUNT(*) 
            FROM public.marketplace_transactions mt 
            WHERE mt.team_id = t.id 
              AND mt.marketplace_item_id = 'partenza_anticipata' 
              AND mt.stato != 'blocked'
          ), 0) * 120
        )
      ))::INTEGER AS total_time_seconds,
      (SELECT MAX(tp.completata_il) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed') AS last_completion,
      -- Token economy
      50 AS starting_tokens,
      COALESCE((
        SELECT SUM(mt.costo_token) 
        FROM public.marketplace_transactions mt 
        WHERE mt.team_id = t.id AND mt.stato != 'blocked' AND mt.costo_token > 0 AND mt.marketplace_item_id != 'reward_stage'
      ), 0)::INTEGER AS spent_tokens,
      COALESCE((
        SELECT SUM(ABS(mt.costo_token)) 
        FROM public.marketplace_transactions mt 
        WHERE mt.team_id = t.id AND (mt.marketplace_item_id = 'reward_stage' OR (mt.dettagli->>'stage_reward')::boolean = true)
      ), 0)::INTEGER AS tokens_gained_rewards,
      -- Token efficiency bonus: floor(token_balance / 5)
      FLOOR(t.token_balance / 5)::INTEGER AS token_efficiency_bonus
    FROM public.teams t
    WHERE t.active = true
  ),
  team_time_ranked AS (
    SELECT 
      trd.*,
      DENSE_RANK() OVER (
        ORDER BY trd.total_time_seconds ASC, trd.last_completion ASC NULLS LAST, trd.team_created_at ASC
      )::INTEGER AS time_rank,
      public._get_time_bonus_points(
        DENSE_RANK() OVER (
          ORDER BY trd.total_time_seconds ASC, trd.last_completion ASC NULLS LAST, trd.team_created_at ASC
        )::INTEGER
      ) AS time_bonus
    FROM team_raw_data trd
  ),
  team_final_calculated AS (
    SELECT 
      ttr.*,
      (ttr.base_score + ttr.time_bonus + ttr.token_efficiency_bonus)::INTEGER AS final_score,
      ROW_NUMBER() OVER (
        ORDER BY 
          (ttr.base_score + ttr.time_bonus + ttr.token_efficiency_bonus) DESC,
          ttr.completed_challenges DESC,
          ttr.total_time_seconds ASC,
          ttr.last_completion ASC NULLS LAST,
          ttr.team_created_at ASC
      )::INTEGER AS final_rank
    FROM team_time_ranked ttr
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'rank', tfc.final_rank,
      'position', tfc.final_rank,
      'final_rank', tfc.final_rank,
      'team_id', tfc.team_id,
      'id', tfc.team_id,
      'team_name', tfc.team_name,
      'nome_squadra', tfc.team_name,
      'name', tfc.team_name,
      'avatar_url', tfc.avatar_url,
      'color', tfc.color,
      'motto', tfc.motto,
      -- Scores breakdown
      'completed_challenges', tfc.completed_challenges,
      'challenges_points', tfc.challenges_points,
      'modifier_points', tfc.modifier_points,
      'cattiveria_points', tfc.cattiveria_points,
      'base_score', tfc.base_score,
      'total_game_points', tfc.base_score,
      'total_score_before_final_bonuses', tfc.base_score,
      'total_points', tfc.final_score,
      'final_score', tfc.final_score,
      -- Time breakdown
      'total_duration_seconds', tfc.total_time_seconds,
      'total_time_seconds', tfc.total_time_seconds,
      'time_rank', tfc.time_rank,
      'time_bonus', tfc.time_bonus,
      'bonus_tempo', tfc.time_bonus,
      'count_partenza_anticipata', tfc.count_partenza_anticipata,
      'partenza_anticipata_seconds_saved', (tfc.count_partenza_anticipata * 120),
      'last_completion', tfc.last_completion,
      -- Token economy
      'tokens_initial', tfc.starting_tokens,
      'starting_tokens', tfc.starting_tokens,
      'tokens_spent_marketplace', tfc.spent_tokens,
      'spent_tokens', tfc.spent_tokens,
      'tokens_gained_rewards', tfc.tokens_gained_rewards,
      'tokens_gained_stage_rewards', tfc.tokens_gained_rewards,
      'token_balance', tfc.current_tokens,
      'remaining_tokens', tfc.current_tokens,
      'token_efficiency_bonus', tfc.token_efficiency_bonus,
      'bonus_token', tfc.token_efficiency_bonus,
      -- Full stages breakdown for accordion
      'stages_breakdown', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'stage_id', st.id,
            'stage_name', st.titolo,
            'stage_order', st.numero_tappa,
            'stage_status', st.stato,
            'stage_total_points', (
              COALESCE((
                SELECT SUM(sc.punti) 
                FROM public.scores sc 
                JOIN public.challenges ch ON ch.id = sc.challenge_id 
                WHERE sc.team_id = tfc.team_id AND ch.stage_id = st.id
              ), 0) +
              COALESCE((
                SELECT SUM(cl.punti)
                FROM public.cattiveria_ledger cl
                WHERE cl.team_id = tfc.team_id AND (cl.stage_id = st.id OR cl.stage_id IS NULL)
              ), 0)
            ),
            'challenges', (
              SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                  'challenge_id', ch.id,
                  'order', ch.ordine_sfida,
                  'title', ch.titolo,
                  'type', ch.tipo_sfida,
                  'max_points', ch.punteggio_massimo,
                  'completed', EXISTS(
                    SELECT 1 FROM public.team_progress tp 
                    WHERE tp.team_id = tfc.team_id AND tp.challenge_id = ch.id AND tp.stato = 'completed'
                  ),
                  'completed_at', (
                    SELECT tp.completata_il FROM public.team_progress tp
                    WHERE tp.team_id = tfc.team_id AND tp.challenge_id = ch.id AND tp.stato = 'completed'
                    LIMIT 1
                  ),
                  'points_awarded', COALESCE((
                    SELECT sc.punti FROM public.scores sc 
                    WHERE sc.team_id = tfc.team_id AND sc.challenge_id = ch.id
                    ORDER BY sc.created_at DESC LIMIT 1
                  ), 0)
                ) ORDER BY ch.ordine_sfida ASC
              ), '[]'::jsonb)
              FROM public.challenges ch
              WHERE ch.stage_id = st.id
            ),
            'bonuses_used', (
              SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                  'transaction_id', mt.id,
                  'item_id', mt.marketplace_item_id,
                  'name', mi.nome,
                  'cost_tokens', mt.costo_token,
                  'is_used', (mt.stato = 'used'),
                  'cattiveria_delta', COALESCE((
                    SELECT cl.punti FROM public.cattiveria_ledger cl
                    WHERE cl.riferimento_transazione = mt.id
                    LIMIT 1
                  ), 0),
                  'timestamp', mt.data_acquisto
                ) ORDER BY mt.data_acquisto ASC
              ), '[]'::jsonb)
              FROM public.marketplace_transactions mt
              JOIN public.marketplace_items mi ON mi.id = mt.marketplace_item_id
              WHERE mt.team_id = tfc.team_id AND LOWER(mi.tipo) = 'bonus' AND (mt.stage_id = st.id OR mt.stage_id IS NULL)
            ),
            'maluses_used', (
              SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                  'transaction_id', mt.id,
                  'item_id', mt.marketplace_item_id,
                  'name', mi.nome,
                  'cost_tokens', mt.costo_token,
                  'target_team_id', mt.target_team_id,
                  'target_team_name', tgt.nome_squadra,
                  'blocked_by_shield', (mt.stato = 'expired' OR (mt.dettagli->>'blocked_by_shield_id') IS NOT NULL),
                  'direct_points_delta', 0,
                  'cattiveria_delta', COALESCE((
                    SELECT cl.punti FROM public.cattiveria_ledger cl
                    WHERE cl.riferimento_transazione = mt.id
                    LIMIT 1
                  ), 10),
                  'status', mt.stato,
                  'timestamp', mt.data_acquisto
                ) ORDER BY mt.data_acquisto ASC
              ), '[]'::jsonb)
              FROM public.marketplace_transactions mt
              JOIN public.marketplace_items mi ON mi.id = mt.marketplace_item_id
              LEFT JOIN public.teams tgt ON tgt.id = mt.target_team_id
              WHERE mt.team_id = tfc.team_id AND LOWER(mi.tipo) = 'malus' AND (mt.stage_id = st.id OR mt.stage_id IS NULL)
            ),
            'maluses_suffered', (
              SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                  'transaction_id', mt.id,
                  'item_id', mt.marketplace_item_id,
                  'name', mi.nome,
                  'attacker_team_id', mt.team_id,
                  'attacker_team_name', atk.nome_squadra,
                  'blocked_by_shield', (mt.stato = 'expired' OR (mt.dettagli->>'blocked_by_shield_id') IS NOT NULL),
                  'points_lost', 0,
                  'status', mt.stato,
                  'timestamp', mt.data_acquisto
                ) ORDER BY mt.data_acquisto ASC
              ), '[]'::jsonb)
              FROM public.marketplace_transactions mt
              JOIN public.marketplace_items mi ON mi.id = mt.marketplace_item_id
              LEFT JOIN public.teams atk ON atk.id = mt.team_id
              WHERE mt.target_team_id = tfc.team_id AND (mt.stage_id = st.id OR mt.stage_id IS NULL)
            ),
            'cattiveria_stage_total', COALESCE((
              SELECT SUM(cl.punti)
              FROM public.cattiveria_ledger cl
              WHERE cl.team_id = tfc.team_id AND (cl.stage_id = st.id OR cl.stage_id IS NULL)
            ), 0),
            'cattiveria_entries', (
              SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                  'id', cl.id,
                  'motivo', cl.motivo,
                  'punti', cl.punti,
                  'timestamp', cl.timestamp
                ) ORDER BY cl.timestamp ASC
              ), '[]'::jsonb)
              FROM public.cattiveria_ledger cl
              WHERE cl.team_id = tfc.team_id AND (cl.stage_id = st.id OR cl.stage_id IS NULL)
            ),
            'stage_reward_tokens', COALESCE((
              SELECT SUM(ABS(mt.costo_token))
              FROM public.marketplace_transactions mt
              WHERE mt.team_id = tfc.team_id AND mt.stage_id = st.id AND (mt.marketplace_item_id = 'reward_stage' OR (mt.dettagli->>'stage_reward')::boolean = true)
            ), 0)
          ) ORDER BY st.numero_tappa ASC
        ), '[]'::jsonb)
        FROM public.stages st
      )
    ) ORDER BY tfc.final_rank ASC
  ), '[]'::jsonb)
  INTO v_teams_report
  FROM team_final_calculated tfc;

  v_full_report := jsonb_build_object(
    'teams', v_teams_report,
    'stages', v_stages_report
  );

  -- 3. Persist calculation atomically in game_report table
  UPDATE public.game_report
  SET 
    status = CASE WHEN status = 'PUBLISHED' THEN 'PUBLISHED' ELSE 'CALCULATED' END,
    state = CASE WHEN status = 'PUBLISHED' THEN 'PUBLISHED_FINAL' ELSE 'PRIVATE_LIVE' END,
    calculated_at = now(),
    calculated_by = v_caller_id,
    calculated_snapshot = v_full_report,
    updated_at = now()
  WHERE id = 'current';

  -- 4. Audit Log
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'CALCULATE_FINAL_RESULTS',
    jsonb_build_object(
      'admin_id', v_caller_id,
      'teams_count', jsonb_array_length(v_teams_report),
      'calculated_at', now()
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'CALCULATED',
    'calculated_at', now(),
    'report', v_full_report
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_stage(p_stage_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.stages SET stato = 'closed' WHERE id = p_stage_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_challenge(p_challenge uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  v_total INTEGER;
  v_completed INTEGER;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN RAISE EXCEPTION 'Non autenticato'; END IF;

  SELECT * INTO v_team FROM public.teams WHERE id = v_team_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Squadra non trovata'; END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = p_challenge;
  IF NOT FOUND THEN RAISE EXCEPTION 'Sfida non trovata'; END IF;

  -- Upsert progress: se esiste aggiorna, se no inserisci (senza stage_id che non esiste nella tabella)
  SELECT * INTO v_prog FROM public.team_progress WHERE team_id = v_team_id AND challenge_id = p_challenge;

  IF FOUND THEN
    IF v_prog.stato = 'completed' THEN
      v_already := true;
    ELSE
      UPDATE public.team_progress SET stato = 'completed', completata_il = now()
      WHERE team_id = v_team_id AND challenge_id = p_challenge;
    END IF;
  ELSE
    -- team_progress NON ha stage_id, quindi non lo mettiamo
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, p_challenge, 'completed', now());
  END IF;

  -- Determina se è sfida fotografica/social
  v_is_photo := (v_challenge.tipo_sfida = 'photo' OR v_challenge.tipo_sfida = 'living_poster' OR v_challenge.tipo_sfida = 'social');

  -- Calcola punti
  IF NOT v_is_photo THEN
    v_points := COALESCE(v_challenge.punteggio_massimo, 0);
    IF v_challenge.tipo_sfida = 'emoji_movies' THEN v_points := 7; END IF;
  END IF;

  -- Assegna punti e log solo se non era già completata
  IF NOT v_already THEN
    -- scores HA stage_id, lo passiamo prendendo v_challenge.stage_id
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (
      v_team_id,
      p_challenge,
      v_challenge.stage_id,
      v_points,
      CASE WHEN v_is_photo THEN 'pending_approval' ELSE 'challenge_points' END,
      CASE WHEN v_is_photo
           THEN 'Foto consegnata — in attesa di valutazione: ' || v_challenge.titolo
           ELSE 'Completamento prova: ' || v_challenge.titolo
      END
    );

    -- Sblocca marketplace alla prima sfida completata
    IF p_challenge = '0147e750-f0a3-4b72-8e76-a003fe2ef143' THEN
      UPDATE public.game_settings SET marketplace_visible = true WHERE id = 'settings_01';
    END IF;
  END IF;

  -- Verifica completamento tappa: join su challenges per ricavare stage_id (team_progress non ce l'ha)
  SELECT COUNT(*)::INTEGER INTO v_total FROM public.challenges WHERE stage_id = v_challenge.stage_id;

  SELECT COUNT(*)::INTEGER INTO v_completed
  FROM public.team_progress tp
  JOIN public.challenges c ON c.id = tp.challenge_id
  WHERE tp.team_id = v_team_id AND c.stage_id = v_challenge.stage_id AND tp.stato = 'completed';

  IF v_total > 0 AND v_completed >= v_total THEN v_stage_completed := true; END IF;

  RETURN jsonb_build_object(
    'already', v_already,
    'points', v_points,
    'bonus', v_bonus,
    'stage_completed', v_stage_completed
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_challenge(p_challenge uuid, p_team_id uuid, p_score integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.confirm_photo_score(p_submission_id uuid, p_points integer, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_sub RECORD;
  v_stage_id UUID;
  v_challenge RECORD;
BEGIN
  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = v_sub.challenge_id;
  v_stage_id := v_challenge.stage_id;

  -- Aggiorna stato approvazione su submissions a 'confirmed'
  UPDATE public.submissions 
  SET stato_approvazione = 'confirmed' 
  WHERE id = p_submission_id;

  -- Segna progresso come completed
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la stessa sfida e inserisce quello nuovo confermato
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_sub.challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, v_stage_id, p_points, 'challenge_points', 'Valutazione foto: ' || COALESCE(v_challenge.titolo, 'Foto'));

  RETURN jsonb_build_object('success', true, 'points', p_points, 'submission_id', p_submission_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.consume_marketplace_transaction(p_transaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.current_team_id()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
BEGIN
  SELECT team_id INTO v_team_id
  FROM public.user_roles
  WHERE user_id = auth.uid() AND role = 'team'
  LIMIT 1;
  
  RETURN v_team_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_team_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF OLD.owner_id IS NOT NULL THEN
    DELETE FROM public.user_roles WHERE user_id = OLD.owner_id;
    DELETE FROM auth.users WHERE id = OLD.owner_id;
  END IF;
  RETURN OLD;
END;
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_poster(p_submission_id uuid, p_approved boolean, p_score integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_poster(p_submission_id uuid, p_voto integer, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_sub RECORD;
  v_challenge RECORD;
  v_stage_id UUID;
BEGIN
  SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sottomissione non trovata';
  END IF;

  SELECT * INTO v_challenge FROM public.challenges WHERE id = v_sub.challenge_id;
  v_stage_id := v_challenge.stage_id;

  -- Aggiorna submission
  UPDATE public.submissions 
  SET voto = p_voto, 
      stato_approvazione = 'confirmed'
  WHERE id = p_submission_id;

  -- Aggiorna progresso team
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_sub.challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la stessa sfida e inserisce quello nuovo
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_sub.challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_sub.challenge_id, v_stage_id, p_voto, 'challenge_points', 'Valutazione Locandina Vivente (' || p_voto || '/15 PT)');

  -- Sblocca visibilità Marketplace nei game_settings se non già visibile
  UPDATE public.game_settings 
  SET marketplace_visible = true 
  WHERE id = 'current' AND marketplace_visible = false;

  RETURN jsonb_build_object('success', true, 'voto', p_voto, 'submission_id', p_submission_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_social_challenge(p_submission_id uuid, p_approved boolean, p_score integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_social_challenge(p_submission_id uuid, p_voto integer, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_sub RECORD;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
  v_stage_id UUID;
BEGIN
  -- Cerca prima in team_social_submissions
  SELECT * INTO v_sub FROM public.team_social_submissions WHERE id = p_submission_id;
  
  IF NOT FOUND THEN
    -- Fallback se passato id da submissions
    SELECT * INTO v_sub FROM public.submissions WHERE id = p_submission_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Sottomissione social non trovata';
    END IF;
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  -- Aggiorna team_social_submissions
  UPDATE public.team_social_submissions 
  SET status = 'approved',
      stato_approvazione = 'confirmed',
      admin_score = p_voto
  WHERE id = p_submission_id OR (team_id = v_sub.team_id AND challenge_id = v_challenge_id);

  -- Aggiorna anche submissions principale se presente
  UPDATE public.submissions 
  SET stato_approvazione = 'confirmed',
      voto = p_voto
  WHERE team_id = v_sub.team_id AND challenge_id = v_challenge_id;

  -- Segna progresso come completato
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_sub.team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) 
  DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());

  -- Rimuove eventuale vecchio punteggio per la missione social e inserisce il voto confermato
  DELETE FROM public.scores 
  WHERE team_id = v_sub.team_id AND challenge_id = v_challenge_id;

  INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
  VALUES (v_sub.team_id, v_challenge_id, v_stage_id, p_voto, 'challenge_points', 'Valutazione Missione Social (' || p_voto || '/20 PT)');

  RETURN jsonb_build_object('success', true, 'voto', p_voto, 'submission_id', p_submission_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_boxe_tournament(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_existing_count INTEGER;
  v_special_bye_team_id UUID;
  v_active_teams UUID[];
  v_sorted_teams UUID[];
  v_team UUID;
  v_n INTEGER;
  v_virtual_n INTEGER;
  v_k INTEGER;
  v_num_matches INTEGER;
  v_num_byes INTEGER;
  v_num_tech_byes INTEGER;
  v_total_rounds INTEGER;
  v_round INTEGER;
  v_matches_in_round INTEGER;
  v_m INTEGER;
  v_team_idx INTEGER;
  v_res JSONB;
  v_cm RECORD;
  v_next_match_idx INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_existing_count FROM public.boxe_matches WHERE challenge_id = v_challenge_id;
  IF v_existing_count > 0 THEN
    RAISE EXCEPTION 'Il torneo è già stato generato.';
  END IF;

  SELECT ARRAY_AGG(id ORDER BY random()) INTO v_active_teams
  FROM public.teams WHERE active = true;

  v_n := COALESCE(array_length(v_active_teams, 1), 0);
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Nessuna squadra attiva per generare il torneo.';
  END IF;

  SELECT boxe_special_bye_team_id INTO v_special_bye_team_id
  FROM public.game_settings LIMIT 1;

  v_sorted_teams := ARRAY[]::UUID[];
  IF v_special_bye_team_id IS NOT NULL AND v_special_bye_team_id = ANY(v_active_teams) THEN
    v_sorted_teams := array_append(v_sorted_teams, v_special_bye_team_id);
    FOREACH v_team IN ARRAY v_active_teams LOOP
      IF v_team <> v_special_bye_team_id THEN
        v_sorted_teams := array_append(v_sorted_teams, v_team);
      END IF;
    END LOOP;
    v_virtual_n := v_n + 1;
  ELSE
    v_sorted_teams := v_active_teams;
    v_virtual_n := v_n;
    v_special_bye_team_id := NULL;
  END IF;

  v_k := 2;
  WHILE v_k < v_virtual_n LOOP
    v_k := v_k * 2;
  END LOOP;

  v_num_matches := v_k / 2;
  v_num_byes := v_k - v_n;
  IF v_special_bye_team_id IS NOT NULL THEN
    v_num_tech_byes := GREATEST(0, v_num_byes - 1);
  ELSE
    v_num_tech_byes := v_num_byes;
  END IF;

  v_total_rounds := (ln(v_k) / ln(2))::INTEGER;

  FOR v_round IN 0..(v_total_rounds - 1) LOOP
    v_matches_in_round := (v_k / (2 ^ (v_round + 1)))::INTEGER;
    FOR v_m IN 0..(v_matches_in_round - 1) LOOP
      INSERT INTO public.boxe_matches (
        id, stage_id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, is_special_bye
      ) VALUES (
        gen_random_uuid(), v_stage_id, v_challenge_id, v_round, v_m, NULL, NULL, NULL, 'pending', NULL, false
      );
    END LOOP;
  END LOOP;

  v_team_idx := 1;
  FOR v_m IN 0..(v_num_matches - 1) LOOP
    IF v_m = 0 AND v_special_bye_team_id IS NOT NULL THEN
      UPDATE public.boxe_matches
      SET team1_id = v_special_bye_team_id,
          team2_id = NULL,
          winner_id = v_special_bye_team_id,
          status = 'completed',
          completed_at = now(),
          is_special_bye = true
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = 0;
      v_team_idx := v_team_idx + 1;
    ELSIF v_m > 0 AND v_m <= v_num_tech_byes THEN
      UPDATE public.boxe_matches
      SET team1_id = v_sorted_teams[v_team_idx],
          team2_id = NULL,
          winner_id = v_sorted_teams[v_team_idx],
          status = 'completed',
          completed_at = now()
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
      v_team_idx := v_team_idx + 1;
    ELSE
      UPDATE public.boxe_matches
      SET team1_id = v_sorted_teams[v_team_idx],
          team2_id = v_sorted_teams[v_team_idx + 1],
          status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
      v_team_idx := v_team_idx + 2;
    END IF;
  END LOOP;

  FOR v_round IN 0..(v_total_rounds - 2) LOOP
    FOR v_cm IN (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id AND round = v_round AND status = 'completed' AND winner_id IS NOT NULL) LOOP
      v_next_match_idx := (v_cm.match_index / 2)::INTEGER;
      IF v_cm.match_index % 2 = 0 THEN
        UPDATE public.boxe_matches SET team1_id = v_cm.winner_id
        WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
      ELSE
        UPDATE public.boxe_matches SET team2_id = v_cm.winner_id
        WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
      END IF;

      UPDATE public.boxe_matches SET status = 'ready'
      WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
    END LOOP;
  END LOOP;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_bank_state(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_team_id UUID;
  v_answers JSONB;
  v_questions JSONB;
  v_progress RECORD;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  -- Recupera risposte corrette del team
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'question_number', question_number,
    'answer', answer,
    'extracted_letter', extracted_letter
  ) ORDER BY question_number), '[]'::jsonb) INTO v_answers
  FROM public.team_bank_answers
  WHERE team_id = p_team_id;

  -- Domande originali da localhost / local_database.json
  v_questions := '[
    {"question_number": 1, "question_text": "Lo usi per prelevare contanti senza fare la fila allo sportello", "length": 8},
    {"question_number": 2, "question_text": "Il codice segreto a 4 cifre che non devi mai dire a nessuno", "length": 3},
    {"question_number": 3, "question_text": "La moneta che hai in tasca in tutta Europa", "length": 4},
    {"question_number": 4, "question_text": "La scadenza mensile del mutuo, incubo di ogni famiglia", "length": 4}
  ]'::jsonb;

  SELECT * INTO v_progress FROM public.team_progress
  WHERE team_id = p_team_id AND challenge_id = 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';

  RETURN jsonb_build_object(
    'progress', jsonb_build_object('status', COALESCE(v_progress.stato, 'locked')),
    'answers', v_answers,
    'all_questions', v_questions
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_boxe_settings()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_cornhole_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_special_bye_team_id UUID;
  v_has_started BOOLEAN;
  v_first_place_team_id UUID;
BEGIN
  SELECT boxe_special_bye_team_id INTO v_special_bye_team_id
  FROM public.game_settings
  LIMIT 1;

  SELECT EXISTS(
    SELECT 1 FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  SELECT winner_id INTO v_first_place_team_id
  FROM public.cornhole_matches
  WHERE challenge_id = v_cornhole_challenge_id AND round = (SELECT MAX(round) FROM public.cornhole_matches WHERE challenge_id = v_cornhole_challenge_id)
  LIMIT 1;

  RETURN jsonb_build_object(
    'special_bye_team_id', v_special_bye_team_id,
    'started', v_has_started,
    'first_place_stage4_3', v_first_place_team_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_boxe_tournament()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_res JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (
    SELECT * FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id 
    ORDER BY round ASC, match_index ASC
  ) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_cornhole_settings()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_enigma3_id UUID := 'e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9';
  v_special_bye_team_id UUID;
  v_has_started BOOLEAN;
  v_first_place_team_id UUID;
BEGIN
  SELECT cornhole_special_bye_team_id INTO v_special_bye_team_id
  FROM public.game_settings
  LIMIT 1;

  SELECT EXISTS(
    SELECT 1 FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  SELECT team_id INTO v_first_place_team_id
  FROM public.team_progress
  WHERE challenge_id = v_enigma3_id AND stato = 'completed'
  ORDER BY completata_il ASC
  LIMIT 1;

  RETURN jsonb_build_object(
    'special_bye_team_id', v_special_bye_team_id,
    'started', v_has_started,
    'first_place_stage4_3', v_first_place_team_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_cornhole_tournament()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_existing_count INTEGER;
  v_special_bye_team_id UUID;
  v_active_teams UUID[];
  v_sorted_teams UUID[];
  v_team UUID;
  v_n INTEGER;
  v_virtual_n INTEGER;
  v_k INTEGER;
  v_num_matches INTEGER;
  v_num_byes INTEGER;
  v_num_tech_byes INTEGER;
  v_total_rounds INTEGER;
  v_round INTEGER;
  v_matches_in_round INTEGER;
  v_m INTEGER;
  v_team_idx INTEGER;
  v_match_id UUID;
  v_res JSONB;
  v_cm RECORD;
  v_next_match_idx INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_existing_count 
  FROM public.cornhole_matches 
  WHERE challenge_id = v_challenge_id;

  IF v_existing_count = 0 THEN
    -- Recupera squadre attive
    SELECT ARRAY_AGG(id ORDER BY nome_squadra ASC) INTO v_active_teams
    FROM public.teams
    WHERE active = true;

    v_n := COALESCE(array_length(v_active_teams, 1), 0);
    IF v_n = 0 THEN
      RETURN '[]'::jsonb;
    END IF;

    SELECT cornhole_special_bye_team_id INTO v_special_bye_team_id
    FROM public.game_settings LIMIT 1;

    -- Se presente special bye valido, mettilo come primo
    v_sorted_teams := ARRAY[]::UUID[];
    IF v_special_bye_team_id IS NOT NULL AND v_special_bye_team_id = ANY(v_active_teams) THEN
      v_sorted_teams := array_append(v_sorted_teams, v_special_bye_team_id);
      FOREACH v_team IN ARRAY v_active_teams LOOP
        IF v_team <> v_special_bye_team_id THEN
          v_sorted_teams := array_append(v_sorted_teams, v_team);
        END IF;
      END LOOP;
      v_virtual_n := v_n + 1;
    ELSE
      v_sorted_teams := v_active_teams;
      v_virtual_n := v_n;
      v_special_bye_team_id := NULL;
    END IF;

    -- Calcolo dimensione tabellone K (potenza di 2)
    v_k := 2;
    WHILE v_k < v_virtual_n LOOP
      v_k := v_k * 2;
    END LOOP;

    v_num_matches := v_k / 2;
    v_num_byes := v_k - v_n;
    IF v_special_bye_team_id IS NOT NULL THEN
      v_num_tech_byes := GREATEST(0, v_num_byes - 1);
    ELSE
      v_num_tech_byes := v_num_byes;
    END IF;

    v_total_rounds := (ln(v_k) / ln(2))::INTEGER;

    -- Inserisci tutti i match vuoti
    FOR v_round IN 0..(v_total_rounds - 1) LOOP
      v_matches_in_round := (v_k / (2 ^ (v_round + 1)))::INTEGER;
      FOR v_m IN 0..(v_matches_in_round - 1) LOOP
        INSERT INTO public.cornhole_matches (
          id, stage_id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, is_special_bye
        ) VALUES (
          gen_random_uuid(), v_stage_id, v_challenge_id, v_round, v_m, NULL, NULL, NULL, 'pending', NULL, false
        );
      END LOOP;
    END LOOP;

    -- Popola Round 0
    v_team_idx := 1;
    FOR v_m IN 0..(v_num_matches - 1) LOOP
      IF v_m = 0 AND v_special_bye_team_id IS NOT NULL THEN
        UPDATE public.cornhole_matches
        SET team1_id = v_special_bye_team_id,
            team2_id = NULL,
            winner_id = v_special_bye_team_id,
            status = 'completed',
            completed_at = now(),
            is_special_bye = true
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = 0;
        v_team_idx := v_team_idx + 1;
      ELSIF v_m > 0 AND v_m <= v_num_tech_byes THEN
        UPDATE public.cornhole_matches
        SET team1_id = v_sorted_teams[v_team_idx],
            team2_id = NULL,
            winner_id = v_sorted_teams[v_team_idx],
            status = 'completed',
            completed_at = now()
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
        v_team_idx := v_team_idx + 1;
      ELSE
        UPDATE public.cornhole_matches
        SET team1_id = v_sorted_teams[v_team_idx],
            team2_id = v_sorted_teams[v_team_idx + 1],
            status = 'ready'
        WHERE challenge_id = v_challenge_id AND round = 0 AND match_index = v_m;
        v_team_idx := v_team_idx + 2;
      END IF;
    END LOOP;

    -- Propaga i vincitori dei bye al Round 1
    FOR v_round IN 0..(v_total_rounds - 2) LOOP
      FOR v_cm IN (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id AND round = v_round AND status = 'completed' AND winner_id IS NOT NULL) LOOP
        v_next_match_idx := (v_cm.match_index / 2)::INTEGER;
        IF v_cm.match_index % 2 = 0 THEN
          UPDATE public.cornhole_matches SET team1_id = v_cm.winner_id
          WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
        ELSE
          UPDATE public.cornhole_matches SET team2_id = v_cm.winner_id
          WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx;
        END IF;

        UPDATE public.cornhole_matches SET status = 'ready'
        WHERE challenge_id = v_challenge_id AND round = v_round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
      END LOOP;
    END LOOP;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (
    SELECT * FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id 
    ORDER BY round ASC, match_index ASC
  ) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_enigma_state(p_challenge_id uuid, p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_attempts JSONB;
  v_is_completed BOOLEAN;
  v_prog RECORD;
BEGIN
  -- Admin può passare p_team_id, il team usa il proprio id
  v_team_id := COALESCE(p_team_id, public.current_team_id());
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_prog FROM public.team_progress
  WHERE team_id = v_team_id AND challenge_id = p_challenge_id;

  v_is_completed := (FOUND AND v_prog.stato = 'completed');

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', ea.id,
      'attempt_number', ea.attempt_number,
      'answer', ea.answer,
      'is_correct', ea.is_correct,
      'submitted_at', ea.submitted_at
    ) ORDER BY ea.attempt_number
  ), '[]'::jsonb)
  INTO v_attempts
  FROM public.enigma_attempts ea
  WHERE ea.team_id = v_team_id AND ea.challenge_id = p_challenge_id;

  RETURN jsonb_build_object(
    'attempts', v_attempts,
    'attempt_count', jsonb_array_length(v_attempts),
    'is_completed', v_is_completed,
    'completed_at', CASE WHEN v_is_completed THEN v_prog.completata_il ELSE NULL END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_game_report(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_is_admin BOOLEAN := false;
  v_report RECORD;
BEGIN
  v_caller_id := COALESCE(auth.uid(), p_user_id);

  -- Check if caller is admin
  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
  END IF;

  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';

  -- IF NOT ADMIN:
  IF NOT COALESCE(v_is_admin, false) THEN
    -- If not published, strictly return null/locked status
    IF COALESCE(v_report.status, 'NOT_CALCULATED') != 'PUBLISHED' THEN
      RETURN jsonb_build_object(
        'is_published', false,
        'status', 'NOT_PUBLISHED',
        'published_at', NULL,
        'report', NULL
      );
    END IF;

    -- If published, return the frozen snapshot
    RETURN jsonb_build_object(
      'is_published', true,
      'status', 'PUBLISHED',
      'published_at', v_report.published_at,
      'report', v_report.snapshot
    );
  END IF;

  -- IF ADMIN:
  IF v_report.status = 'PUBLISHED' THEN
    RETURN jsonb_build_object(
      'is_published', true,
      'status', 'PUBLISHED',
      'calculated_at', v_report.calculated_at,
      'published_at', v_report.published_at,
      'report', COALESCE(v_report.snapshot, v_report.calculated_snapshot)
    );
  ELSIF v_report.status = 'CALCULATED' THEN
    RETURN jsonb_build_object(
      'is_published', false,
      'status', 'CALCULATED',
      'calculated_at', v_report.calculated_at,
      'published_at', NULL,
      'report', v_report.calculated_snapshot
    );
  ELSE
    RETURN jsonb_build_object(
      'is_published', false,
      'status', 'NOT_CALCULATED',
      'calculated_at', NULL,
      'published_at', NULL,
      'report', NULL
    );
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_jackpot_plays(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_res JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(p)), '[]'::jsonb) INTO v_res
  FROM (
    SELECT * FROM public.jackpot_plays
    WHERE challenge_id = v_challenge_id
    ORDER BY timestamp DESC
  ) p;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_jackpot_state(p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_play RECORD;
  v_current_score INTEGER := 0;
BEGIN
  v_team_id := COALESCE(p_team_id, public.current_team_id());

  IF v_team_id IS NOT NULL THEN
    SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_current_score
    FROM public.scores
    WHERE team_id = v_team_id;

    SELECT * INTO v_play
    FROM public.jackpot_plays
    WHERE team_id = v_team_id AND challenge_id = v_challenge_id
    ORDER BY timestamp DESC
    LIMIT 1;

    IF v_play.id IS NOT NULL THEN
      RETURN jsonb_build_object(
        'played', true,
        'play', row_to_json(v_play),
        'current_score', v_current_score
      );
    ELSE
      RETURN jsonb_build_object(
        'played', false,
        'play', NULL,
        'current_score', v_current_score
      );
    END IF;
  ELSE
    RETURN jsonb_build_object(
      'played', false,
      'play', NULL,
      'current_score', 0
    );
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_or_assign_poster(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
    IF FOUND THEN
      RETURN jsonb_build_object(
        'id', v_poster.id,
        'file_name', v_poster.file_name,
        'titolo', v_poster.titolo,
        'poster', jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo),
        'assigned', v_assigned
      );
    END IF;
  END IF;

  -- Altrimenti assegna il primo poster disponibile
  SELECT p.* INTO v_poster
  FROM public.posters p
  LEFT JOIN public.team_posters tp ON tp.poster_id = p.id
  WHERE p.active = true
  GROUP BY p.id, p.file_name, p.titolo
  ORDER BY COUNT(tp.id) ASC, p.id ASC
  LIMIT 1;

  IF FOUND THEN
    INSERT INTO public.team_posters (team_id, poster_id)
    VALUES (p_team_id, v_poster.id)
    ON CONFLICT (team_id) DO UPDATE SET poster_id = EXCLUDED.poster_id;

    RETURN jsonb_build_object(
      'id', v_poster.id,
      'file_name', v_poster.file_name,
      'titolo', v_poster.titolo,
      'poster', jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo),
      'assigned', jsonb_build_object('team_id', p_team_id, 'poster_id', v_poster.id)
    );
  END IF;

  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_report_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_report RECORD;
BEGIN
  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';
  RETURN jsonb_build_object(
    'status', COALESCE(v_report.status, 'NOT_CALCULATED'),
    'is_calculated', (v_report.status IN ('CALCULATED', 'PUBLISHED')),
    'is_published', (v_report.status = 'PUBLISHED'),
    'calculated_at', v_report.calculated_at,
    'published_at', v_report.published_at
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_secret_code_state(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_team_id UUID;
  v_full_code TEXT;
  v_destination TEXT;
  v_part RECORD;
  v_match RECORD;
  v_seller_name TEXT := 'Regia';
  v_first5 TEXT;
  v_last5 TEXT;
  v_has_purchased BOOLEAN := false;
  v_purchased_digits TEXT := NULL;
  v_completed BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_other_team RECORD;
  v_team_idx INTEGER := 0;
  v_part_type TEXT;
  v_code_val TEXT;
  v_cost INTEGER := 4;
BEGIN
  v_caller_team_id := public.current_team_id();
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  SELECT full_code, next_stage_destination 
  INTO v_full_code, v_destination 
  FROM public.game_final_code 
  WHERE id = 'current' 
  LIMIT 1;

  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;
  IF v_destination IS NULL THEN v_destination := 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)'; END IF;

  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- 1. Assegna/Recupera frammento per il team
  SELECT * INTO v_part FROM public.team_code_parts WHERE team_id = p_team_id;
  IF NOT FOUND THEN
    SELECT (COUNT(*) % 2) INTO v_team_idx FROM public.team_code_parts;
    IF v_team_idx = 1 THEN
      v_part_type := 'LAST_5';
      v_code_val := v_last5;
    ELSE
      v_part_type := 'FIRST_5';
      v_code_val := v_first5;
    END IF;

    INSERT INTO public.team_code_parts (team_id, code_part, part_type)
    VALUES (p_team_id, v_code_val, v_part_type)
    ON CONFLICT (team_id) DO NOTHING;

    SELECT * INTO v_part FROM public.team_code_parts WHERE team_id = p_team_id;
  END IF;

  -- 2. Assegna/Recupera match (partner e costo tra 3 e 5 token, default 4)
  SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  IF NOT FOUND THEN
    SELECT * INTO v_other_team 
    FROM public.teams 
    WHERE id <> p_team_id AND active = true 
    ORDER BY created_at ASC 
    LIMIT 1;

    v_cost := 4;
    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (
      p_team_id, 
      COALESCE(v_other_team.id, p_team_id), 
      CASE WHEN v_part.part_type = 'FIRST_5' THEN 'LAST_5' ELSE 'FIRST_5' END,
      v_cost
    )
    ON CONFLICT (buyer_team_id) DO NOTHING;

    SELECT * INTO v_match FROM public.team_code_matches WHERE buyer_team_id = p_team_id;
  END IF;

  IF v_match.seller_team_id IS NOT NULL AND v_match.seller_team_id <> p_team_id THEN
    SELECT COALESCE(nome_squadra, 'Altra Squadra') INTO v_seller_name FROM public.teams WHERE id = v_match.seller_team_id;
  ELSE
    v_seller_name := 'Regia';
  END IF;

  -- 3. Controlla se ha acquistato il frammento
  SELECT EXISTS(
    SELECT 1 FROM public.code_purchase_transactions WHERE buyer_team_id = p_team_id
  ) INTO v_has_purchased;

  IF v_has_purchased THEN
    SELECT digits_received INTO v_purchased_digits 
    FROM public.code_purchase_transactions 
    WHERE buyer_team_id = p_team_id 
    LIMIT 1;

    IF v_purchased_digits IS NULL THEN
      v_purchased_digits := CASE WHEN v_part.part_type = 'FIRST_5' THEN v_last5 ELSE v_first5 END;
    END IF;
  END IF;

  -- 4. Controlla completamento
  SELECT EXISTS(
    SELECT 1 FROM public.team_progress
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND stato = 'completed'
  ) INTO v_completed;

  RETURN jsonb_build_object(
    'part', jsonb_build_object('code_part', v_part.code_part, 'part_type', v_part.part_type),
    'match', CASE WHEN v_match.id IS NOT NULL THEN jsonb_build_object(
      'seller_team_id', v_match.seller_team_id,
      'seller_name', v_seller_name,
      'required_part', v_match.required_part,
      'token_cost', COALESCE(v_match.token_cost, 4)
    ) ELSE NULL END,
    'has_purchased', v_has_purchased,
    'purchased_digits', v_purchased_digits,
    'completed', v_completed,
    'destination', v_destination
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_secure_leaderboard()
 RETURNS TABLE(team_id uuid, name text, color text, avatar_url text, motto text, challenges_points numeric, modifier_points numeric, cattiveria_points numeric, total_points numeric, completed_challenges bigint, total_duration_seconds numeric, last_completion timestamp with time zone, active boolean, freeze_started_at timestamp with time zone, freeze_expires_at timestamp with time zone, rank integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_caller_team_id UUID;
  v_is_admin BOOLEAN := false;
  v_has_bonus BOOLEAN := false;
  v_report_status TEXT;
BEGIN
  v_caller_id := auth.uid();

  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
    SELECT t.id INTO v_caller_team_id FROM public.teams t WHERE t.owner_id = v_caller_id;
  END IF;

  SELECT status INTO v_report_status FROM public.game_report WHERE id = 'current';

  -- Full leaderboard visible if admin, if game report is published, or if team has active bonus_classifica
  IF COALESCE(v_is_admin, false) OR COALESCE(v_report_status, 'NOT_CALCULATED') = 'PUBLISHED' THEN
    v_has_bonus := true;
  ELSIF v_caller_team_id IS NOT NULL THEN
    SELECT EXISTS(
      SELECT 1 FROM public.marketplace_transactions mt
      WHERE mt.team_id = v_caller_team_id
        AND mt.marketplace_item_id = 'bonus_classifica'
        AND mt.stato IN ('completed', 'viewing')
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
      COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)::NUMERIC AS l_catt_pts,
      (
        COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) +
        COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)
      )::NUMERIC AS l_tot_pts,
      (SELECT COUNT(DISTINCT tp.challenge_id) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed') AS l_comp_ch,
      GREATEST(0, (
        COALESCE((
          SELECT SUM(rs.duration_seconds) FROM public.race_sessions rs WHERE rs.team_id = t.id
        ), EXTRACT(EPOCH FROM (
          COALESCE((SELECT MAX(tp.completata_il) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed'), t.created_at) - t.created_at
        )))::NUMERIC + 
        COALESCE((
          SELECT (SUM(tp.minuti_penalita) * 60)::NUMERIC FROM public.time_penalties tp WHERE tp.team_id = t.id
        ), 0) -
        (
          COALESCE((
            SELECT COUNT(*) 
            FROM public.marketplace_transactions mt 
            WHERE mt.team_id = t.id 
              AND mt.marketplace_item_id = 'partenza_anticipata' 
              AND mt.stato != 'blocked'
          ), 0) * 120
        )::NUMERIC
      )) AS l_duration,
      (SELECT MAX(tp.completata_il) FROM public.team_progress tp WHERE tp.team_id = t.id AND tp.stato = 'completed') AS l_last_comp,
      t.active AS l_active,
      t.freeze_started_at AS l_freeze_start,
      t.freeze_expires_at AS l_freeze_exp
    FROM public.teams t
  ),
  ranked_leaderboard AS (
    SELECT 
      rb.*,
      ROW_NUMBER() OVER (
        ORDER BY rb.l_active DESC, rb.l_comp_ch DESC, rb.l_tot_pts DESC, rb.l_duration ASC, rb.l_last_comp ASC NULLS LAST
      )::INTEGER AS l_rank
    FROM raw_leaderboard rb
  )
  SELECT 
    rl.l_team_id, rl.l_name, rl.l_color, rl.l_avatar_url, rl.l_motto, rl.l_ch_pts, rl.l_mod_pts, rl.l_catt_pts, rl.l_tot_pts, rl.l_comp_ch, rl.l_duration, rl.l_last_comp, rl.l_active, rl.l_freeze_start, rl.l_freeze_exp, rl.l_rank
  FROM ranked_leaderboard rl
  WHERE v_has_bonus = true OR rl.l_team_id = v_caller_team_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_social_submission()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
    'team_id', v_sub.team_id,
    'challenge_id', v_sub.challenge_id,
    'image_1_url', COALESCE(v_sub.image_1_url, v_sub.social_url),
    'image_2_url', v_sub.image_2_url,
    'status', COALESCE(v_sub.status, 'submitted'),
    'stato_approvazione', v_sub.stato_approvazione,
    'admin_score', v_sub.admin_score,
    'uploaded_at', COALESCE(v_sub.uploaded_at, v_sub.created_at)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.initialize_secret_code_challenge()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_teams UUID[];
  v_count INTEGER;
  v_i INTEGER;
  v_full_code TEXT := '4829167305';
  v_first5 TEXT;
  v_last5 TEXT;
  v_buyer_id UUID;
  v_seller_id UUID;
  v_part_type TEXT;
  v_required_type TEXT;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT full_code INTO v_full_code FROM public.game_final_code WHERE id = 'current';
  IF v_full_code IS NULL THEN v_full_code := '4829167305'; END IF;

  v_first5 := SUBSTRING(v_full_code FROM 1 FOR 5);
  v_last5 := SUBSTRING(v_full_code FROM 6 FOR 5);

  -- Collect active teams
  SELECT array_agg(id ORDER BY created_at ASC) INTO v_teams
  FROM public.teams
  WHERE active = true;

  v_count := COALESCE(array_length(v_teams, 1), 0);
  IF v_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nessuna squadra attiva trovata.');
  END IF;

  -- Clear previous assignments if regenerating
  DELETE FROM public.team_code_matches;
  DELETE FROM public.team_code_parts;

  -- Assign parts: alternating FIRST_5 and LAST_5
  FOR v_i IN 1..v_count LOOP
    v_buyer_id := v_teams[v_i];
    
    IF v_i % 2 = 1 THEN
      v_part_type := 'FIRST_5';
      v_required_type := 'LAST_5';
      INSERT INTO public.team_code_parts (team_id, code_part, part_type)
      VALUES (v_buyer_id, v_first5, 'FIRST_5')
      ON CONFLICT (team_id) DO UPDATE SET code_part = v_first5, part_type = 'FIRST_5';
    ELSE
      v_part_type := 'LAST_5';
      v_required_type := 'FIRST_5';
      INSERT INTO public.team_code_parts (team_id, code_part, part_type)
      VALUES (v_buyer_id, v_last5, 'LAST_5')
      ON CONFLICT (team_id) DO UPDATE SET code_part = v_last5, part_type = 'LAST_5';
    END IF;

    -- Pair with next team in circle (cyclic matching)
    IF v_count > 1 THEN
      IF v_i < v_count THEN
        v_seller_id := v_teams[v_i + 1];
      ELSE
        v_seller_id := v_teams[1];
      END IF;
    ELSE
      v_seller_id := v_buyer_id;
    END IF;

    INSERT INTO public.team_code_matches (buyer_team_id, seller_team_id, required_part, token_cost)
    VALUES (v_buyer_id, v_seller_id, v_required_type, 4)
    ON CONFLICT (buyer_team_id) 
    DO UPDATE SET seller_team_id = v_seller_id, required_part = v_required_type, token_cost = 4;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'message', 'Abbinamenti e frammenti codice segreto configurati per ' || v_count || ' squadre.');
END;
$function$;

CREATE OR REPLACE FUNCTION public.mark_partenza_used(p_transaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
  v_is_admin := public.has_role(auth.uid(), 'admin') OR (p_admin_id IS NOT NULL AND public.has_role(p_admin_id, 'admin'));
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
  WHERE id = p_transaction_id AND team_id = v_team_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transazione non trovata';
  END IF;

  IF v_tx.marketplace_item_id != 'bonus_classifica' THEN
    RAISE EXCEPTION 'Transazione non abbinata al bonus classifica';
  END IF;

  IF v_tx.stato = 'completed' THEN
    -- Generate snapshot of current leaderboard
    SELECT jsonb_agg(jsonb_build_object(
      'team_id', t.id,
      'name', t.nome_squadra,
      'color', t.color,
      'avatar_url', t.avatar_url,
      'total_points', COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) + COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)
    ) ORDER BY (COALESCE((SELECT SUM(s.punti) FROM public.scores s WHERE s.team_id = t.id), 0) + COALESCE((SELECT SUM(c.punti) FROM public.cattiveria_ledger c WHERE c.team_id = t.id), 0)) DESC)
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

CREATE OR REPLACE FUNCTION public.play_jackpot(p_team_id uuid DEFAULT NULL::uuid, p_puntata integer DEFAULT 10)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_already_played BOOLEAN;
  v_current_score INTEGER := 0;
  v_pool TEXT[] := ARRAY['🍒', '🍋', '🔔', '💎'];
  v_s1 INTEGER;
  v_s2 INTEGER;
  v_s3 INTEGER;
  v_sym1 TEXT;
  v_sym2 TEXT;
  v_sym3 TEXT;
  v_simboli TEXT;
  v_is_win BOOLEAN;
  v_risultato TEXT;
  v_variazione INTEGER;
  v_nuovo_punteggio INTEGER;
  v_play_id UUID;
  v_play RECORD;
BEGIN
  v_team_id := COALESCE(p_team_id, public.current_team_id());
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Squadra non identificata.';
  END IF;

  PERFORM 1 FROM public.teams WHERE id = v_team_id FOR UPDATE;

  SELECT EXISTS(
    SELECT 1 FROM public.jackpot_plays
    WHERE team_id = v_team_id AND challenge_id = v_challenge_id
  ) INTO v_already_played;

  IF v_already_played THEN
    RAISE EXCEPTION 'La tua squadra ha già tentato il Jackpot della Regia.';
  END IF;

  SELECT COALESCE(SUM(punti), 0)::INTEGER INTO v_current_score
  FROM public.scores
  WHERE team_id = v_team_id;

  IF p_puntata < 5 OR p_puntata > 20 THEN
    RAISE EXCEPTION 'La puntata deve essere compresa tra 5 e 20 punti.';
  END IF;

  IF p_puntata > v_current_score THEN
    RAISE EXCEPTION 'Non puoi scommettere più punti di quelli che possiedi (% PT attuali).', v_current_score;
  END IF;

  v_s1 := 1 + floor(random() * 4)::INTEGER;
  v_s2 := 1 + floor(random() * 4)::INTEGER;
  v_s3 := 1 + floor(random() * 4)::INTEGER;

  v_sym1 := v_pool[v_s1];
  v_sym2 := v_pool[v_s2];
  v_sym3 := v_pool[v_s3];
  v_simboli := v_sym1 || ',' || v_sym2 || ',' || v_sym3;

  v_is_win := (v_s1 = v_s2 AND v_s2 = v_s3);
  v_risultato := CASE WHEN v_is_win THEN 'vinta' ELSE 'persa' END;
  v_variazione := CASE WHEN v_is_win THEN p_puntata ELSE -p_puntata END;
  v_nuovo_punteggio := v_current_score + v_variazione;

  v_play_id := gen_random_uuid();

  INSERT INTO public.jackpot_plays (
    id, team_id, challenge_id, puntata, puntata_punti, simboli, risultato, variazione, delta_punti, punteggio_precedente, punteggio_attuale, timestamp
  ) VALUES (
    v_play_id, v_team_id, v_challenge_id, p_puntata, p_puntata, v_simboli, v_risultato, v_variazione, v_variazione, v_current_score, v_nuovo_punteggio, now()
  );

  INSERT INTO public.scores (
    team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo
  ) VALUES (
    v_team_id, v_challenge_id, v_stage_id, v_variazione, 'challenge_points', 'Jackpot della Regia: ' || UPPER(v_risultato) || ' (' || v_sym1 || ' ' || v_sym2 || ' ' || v_sym3 || ')'
  );

  INSERT INTO public.team_progress (
    team_id, challenge_id, stato, completata_il
  ) VALUES (
    v_team_id, v_challenge_id, 'completed', now()
  )
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET stato = 'completed', completata_il = now();

  SELECT * INTO v_play FROM public.jackpot_plays WHERE id = v_play_id;

  RETURN row_to_json(v_play);
END;
$function$;

CREATE OR REPLACE FUNCTION public.publish_game_report(p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_caller_id UUID;
  v_is_admin BOOLEAN := false;
  v_report RECORD;
  v_snapshot JSONB;
BEGIN
  v_caller_id := COALESCE(auth.uid(), p_admin_id);

  -- Check Admin Authorization
  IF v_caller_id IS NOT NULL THEN
    SELECT public.has_role(v_caller_id, 'admin') INTO v_is_admin;
  END IF;

  IF NOT COALESCE(v_is_admin, false) THEN
    RAISE EXCEPTION 'Access Denied: Only Admin can publish final results.';
  END IF;

  SELECT * INTO v_report FROM public.game_report WHERE id = 'current';

  -- Enforce calculation before publication
  IF v_report.status = 'NOT_CALCULATED' OR v_report.calculated_snapshot IS NULL THEN
    -- Auto-calculate before publish if not yet done
    PERFORM public.calculate_final_game_results(v_caller_id);
    SELECT * INTO v_report FROM public.game_report WHERE id = 'current';
  END IF;

  v_snapshot := v_report.calculated_snapshot;

  -- Update to PUBLISHED status
  UPDATE public.game_report
  SET 
    status = 'PUBLISHED',
    state = 'PUBLISHED_FINAL',
    published_at = now(),
    published_by = v_caller_id,
    snapshot = v_snapshot,
    updated_at = now()
  WHERE id = 'current';

  -- Audit Log
  INSERT INTO public.activity_log (tipo_evento, dettagli)
  VALUES (
    'PUBLISH_FINAL_RESULTS',
    jsonb_build_object(
      'admin_id', v_caller_id,
      'published_at', now()
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'status', 'PUBLISHED',
    'published_at', now()
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.reopen_stage(p_stage_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  UPDATE public.stages SET stato = 'open' WHERE id = p_stage_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.respond_passaparola_request(p_transaction_id uuid, p_response text, p_nota_interna text DEFAULT NULL::text, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN := false;
  v_tx RECORD;
  v_team_name TEXT;
BEGIN
  v_is_admin := public.has_role(auth.uid(), 'admin') OR (p_admin_id IS NOT NULL AND public.has_role(p_admin_id, 'admin'));
  IF NOT v_is_admin THEN
    RETURN jsonb_build_object('success', false, 'error', 'Non autorizzato');
  END IF;

  SELECT * INTO v_tx FROM public.marketplace_transactions WHERE id = p_transaction_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transazione non trovata');
  END IF;

  IF v_tx.stato != 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'La richiesta non è in attesa di risposta');
  END IF;

  UPDATE public.marketplace_transactions
  SET 
    stato = 'used',
    data_utilizzo = now(),
    dettagli = COALESCE(dettagli, '{}'::jsonb) || jsonb_build_object(
      'response_text', p_response, 
      'nota_interna', p_nota_interna, 
      'response_timestamp', now()
    )
  WHERE id = p_transaction_id;

  SELECT nome_squadra INTO v_team_name FROM public.teams WHERE id = v_tx.team_id;

  INSERT INTO public.activity_log (tipo_evento, team_id, dettagli)
  VALUES ('passaparola_responded', v_tx.team_id, jsonb_build_object('message', 'La Regia ha risposto alla richiesta Passaparola di "' || COALESCE(v_team_name, 'Sconosciuta') || '": "' || p_response || '"'));

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.rollback_boxe_match_result(p_match_id text, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_max_round INTEGER;
  v_next_match RECORD;
  v_next_match_idx INTEGER;
  v_res JSONB;
BEGIN
  SELECT * INTO v_match FROM public.boxe_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.status <> 'completed' THEN
    SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
    FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;
    RETURN v_res;
  END IF;

  SELECT MAX(round)::INTEGER INTO v_max_round 
  FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    v_next_match_idx := (v_match.match_index / 2)::INTEGER;
    SELECT * INTO v_next_match FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;

    IF v_next_match.status = 'completed' THEN
      RAISE EXCEPTION 'Impossibile annullare: il turno successivo è già stato disputato. Annulla prima quel match.';
    END IF;

    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.boxe_matches SET team1_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    ELSE
      UPDATE public.boxe_matches SET team2_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    END IF;
  ELSE
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;
    UPDATE public.team_progress SET stato = 'in_progress', completata_il = NULL WHERE challenge_id = v_challenge_id;
  END IF;

  UPDATE public.boxe_matches
  SET winner_id = NULL, status = 'ready', completed_at = NULL
  WHERE id = v_match.id;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.rollback_cornhole_match_result(p_match_id text, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_max_round INTEGER;
  v_next_match RECORD;
  v_next_match_idx INTEGER;
  v_res JSONB;
BEGIN
  SELECT * INTO v_match FROM public.cornhole_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.status <> 'completed' THEN
    SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
    FROM (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;
    RETURN v_res;
  END IF;

  SELECT MAX(round)::INTEGER INTO v_max_round 
  FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    v_next_match_idx := (v_match.match_index / 2)::INTEGER;
    SELECT * INTO v_next_match FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;

    IF v_next_match.status = 'completed' THEN
      RAISE EXCEPTION 'Impossibile annullare: il turno successivo è già stato disputato. Annulla prima quel match.';
    END IF;

    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.cornhole_matches SET team1_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    ELSE
      UPDATE public.cornhole_matches SET team2_id = NULL, status = 'pending' WHERE id = v_next_match.id;
    END IF;
  ELSE
    -- Rollback della finale: cancella i punteggi
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;
    UPDATE public.team_progress SET stato = 'in_progress', completata_il = NULL WHERE challenge_id = v_challenge_id;
  END IF;

  UPDATE public.cornhole_matches
  SET winner_id = NULL, status = 'ready', completed_at = NULL
  WHERE id = v_match.id;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_boxe_special_bye(p_team_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_has_started BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.boxe_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  IF v_has_started THEN
    RAISE EXCEPTION 'Impossibile modificare il vantaggio: il torneo è già iniziato.';
  END IF;

  UPDATE public.game_settings
  SET boxe_special_bye_team_id = p_team_id;

  DELETE FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  RETURN jsonb_build_object('success', true, 'special_bye_team_id', p_team_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_cornhole_special_bye(p_team_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_has_started BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.cornhole_matches 
    WHERE challenge_id = v_challenge_id AND status = 'completed' AND team2_id IS NOT NULL
  ) INTO v_has_started;

  IF v_has_started THEN
    RAISE EXCEPTION 'Impossibile modificare il vantaggio: il torneo è già iniziato.';
  END IF;

  UPDATE public.game_settings
  SET cornhole_special_bye_team_id = p_team_id;

  -- Resetta i match per consentire rigenerazione con il nuovo bye
  DELETE FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  RETURN jsonb_build_object('success', true, 'special_bye_team_id', p_team_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.spin_unlucky_wheel()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
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
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_tx 
  FROM public.marketplace_transactions
  WHERE target_team_id = v_team_id 
    AND marketplace_item_id = 'ruota_sfortunata' 
    AND stato = 'completed'
  ORDER BY data_acquisto ASC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Nessuna Ruota Sfortunata in sospeso');
  END IF;

  -- 6 slices:
  -- 1: freeze_2min (1-17)
  -- 2: minus_20_points (18-34)
  -- 3: minus_10_tokens (35-51)
  -- 4: plus_2_min (52-68)
  -- 5: heavy_backpack (69-84)
  -- 6: minus_10_points_minus_5_tokens (85-100)
  v_roll := floor(random() * 100) + 1;

  IF v_roll <= 17 THEN
    v_outcome_id := 'freeze_2min';
    v_outcome_label := '❄️ FREEZE (2 MINUTI)';
    v_freeze_seconds := 120;
  ELSIF v_roll <= 34 THEN
    v_outcome_id := 'minus_20_points';
    v_outcome_label := '💸 PENALITÀ -20 PUNTI';
    v_points := 20;
  ELSIF v_roll <= 51 THEN
    v_outcome_id := 'minus_10_tokens';
    v_outcome_label := '🪙 PERDITA -10 TOKEN';
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

  -- Apply penalties
  IF v_freeze_seconds > 0 THEN
    UPDATE public.teams 
    SET 
      freeze_started_at = now(),
      freeze_expires_at = now() + INTERVAL '120 seconds',
      freeze_duration_seconds = 120
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

  -- Mark transaction used
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

CREATE OR REPLACE FUNCTION public.start_challenge(p_challenge uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.submit_bank_answer(p_question_number integer, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_correct_answer TEXT;
  v_extracted_letter CHAR(1);
  v_correct BOOLEAN := false;
  v_challenge_completed BOOLEAN := false;
  v_challenge_id UUID := 'b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6';
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  -- Risposte esatte originali:
  -- 1: BANCOMAT (B)
  -- 2: PIN (P)
  -- 3: EURO (E)
  -- 4: RATA (R)
  IF p_question_number = 1 THEN 
    v_correct_answer := 'BANCOMAT';
    v_extracted_letter := 'B';
  ELSIF p_question_number = 2 THEN 
    v_correct_answer := 'PIN';
    v_extracted_letter := 'P';
  ELSIF p_question_number = 3 THEN 
    v_correct_answer := 'EURO';
    v_extracted_letter := 'E';
  ELSIF p_question_number = 4 THEN 
    v_correct_answer := 'RATA';
    v_extracted_letter := 'R';
  ELSE 
    RAISE EXCEPTION 'Numero domanda non valido';
  END IF;

  v_correct := (UPPER(TRIM(p_answer)) = v_correct_answer);

  IF v_correct THEN
    INSERT INTO public.team_bank_answers (team_id, question_number, answer, extracted_letter)
    VALUES (v_team_id, p_question_number, UPPER(TRIM(p_answer)), v_extracted_letter)
    ON CONFLICT (team_id, question_number) DO UPDATE
    SET answer = EXCLUDED.answer, extracted_letter = EXCLUDED.extracted_letter;

    -- Assegna 5 punti per ogni enigma risolto
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, 5, 'challenge_points', 'Risposta esatta enigma ' || p_question_number || ' - La Banca')
    ON CONFLICT DO NOTHING;

    -- Se ha completato tutti e 4 gli enigmi, segna la sfida completata
    IF (SELECT COUNT(*) FROM public.team_bank_answers WHERE team_id = v_team_id) = 4 THEN
      v_challenge_completed := true;
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team_id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE
      SET stato = 'completed', completata_il = now();
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'correct', v_correct,
    'letter', v_extracted_letter,
    'challenge_completed', v_challenge_completed
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_boxe_match_result(p_match_id text, p_winner_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_max_round INTEGER;
  v_next_match_idx INTEGER;
  v_team RECORD;
  v_res JSONB;
BEGIN
  SELECT * INTO v_match FROM public.boxe_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.team1_id <> p_winner_id AND v_match.team2_id <> p_winner_id THEN
    RAISE EXCEPTION 'La squadra vincitrice deve far parte del match.';
  END IF;

  UPDATE public.boxe_matches
  SET winner_id = p_winner_id, status = 'completed', completed_at = now()
  WHERE id = v_match.id;

  SELECT MAX(round)::INTEGER INTO v_max_round 
  FROM public.boxe_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    v_next_match_idx := (v_match.match_index / 2)::INTEGER;
    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.boxe_matches SET team1_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
    ELSE
      UPDATE public.boxe_matches SET team2_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
    END IF;

    UPDATE public.boxe_matches SET status = 'ready'
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
  ELSE
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (p_winner_id, v_challenge_id, v_stage_id, 20, 'challenge_points', 'Vincitore Torneo Boxe Gonfiabile (Tappa 5)');

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true AND id <> p_winner_id) LOOP
      INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team.id, v_challenge_id, v_stage_id, 10, 'challenge_points', 'Partecipazione Torneo Boxe Gonfiabile (Tappa 5)');
    END LOOP;

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true) LOOP
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team.id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());
    END LOOP;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.boxe_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_cornhole_match_result(p_match_id text, p_winner_id uuid, p_admin_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_match RECORD;
  v_challenge_id UUID := 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0';
  v_stage_id UUID := '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c';
  v_max_round INTEGER;
  v_next_match_idx INTEGER;
  v_team RECORD;
  v_res JSONB;
BEGIN
  SELECT * INTO v_match FROM public.cornhole_matches WHERE id::TEXT = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match non trovato.';
  END IF;

  IF v_match.team1_id <> p_winner_id AND v_match.team2_id <> p_winner_id THEN
    RAISE EXCEPTION 'La squadra vincitrice deve far parte del match.';
  END IF;

  UPDATE public.cornhole_matches
  SET winner_id = p_winner_id, status = 'completed', completed_at = now()
  WHERE id = v_match.id;

  SELECT MAX(round)::INTEGER INTO v_max_round 
  FROM public.cornhole_matches WHERE challenge_id = v_challenge_id;

  IF v_match.round < v_max_round THEN
    v_next_match_idx := (v_match.match_index / 2)::INTEGER;
    IF v_match.match_index % 2 = 0 THEN
      UPDATE public.cornhole_matches SET team1_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
    ELSE
      UPDATE public.cornhole_matches SET team2_id = p_winner_id
      WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx;
    END IF;

    UPDATE public.cornhole_matches SET status = 'ready'
    WHERE challenge_id = v_challenge_id AND round = v_match.round + 1 AND match_index = v_next_match_idx AND team1_id IS NOT NULL AND team2_id IS NOT NULL;
  ELSE
    -- Finale completata: assegna 20 punti al vincitore e 10 a tutti gli altri team attivi
    DELETE FROM public.scores WHERE challenge_id = v_challenge_id;

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (p_winner_id, v_challenge_id, v_stage_id, 20, 'challenge_points', 'Vincitore Torneo Cornhole (Tappa 5)');

    FOR v_team IN (SELECT id FROM public.teams WHERE active = true AND id <> p_winner_id) LOOP
      INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
      VALUES (v_team.id, v_challenge_id, v_stage_id, 10, 'challenge_points', 'Partecipazione Torneo Cornhole (Tappa 5)');
    END LOOP;

    -- Segna completata in team_progress per tutti i team attivi
    FOR v_team IN (SELECT id FROM public.teams WHERE active = true) LOOP
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team.id, v_challenge_id, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE SET stato = 'completed', completata_il = COALESCE(team_progress.completata_il, now());
    END LOOP;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb) INTO v_res
  FROM (SELECT * FROM public.cornhole_matches WHERE challenge_id = v_challenge_id ORDER BY round ASC, match_index ASC) m;

  RETURN v_res;
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_enigma_answer(p_challenge_id uuid, p_answer jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.submit_enigma_extra_answer(p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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

CREATE OR REPLACE FUNCTION public.submit_quiz_answer(p_question uuid, p_selected integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_question RECORD;
  v_correct BOOLEAN;
  v_points INTEGER := 0;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT * INTO v_question FROM public.quiz_questions WHERE id = p_question;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('correct', false, 'points', 0, 'error', 'Domanda non trovata');
  END IF;

  v_correct := (p_selected = v_question.correct_answer_index);
  v_points := CASE WHEN v_correct THEN v_question.points ELSE 0 END;

  -- Upsert risposta (UNIQUE su team_id, question_id)
  INSERT INTO public.team_answers (team_id, question_id, selected_answer, correct)
  VALUES (v_team_id, p_question, p_selected, v_correct)
  ON CONFLICT (team_id, question_id) DO UPDATE
    SET selected_answer = EXCLUDED.selected_answer, correct = EXCLUDED.correct;

  -- Assegna punti se corretto
  IF v_correct AND v_points > 0 THEN
    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_question.challenge_id, v_points, 'challenge_points', 'Risposta corretta al quiz');
  END IF;

  RETURN jsonb_build_object('correct', v_correct, 'points', v_points);
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_secret_code_pin(p_inserted_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_correct_pin TEXT;
  v_correct BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
  v_stage_id UUID;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  SELECT full_code INTO v_correct_pin FROM public.game_final_code WHERE id = 'current' LIMIT 1;
  IF v_correct_pin IS NULL THEN
    v_correct_pin := '4829167305';
  END IF;

  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  v_correct := (TRIM(p_inserted_code) = TRIM(v_correct_pin));

  IF v_correct THEN
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, v_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, 30, 'challenge_points', 'Sfida PIN superata')
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN jsonb_build_object(
    'success', v_correct,
    'message', CASE WHEN v_correct THEN 'Sbloccato!' ELSE 'Codice errato. Controlla attentamente le cifre.' END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_social_challenge(p_image_1_path text, p_image_2_path text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  INSERT INTO public.team_social_submissions (
    team_id, challenge_id, social_url, image_1_url, image_2_url, status, stato_approvazione, uploaded_at
  )
  VALUES (
    v_team_id, v_challenge_id, p_image_1_path, p_image_1_path, p_image_2_path, 'submitted', 'pending', now()
  )
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET 
    image_1_url = EXCLUDED.image_1_url,
    image_2_url = EXCLUDED.image_2_url,
    social_url = EXCLUDED.social_url,
    status = 'submitted',
    stato_approvazione = 'pending',
    uploaded_at = now();

  -- Segna progresso in completed o submitted
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET stato = 'completed', completata_il = now();

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_social_challenge(p_challenge_id uuid, p_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.sync_team_to_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp', 'extensions'
AS $function$
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

  -- Cerca utente esistente
  SELECT id INTO v_user_id 
  FROM auth.users 
  WHERE email = v_email;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();

    -- Crea utente in auth.users
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
    -- Aggiorna password esistente
    UPDATE auth.users 
    SET encrypted_password = v_encrypted_pass, updated_at = now()
    WHERE id = v_user_id;
  END IF;

  -- Imposta owner_id
  NEW.owner_id := v_user_id;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.toggle_marketplace(p_active boolean, p_admin_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_is_admin BOOLEAN;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN RAISE EXCEPTION 'Non autorizzato'; END IF;
  UPDATE public.game_settings SET
    marketplace_active = p_active,
    activated_at = CASE WHEN p_active THEN now() ELSE NULL END,
    activated_by = CASE WHEN p_active THEN p_admin_id ELSE NULL END
  WHERE id = (SELECT id FROM public.game_settings LIMIT 1);
END;
$function$;


-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

CREATE POLICY "Public Read Activity Log" ON public.activity_log AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Admin All Boxe Matches" ON public.boxe_matches AS PERMISSIVE FOR ALL TO public USING (public.has_role(auth.uid(), 'admin'::text));
CREATE POLICY "Public Read Boxe Matches" ON public.boxe_matches AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Cattiveria" ON public.cattiveria_ledger AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Secure SELECT Cattiveria" ON public.cattiveria_ledger AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Public Read Challenges" ON public.challenges AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Code Purchases" ON public.code_purchase_transactions AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Admin All Cornhole Matches" ON public.cornhole_matches AS PERMISSIVE FOR ALL TO public USING (public.has_role(auth.uid(), 'admin'::text));
CREATE POLICY "Public Read Cornhole Matches" ON public.cornhole_matches AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Team Read Enigma Attempts" ON public.enigma_attempts AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Public Read Report" ON public.game_report AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Admin Write Game Settings" ON public.game_settings AS PERMISSIVE FOR ALL TO public USING (public.has_role(auth.uid(), 'admin'::text));
CREATE POLICY "Public Read Game Settings" ON public.game_settings AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Team Read Own Jackpot Plays" ON public.jackpot_plays AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY jackpot_plays_all_admin ON public.jackpot_plays AS PERMISSIVE FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY jackpot_plays_select_all ON public.jackpot_plays AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Marketplace Items" ON public.marketplace_items AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Transactions" ON public.marketplace_transactions AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Secure SELECT Transactions" ON public.marketplace_transactions AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Public Read Posters" ON public.posters AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Quiz Questions" ON public.quiz_questions AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Scores" ON public.scores AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Secure SELECT Scores" ON public.scores AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Admin Write Settings" ON public.settings AS PERMISSIVE FOR ALL TO public USING (public.has_role(auth.uid(), 'admin'::text));
CREATE POLICY "Public Read Settings" ON public.settings AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Stages" ON public.stages AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Submissions" ON public.submissions AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Secure SELECT Submissions" ON public.submissions AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Team INSERT Submissions" ON public.submissions AS PERMISSIVE FOR INSERT TO public WITH CHECK ((team_id = public.current_team_id()));
CREATE POLICY "Team Read Own Answers" ON public.team_answers AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Team Read Own Bank Answers" ON public.team_bank_answers AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Public Read Code Matches" ON public.team_code_matches AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Code Parts" ON public.team_code_parts AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Team Insert Own Emoji Movies" ON public.team_emoji_movies AS PERMISSIVE FOR INSERT TO public WITH CHECK (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Team Read Own Emoji Movies" ON public.team_emoji_movies AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Team Update Own Emoji Movies" ON public.team_emoji_movies AS PERMISSIVE FOR UPDATE TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Public Read Team Posters" ON public.team_posters AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public Read Progress" ON public.team_progress AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Secure SELECT Progress" ON public.team_progress AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Team INSERT Progress" ON public.team_progress AS PERMISSIVE FOR INSERT TO public WITH CHECK ((team_id = public.current_team_id()));
CREATE POLICY "Team Read Own Social Submissions" ON public.team_social_submissions AS PERMISSIVE FOR SELECT TO public USING (((team_id = public.current_team_id()) OR public.has_role(auth.uid(), 'admin'::text)));
CREATE POLICY "Admin All Teams" ON public.teams AS PERMISSIVE FOR ALL TO public USING (public.has_role(auth.uid(), 'admin'::text));
CREATE POLICY "Public Read Teams" ON public.teams AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Team Update Self Team" ON public.teams AS PERMISSIVE FOR UPDATE TO public USING ((id = public.current_team_id())) WITH CHECK ((id = public.current_team_id()));


-- ============================================================================
-- DATA RECORDS
-- ============================================================================

-- Table: activity_log (102 records)
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('e2b4e414-4be5-4cca-89b3-c9b96e3034de', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udf81 PICCOLO BONUS"}'::jsonb, '2026-08-19T07:57:34.337394+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('5059b14d-df10-48f2-8601-cdf4825d988f', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 100 token alla squadra \"prova4\". Motivazione: a", "new_balance": 150}'::jsonb, '2026-08-18T20:41:37.038926+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('c6a4b81c-0202-4503-8e49-eec327728777', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 100 token alla squadra \"prova3\". Motivazione: a", "new_balance": 150}'::jsonb, '2026-08-18T20:41:37.124425+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('21ed3118-c334-43f2-aec4-f51ad7e5c8fe', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 100 token alla squadra \"prova2\". Motivazione: a", "new_balance": 150}'::jsonb, '2026-08-18T20:41:37.213453+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('da798802-98c5-41c6-a1b3-c7ec0c9c5e52', 'malus_blocked', NULL, NULL, '{"message": "Il Malus \"FREEZE 2 MINUTI\" lanciato da \"TEST_TEAM_ALPHA\" contro \"TEST_TEAM_BETA\" \u00e8 stato BLOCCATO dallo Scudo."}'::jsonb, '2026-08-19T07:57:37.801201+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('9082deaf-48a9-4df8-ba1c-aa606cf94665', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova2\" ha risolto l''enigma \"Rebus Musicale\" al tentativo #1"}'::jsonb, '2026-08-18T20:59:25.128471+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('f83aca4a-ebda-45de-8886-dc230627c6e4', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"prova2\" ha risposto in modo errato all''enigma \"Lucchetto Direzionale\", subendo -8 PT."}'::jsonb, '2026-08-18T20:59:34.937099+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('12693683-97c3-4577-a083-eb1c6d224793', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova2\" ha risolto l''enigma \"Lucchetto Direzionale\" al tentativo #2"}'::jsonb, '2026-08-18T20:59:39.913383+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('efe9048a-230f-4903-b132-2938e96c926a', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova2\" ha risolto l''enigma \"Le Coordinate Finali\" al tentativo #1"}'::jsonb, '2026-08-18T20:59:53.217436+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('260e7c60-a396-4699-a0e3-735952b063c3', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 10 token alla squadra \"prova\". Motivazione: si", "new_balance": 60}'::jsonb, '2026-08-18T08:57:39.56613+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('9fadf261-f647-492e-aced-2b25d846acd0', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha rimosso 10 token alla squadra \"prova\". Motivazione: si", "new_balance": 50}'::jsonb, '2026-08-18T08:57:55.599358+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('7ebcc088-82b2-48fe-a13f-6b7dc3751e97', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova\" ha risolto l''enigma \"Rebus Musicale\" al tentativo #1"}'::jsonb, '2026-08-18T20:38:38.385845+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('e7943c9f-c4b6-4b96-b62f-2a79f46d9d87', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova\" ha risolto l''enigma \"Lucchetto Direzionale\" al tentativo #1"}'::jsonb, '2026-08-18T20:38:49.364491+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('3e4e98d1-0454-4fa4-9493-22e480e92bc8', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova\" ha risolto l''enigma \"Le Coordinate Finali\" al tentativo #1"}'::jsonb, '2026-08-18T20:39:01.841117+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('1e2b477d-4132-4e85-b744-6f9ed67261d6', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 100 token alla squadra \"prova\". Motivazione: a", "new_balance": 146}'::jsonb, '2026-08-18T20:41:37.299394+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('603b9e63-e7d9-4189-8b5e-90a1ecd56ae4', 'buy_secret_code_part', NULL, NULL, '{"cost": 4, "digits": "48291"}'::jsonb, '2026-08-18T20:58:24.012742+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('4f3d99a3-ff13-4b09-8d2d-30800501ff40', 'buy_secret_code_part', NULL, NULL, '{"cost": 4, "digits": "67305"}'::jsonb, '2026-08-18T20:36:49.200775+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('50cafbd4-b075-4642-9df8-63d98c0801df', 'team_frozen', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_GAMMA\" \u00e8 stata congelata da \"TEST_TEAM_ALPHA\" per 120 secondi!"}'::jsonb, '2026-08-19T07:57:38.509708+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('954c3d9c-6002-423b-a88a-3c8cba492c1a', 'trappola_used', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha attivato la TRAPPOLA contro \"TEST_TEAM_GAMMA\" rubando 30 PT."}'::jsonb, '2026-08-19T07:57:39.98846+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('2e7399e0-bc33-4831-8d93-c3ec2f4d6fbb', 'tassa_passaggio_used', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha attivato la TASSA DI PASSAGGIO scambiando i suoi 80 PT con i 150 PT di \"TEST_TEAM_DELTA\"."}'::jsonb, '2026-08-19T07:57:40.898787+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('627e834c-10dc-4dbb-84b6-34ae26794aef', 'passaparola_request', NULL, NULL, '{"message": "La squadra \"TEST_ADMIN_FLOW_TEAM\" ha inoltrato una richiesta Passaparola: \"\u00c8 la statua di bronzo in piazza?\""}'::jsonb, '2026-08-19T08:13:22.076278+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('89a95c8c-4759-4235-adf0-623d0637b3e1', 'passaparola_responded', NULL, NULL, '{"message": "La Regia ha risposto alla richiesta Passaparola di \"TEST_ADMIN_FLOW_TEAM\": \"S\u00cc\""}'::jsonb, '2026-08-19T08:13:22.339277+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ad6410cf-ec06-4838-96e8-9a7e2f4a193d', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova4\". Motivazione: a", "new_balance": 450}'::jsonb, '2026-08-19T08:37:32.353508+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('eb3bc679-1fc1-48ab-b72b-5a3c5d68246a', 'trappola_used', NULL, NULL, '{"message": "La squadra \"SIM_TEAM_3\" ha attivato la TRAPPOLA contro \"SIM_TEAM_4\" rubando 0 PT."}'::jsonb, '2026-08-19T08:14:48.220566+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('153be871-6b81-492b-a7cf-9214b1f3733d', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"SIM_TEAM_5\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udf89 SORPRESA"}'::jsonb, '2026-08-19T08:14:48.724732+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('87ccbcbf-3659-4544-a502-830dc73329f1', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"SIM_TEAM_8\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83e\udde0 AIUTO EXTRA DI DAVE"}'::jsonb, '2026-08-19T08:14:49.523768+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('101d412d-569e-4010-aeb3-02b82c94fcda', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"prova3\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udfaf DOPPIO PREMIO"}'::jsonb, '2026-08-19T08:25:07.738802+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('8878727e-aa8b-443f-ac87-0a1bbec95fbb', 'passaparola_request', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_A\" ha inoltrato una richiesta Passaparola: \"\u00c8 la torre del castello?\""}'::jsonb, '2026-08-19T08:18:20.201561+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('cd16cdac-48c7-4465-9b67-a8bf06554139', 'passaparola_responded', NULL, NULL, '{"message": "La Regia ha risposto alla richiesta Passaparola di \"TEST_TEAM_A\": \"NO\""}'::jsonb, '2026-08-19T08:18:20.639604+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('5e1b548b-b261-412c-ba1a-312cc7ec5739', 'malus_blocked', NULL, NULL, '{"message": "Il Malus \"FREEZE 2 MINUTI\" lanciato da \"TEST_TEAM_A\" contro \"TEST_TEAM_B\" \u00e8 stato BLOCCATO dallo Scudo."}'::jsonb, '2026-08-19T08:18:17.835871+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ec1397d9-073d-44b3-aea4-f3c5595390d7', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"TEST_BONUS_VERIFY_TEAM\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udf81 PICCOLO (+5 PT)"}'::jsonb, '2026-08-19T08:31:00.758798+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('5e2c44f5-38b9-45f7-9fa5-aa48c86d557d', 'passaparola_request', NULL, NULL, '{"message": "La squadra \"TEST_BONUS_VERIFY_TEAM\" ha inoltrato una richiesta Passaparola: \"\u00c8 corretto il colore rosso?\""}'::jsonb, '2026-08-19T08:31:01.777759+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('5c98b401-dd53-4056-ba2f-3b0affff97dc', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"TEST_BONUS_VERIFY_TEAM\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83e\ude99 GETTONI (+10 TK)"}'::jsonb, '2026-08-19T08:31:17.649099+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('41d4e6d9-6fa7-49a8-a696-6d8cde4821d2', 'passaparola_request', NULL, NULL, '{"message": "La squadra \"TEST_BONUS_VERIFY_TEAM\" ha inoltrato una richiesta Passaparola: \"\u00c8 corretto il colore rosso?\""}'::jsonb, '2026-08-19T08:31:18.683708+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('e5b06b1b-d752-4697-aa32-384c4573145b', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova3\". Motivazione: a", "new_balance": 345}'::jsonb, '2026-08-19T08:37:32.415713+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('1c997a31-be38-4339-bacd-d7691211093b', 'passaparola_request', NULL, NULL, '{"message": "La squadra \"prova3\" ha inoltrato una richiesta Passaparola: \"Ciao\""}'::jsonb, '2026-08-19T08:38:20.332735+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('51441283-cada-455e-aba4-f3b0ed43f910', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova2\". Motivazione: a", "new_balance": 446}'::jsonb, '2026-08-19T08:37:32.472532+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('a88a6d2e-d94d-4aa6-b3a8-222213774ce9', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"prova\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udf89 SORPRESA"}'::jsonb, '2026-08-19T08:25:30.529801+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('f5ebf00e-af4b-4442-92c9-8c6894785691', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova\". Motivazione: a", "new_balance": 300}'::jsonb, '2026-08-19T08:37:32.519203+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('49701e5f-0c83-4e47-89d3-895fefa96cc0', 'malus_blocked', NULL, NULL, '{"message": "Il Malus \"PENALIT\u00c0 PUNTI (-20 PT)\" lanciato da \"prova\" contro \"prova3\" \u00e8 stato BLOCCATO dallo Scudo."}'::jsonb, '2026-08-19T08:38:49.157128+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('845488ff-f6c8-4b56-80ce-bee325145650', 'trappola_used', NULL, NULL, '{"message": "La squadra \"prova\" ha attivato la TRAPPOLA contro \"prova3\" rubando 30 PT."}'::jsonb, '2026-08-19T08:39:08.853855+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('e115076e-a48d-4cc7-ace0-7993b685bf70', 'team_frozen', NULL, NULL, '{"message": "La squadra \"prova3\" \u00e8 stata congelata da \"prova\" per 120 secondi!"}'::jsonb, '2026-08-19T08:39:25.946966+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('5d92f2cb-947e-4405-8d99-acd09371bd82', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha acquistato \"BONUS CLASSIFICA\"."}'::jsonb, '2026-08-19T08:51:11.325631+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('0fc8bcdd-e331-4dbc-bee3-dc7db95a757f', 'ruota_sfortunata_spin', NULL, NULL, '{"message": "La squadra ha girato la Ruota Sfortunata ed ha subito: \ud83d\udca5 -10 PUNTI & -5 TOKEN"}'::jsonb, '2026-08-19T08:51:34.382568+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('eb8f66e2-6b36-4594-b429-278f3597c4d1', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova4\". Motivazione: A", "new_balance": 750}'::jsonb, '2026-08-19T08:54:49.520089+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('91ee4c77-cb60-4da0-9135-21295c26ae20', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha acquistato \"BONUS CLASSIFICA\"."}'::jsonb, '2026-08-19T08:51:34.602711+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('17583421-b2b2-434b-a6a4-e8aff3f73d9f', 'team_frozen', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha congelato la squadra \"TEST_TEAM_BETA\" per 120 secondi!"}'::jsonb, '2026-08-19T08:51:33.700051+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('2cb9084a-d397-4449-a858-b9557ea5ff2e', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha acquistato \"RUOTA SFORTUNATA\"."}'::jsonb, '2026-08-19T08:51:34.168344+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('32dfd671-9280-4728-b644-f80f5f7068b9', 'tassa_passaggio_used', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha attivato la TASSA DI PASSAGGIO scambiando i suoi 50 PT con i 85 PT di \"TEST_TEAM_BETA\"."}'::jsonb, '2026-08-19T08:51:36.40392+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('b15e8d9a-ff68-45d1-ad3b-2bc1d71f5e52', 'ruota_sfortunata_spin', NULL, NULL, '{"message": "La squadra ha girato la Ruota Sfortunata ed ha subito: \ud83e\ude99 PERDITA -10 TOKEN"}'::jsonb, '2026-08-19T08:51:47.241639+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('2bd03b52-bdf5-42e5-8f22-da68dd24f810', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"prova4\" ha risposto in modo errato all''enigma \"Rebus Musicale\", subendo -8 PT."}'::jsonb, '2026-08-19T09:05:32.138983+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('0e3c4143-c95d-4b12-95c6-0813e3ca24c7', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova4\" ha risolto l''enigma \"Rebus Musicale\" al tentativo #2"}'::jsonb, '2026-08-19T09:07:08.639938+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('3e1baf7e-6ea0-49a8-a81d-067f8611dfa6', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova4\" ha risolto l''enigma \"Lucchetto Direzionale\" al tentativo #1"}'::jsonb, '2026-08-19T09:07:17.002364+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('2c5a5ef5-8642-4f91-b049-05183cacbcff', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha acquistato \"BONUS CLASSIFICA\"."}'::jsonb, '2026-08-19T08:51:47.543342+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('f9936675-2bda-45ac-a5e3-0170a041cead', 'team_frozen', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha congelato la squadra \"TEST_TEAM_BETA\" per 120 secondi!"}'::jsonb, '2026-08-19T08:51:46.555149+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('53a70861-ae00-42d9-bbfd-d6e03a8cba95', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha acquistato \"RUOTA SFORTUNATA\"."}'::jsonb, '2026-08-19T08:51:47.019293+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('6f14fea4-a40d-4758-87b6-2e796b9b5cbe', 'tassa_passaggio_used', NULL, NULL, '{"message": "La squadra \"TEST_TEAM_ALPHA\" ha attivato la TASSA DI PASSAGGIO scambiando i suoi 30 PT con i 85 PT di \"TEST_TEAM_BETA\"."}'::jsonb, '2026-08-19T08:51:49.435248+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('96e654f3-2e66-4745-99e1-1a337e22f5cb', 'passaparola_responded', NULL, NULL, '{"message": "La Regia ha risposto alla richiesta Passaparola di \"prova3\": \"S\u00cc\""}'::jsonb, '2026-08-19T08:47:18.451271+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ffddb28d-aa0e-44eb-90e5-719809d3f3b5', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova3\". Motivazione: A", "new_balance": 645}'::jsonb, '2026-08-19T08:54:49.56735+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ead11e4a-dfcd-49a2-816d-c65a4ed99aac', 'ruota_sfortunata_spin', NULL, NULL, '{"message": "La squadra ha girato la Ruota Sfortunata ed ha subito: \u2744\ufe0f FREEZE (2 MINUTI)"}'::jsonb, '2026-08-19T08:58:20.507208+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('712450d4-fdc5-4650-b327-043fa1208816', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova2\". Motivazione: A", "new_balance": 716}'::jsonb, '2026-08-19T08:54:49.671321+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('78f34cf8-94c2-4fde-b755-c827e54f2f74', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"prova\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udf89 SORPRESA (+3 PT)"}'::jsonb, '2026-08-19T09:13:49.950717+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('a3885794-39b3-48d4-b04e-a44fd508f562', 'admin_tokens_adjusted', NULL, NULL, '{"message": "La Regia ha aggiunto 300 token alla squadra \"prova\". Motivazione: A", "new_balance": 395}'::jsonb, '2026-08-19T08:54:49.715644+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('1767d460-4432-4a66-861b-fd3a9349de42', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"prova\" ha acquistato \"BONUS CLASSIFICA\"."}'::jsonb, '2026-08-19T08:58:47.521376+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('6d47c903-2751-44a8-b79d-5a0ad28ea6a1', 'team_frozen', NULL, NULL, '{"message": "La squadra \"prova\" ha congelato la squadra \"prova3\" per 120 secondi!"}'::jsonb, '2026-08-19T08:55:50.956939+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('0d10d817-fa24-479d-a55c-d1815c963f29', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"prova\" ha acquistato \"RUOTA SFORTUNATA\"."}'::jsonb, '2026-08-19T08:58:15.256443+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('88867219-7958-46b4-8628-6f791083eebc', 'tassa_passaggio_used', NULL, NULL, '{"message": "La squadra \"prova\" ha attivato la TASSA DI PASSAGGIO scambiando i suoi 268 PT con i 152 PT di \"prova2\"."}'::jsonb, '2026-08-19T08:45:48.179493+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('8573543b-c678-47ce-98fc-40e215fc18e9', 'buy_secret_code_part', NULL, NULL, '{"cost": 4, "digits": "67305"}'::jsonb, '2026-08-19T09:05:06.685456+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('97fa312e-e9db-4f64-95b2-eaa3dbeb79b7', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:48:51.789643+00:00"}'::jsonb, '2026-08-19T09:48:51.789643+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('28eabc25-600d-476f-af64-af3dbf6c3c90', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:48:52.307353+00:00"}'::jsonb, '2026-08-19T09:48:52.307353+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('53654d46-76fa-4622-a296-0bf82476b5cc', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:48:52.307353+00:00"}'::jsonb, '2026-08-19T09:48:52.307353+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('9492ed97-ab02-4f94-8984-f55dba00b5b9', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:48:52.307353+00:00"}'::jsonb, '2026-08-19T09:48:52.307353+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ea00c664-9d36-4311-a64b-442c824d13ed', 'PUBLISH_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "published_at": "2026-08-19T09:48:52.548691+00:00"}'::jsonb, '2026-08-19T09:48:52.548691+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('d13e8d0c-1567-45bc-ba75-542b7ab3f1c1', 'REOPEN_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "reopened_at": "2026-08-19T09:48:53.04959+00:00"}'::jsonb, '2026-08-19T09:48:53.04959+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('beee3745-c034-4402-8c42-1e3aace1e9f8', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:48:53.501162+00:00"}'::jsonb, '2026-08-19T09:48:53.501162+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('23f3d100-24a4-4a10-8882-3beb8555b317', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:49:45.462799+00:00"}'::jsonb, '2026-08-19T09:49:45.462799+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('cbc945d6-66bc-4afb-8f91-7e881ed1b8fb', 'PUBLISH_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "published_at": "2026-08-19T09:50:14.096901+00:00"}'::jsonb, '2026-08-19T09:50:14.096901+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('7b871ae7-5a6b-4957-82f3-1cefb716a25e', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T09:53:43.84288+00:00"}'::jsonb, '2026-08-19T09:53:43.84288+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('3e130f2a-eb15-4917-b31e-7a32883251ac', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 14, "calculated_at": "2026-08-19T10:08:18.018522+00:00"}'::jsonb, '2026-08-19T10:08:18.018522+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ea3e557f-e949-4354-a958-dd241e7e71f7', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T10:08:18.939509+00:00"}'::jsonb, '2026-08-19T10:08:18.939509+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('9b3768a2-caf0-4495-8f13-89255da55783', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"prova4\" ha risposto in modo errato all''enigma \"Le Coordinate Finali\", subendo -8 PT."}'::jsonb, '2026-08-19T09:07:28.821068+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ed643d3d-c4dd-478c-ab3d-d855c407db47', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova4\" ha risolto l''enigma \"Le Coordinate Finali\" al tentativo #2"}'::jsonb, '2026-08-19T09:07:30.602661+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('dc905ac1-430b-4ec1-bbf2-f9131ffa540c', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova3\" ha risolto l''enigma \"Rebus Musicale\" al tentativo #1"}'::jsonb, '2026-08-19T09:12:19.455191+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('3aef19db-082d-43ea-b808-bde730d3cb3c', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova3\" ha risolto l''enigma \"Lucchetto Direzionale\" al tentativo #1"}'::jsonb, '2026-08-19T09:12:26.420516+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('745962ba-9302-4bea-a362-535eb12985c3', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"prova3\" ha risolto l''enigma \"Le Coordinate Finali\" al tentativo #1"}'::jsonb, '2026-08-19T09:12:38.55457+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('8dd4f845-5eea-4ca5-93af-d4174c7e0b4b', 'ruota_sfortunata_spin', NULL, NULL, '{"message": "La squadra ha girato la Ruota Sfortunata ed ha subito: \ud83c\udf92 ZAINO PESANTE (+3 MIN)"}'::jsonb, '2026-08-19T09:14:07.720768+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('603c8364-13b9-4cca-ae8d-d0dd5557ebc0', 'marketplace_purchase', NULL, NULL, '{"message": "La squadra \"prova\" ha acquistato \"RUOTA SFORTUNATA\"."}'::jsonb, '2026-08-19T09:14:03.319751+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('3ee2e79c-821e-43fd-8d9b-c48de48dc9c3', 'tassa_passaggio_used', NULL, NULL, '{"message": "La squadra \"prova\" ha attivato la TASSA DI PASSAGGIO scambiando i suoi 228 PT con i 185 PT di \"prova2\"."}'::jsonb, '2026-08-19T09:14:49.493418+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('47cff65d-d401-4503-9155-6ea13c76d5f9', 'buy_secret_code_part', NULL, NULL, '{"cost": 4, "digits": "48291"}'::jsonb, '2026-08-19T09:11:59.821323+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('8a6d95e4-45de-4e6c-92c7-254472777662', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 14, "calculated_at": "2026-08-19T10:10:43.705088+00:00"}'::jsonb, '2026-08-19T10:10:43.705088+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('9b73b1df-c183-4c1e-b547-6598014b1775', 'CALCULATE_FINAL_RESULTS', NULL, NULL, '{"admin_id": "11111111-1111-1111-1111-111111111111", "teams_count": 4, "calculated_at": "2026-08-19T10:10:44.822421+00:00"}'::jsonb, '2026-08-19T10:10:44.822421+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('2a5a14dd-09cd-469d-bfec-4cc938811fd2', 'ruota_fortuna_spin', NULL, NULL, '{"message": "La squadra \"Ff\" ha girato la Ruota della Fortuna ed ha ottenuto: \ud83c\udf40 FORTUNA (+5 TK)"}'::jsonb, '2026-08-19T12:28:00.476888+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('ce3b0967-44ef-4dee-9366-f4939c1f4687', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"Ff\" ha risolto l''enigma \"Rebus Musicale\" al tentativo #1"}'::jsonb, '2026-08-19T12:29:47.92154+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('28d468ed-3064-48e3-b7dc-13263be6e6c1', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"Ff\" ha risposto in modo errato all''enigma \"Lucchetto Direzionale\", subendo -8 PT."}'::jsonb, '2026-08-19T12:29:53.930354+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('89967a6e-53e2-45cd-8b17-8f5f619d13c1', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"Ff\" ha risposto in modo errato all''enigma \"Lucchetto Direzionale\", subendo -8 PT."}'::jsonb, '2026-08-19T12:29:57.463828+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('4ad2c7a4-b447-4fbe-b3f0-627d1a12eee7', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"Ff\" ha risposto in modo errato all''enigma \"Lucchetto Direzionale\", subendo -8 PT."}'::jsonb, '2026-08-19T12:30:01.048853+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('a23b34cc-af54-4b09-a319-dcc80e453cc2', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"Ff\" ha risposto in modo errato all''enigma \"Lucchetto Direzionale\", subendo -8 PT."}'::jsonb, '2026-08-19T12:30:06.618272+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('a04663d5-aaf1-4355-b3d7-5d23506cbc9e', 'enigma_solved', NULL, NULL, '{"punti": 20, "message": "La squadra \"Ff\" ha risolto l''enigma \"Lucchetto Direzionale\" al tentativo #5"}'::jsonb, '2026-08-19T12:30:10.215474+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('01c0f7ce-f44a-4042-a0a4-855a26f978ca', 'enigma_failed', NULL, NULL, '{"punti": -8, "message": "La squadra \"Ff\" ha risposto in modo errato all''enigma \"Le Coordinate Finali\", subendo -8 PT."}'::jsonb, '2026-08-19T12:30:20.620661+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('b14ec465-1514-4699-b34d-394033755944', 'ruota_sfortunata_assigned', NULL, NULL, '{"message": "La squadra \"prova3\" ha subito un Malus Ruota Sfortunata da \"prova\"!"}'::jsonb, '2026-08-19T08:41:20.672885+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('c9b152cd-1fac-4655-bb27-c14a29e086e3', 'enigma_extra_assigned', NULL, NULL, '{"message": "La squadra \"prova2\" ha ricevuto un Enigma Extra da \"prova\"!"}'::jsonb, '2026-08-19T08:42:39.176234+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.activity_log (id, tipo_evento, team_id, target_team_id, dettagli, created_at) VALUES ('d773fce1-e4d8-461c-99a6-1efe6226313c', 'buy_secret_code_part', NULL, NULL, '{"cost": 4, "digits": "67305"}'::jsonb, '2026-08-19T12:29:12.355364+00:00') ON CONFLICT DO NOTHING;

-- Table: boxe_matches (3 records)
INSERT INTO public.boxe_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('a2e8ab89-869b-49d7-9be6-b1b36ab4d71e', 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', 0, 0, NULL, NULL, NULL, 'completed', '2026-08-18T21:07:50.766784+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.boxe_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('73a24bba-0f41-47a9-a188-f34f817da72f', 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', 1, 0, NULL, NULL, NULL, 'completed', '2026-08-18T21:08:09.328177+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.boxe_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('d81b6077-163a-498d-9548-5f7156e5ebe6', 'd5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', 0, 1, NULL, NULL, NULL, 'completed', '2026-08-18T21:08:00.33665+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;

-- Table: challenges (15 records)
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Creazione squadra', 'Scegliete nome, motto, avatar e colore della vostra squadra.', 'team_setup', 5, 1, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('c4e6c385-69ba-4f17-a6d0-36b78776d527', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Quiz Bra', 'Rispondete alle domande sulla città di Bra.', 'quiz', 15, 2, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('0147e750-f0a3-4b72-8e76-a003fe2ef143', '4a57212e-7e83-430c-b5fe-6cf38db7be2e', 'Foto ufficiale', 'Scattate la foto ufficiale della squadra.', 'photo', 10, 3, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('999f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Il Rebus Visivo', 'Raggiungete il luogo rappresentato dal simbolo.', 'photo', 25, 1, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('777f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'Indovina il film dalle emoji', 'benvenuti nella sala più insolita della caccia!', 'emoji_movies', 15, 2, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('555f4e1f-7443-42e7-9d7a-115f2122888f', 'dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 'La locandina vivente', 'La vostra squadra ha appena ricevuto la locandina di un film iconico.', 'living_poster', 15, 3, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'La Banca', 'Risolvete gli enigmi come veri enigmisti.', 'banca', 25, 1, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Missione Social', 'Capacità di comunicare e creare relazioni.', 'social', 20, 2, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8', '3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 'Il Codice Segreto', 'Sbloccate la destinazione finale con il PIN a 10 cifre.', 'codice', 15, 3, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Rebus Musicale', 'Scoprite le 3 note e inseritele nell''ordine corretto.', 'enigma_musicale', 20, 1, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Lucchetto Direzionale', 'Sequenza di 4 direzioni.', 'lucchetto_direzionale', 20, 2, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', '4b4b4c4d-5e5f-6061-7172-838485868788', 'Le Coordinate Finali', 'Coordinate finali.', 'enigma_coordinate', 20, 3, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Sfida Cornhole', 'Torneo fisico di Cornhole 1vs1.', 'cornhole', 20, 1, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Boxe Gonfiabile', 'Torneo a eliminazione diretta di Boxe Gonfiabile.', 'boxe', 20, 2, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.challenges (id, stage_id, titolo, descrizione, tipo_sfida, punteggio_massimo, ordine_sfida, configurazione, created_at) VALUES ('f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 'Jackpot della Regia', 'Sfida Bonus Slot Machine.', 'jackpot', 20, 3, '{}'::jsonb, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;

-- Table: cornhole_matches (7 records)
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('ffc0f3cc-a701-4003-b020-fbd03cbb8e05', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 0, 3, NULL, NULL, NULL, 'completed', '2026-08-18T21:02:40.400789+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('632acc93-a407-4c3c-a137-c3206ac1c586', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 1, 1, NULL, NULL, NULL, 'completed', '2026-08-18T21:04:44.035137+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('92ef2570-3d8a-43cc-b23e-aa82ee45bf5d', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 0, 2, NULL, NULL, NULL, 'completed', '2026-08-18T21:02:40.400789+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('1055b7c4-74ff-4ea8-958f-c6af2b0acd7b', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 0, 1, NULL, NULL, NULL, 'completed', '2026-08-18T21:02:40.400789+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('ece7c8ad-161c-434e-8b02-95021e859a20', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 0, 0, NULL, NULL, NULL, 'completed', '2026-08-18T21:02:40.400789+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', True) ON CONFLICT DO NOTHING;
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('fb5c1163-b2aa-4ea3-92d3-d9a3312d4269', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 2, 0, NULL, NULL, NULL, 'completed', '2026-08-18T21:04:45.685608+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;
INSERT INTO public.cornhole_matches (id, challenge_id, round, match_index, team1_id, team2_id, winner_id, status, completed_at, stage_id, is_special_bye) VALUES ('84609ccc-687c-4db9-ba2d-49a9c5a12f55', 'c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0', 1, 0, NULL, NULL, NULL, 'completed', '2026-08-18T21:04:42.143381+00:00', '5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', False) ON CONFLICT DO NOTHING;

-- Table: enigma_solutions (3 records)
INSERT INTO public.enigma_solutions (id, challenge_id, solution_type, solution, punteggio, created_at) VALUES ('db66f42d-dab4-4ad0-b9ee-772c9f7b8624', 'e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7', 'notes', '["La", "Do", "Re"]'::jsonb, 20, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.enigma_solutions (id, challenge_id, solution_type, solution, punteggio, created_at) VALUES ('629729d2-da36-4d6b-a468-3d47a22d0f43', 'e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8', 'directions', '["nord-ovest", "sud", "ovest", "est"]'::jsonb, 20, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.enigma_solutions (id, challenge_id, solution_type, solution, punteggio, created_at) VALUES ('2dbb9060-9120-4472-8940-a742fbf24e67', 'e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9', 'coordinates', '{"lat": "44.71", "lng": "7.84"}'::jsonb, 20, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;

-- Table: game_final_code (1 records)
INSERT INTO public.game_final_code (id, full_code, next_stage_destination) VALUES ('current', '4829167305', 'Parco Giochi Madonna dei Fiori (lato piazzale grigio)') ON CONFLICT DO NOTHING;

-- Table: game_report (1 records)
INSERT INTO public.game_report (id, state, published_at, published_by, snapshot, updated_at, status, calculated_at, calculated_by, calculated_snapshot) VALUES ('current', 'PUBLISHED_FINAL', '2026-08-19T09:50:14.096901+00:00', '11111111-1111-1111-1111-111111111111', '{"teams": [{"id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "name": "prova2", "rank": 1, "color": "#22c55e", "motto": "In corsa per la vittoria!", "team_id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "position": 1, "team_name": "prova2", "time_rank": 1, "avatar_url": "\ud83d\udc05", "base_score": 228, "final_rank": 1, "time_bonus": 30, "bonus_tempo": 30, "bonus_token": 143, "final_score": 401, "nome_squadra": "prova2", "spent_tokens": 0, "total_points": 401, "token_balance": 716, "tokens_initial": 50, "last_completion": "2026-08-19T09:03:10.879743+00:00", "modifier_points": 43, "starting_tokens": 50, "remaining_tokens": 716, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T20:56:47.285776+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T20:56:54.233151+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T20:57:01.127+00:00", "points_awarded": 0}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [{"name": "RUOTA SFORTUNATA", "status": "used", "item_id": "ruota_sfortunata", "timestamp": "2026-08-19T09:14:03.319751+00:00", "points_lost": 0, "transaction_id": "503f84df-7ebb-48d3-95ba-e92cb7355907", "attacker_team_id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "blocked_by_shield": false, "attacker_team_name": "prova"}, {"name": "TASSA DI PASSAGGIO", "status": "used", "item_id": "tassa_passaggio", "timestamp": "2026-08-19T09:14:49.493418+00:00", "points_lost": 0, "transaction_id": "1b026cfa-7821-43f8-94eb-762a05ee828b", "attacker_team_id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "blocked_by_shield": false, "attacker_team_name": "prova"}], "cattiveria_entries": [], "stage_total_points": 23, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:57:09.682757+00:00", "points_awarded": 0}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:57:44.998133+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:57:51.747796+00:00", "points_awarded": 15}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 22, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-18T20:58:10.419005+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-18T20:58:20.404161+00:00", "points_awarded": 20}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-18T20:58:33.063957+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 70, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-18T20:59:25.128471+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-18T20:59:39.913383+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-18T20:59:53.217436+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 60, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 10}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 10}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-19T09:03:10.879743+00:00", "points_awarded": -10}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 10, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 0, "challenges_points": 185, "total_game_points": 228, "total_time_seconds": 44775, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 143, "total_duration_seconds": 44775, "tokens_spent_marketplace": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 228}, {"id": "5ebc6287-ace7-4271-bb3a-d8fe9e74fb79", "name": "prova4", "rank": 2, "color": "#06b6d4", "motto": "In corsa per la vittoria!", "team_id": "5ebc6287-ace7-4271-bb3a-d8fe9e74fb79", "position": 2, "team_name": "prova4", "time_rank": 3, "avatar_url": "\ud83d\udc09", "base_score": 181, "final_rank": 2, "time_bonus": 20, "bonus_tempo": 20, "bonus_token": 149, "final_score": 350, "nome_squadra": "prova4", "spent_tokens": 0, "total_points": 350, "token_balance": 746, "tokens_initial": 50, "last_completion": "2026-08-19T09:07:40.901711+00:00", "modifier_points": 0, "starting_tokens": 50, "remaining_tokens": 746, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T21:22:33.283445+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T21:22:44.384927+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T21:23:39.564008+00:00", "points_awarded": 0}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 32, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:03:44.838069+00:00", "points_awarded": 0}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:04:15.82921+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:04:23.03363+00:00", "points_awarded": 15}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 22, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-19T09:04:50.535851+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-19T09:05:01.373944+00:00", "points_awarded": 20}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-19T09:05:15.026419+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 70, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-19T09:07:08.639938+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-19T09:07:17.002364+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-19T09:07:30.602661+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 44, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 10}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 10}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-19T09:07:40.901711+00:00", "points_awarded": -7}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 13, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 0, "challenges_points": 181, "total_game_points": 181, "total_time_seconds": 44844, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 149, "total_duration_seconds": 44844, "tokens_spent_marketplace": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 181}, {"id": "8333c106-0893-4fb7-8a19-c5e881054b12", "name": "prova3", "rank": 3, "color": "#ea580c", "motto": "In corsa per la vittoria!", "team_id": "8333c106-0893-4fb7-8a19-c5e881054b12", "position": 3, "team_name": "prova3", "time_rank": 4, "avatar_url": "\ud83d\udc3a", "base_score": 169, "final_rank": 3, "time_bonus": 17, "bonus_tempo": 17, "bonus_token": 128, "final_score": 314, "nome_squadra": "prova3", "spent_tokens": 0, "total_points": 314, "token_balance": 641, "tokens_initial": 50, "last_completion": "2026-08-19T09:12:46.793347+00:00", "modifier_points": 0, "starting_tokens": 50, "remaining_tokens": 641, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T21:36:15.504196+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T21:36:21.92435+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T21:36:29.526087+00:00", "points_awarded": 0}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 32, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T21:36:40.769601+00:00", "points_awarded": 0}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:11:24.603609+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:11:31.853862+00:00", "points_awarded": 0}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 7, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-19T09:11:45.62981+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-19T09:11:55.689327+00:00", "points_awarded": 0}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-19T09:12:06.835477+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 50, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-19T09:12:19.455191+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-19T09:12:26.420516+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-19T09:12:38.55457+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 60, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 10}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 20}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-19T09:12:46.793347+00:00", "points_awarded": -10}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 20, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 0, "challenges_points": 169, "total_game_points": 169, "total_time_seconds": 45159, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 128, "total_duration_seconds": 45159, "tokens_spent_marketplace": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 169}, {"id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "name": "prova", "rank": 4, "color": "#84cc16", "motto": "In corsa per la vittoria!", "team_id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "position": 4, "team_name": "prova", "time_rank": 2, "avatar_url": "\ud83e\udd8a", "base_score": 185, "final_rank": 4, "time_bonus": 25, "bonus_tempo": 25, "bonus_token": 43, "final_score": 253, "nome_squadra": "prova", "spent_tokens": 115, "total_points": 253, "token_balance": 218, "tokens_initial": 50, "last_completion": "2026-08-18T21:13:06.876309+00:00", "modifier_points": -50, "starting_tokens": 50, "remaining_tokens": 218, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T20:04:31.962841+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T20:04:46.443599+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T20:04:56.686252+00:00", "points_awarded": 20}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [{"name": "RUOTA DELLA FORTUNA", "is_used": true, "item_id": "ruota_fortuna", "timestamp": "2026-08-19T09:13:49.950717+00:00", "cost_tokens": 25, "transaction_id": "e51e3099-29a7-4180-9805-b41cf843e0e8", "cattiveria_delta": 0}], "maluses_used": [{"name": "RUOTA SFORTUNATA", "status": "used", "item_id": "ruota_sfortunata", "timestamp": "2026-08-19T09:14:03.319751+00:00", "cost_tokens": 20, "target_team_id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "transaction_id": "503f84df-7ebb-48d3-95ba-e92cb7355907", "cattiveria_delta": 10, "target_team_name": "prova2", "blocked_by_shield": false, "direct_points_delta": 0}, {"name": "TASSA DI PASSAGGIO", "status": "used", "item_id": "tassa_passaggio", "timestamp": "2026-08-19T09:14:49.493418+00:00", "cost_tokens": 70, "target_team_id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "transaction_id": "1b026cfa-7821-43f8-94eb-762a05ee828b", "cattiveria_delta": 10, "target_team_name": "prova2", "blocked_by_shield": false, "direct_points_delta": 0}], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [{"id": "cb95c249-917b-4ca0-a411-7195f6990395", "punti": 10, "motivo": "Malus RUOTA SFORTUNATA attivato.", "timestamp": "2026-08-19T09:14:03.319751+00:00"}, {"id": "9ed5a4fc-68f2-483b-b694-9469df2f3615", "punti": 10, "motivo": "Tassa di Passaggio attivata.", "timestamp": "2026-08-19T09:14:49.493418+00:00"}], "stage_total_points": 72, "stage_reward_tokens": 0, "cattiveria_stage_total": 20}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:06:12.4253+00:00", "points_awarded": 3}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:13:17.815981+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:18:01.47827+00:00", "points_awarded": 15}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 25, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-18T20:29:31.862935+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-18T20:29:45.151191+00:00", "points_awarded": 18}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-18T20:36:59.38274+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 68, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-18T20:38:38.385845+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-18T20:38:49.364491+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-18T20:39:01.841117+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 60, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 20}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 10}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-18T21:13:06.876309+00:00", "points_awarded": -20}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 10, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 20, "challenges_points": 215, "total_game_points": 185, "total_time_seconds": 44785, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 43, "total_duration_seconds": 44785, "tokens_spent_marketplace": 115, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 185}], "stages": [{"id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "name": "Il Passaporto di Bra", "order": 1, "status": "open", "challenges_count": 3}, {"id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "name": "Il Rebus Visivo", "order": 2, "status": "open", "challenges_count": 3}, {"id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "name": "La Banca", "order": 3, "status": "open", "challenges_count": 3}, {"id": "4b4b4c4d-5e5f-6061-7172-838485868788", "name": "Enigmi", "order": 4, "status": "open", "challenges_count": 3}, {"id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "name": "Tappa Finale", "order": 5, "status": "open", "challenges_count": 3}]}'::jsonb, '2026-08-19T10:10:44.822421+00:00', 'PUBLISHED', '2026-08-19T10:10:44.822421+00:00', '11111111-1111-1111-1111-111111111111', '{"teams": [{"id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "name": "prova2", "rank": 1, "color": "#22c55e", "motto": "In corsa per la vittoria!", "team_id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "position": 1, "team_name": "prova2", "time_rank": 1, "avatar_url": "\ud83d\udc05", "base_score": 228, "final_rank": 1, "time_bonus": 30, "bonus_tempo": 30, "bonus_token": 143, "final_score": 401, "nome_squadra": "prova2", "spent_tokens": 0, "total_points": 401, "token_balance": 716, "tokens_initial": 50, "last_completion": "2026-08-19T09:03:10.879743+00:00", "modifier_points": 43, "starting_tokens": 50, "remaining_tokens": 716, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T20:56:47.285776+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T20:56:54.233151+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T20:57:01.127+00:00", "points_awarded": 0}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [{"name": "RUOTA SFORTUNATA", "status": "used", "item_id": "ruota_sfortunata", "timestamp": "2026-08-19T09:14:03.319751+00:00", "points_lost": 0, "transaction_id": "503f84df-7ebb-48d3-95ba-e92cb7355907", "attacker_team_id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "blocked_by_shield": false, "attacker_team_name": "prova"}, {"name": "TASSA DI PASSAGGIO", "status": "used", "item_id": "tassa_passaggio", "timestamp": "2026-08-19T09:14:49.493418+00:00", "points_lost": 0, "transaction_id": "1b026cfa-7821-43f8-94eb-762a05ee828b", "attacker_team_id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "blocked_by_shield": false, "attacker_team_name": "prova"}], "cattiveria_entries": [], "stage_total_points": 23, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:57:09.682757+00:00", "points_awarded": 0}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:57:44.998133+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:57:51.747796+00:00", "points_awarded": 15}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 22, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-18T20:58:10.419005+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-18T20:58:20.404161+00:00", "points_awarded": 20}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-18T20:58:33.063957+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 70, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-18T20:59:25.128471+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-18T20:59:39.913383+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-18T20:59:53.217436+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 60, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 10}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 10}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-19T09:03:10.879743+00:00", "points_awarded": -10}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 10, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 0, "challenges_points": 185, "total_game_points": 228, "total_time_seconds": 44775, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 143, "total_duration_seconds": 44775, "tokens_spent_marketplace": 0, "count_partenza_anticipata": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 228, "partenza_anticipata_seconds_saved": 0}, {"id": "5ebc6287-ace7-4271-bb3a-d8fe9e74fb79", "name": "prova4", "rank": 2, "color": "#06b6d4", "motto": "In corsa per la vittoria!", "team_id": "5ebc6287-ace7-4271-bb3a-d8fe9e74fb79", "position": 2, "team_name": "prova4", "time_rank": 3, "avatar_url": "\ud83d\udc09", "base_score": 181, "final_rank": 2, "time_bonus": 20, "bonus_tempo": 20, "bonus_token": 149, "final_score": 350, "nome_squadra": "prova4", "spent_tokens": 0, "total_points": 350, "token_balance": 746, "tokens_initial": 50, "last_completion": "2026-08-19T09:07:40.901711+00:00", "modifier_points": 0, "starting_tokens": 50, "remaining_tokens": 746, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T21:22:33.283445+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T21:22:44.384927+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T21:23:39.564008+00:00", "points_awarded": 0}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 32, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:03:44.838069+00:00", "points_awarded": 0}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:04:15.82921+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:04:23.03363+00:00", "points_awarded": 15}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 22, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-19T09:04:50.535851+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-19T09:05:01.373944+00:00", "points_awarded": 20}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-19T09:05:15.026419+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 70, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-19T09:07:08.639938+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-19T09:07:17.002364+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-19T09:07:30.602661+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 44, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 10}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 10}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-19T09:07:40.901711+00:00", "points_awarded": -7}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 13, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 0, "challenges_points": 181, "total_game_points": 181, "total_time_seconds": 44844, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 149, "total_duration_seconds": 44844, "tokens_spent_marketplace": 0, "count_partenza_anticipata": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 181, "partenza_anticipata_seconds_saved": 0}, {"id": "8333c106-0893-4fb7-8a19-c5e881054b12", "name": "prova3", "rank": 3, "color": "#ea580c", "motto": "In corsa per la vittoria!", "team_id": "8333c106-0893-4fb7-8a19-c5e881054b12", "position": 3, "team_name": "prova3", "time_rank": 4, "avatar_url": "\ud83d\udc3a", "base_score": 169, "final_rank": 3, "time_bonus": 17, "bonus_tempo": 17, "bonus_token": 128, "final_score": 314, "nome_squadra": "prova3", "spent_tokens": 0, "total_points": 314, "token_balance": 641, "tokens_initial": 50, "last_completion": "2026-08-19T09:12:46.793347+00:00", "modifier_points": 0, "starting_tokens": 50, "remaining_tokens": 641, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T21:36:15.504196+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T21:36:21.92435+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T21:36:29.526087+00:00", "points_awarded": 0}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 32, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T21:36:40.769601+00:00", "points_awarded": 0}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:11:24.603609+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-19T09:11:31.853862+00:00", "points_awarded": 0}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 7, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-19T09:11:45.62981+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-19T09:11:55.689327+00:00", "points_awarded": 0}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-19T09:12:06.835477+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 50, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-19T09:12:19.455191+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-19T09:12:26.420516+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-19T09:12:38.55457+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 60, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 10}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 20}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-19T09:12:46.793347+00:00", "points_awarded": -10}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 20, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 0, "challenges_points": 169, "total_game_points": 169, "total_time_seconds": 45159, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 128, "total_duration_seconds": 45159, "tokens_spent_marketplace": 0, "count_partenza_anticipata": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 169, "partenza_anticipata_seconds_saved": 0}, {"id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "name": "prova", "rank": 4, "color": "#84cc16", "motto": "In corsa per la vittoria!", "team_id": "c523ba36-0dd2-4cde-a373-59efbe2ba7c3", "position": 4, "team_name": "prova", "time_rank": 2, "avatar_url": "\ud83e\udd8a", "base_score": 185, "final_rank": 4, "time_bonus": 25, "bonus_tempo": 25, "bonus_token": 43, "final_score": 253, "nome_squadra": "prova", "spent_tokens": 115, "total_points": 253, "token_balance": 218, "tokens_initial": 50, "last_completion": "2026-08-18T21:13:06.876309+00:00", "modifier_points": -50, "starting_tokens": 50, "remaining_tokens": 218, "stages_breakdown": [{"stage_id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "challenges": [{"type": "team_setup", "order": 1, "title": "Creazione squadra", "completed": true, "max_points": 5, "challenge_id": "81b2f378-dc50-4bb8-a0e8-8f20f6d2fb47", "completed_at": "2026-08-18T20:04:31.962841+00:00", "points_awarded": 5}, {"type": "quiz", "order": 2, "title": "Quiz Bra", "completed": true, "max_points": 15, "challenge_id": "c4e6c385-69ba-4f17-a6d0-36b78776d527", "completed_at": "2026-08-18T20:04:46.443599+00:00", "points_awarded": 15}, {"type": "photo", "order": 3, "title": "Foto ufficiale", "completed": true, "max_points": 10, "challenge_id": "0147e750-f0a3-4b72-8e76-a003fe2ef143", "completed_at": "2026-08-18T20:04:56.686252+00:00", "points_awarded": 20}], "stage_name": "Il Passaporto di Bra", "stage_order": 1, "bonuses_used": [{"name": "RUOTA DELLA FORTUNA", "is_used": true, "item_id": "ruota_fortuna", "timestamp": "2026-08-19T09:13:49.950717+00:00", "cost_tokens": 25, "transaction_id": "e51e3099-29a7-4180-9805-b41cf843e0e8", "cattiveria_delta": 0}], "maluses_used": [{"name": "RUOTA SFORTUNATA", "status": "used", "item_id": "ruota_sfortunata", "timestamp": "2026-08-19T09:14:03.319751+00:00", "cost_tokens": 20, "target_team_id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "transaction_id": "503f84df-7ebb-48d3-95ba-e92cb7355907", "cattiveria_delta": 10, "target_team_name": "prova2", "blocked_by_shield": false, "direct_points_delta": 0}, {"name": "TASSA DI PASSAGGIO", "status": "used", "item_id": "tassa_passaggio", "timestamp": "2026-08-19T09:14:49.493418+00:00", "cost_tokens": 70, "target_team_id": "a6e05001-0c8e-4194-b46b-e56568ab9fb8", "transaction_id": "1b026cfa-7821-43f8-94eb-762a05ee828b", "cattiveria_delta": 10, "target_team_name": "prova2", "blocked_by_shield": false, "direct_points_delta": 0}], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [{"id": "cb95c249-917b-4ca0-a411-7195f6990395", "punti": 10, "motivo": "Malus RUOTA SFORTUNATA attivato.", "timestamp": "2026-08-19T09:14:03.319751+00:00"}, {"id": "9ed5a4fc-68f2-483b-b694-9469df2f3615", "punti": 10, "motivo": "Tassa di Passaggio attivata.", "timestamp": "2026-08-19T09:14:49.493418+00:00"}], "stage_total_points": 72, "stage_reward_tokens": 0, "cattiveria_stage_total": 20}, {"stage_id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "challenges": [{"type": "photo", "order": 1, "title": "Il Rebus Visivo", "completed": true, "max_points": 25, "challenge_id": "999f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:06:12.4253+00:00", "points_awarded": 3}, {"type": "emoji_movies", "order": 2, "title": "Indovina il film dalle emoji", "completed": true, "max_points": 15, "challenge_id": "777f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:13:17.815981+00:00", "points_awarded": 7}, {"type": "living_poster", "order": 3, "title": "La locandina vivente", "completed": true, "max_points": 15, "challenge_id": "555f4e1f-7443-42e7-9d7a-115f2122888f", "completed_at": "2026-08-18T20:18:01.47827+00:00", "points_awarded": 15}], "stage_name": "Il Rebus Visivo", "stage_order": 2, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 25, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "banca", "order": 1, "title": "La Banca", "completed": true, "max_points": 25, "challenge_id": "b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6", "completed_at": "2026-08-18T20:29:31.862935+00:00", "points_awarded": 5}, {"type": "social", "order": 2, "title": "Missione Social", "completed": true, "max_points": 20, "challenge_id": "c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7", "completed_at": "2026-08-18T20:29:45.151191+00:00", "points_awarded": 18}, {"type": "codice", "order": 3, "title": "Il Codice Segreto", "completed": true, "max_points": 15, "challenge_id": "d3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8", "completed_at": "2026-08-18T20:36:59.38274+00:00", "points_awarded": 30}], "stage_name": "La Banca", "stage_order": 3, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 68, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "4b4b4c4d-5e5f-6061-7172-838485868788", "challenges": [{"type": "enigma_musicale", "order": 1, "title": "Rebus Musicale", "completed": true, "max_points": 20, "challenge_id": "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7", "completed_at": "2026-08-18T20:38:38.385845+00:00", "points_awarded": 20}, {"type": "lucchetto_direzionale", "order": 2, "title": "Lucchetto Direzionale", "completed": true, "max_points": 20, "challenge_id": "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8", "completed_at": "2026-08-18T20:38:49.364491+00:00", "points_awarded": 20}, {"type": "enigma_coordinate", "order": 3, "title": "Le Coordinate Finali", "completed": true, "max_points": 20, "challenge_id": "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9", "completed_at": "2026-08-18T20:39:01.841117+00:00", "points_awarded": 20}], "stage_name": "Enigmi", "stage_order": 4, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 60, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}, {"stage_id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "challenges": [{"type": "cornhole", "order": 1, "title": "Sfida Cornhole", "completed": true, "max_points": 20, "challenge_id": "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0", "completed_at": "2026-08-18T21:04:45.685608+00:00", "points_awarded": 20}, {"type": "boxe", "order": 2, "title": "Boxe Gonfiabile", "completed": true, "max_points": 20, "challenge_id": "d5d5d5d5-e6e6-f7f7-f8f8-b9b9b0b0b0b0", "completed_at": "2026-08-18T21:08:09.328177+00:00", "points_awarded": 10}, {"type": "jackpot", "order": 3, "title": "Jackpot della Regia", "completed": true, "max_points": 20, "challenge_id": "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0", "completed_at": "2026-08-18T21:13:06.876309+00:00", "points_awarded": -20}], "stage_name": "Tappa Finale", "stage_order": 5, "bonuses_used": [], "maluses_used": [], "stage_status": "open", "maluses_suffered": [], "cattiveria_entries": [], "stage_total_points": 10, "stage_reward_tokens": 0, "cattiveria_stage_total": 0}], "cattiveria_points": 20, "challenges_points": 215, "total_game_points": 185, "total_time_seconds": 44785, "completed_challenges": 15, "tokens_gained_rewards": 0, "token_efficiency_bonus": 43, "total_duration_seconds": 44785, "tokens_spent_marketplace": 115, "count_partenza_anticipata": 0, "tokens_gained_stage_rewards": 0, "total_score_before_final_bonuses": 185, "partenza_anticipata_seconds_saved": 0}], "stages": [{"id": "4a57212e-7e83-430c-b5fe-6cf38db7be2e", "name": "Il Passaporto di Bra", "order": 1, "status": "open", "challenges_count": 3}, {"id": "dfa9e6db-4e1b-41be-94be-21cf2980fa2a", "name": "Il Rebus Visivo", "order": 2, "status": "open", "challenges_count": 3}, {"id": "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c", "name": "La Banca", "order": 3, "status": "open", "challenges_count": 3}, {"id": "4b4b4c4d-5e5f-6061-7172-838485868788", "name": "Enigmi", "order": 4, "status": "open", "challenges_count": 3}, {"id": "5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c", "name": "Tappa Finale", "order": 5, "status": "open", "challenges_count": 3}]}'::jsonb) ON CONFLICT DO NOTHING;

-- Table: game_settings (1 records)
INSERT INTO public.game_settings (id, marketplace_visible, marketplace_active, activated_at, activated_by, cornhole_special_bye_team_id, boxe_special_bye_team_id) VALUES ('settings_01', True, True, '2026-08-18T09:02:31.813811+00:00', '11111111-1111-1111-1111-111111111111', NULL, NULL) ON CONFLICT DO NOTHING;

-- Table: marketplace_items (12 records)
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('bonus_punti', 'BONUS PUNTI (+20 PT)', 'bonus', 'Aggiunge +20 PT alla classifica della squadra.', 40, '', 'Sparkles', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('bonus_scudo', 'BONUS SCUDO', 'bonus', 'Protegge la squadra da un malus attivo.', 35, '', 'Shield', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('ruota_fortuna', 'RUOTA DELLA FORTUNA', 'bonus', 'Gira la ruota per vincere premi o subire perdite casuali.', 25, '', 'Compass', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('passaparola', 'PASSAPAROLA', 'bonus', 'Ricevi un aiuto dalla regia.', 20, '', 'HelpCircle', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('bonus_classifica', 'BONUS CLASSIFICA', 'bonus', 'Permette di sbirciare la classifica.', 30, '', 'ListOrdered', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('partenza_anticipata', 'PARTENZA ANTICIPATA', 'bonus', 'Riduce di 2 minuti il tempo di partenza.', 35, '', 'Zap', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('freeze_2min', 'FREEZE 2 MINUTI', 'malus', 'Blocca una squadra avversaria per 2 minuti.', 20, '', 'Flame', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('enigma_extra', 'ENIGMA EXTRA', 'malus', 'Obbliga gli avversari a risolvere un enigma aggiuntivo.', 25, '', 'AlertTriangle', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('ruota_sfortunata', 'RUOTA SFORTUNATA', 'malus', 'Obbliga gli avversari a fare uno spin sfortunato.', 20, '', 'Skull', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('trappola', 'TRAPPOLA PUNTI', 'malus', 'Ruba 30 punti alla squadra bersaglio.', 40, '', 'Target', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('penalita_punti', 'PENALITÀ PUNTI (-20 PT)', 'malus', 'Sottrae 20 punti ad una squadra avversaria.', 30, '', 'MinusCircle', True, '{}'::jsonb) ON CONFLICT DO NOTHING;
INSERT INTO public.marketplace_items (id, nome, tipo, descrizione, costo_token, effetto, icona, disponibile, regole) VALUES ('tassa_passaggio', 'TASSA DI PASSAGGIO', 'malus', 'Scambia i punti con quelli di un''altra squadra.', 70, '', 'TrendingUp', True, '{}'::jsonb) ON CONFLICT DO NOTHING;

-- Table: posters (10 records)
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_01', 'Poster1.jpg', 'Indiana Jones', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_02', 'Poster2.jpg', 'Back to the Future', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_03', 'Poster3.jpg', 'Star Wars', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_04', 'Poster4.jpg', 'Jurassic Park', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_05', 'Poster5.jpg', 'Titanic', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_06', 'Poster6.jpg', 'Pulp Fiction', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_07', 'Poster7.jpg', 'The Matrix', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_08', 'Poster8.jpg', 'Forrest Gump', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_09', 'Poster9.jpg', 'E.T.', True) ON CONFLICT DO NOTHING;
INSERT INTO public.posters (id, file_name, titolo, active) VALUES ('poster_10', 'Poster10.jpg', 'The Godfather', True) ON CONFLICT DO NOTHING;

-- Table: quiz_questions (5 records)
INSERT INTO public.quiz_questions (id, challenge_id, question, options, correct_answer_index, order_index, points, created_at) VALUES ('a1111111-1111-1111-1111-111111111111', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Qual è il piatto tipico a base di carne cruda di Bra?', '["Salsiccia di Bra", "Prosciutto di Cuneo", "Vitello Tonnato", "Battuta di Fassona"]'::jsonb, 0, 1, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions (id, challenge_id, question, options, correct_answer_index, order_index, points, created_at) VALUES ('a2222222-2222-2222-2222-222222222222', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'In quale regione italiana si trova Bra?', '["Lombardia", "Piemonte", "Liguria", "Veneto"]'::jsonb, 1, 2, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions (id, challenge_id, question, options, correct_answer_index, order_index, points, created_at) VALUES ('a3333333-3333-3333-3333-333333333333', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Quale importante movimento internazionale è nato a Bra?', '["Slow Food", "WWF", "Greenpeace", "Caritas"]'::jsonb, 0, 3, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions (id, challenge_id, question, options, correct_answer_index, order_index, points, created_at) VALUES ('a4444444-4444-4444-4444-444444444444', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Quale celebre scrittore piemontese nacque nei pressi di Bra?', '["Cesare Pavese", "Beppe Fenoglio", "Giovanni Arpino", "Italo Calvino"]'::jsonb, 2, 4, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions (id, challenge_id, question, options, correct_answer_index, order_index, points, created_at) VALUES ('a5555555-5555-5555-5555-555555555555', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Che tipo di formaggio DOP prende il nome da questa città?', '["Castelmagno", "Murazzano", "Raschera", "Bra DOP"]'::jsonb, 3, 5, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;

-- Table: quiz_questions_public (5 records)
INSERT INTO public.quiz_questions_public (id, challenge_id, question, options, order_index, points, created_at) VALUES ('a1111111-1111-1111-1111-111111111111', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Qual è il piatto tipico a base di carne cruda di Bra?', '["Salsiccia di Bra", "Prosciutto di Cuneo", "Vitello Tonnato", "Battuta di Fassona"]'::jsonb, 1, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions_public (id, challenge_id, question, options, order_index, points, created_at) VALUES ('a2222222-2222-2222-2222-222222222222', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'In quale regione italiana si trova Bra?', '["Lombardia", "Piemonte", "Liguria", "Veneto"]'::jsonb, 2, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions_public (id, challenge_id, question, options, order_index, points, created_at) VALUES ('a3333333-3333-3333-3333-333333333333', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Quale importante movimento internazionale è nato a Bra?', '["Slow Food", "WWF", "Greenpeace", "Caritas"]'::jsonb, 3, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions_public (id, challenge_id, question, options, order_index, points, created_at) VALUES ('a4444444-4444-4444-4444-444444444444', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Quale celebre scrittore piemontese nacque nei pressi di Bra?', '["Cesare Pavese", "Beppe Fenoglio", "Giovanni Arpino", "Italo Calvino"]'::jsonb, 4, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.quiz_questions_public (id, challenge_id, question, options, order_index, points, created_at) VALUES ('a5555555-5555-5555-5555-555555555555', 'c4e6c385-69ba-4f17-a6d0-36b78776d527', 'Che tipo di formaggio DOP prende il nome da questa città?', '["Castelmagno", "Murazzano", "Raschera", "Bra DOP"]'::jsonb, 5, 3, '2026-08-18T19:54:47.974481+00:00') ON CONFLICT DO NOTHING;

-- Table: settings (3 records)
INSERT INTO public.settings (id, value, updated_at) VALUES ('game_status', 'Gara non iniziata', '2026-08-19T12:57:30.903+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.settings (id, value, updated_at) VALUES ('game_started_at', '', '2026-08-19T12:57:30.903+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.settings (id, value, updated_at) VALUES ('game_ended_at', '', '2026-08-19T12:57:30.903+00:00') ON CONFLICT DO NOTHING;

-- Table: stages (5 records)
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome, created_at) VALUES ('4a57212e-7e83-430c-b5fe-6cf38db7be2e', 1, 'Il Passaporto di Bra', 'Piazza Caduti per la Libertà, 14', 44.6982, 7.8507, 'open', NULL, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome, created_at) VALUES ('dfa9e6db-4e1b-41be-94be-21cf2980fa2a', 2, 'Il Rebus Visivo', 'Via Mendicità Istruita, 12', 44.6976, 7.8544, 'open', NULL, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome, created_at) VALUES ('3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c', 3, 'La Banca', 'Stazione Ferroviaria di Bra', 44.6946, 7.8542, 'open', NULL, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome, created_at) VALUES ('4b4b4c4d-5e5f-6061-7172-838485868788', 4, 'Enigmi', 'Risolvi gli enigmi e inserisci le soluzioni per avanzare.', NULL, NULL, 'open', NULL, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.stages (id, numero_tappa, titolo, descrizione, latitude, longitude, stato, outcome, created_at) VALUES ('5c5c5d5e-6f6a-7b7b-8c8c-9c9c9c9c9c9c', 5, 'Tappa Finale', 'Traguardo finale della gara! Raggiungete la destinazione.', 44.7163149, 7.8429014, 'open', NULL, '2026-08-18T08:11:18.44514+00:00') ON CONFLICT DO NOTHING;

-- Table: user_roles (5 records)
INSERT INTO public.user_roles (id, user_id, role, team_id, created_at) VALUES ('324f71eb-5375-4915-93ed-cd99bf983b9a', '11111111-1111-1111-1111-111111111111', 'admin', NULL, '2026-08-18T08:24:30.701766+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.user_roles (id, user_id, role, team_id, created_at) VALUES ('17e1657a-21f7-4ced-90e8-0d51d5fdc3b9', '11111111-1111-1111-1111-111111111111', 'admin', NULL, '2026-08-19T08:13:21.281806+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.user_roles (id, user_id, role, team_id, created_at) VALUES ('91279c0c-9319-475e-ba62-ea15a7f3d385', '00000000-0000-0000-0000-000000000001', 'admin', NULL, '2026-08-19T08:18:13.819782+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.user_roles (id, user_id, role, team_id, created_at) VALUES ('89636442-ada3-471f-9e6f-f78bb94eb2f3', '55555555-0000-0000-0000-000000000001', 'admin', NULL, '2026-08-19T08:30:58.932358+00:00') ON CONFLICT DO NOTHING;
INSERT INTO public.user_roles (id, user_id, role, team_id, created_at) VALUES ('969f79bd-8271-4a77-a01d-efe7c407e19e', '55555555-0000-0000-0000-000000000001', 'admin', NULL, '2026-08-19T08:31:16.107856+00:00') ON CONFLICT DO NOTHING;
