BEGIN;

CREATE TABLE IF NOT EXISTS public.team_emoji_movies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  movie_index INTEGER NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 1,
  last_answer TEXT,
  is_correct BOOLEAN NOT NULL DEFAULT false,
  points INTEGER NOT NULL DEFAULT 0,
  letter CHAR(1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT team_emoji_movies_team_movie_key UNIQUE (team_id, movie_index)
);

ALTER TABLE public.team_emoji_movies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Team Read Own Emoji Movies" ON public.team_emoji_movies;
CREATE POLICY "Team Read Own Emoji Movies" ON public.team_emoji_movies FOR SELECT USING (
  team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin')
);

DROP POLICY IF EXISTS "Team Insert Own Emoji Movies" ON public.team_emoji_movies;
CREATE POLICY "Team Insert Own Emoji Movies" ON public.team_emoji_movies FOR INSERT WITH CHECK (
  team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin')
);

DROP POLICY IF EXISTS "Team Update Own Emoji Movies" ON public.team_emoji_movies;
CREATE POLICY "Team Update Own Emoji Movies" ON public.team_emoji_movies FOR UPDATE USING (
  team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin')
);

NOTIFY pgrst, 'reload schema';

COMMIT;
