-- ============================================================================
-- PECHINO EXPRESS BRA — ADD USER ROLES POLICIES & RE-LINK
-- ============================================================================

-- 1. Enable RLS policies for user_roles
DROP POLICY IF EXISTS "Public Read All Roles" ON public.user_roles;
CREATE POLICY "Public Read All Roles" ON public.user_roles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Write All Roles" ON public.user_roles;
CREATE POLICY "Public Write All Roles" ON public.user_roles FOR ALL USING (true);

-- 2. Clean and re-link just in case
DELETE FROM public.user_roles;

INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin' 
FROM auth.users 
WHERE email = 'justdave@pechino.it'
ON CONFLICT DO NOTHING;

INSERT INTO public.user_roles (user_id, role, team_id)
SELECT u.id, 'team', t.id
FROM auth.users u
CROSS JOIN public.teams t
WHERE u.email = 'lorenzom@pechino.it' AND t.nome_squadra = 'Fost & Loud'
ON CONFLICT DO NOTHING;

INSERT INTO public.user_roles (user_id, role, team_id)
SELECT u.id, 'team', t.id
FROM auth.users u
CROSS JOIN public.teams t
WHERE u.email = 'pietrom@pechino.it' AND t.nome_squadra = 'Ciccioni Bislunghi'
ON CONFLICT DO NOTHING;
