-- 31_tournament_self_heal.sql
-- Cornhole e Boxe sono tornei fisici: alla FINALE la Regia registra il risultato e il database segna la prova "completata" per tutte le
-- squadre attive in quel momento (+20 al vincitore, +10 partecipazione). Se una squadra NON era attiva/presente in quel momento (creata o
-- riattivata dopo, o con il progresso ripulito) restava con la prova "in corso" per sempre: il torneo risultava chiuso ma la sua prova no,
-- e Boxe/Jackpot (che dipendono da lei) restavano bloccati.
-- Ora, quando una squadra apre la prova e la finale e' gia' stata registrata, la prova si allinea da sola: viene segnata completata e, se
-- non ha ancora punti per quel torneo, riceve i 10 punti di partecipazione (il vincitore ha gia' i suoi 20). Ripetibile.

DO $patch$
DECLARE
  def text;
  newdef text;
  v_anchor text := E'  INSERT INTO public.team_progress (team_id, challenge_id, stato, created_at)\n  VALUES (v_team_id, p_challenge, ''in_progress'', now())\n  ON CONFLICT (team_id, challenge_id) DO NOTHING;';
  v_heal text := $heal$
  -- Tornei fisici (Cornhole / Boxe): se la finale e' gia' stata registrata la prova risulta completata anche per chi non c'era
  IF v_challenge_row.tipo_sfida IN ('cornhole', 'boxe') THEN
    IF (v_challenge_row.tipo_sfida = 'cornhole' AND EXISTS (
          SELECT 1 FROM public.cornhole_matches m
          WHERE m.challenge_id = p_challenge AND m.status = 'completed'
            AND m.round = (SELECT MAX(round) FROM public.cornhole_matches WHERE challenge_id = p_challenge)))
       OR (v_challenge_row.tipo_sfida = 'boxe' AND EXISTS (
          SELECT 1 FROM public.boxe_matches m
          WHERE m.challenge_id = p_challenge AND m.status = 'completed'
            AND m.round = (SELECT MAX(round) FROM public.boxe_matches WHERE challenge_id = p_challenge))) THEN
      INSERT INTO public.team_progress (team_id, challenge_id, stato, completata_il)
      VALUES (v_team_id, p_challenge, 'completed', now())
      ON CONFLICT (team_id, challenge_id) DO UPDATE
        SET stato = 'completed', completata_il = COALESCE(public.team_progress.completata_il, now())
        WHERE public.team_progress.stato <> 'completed';

      IF NOT EXISTS (SELECT 1 FROM public.scores WHERE team_id = v_team_id AND challenge_id = p_challenge) THEN
        INSERT INTO public.scores (team_id, challenge_id, stage_id, punti, tipo_modificatore, motivo)
        VALUES (v_team_id, p_challenge, v_challenge_row.stage_id, 10, 'challenge_points',
                'Partecipazione Torneo ' || CASE WHEN v_challenge_row.tipo_sfida = 'boxe' THEN 'Boxe Gonfiabile' ELSE 'Cornhole' END || ' (Tappa 5)');
      END IF;
      RETURN;
    END IF;
  END IF;

$heal$;
BEGIN
  def := pg_get_functiondef('public.start_challenge(uuid)'::regprocedure);
  IF position('Tornei fisici (Cornhole / Boxe)' IN def) > 0 THEN
    RETURN; -- gia' applicata
  END IF;
  IF position(v_anchor IN def) = 0 THEN
    RAISE EXCEPTION 'start_challenge: punto di inserimento non trovato';
  END IF;
  newdef := replace(def, v_anchor, v_heal || v_anchor);
  IF newdef = def THEN
    RAISE EXCEPTION 'start_challenge: modifica non applicata';
  END IF;
  EXECUTE newdef;
END
$patch$;
