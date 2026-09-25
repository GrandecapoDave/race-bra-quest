import { useState, useEffect, useMemo } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, Trophy, Clock, ShieldAlert, Award } from "lucide-react";
import { leaderboardQuery, formatDuration, rankLeaderboard } from "@/lib/race";
import { HeroAvatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";

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

  // Interruttore: mostra la classifica CON i punti cattiveria (malus/bonus usati). Di default e' quella che vedono le squadre.
  const [withMalus, setWithMalus] = useState<boolean>(() => {
    try { return localStorage.getItem("admin-live-with-malus") === "1"; } catch { return false; }
  });
  const toggleMalus = () => {
    const next = !withMalus;
    setWithMalus(next);
    try { localStorage.setItem("admin-live-with-malus", next ? "1" : "0"); } catch { /* ignore */ }
  };
  const rows = useMemo(() => {
    const withTotals = (leaderboard as any[]).map((r) => ({
      ...r,
      shown_total: Number(r.total_points ?? 0) + (withMalus ? Number(r.cattiveria_points ?? 0) : 0),
    }));
    if (!withMalus) return withTotals; // stesso ordine che vedono le squadre
    // stesso criterio della classifica: prove completate, poi punti (ora con la cattiveria), poi tempo
    const ordered = rankLeaderboard(withTotals.map((r) => ({ ...r, total_points: r.shown_total })) as any);
    return ordered as any[];
  }, [leaderboard, withMalus]);

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

        {/* Interruttore cattiveria */}
        <button
          type="button"
          onClick={toggleMalus}
          aria-pressed={withMalus}
          className={`flex items-center gap-2.5 self-start sm:self-center rounded-2xl border px-3.5 py-2 text-left transition-colors cursor-pointer ${
            withMalus ? "border-purple-500/50 bg-purple-500/15" : "border-border/50 bg-secondary/40 hover:bg-secondary/60"
          }`}
        >
          <span className={`relative h-5 w-9 shrink-0 rounded-full transition-colors ${withMalus ? "bg-purple-500" : "bg-zinc-700"}`}>
            <span className={`absolute top-0.5 size-4 rounded-full bg-white transition-all ${withMalus ? "left-[18px]" : "left-0.5"}`} />
          </span>
          <span className="leading-tight">
            <span className="block text-[11px] font-black uppercase tracking-wider text-foreground">😈 Con punti cattiveria</span>
            <span className="block text-[10px] text-muted-foreground">
              {withMalus ? "Acceso: prove + modificatori + cattiveria" : "Spento: senza cattiveria (come nella classifica delle squadre)"}
            </span>
          </span>
        </button>

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

      {withMalus && (
        <p className="rounded-xl border border-purple-500/25 bg-purple-500/5 px-3.5 py-2.5 text-[11px] leading-snug text-purple-200/90">
          Classifica in corso <strong>con i punti cattiveria</strong>, aggiornata in tempo reale. I bonus tempo e token non ci sono ancora:
          si calcolano solo a fine gara (li vedi nel Resoconto, con "Ricalcola").
        </p>
      )}

      {/* LEADERBOARD TABLE CARD */}
      <div className="surface border border-border/30 rounded-2xl p-5 space-y-4">
        {leaderboard.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground space-y-2">
            <Award className="size-8 mx-auto opacity-40 text-muted-foreground animate-bounce" />
            <p className="text-sm font-bold">Nessuna squadra iscritta</p>
            <p className="text-xs">Le squadre compariranno in questa classifica non appena si registreranno.</p>
          </div>
        ) : (
          <>
          {/* MOBILE: una scheda per squadra */}
          <div className="space-y-2 md:hidden">
            {rows.map((row: any, index: number) => {
              const position = index + 1;
              const medal = position === 1 ? "🥇" : position === 2 ? "🥈" : position === 3 ? "🥉" : `#${position}`;
              const expires = row.freeze_expires_at ? new Date(row.freeze_expires_at).getTime() : 0;
              const frozenLeft = expires > now ? Math.max(0, Math.round((expires - now) / 1000)) : 0;
              let statusText = "Attiva";
              let statusClass = "bg-success/10 border-success/20 text-success";
              if (!row.active) {
                statusText = "Disattivata";
                statusClass = "bg-destructive/10 border-destructive/20 text-destructive";
              } else if (frozenLeft > 0) {
                statusText = `Congelata ${Math.floor(frozenLeft / 60)}:${String(frozenLeft % 60).padStart(2, "0")}`;
                statusClass = "bg-cyan-500/10 border-cyan-500/20 text-cyan-400";
              }
              const cat = row.cattiveria_points ?? 0;
              return (
                <div key={row.team_id} className="rounded-xl border border-border/40 bg-secondary/40 p-3 space-y-2.5">
                  <div className="flex items-center gap-3">
                    <span className={`w-8 shrink-0 text-center font-black ${position <= 3 ? "text-xl" : "text-sm text-muted-foreground"}`}>{medal}</span>
                    <HeroAvatar
                      emoji={row.avatar_url || "🏳️"}
                      color={row.color}
                      isBordered
                      size="sm"
                      radius="full"
                      className="size-9 text-lg"
                      style={{ backgroundColor: (row.color || "#f97316") + "26" }}
                    />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-black text-foreground">{row.name}</p>
                      <span className={`inline-block mt-0.5 px-2 py-0.5 rounded-full text-[9px] font-black uppercase border tracking-wider ${statusClass}`}>{statusText}</span>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="font-display text-xl font-black text-primary leading-none">{row.shown_total}</p>
                      <p className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">punti</p>
                    </div>
                  </div>
                  <div className="grid grid-cols-4 gap-1.5 text-center text-[10px] font-bold">
                    <div className="rounded-lg bg-background/50 py-1.5">
                      <p className="text-muted-foreground uppercase tracking-wider text-[8px]">Prove</p>
                      <p className="text-foreground">{row.completed_challenges}/14</p>
                    </div>
                    <div className="rounded-lg bg-background/50 py-1.5">
                      <p className="text-muted-foreground uppercase tracking-wider text-[8px]">Sfide</p>
                      <p className="text-foreground">{row.challenges_points ?? 0}</p>
                    </div>
                    <div className="rounded-lg bg-background/50 py-1.5">
                      <p className="text-muted-foreground uppercase tracking-wider text-[8px]">😈</p>
                      <p className={cat > 0 ? "text-purple-400" : cat < 0 ? "text-red-400" : "text-zinc-400"}>{cat > 0 ? `+${cat}` : cat}</p>
                    </div>
                    <div className="rounded-lg bg-background/50 py-1.5">
                      <p className="text-muted-foreground uppercase tracking-wider text-[8px]">Tempo</p>
                      <p className="font-mono text-foreground">{row.total_duration_seconds != null ? formatDuration(row.total_duration_seconds) : "—"}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="hidden md:block overflow-x-auto rounded-xl border border-border/30 bg-zinc-950/40">
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
                {rows.map((row: any, index: number) => {
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
                          <HeroAvatar
                            emoji={row.avatar_url || "🏳️"}
                            color={row.color}
                            isBordered
                            size="sm"
                            radius="full"
                            isHoverable
                            className="size-9 text-lg"
                            style={{
                              backgroundColor: (row.color || "#f97316") + "26",
                            }}
                          />
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
                        {row.shown_total} PT
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
          </>
        )}
      </div>
    </div>
  );
}
