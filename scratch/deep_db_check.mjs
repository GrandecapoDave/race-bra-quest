import { execSync } from "child_process";
import * as fs from "fs";

function runSql(sql) {
  const cmd = `psql 'postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres' -t -A -c "${sql.replace(/"/g, '\\"')}"`;
  return execSync(cmd, { encoding: "utf8" }).trim();
}

console.log("=== CHECKING ALL TABLES & ROW COUNTS ===");
const tableCounts = runSql(`
  SELECT json_object_agg(table_name, count)
  FROM (
    SELECT table_name, (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text::int as count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
  ) t;
`);
console.log(tableCounts);

console.log("\n=== CHECKING ALL RPC DEFINITIONS & SIGNATURES ===");
const rpcList = runSql(`
  SELECT json_agg(json_build_object(
    'name', p.proname,
    'args', pg_get_function_arguments(p.oid),
    'return', pg_get_function_result(p.oid),
    'secdef', p.prosecdef
  ))
  FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public';
`);
fs.writeFileSync("scratch/real_rpc_list.json", rpcList);

console.log("\n=== CHECKING RLS POLICIES FOR ALL TABLES ===");
const rlsPolicies = runSql(`
  SELECT json_agg(json_build_object(
    'table', tablename,
    'policy', policyname,
    'cmd', cmd,
    'roles', roles,
    'qual', qual,
    'with_check', with_check
  ))
  FROM pg_policies WHERE schemaname = 'public';
`);
fs.writeFileSync("scratch/real_policies.json", rlsPolicies);

console.log("\n=== CHECKING AUTH & USER_ROLES INTEGRITY ===");
const authIntegrity = runSql(`
  SELECT json_build_object(
    'total_auth_users', (SELECT count(*) FROM auth.users),
    'auth_users_sample', (SELECT json_agg(json_build_object('id', id, 'email', email, 'created_at', created_at)) FROM (SELECT id, email, created_at FROM auth.users LIMIT 20) u),
    'total_teams', (SELECT count(*) FROM public.teams),
    'teams_sample', (SELECT json_agg(json_build_object('id', id, 'nome_squadra', nome_squadra, 'token_balance', token_balance, 'active', active)) FROM public.teams),
    'total_user_roles', (SELECT count(*) FROM public.user_roles),
    'user_roles_sample', (SELECT json_agg(json_build_object('id', id, 'user_id', user_id, 'role', role)) FROM public.user_roles)
  );
`);
fs.writeFileSync("scratch/auth_integrity.json", authIntegrity);

console.log("\n=== CHECKING ORPHAN RECORDS ===");
const orphanCheck = runSql(`
  SELECT json_build_object(
    'orphan_progress_team', (SELECT count(*) FROM public.team_progress tp LEFT JOIN public.teams t ON tp.team_id = t.id WHERE t.id IS NULL),
    'orphan_progress_challenge', (SELECT count(*) FROM public.team_progress tp LEFT JOIN public.challenges c ON tp.challenge_id = c.id WHERE c.id IS NULL),
    'orphan_scores_team', (SELECT count(*) FROM public.scores s LEFT JOIN public.teams t ON s.team_id = t.id WHERE t.id IS NULL),
    'orphan_submissions_team', (SELECT count(*) FROM public.submissions s LEFT JOIN public.teams t ON s.team_id = t.id WHERE t.id IS NULL),
    'orphan_user_roles_auth', (SELECT count(*) FROM public.user_roles ur LEFT JOIN auth.users u ON ur.user_id = u.id WHERE u.id IS NULL)
  );
`);
console.log("Orphan Check:", orphanCheck);
fs.writeFileSync("scratch/orphan_check.json", orphanCheck);
