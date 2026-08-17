import { createClient } from "@supabase/supabase-js";
import type { Database } from "./types";

const SUPABASE_URL = import.meta.env["VITE_SUPABASE_URL"] || "https://aehjyuarqvwovqfodlss.supabase.co";
const SUPABASE_KEY = import.meta.env["VITE_SUPABASE_PUBLISHABLE_KEY"] || "sb_publishable_JPNkHg4UFgBYnasfD2c23g_4vtHSSCm";

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: typeof window !== "undefined" ? window.localStorage : undefined,
  },
}) as any;
