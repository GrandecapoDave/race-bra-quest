-- 43_fix_social_completata_il_drift.sql
-- Rilettura del flusso di gioco squadre: submit_social_challenge aggiornava completata_il a "adesso" ad OGNI
-- invio, anche su un reinvio (es. la squadra corregge una foto sbagliata prima che la Regia valuti). Il sito
-- blocca gia' il reinvio dall'interfaccia una volta inviato, ma il database da solo non lo impediva: chiamando
-- la funzione una seconda volta, l'orario "ufficiale" di completamento della prova si sarebbe spostato in
-- avanti, alterando ingiustamente il bonus tempo finale (che usa l'ultimo completamento tra le 14 prove
-- obbligatorie). Nessun altro effetto duplicato: apply_completion_effects e' gia' protetta da controlli propri.
-- Ora completata_il resta quello del primo completamento reale; cambiano solo le foto/il testo della richiesta.

CREATE OR REPLACE FUNCTION public.submit_social_challenge(p_image_1_path text, p_image_2_path text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_team_id UUID;
  v_challenge_id UUID := 'c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7';
BEGIN
  PERFORM public.assert_team_not_blocked();
  PERFORM public.assert_race_not_paused();
  PERFORM public.assert_gate_open('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7'::uuid);
  PERFORM public.assert_challenge_unlocked('c2c3c4c5-c6c7-c8c9-d0d1-d2d3d4d5d6d7'::uuid);
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

  -- Segna progresso in completed; su un eventuale reinvio l'orario resta quello del primo completamento
  INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
  VALUES (v_team_id, v_challenge_id, 'completed', now())
  ON CONFLICT (team_id, challenge_id) DO UPDATE
  SET stato = 'completed', completata_il = COALESCE(public.team_progress.completata_il, now());

  PERFORM public.apply_completion_effects(v_team_id, v_challenge_id);

  RETURN jsonb_build_object('success', true);
END;
$function$;
