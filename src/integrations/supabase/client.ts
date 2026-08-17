import { createClient } from "@supabase/supabase-js";
import type { Database } from "./types";

const SUPABASE_URL = import.meta.env["VITE_SUPABASE_URL"] || "https://cmnztsstsbxyjltlzqiu.supabase.co";
const SUPABASE_KEY = import.meta.env["VITE_SUPABASE_PUBLISHABLE_KEY"] || "sb_publishable_wqueqc_1ovzB-wn5yfjc0A_3mHfmy22";

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: typeof window !== "undefined" ? window.localStorage : undefined,
  },
}) as any;
