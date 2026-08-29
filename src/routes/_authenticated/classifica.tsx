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
  if (tx.stato === "used" || (tx.stato === "viewing" && openError)) {
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

  // ─── Transitioning: "completed" → waiting for "viewing" snapshot ──────────
  if (tx.stato === "completed") {
    return (
      <AppShell isAdmin={false}>
        <div className="flex h-[50vh] items-center justify-center flex-col gap-4">
          <Trophy className="size-10 text-yellow-500 animate-bounce" />
          <p className="text-sm text-muted-foreground">Caricamento snapshot classifica in corso…</p>
        </div>
      </AppShell>
    );
  }

  // ─── Active viewing state with FROZEN SNAPSHOT Data ────────────────────────
  const snapshot: any[] = tx.outcome?.snapshot || tx.dettagli?.snapshot || [];
  const displayRows: any[] = snapshot.length > 0 ? snapshot : (boardQuery.data || []);
  const timestamp: string | undefined = tx.outcome?.snapshot_timestamp || tx.dettagli?.snapshot_timestamp;

  return (
    <AppShell isAdmin={false}>
      <div className="space-y-5 max-w-lg mx-auto pb-10">
        {/* Top Sticky/Prominent Action Bar */}
        <div className="flex items-center justify-between bg-zinc-950/90 backdrop-blur-md p-3 px-4 rounded-2xl border border-zinc-800/80 shadow-lg sticky top-3 z-30">
          <span className="text-[11px] font-black uppercase text-amber-500 tracking-wider flex items-center gap-1.5">
            <Trophy className="size-4" /> Bonus Attivo (View-Once)
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
          <div className="size-16 rounded-2xl gold-gradient text-white flex items-center justify-center mx-auto shadow-lg shadow-amber-500/25 animate-pop-in">
            <Trophy className="size-8" />
          </div>
          <h1 className="text-3xl sm:text-4xl font-display font-extrabold uppercase tracking-wide text-foreground">
            Classifica Generale
          </h1>
          {timestamp && (
            <p className="text-[10px] text-muted-foreground font-black uppercase tracking-widest flex items-center justify-center gap-1.5 bg-secondary/80 py-1.5 px-3.5 rounded-full border border-border/50 w-fit mx-auto shadow-inner">
              <Clock className="size-3.5 text-primary" />
              Snapshot live delle{" "}
              {new Date(timestamp).toLocaleTimeString("it-IT", {
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
              })}
            </p>
          )}
        </div>

        {/* TOP 3 PODIUM (Se ci sono almeno 3 squadre) */}
        {displayRows.length >= 3 && (
          <div className="grid grid-cols-3 gap-2 sm:gap-3 items-end pt-2 pb-2">
            {/* 2° Posto (Argento) */}
            <div className="podium-card-2 rounded-2xl p-3 sm:p-4 text-center flex flex-col items-center order-1">
              <span className="text-2xl sm:text-3xl">🥈</span>
              <span className="text-[10px] font-black uppercase text-slate-300 mt-1 truncate max-w-full">
                {displayRows[1]?.name || displayRows[1]?.nome_squadra}
              </span>
              <span className="text-sm sm:text-base font-black font-mono text-foreground mt-0.5">
                {displayRows[1]?.total_points} PT
              </span>
            </div>

            {/* 1° Posto (Oro - Più alto) */}
            <div className="podium-card-1 rounded-2xl p-4 sm:p-5 text-center flex flex-col items-center order-2 pb-6 shadow-xl">
              <span className="text-3xl sm:text-4xl animate-bounce">🥇</span>
              <span className="text-xs font-black uppercase text-amber-300 mt-1 truncate max-w-full">
                {displayRows[0]?.name || displayRows[0]?.nome_squadra}
              </span>
              <span className="text-base sm:text-lg font-black font-mono text-amber-400 mt-0.5 drop-shadow-[0_0_8px_rgba(245,158,11,0.4)]">
                {displayRows[0]?.total_points} PT
              </span>
            </div>

            {/* 3° Posto (Bronzo) */}
            <div className="podium-card-3 rounded-2xl p-3 sm:p-4 text-center flex flex-col items-center order-3">
              <span className="text-2xl sm:text-3xl">🥉</span>
              <span className="text-[10px] font-black uppercase text-amber-600 mt-1 truncate max-w-full">
                {displayRows[2]?.name || displayRows[2]?.nome_squadra}
              </span>
              <span className="text-sm sm:text-base font-black font-mono text-foreground mt-0.5">
                {displayRows[2]?.total_points} PT
              </span>
            </div>
          </div>
        )}

        {/* Snapshot list */}
        <div className="hud-panel p-4 sm:p-5 space-y-3">
          <div className="divide-y divide-border/20">
            {displayRows.map((row: any, index: number) => {
              const position = index + 1;
              const isCurrentTeam = row.team_id === team?.id;
              const medal =
                position === 1 ? "🥇" : position === 2 ? "🥈" : position === 3 ? "🥉" : `${position}°`;

              return (
                <div
                  key={row.team_id}
                  className={`flex items-center justify-between py-3 px-3 transition-all rounded-xl ${
                    isCurrentTeam
                      ? "hud-panel-glow border-primary/50 bg-primary/10 shadow-lg shadow-primary/10 scale-[1.02] my-1.5"
                      : "hover:bg-secondary/40"
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="w-7 text-center text-sm font-black text-muted-foreground shrink-0">{medal}</span>
                    <div className="flex items-center gap-2.5 min-w-0">
                      <div
                        className="size-3 rounded-full shrink-0 shadow-sm"
                        style={{ backgroundColor: row.color || "#f97316" }}
                      />
                      <span
                        className={`text-xs sm:text-sm uppercase font-black truncate ${
                          isCurrentTeam ? "text-primary" : "text-foreground"
                        }`}
                      >
                        {row.name || row.nome_squadra}
                      </span>
                      {isCurrentTeam && (
                        <span className="text-[9px] bg-primary text-white px-2 py-0.5 rounded-full font-black tracking-wide shrink-0">
                          LA TUA SQUADRA
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="text-right shrink-0 pl-2">
                    <span className="text-xs sm:text-sm font-black text-foreground font-mono">
                      {row.total_points} PT
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="bg-amber-500/10 border border-amber-500/25 p-3 rounded-xl text-[11px] text-amber-200/90 flex items-start gap-2.5 leading-relaxed mt-4">
            <AlertTriangle className="size-4 text-amber-400 shrink-0 mt-0.5" />
            <div>
              <strong>ATTENZIONE:</strong> Questa classifica mostra la situazione esatta al momento dell'attivazione del Bonus. Uscire da questa schermata o premere "Chiudi Classifica" <strong>consumerà definitivamente il Bonus</strong>.
            </div>
          </div>
        </div>
      </div>
    </AppShell>
  );
}
