-- Rollback della migrazione 38_fix_admin_edit_bank_answer.sql: ripristina la firma e la logica precedenti (rotte)
DROP FUNCTION IF EXISTS public.admin_edit_bank_answer(uuid, integer, boolean, uuid, text);

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
$function$;
