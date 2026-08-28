-- Function for admin to safely adjust team score bypassing RLS
CREATE OR REPLACE FUNCTION public.admin_adjust_team_score(
  p_team_id UUID,
  p_punti INTEGER,
  p_motivo TEXT,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_score_id UUID;
BEGIN
  INSERT INTO public.scores (
    team_id,
    punti,
    motivo,
    tipo_modificatore,
    created_at
  ) VALUES (
    p_team_id,
    p_punti,
    COALESCE(p_motivo, 'Regolazione manuale Regia'),
    'admin_adjustment',
    NOW()
  )
  RETURNING id INTO v_score_id;

  RETURN jsonb_build_object('success', true, 'score_id', v_score_id);
END;
$$;

-- Function for admin to delete manual score adjustment
CREATE OR REPLACE FUNCTION public.admin_delete_team_score(
  p_score_id UUID,
  p_admin_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.scores WHERE id = p_score_id;
  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_adjust_team_score TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.admin_delete_team_score TO authenticated, anon, service_role;
