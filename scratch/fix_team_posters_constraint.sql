BEGIN;

-- 1. Aggiungi vincolo unique su team_posters
ALTER TABLE public.team_posters DROP CONSTRAINT IF EXISTS team_posters_team_id_key;
ALTER TABLE public.team_posters ADD CONSTRAINT team_posters_team_id_key UNIQUE (team_id);

-- 2. Abilita RLS su team_posters
ALTER TABLE public.team_posters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Team Read Own Poster" ON public.team_posters;
CREATE POLICY "Team Read Own Poster" ON public.team_posters FOR SELECT USING (
  team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin')
);

-- 3. Aggiorna get_or_assign_poster
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
