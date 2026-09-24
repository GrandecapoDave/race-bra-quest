-- 08_emoji_movies_rpc.sql
-- "Indovina il film dalle emoji": risposte verificate lato server, punteggio reale (+1 giusto, -2 sbagliato, max 3 tentativi per film).
-- Prima le risposte erano nel client e gli inserimenti in `scores` venivano bloccati dall'RLS: i toast mostravano punti mai assegnati.

-- Il titolo corretto viene salvato solo quando il film è risolto (giusto o 3 tentativi esauriti)
ALTER TABLE public.team_emoji_movies ADD COLUMN IF NOT EXISTS title TEXT;

CREATE OR REPLACE FUNCTION public.submit_emoji_movie_answer(p_movie_index integer, p_answer text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := '777f4e1f-7443-42e7-9d7a-115f2122888f';
  v_stage_id UUID;
  v_titles TEXT[] := ARRAY['Venom','Inside Out','Titanic','Toy Story','Oceania','Ratatouille','It','Avatar'];
  v_title TEXT;
  v_letter TEXT;
  v_existing RECORD;
  v_attempts INTEGER;
  v_correct BOOLEAN;
  v_resolved BOOLEAN;
BEGIN
  IF EXISTS (SELECT 1 FROM public.game_settings WHERE race_status = 'completed') THEN
    RAISE EXCEPTION 'La gara è terminata! Non è più possibile compiere azioni.';
  END IF;

  v_team_id := public.current_team_id();
  IF v_team_id IS NULL THEN
    RAISE EXCEPTION 'Non autenticato';
  END IF;

  IF p_movie_index IS NULL OR p_movie_index < 1 OR p_movie_index > 8 THEN
    RAISE EXCEPTION 'Film non valido';
  END IF;

  v_title := v_titles[p_movie_index];
  v_letter := UPPER(LEFT(v_title, 1));
  SELECT stage_id INTO v_stage_id FROM public.challenges WHERE id = v_challenge_id;

  PERFORM pg_advisory_xact_lock(hashtext('emoji:' || v_team_id::text || ':' || p_movie_index::text));

  SELECT * INTO v_existing
  FROM public.team_emoji_movies
  WHERE team_id = v_team_id AND movie_index = p_movie_index
  LIMIT 1;

  -- Già risolto (giusto o 3 tentativi esauriti): nessun nuovo punteggio
  IF FOUND AND (v_existing.is_correct OR v_existing.attempts >= 3) THEN
    RETURN jsonb_build_object(
      'is_correct', v_existing.is_correct,
      'attempts', v_existing.attempts,
      'already_resolved', true,
      'title', v_title,
      'letter', v_letter
    );
  END IF;

  v_attempts := COALESCE(v_existing.attempts, 0) + 1;
  v_correct := LOWER(TRIM(COALESCE(p_answer, ''))) = LOWER(v_title);
  v_resolved := v_correct OR v_attempts >= 3;

  IF FOUND THEN
    UPDATE public.team_emoji_movies
    SET attempts = v_attempts,
        last_answer = p_answer,
        is_correct = v_correct,
        points = CASE WHEN v_correct THEN 1 ELSE 0 END,
        letter = CASE WHEN v_resolved THEN v_letter ELSE NULL END,
        title = CASE WHEN v_resolved THEN v_title ELSE NULL END
    WHERE id = v_existing.id;
  ELSE
    INSERT INTO public.team_emoji_movies (team_id, movie_index, attempts, last_answer, is_correct, points, letter, title)
    VALUES (v_team_id, p_movie_index, v_attempts, p_answer, v_correct, CASE WHEN v_correct THEN 1 ELSE 0 END,
            CASE WHEN v_resolved THEN v_letter ELSE NULL END, CASE WHEN v_resolved THEN v_title ELSE NULL END);
  END IF;

  IF v_correct THEN
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, 1, 'challenge_points',
            'Indovinato film dalle emoji: ' || v_title || ' (' || p_movie_index || '/8)');
  ELSE
    INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
    VALUES (v_team_id, v_challenge_id, v_stage_id, -2, 'penalty',
            'Errore film emoji #' || p_movie_index || ': "' || LEFT(COALESCE(p_answer, ''), 60) || '" (-2 PT)');
  END IF;

  RETURN jsonb_build_object(
    'is_correct', v_correct,
    'attempts', v_attempts,
    'already_resolved', false,
    'title', CASE WHEN v_resolved THEN v_title ELSE NULL END,
    'letter', CASE WHEN v_resolved THEN v_letter ELSE NULL END
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.submit_emoji_movie_answer(integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_emoji_movie_answer(integer, text) TO authenticated;
