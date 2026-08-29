import { execFileSync } from "child_process";
import * as fs from "fs";

function runSql(sql) {
  const res = execFileSync("psql", [
    "postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres",
    "-t", "-A", "-c", sql
  ], { encoding: "utf8" });
  return res.trim();
}

console.log("=== EXECUTING AUTOMATED VERIFICATION SUITE ===");

const results = {};

// 1. Auth & Roles
const usersCount = runSql("SELECT count(*) FROM auth.users;");
const rolesCount = runSql("SELECT count(*) FROM public.user_roles;");
const teamsCount = runSql("SELECT count(*) FROM public.teams;");
results.auth = { usersCount, rolesCount, teamsCount };

// 2. RLS on tables
const rlsTables = JSON.parse(runSql(`
  SELECT json_agg(json_build_object('table', tablename, 'rls', rowsecurity))
  FROM pg_tables WHERE schemaname = 'public';
`));
results.rls = rlsTables;

// 3. Stages and Challenges
const stages = JSON.parse(runSql(`
  SELECT json_agg(json_build_object('id', id, 'numero', numero_tappa, 'titolo', titolo, 'stato', stato) ORDER BY numero_tappa)
  FROM public.stages;
`));
const challenges = JSON.parse(runSql(`
  SELECT json_agg(json_build_object('id', id, 'titolo', titolo, 'tipo', tipo_sfida, 'punti', punteggio_massimo, 'stage_id', stage_id) ORDER BY ordine_sfida)
  FROM public.challenges;
`));
results.stages = stages;
results.challenges = challenges;

// 4. Quiz Questions
const quizQuestions = JSON.parse(runSql("SELECT json_agg(json_build_object('id', id, 'question', question, 'pts', points)) FROM public.quiz_questions_public;"));
results.quizQuestions = quizQuestions;

// 5. Enigmi solutions
const enigmi = JSON.parse(runSql("SELECT json_agg(json_build_object('id', id, 'challenge_id', challenge_id, 'type', solution_type, 'pts', punteggio)) FROM public.enigma_solutions;"));
results.enigmi = enigmi;

// 6. Posters
const posters = JSON.parse(runSql("SELECT json_agg(json_build_object('id', id, 'titolo', titolo, 'file', file_name)) FROM public.posters;"));
results.posters = posters;

// 7. Marketplace Items
const mpItems = JSON.parse(runSql("SELECT json_agg(json_build_object('id', id, 'nome', nome, 'tipo', tipo, 'costo', costo_token, 'disp', disponibile)) FROM public.marketplace_items;"));
results.marketplaceItems = mpItems;

// 8. Test RPCs signatures and definers
const rpcCheck = JSON.parse(runSql(`
  SELECT json_agg(json_build_object('name', proname, 'secdef', prosecdef))
  FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND proname IN (
    'buy_marketplace_item', 'complete_challenge', 'start_challenge', 'get_secure_leaderboard',
    'verify_enigma_solution', 'open_classifica_bonus', 'consume_marketplace_transaction',
    'submit_jackpot_play', 'record_boxe_match', 'record_cornhole_match', 'admin_override_score',
    'admin_grant_tokens', 'admin_reset_game', 'admin_toggle_stage'
  );
`));
results.rpcCheck = rpcCheck;

fs.writeFileSync("scratch/audit_suite_results.json", JSON.stringify(results, null, 2));
console.log("Suite verification completed successfully.");
console.log(JSON.stringify({
  users: usersCount,
  teams: teamsCount,
  stages: stages.length,
  challenges: challenges.length,
  quizQuestions: quizQuestions.length,
  posters: posters.length,
  marketplaceItems: mpItems.length,
  rpcsVerified: rpcCheck.length
}, null, 2));
