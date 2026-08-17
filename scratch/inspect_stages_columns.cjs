const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function inspectColumns() {
  const { error: insErr } = await supabase.from("stages").insert({
    titolo: "Test Stage",
    descrizione: "Test Desc",
    numero_tappa: 99
  });
  console.log("Insert stages error:", insErr);
}

inspectColumns();
