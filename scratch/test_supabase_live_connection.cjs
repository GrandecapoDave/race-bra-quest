const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testConnection() {
  console.log("Testing Supabase Cloud Connection...");
  
  // 1. Fetch Stages
  const { data: stages, error: stagesErr } = await supabase.from("stages").select("*").order("numero_tappa");
  if (stagesErr) {
    console.error("Stages error:", stagesErr);
  } else {
    console.log(`✅ Stages fetched successfully (${stages?.length} stages found):`);
    stages?.forEach(s => console.log(`   - Tappa ${s.numero_tappa}: ${s.titolo}`));
  }

  // 2. Fetch Challenges
  const { data: challenges, error: chalErr } = await supabase.from("challenges").select("id, titolo, tipo_sfida, punteggio_massimo");
  if (chalErr) {
    console.error("Challenges error:", chalErr);
  } else {
    console.log(`✅ Challenges fetched successfully (${challenges?.length} challenges found)`);
  }

  // 3. Fetch Teams
  const { data: teams, error: teamsErr } = await supabase.from("teams").select("*");
  if (teamsErr) {
    console.error("Teams error:", teamsErr);
  } else {
    console.log(`✅ Teams fetched successfully (${teams?.length} teams found):`);
    teams?.forEach(t => console.log(`   - ${t.nome_squadra} (Token: ${t.token_balance})`));
  }

  // 4. Fetch Marketplace Items
  const { data: items, error: itemsErr } = await supabase.from("marketplace_items").select("*");
  if (itemsErr) {
    console.error("Marketplace items error:", itemsErr);
  } else {
    console.log(`✅ Marketplace items fetched successfully (${items?.length} items found)`);
  }
}

testConnection();
