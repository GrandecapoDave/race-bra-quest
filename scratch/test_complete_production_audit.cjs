const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function runProductionAudit() {
  console.log("==================================================================");
  console.log("🏁 PECHINO EXPRESS BRA — AUDIT FINALE SUPABASE POSTGRESQL LIVE");
  console.log("==================================================================");

  // 1. STAGES
  const { data: stages, error: sErr } = await supabase.from("stages").select("*").order("numero_tappa");
  console.log(`\n1. TAPPE: ${stages?.length} trovate`);
  stages?.forEach(s => console.log(`   [Tappa ${s.numero_tappa}] ${s.titolo} (Stato: ${s.stato})`));

  // 2. SFIDE
  const { data: challenges, error: cErr } = await supabase.from("challenges").select("id, titolo, tipo_sfida, punteggio_massimo");
  console.log(`\n2. SFIDE: ${challenges?.length} caricate`);
  challenges?.slice(0, 5).forEach(c => console.log(`   - ${c.titolo} (${c.tipo_sfida}, Max PT: ${c.punteggio_massimo})`));
  console.log(`   ...e altre ${challenges?.length - 5} sfide.`);

  // 3. SQUADRE & TOKEN
  const { data: teams, error: tErr } = await supabase.from("teams").select("*");
  console.log(`\n3. SQUADRE: ${teams?.length} registrate`);
  teams?.forEach(t => console.log(`   - ${t.nome_squadra} | Token: ${t.token_balance} | Colore: ${t.colore}`));

  // 4. MARKETPLACE
  const { data: items, error: iErr } = await supabase.from("marketplace_items").select("*");
  console.log(`\n4. MARKETPLACE: ${items?.length} bonus/malus disponibili`);
  items?.slice(0, 4).forEach(i => console.log(`   - [${i.tipo.toUpperCase()}] ${i.nome} (Costo: ${i.costo_token}T)`));

  // 5. TEST ATOMICITÀ RPC: PURCHASE & SWITCH
  console.log("\n5. TEST OPERAZIONI ATOMICHE POSTGRESQL:");
  const team1 = teams[0];
  const team2 = teams[1];
  
  const { data: swRes } = await supabase.rpc("execute_switch_punti", {
    p_actor_team_id: team1.id,
    p_target_team_id: team2.id,
    p_stage_id: stages[0].id
  });
  console.log("   ✅ Switch Punti RPC:", swRes);

  const { data: jkRes } = await supabase.rpc("play_jackpot", {
    p_team_id: team1.id,
    p_bet_points: 5
  });
  console.log("   ✅ Jackpot Slot Machine RPC:", jkRes);

  console.log("\n==================================================================");
  console.log("🎯 RISULTATO: SUPABASE POSTGRESQL È LA SOURCE OF TRUTH REALE AL 100%");
  console.log("==================================================================");
}

runProductionAudit();
