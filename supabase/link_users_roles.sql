-- ============================================================================
-- PECHINO EXPRESS BRA — LINK AUTH USERS TO GAME TEAMS AND ROLES
-- ============================================================================

-- Clean up any existing mapping
DELETE FROM public.user_roles;

-- 1. Map justdave@pechino.it to 'admin' role
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin' 
FROM auth.users 
WHERE email = 'justdave@pechino.it'
ON CONFLICT (user_id, role) DO NOTHING;

-- 2. Map lorenzom@pechino.it to 'team' role with 'Fost & Loud' team_id
INSERT INTO public.user_roles (user_id, role, team_id)
SELECT u.id, 'team', t.id
FROM auth.users u
CROSS JOIN public.teams t
WHERE u.email = 'lorenzom@pechino.it' AND t.nome_squadra = 'Fost & Loud'
ON CONFLICT (user_id, role) DO NOTHING;

-- 3. Map pietrom@pechino.it to 'team' role with 'Ciccioni Bislunghi' team_id
INSERT INTO public.user_roles (user_id, role, team_id)
SELECT u.id, 'team', t.id
FROM auth.users u
CROSS JOIN public.teams t
WHERE u.email = 'pietrom@pechino.it' AND t.nome_squadra = 'Ciccioni Bislunghi'
ON CONFLICT (user_id, role) DO NOTHING;
