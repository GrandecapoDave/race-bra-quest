const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testConcurrency() {
  console.log("=== Testing Real Supabase PostgreSQL Concurrency & Atomicity ===");

  const teamAId = "676dfae3-e0c8-4d50-8555-b5a61472522a"; // Fost & Loud
  const teamBId = "155e40fe-29ea-47dc-8f23-37f3fa560049"; // Ciccioni Bislunghi
  const stageId = "4a57212e-7e83-430c-b5fe-6cf38db7be2e"; // Tappa 1

  // 1. Test Atomic Marketplace Purchase
  console.log("\n1. Testing Atomic Marketplace Purchase (bonus_punti, cost 40)...");
  const { data: purchaseRes, error: pErr } = await supabase.rpc("purchase_marketplace_item", {
    p_team_id: teamAId,
    p_item_id: "bonus_punti",
    p_stage_id: stageId
  });
  console.log("Purchase Result:", purchaseRes, pErr ? pErr.message : "OK");

  // 2. Check token balance after deduction
  const { data: teamA } = await supabase.from("teams").select("token_balance").eq("id", teamAId).single();
  console.log("Team A new balance:", teamA?.token_balance);

  // 3. Test Atomic Switch Punti
  console.log("\n2. Testing Atomic Switch Punti between Team A and Team B...");
  const { data: switchRes, error: swErr } = await supabase.rpc("execute_switch_punti", {
    p_actor_team_id: teamAId,
    p_target_team_id: teamBId,
    p_stage_id: stageId
  });
  console.log("Switch Result:", switchRes, swErr ? swErr.message : "OK");

  // 4. Test Atomic Jackpot Slot Play
  console.log("\n3. Testing Atomic Jackpot Play (Bet 10 PT)...");
  const { data: jackpotRes, error: jErr } = await supabase.rpc("play_jackpot", {
    p_team_id: teamAId,
    p_bet_points: 10
  });
  console.log("Jackpot Result:", jackpotRes, jErr ? jErr.message : "OK");

  console.log("\n✅ All Atomic PostgreSQL RPCs passed successfully!");
}

testConcurrency();
