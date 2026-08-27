import { useState, useEffect } from "react";
import { Check, X, Loader2, Trophy, Undo, Swords, Users } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import type { Challenge, Team } from "@/lib/race";

interface Props {
  challenge: Challenge;
  team: Team | null;
  completed: boolean;
  onComplete: () => void;
  completing: boolean;
}

export function CornholeChallenge({ challenge, team, completed, onComplete, completing }: Props) {
  const queryClient = useQueryClient();
  const { session } = useSession();
  const isAdminQuery = useIsAdmin(session?.user);
  const isAdmin = isAdminQuery.data === true;
  const currentUserId = team?.id;

  const [submittingMatchId, setSubmittingMatchId] = useState<string | null>(null);
  const [rollingBackMatchId, setRollingBackMatchId] = useState<string | null>(null);
  const [selectedSpecialByeTeamId, setSelectedSpecialByeTeamId] = useState<string>("");

  // 1. Fetch all teams to resolve IDs to Names
  const { data: allTeams, isLoading: loadingTeams } = useQuery({
    queryKey: ["teams_all_cornhole"],
    queryFn: async () => {
      const { data, error } = await supabase.from("teams").select("*");
      if (error) throw error;
      return data || [];
    }
  });

  // 2. Fetch tournament matches via RPC
  const { data: matches, isLoading: loadingMatches, refetch: refetchMatches } = useQuery({
    queryKey: ["cornhole_tournament", challenge.id],
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_cornhole_tournament");
      if (error) throw error;
      return data || [];
    }
  });

  // 2b. Fetch cornhole tournament settings
  const { data: cornholeSettings, isLoading: loadingSettings, refetch: refetchSettings } = useQuery({
    queryKey: ["cornhole_settings", challenge.id],
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_cornhole_settings");
      if (error) throw error;
      return data;
    }
  });

  // 2c. Special Bye selection mutation
  const setSpecialByeMutation = useMutation({
    mutationFn: async (teamId: string | null) => {
      const adminId = isAdmin ? "11111111-1111-1111-1111-111111111111" : currentUserId;
      const { data, error } = await supabase.rpc("set_cornhole_special_bye", {
        p_team_id: teamId,
        p_admin_id: adminId
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      toast.success("Vantaggio Speciale salvato e tabellone aggiornato!");
      queryClient.invalidateQueries({ queryKey: ["cornhole_tournament"] });
      refetchMatches();
      refetchSettings();
    },
    onError: (err: any) => {
      toast.error(err.message || "Errore durante il salvataggio.");
    }
  });

  // Sync selection local state with DB settings once loaded
  useEffect(() => {
    if (cornholeSettings?.special_bye_team_id) {
      setSelectedSpecialByeTeamId(cornholeSettings.special_bye_team_id);
    } else if (cornholeSettings) {
      setSelectedSpecialByeTeamId("none");
    }
  }, [cornholeSettings]);

  // 3. Match submission mutation
  const submitWinnerMutation = useMutation({
    mutationFn: async ({ matchId, winnerId }: { matchId: string; winnerId: string }) => {
      const adminId = isAdmin ? "11111111-1111-1111-1111-111111111111" : currentUserId;
      const { data, error } = await supabase.rpc("submit_cornhole_match_result", {
        p_match_id: matchId,
        p_winner_id: winnerId,
        p_admin_id: adminId
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      toast.success("Risultato salvato con successo!");
      queryClient.invalidateQueries({ queryKey: ["cornhole_tournament"] });
      queryClient.invalidateQueries({ queryKey: ["leaderboard"] });
      queryClient.invalidateQueries({ queryKey: ["scores"] });
      queryClient.invalidateQueries({ queryKey: ["progress"] });
      refetchMatches();
    },
    onError: (err: any) => {
      toast.error(err.message || "Errore nel salvataggio del risultato.");
    },
    onSettled: () => {
      setSubmittingMatchId(null);
    }
  });

  // 4. Rollback mutation
  const rollbackMutation = useMutation({
    mutationFn: async (matchId: string) => {
      const adminId = isAdmin ? "11111111-1111-1111-1111-111111111111" : currentUserId;
      const { data, error } = await supabase.rpc("rollback_cornhole_match_result", {
        p_match_id: matchId,
        p_admin_id: adminId
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      toast.success("Ultimo risultato annullato con successo!");
      queryClient.invalidateQueries({ queryKey: ["cornhole_tournament"] });
      queryClient.invalidateQueries({ queryKey: ["leaderboard"] });
      queryClient.invalidateQueries({ queryKey: ["scores"] });
      queryClient.invalidateQueries({ queryKey: ["progress"] });
      refetchMatches();
    },
    onError: (err: any) => {
      toast.error(err.message || "Errore durante l'annullamento.");
    },
    onSettled: () => {
      setRollingBackMatchId(null);
    }
  });

  // 5. Reset tournament mutation
  const resetTournamentMutation = useMutation({
    mutationFn: async () => {
      const adminId = isAdmin ? "11111111-1111-1111-1111-111111111111" : currentUserId;
      const { data, error } = await supabase.rpc("reset_cornhole_tournament", {
        p_admin_id: adminId
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      toast.success("Torneo Cornhole resettato con successo!");
      queryClient.invalidateQueries({ queryKey: ["cornhole_tournament"] });
      queryClient.invalidateQueries({ queryKey: ["leaderboard"] });
      queryClient.invalidateQueries({ queryKey: ["scores"] });
      queryClient.invalidateQueries({ queryKey: ["progress"] });
      refetchMatches();
      refetchSettings();
    },
    onError: (err: any) => {
      toast.error(err.message || "Errore durante il reset del torneo.");
    }
  });

  // 6. Generate tournament mutation
  const generateTournamentMutation = useMutation({
    mutationFn: async () => {
      const adminId = isAdmin ? "11111111-1111-1111-1111-111111111111" : currentUserId;
      const targetTeamId = selectedSpecialByeTeamId === "none" ? null : selectedSpecialByeTeamId;
      const { data, error } = await supabase.rpc("generate_cornhole_tournament", {
        p_admin_id: adminId,
        p_special_bye_team_id: targetTeamId
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      toast.success("Torneo Cornhole generato e accoppiamenti salvati!");
      queryClient.invalidateQueries({ queryKey: ["cornhole_tournament"] });
      queryClient.invalidateQueries({ queryKey: ["leaderboard"] });
      queryClient.invalidateQueries({ queryKey: ["scores"] });
      queryClient.invalidateQueries({ queryKey: ["progress"] });
      refetchMatches();
      refetchSettings();
    },
    onError: (err: any) => {
      toast.error(err.message || "Errore durante la generazione del torneo.");
    }
  });

  // Resolve team name helper
  const getTeamName = (id: string | null) => {
    if (!id) return "—";
    const found = allTeams?.find((t: any) => t.id === id);
    return found ? found.nome_squadra : "Squadra Sconosciuta";
  };

  if (loadingTeams || loadingMatches || loadingSettings) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-3">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Caricamento torneo di Cornhole...</p>
      </div>
    );
  }

  const sortedMatches = [...(matches || [])].sort((a: any, b: any) => {
    if (a.round !== b.round) return a.round - b.round;
    return a.match_index - b.match_index;
  });

  const maxRound = sortedMatches.length > 0 ? Math.max(...sortedMatches.map((m: any) => m.round)) : 0;
  const isTournamentCompleted = sortedMatches.some((m: any) => m.round === maxRound && m.status === "completed");
  const finalMatch = sortedMatches.find((m: any) => m.round === maxRound);
  const tournamentWinnerId = finalMatch?.winner_id;

  // Find active matches ready to be played (status === 'ready') for Regia controls
  const activeMatches = sortedMatches.filter((m: any) => m.status === "ready");
  // Find last completed match to allow rollback
  const completedMatchesSorted = sortedMatches
    .filter((m: any) => m.status === "completed" && m.team2_id !== null) // Ignore automatic bye matches
    .sort((a: any, b: any) => new Date(b.completed_at || "").getTime() - new Date(a.completed_at || "").getTime());
  const lastCompletedMatch = completedMatchesSorted[0];

  // Organize matches by round
  const rounds: { [key: number]: any[] } = {};
  sortedMatches.forEach((m: any) => {
    if (m && m.round !== undefined) {
      let list = rounds[m.round];
      if (!list) {
        list = [];
        rounds[m.round] = list;
      }
      list.push(m);
    }
  });

  const getRoundLabel = (r: number) => {
    const hasPrelim = rounds[0] && rounds[1] && rounds[0].length < rounds[1].length;
    if (hasPrelim && r === 0) return "Ottavi (Qualificazione)";
    const stepsFromFinal = maxRound - r;
    if (stepsFromFinal === 0) return "Finale";
    if (stepsFromFinal === 1) return "Semifinali";
    if (stepsFromFinal === 2) return "Quarti di Finale";
    if (stepsFromFinal === 3) return "Ottavi di Finale";
    if (stepsFromFinal === 4) return "Sedicesimi di Finale";
    return `Round ${r + 1}`;
  };

  return (
    <div className="space-y-6 w-full max-w-4xl mx-auto p-1">
      {/* Header Stat / Info */}
      <div className="surface p-5 rounded-2xl border border-border/40 text-center space-y-2 relative overflow-hidden bg-gradient-to-b from-[#111936] to-[#070d1e]">
        <div className="absolute top-2 right-2">
          {isTournamentCompleted ? (
            <span className="bg-success/20 border border-success/30 text-success text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full">
              Completato
            </span>
          ) : activeMatches.length > 0 ? (
            <span className="bg-warning/20 border border-warning/30 text-warning text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full animate-pulse">
              In Corso
            </span>
          ) : (
            <span className="bg-muted/20 border border-muted/30 text-muted-foreground text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full">
              Non Iniziato
            </span>
          )}
        </div>
        <div className="inline-flex size-12 items-center justify-center rounded-full bg-primary/10 border border-primary/20 mx-auto text-primary">
          <Trophy className="size-6 animate-bounce" />
        </div>
        <div>
          <h2 className="text-xl font-display font-black uppercase tracking-wider text-foreground flex items-center justify-center gap-2">
            🏆 Torneo Cornhole
          </h2>
          <p className="text-xs text-muted-foreground max-w-md mx-auto">
            Sfida fisica a eliminazione diretta 1vs1, round secco.
            La Regia convalida l'esito dei match fisici.
          </p>
        </div>
      </div>

      {/* Regia Controls - Only visible to ADMIN */}
      {isAdmin && (
        <div className="surface border border-primary/20 bg-primary/5 rounded-3xl p-6 space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border/10 pb-3">
            <h3 className="text-sm font-black uppercase tracking-wider text-primary flex items-center gap-2">
              <Swords className="size-4 animate-pulse" /> Console Arbitro Regia
            </h3>
            <div className="flex items-center gap-3">
              {lastCompletedMatch && !isTournamentCompleted && (
                <button
                  type="button"
                  onClick={async () => {
                    if (window.confirm(`Annullare il risultato dell'ultimo match disputato (${getTeamName(lastCompletedMatch.team1_id)} vs ${getTeamName(lastCompletedMatch.team2_id)})?`)) {
                      setRollingBackMatchId(lastCompletedMatch.id);
                      await rollbackMutation.mutateAsync(lastCompletedMatch.id);
                    }
                  }}
                  disabled={rollbackMutation.isPending}
                  className="text-xs font-bold text-muted-foreground hover:text-foreground flex items-center gap-1 cursor-pointer disabled:opacity-50"
                >
                  {rollbackMutation.isPending && rollingBackMatchId === lastCompletedMatch.id ? (
                    <Loader2 className="size-3 animate-spin" />
                  ) : (
                    <Undo className="size-3" />
                  )}
                  Annulla Ultimo Risultato
                </button>
              )}

              {/* 🔄 PULSANTE RESET TORNEO */}
              <button
                type="button"
                onClick={async () => {
                  if (window.confirm("⚠️ Sei sicuro di voler resettare il Torneo Cornhole? Tutti i match e i punteggi assegnati a questa sfida verranno azzerati.")) {
                    await resetTournamentMutation.mutateAsync();
                  }
                }}
                disabled={resetTournamentMutation.isPending}
                className="px-3 py-1.5 bg-destructive/10 hover:bg-destructive/20 text-destructive border border-destructive/30 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 disabled:opacity-50"
              >
                {resetTournamentMutation.isPending ? (
                  <Loader2 className="size-3 animate-spin" />
                ) : (
                  <span>🔄 Reset Torneo</span>
                )}
              </button>
            </div>
          </div>

          {/* ⚡ VANTAGGIO TAPPA 4 & CONFIGURAZIONE / AVVIO */}
          {sortedMatches.length === 0 ? (
            <div className="space-y-6">
              <div className="bg-zinc-950/40 border border-[#f59e0b]/20 p-5 rounded-2xl space-y-4">
                <div>
                  <h4 className="text-xs font-black uppercase text-[#f59e0b] tracking-wider flex items-center gap-2">
                    ⚡ Vantaggio Tappa 4
                  </h4>
                  <p className="text-[11px] text-muted-foreground mt-1">
                    La squadra arrivata prima nella Sfida 4.3 può saltare il primo turno del torneo di Cornhole e accedere direttamente al turno successivo.
                  </p>
                </div>

                {cornholeSettings?.first_place_stage4_3 && (
                  <div className="bg-[#f59e0b]/5 border border-[#f59e0b]/20 px-3 py-2 rounded-xl text-center">
                    <p className="text-[10px] text-muted-foreground font-semibold">
                      💡 SUGGERIMENTO: Il 1° classificato della Sfida 4.3 è{" "}
                      <span className="text-[#f59e0b] font-black">{getTeamName(cornholeSettings.first_place_stage4_3)}</span>
                    </p>
                  </div>
                )}

                <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
                  <div className="flex-1">
                    <label className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest block mb-1">
                      Seleziona squadra per il BYE:
                    </label>
                    <select
                      value={selectedSpecialByeTeamId}
                      onChange={(e) => setSelectedSpecialByeTeamId(e.target.value)}
                      className="w-full bg-zinc-900 border border-border/80 rounded-xl px-3 py-2.5 text-xs font-bold text-foreground focus:outline-none focus:ring-1 focus:ring-[#f59e0b]/30"
                    >
                      <option value="none">Nessun Vantaggio</option>
                      {allTeams
                        ?.filter((t: any) => t.active !== false)
                        .sort((a: any, b: any) => a.nome_squadra.localeCompare(b.nome_squadra))
                        .map((t: any) => (
                          <option key={t.id} value={t.id}>
                            {t.nome_squadra}
                          </option>
                        ))}
                    </select>
                  </div>
                </div>
              </div>

              {/* 🎲 PULSANTE GENERA ACCOPPIAMENTI & AVVIA TORNEO */}
              <div className="text-center bg-zinc-950/20 p-6 rounded-2xl border border-border/20 space-y-3">
                <p className="text-xs text-muted-foreground font-semibold">
                  Squadre partecipanti attive: <span className="text-foreground font-black">{allTeams?.filter((t: any) => t.active !== false).length}</span>
                </p>
                <button
                  type="button"
                  onClick={async () => {
                    if (window.confirm("Sei sicuro di voler generare gli accoppiamenti e avviare il Torneo Cornhole?")) {
                      await generateTournamentMutation.mutateAsync();
                    }
                  }}
                  disabled={generateTournamentMutation.isPending}
                  className="primary-gradient glow w-full max-w-sm py-4 px-6 text-primary-foreground font-black text-sm rounded-2xl shadow-xl transition-all hover:scale-[1.02] active:scale-95 cursor-pointer flex items-center justify-center gap-2 mx-auto disabled:opacity-50"
                >
                  {generateTournamentMutation.isPending ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    "🎲 GENERA ACCOPPIAMENTI & AVVIA TORNEO"
                  )}
                </button>
              </div>
            </div>
          ) : (
            <>
              {isTournamentCompleted ? (
                <div className="text-center py-6 space-y-3 bg-zinc-950/40 border border-success/30 rounded-2xl p-6">
                  <p className="text-base font-black text-success uppercase">🏆 Il torneo Cornhole è terminato!</p>
                  <p className="text-xs text-muted-foreground">Tutti i punti sono stati accreditati correttamente nella classifica.</p>
                  <button
                    type="button"
                    onClick={async () => {
                      if (window.confirm("Vuoi azzerare il torneo per ripeterlo da capo?")) {
                        await resetTournamentMutation.mutateAsync();
                      }
                    }}
                    disabled={resetTournamentMutation.isPending}
                    className="mt-3 px-5 py-2.5 bg-zinc-900 hover:bg-zinc-800 border border-border text-foreground font-bold rounded-xl text-xs cursor-pointer inline-flex items-center gap-2"
                  >
                    {resetTournamentMutation.isPending ? <Loader2 className="size-3.5 animate-spin" /> : "🔄 Riavvia / Reset Torneo"}
                  </button>
                </div>
              ) : activeMatches.length > 0 ? (
                <div className="grid gap-6">
                  <div className="text-center">
                    <span className="text-xs font-bold text-muted-foreground uppercase tracking-wider">
                      Seleziona il vincitore del match corrente:
                    </span>
                  </div>
                  {activeMatches.map((match) => (
                    <div
                      key={match.id}
                      className="bg-zinc-950/60 border border-border/40 p-5 rounded-2xl space-y-4 text-center"
                    >
                      <p className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">
                        {getRoundLabel(match.round)} — Match {match.match_index + 1}
                      </p>
                      
                      <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8">
                        {/* Team 1 Button */}
                        <div className="flex-1 w-full">
                          <button
                            type="button"
                            onClick={async () => {
                              setSubmittingMatchId(match.id);
                              await submitWinnerMutation.mutateAsync({ matchId: match.id, winnerId: match.team1_id });
                            }}
                            disabled={submitWinnerMutation.isPending}
                            className="w-full py-4 px-5 bg-gradient-to-r from-blue-900/40 to-blue-700/20 hover:from-blue-800/60 border border-blue-500/30 rounded-2xl text-foreground font-black text-sm active:scale-95 transition-all cursor-pointer shadow-lg shadow-blue-950/20"
                          >
                            🏆 {getTeamName(match.team1_id)} VINCE
                          </button>
                        </div>

                        <span className="text-xs font-black uppercase tracking-widest text-primary px-3 py-1 bg-primary/10 rounded-full border border-primary/20 shrink-0">
                          VS
                        </span>

                        {/* Team 2 Button */}
                        <div className="flex-1 w-full">
                          <button
                            type="button"
                            onClick={async () => {
                              setSubmittingMatchId(match.id);
                              await submitWinnerMutation.mutateAsync({ matchId: match.id, winnerId: match.team2_id });
                            }}
                            disabled={submitWinnerMutation.isPending}
                            className="w-full py-4 px-5 bg-gradient-to-r from-orange-900/40 to-orange-700/20 hover:from-orange-800/60 border border-orange-500/30 rounded-2xl text-foreground font-black text-sm active:scale-95 transition-all cursor-pointer shadow-lg shadow-orange-950/20"
                          >
                            🏆 {getTeamName(match.team2_id)} VINCE
                          </button>
                        </div>
                      </div>
                      {submitWinnerMutation.isPending && submittingMatchId === match.id && (
                        <div className="flex items-center justify-center gap-1.5 text-xs text-primary font-bold">
                          <Loader2 className="size-3.5 animate-spin" /> Salvataggio verdetto...
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : null}
            </>
          )}
        </div>
      )}

      {/* Se non sei admin e il torneo non è ancora generato */}
      {!isAdmin && sortedMatches.length === 0 && (
        <div className="surface p-8 rounded-2xl border border-border/40 text-center space-y-3">
          <Loader2 className="size-8 animate-spin text-primary mx-auto" />
          <h3 className="text-sm font-black uppercase tracking-wider text-foreground">
            In attesa del sorteggio
          </h3>
          <p className="text-xs text-muted-foreground max-w-sm mx-auto">
            La Regia sta configurando il torneo. Gli accoppiamenti verranno generati casualmente e saranno visibili a breve.
          </p>
        </div>
      )}

      {/* Team-only Special Bye Info Section */}
      {!isAdmin && !isTournamentCompleted && (
        <div className="surface p-5 rounded-2xl border border-border/40 text-center space-y-4">
          {cornholeSettings?.special_bye_team_id === currentUserId ? (
            <div className="space-y-1 animate-in fade-in duration-300">
              <p className="text-xs font-black uppercase text-[#f59e0b] tracking-wider flex items-center justify-center gap-1">
                ⚡ VANTAGGIO TAPPA 4.3
              </p>
              <p className="text-sm font-black text-foreground">
                La Regia ti ha assegnato un BYE.
              </p>
              <p className="text-xs text-muted-foreground">
                <b>Salti il primo turno del torneo di Cornhole</b> e accederai direttamente al turno successivo.
              </p>
            </div>
          ) : (
            <div className="space-y-1 text-muted-foreground/60 animate-in fade-in duration-300">
              <p className="text-[10px] font-bold uppercase tracking-widest">
                Vantaggio Tappa 4.3
              </p>
              <p className="text-xs">
                Nessun BYE assegnato alla tua squadra.
              </p>
            </div>
          )}
          
          <div className="border-t border-border/10 pt-3 text-center">
            <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">
              Punti in Palio in questa sfida:
            </p>
            <p className="text-xs font-bold text-foreground mt-1">
              🏆 <span className="text-gold font-black">20 PUNTI</span> alla squadra campione
            </p>
            <p className="text-xs font-bold text-muted-foreground">
              👥 <span className="text-foreground font-black">10 PUNTI</span> a tutte le altre squadre partecipanti
            </p>
          </div>
        </div>
      )}

      {/* Celebratory Screen if Finished */}
      {isTournamentCompleted && (
        <div className="surface border border-gold/40 bg-gold/5 rounded-3xl p-6 text-center space-y-4 animate-in fade-in duration-700 shadow-xl shadow-gold/5">
          <div className="inline-flex size-16 items-center justify-center rounded-full bg-gold/15 border border-gold/30 text-gold mx-auto animate-pulse">
            <Trophy className="size-8" />
          </div>
          <div>
            <h3 className="text-xl font-display font-black uppercase tracking-wider text-gold">
              🏆 TORNEO CONCLUSO
            </h3>
            <p className="text-sm font-black text-foreground mt-1">
              Campione: <span className="text-gold text-lg">{getTeamName(tournamentWinnerId)}</span>
            </p>
            <div className="inline-block bg-gold/25 border border-gold/40 text-gold font-black text-xs px-4 py-1.5 rounded-full mt-2.5">
              +20 PUNTI AL CAMPIONE / +10 PUNTI A TUTTI GLI ALTRI
            </div>

            {/* Team Specific Points Awarded View */}
            {!isAdmin && (
              <div className="mt-4 p-3 rounded-2xl bg-zinc-950/60 border border-border/40 max-w-xs mx-auto">
                <p className="text-[10px] uppercase text-muted-foreground font-bold tracking-wider">
                  Punti accreditati alla tua squadra:
                </p>
                <p className="text-xl font-black text-primary mt-1">
                  {currentUserId === tournamentWinnerId ? "+20 PUNTI 🏆" : "+10 PUNTI 👥"}
                </p>
                <p className="text-[9px] text-muted-foreground">
                  Registrati ed applicati in classifica generale.
                </p>
              </div>
            )}
          </div>

          {/* Leaderboard/Results table */}
          <div className="border-t border-border/10 pt-4 mt-2 max-w-md mx-auto">
            <h4 className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-3 flex items-center justify-center gap-1.5">
              <Users className="size-3.5" /> Classifica Sfida
            </h4>
            <div className="overflow-hidden rounded-xl border border-border/30 bg-zinc-950/40">
              <table className="w-full text-xs text-left">
                <thead className="bg-muted/10 text-muted-foreground uppercase text-[9px] tracking-wider border-b border-border/30">
                  <tr>
                    <th className="px-4 py-2">Squadra</th>
                    <th className="px-4 py-2">Risultato</th>
                    <th className="px-4 py-2 text-right">Punti</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/25">
                  <tr className="bg-gold/10 font-bold">
                    <td className="px-4 py-2.5 flex items-center gap-1">🏆 {getTeamName(tournamentWinnerId)}</td>
                    <td className="px-4 py-2.5 text-gold">Vincitore</td>
                    <td className="px-4 py-2.5 text-right font-black text-gold">20</td>
                  </tr>
                  {allTeams
                    ?.filter((t: any) => t.active !== false && t.id !== tournamentWinnerId)
                    .sort((a: any, b: any) => a.nome_squadra.localeCompare(b.nome_squadra))
                    .map((t: any) => (
                      <tr key={t.id} className="text-muted-foreground">
                        <td className="px-4 py-2">{t.nome_squadra}</td>
                        <td className="px-4 py-2">Partecipante</td>
                        <td className="px-4 py-2 text-right font-black text-foreground">10</td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Visual Bracket Tabellone */}
      <div className="space-y-3">
        <h3 className="text-xs font-bold uppercase tracking-widest text-muted-foreground px-1">
          Tabellone Torneo (Bracket)
        </h3>

        <div className="surface rounded-3xl border border-border/30 p-6 overflow-x-auto flex gap-8 items-start bg-[#070d1e]/80 shadow-lg min-h-[350px]">
          {Object.keys(rounds).map((roundStr) => {
            const r = parseInt(roundStr, 10);
            const roundMatches = rounds[r] || [];
            return (
              <div key={r} className="flex-1 min-w-[200px] flex flex-col justify-around h-full gap-4 self-stretch">
                <div className="text-center border-b border-border/10 pb-2 mb-2">
                  <p className="text-[10px] font-black uppercase tracking-widest text-primary">
                    {getRoundLabel(r)}
                  </p>
                </div>

                <div className="flex flex-col justify-around flex-grow gap-6">
                  {roundMatches.map((match: any) => {
                    const isCompleted = match.status === "completed";
                    const isReady = match.status === "ready";
                    const isT1Winner = isCompleted && match.winner_id === match.team1_id;
                    const isT2Winner = isCompleted && match.winner_id === match.team2_id;

                    const isT1Bye = match.round === 0 && match.team1_id && !match.team2_id;

                    return (
                      <div
                        key={match.id}
                        className={`flex flex-col rounded-xl border overflow-hidden transition-all bg-zinc-950/70 shadow-sm ${
                          isReady
                            ? "border-primary/40 ring-1 ring-primary/20"
                            : isCompleted
                            ? "border-success/20 opacity-80"
                            : "border-border/30 opacity-40"
                        }`}
                      >
                        {/* Team 1 Slot */}
                        <div
                          className={`flex items-center justify-between px-3 py-2.5 text-xs border-b border-border/20 ${
                            isT1Winner
                              ? "bg-success/5 text-success font-bold"
                              : isCompleted && match.team1_id
                              ? "line-through text-muted-foreground opacity-60"
                              : "text-foreground"
                          }`}
                        >
                          <span className="truncate max-w-[130px]">
                            {match.team1_id ? getTeamName(match.team1_id) : "?"}
                          </span>
                          {isT1Winner && (
                            <span className="text-[10px] font-bold text-success">
                              {match.is_special_bye ? "⚡ BYE" : isT1Bye ? "BYE" : "✓"}
                            </span>
                          )}
                        </div>

                        {/* Team 2 Slot */}
                        <div
                          className={`flex items-center justify-between px-3 py-2.5 text-xs ${
                            isT2Winner
                              ? "bg-success/5 text-success font-bold"
                              : isCompleted && match.team2_id
                              ? "line-through text-muted-foreground opacity-60"
                              : "text-foreground"
                          }`}
                        >
                          <span className={`truncate max-w-[130px] ${!match.team2_id ? "italic text-muted-foreground/60" : ""}`}>
                            {match.team2_id ? getTeamName(match.team2_id) : match.round > 0 ? "In attesa..." : "?"}
                          </span>
                          {isT2Winner && <span className="text-[10px] font-bold text-success">✓</span>}
                        </div>

                        {/* Special Bye Explanatory Footer Badge inside Match Card */}
                        {match.is_special_bye && (
                          <div className="bg-[#f59e0b]/10 border-t border-[#f59e0b]/20 px-3 py-1.5 text-[9px] text-[#f59e0b] font-black uppercase text-center tracking-wider">
                            ⚡ BYE — PASSAGGIO AUTOMATICO
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Complete Button (Only visible to admin once tournament is concluded) */}
      {isAdmin && isTournamentCompleted && (
        <button
          onClick={onComplete}
          disabled={completing}
          className="primary-gradient w-full py-4 rounded-2xl font-extrabold text-primary-foreground flex items-center justify-center gap-2 text-base active:scale-95 transition-all shadow-md shadow-primary/20 cursor-pointer disabled:opacity-50"
        >
          {completing ? (
            <><Loader2 className="size-5 animate-spin" /> Conclusione...</>
          ) : (
            <>Salva e Chiudi Sfida <Check className="size-5" /></>
          )}
        </button>
      )}
    </div>
  );
}
