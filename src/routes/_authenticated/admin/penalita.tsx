import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { AppShell } from "@/components/AppShell";
import { supabase } from "@/integrations/supabase/client";
import {
  Skull,
  Users,
  ShieldAlert,
  ArrowDownCircle,
  Calendar,
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/penalita")({
  head: () => ({
    meta: [{ title: "Penalità Punti — Admin · Pechino Express Bra" }],
  }),
  component: PenalitaAdmin,
});

function PenalitaAdmin() {
  // All active teams
  const teamsQuery = useQuery({
    queryKey: ["admin-all-teams-penalita"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("teams")
        .select("id,nome_squadra,color,active");
      if (error) return [];
      return data ?? [];
    },
    refetchInterval: 5000,
  });

  // All penalita_punti transactions
  const txQuery = useQuery({
    queryKey: ["admin-penalita-transactions"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("marketplace_transactions")
        .select("*")
        .eq("item_id", "penalita_punti")
        .order("timestamp", { ascending: false });
      if (error) return [];
      return data ?? [];
    },
    refetchInterval: 5000,
  });

  const teams: any[] = teamsQuery.data ?? [];
  const transactions: any[] = txQuery.data ?? [];

  const getTeamName = (teamId: string) => {
    return teams.find((t) => t.id === teamId)?.nome_squadra || "Sconosciuta";
  };

  const getTeamColor = (teamId: string) => {
    return teams.find((t) => t.id === teamId)?.color || "#ffffff";
  };

  const isLoading = teamsQuery.isLoading || txQuery.isLoading;

  return (
    <AppShell isAdmin={true}>
      <div className="space-y-6 max-w-5xl mx-auto pb-10">
        {/* Header */}
        <div className="space-y-1">
          <h1 className="text-2xl sm:text-3xl font-display font-black uppercase tracking-wider text-foreground flex items-center gap-3">
            <Skull className="size-7 text-red-500" />
            Penalità Punti
          </h1>
          <p className="text-xs text-muted-foreground leading-relaxed max-w-lg">
            Monitora l'applicazione del Malus <strong className="text-red-400">PENALITÀ PUNTI (−20 PT)</strong>.
            I punti rimossi vengono distrutti dal sistema e non vengono assegnati a chi acquista il malus.
          </p>
        </div>

        {/* Transactions Table */}
        <div className="surface border border-zinc-800 bg-[#070d1e] rounded-2xl overflow-hidden shadow-xl">
          <div className="p-5 border-b border-border/40 flex items-center justify-between">
            <h2 className="text-sm font-black uppercase tracking-wider flex items-center gap-2">
              <Users className="size-4 text-zinc-400" /> Storico Utilizzi
            </h2>
            <span className="text-[10px] bg-zinc-900 border border-zinc-800 px-2 py-0.5 rounded-full text-zinc-400 font-mono">
              Totale: {transactions.length}
            </span>
          </div>

          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-3">
              <div className="size-8 border-4 border-t-red-500 border-red-500/20 rounded-full animate-spin" />
              <span className="text-xs text-muted-foreground">Caricamento transazioni...</span>
            </div>
          ) : transactions.length === 0 ? (
            <div className="text-center py-20 space-y-2">
              <Skull className="size-10 text-zinc-700 mx-auto" />
              <p className="text-xs text-muted-foreground italic">Nessun utilizzo di Penalità Punti registrato finora.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-border/20 bg-zinc-950/20 text-zinc-500 text-[10px] font-black uppercase tracking-wider">
                    <th className="py-3.5 px-5">Acquirente</th>
                    <th className="py-3.5 px-5">Bersaglio</th>
                    <th className="py-3.5 px-5">Costo</th>
                    <th className="py-3.5 px-5">Penalità</th>
                    <th className="py-3.5 px-5">Esito Dettagliato</th>
                    <th className="py-3.5 px-5">Data/Ora</th>
                    <th className="py-3.5 px-5">Stato</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/10">
                  {transactions.map((tr) => {
                    const isBlocked = tr.stato === "blocked";
                    const outcome = tr.outcome;
                    
                    return (
                      <tr key={tr.id} className="hover:bg-zinc-900/10 transition-colors">
                        {/* Acquirente */}
                        <td className="py-4 px-5">
                          <div className="flex items-center gap-2">
                            <span
                              className="size-2 rounded-full shrink-0"
                              style={{ backgroundColor: getTeamColor(tr.buyer_team_id) }}
                            />
                            <strong className="text-foreground text-xs font-bold">
                              {getTeamName(tr.buyer_team_id)}
                            </strong>
                          </div>
                        </td>

                        {/* Bersaglio */}
                        <td className="py-4 px-5">
                          {tr.target_team_id ? (
                            <div className="flex items-center gap-2">
                              <span
                                className="size-2 rounded-full shrink-0"
                                style={{ backgroundColor: getTeamColor(tr.target_team_id) }}
                              />
                              <span className="text-foreground font-semibold">
                                {getTeamName(tr.target_team_id)}
                              </span>
                            </div>
                          ) : (
                            <span className="text-zinc-600">—</span>
                          )}
                        </td>

                        {/* Costo */}
                        <td className="py-4 px-5 font-mono text-orange-400 font-bold">
                          {tr.costo} TK 🪙
                        </td>

                        {/* Penalità nominale */}
                        <td className="py-4 px-5">
                          <span className="inline-flex items-center gap-1 font-bold text-red-400">
                            <ArrowDownCircle className="size-3.5" />
                            -20 PT
                          </span>
                        </td>

                        {/* Dettagli punti prima/dopo */}
                        <td className="py-4 px-5">
                          {isBlocked ? (
                            <span className="text-[10px] text-zinc-500 italic">Neutralizzato da Scudo</span>
                          ) : outcome ? (
                            <div className="space-y-0.5 text-[10px]">
                              <div className="flex justify-between gap-4 text-zinc-400">
                                <span>Punti Bersaglio Prima:</span>
                                <strong className="font-mono text-zinc-300">{outcome.target_points_before} PT</strong>
                              </div>
                              <div className="flex justify-between gap-4 text-zinc-400">
                                <span>Punti Sottratti:</span>
                                <strong className="font-mono text-red-400">-{outcome.points_deducted} PT</strong>
                              </div>
                              <div className="flex justify-between gap-4 text-zinc-400 border-t border-zinc-900 pt-0.5 mt-0.5">
                                <span>Punti Bersaglio Dopo:</span>
                                <strong className="font-mono text-white">{outcome.target_points_after} PT</strong>
                              </div>
                              {outcome.points_deducted < 20 && (
                                <div className="text-[9px] text-orange-400 italic font-semibold">
                                  Punteggio insufficiente
                                </div>
                              )}
                            </div>
                          ) : (
                            <span className="text-zinc-600">—</span>
                          )}
                        </td>

                        {/* Data/Ora */}
                        <td className="py-4 px-5 text-zinc-500 font-mono text-[10px]">
                          <div className="flex items-center gap-1">
                            <Calendar className="size-3 text-zinc-600" />
                            <span>{new Date(tr.timestamp).toLocaleString("it-IT")}</span>
                          </div>
                        </td>

                        {/* Stato */}
                        <td className="py-4 px-5">
                          {isBlocked ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider border border-red-500/20 bg-red-500/5 text-red-400">
                              <ShieldAlert className="size-3" /> NEUTRALIZZATO
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider border border-emerald-500/20 bg-emerald-500/5 text-emerald-400">
                              <CheckCircle className="size-3" /> APPLICATA
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </AppShell>
  );
}

// Inline CheckCircle component helper
function CheckCircle(props: any) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
      <path d="m9 11 3 3L22 4" />
    </svg>
  );
}
