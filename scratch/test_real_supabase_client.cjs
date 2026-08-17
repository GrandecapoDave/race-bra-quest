const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testFullFlow() {
  console.log("1. Testing Auth & Role Verification...");
  const { data: isAdmin } = await supabase.rpc("has_role", {
    _user_id: "11111111-1111-1111-1111-111111111111",
    _role: "admin"
  });
  console.log("has_role admin result:", isAdmin);

  console.log("2. Testing Teams Query...");
  const { data: teams, error: tErr } = await supabase.from("teams").select("*");
  console.log("Teams count:", teams ? teams.length : 0, tErr ? tErr.message : "OK");

  console.log("3. Testing Storage Bucket 'team-media'...");
  const { data: files, error: fErr } = await supabase.storage.from("team-media").list();
  console.log("Files in team-media:", files ? files.length : 0, fErr ? fErr.message : "OK");
}

testFullFlow();
