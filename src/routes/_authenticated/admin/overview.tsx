import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { signed } from "@/lib/utils";
import { formatDuration } from "@/lib/race";
import { useAdminContext } from "../admin";
import { AdminRaceControls } from "@/components/AdminRaceControls";

export const Route = createFileRoute("/_authenticated/admin/overview")({
  component: AdminOverviewPage,
});

function AdminOverviewPage() {
  const {
    monitorRows,
    challenges,
    sortedLeaderboard,
    activityLog,
    setSelectedTeamId,
    gameSettings,
    allTeams,
    allProgress,
  } = useAdminContext();
  const navigate = useNavigate();
  // prove obbligatorie (il Jackpot e' facoltativo e non entra nel conteggio)
  const totalMandatory = (challenges.data ?? []).filter((c: any) => (c.type ?? c.tipo_sfida) !== "jackpot").length;

  return (
    <div className="space-y-6">
      {/* COMANDI DELLA REGIA: pausa del tempo e sblocco dopo la banca */}
      <AdminRaceControls
        gameSettings={gameSettings.data}
        allTeams={allTeams.data ?? []}
        allProgress={allProgress.data ?? []}
      />

      {/* LIVE MONITOR SQUADRE */}
      <div className="surface p-4 sm:p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h2 className="text-base sm:text-xl font-display font-black uppercase tracking-wider text-muted-foreground">Monitoraggio Live Squadre</h2>

        {/* MOBILE: una scheda per squadra, tutto leggibile senza scorrere di lato */}
        <div className="space-y-2 md:hidden">
          {monitorRows.map((row: any) => (
            <button
              key={row.id}
              type="button"
              onClick={() => {
                setSelectedTeamId(row.id);
                navigate({ to: "/admin/teams" });
              }}
              className="w-full text-left rounded-xl border border-border/40 bg-secondary/40 p-3 space-y-2 active:scale-[0.99] transition-transform cursor-pointer"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="flex items-center gap-2 min-w-0">
                  <span className="size-2.5 rounded-full shrink-0" style={{ backgroundColor: row.color || "#f97316" }} />
                  <span className="font-black text-foreground truncate">{row.nome_squadra}</span>
                </span>
                <span className="font-display text-lg font-black text-gold shrink-0">{row.points} PT</span>
              </div>
              <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-muted-foreground font-semibold">
                <span className={`text-[10px] font-bold px-2 py-0.5 border rounded-full ${row.statusColor}`}>{row.statusLabel}</span>
                <span>{row.currentStageName}</span>
                <span className="text-primary font-bold">{row.completedCount}/{totalMandatory} prove</span>
                <span className="font-mono">{formatDuration(row.totalDurationSeconds)}</span>
              </div>
              <p className="text-[11px] text-muted-foreground truncate">
                <span className="text-foreground/90 font-semibold">{row.lastActionText}</span>
                {row.lastActionTime ? ` · ${row.lastActionTime}` : ""}
              </p>
            </button>
          ))}
        </div>

        <div className="overflow-x-auto hidden md:block">
          <table className="w-full min-w-[850px] text-left border-collapse text-sm">
            <thead>
              <tr className="border-b border-border/40 text-[10px] text-muted-foreground uppercase font-bold tracking-widest">
                <th className="pb-3 pr-4">Squadra</th>
                <th className="pb-3 pr-4">Stato</th>
                <th className="pb-3 pr-4">Tappa Corrente</th>
                <th className="pb-3 pr-4">Ultima Azione</th>
                <th className="pb-3 pr-4 text-right">Punti</th>
                <th className="pb-3 pr-4 text-right">Tempo</th>
                <th className="pb-3 text-right">Completate</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/20">
              {monitorRows.map((row: any) => (
                <tr
                  key={row.id}
                  onClick={() => {
                    setSelectedTeamId(row.id);
                    navigate({ to: "/admin/teams" });
                  }}
                  className="hover:bg-zinc-900/50 cursor-pointer transition-colors"
                >
                  <td className="py-3.5 pr-4 font-black text-foreground flex items-center gap-2">
                    <span className="size-2.5 rounded-full" style={{ backgroundColor: row.color || "#f97316" }} />
                    {row.nome_squadra}
                  </td>
                  <td className="py-3.5 pr-4">
                    <span className={`text-[10px] font-bold px-2 py-0.5 border rounded-full ${row.statusColor}`}>
                      {row.statusLabel}
                    </span>
                  </td>
                  <td className="py-3.5 pr-4 text-muted-foreground font-medium">{row.currentStageName}</td>
                  <td className="py-3.5 pr-4">
                    <div className="max-w-[200px] truncate">
                      <p className="font-semibold text-foreground">{row.lastActionText}</p>
                      <p className="text-[10px] text-muted-foreground">{row.lastActionTime}</p>
                    </div>
                  </td>
                  <td className="py-3.5 pr-4 text-right font-black text-gold">{row.points} PT</td>
                  <td className="py-3.5 pr-4 text-right font-mono text-xs text-muted-foreground">
                    {formatDuration(row.totalDurationSeconds)}
                  </td>
                  <td className="py-3.5 text-right font-bold text-primary">
                    {row.completedCount} / {totalMandatory}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* CLASSIFICA TEMPO REALE */}
        <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
          <h2 className="text-xl font-display font-black uppercase tracking-wider text-muted-foreground">Classifica Generale</h2>
          <div className="divide-y divide-border/40">
            {sortedLeaderboard.map((t: any, idx: number) => (
              <div key={t.id} className="flex items-center justify-between py-3">
                <div className="flex items-center gap-3">
                  <span className="font-display font-extrabold text-lg w-6 text-center text-muted-foreground">
                    #{idx + 1}
                  </span>
                  <div>
                    <p className="font-extrabold">{t.nome_squadra}</p>
                    <p className="text-xs text-muted-foreground">
                      {t.completedCount} prove completate · Tempo: {formatDuration(t.totalDurationSeconds)}
                    </p>
                  </div>
                </div>
                <span className="font-display text-2xl font-extrabold text-gold">{t.points} PT</span>
              </div>
            ))}
          </div>
        </div>

        {/* REGISTRO ATTIVITÀ IN TEMPO REALE */}
        <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
          <h2 className="text-xl font-display font-black uppercase tracking-wider text-muted-foreground">Attività in Tempo Reale</h2>
          <div className="divide-y divide-border/40 max-h-[380px] overflow-y-auto pr-2">
            {(activityLog.data ?? []).length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">Nessuna attività registrata.</p>
            ) : (
              (activityLog.data ?? []).slice(0, 15).map((log: any) => (
                <div key={log.id} className="flex items-start justify-between py-3 gap-2">
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-foreground">
                      {log.action}
                    </p>
                    <p className="text-[10px] text-muted-foreground/80 mt-1 font-semibold">
                      {new Date(log.timestamp).toLocaleString("it-IT")}
                    </p>
                  </div>
                  {log.points && (
                    <span className="text-[9px] font-extrabold uppercase px-2 py-0.5 rounded bg-primary/20 text-primary shrink-0">
                      {signed(log.points)} PT
                    </span>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Fine Panoramica */}
    </div>
  );
}
