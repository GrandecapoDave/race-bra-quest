-- Migration 03: Poster assignment hardening

-- 1. Pulizia eventuali duplicati di team_id in team_posters (sicurezza/idempotenza)
DELETE FROM public.team_posters a
USING public.team_posters b
WHERE a.id < b.id 
  AND a.team_id = b.team_id;

-- 2. Aggiunta vincolo UNIQUE su team_id per prevenire doppie assegnazioni e race condition
ALTER TABLE public.team_posters DROP CONSTRAINT IF EXISTS team_posters_team_id_key;
ALTER TABLE public.team_posters ADD CONSTRAINT team_posters_team_id_key UNIQUE (team_id);

-- 3. Aggiornamento RPC con logica deterministica e gestione concorrenza
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

  -- 1. Controlla se ha già un poster assegnato
  SELECT * INTO v_assigned FROM public.team_posters WHERE team_id = p_team_id LIMIT 1;
  IF FOUND THEN
    SELECT * INTO v_poster FROM public.posters WHERE id = v_assigned.poster_id;
    RETURN jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo);
  END IF;

  -- 2. Altrimenti seleziona il poster con meno assegnazioni. 
  --    In caso di parità, scegli quello con ID minore (deterministico).
  SELECT p.* INTO v_poster
  FROM public.posters p
  LEFT JOIN public.team_posters tp ON tp.poster_id = p.id
  WHERE p.active = true
  GROUP BY p.id, p.file_name, p.titolo
  ORDER BY COUNT(tp.id) ASC, p.id ASC
  LIMIT 1;

  IF FOUND THEN
    -- Inserimento sicuro con ON CONFLICT per prevenire race conditions
    INSERT INTO public.team_posters (team_id, poster_id) 
    VALUES (p_team_id, v_poster.id)
    ON CONFLICT (team_id) DO NOTHING;
    
    -- Rileggiamo in caso un'altra transazione abbia inserito nel frattempo (race condition vinta dall'altra transazione)
    SELECT p.* INTO v_poster 
    FROM public.posters p 
    JOIN public.team_posters tp ON tp.poster_id = p.id 
    WHERE tp.team_id = p_team_id;

    RETURN jsonb_build_object('id', v_poster.id, 'file_name', v_poster.file_name, 'titolo', v_poster.titolo);
  END IF;

  RETURN NULL;
END;
$$;
