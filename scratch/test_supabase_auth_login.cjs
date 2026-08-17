const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testAuthLogin() {
  console.log("Testing Supabase Auth signInWithPassword...");
  const { data, error } = await supabase.auth.signInWithPassword({
    email: "justdave@admin.pechino.local",
    password: "Zioporco01"
  });

  console.log("Login result:", data, error);
}

testAuthLogin();
