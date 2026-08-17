-- ============================================================================
-- PECHINO EXPRESS BRA — PRE-CONFIRMED AUTH USERS SETUP
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. ADMIN USER: justdave / Zioporco01
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'justdave@pechino.it',
  crypt('Zioporco01', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Admin Regia"}'::jsonb,
  now(),
  now(),
  '',
  ''
) ON CONFLICT (id) DO UPDATE SET 
  encrypted_password = crypt('Zioporco01', gen_salt('bf')),
  email_confirmed_at = now(),
  email = 'justdave@pechino.it';

-- 2. TEAM 1: lorenzom / LorenzoM834 (Fost & Loud)
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '676dfae3-e0c8-4d50-8555-b5a61472522a',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'lorenzom@pechino.it',
  crypt('LorenzoM834', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Fost & Loud"}'::jsonb,
  now(),
  now(),
  '',
  ''
) ON CONFLICT (id) DO UPDATE SET 
  encrypted_password = crypt('LorenzoM834', gen_salt('bf')),
  email_confirmed_at = now(),
  email = 'lorenzom@pechino.it';

-- 3. TEAM 2: pietrom / PietroM610 (Ciccioni Bislunghi)
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token
) VALUES (
  '155e40fe-29ea-47dc-8f23-37f3fa560049',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'pietrom@pechino.it',
  crypt('PietroM610', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Ciccioni Bislunghi"}'::jsonb,
  now(),
  now(),
  '',
  ''
) ON CONFLICT (id) DO UPDATE SET 
  encrypted_password = crypt('PietroM610', gen_salt('bf')),
  email_confirmed_at = now(),
  email = 'pietrom@pechino.it';

-- 4. INSERT USER ROLES
INSERT INTO public.user_roles (id, user_id, role)
VALUES ('11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'admin')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role, team_id)
VALUES ('676dfae3-e0c8-4d50-8555-b5a61472522a', '676dfae3-e0c8-4d50-8555-b5a61472522a', 'team', '676dfae3-e0c8-4d50-8555-b5a61472522a')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role, team_id)
VALUES ('155e40fe-29ea-47dc-8f23-37f3fa560049', '155e40fe-29ea-47dc-8f23-37f3fa560049', 'team', '155e40fe-29ea-47dc-8f23-37f3fa560049')
ON CONFLICT (id) DO NOTHING;
