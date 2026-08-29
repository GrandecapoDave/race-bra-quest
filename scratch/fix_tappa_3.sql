BEGIN;

-- ==========================================================
-- 1. TABELLA E RPC PER SFIDA 1 (LA BANCA)
-- ==========================================================
CREATE TABLE IF NOT EXISTS public.team_bank_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  question_number INTEGER NOT NULL,
  answer TEXT NOT NULL,
  extracted_letter CHAR(1) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT team_bank_answers_team_q_key UNIQUE (team_id, question_number)
);

ALTER TABLE public.team_bank_answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Team Read Own Bank Answers" ON public.team_bank_answers;
CREATE POLICY "Team Read Own Bank Answers" ON public.team_bank_answers FOR SELECT USING (
  team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin')
);

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
  IF v_caller_team_id IS NOT NULL THEN
    p_team_id := v_caller_team_id;
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'question_number', question_number,
    'answer', answer,
    'extracted_letter', extracted_letter
  ) ORDER BY question_number), '[]'::jsonb) INTO v_answers
  FROM public.team_bank_answers
  WHERE team_id = p_team_id;

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
  v_challenge_completed BOOLEAN := false;
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  IF p_question_number = 1 THEN v_correct_answer := 'LUMACA';
  ELSIF p_question_number = 2 THEN v_correct_answer := 'DIVANO';
  ELSIF p_question_number = 3 THEN v_correct_answer := 'PALLA';
  ELSIF p_question_number = 4 THEN v_correct_answer := 'NASO';
  ELSE RAISE EXCEPTION 'Numero domanda non valido';
  END IF;

  v_correct := (UPPER(TRIM(p_answer)) = v_correct_answer);
  v_letter := SUBSTRING(v_correct_answer FROM 1 FOR 1);

  IF v_correct THEN
    INSERT INTO public.team_bank_answers (team_id, question_number, answer, extracted_letter)
    VALUES (v_team_id, p_question_number, UPPER(TRIM(p_answer)), v_letter)
    ON CONFLICT (team_id, question_number) DO UPDATE
    SET answer = EXCLUDED.answer, extracted_letter = EXCLUDED.extracted_letter;

    IF (SELECT COUNT(*) FROM public.team_bank_answers WHERE team_id = v_team_id) = 4 THEN
      v_challenge_completed := true;
      PERFORM public.complete_challenge('b1b2b3b4-b5b6-b7b8-b9b0-b1b2b3b4b5b6');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'correct', v_correct,
    'letter', v_letter,
    'challenge_completed', v_challenge_completed
  );
END;
$$;

-- ==========================================================
-- 2. TABELLA E RPC PER SFIDA 2 (MISSIONE SOCIAL)
-- ==========================================================
ALTER TABLE public.team_social_submissions ADD COLUMN IF NOT EXISTS image_1_url TEXT;
ALTER TABLE public.team_social_submissions ADD COLUMN IF NOT EXISTS image_2_url TEXT;
ALTER TABLE public.team_social_submissions ADD COLUMN IF NOT EXISTS admin_score INTEGER;
ALTER TABLE public.team_social_submissions ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'submitted';
ALTER TABLE public.team_social_submissions ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.team_social_submissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Team Read Own Social Submissions" ON public.team_social_submissions;
CREATE POLICY "Team Read Own Social Submissions" ON public.team_social_submissions FOR SELECT USING (
  team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin')
);

CREATE OR REPLACE FUNCTION public.submit_social_challenge(
  p_image_1_path TEXT,
  p_image_2_path TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

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
$$;

-- ==========================================================
-- 3. TABELLA E RPC PER SFIDA 3 (IL CODICE SEGRETO)
-- ==========================================================
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
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
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
    WHERE team_id = p_team_id AND challenge_id = v_challenge_id AND stato = 'completed'
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

CREATE OR REPLACE FUNCTION public.submit_secret_code_pin(p_inserted_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_team_id UUID;
  v_correct_pin TEXT := '1234567890';
  v_correct BOOLEAN := false;
  v_challenge_id UUID := 'd3d4d5d6-d7d8-d9d0-e1e2-e3e4e5e6e7e8';
BEGIN
  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  v_correct := (p_inserted_code = v_correct_pin);

  IF v_correct THEN
    INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
    VALUES (v_team_id, v_challenge_id, 'completed', now())
    ON CONFLICT (team_id, challenge_id) 
    DO UPDATE SET stato = 'completed', completata_il = now();

    INSERT INTO public.scores (team_id, challenge_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, 30, 'challenge_points', 'Sfida PIN superata');
  END IF;

  RETURN jsonb_build_object(
    'success', v_correct,
    'message', CASE WHEN v_correct THEN 'Sbloccato!' ELSE 'Codice errato' END
  );
END;
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
