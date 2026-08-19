import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { AppShell } from "@/components/AppShell";
import { useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import {
  Zap,
  Clock,
  CheckCircle,
  Users,
  Loader2,
  ShieldAlert,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/partenze")({
  head: () => ({
    meta: [{ title: "Partenze Anticipate — Admin · Pechino Express Bra" }],
  }),
  component: PartenzeAnticipateAdmin,
});

function PartenzeAnticipateAdmin() {
  const { user } = useSession();
  const queryClient = useQueryClient();
  const [markingId, setMarkingId] = useState<string | null>(null);

  // All active teams
  const teamsQuery = useQuery({
    queryKey: ["admin-all-teams"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("teams")
        .select("id,nome_squadra,color,avatar_url,active")
        .eq("active", true);
      if (error) return [];
      return data ?? [];
    },
    refetchInterval: 5000,
  });

  // All partenza_anticipata transactions
  const txQuery = useQuery({
    queryKey: ["admin-partenze-transactions"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id")
        .eq("marketplace_item_id", "partenza_anticipata");
      if (error) return [];
      return data ?? [];
    },
    refetchInterval: 5000,
  });

  const teams: any[] = teamsQuery.data ?? [];
  const transactions: any[] = txQuery.data ?? [];

  // Build a map: team_id → transaction
  const txByTeam = new Map<string, any>();
  for (const tx of transactions) {
    txByTeam.set(tx.team_id || tx.buyer_team_id, tx);
  }

  const handleMarkUsed = async (tx: any) => {
    if (markingId) return;
    setMarkingId(tx.id);
    try {
      const { error } = await (supabase as any).rpc("mark_partenza_used", {
        p_transaction_id: tx.id,
        p_admin_id: user?.id,
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Bonus registrato come UTILIZZATO.");
        queryClient.invalidateQueries({ queryKey: ["admin-partenze-transactions"] });
      }
    } finally {
      setMarkingId(null);
    }
  };

  const isLoading = teamsQuery.isLoading || txQuery.isLoading;

  return (
    <AppShell isAdmin={true}>
      <div className="space-y-6 max-w-2xl mx-auto pb-10">
        {/* Header */}
        <div className="space-y-1">
          <h1 className="text-2xl sm:text-3xl font-display font-black uppercase tracking-wider text-foreground flex items-center gap-3">
            <Zap className="size-7 text-yellow-400" />
            Partenze Anticipate
          </h1>
          <p className="text-xs text-muted-foreground leading-relaxed max-w-lg">
            Verifica quali squadre hanno acquistato il Bonus Partenza Anticipata (−2 minuti).
            Le squadre con stato <strong className="text-yellow-400">DISPONIBILE</strong> comunicheranno verbalmente
            alla Regia di voler usufruire del vantaggio — la Regia le farà partire fisicamente 2 minuti prima.
          </p>
        </div>

        {/* Info banner */}
        <div className="bg-yellow-950/10 border border-yellow-500/15 rounded-2xl p-4 flex items-start gap-3">
          <ShieldAlert className="size-5 text-yellow-400 shrink-0 mt-0.5" />
          <div className="text-xs text-zinc-400 leading-relaxed space-y-1">
            <p>
              <strong className="text-yellow-400">Nessun pulsante "Attiva" richiesto.</strong> Il vantaggio è puramente fisico:
              la squadra parte 2 minuti prima. L'app serve solo come registro.
            </p>
            <p>
              Il bottone <span className="font-bold text-zinc-300">Segna come Utilizzato</span> è facoltativo:
              consente alla Regia di annotare a posteriori che la partenza è avvenuta.
            </p>
          </div>
        </div>

        {/* Loading */}
        {isLoading && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="size-8 animate-spin text-yellow-400" />
          </div>
        )}

        {/* Teams list */}
        {!isLoading && (
          <div className="space-y-3">
            {teams.length === 0 && (
              <div className="text-center py-12 text-muted-foreground text-sm">
                <Users className="size-8 mx-auto mb-3 opacity-30" />
                Nessuna squadra attiva trovata.
              </div>
            )}

            {teams.map((team: any) => {
              const tx = txByTeam.get(team.id);
              const hasPurchased = !!tx;
              const isUsed = tx?.stato === "used";
              const purchasedAt = tx?.created_at ? new Date(tx.created_at) : null;
              const usedAt = tx?.used_at ? new Date(tx.used_at) : null;

              return (
                <div
                  key={team.id}
                  className={`surface rounded-2xl p-5 border transition-all ${
                    isUsed
                      ? "border-emerald-500/20 bg-emerald-950/5"
                      : hasPurchased
                      ? "border-yellow-500/30 bg-yellow-950/10"
                      : "border-border/40 bg-card/30 opacity-60"
                  }`}
                >
                  {/* Team name row */}
                  <div className="flex items-center gap-3 mb-4">
                    <span
                      className="size-9 rounded-xl text-xl flex items-center justify-center shrink-0"
                      style={{ backgroundColor: (team.color ?? "#f97316") + "22", border: `1px solid ${(team.color ?? "#f97316")}44` }}
                    >
                      {team.avatar_url ?? "🏳️"}
                    </span>
                    <div className="min-w-0">
                      <h2 className="text-sm font-black uppercase tracking-wider text-foreground truncate">
                        {team.nome_squadra}
                      </h2>
                      {!hasPurchased && (
                        <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-wider">Nessun Bonus</p>
                      )}
                    </div>
                    {hasPurchased && (
                      <div className="ml-auto shrink-0">
                        {isUsed ? (
                          <span className="flex items-center gap-1.5 text-[10px] text-emerald-400 font-black uppercase tracking-wider bg-emerald-500/10 border border-emerald-500/20 px-3 py-1.5 rounded-full">
                            <CheckCircle className="size-3.5" />
                            UTILIZZATO
                          </span>
                        ) : (
                          <span className="flex items-center gap-1.5 text-[10px] text-yellow-400 font-black uppercase tracking-wider bg-yellow-500/10 border border-yellow-500/20 px-3 py-1.5 rounded-full animate-pulse">
                            <Zap className="size-3.5" />
                            DISPONIBILE
                          </span>
                        )}
                      </div>
                    )}
                  </div>

                  {/* Bonus details */}
                  {hasPurchased && (
                    <div className="space-y-3">
                      <div className="grid grid-cols-2 gap-2 text-[10px]">
                        <div className="bg-zinc-900/40 rounded-xl p-2.5 border border-zinc-800">
                          <p className="text-zinc-500 font-bold uppercase tracking-wider mb-0.5">Bonus</p>
                          <p className="font-black text-yellow-400">🚦 PARTENZA ANTICIPATA</p>
                        </div>
                        <div className="bg-zinc-900/40 rounded-xl p-2.5 border border-zinc-800">
                          <p className="text-zinc-500 font-bold uppercase tracking-wider mb-0.5">Vantaggio</p>
                          <p className="font-black text-foreground">−2:00 minuti</p>
                        </div>
                        <div className="bg-zinc-900/40 rounded-xl p-2.5 border border-zinc-800">
                          <p className="text-zinc-500 font-bold uppercase tracking-wider mb-0.5">Costo</p>
                          <p className="font-black text-orange-400">35 Token</p>
                        </div>
                        {purchasedAt && (
                          <div className="bg-zinc-900/40 rounded-xl p-2.5 border border-zinc-800">
                            <p className="text-zinc-500 font-bold uppercase tracking-wider mb-0.5">Acquistato</p>
                            <p className="font-black text-foreground flex items-center gap-1">
                              <Clock className="size-3 shrink-0" />
                              {purchasedAt.toLocaleString("it-IT", {
                                day: "2-digit",
                                month: "2-digit",
                                year: "numeric",
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </p>
                          </div>
                        )}
                      </div>

                      {isUsed && usedAt && (
                        <div className="bg-emerald-950/10 border border-emerald-500/15 rounded-xl p-2.5 text-[10px] flex items-center gap-2">
                          <CheckCircle className="size-3.5 text-emerald-400 shrink-0" />
                          <span className="text-emerald-400 font-bold">
                            Registrato come utilizzato il{" "}
                            {usedAt.toLocaleString("it-IT", {
                              day: "2-digit",
                              month: "2-digit",
                              year: "numeric",
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </span>
                        </div>
                      )}

                      {/* Optional: Admin can mark as used AFTER physical departure */}
                      {!isUsed && (
                        <button
                          onClick={() => handleMarkUsed(tx)}
                          disabled={markingId === tx.id}
                          className="w-full py-2 rounded-xl border border-emerald-500/30 hover:bg-emerald-500/10 text-emerald-400 font-black text-[10px] uppercase tracking-wider flex items-center justify-center gap-1.5 transition-all cursor-pointer disabled:opacity-50"
                        >
                          {markingId === tx.id ? (
                            <Loader2 className="size-3.5 animate-spin" />
                          ) : (
                            <CheckCircle className="size-3.5" />
                          )}
                          Segna come Utilizzato (facoltativo)
                        </button>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </AppShell>
  );
}
