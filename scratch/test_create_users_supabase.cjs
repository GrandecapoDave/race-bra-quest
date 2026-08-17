const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function createUsers() {
  console.log("1. Creating Admin User 'justdave@pechino.it'...");
  const { data: adminSignUp, error: adminErr } = await supabase.auth.signUp({
    email: "justdave@pechino.it",
    password: "Zioporco01",
    options: {
      data: {
        display_name: "Admin Regia"
      }
    }
  });
  console.log("Admin Sign Up result:", adminSignUp?.user?.email, adminErr);

  console.log("\n2. Testing Admin Login with justdave@pechino.it...");
  const { data: adminLogin, error: loginErr } = await supabase.auth.signInWithPassword({
    email: "justdave@pechino.it",
    password: "Zioporco01"
  });
  console.log("Admin Login result:", adminLogin?.user?.email, loginErr);

  console.log("\n3. Creating Team 1 'lorenzom@pechino.it'...");
  const { data: team1SignUp, error: t1Err } = await supabase.auth.signUp({
    email: "lorenzom@pechino.it",
    password: "LorenzoM834",
    options: {
      data: {
        display_name: "Fost & Loud"
      }
    }
  });
  console.log("Team 1 Sign Up result:", team1SignUp?.user?.email, t1Err);

  console.log("\n4. Creating Team 2 'pietrom@pechino.it'...");
  const { data: team2SignUp, error: t2Err } = await supabase.auth.signUp({
    email: "pietrom@pechino.it",
    password: "PietroM610",
    options: {
      data: {
        display_name: "Ciccioni Bislunghi"
      }
    }
  });
  console.log("Team 2 Sign Up result:", team2SignUp?.user?.email, t2Err);
}

createUsers();
