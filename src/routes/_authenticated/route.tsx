import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { Loader2, RefreshCw } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    try {
      // 1. Fast local session lookup first (avoids blocking network call on refresh)
      const { data: sessionData } = await supabase.auth.getSession().catch(() => ({ data: { session: null } }));
      if (sessionData?.session?.user) {
        return { user: sessionData.session.user };
      }

      // 2. Network fallback with strict 4s timeout to prevent infinite router hang
      const userPromise = supabase.auth.getUser().then((res: any) => res.data?.user ?? null).catch(() => null);
      const timeoutPromise = new Promise<null>((resolve) => setTimeout(() => resolve(null), 4000));
      const user = await Promise.race([userPromise, timeoutPromise]);

      if (!user) {
        throw redirect({ to: "/auth" });
      }
      return { user };
    } catch (err) {
      // If it's already a TanStack redirect, rethrow it
      if (err && typeof err === "object" && "to" in err) {
        throw err;
      }
      // Otherwise redirect safely to login
      throw redirect({ to: "/auth" });
    }
  },
  pendingComponent: () => (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="flex flex-col items-center gap-3 text-center">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-xs font-bold text-muted-foreground uppercase tracking-widest">
          Caricamento sessione in corso...
        </p>
      </div>
    </div>
  ),
  errorComponent: ({ reset }: { reset: () => void }) => (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center space-y-4 surface p-6 rounded-2xl border border-border/40">
        <h2 className="text-xl font-black text-foreground">Si è verificato un problema</h2>
        <p className="text-xs text-muted-foreground">
          Impossibile completare il caricamento della pagina. Riprova per continuare la gara.
        </p>
        <div className="pt-2 flex justify-center gap-3">
          <button
            onClick={() => {
              if (typeof window !== "undefined") window.location.reload();
              else reset();
            }}
            className="primary-gradient px-4 py-2 rounded-xl text-xs font-extrabold text-primary-foreground flex items-center gap-1.5 cursor-pointer"
          >
            <RefreshCw className="size-3.5" />
            <span>Ricarica Pagina</span>
          </button>
          <a
            href="/"
            className="bg-secondary hover:bg-secondary/80 px-4 py-2 rounded-xl text-xs font-bold text-foreground border border-border/40"
          >
            Torna alla Base
          </a>
        </div>
      </div>
    </div>
  ),
  component: () => <Outlet />,
});
