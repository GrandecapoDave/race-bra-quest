const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testLiveActiveProject() {
  console.log("=== Testing Real Active Supabase Project (aehjyuarqvwovqfodlss) ===");
  
  // 1. Teams
  const { data: teams, error: tErr } = await supabase.from("teams").select("*");
  console.log("Teams:", teams ? `${teams.length} found` : "ERROR", tErr ? tErr.message : "OK");
  if (teams && teams.length > 0) {
    teams.forEach(t => console.log(`   - ${t.nome_squadra} (Token: ${t.token_balance})`));
  }

  // 2. Stages
  const { data: stages, error: sErr } = await supabase.from("stages").select("*").order("numero_tappa");
  console.log("Stages:", stages ? `${stages.length} found` : "ERROR", sErr ? sErr.message : "OK");
  if (stages && stages.length > 0) {
    stages.forEach(s => console.log(`   - Tappa ${s.numero_tappa}: ${s.titolo}`));
  }

  // 3. Challenges
  const { data: challenges, error: cErr } = await supabase.from("challenges").select("id, titolo, tipo_sfida, punteggio_massimo");
  console.log("Challenges:", challenges ? `${challenges.length} found` : "ERROR", cErr ? cErr.message : "OK");

  // 4. Marketplace Items
  const { data: items, error: iErr } = await supabase.from("marketplace_items").select("*");
  console.log("Marketplace Items:", items ? `${items.length} found` : "ERROR", iErr ? iErr.message : "OK");

  // 5. Atomic RPC test: has_role
  const { data: isAdmin, error: rpcErr } = await supabase.rpc("has_role", {
    _user_id: "11111111-1111-1111-1111-111111111111",
    _role: "admin"
  });
  console.log("RPC has_role (admin):", isAdmin, rpcErr ? rpcErr.message : "OK");
}

testLiveActiveProject();
