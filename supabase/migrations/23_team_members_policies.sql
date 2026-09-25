-- 23_team_members_policies.sql
-- team_members aveva RLS attiva ma NESSUNA regola: lettura e scrittura sempre negate. I partecipanti della squadra
-- venivano salvati solo nel telefono (localStorage): su un altro dispositivo risultavano 0/2 e la Regia non li vedeva.
-- Ora ogni squadra legge/aggiunge/rimuove i propri partecipanti; la Regia legge tutto.

DROP POLICY IF EXISTS "Own Or Admin Read Team Members" ON public.team_members;
CREATE POLICY "Own Or Admin Read Team Members" ON public.team_members
  FOR SELECT TO authenticated
  USING (team_id = public.current_team_id() OR public.has_role(auth.uid(), 'admin'::text));

DROP POLICY IF EXISTS "Own Insert Team Members" ON public.team_members;
CREATE POLICY "Own Insert Team Members" ON public.team_members
  FOR INSERT TO authenticated
  WITH CHECK (team_id = public.current_team_id());

DROP POLICY IF EXISTS "Own Delete Team Members" ON public.team_members;
CREATE POLICY "Own Delete Team Members" ON public.team_members
  FOR DELETE TO authenticated
  USING (team_id = public.current_team_id());
