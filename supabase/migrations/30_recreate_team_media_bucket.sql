-- 30_recreate_team_media_bucket.sql
-- Su Production il bucket di storage "team-media" non esiste piu' (0 bucket): senza di esso nessuna squadra puo' caricare foto
-- (Foto ufficiale, Rebus Visivo, Locandina vivente, Missione Social). Su Staging esiste, privato.
-- Le regole di accesso ("Team media: upload to own folder" / "read own folder or admin") sono gia' presenti su entrambi gli ambienti.
-- Ripetibile: se il bucket c'e' gia' lo lascia privato senza toccare i file.
-- Rollback (solo se il bucket e' vuoto): DELETE FROM storage.buckets WHERE id = 'team-media';

INSERT INTO storage.buckets (id, name, public)
VALUES ('team-media', 'team-media', false)
ON CONFLICT (id) DO UPDATE SET public = false;
