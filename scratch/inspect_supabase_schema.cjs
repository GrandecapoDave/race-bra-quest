const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function inspectSupabase() {
  const tables = [
    "stages", "challenges", "teams", "team_progress", "scores", 
    "marketplace_items", "marketplace_transactions", "cattiveria_ledger",
    "jackpot_plays", "submissions", "game_report", "game_settings"
  ];

  for (const t of tables) {
    const { data, error } = await supabase.from(t).select("*").limit(1);
    if (error) {
      console.log(`❌ Table '${t}': ERROR ->`, error.message);
    } else {
      console.log(`✅ Table '${t}': EXISTS (${data.length} sample rows)`);
      if (data.length > 0) {
        console.log(`   Sample keys:`, Object.keys(data[0]));
      }
    }
  }
}

inspectSupabase();
