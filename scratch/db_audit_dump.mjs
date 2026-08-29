import { Client } from "pg";
import * as fs from "fs";

const connectionString = "postgresql://postgres.mbomqxuwmbtxcogbuugr:KawxpDcqz8S!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres";

async function main() {
  const client = new Client({ connectionString });
  await client.connect();

  const report = {};

  // 1. Tables and Columns
  const colsRes = await client.query(`
    SELECT table_name, column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
    ORDER BY table_name, ordinal_position;
  `);
  report.columns = colsRes.rows;

  // 2. Tables list & RLS status
  const rlsRes = await client.query(`
    SELECT tablename, rowsecurity
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY tablename;
  `);
  report.rls_tables = rlsRes.rows;

  // 3. Policies
  const polRes = await client.query(`
    SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
    ORDER BY tablename, policyname;
  `);
  report.policies = polRes.rows;

  // 4. Foreign Keys & Constraints
  const fkRes = await client.query(`
    SELECT
      tc.table_name, kcu.column_name,
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name,
      tc.constraint_type, tc.constraint_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    LEFT JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
    WHERE tc.table_schema = 'public'
    ORDER BY tc.table_name, tc.constraint_name;
  `);
  report.constraints = fkRes.rows;

  // 5. Views
  const viewsRes = await client.query(`
    SELECT table_name, view_definition
    FROM information_schema.views
    WHERE table_schema = 'public'
    ORDER BY table_name;
  `);
  report.views = viewsRes.rows;

  // 6. Functions / RPCs with details
  const rpcRes = await client.query(`
    SELECT 
      p.proname AS name,
      pg_get_function_arguments(p.oid) AS arguments,
      pg_get_function_result(p.oid) AS return_type,
      p.prosecdef AS is_security_definer,
      p.provolatile AS volatility,
      COALESCE(array_to_string(p.proconfig, ', '), '') AS config
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    ORDER BY p.proname;
  `);
  report.rpcs = rpcRes.rows;

  // 7. Triggers
  const trigRes = await client.query(`
    SELECT event_object_table, trigger_name, event_manipulation, action_statement, action_timing
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
    ORDER BY event_object_table, trigger_name;
  `);
  report.triggers = trigRes.rows;

  // 8. Data integrity checks (SELECT only)
  const integrity = {};
  
  // Teams count & sample
  const teams = await client.query(`SELECT id, nome_squadra, colore, color, token_balance, active, username FROM public.teams;`);
  integrity.teams = teams.rows;

  // Stages count
  const stages = await client.query(`SELECT id, numero_tappa, titolo, active, ordine FROM public.stages ORDER BY ordine;`);
  integrity.stages = stages.rows;

  // Challenges count
  const challenges = await client.query(`SELECT id, stage_id, titolo, tipo_sfida, punteggio_massimo, ordine_sfida FROM public.challenges ORDER BY ordine_sfida;`);
  integrity.challenges = challenges.rows;

  // Orphan challenges (stage_id not in stages)
  const orphanChallenges = await client.query(`
    SELECT c.id, c.titolo, c.stage_id 
    FROM public.challenges c 
    LEFT JOIN public.stages s ON c.stage_id = s.id 
    WHERE s.id IS NULL;
  `);
  integrity.orphanChallenges = orphanChallenges.rows;

  // Orphan team_progress
  const orphanProgress = await client.query(`
    SELECT tp.id, tp.team_id, tp.challenge_id 
    FROM public.team_progress tp 
    LEFT JOIN public.teams t ON tp.team_id = t.id 
    LEFT JOIN public.challenges c ON tp.challenge_id = c.id
    WHERE t.id IS NULL OR c.id IS NULL;
  `);
  integrity.orphanProgress = orphanProgress.rows;

  // Orphan scores
  const orphanScores = await client.query(`
    SELECT s.id, s.team_id, s.challenge_id, s.stage_id, s.punti
    FROM public.scores s
    LEFT JOIN public.teams t ON s.team_id = t.id
    LEFT JOIN public.challenges c ON s.challenge_id = c.id
    WHERE t.id IS NULL OR (s.challenge_id IS NOT NULL AND c.id IS NULL);
  `);
  integrity.orphanScores = orphanScores.rows;

  // User roles check
  const userRoles = await client.query(`
    SELECT ur.id, ur.user_id, ur.role
    FROM public.user_roles ur;
  `);
  integrity.userRoles = userRoles.rows;

  // Marketplace items check
  const mpItems = await client.query(`
    SELECT id, nome, categoria, tipo, costo_token, active FROM public.marketplace_items;
  `);
  integrity.marketplaceItems = mpItems.rows;

  // Marketplace transactions check
  const mpTxs = await client.query(`
    SELECT mt.id, mt.team_id, mt.marketplace_item_id, mt.target_team_id, mt.stato, mt.costo_token, mt.data_acquisto
    FROM public.marketplace_transactions mt;
  `);
  integrity.marketplaceTransactions = mpTxs.rows;

  // Game settings check
  const gSettings = await client.query(`
    SELECT * FROM public.game_settings;
  `);
  integrity.gameSettings = gSettings.rows;

  // Storage buckets check
  const buckets = await client.query(`
    SELECT id, name, public, created_at FROM storage.buckets;
  `);
  integrity.storageBuckets = buckets.rows;

  // Storage policies
  const storagePolicies = await client.query(`
    SELECT policyname, permissive, roles, cmd, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'storage';
  `);
  integrity.storagePolicies = storagePolicies.rows;

  report.integrity = integrity;

  fs.writeFileSync("scratch/db_audit_dump.json", JSON.stringify(report, null, 2));
  console.log("DB Audit Dump Complete! Rows:", colsRes.rows.length, "cols,", rpcRes.rows.length, "RPCs.");

  await client.end();
}

main().catch(err => {
  console.error("DB Dump Error:", err);
  process.exit(1);
});
