-- Migration 04: Authentication Architecture (Username-based)

-- 1. Aggiungiamo il concetto nativo di username su user_roles e rinforziamo la tabella
ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS username TEXT;

-- Drop vecchi constraint se presenti e aggiungiamo i nuovi
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_key;
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_username_key;

-- Pulizia di eventuali duplicati sporchi in user_roles per sicurezza
DELETE FROM public.user_roles a USING public.user_roles b WHERE a.id < b.id AND a.user_id = b.user_id;
DELETE FROM public.user_roles WHERE role = 'admin' AND user_id != '11111111-1111-1111-1111-111111111111';

ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_user_id_key UNIQUE (user_id);
-- Invece di un CONSTRAINT case-sensitive, usiamo un indice UNIQUE su LOWER(username)
DROP INDEX IF EXISTS user_roles_username_lower_idx;
CREATE UNIQUE INDEX user_roles_username_lower_idx ON public.user_roles (LOWER(username));

-- 2. Migriamo i dati esistenti
-- A. Team (recuperiamo dalla tabella teams)
UPDATE public.user_roles ur
SET username = LOWER(TRIM(t.username))
FROM public.teams t
WHERE ur.team_id = t.id AND t.username IS NOT NULL;

-- C. Se ci fossero team creati con seed_auth_users che non hanno il campo username popolato in teams:
-- Recuperiamo la parte prima della @ dalla vecchia email in auth.users
UPDATE public.user_roles ur
SET username = LOWER(SPLIT_PART(u.email, '@', 1))
FROM auth.users u
WHERE ur.user_id = u.id AND ur.username IS NULL AND u.email LIKE '%@pechino.it%';

-- B. Admin (justdave - ricavato dallo storico, come fallback di sicurezza per i seed)
UPDATE public.user_roles
SET username = 'justdave'
WHERE role = 'admin' AND user_id = '11111111-1111-1111-1111-111111111111' AND username IS NULL;

-- D. Assicuriamo che teams.username sia allineato per i seed vecchi
UPDATE public.teams t
SET username = ur.username
FROM public.user_roles ur
WHERE t.id = ur.team_id AND t.username IS NULL;

-- 3. Rendiamo anonime/tecniche le email nel sistema Supabase Auth
UPDATE auth.users
SET email = id || '@auth.local'
WHERE email LIKE '%@pechino.it%';

-- 4. Creiamo la RPC per esporre la mappatura e il ruolo al frontend
CREATE OR REPLACE FUNCTION public.get_auth_context_by_username(p_username TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_email TEXT;
  v_role TEXT;
BEGIN
  SELECT u.email, ur.role INTO v_email, v_role
  FROM auth.users u
  JOIN public.user_roles ur ON u.id = ur.user_id
  WHERE LOWER(ur.username) = LOWER(TRIM(p_username));
  
  IF v_email IS NOT NULL THEN
    RETURN jsonb_build_object('email', v_email, 'role', v_role);
  END IF;
  
  RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_auth_context_by_username(TEXT) TO anon, authenticated;

-- Rimuoviamo la vecchia RPC se presente da precedenti prove
DROP FUNCTION IF EXISTS public.get_auth_email_by_username(TEXT);

-- 5. Aggiorniamo i Trigger per i nuovi team che verranno creati o modificati
CREATE OR REPLACE FUNCTION public.sync_team_to_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_email TEXT;
  v_encrypted_pass TEXT;
BEGIN
  IF NEW.username IS NULL OR NEW.password_plain IS NULL THEN
    RETURN NEW;
  END IF;

  v_encrypted_pass := extensions.crypt(NEW.password_plain, extensions.gen_salt('bf', 10));

  IF OLD.owner_id IS NOT NULL THEN
    v_user_id := OLD.owner_id;
    UPDATE auth.users 
    SET encrypted_password = v_encrypted_pass, updated_at = now()
    WHERE id = v_user_id;
  ELSE
    v_user_id := gen_random_uuid();
    v_email := v_user_id || '@auth.local';

    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
      v_email, v_encrypted_pass, now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
      now(), now(), '', '', '', ''
    );
  END IF;

  NEW.owner_id := v_user_id;
  
  -- Sicurezza: non salviamo la password in chiaro nel database
  NEW.password_plain := NULL;
  
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.after_sync_team_to_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.owner_id IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role, team_id, username)
    VALUES (NEW.owner_id, 'team', NEW.id, LOWER(TRIM(NEW.username)))
    ON CONFLICT (user_id) DO UPDATE 
    SET username = EXCLUDED.username, team_id = EXCLUDED.team_id;
  END IF;
  RETURN NEW;
END;
$$;
