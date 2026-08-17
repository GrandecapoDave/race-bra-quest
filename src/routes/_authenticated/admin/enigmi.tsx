import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Puzzle, Check, Clock, RefreshCw, Edit2, X, Loader2, Users } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useAdminContext } from "@/routes/_authenticated/admin";
import { toast } from "sonner";

export const Route = createFileRoute("/_authenticated/admin/enigmi")({
  head: () => ({
    meta: [
      { title: "Enigmi Tappa 4 — Admin Pechino Express Bra" },
      { name: "description", content: "Dashboard admin per la Tappa 4 ENIGMI." },
    ],
  }),
  component: AdminEnigmiPage,
});

function formatTime(iso: string | null): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

function formatDurationSec(startIso: string | null, endIso: string | null): string {
  if (!startIso) return "—";
  const start = new Date(startIso).getTime();
  const end = endIso ? new Date(endIso).getTime() : Date.now();
  const sec = Math.floor((end - start) / 1000);
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function AdminEnigmiPage() {
  const queryClient = useQueryClient();
  const [editingSolution, setEditingSolution] = useState<{ challenge_id: string; current: string } | null>(null);
  const [solutionInput, setSolutionInput] = useState("");
  const [expandedTeam, setExpandedTeam] = useState<string | null>(null);

  const { data: sessionData } = useQuery({
    queryKey: ["admin-session"],
    queryFn: async () => {
      const { data } = await supabase.auth.getUser();
      return data?.user?.id ?? null;
    },
  });
  const adminId = sessionData ?? "11111111-1111-1111-1111-111111111111";

  const dashboard = useQuery({
    queryKey: ["enigma-dashboard"],
    refetchInterval: 10000,
    queryFn: async () => {
      const { data, error } = await supabase.rpc("admin_get_enigma_dashboard", { p_admin_id: adminId });
      if (error) throw error;
      return data as { rows: any[]; enigma_solutions: any[] };
    },
    enabled: !!adminId,
  });

  const updateSolution = useMutation({
    mutationFn: async ({ challengeId, solution }: { challengeId: string; solution: string }) => {
      const { data, error } = await supabase.rpc("admin_update_enigma_solution", {
        p_challenge_id: challengeId,
        p_solution: solution,
        p_admin_id: adminId,
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      toast.success("Soluzione aggiornata.");
      setEditingSolution(null);
      setSolutionInput("");
      queryClient.invalidateQueries({ queryKey: ["enigma-dashboard"] });
    },
    onError: (err: any) => toast.error("Errore: " + err.message),
  });

  const rows = dashboard.data?.rows ?? [];
  const solutions = dashboard.data?.enigma_solutions ?? [];
  const activeRows = rows.filter((r: any) => r.active !== false);
  const startedCount = activeRows.filter((r: any) => r.started).length;
  const completedCount = activeRows.filter((r: any) => r.completed_all).length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-3xl font-display font-black uppercase tracking-wider flex items-center gap-3">
            <Puzzle className="size-7 text-primary" />
            Tappa 4 — Enigmi
          </h1>
          <p className="text-sm text-muted-foreground mt-1">Dashboard in tempo reale. Aggiornamento automatico ogni 10s.</p>
        </div>
        <button
          onClick={() => queryClient.invalidateQueries({ queryKey: ["enigma-dashboard"] })}
          className="flex items-center gap-2 px-4 py-2 rounded-xl border border-border text-xs font-bold hover:bg-secondary/50 transition-colors cursor-pointer"
        >
          <RefreshCw className={"size-4 " + (dashboard.isFetching ? "animate-spin" : "")} />
          Aggiorna
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: "Squadre Attive", value: activeRows.length, color: "text-foreground" },
          { label: "Avanzate a T4", value: startedCount, color: "text-primary" },
          { label: "T4 Completata", value: completedCount, color: "text-success" },
          { label: "Enigmi Totali", value: 3, color: "text-muted-foreground" },
        ].map((s) => (
          <div key={s.label} className="surface p-4 rounded-2xl border border-border/40 text-center space-y-1">
            <p className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground">{s.label}</p>
            <p className={"text-3xl font-black " + s.color}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Solution management */}
      <div className="surface p-5 rounded-2xl border border-border/40 space-y-4">
        <h2 className="text-base font-extrabold uppercase tracking-wider text-muted-foreground flex items-center gap-2">
          <Edit2 className="size-4" />
          Gestione Soluzioni
        </h2>
        <p className="text-xs text-muted-foreground">
          Tutti gli enigmi di questa tappa (Rebus Musicale, Lucchetto Direzionale, Coordinate Finali) hanno soluzioni fisse gestite in modo sicuro dal sistema.
        </p>
        <div className="grid gap-3">
          {solutions.map((sol: any) => {
            const isReadOnly = true;
            const isEditing = editingSolution?.challenge_id === sol.challenge_id;
            const label = sol.challenge_id === "e1e1e1e1-f2f2-f3f3-f4f4-f5f5f6f6f7f7"
              ? "Enigma 1 — Rebus Musicale"
              : sol.challenge_id === "e2e2e2e2-f3f3-f4f4-f5f5-f6f6f7f7f8f8"
              ? "Enigma 2 — Lucchetto Direzionale"
              : "Enigma 3 — Le Coordinate Finali";
            return (
              <div key={sol.challenge_id} className="flex items-center justify-between gap-3 p-3 rounded-xl bg-muted/10 border border-border/30">
                <div>
                  <p className="text-sm font-bold">{label}</p>
                  <p className="text-xs text-muted-foreground font-mono">
                    {sol.challenge_id === "e3e3e3e3-f4f4-f5f5-f6f6-f7f7f8f8f9f9" ? "Lat: 44.71, Lng: 7.84" : sol.hint}
                  </p>
                </div>
                {!isReadOnly && (
                  isEditing ? (
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        value={solutionInput}
                        onChange={(e) => setSolutionInput(e.target.value)}
                        placeholder="Nuova soluzione..."
                        className="rounded-xl border border-input bg-input/40 px-3 py-2 text-sm font-bold focus:outline-none w-36"
                        autoFocus
                        onKeyDown={(e) => { if (e.key === "Enter") updateSolution.mutate({ challengeId: sol.challenge_id, solution: solutionInput }); }}
                      />
                      <button
                        onClick={() => updateSolution.mutate({ challengeId: sol.challenge_id, solution: solutionInput })}
                        disabled={!solutionInput.trim() || updateSolution.isPending}
                        className="p-2 rounded-xl bg-primary text-primary-foreground disabled:opacity-40 cursor-pointer"
                      >
                        {updateSolution.isPending ? <Loader2 className="size-4 animate-spin" /> : <Check className="size-4" />}
                      </button>
                      <button onClick={() => { setEditingSolution(null); setSolutionInput(""); }} className="p-2 rounded-xl border border-border text-muted-foreground hover:text-foreground cursor-pointer">
                        <X className="size-4" />
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => { setEditingSolution({ challenge_id: sol.challenge_id, current: sol.hint }); setSolutionInput(""); }}
                      className="px-3 py-1.5 rounded-xl border border-border text-xs font-bold hover:bg-secondary/50 transition-colors cursor-pointer"
                    >
                      Modifica
                    </button>
                  )
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Team progress table */}
      <div className="surface rounded-2xl border border-border/40 overflow-hidden">
        <div className="p-5 border-b border-border/40">
          <h2 className="text-base font-extrabold uppercase tracking-wider text-muted-foreground flex items-center gap-2">
            <Users className="size-4" />
            Progresso Squadre
          </h2>
        </div>

        {dashboard.isLoading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="size-6 animate-spin text-muted-foreground" />
          </div>
        ) : activeRows.length === 0 ? (
          <div className="py-12 text-center text-sm text-muted-foreground">Nessuna squadra attiva.</div>
        ) : (
          <div className="divide-y divide-border/30">
            {activeRows
              .sort((a: any, b: any) => b.enigmi_completati - a.enigmi_completati)
              .map((row: any) => {
                const isExpanded = expandedTeam === row.team_id;
                return (
                  <div key={row.team_id}>
                    <button
                      onClick={() => setExpandedTeam(isExpanded ? null : row.team_id)}
                      className="w-full flex items-center justify-between px-5 py-4 hover:bg-muted/5 transition-colors cursor-pointer text-left"
                    >
                      <div className="flex items-center gap-3">
                        <div className={
                          "size-2.5 rounded-full shrink-0 " +
                          (row.completed_all ? "bg-success" : row.started ? "bg-primary animate-pulse" : "bg-muted-foreground/30")
                        } />
                        <div>
                          <p className="font-extrabold text-sm">{row.nome_squadra}</p>
                          <p className="text-xs text-muted-foreground">
                            {row.completed_all ? "Completata" : row.started ? "In corso" : "Non iniziata"}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4">
                        {/* Enigma pills */}
                        <div className="flex gap-1.5">
                          {(row.enigma_progress || []).map((ep: any) => (
                            <div
                              key={ep.challenge_id}
                              className={
                                "size-7 rounded-lg flex items-center justify-center text-xs font-black " +
                                (ep.stato === "completed" ? "bg-success/20 text-success border border-success/30" :
                                  ep.stato === "started" ? "bg-primary/20 text-primary border border-primary/30" :
                                  "bg-muted/20 text-muted-foreground border border-border/30")
                              }
                              title={ep.titolo}
                            >
                              {ep.stato === "completed" ? "✓" : ep.ordine}
                            </div>
                          ))}
                        </div>
                        <span className="text-xs text-muted-foreground font-mono">
                          {row.enigmi_completati}/{row.enigmi_totali}
                        </span>
                      </div>
                    </button>

                    {isExpanded && (
                      <div className="px-5 pb-4 bg-muted/5 border-t border-border/20 space-y-3 animate-in slide-in-from-top-2 duration-200">
                        {(row.enigma_progress || []).map((ep: any) => (
                          <div key={ep.challenge_id} className="rounded-xl border border-border/30 overflow-hidden">
                            <div className="flex items-center justify-between px-4 py-2.5 bg-muted/10">
                              <div className="flex items-center gap-2">
                                <span className={
                                  "text-[10px] font-extrabold uppercase px-2 py-0.5 rounded " +
                                  (ep.stato === "completed" ? "bg-success/20 text-success" :
                                    ep.stato === "started" ? "bg-primary/20 text-primary" :
                                    "bg-muted/20 text-muted-foreground")
                                }>
                                  {ep.stato === "completed" ? "Risolto" : ep.stato === "started" ? "In corso" : "Non iniziato"}
                                </span>
                                <p className="text-sm font-bold">{ep.titolo}</p>
                              </div>
                              <div className="flex items-center gap-3 text-xs text-muted-foreground">
                                <span className="flex items-center gap-1">
                                  <Clock className="size-3" />
                                  {ep.stato === "completed" ? formatDurationSec(ep.started_at, ep.completed_at) : "—"}
                                </span>
                                <span>{ep.attempt_count} tent.</span>
                              </div>
                            </div>
                            {ep.attempts && ep.attempts.length > 0 && (
                              <div className="px-4 py-2 space-y-1">
                                {ep.attempts.slice(-5).map((att: any) => (
                                  <div key={att.id} className="flex items-center justify-between text-xs">
                                    <span className="text-muted-foreground font-mono">
                                      #{att.attempt_number} — {formatTime(att.submitted_at)}
                                    </span>
                                    <span className={"font-bold px-2 py-0.5 rounded " + (att.is_correct ? "text-success bg-success/10" : "text-destructive bg-destructive/10")}>
                                      {att.is_correct ? "Corretto" : "Errato (-8 PT)"}
                                    </span>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
          </div>
        )}
      </div>
    </div>
  );
}
