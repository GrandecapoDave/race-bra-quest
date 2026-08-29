BEGIN;

-- 1. Svuota e ripopola la tabella posters con le 10 locandine reali
DELETE FROM public.posters;

INSERT INTO public.posters (id, file_name, titolo, active)
VALUES
  ('poster_01', 'Poster1.jpg', 'Indiana Jones', true),
  ('poster_02', 'Poster2.jpg', 'Back to the Future', true),
  ('poster_03', 'Poster3.jpg', 'Star Wars', true),
  ('poster_04', 'Poster4.jpg', 'Jurassic Park', true),
  ('poster_05', 'Poster5.jpg', 'Titanic', true),
  ('poster_06', 'Poster6.jpg', 'Pulp Fiction', true),
  ('poster_07', 'Poster7.jpg', 'The Matrix', true),
  ('poster_08', 'Poster8.jpg', 'Forrest Gump', true),
  ('poster_09', 'Poster9.jpg', 'E.T.', true),
  ('poster_10', 'Poster10.jpg', 'The Godfather', true);

-- 2. Aggiorna RPC get_or_assign_poster per restituire { poster: { id, file_name, titolo }, id, file_name, titolo } (compatibile con entrambi i formati)
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
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
