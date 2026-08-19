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
