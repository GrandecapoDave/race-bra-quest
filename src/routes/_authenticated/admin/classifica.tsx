import { useState, useEffect } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, Trophy, Clock, ShieldAlert, Award } from "lucide-react";
import { leaderboardQuery, formatDuration } from "@/lib/race";

export const Route = createFileRoute("/_authenticated/admin/classifica")({
  head: () => ({
    meta: [
      { title: "Classifica Live — Regia" },
      { name: "description", content: "Classifica reale e in tempo reale per la regia di Pechino Express Bra." },
    ],
  }),
  component: AdminLiveLeaderboardPage,
});

function AdminLiveLeaderboardPage() {
  const [lastUpdated, setLastUpdated] = useState<string>("");

  // Query the real-time leaderboard with 3s polling
  const { data: leaderboard = [], isLoading, error, dataUpdatedAt } = useQuery({
    ...leaderboardQuery,
    refetchInterval: 3000,
  });

  // Track the last updated time
  useEffect(() => {
    if (dataUpdatedAt) {
      setLastUpdated(new Date(dataUpdatedAt).toLocaleTimeString("it-IT"));
    }
  }, [dataUpdatedAt]);

  // Clock state to tick freeze remaining time countdowns
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-3">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Caricamento classifica live...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="surface p-6 rounded-2xl border border-destructive/20 bg-destructive/10 text-center max-w-md mx-auto mt-12 space-y-3">
        <ShieldAlert className="size-8 text-destructive mx-auto" />
        <p className="font-bold text-destructive">Errore nel caricamento dei dati</p>
        <p className="text-xs text-muted-foreground">
          Si è verificato un errore durante il caricamento della classifica. Riprova o ricarica la pagina.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="surface p-5 rounded-2xl border border-border/40 bg-gradient-to-b from-[#1b1c2b]/60 to-[#0c0d15]/60 flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="size-12 rounded-full bg-yellow-500/10 border border-yellow-500/20 flex items-center justify-center text-yellow-500 text-xl">
            🏆
          </div>
          <div>
            <h1 className="text-xl font-display font-black uppercase tracking-wider text-foreground">
              🏆 CLASSIFICA LIVE
            </h1>
            <p className="text-xs text-muted-foreground">
              Posizionamento in tempo reale della gara
            </p>
          </div>
        </div>

        {/* Live Indicator */}
        <div className="flex items-center gap-3 self-start sm:self-center">
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-success/10 border border-success/20 text-success text-[10px] uppercase font-black tracking-widest animate-pulse">
            <span className="size-2 rounded-full bg-success" />
            LIVE
          </div>
          {lastUpdated && (
            <p className="text-[10px] text-muted-foreground font-semibold flex items-center gap-1">
              <Clock className="size-3.5" /> Aggiornato alle {lastUpdated}
            </p>
          )}
        </div>
      </div>

      {/* LEADERBOARD TABLE CARD */}
      <div className="surface border border-border/30 rounded-2xl p-5 space-y-4">
        {leaderboard.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground space-y-2">
            <Award className="size-8 mx-auto opacity-40 text-muted-foreground animate-bounce" />
            <p className="text-sm font-bold">Nessuna squadra iscritta</p>
            <p className="text-xs">Le squadre compariranno in questa classifica non appena si registreranno.</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-border/30 bg-zinc-950/40">
            <table className="w-full text-xs text-left">
              <thead className="bg-muted/10 text-muted-foreground uppercase text-[9px] tracking-wider border-b border-border/30">
                <tr>
                  <th className="px-4 py-3 text-center w-16 whitespace-nowrap">Pos</th>
                  <th className="px-4 py-3 whitespace-nowrap">Squadra</th>
                  <th className="px-4 py-3 text-center whitespace-nowrap">Prove Completate</th>
                  <th className="px-4 py-3 text-center whitespace-nowrap">Punti Sfide</th>
                  <th className="px-4 py-3 text-center whitespace-nowrap min-w-[120px]">Punti Cattiveria</th>
                  <th className="px-4 py-3 text-center whitespace-nowrap">Modificatori</th>
                  <th className="px-4 py-3 text-center whitespace-nowrap">Punteggio Totale</th>
                  <th className="px-4 py-3 text-center whitespace-nowrap">Tempo di Percorrenza</th>
                  <th className="px-4 py-3 text-center w-36 whitespace-nowrap">Stato</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/25">
                {leaderboard.map((row: any, index: number) => {
                  const position = index + 1;
                  const medal =
                    position === 1
                      ? "🥇"
                      : position === 2
                      ? "🥈"
                      : position === 3
                      ? "🥉"
                      : `#${position}`;

                  // Determine active freeze countdown
                  let isFrozen = false;
                  let freezeSecondsLeft = 0;
                  if (row.freeze_expires_at) {
                    const expires = new Date(row.freeze_expires_at).getTime();
                    if (expires > now) {
                      isFrozen = true;
                      freezeSecondsLeft = Math.max(0, Math.round((expires - now) / 1000));
                    }
                  }

                  // Determine status badge
                  let statusText = "Attiva";
                  let statusClass = "bg-success/10 border-success/20 text-success";
                  if (!row.active) {
                    statusText = "Disattivata";
                    statusClass = "bg-destructive/10 border-destructive/20 text-destructive";
                  } else if (isFrozen) {
                    const min = Math.floor(freezeSecondsLeft / 60);
                    const sec = freezeSecondsLeft % 60;
                    statusText = `Congelata (${min}:${String(sec).padStart(2, "0")})`;
                    statusClass = "bg-cyan-500/10 border-cyan-500/20 text-cyan-400";
                  }

                  return (
                    <tr
                      key={row.team_id}
                      className="hover:bg-zinc-900/40 transition-colors duration-200"
                    >
                      <td className="px-4 py-4 text-center font-black text-sm text-foreground">
                        {position <= 3 ? (
                          <span className="text-xl" title={`${position}° posto`}>{medal}</span>
                        ) : (
                          <span className="text-muted-foreground">{medal}</span>
                        )}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-3">
                          <span
                            className="size-9 rounded-full bg-zinc-900 border border-border flex items-center justify-center text-lg select-none shadow-inner"
                            style={{ borderColor: row.color + "40", boxShadow: `0 0 8px ${row.color}15` }}
                          >
                            {row.avatar_url || "🏳️"}
                          </span>
                          <div>
                            <div className="flex items-center gap-1.5 font-bold text-foreground text-sm">
                              <span className="size-2 rounded-full shrink-0" style={{ backgroundColor: row.color }} />
                              {row.name}
                            </div>
                            {row.motto && (
                              <p className="text-[10px] text-muted-foreground italic mt-0.5 line-clamp-1 max-w-[200px]">
                                "{row.motto}"
                              </p>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-center">
                        <div className="inline-flex flex-col items-center gap-1">
                          <span className="font-extrabold text-sm text-foreground">
                            {row.completed_challenges} <span className="text-[10px] text-muted-foreground">/ 14</span>
                          </span>
                          {/* Progress bar */}
                          <div className="w-16 h-1 bg-zinc-800 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-orange-500 to-yellow-400 transition-all duration-500"
                              style={{ width: `${Math.min(100, (row.completed_challenges / 14) * 100)}%` }}
                            />
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-center font-bold text-foreground">
                        {row.challenges_points ?? 0} PT
                      </td>
                      <td className="px-4 py-4 text-center">
                        <div className="flex items-center justify-center">
                          <span
                            className={`inline-flex items-center justify-center gap-1.5 px-2.5 py-1 rounded-lg font-black text-xs whitespace-nowrap shadow-sm ${
                              (row.cattiveria_points ?? 0) > 0
                                ? "bg-purple-500/20 text-purple-400 border border-purple-500/40"
                                : (row.cattiveria_points ?? 0) < 0
                                ? "bg-red-500/20 text-red-400 border border-red-500/40"
                                : "bg-zinc-800/80 text-zinc-400 border border-zinc-700/40"
                            }`}
                          >
                            <span>{row.cattiveria_points > 0 ? `+${row.cattiveria_points}` : row.cattiveria_points ?? 0}</span>
                            <span className="text-sm leading-none select-none">😈</span>
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-center font-bold text-muted-foreground">
                        {row.modifier_points > 0 ? `+${row.modifier_points}` : row.modifier_points ?? 0} PT
                      </td>
                      <td className="px-4 py-4 text-center font-black text-sm text-primary">
                        {row.total_points} PT
                      </td>
                      <td className="px-4 py-4 text-center font-mono font-bold text-foreground">
                        {row.total_duration_seconds != null ? (
                          <div className="flex items-center justify-center gap-1 text-xs">
                            <Clock className="size-3.5 text-muted-foreground shrink-0" />
                            {formatDuration(row.total_duration_seconds)}
                          </div>
                        ) : (
                          "—"
                        )}
                      </td>
                      <td className="px-4 py-4 text-center">
                        <span className={`px-2.5 py-1 rounded-full text-[9px] font-black uppercase border tracking-wider ${statusClass}`}>
                          {statusText}
                        </span>
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
  );
}
