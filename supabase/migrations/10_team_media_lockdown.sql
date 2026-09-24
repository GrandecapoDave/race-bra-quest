-- 10_team_media_lockdown.sql
-- Foto delle squadre: bucket privato. Ogni squadra carica e legge solo nella propria cartella ({team_id}/...), la Regia (admin) legge tutto.
-- Nessuna policy di UPDATE/DELETE: i file caricati non sono modificabili (il client usa upsert:false).
-- Rollback: UPDATE storage.buckets SET public = true WHERE id = 'team-media';
--           DROP POLICY "Team media: read own folder or admin" ON storage.objects; DROP POLICY "Team media: upload to own folder" ON storage.objects;
--           CREATE POLICY "Public Read Team Media" ON storage.objects FOR SELECT TO public USING (bucket_id = 'team-media');
--           CREATE POLICY "Authenticated/Anon Insert Team Media" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'team-media');

UPDATE storage.buckets SET public = false WHERE id = 'team-media';

DROP POLICY IF EXISTS "Public Read Team Media" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated/Anon Insert Team Media" ON storage.objects;
DROP POLICY IF EXISTS "Team media: read own folder or admin" ON storage.objects;
DROP POLICY IF EXISTS "Team media: upload to own folder" ON storage.objects;

CREATE POLICY "Team media: read own folder or admin" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'team-media'
    AND (
      public.has_role(auth.uid(), 'admin')
      OR (storage.foldername(name))[1] = public.current_team_id()::text
    )
  );

CREATE POLICY "Team media: upload to own folder" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'team-media'
    AND (
      public.has_role(auth.uid(), 'admin')
      OR (storage.foldername(name))[1] = public.current_team_id()::text
    )
  );
