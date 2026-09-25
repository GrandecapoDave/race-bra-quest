-- 32_quiz_single_answer.sql
-- Quiz: ogni domanda ha UNA sola risposta. L'app gia' blocca le opzioni dopo la prima risposta, ma il database permetteva di
-- riscrivere la risposta: chi chiamava la funzione a mano poteva dare una risposta sbagliata dopo una giusta e poi di nuovo la giusta,
-- incassando +3 ogni volta. Ora la seconda chiamata sulla stessa domanda non cambia nulla e non da' punti. Ripetibile.

DO $patch$
DECLARE
  def text;
  newdef text;
  v_anchor text := E'  SELECT EXISTS (SELECT 1 FROM public.team_answers WHERE team_id = v_team_id AND question_id = p_question AND correct) INTO v_prev_correct;\n';
  v_guard text := E'  IF EXISTS (SELECT 1 FROM public.team_answers WHERE team_id = v_team_id AND question_id = p_question) THEN\n    -- una sola risposta per domanda: niente modifiche, niente punti\n    RETURN jsonb_build_object(''correct'', v_prev_correct, ''points'', 0, ''already_answered'', true);\n  END IF;\n';
BEGIN
  def := pg_get_functiondef('public.submit_quiz_answer(uuid,integer)'::regprocedure);
  IF position('already_answered' IN def) > 0 THEN
    RETURN; -- gia' applicata
  END IF;
  IF position(v_anchor IN def) = 0 THEN
    RAISE EXCEPTION 'submit_quiz_answer: punto di inserimento non trovato';
  END IF;
  newdef := replace(def, v_anchor, v_anchor || v_guard);
  IF newdef = def THEN
    RAISE EXCEPTION 'submit_quiz_answer: modifica non applicata';
  END IF;
  EXECUTE newdef;
END
$patch$;
