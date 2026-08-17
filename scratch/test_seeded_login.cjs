const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testSeededLogin() {
  console.log("=== Testing Seeded Logins ===");

  const { data: adminData, error: adminErr } = await supabase.auth.signInWithPassword({
    email: "justdave@pechino.it",
    password: "Zioporco01"
  });
  console.log("1. Admin Login (justdave@pechino.it):", adminData?.user ? "SUCCESS ✅" : "FAILED ❌", adminErr?.message || "OK");

  const { data: team1Data, error: team1Err } = await supabase.auth.signInWithPassword({
    email: "lorenzom@pechino.it",
    password: "LorenzoM834"
  });
  console.log("2. Team 1 Login (lorenzom@pechino.it):", team1Data?.user ? "SUCCESS ✅" : "FAILED ❌", team1Err?.message || "OK");

  const { data: team2Data, error: team2Err } = await supabase.auth.signInWithPassword({
    email: "pietrom@pechino.it",
    password: "PietroM610"
  });
  console.log("3. Team 2 Login (pietrom@pechino.it):", team2Data?.user ? "SUCCESS ✅" : "FAILED ❌", team2Err?.message || "OK");
}

testSeededLogin();
