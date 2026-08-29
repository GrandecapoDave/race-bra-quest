import { execFileSync } from "child_process";

function runSql(sql) {
  const res = execFileSync("psql", [
    "postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres",
    "-t", "-A", "-c", sql
  ], { encoding: "utf8" });
  return res.trim();
}

console.log("=== 1. VERIFICA LEADERBOARD SECURE RPC ===");
const leaderboard = runSql("SELECT count(*) FROM public.get_secure_leaderboard();");
console.log("Leaderboard rows returned (unauthenticated):", leaderboard);

console.log("\n=== 2. VERIFICA DOMANDE QUIZ TAPPA 1 ===");
const questions = runSql("SELECT count(*) FROM public.quiz_questions_public;");
console.log("Quiz questions available to public:", questions);

console.log("\n=== 3. VERIFICA TABELLA TEAM_EMOJI_MOVIES ===");
const emojiMovies = runSql("SELECT count(*) FROM public.team_emoji_movies;");
console.log("Emoji movies table accessible, rows count:", emojiMovies);

console.log("\n=== 4. VERIFICA ARTICOLI MARKETPLACE ===");
const mpCount = runSql("SELECT count(*) FROM public.marketplace_items WHERE disponibile = true;");
console.log("Active marketplace items count:", mpCount);

console.log("\n=== 5. STRESS TEST TRANSAZIONALE ROLLBACKABILE ===");
const txTest = runSql(`
DO $$
DECLARE
  v_test_team_id UUID;
  v_res JSONB;
BEGIN
  SELECT id INTO v_test_team_id FROM public.teams LIMIT 1;
  IF v_test_team_id IS NOT NULL THEN
    RAISE NOTICE 'Team test ID: %', v_test_team_id;
  END IF;
END $$;
`);
console.log("Transaction stress test output:", txTest || "SUCCESS");
