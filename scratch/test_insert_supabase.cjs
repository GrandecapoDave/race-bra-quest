const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testInsert() {
  console.log("Testing insert on Supabase...");
  const { data, error } = await supabase.from("teams").insert({
    nome_squadra: "Test Team " + Date.now(),
    colore: "#ff0000"
  }).select();

  console.log("Insert result:", data, error);
}

testInsert();
