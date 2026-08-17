const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testAll() {
  console.log("Checking tables...");
  const tables = ["teams", "stages", "challenges", "marketplace_items", "marketplace_transactions", "cattiveria_ledger", "jackpot_plays", "submissions"];
  for (const t of tables) {
    const { data, error } = await supabase.from(t).select("*");
    if (error) {
      console.log(`❌ ${t}:`, error.message);
    } else {
      console.log(`✅ ${t}: ${data.length} rows`);
    }
  }
}

testAll();
