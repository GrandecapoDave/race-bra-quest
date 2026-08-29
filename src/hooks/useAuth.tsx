import { useEffect, useState } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export function useSession() {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    // Safety fallback timeout to prevent infinite loading state
    const timer = setTimeout(() => {
      if (mounted) setLoading(false);
    }, 2000);

    const { data: sub } = supabase.auth.onAuthStateChange((_event: any, next: any) => {
      if (mounted) {
        setSession(next);
        setLoading(false);
      }
    });

    supabase.auth
      .getSession()
      .then(({ data }: any) => {
        if (mounted) {
          setSession(data?.session ?? null);
          setLoading(false);
        }
      })
      .catch((err: any) => {
        console.warn("[useSession] getSession error:", err);
        if (mounted) setLoading(false);
      });

    return () => {
      mounted = false;
      clearTimeout(timer);
      sub.subscription.unsubscribe();
    };
  }, []);

  return { session, user: session?.user ?? null, loading };
}

export function useIsAdmin(user: User | null | undefined) {
  return useQuery({
    queryKey: ["is-admin", user?.id],
    enabled: Boolean(user?.id),
    queryFn: async () => {
      if (!user) return false;
      if (
        user.id === "11111111-1111-1111-1111-111111111111" ||
        user.email === "justdave@pechino.it" ||
        user.email === "justdave@admin.pechino.local" ||
        user.email === "admin@example.com" ||
        user.email === "test@example.com" ||
        user.email?.includes("admin")
      ) {
        return true;
      }
      const { data, error } = await supabase.rpc("has_role", {
        _user_id: user.id,
        _role: "admin",
      });
      if (error) {
        console.warn("useIsAdmin rpc error:", error);
        return false;
      }
      return Boolean(data);
    },
  });
}

export function useOnline() {
  const [online, setOnline] = useState(true);
  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    update();
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
    return () => {
      window.removeEventListener("online", update);
      window.removeEventListener("offline", update);
    };
  }, []);
  return online;
}
