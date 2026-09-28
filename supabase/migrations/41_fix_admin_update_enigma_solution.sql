-- 41_fix_admin_update_enigma_solution.sql
-- Bug (silenzioso, pericoloso se usato): il modulo "Modifica soluzione" in Regia > Enigmi ha un solo campo di
-- testo libero, ma le soluzioni vere hanno formati diversi: un elenco per le note musicali e le direzioni
-- (es. ["La","Do","Re"]), un oggetto lat/lng per le coordinate. La funzione salvava il testo digitato cosi'
-- com'era (una singola stringa), incompatibile con submit_enigma_answer che si aspetta quell'elenco/oggetto:
-- se mai usata per correggere un enigma, la sfida avrebbe smesso di riconoscere risposte corrette.
-- Ora la funzione guarda il tipo di soluzione gia' configurato per quella sfida e converte da sola il testo
-- digitato nel formato giusto: elenco separato da virgole per note/direzioni, "lat,lng" per le coordinate.

-- La funzione precedente restituiva void: serve DROP prima di ricrearla con un tipo di ritorno diverso (jsonb).
DROP FUNCTION IF EXISTS public.admin_update_enigma_solution(uuid, jsonb, uuid);

CREATE FUNCTION public.admin_update_enigma_solution(p_challenge_id uuid, p_solution jsonb, p_admin_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_is_admin BOOLEAN;
  v_existing_type text;
  v_final_solution jsonb;
  v_raw text;
BEGIN
  SELECT public.has_role(auth.uid(), 'admin') INTO v_is_admin;
  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Non autorizzato';
  END IF;

  SELECT solution_type INTO v_existing_type FROM public.enigma_solutions WHERE challenge_id = p_challenge_id;

  IF jsonb_typeof(p_solution) IN ('array', 'object') THEN
    -- gia' nel formato strutturato corretto: lo usiamo cosi' com'e'
    v_final_solution := p_solution;
  ELSIF jsonb_typeof(p_solution) = 'string' THEN
    v_raw := p_solution #>> '{}';
    IF v_existing_type = 'coordinates' THEN
      IF position(',' IN v_raw) = 0 THEN
        RAISE EXCEPTION 'Formato coordinate non valido: usa "latitudine,longitudine" (es. 44.71,7.84)';
      END IF;
      v_final_solution := jsonb_build_object(
        'lat', trim(split_part(v_raw, ',', 1)),
        'lng', trim(split_part(v_raw, ',', 2))
      );
    ELSE
      -- note / direzioni (o tipo non ancora configurato): elenco separato da virgole -> array di stringhe
      SELECT jsonb_agg(trim(x)) INTO v_final_solution
      FROM unnest(string_to_array(v_raw, ',')) AS x
      WHERE trim(x) <> '';
    END IF;
  ELSE
    v_final_solution := p_solution;
  END IF;

  INSERT INTO public.enigma_solutions (challenge_id, solution, solution_type)
  VALUES (p_challenge_id, v_final_solution, COALESCE(v_existing_type, 'text'))
  ON CONFLICT (challenge_id) DO UPDATE
    SET solution = EXCLUDED.solution;

  RETURN jsonb_build_object('success', true, 'solution', v_final_solution, 'solution_type', COALESCE(v_existing_type, 'text'));
END;
$function$;
REVOKE ALL ON FUNCTION public.admin_update_enigma_solution(uuid, jsonb, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_update_enigma_solution(uuid, jsonb, uuid) TO authenticated;
