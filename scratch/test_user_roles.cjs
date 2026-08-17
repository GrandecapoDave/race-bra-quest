const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function checkUserRoles() {
  console.log("Checking public.user_roles mapping...");
  const { data, error } = await supabase.from("user_roles").select(`
    role,
    user_id,
    team_id,
    teams ( nome_squadra )
  `);

  if (error) {
    console.error("Error fetching user roles:", error);
  } else {
    console.log("User Roles mapped in DB:");
    data.forEach(r => {
      console.log(`- User ID: ${r.user_id} | Role: ${r.role} | Team: ${r.teams?.nome_squadra || 'None (Admin)'}`);
    });
  }
}

checkUserRoles();
