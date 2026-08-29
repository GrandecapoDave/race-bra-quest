BEGIN;

-- 1. Abilita SELECT su posters per tutti (pubblico e admin)
ALTER TABLE public.posters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Posters" ON public.posters;
DROP POLICY IF EXISTS "Team Read Posters" ON public.posters;
CREATE POLICY "Public Read Posters" ON public.posters FOR SELECT USING (true);

-- 2. Abilita SELECT su team_posters per tutti (pubblico e admin)
ALTER TABLE public.team_posters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Team Posters" ON public.team_posters;
DROP POLICY IF EXISTS "Team Read Own Poster" ON public.team_posters;
CREATE POLICY "Public Read Team Posters" ON public.team_posters FOR SELECT USING (true);

-- 3. Crea RPC admin per recuperare le locandine e assegnazioni con join sicuro
CREATE OR REPLACE FUNCTION public.admin_get_posters_overview()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

NOTIFY pgrst, 'reload schema';

COMMIT;
