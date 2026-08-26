import { useState, useEffect, useRef } from "react";
import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { AppShell } from "@/components/AppShell";
import { useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import {
  Trophy,
  Lock,
  Clock,
  AlertTriangle,
  ShoppingBag,
  Home,
  ArrowLeft,
  XCircle,
  Loader2,
} from "lucide-react";
import { myTeamQuery, leaderboardQuery } from "@/lib/race";

export const Route = createFileRoute("/_authenticated/classifica")({
  component: ClassificaPage,
});

function ClassificaPage() {
  const { user } = useSession();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // Track whether we've already triggered a consume so we don't double-call.
  const consumedRef = useRef(false);
  const [isClosing, setIsClosing] = useState(false);
  const [openError, setOpenError] = useState<string | null>(null);

  // Query team details using canonical race query
  const teamQuery = useQuery(myTeamQuery);
  const team = teamQuery.data;

  // Unconditionally query leaderboard for backup / display rows (Rules of Hooks)
  const boardQuery = useQuery(leaderboardQuery);

  // Query the team's latest bonus_classifica transaction — no auto-refetch while viewing
  const classificationTxQuery = useQuery({
    queryKey: ["team-classification-bonus-detail", team?.id],
    enabled: !!team?.id,
    staleTime: 0,
    refetchInterval: false,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id,outcome:dettagli")
        .eq("team_id", team!.id)
        .eq("marketplace_item_id", "bonus_classifica")
        .order("data_acquisto", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error) return null;
      return data;
    },
  });

  const tx = classificationTxQuery.data;

  // ─── Core close function ─────────────────────────────────────────────────
  // Called by both the "CHIUDI CLASSIFICA" button and the useEffect cleanup.
  const closeLeaderboardBonus = async (txId: string) => {
    if (consumedRef.current) return;
    consumedRef.current = true;

    await (supabase as any).rpc("consume_marketplace_transaction", {
      p_transaction_id: txId,
    });

    // Invalidate sidebar badge and classifica queries immediately
    queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
    queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
  };

  // ─── Auto-consume on unmount (navigating away, sidebar click, back button, etc.) ─────
  useEffect(() => {
    const currentTxId = tx?.id;
    if (!currentTxId) return;

    return () => {
      if (!consumedRef.current) {
        consumedRef.current = true;
        (supabase as any).rpc("consume_marketplace_transaction", {
          p_transaction_id: currentTxId,
        });
        queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
        queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
      }
    };
  }, [tx?.id, queryClient]);

  // ─── Auto-consume on window/tab close ─────────────────────────────────────
  useEffect(() => {
    const handleBeforeUnload = () => {
      if (tx?.id && !consumedRef.current) {
        (supabase as any).rpc("consume_marketplace_transaction", {
          p_transaction_id: tx.id,
        });
      }
    };
    window.addEventListener("beforeunload", handleBeforeUnload);
    return () => {
      window.removeEventListener("beforeunload", handleBeforeUnload);
    };
  }, [tx?.id]);

  // ─── Step: transition completed → viewing on first render ─────────────────
  useEffect(() => {
    if (!tx?.id || !team?.id) return;
    if (tx.stato !== "completed") return;

    (async () => {
      const { error } = await (supabase as any).rpc("open_classifica_bonus", {
        p_transaction_id: tx.id,
      });

      if (error) {
        setOpenError(error.message);
      } else {
        // Refresh the local view so we see the "viewing" state and snapshot
        queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail", team?.id] });
      }
    })();
  }, [tx?.id, tx?.stato, team?.id, queryClient]);

  // ─── Explicit close button ─────────────────────────────────────────────────
  const handleCloseClassifica = async () => {
    if (!tx?.id) return;
    setIsClosing(true);
    try {
      await closeLeaderboardBonus(tx.id);
      toast.success("Classifica chiusa. Il Bonus è stato consumato.");
      navigate({ to: "/dashboard" });
    } catch {
      toast.error("Si è verificato un errore imprevisto.");
    } finally {
      setIsClosing(false);
    }
  };

  // ─── Loading ───────────────────────────────────────────────────────────────
  if (teamQuery.isLoading || (team?.id && classificationTxQuery.isLoading)) {
    return (
      <AppShell isAdmin={false}>
        <div className="flex h-[50vh] items-center justify-center">
          <Loader2 className="size-8 animate-spin text-orange-500" />
        </div>
      </AppShell>
    );
  }

  // ─── Not purchased ─────────────────────────────────────────────────────────
  if (!tx) {
    return (
      <AppShell isAdmin={false}>
        <div className="surface p-8 max-w-lg mx-auto text-center space-y-6 border border-dashed border-red-500/30 rounded-3xl mt-12 bg-red-950/5">
          <div className="size-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto border border-red-500/20 text-red-500">
            <Lock className="size-8" />
          </div>
          <div className="space-y-2">
            <h1 className="text-3xl font-display font-black uppercase text-red-500">Classifica Bloccata</h1>
            <p className="text-sm text-muted-foreground leading-relaxed">
              La classifica è attualmente riservata alle squadre che hanno acquistato il{" "}
              <strong>Bonus Classifica</strong>.
            </p>
          </div>
          <div className="pt-2 flex flex-col sm:flex-row justify-center gap-3">
            <Link
              to="/marketplace"
              className="px-6 py-2.5 rounded-xl bg-orange-500 text-black font-black text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer flex items-center justify-center gap-1.5"
            >
              <ShoppingBag className="size-4" />
              Vai al Marketplace
            </Link>
            <Link
              to="/dashboard"
              className="px-6 py-2.5 rounded-xl border border-zinc-800 hover:bg-zinc-900 text-xs font-black uppercase tracking-wider text-muted-foreground hover:text-white transition-all cursor-pointer flex items-center justify-center gap-1.5"
            >
              <Home className="size-4" />
              Torna alla Dashboard
            </Link>
          </div>
        </div>
      </AppShell>
    );
  }

  // ─── Already consumed or blocked due to second access attempt ─────────────
  if (tx.stato === "used" || tx.stato === "viewing" && openError) {
    return (
      <AppShell isAdmin={false}>
        <div className="surface p-8 max-w-lg mx-auto text-center space-y-6 border border-zinc-800 rounded-3xl mt-12 bg-zinc-950/30">
          <div className="size-16 rounded-full bg-zinc-800 border border-zinc-700 flex items-center justify-center mx-auto text-zinc-400">
            <Lock className="size-8" />
          </div>
          <div className="space-y-2">
            <h1 className="text-3xl font-display font-black uppercase text-foreground">
              Classifica non disponibile
            </h1>
            <p className="text-sm text-muted-foreground leading-relaxed">
              Hai già utilizzato il <strong>Bonus Classifica</strong> durante questa gara. Come da
              regolamento, la classifica poteva essere visualizzata <strong>una sola volta</strong>.
            </p>
          </div>
          <div className="pt-2 flex justify-center">
            <Link
              to="/dashboard"
              className="px-6 py-2.5 rounded-xl border border-zinc-800 hover:bg-zinc-900 text-xs font-black uppercase tracking-wider text-muted-foreground hover:text-white transition-all cursor-pointer flex items-center justify-center gap-1.5"
            >
              <ArrowLeft className="size-4" />
              Torna alla Dashboard
            </Link>
          </div>
        </div>
      </AppShell>
    );
  }

  // ─── Transitioning: "completed" → waiting for "viewing" ───────────────────
  // Show a brief spinner while the open_classifica_bonus RPC completes and
  // the query refreshes to the "viewing" state with the snapshot.
  if (tx.stato === "completed") {
    return (
      <AppShell isAdmin={false}>
        <div className="flex h-[50vh] items-center justify-center flex-col gap-4">
          <Trophy className="size-10 text-yellow-500 animate-bounce" />
          <p className="text-sm text-muted-foreground">Caricamento classifica in corso…</p>
        </div>
      </AppShell>
    );
  }

  // ─── Active viewing state ──────────────────────────────────────────────────
  const snapshot: any[] = tx.outcome?.snapshot || tx.dettagli?.snapshot || [];
  const displayRows: any[] = snapshot.length > 0 ? snapshot : (boardQuery.data || []);
  const timestamp: string | undefined = tx.outcome?.snapshot_timestamp || tx.dettagli?.snapshot_timestamp;

  return (
    <AppShell isAdmin={false}>
      <div className="space-y-5 max-w-lg mx-auto pb-10">
        {/* Top Sticky/Prominent Action Bar */}
        <div className="flex items-center justify-between bg-zinc-950/80 backdrop-blur-md p-3 px-4 rounded-2xl border border-zinc-800/80 shadow-lg">
          <span className="text-[11px] font-black uppercase text-amber-500 tracking-wider flex items-center gap-1.5">
            <Trophy className="size-4" /> Bonus Attivo
          </span>
          <button
            onClick={handleCloseClassifica}
            disabled={isClosing}
            className="px-3.5 py-1.5 rounded-xl bg-red-600 hover:bg-red-500 text-white font-black text-xs uppercase tracking-wider shadow-md active:scale-95 transition-all cursor-pointer flex items-center gap-1.5 border border-red-500/40"
          >
            {isClosing ? <Loader2 className="size-3.5 animate-spin" /> : <XCircle className="size-3.5" />}
            <span>Chiudi Classifica</span>
          </button>
        </div>

        {/* Header */}
        <div className="text-center space-y-2">
          <div className="size-14 rounded-full bg-yellow-500/10 border border-yellow-500/20 text-yellow-500 flex items-center justify-center mx-auto animate-pulse">
            <Trophy className="size-7" />
          </div>
          <h1 className="text-3xl font-display font-black uppercase tracking-wider text-foreground">
            Classifica Generale
          </h1>
          {timestamp && (
            <p className="text-[10px] text-zinc-500 font-extrabold uppercase tracking-widest flex items-center justify-center gap-1.5 bg-zinc-900/60 py-1.5 px-3 rounded-full border border-zinc-800/80 w-fit mx-auto">
              <Clock className="size-3.5 text-orange-400" />
              Snapshot rilevato alle{" "}
              {new Date(timestamp).toLocaleTimeString("it-IT", {
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
              })}
            </p>
          )}
        </div>

        {/* Snapshot list */}
        <div className="surface border rounded-3xl bg-[#070d1e]/40 p-5 shadow-2xl relative overflow-hidden space-y-3">
          <div className="absolute top-0 right-0 w-32 h-32 bg-yellow-500/5 rounded-full blur-3xl pointer-events-none" />

          <div className="divide-y divide-border/10">
            {displayRows.map((row: any, index: number) => {
              const position = index + 1;
              const isCurrentTeam = row.team_id === team?.id;
              const medal =
                position === 1 ? "🥇" : position === 2 ? "🥈" : position === 3 ? "🥉" : `${position}°`;

              return (
                <div
                  key={row.team_id}
                  className={`flex items-center justify-between py-3.5 px-2 transition-all rounded-xl ${
                    isCurrentTeam ? "bg-white/5 border border-white/10 font-bold" : "hover:bg-zinc-900/30"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="w-8 text-center text-sm font-black text-zinc-400">{medal}</span>
                    <div className="flex items-center gap-2">
                      <span className="text-sm shrink-0" style={{ color: row.color }}>
                        ●
                      </span>
                      <span
                        className={`text-xs uppercase font-extrabold ${
                          isCurrentTeam ? "text-white" : "text-zinc-300"
                        }`}
                      >
                        {row.name || row.nome_squadra}
                        {isCurrentTeam && (
                          <span className="ml-1.5 text-[8px] bg-orange-500 text-black px-1 py-0.5 rounded font-black tracking-wide">
                            TU
                          </span>
                        )}
                      </span>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className="text-xs font-black text-foreground font-mono">
                      {row.total_points} PT
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="bg-yellow-950/10 border border-yellow-500/10 p-3 rounded-2xl text-[10px] text-zinc-500 flex items-start gap-2 leading-relaxed">
            <AlertTriangle className="size-4 text-yellow-500 shrink-0 mt-0.5" />
            <div>
              <strong>ATTENZIONE:</strong> Questa classifica mostra la situazione esatta al momento
              dell'attivazione del Bonus. Navigare verso un'altra sezione o chiudere questa
              pagina <strong>consumerà definitivamente il Bonus</strong>.
            </div>
          </div>
        </div>

        {/* Explicit close button */}
        <button
          onClick={handleCloseClassifica}
          disabled={isClosing}
          className="w-full py-3 rounded-xl bg-gradient-to-r from-red-600 to-rose-700 text-white font-black text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer flex items-center justify-center gap-2"
        >
          {isClosing ? (
            <Loader2 className="size-4 animate-spin" />
          ) : (
            <>
              <XCircle className="size-4" />
              Chiudi Classifica
            </>
          )}
        </button>
      </div>
    </AppShell>
  );
}
