import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, Sparkles, TrendingUp, Calendar, Swords, HelpCircle, User } from "lucide-react";
import { useAdminContext } from "../admin";

export const Route = createFileRoute("/_authenticated/admin/jackpot")({
  head: () => ({
    meta: [
      { title: "Monitoraggio Jackpot — Regia" },
      { name: "description", content: "Monitoraggio in tempo reale del Jackpot della Regia." },
    ],
  }),
  component: AdminJackpotPage,
});

function AdminJackpotPage() {
  const { allTeams } = useAdminContext();
  const [selectedPlayId, setSelectedPlayId] = useState<string | null>(null);

  // Fetch all jackpot plays
  const { data: plays = [], isLoading: loadingPlays, error: playsError } = useQuery({
    queryKey: ["admin_jackpot_plays"],
    queryFn: async () => {
      const ADMIN_ID = "11111111-1111-1111-1111-111111111111";
      const { data, error } = await supabase.rpc("get_jackpot_plays", {
        p_admin_id: ADMIN_ID
      });
      if (error) throw error;
      return (data || []) as any[];
    },
    refetchInterval: 3000
  });

  if (loadingPlays || allTeams?.isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-3">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Caricamento console Jackpot della Regia...</p>
      </div>
    );
  }

  if (playsError || allTeams?.error) {
    return (
      <div className="surface p-6 rounded-2xl border border-destructive/20 bg-destructive/10 text-center max-w-md mx-auto mt-12 space-y-3">
        <p className="font-bold text-destructive">Errore nel caricamento dei dati</p>
        <p className="text-xs text-muted-foreground">
          Si è verificato un errore durante il caricamento della console Jackpot. Ricarica la pagina o riprova.
        </p>
      </div>
    );
  }

  // Active teams filter
  const activeTeamsList = allTeams?.data?.filter((t: any) => t.active !== false) ?? [];
  const totalTeamsCount = activeTeamsList.length;

  const playedTeamsCount = plays.length;
  const notPlayedTeamsCount = Math.max(0, totalTeamsCount - playedTeamsCount);

  const winsCount = plays.filter((p: any) => p.risultato === "vinta").length;
  const lossesCount = plays.filter((p: any) => p.risultato === "persa").length;

  const totalScommessi = plays.reduce((sum: number, p: any) => sum + p.puntata, 0);
  const totalVinti = plays.filter((p: any) => p.risultato === "vinta").reduce((sum: number, p: any) => sum + p.puntata, 0);
  const totalPersi = plays.filter((p: any) => p.risultato === "persa").reduce((sum: number, p: any) => sum + p.puntata, 0);

  // Helper to find team name
  const getTeamName = (teamId: string) => {
    const found = activeTeamsList.find((t: any) => t.id === teamId);
    return found ? found.nome_squadra : "Squadra Sconosciuta";
  };

  // Find selected play detail
  const selectedPlay = plays.find((p: any) => p.team_id === selectedPlayId);

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="surface p-5 rounded-2xl border border-border/40 bg-gradient-to-b from-[#1c0f16] to-[#0d070b]">
        <div className="flex items-center gap-3">
          <div className="size-12 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center text-primary text-xl">
            🎰
          </div>
          <div>
            <h1 className="text-xl font-display font-black uppercase tracking-wider text-foreground">
              SFIDA 5.3 — JACKPOT DELLA REGIA
            </h1>
            <p className="text-xs text-muted-foreground">
              Monitora in tempo reale le scommesse e le giocate alla slot machine delle squadre.
            </p>
          </div>
        </div>
      </div>

      {/* STATS BREAKDOWN GRID */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Teams played */}
        <div className="surface p-4 rounded-xl border border-border/30 bg-zinc-950/20 text-center space-y-1">
          <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Hanno Giocato</p>
          <p className="text-2xl font-black text-foreground">{playedTeamsCount} / {totalTeamsCount}</p>
          <p className="text-[9px] text-muted-foreground">Non giocato: {notPlayedTeamsCount}</p>
        </div>

        {/* Results */}
        <div className="surface p-4 rounded-xl border border-border/30 bg-zinc-950/20 text-center space-y-1">
          <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Risultati</p>
          <p className="text-2xl font-black text-foreground">🏆 {winsCount} <span className="text-xs text-muted-foreground">/</span> 💥 {lossesCount}</p>
          <p className="text-[9px] text-muted-foreground">Percentuale vittorie: {plays.length > 0 ? ((winsCount / plays.length) * 100).toFixed(1) : 0}%</p>
        </div>

        {/* Scommessi */}
        <div className="surface p-4 rounded-xl border border-border/30 bg-zinc-950/20 text-center space-y-1">
          <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Punti Scommessi</p>
          <p className="text-2xl font-black text-primary">{totalScommessi} PT</p>
          <p className="text-[9px] text-muted-foreground">Media per scommessa: {plays.length > 0 ? (totalScommessi / plays.length).toFixed(1) : 0} PT</p>
        </div>

        {/* Bilancio Regia */}
        <div className="surface p-4 rounded-xl border border-border/30 bg-zinc-950/20 text-center space-y-1">
          <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">Bilancio Punti</p>
          <p className={`text-2xl font-black ${totalVinti >= totalPersi ? "text-success" : "text-destructive"}`}>
            {totalVinti >= totalPersi ? `+${totalVinti - totalPersi}` : `-${totalPersi - totalVinti}`} PT
          </p>
          <p className="text-[9px] text-muted-foreground">Vinti: +{totalVinti} | Persi: -{totalPersi}</p>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6 items-start">
        {/* MAIN PLAYS TABLE */}
        <div className="surface border border-border/30 rounded-2xl p-5 lg:col-span-2 space-y-4">
          <h2 className="text-sm font-black uppercase tracking-wider text-foreground">Giocate registrate</h2>

          <div className="overflow-x-auto rounded-xl border border-border/30 bg-zinc-950/40">
            <table className="w-full text-xs text-left">
              <thead className="bg-muted/10 text-muted-foreground uppercase text-[9px] tracking-wider border-b border-border/30">
                <tr>
                  <th className="px-4 py-3">Squadra</th>
                  <th className="px-4 py-3">Stato</th>
                  <th className="px-4 py-3 text-right">Puntata</th>
                  <th className="px-4 py-3 text-center">Simboli</th>
                  <th className="px-4 py-3">Risultato</th>
                  <th className="px-4 py-3 text-right">Variazione</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/25">
                {activeTeamsList.map((team: any) => {
                  const play = plays.find((p: any) => p.team_id === team.id);
                  const isGiocata = !!play;
                  const isVinta = play?.risultato === "vinta";

                  return (
                    <tr
                      key={team.id}
                      onClick={() => isGiocata && setSelectedPlayId(team.id)}
                      className={`transition-colors ${isGiocata ? "hover:bg-zinc-900/50 cursor-pointer" : "opacity-60"} ${
                        selectedPlayId === team.id ? "bg-primary/5 text-primary" : ""
                      }`}
                    >
                      <td className="px-4 py-3 font-bold text-foreground">
                        {team.nome_squadra}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`px-2 py-0.5 rounded-full text-[9px] font-black uppercase border ${
                          isGiocata 
                            ? "bg-success/10 border-success/20 text-success" 
                            : "bg-muted/10 border-border/40 text-muted-foreground"
                        }`}>
                          {isGiocata ? "Giocata" : "Non giocata"}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right font-black">
                        {isGiocata ? `${play.puntata} PT` : "—"}
                      </td>
                      <td className="px-4 py-3 text-center text-sm font-semibold">
                        {isGiocata ? play.simboli.split(",").join(" ") : "—"}
                      </td>
                      <td className="px-4 py-3 font-black">
                        {isGiocata ? (
                          <span className={isVinta ? "text-success" : "text-destructive"}>
                            {isVinta ? "🏆 Vinta" : "❌ Persa"}
                          </span>
                        ) : "—"}
                      </td>
                      <td className={`px-4 py-3 text-right font-black ${isGiocata ? (isVinta ? "text-success" : "text-destructive") : ""}`}>
                        {isGiocata ? (isVinta ? `+${play.puntata}` : `-${play.puntata}`) : "—"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {/* PLAY DETAIL WIDGET */}
        <div className="surface border border-border/30 rounded-2xl p-5 space-y-5">
          <h2 className="text-sm font-black uppercase tracking-wider text-foreground">Dettaglio giocata</h2>

          {selectedPlay ? (
            <div className="space-y-4 animate-in fade-in duration-200">
              <div className="flex justify-center gap-3 py-2 bg-zinc-950/60 rounded-xl border border-border/20">
                {selectedPlay.simboli.split(",").map((sym: string, i: number) => (
                  <div
                    key={i}
                    className="size-14 flex items-center justify-center rounded-lg bg-zinc-900 border border-border/40 text-2xl select-none"
                  >
                    {sym}
                  </div>
                ))}
              </div>

              <div className="divide-y divide-border/10 text-xs space-y-2.5">
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground flex items-center gap-1.5"><User className="size-3.5" /> Squadra</span>
                  <span className="font-bold text-foreground">{getTeamName(selectedPlay.team_id)}</span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground flex items-center gap-1.5"><Sparkles className="size-3.5 text-primary" /> Risultato</span>
                  <span className={`font-black uppercase tracking-wider ${selectedPlay.risultato === "vinta" ? "text-success" : "text-destructive"}`}>
                    {selectedPlay.risultato === "vinta" ? "🏆 JACKPOT!" : "❌ SCONFITTA"}
                  </span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground flex items-center gap-1.5"><TrendingUp className="size-3.5" /> Puntata</span>
                  <span className="font-black text-foreground">{selectedPlay.puntata} PT</span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground">Variazione</span>
                  <span className={`font-black ${selectedPlay.risultato === "vinta" ? "text-success" : "text-destructive"}`}>
                    {selectedPlay.risultato === "vinta" ? `+${selectedPlay.puntata}` : `-${selectedPlay.puntata}`} PT
                  </span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground">Punteggio Precedente</span>
                  <span className="font-bold text-foreground">{selectedPlay.punteggio_precedente} PT</span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground">Punteggio Attuale</span>
                  <span className="font-black text-primary">{selectedPlay.punteggio_attuale} PT</span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-muted-foreground flex items-center gap-1.5"><Calendar className="size-3.5" /> Data/Ora</span>
                  <span className="text-foreground">
                    {new Date(selectedPlay.timestamp).toLocaleString("it-IT", {
                      day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit", second: "2-digit"
                    })}
                  </span>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-12 text-muted-foreground space-y-2">
              <HelpCircle className="size-8 mx-auto opacity-40 animate-pulse text-muted-foreground" />
              <p className="text-xs">Seleziona una squadra che ha giocato per visualizzare il report dettagliato della scommessa.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
