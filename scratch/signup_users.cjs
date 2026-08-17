const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function signUpAll() {
  console.log("Signing up users via standard API...");

  const r1 = await supabase.auth.signUp({
    email: "justdave@pechino.it",
    password: "Zioporco01"
  });
  console.log("- justdave@pechino.it:", r1.error ? r1.error.message : "CREATED ✅");

  // Wait a bit to prevent rate limiting
  await new Promise(r => setTimeout(r, 1000));

  const r2 = await supabase.auth.signUp({
    email: "lorenzom@pechino.it",
    password: "LorenzoM834"
  });
  console.log("- lorenzom@pechino.it:", r2.error ? r2.error.message : "CREATED ✅");

  await new Promise(r => setTimeout(r, 1000));

  const r3 = await supabase.auth.signUp({
    email: "pietrom@pechino.it",
    password: "PietroM610"
  });
  console.log("- pietrom@pechino.it:", r3.error ? r3.error.message : "CREATED ✅");
}

signUpAll();
