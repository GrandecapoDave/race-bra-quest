import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useSession } from "@/hooks/useAuth";
import { gameReportQuery, reportStatusQuery, formatDuration } from "@/lib/race";
import {
  FileText,
  Trophy,
  Coins,
  Sparkles,
  Lock,
  Unlock,
  AlertTriangle,
  Loader2,
  CheckCircle2,
  Calendar,
  Clock,
  Shield,
  Zap,
  Skull,
  Share2,
  PhoneCall,
  History,
  ChevronDown,
  ChevronUp,
  Layers,
  Award
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/resoconto")({
  component: AdminResocontoPage,
});

function AdminResocontoPage() {
  const { user } = useSession();
  const queryClient = useQueryClient();
  const [selectedTeamId, setSelectedTeamId] = useState<string | "ALL">("ALL");
  const [openStages, setOpenStages] = useState<Record<string, boolean>>({});
  const [showPublishModal, setShowPublishModal] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);

  const reportStatus = useQuery(reportStatusQuery);
  const reportQuery = useQuery(gameReportQuery(user?.id));

  const isPublished = reportStatus.data?.is_published || reportQuery.data?.is_published || false;
  const publishedAt = reportStatus.data?.published_at || reportQuery.data?.published_at;
  const reportData = reportQuery.data?.report;

  function toggleStage(teamId: string, stageId: string) {
    const key = `${teamId}_${stageId}`;
    setOpenStages((prev) => ({ ...prev, [key]: !prev[key] }));
  }

  async function handlePublishReport() {
    setIsPublishing(true);
    try {
      const { data, error } = await supabase.rpc("publish_game_report", {
        p_admin_id: user?.id || "11111111-1111-1111-1111-111111111111",
      });

      if (error) {
        toast.error("Errore durante la pubblicazione: " + error.message);
      } else {
        toast.success("Resoconto Finale pubblicato ufficialmente! Ora è visibile a tutte le squadre.");
        setShowPublishModal(false);
        queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setIsPublishing(false);
    }
  }

  if (reportQuery.isLoading) {
    return (
      <div className="surface p-12 text-center rounded-2xl border border-border/40 space-y-4">
        <Loader2 className="size-8 animate-spin mx-auto text-primary" />
        <p className="text-sm font-black uppercase tracking-wider text-muted-foreground">
          Caricamento Resoconto Gara in corso...
        </p>
      </div>
    );
  }

  if (!reportData || !reportData.teams) {
    return (
      <div className="surface p-8 text-center rounded-2xl border border-border/40 space-y-3">
        <AlertTriangle className="size-8 mx-auto text-amber-500" />
        <p className="text-sm font-bold text-foreground">Nessun dato disponibile per il Resoconto Gara.</p>
      </div>
    );
  }

  const teams = reportData.teams || [];
  const stages = reportData.stages || [];
  const filteredTeams = selectedTeamId === "ALL" ? teams : teams.filter((t: any) => t.team_id === selectedTeamId);

  return (
    <div className="space-y-6 animate-in fade-in duration-300">
      {/* MODALE CONFERMA PUBBLICAZIONE */}
      {showPublishModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="surface max-w-lg w-full p-6 rounded-2xl border border-amber-500/40 bg-zinc-950 shadow-2xl space-y-5">
            <div className="flex items-center gap-3 text-amber-400">
              <AlertTriangle className="size-7 shrink-0" />
              <h3 className="text-lg font-display font-black uppercase tracking-wide">
                Pubblicazione Ufficiale Resoconto Finale
              </h3>
            </div>

            <div className="space-y-3 text-xs leading-relaxed text-zinc-300">
              <p className="font-bold text-sm text-foreground">
                ⚠️ Stai per rendere pubblico il Resoconto Finale della gara.
              </p>
              <p className="text-muted-foreground">
                Questa operazione eseguirà le seguenti azioni:
              </p>
              <ul className="space-y-1.5 list-disc list-inside bg-zinc-900/60 p-3.5 rounded-xl border border-zinc-800 text-zinc-300">
                <li><strong>Snapshot Definitivo:</strong> Congelerà i dati di gioco allo stato attuale in un report immutabile</li>
                <li><strong>Visibilità a tutte le squadre:</strong> Abiliterà la voce <em>"📊 Resoconto Finale"</em> nella sidebar di ogni squadra</li>
                <li><strong>Trasparenza Totale:</strong> Tutte le squadre potranno consultare il dettaglio completo di sfide, bonus, malus, switch e token di tutti i team</li>
                <li><strong>Immutabilità:</strong> Il Resoconto Pubblico non cambierà anche in caso di modifiche successive al database</li>
              </ul>
              <p className="text-amber-400/90 font-medium">
                Sei sicuro di voler pubblicare il Resoconto Finale adesso?
              </p>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setShowPublishModal(false)}
                disabled={isPublishing}
                className="px-4 py-2.5 rounded-xl border border-border/50 text-xs font-black uppercase tracking-wider text-muted-foreground hover:bg-zinc-900 transition-colors cursor-pointer disabled:opacity-50"
              >
                ANNULLA
              </button>
              <button
                type="button"
                onClick={handlePublishReport}
                disabled={isPublishing}
                className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-black font-black text-xs uppercase tracking-wider transition-all shadow-lg shadow-amber-500/20 flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {isPublishing ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Pubblicazione in corso...
                  </>
                ) : (
                  <>
                    <Sparkles className="size-4" />
                    PUBBLICA RESOCONTO FINALE
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* HEADER SECTION */}
      <div className="surface p-6 rounded-2xl border border-border/40 bg-zinc-950/60 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl font-display font-black tracking-wide uppercase text-foreground flex items-center gap-2">
              <FileText className="size-6 text-primary" />
              Resoconto Gara
            </h1>
            {isPublished ? (
              <span className="flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wider bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 px-3 py-1 rounded-full">
                <CheckCircle2 className="size-3.5" />
                🟢 PUBBLICATO — SNAPSHOT DEFINITIVO
              </span>
            ) : (
              <span className="flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wider bg-rose-500/10 border border-rose-500/30 text-rose-400 px-3 py-1 rounded-full animate-pulse">
                <span className="size-2 rounded-full bg-rose-500" />
                🔴 LIVE — AGGIORNAMENTO IN TEMPO REALE
              </span>
            )}
          </div>
          <p className="text-xs text-muted-foreground font-semibold mt-1">
            {isPublished
              ? `Pubblicato il ${new Date(publishedAt).toLocaleString("it-IT")} · I dati pubblici sono congelati.`
              : "Visibile esclusivamente all'Admin. Mostra la ricostruzione esatta di ogni punto, bonus, malus, switch e token."}
          </p>
        </div>

        <div>
          {isPublished ? (
            <div className="px-4 py-2 bg-emerald-950/40 border border-emerald-500/30 text-emerald-400 font-black text-xs uppercase tracking-wider rounded-xl flex items-center gap-2">
              <CheckCircle2 className="size-4" />
              Resoconto Pubblicato
            </div>
          ) : (
            <button
              onClick={() => setShowPublishModal(true)}
              className="px-5 py-3 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-black font-black text-xs uppercase tracking-wider rounded-xl transition-all shadow-lg shadow-amber-500/20 flex items-center gap-2 cursor-pointer"
            >
              <Sparkles className="size-4" />
              📢 PUBBLICA RESOCONTO FINALE
            </button>
          )}
        </div>
      </div>

      {/* TEAM SELECTOR FILTER */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-thin">
        <button
          onClick={() => setSelectedTeamId("ALL")}
          className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all whitespace-nowrap cursor-pointer ${
            selectedTeamId === "ALL"
              ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
              : "surface border border-border/40 text-muted-foreground hover:text-foreground"
          }`}
        >
          Tutte le Squadre ({teams.length})
        </button>
        {teams.map((t: any) => (
          <button
            key={t.team_id}
            onClick={() => setSelectedTeamId(t.team_id)}
            className={`px-3.5 py-2 rounded-xl text-xs font-extrabold uppercase tracking-wider transition-all flex items-center gap-1.5 whitespace-nowrap cursor-pointer ${
              selectedTeamId === t.team_id
                ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                : "surface border border-border/40 text-muted-foreground hover:text-foreground"
            }`}
          >
            <span
              className="size-4 rounded text-[10px] flex items-center justify-center"
              style={{ backgroundColor: (t.color ?? "#f97316") + "33" }}
            >
              {t.avatar_url ?? "🏳️"}
            </span>
            {t.nome_squadra || t.name}
          </button>
        ))}
      </div>

      {/* TEAMS REPORT CARDS */}
      <div className="space-y-8">
        {filteredTeams.map((team: any) => {
          return (
            <div
              key={team.team_id}
              className="surface rounded-2xl border border-border/50 bg-zinc-950/40 p-6 space-y-6 shadow-xl"
            >
              {/* TEAM MAIN HEADER */}
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-border/30 pb-5">
                <div className="flex items-center gap-4">
                  <div
                    className="size-14 rounded-2xl flex items-center justify-center text-3xl shadow-inner border"
                    style={{
                      backgroundColor: (team.color ?? "#f97316") + "22",
                      borderColor: (team.color ?? "#f97316") + "55",
                    }}
                  >
                    {team.avatar_url ?? "🏳️"}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black uppercase tracking-widest text-primary px-2.5 py-0.5 rounded-full bg-primary/10 border border-primary/20">
                        {team.position === 1 ? "🥇 1° Posto" : team.position === 2 ? "🥈 2° Posto" : team.position === 3 ? "🥉 3° Posto" : `#${team.position} in Gara`}
                      </span>
                      <h2 className="text-2xl font-display font-black text-foreground uppercase tracking-wide">
                        {team.nome_squadra || team.name}
                      </h2>
                    </div>
                    <p className="text-xs text-muted-foreground font-semibold mt-1">
                      {team.motto ? `"${team.motto}" · ` : ""}
                      Prove completate: {team.completed_challenges} · Tempo totale: {formatDuration(team.total_duration_seconds)}
                    </p>
                  </div>
                </div>

                {/* KPI SCORE BLOCKS */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                  <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                    <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Totali</span>
                    <p className="text-xl font-display font-black text-primary">{team.total_points} PT</p>
                  </div>
                  <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                    <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Sfide</span>
                    <p className="text-lg font-mono font-black text-emerald-400">{team.challenges_points} PT</p>
                  </div>
                  <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                    <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Cattiveria</span>
                    <p className={`text-lg font-mono font-black ${team.cattiveria_points >= 0 ? "text-purple-400" : "text-rose-400"}`}>
                      {team.cattiveria_points > 0 ? `+${team.cattiveria_points}` : team.cattiveria_points} 😈
                    </p>
                  </div>
                  <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                    <span className="text-[10px] uppercase font-bold text-muted-foreground">Saldo Token</span>
                    <p className="text-lg font-mono font-black text-amber-400">{team.token_balance} 🪙</p>
                  </div>
                </div>
              </div>

              {/* MOVIMENTO TOKEN SUMMARY */}
              <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/80 space-y-2">
                <h4 className="text-xs font-black uppercase tracking-wider text-zinc-400 flex items-center gap-1.5">
                  <Coins className="size-4 text-amber-400" /> Movimento Token
                </h4>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                  <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                    <p className="text-[9px] text-muted-foreground uppercase font-bold">Iniziali</p>
                    <p className="font-mono font-bold text-zinc-300">+{team.tokens_initial} TK</p>
                  </div>
                  <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                    <p className="text-[9px] text-muted-foreground uppercase font-bold">Guadagnati a Fine Tappa</p>
                    <p className="font-mono font-bold text-emerald-400">+{team.tokens_gained_rewards} TK</p>
                  </div>
                  <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                    <p className="text-[9px] text-muted-foreground uppercase font-bold">Spesi nel Marketplace</p>
                    <p className="font-mono font-bold text-rose-400">−{team.tokens_spent_marketplace} TK</p>
                  </div>
                  <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                    <p className="text-[9px] text-muted-foreground uppercase font-bold">Saldo Attuale</p>
                    <p className="font-mono font-black text-amber-400">{team.token_balance} TK</p>
                  </div>
                </div>
              </div>

              {/* DETTAGLIO PER TAPPA ACCORDION */}
              <div className="space-y-3">
                <h3 className="text-sm font-display font-black uppercase tracking-wider text-muted-foreground flex items-center gap-2">
                  <Layers className="size-4 text-primary" /> Dettaglio per Tappa
                </h3>

                <div className="space-y-3">
                  {team.stages_breakdown.map((sb: any) => {
                    const stageKey = `${team.team_id}_${sb.stage_id}`;
                    const isOpen = openStages[stageKey] ?? true; // default open

                    return (
                      <div
                        key={sb.stage_id}
                        className="bg-zinc-900/40 rounded-xl border border-zinc-800 overflow-hidden transition-all"
                      >
                        <button
                          type="button"
                          onClick={() => toggleStage(team.team_id, sb.stage_id)}
                          className="w-full p-4 flex items-center justify-between text-left hover:bg-zinc-900/80 transition-colors cursor-pointer"
                        >
                          <div className="flex items-center gap-3">
                            <span className="size-6 rounded-lg bg-zinc-800 text-xs font-black flex items-center justify-center text-primary">
                              {sb.stage_order}
                            </span>
                            <div>
                              <h4 className="font-bold text-sm text-foreground">
                                {sb.stage_name || `Tappa ${sb.stage_order}`}
                              </h4>
                              <p className="text-[10px] text-muted-foreground">
                                Stato: {sb.stage_status === "closed" ? "🔒 Chiusa" : "🟡 Aperta"} · Punti Tappa: {sb.stage_total_points} PT
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-4">
                            <span className="text-xs font-mono font-black text-primary">
                              +{sb.stage_total_points} PT
                            </span>
                            {isOpen ? (
                              <ChevronUp className="size-4 text-muted-foreground" />
                            ) : (
                              <ChevronDown className="size-4 text-muted-foreground" />
                            )}
                          </div>
                        </button>

                        {isOpen && (
                          <div className="p-4 pt-0 space-y-4 border-t border-zinc-800/60 divide-y divide-zinc-800/40">
                            {/* 1. SFIDE DELLA TAPPA */}
                            <div className="pt-3 space-y-2">
                              <h5 className="text-[11px] font-black uppercase tracking-wider text-zinc-400">
                                🎯 Prove e Sfide
                              </h5>
                              <div className="space-y-1.5">
                                {sb.challenges.map((c: any) => (
                                  <div
                                    key={c.challenge_id}
                                    className="flex items-center justify-between p-2 rounded-lg bg-zinc-950/40 border border-zinc-800 text-xs"
                                  >
                                    <div>
                                      <span className="font-bold text-foreground">
                                        {c.order}. {c.title}
                                      </span>
                                      <p className="text-[10px] text-muted-foreground">
                                        Tipo: {c.type} {c.completed_at ? `· Completata il ${new Date(c.completed_at).toLocaleTimeString("it-IT")}` : "· Non completata"}
                                      </p>
                                    </div>
                                    <div className="text-right">
                                      <span
                                        className={`font-mono font-bold ${
                                          c.points_awarded > 0 ? "text-emerald-400" : "text-zinc-500"
                                        }`}
                                      >
                                        +{c.points_awarded} PT
                                      </span>
                                    </div>
                                  </div>
                                ))}
                              </div>
                            </div>

                            {/* 2. BONUS UTILIZZATI */}
                            {sb.bonuses_used && sb.bonuses_used.length > 0 && (
                              <div className="pt-3 space-y-2">
                                <h5 className="text-[11px] font-black uppercase tracking-wider text-emerald-400">
                                  ✨ Bonus Acquistati / Utilizzati
                                </h5>
                                <div className="space-y-1.5">
                                  {sb.bonuses_used.map((b: any) => (
                                    <div
                                      key={b.transaction_id}
                                      className="flex items-center justify-between p-2 rounded-lg bg-zinc-950/40 border border-zinc-800 text-xs"
                                    >
                                      <div>
                                        <span className="font-bold text-foreground">{b.name}</span>
                                        <p className="text-[10px] text-muted-foreground">
                                          Costo: {b.cost_tokens} TK · Stato: {b.is_used ? "Utilizzato ✓" : "Non utilizzato"}
                                        </p>
                                      </div>
                                      <span className="text-[11px] font-mono font-bold text-purple-400">
                                        {b.cattiveria_delta} Cattiveria 😈
                                      </span>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}

                            {/* 3. MALUS UTILIZZATI (ATTACCO) */}
                            {sb.maluses_used && sb.maluses_used.length > 0 && (
                              <div className="pt-3 space-y-2">
                                <h5 className="text-[11px] font-black uppercase tracking-wider text-purple-400">
                                  ⚡ Malus Utilizzati contro Avversari
                                </h5>
                                <div className="space-y-1.5">
                                  {sb.maluses_used.map((m: any) => (
                                    <div
                                      key={m.transaction_id}
                                      className="flex items-center justify-between p-2 rounded-lg bg-zinc-950/40 border border-zinc-800 text-xs"
                                    >
                                      <div>
                                        <span className="font-bold text-foreground">{m.name}</span>
                                        <p className="text-[10px] text-muted-foreground">
                                          Bersaglio: <strong>{m.target_team_name}</strong> · Costo: {m.cost_tokens} TK
                                          {m.blocked_by_shield ? " (🛡️ Bloccato da Scudo)" : " (✓ Applicato)"}
                                        </p>
                                      </div>
                                      <div className="text-right">
                                        {m.direct_points_delta > 0 && (
                                          <span className="font-mono font-bold text-emerald-400 mr-2">
                                            +{m.direct_points_delta} PT
                                          </span>
                                        )}
                                        <span className="font-mono font-bold text-purple-400">
                                          +{m.cattiveria_delta} Cattiveria 😈
                                        </span>
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}

                            {/* 4. MALUS SUBITI */}
                            {sb.maluses_suffered && sb.maluses_suffered.length > 0 && (
                              <div className="pt-3 space-y-2">
                                <h5 className="text-[11px] font-black uppercase tracking-wider text-rose-400">
                                  🛡️ Malus Subiti da Altre Squadre
                                </h5>
                                <div className="space-y-1.5">
                                  {sb.maluses_suffered.map((ms: any) => (
                                    <div
                                      key={ms.transaction_id}
                                      className="flex items-center justify-between p-2 rounded-lg bg-zinc-950/40 border border-zinc-800 text-xs"
                                    >
                                      <div>
                                        <span className="font-bold text-foreground">{ms.name}</span>
                                        <p className="text-[10px] text-muted-foreground">
                                          Attaccante: <strong>{ms.attacker_team_name}</strong> ·{" "}
                                          {ms.blocked_by_shield ? "🛡️ Difeso con Scudo" : "Colpito"}
                                        </p>
                                      </div>
                                      {ms.points_lost > 0 && (
                                        <span className="font-mono font-bold text-rose-400">
                                          −{ms.points_lost} PT
                                        </span>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}

                            {/* 5. PUNTI CATTIVERIA DETTAGLIO */}
                            <div className="pt-3 space-y-2">
                              <h5 className="text-[11px] font-black uppercase tracking-wider text-purple-400">
                                😈 Punti Cattiveria Tappa ({sb.cattiveria_stage_total > 0 ? `+${sb.cattiveria_stage_total}` : sb.cattiveria_stage_total} PT)
                              </h5>
                              <div className="space-y-1 text-xs">
                                {sb.cattiveria_entries.map((ce: any) => (
                                  <div key={ce.id} className="flex justify-between text-muted-foreground">
                                    <span>• {ce.motivo}</span>
                                    <span className={`font-mono font-bold ${ce.punti >= 0 ? "text-purple-400" : "text-rose-400"}`}>
                                      {ce.punti > 0 ? `+${ce.punti}` : ce.punti} PT
                                    </span>
                                  </div>
                                ))}
                              </div>
                            </div>

                            {/* 6. FINE TAPPA REWARDS */}
                            {sb.stage_reward_tokens > 0 && (
                              <div className="pt-3 flex items-center justify-between text-xs font-bold text-amber-400">
                                <span>🪙 Ricompensa Posizionamento Chiusura Tappa</span>
                                <span className="font-mono">+{sb.stage_reward_tokens} Token</span>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* TIMELINE CRONOLOGICA */}
              <div className="space-y-3 pt-3 border-t border-border/30">
                <h3 className="text-sm font-display font-black uppercase tracking-wider text-muted-foreground flex items-center gap-2">
                  <History className="size-4 text-primary" /> Cronologia Eventi Squadra
                </h3>

                {team.timeline && team.timeline.length > 0 ? (
                  <div className="relative pl-6 space-y-3 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-zinc-800">
                    {team.timeline.map((event: any, idx: number) => {
                      let iconColor = "bg-primary text-primary-foreground";
                      if (event.category === "CHALLENGE") iconColor = "bg-emerald-500 text-black";
                      if (event.category === "MALUS_ATTACK") iconColor = "bg-purple-500 text-white";
                      if (event.category === "MALUS_VICTIM") iconColor = "bg-rose-500 text-white";
                      if (event.category === "STAGE_REWARD") iconColor = "bg-amber-500 text-black";
                      if (event.category === "JACKPOT") iconColor = "bg-cyan-500 text-black";

                      return (
                        <div key={idx} className="relative group">
                          <div
                            className={`absolute -left-6 top-1.5 size-3.5 rounded-full border-2 border-zinc-950 ${iconColor}`}
                          />
                          <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800/80 text-xs space-y-1">
                            <div className="flex items-center justify-between gap-2 flex-wrap">
                              <span className="font-extrabold text-foreground">{event.title}</span>
                              <span className="text-[10px] text-muted-foreground font-mono">
                                {new Date(event.timestamp).toLocaleTimeString("it-IT", {
                                  hour: "2-digit",
                                  minute: "2-digit",
                                  second: "2-digit",
                                })}
                              </span>
                            </div>
                            <p className="text-[11px] text-zinc-300">{event.details}</p>
                            <div className="flex gap-2 pt-0.5">
                              {event.points_delta !== 0 && (
                                <span
                                  className={`text-[9px] font-mono font-bold px-1.5 py-0.5 rounded ${
                                    event.points_delta > 0
                                      ? "bg-emerald-500/10 text-emerald-400"
                                      : "bg-rose-500/10 text-rose-400"
                                  }`}
                                >
                                  {event.points_delta > 0 ? `+${event.points_delta}` : event.points_delta} PT
                                </span>
                              )}
                              {event.cattiveria_delta !== 0 && (
                                <span
                                  className={`text-[9px] font-mono font-bold px-1.5 py-0.5 rounded ${
                                    event.cattiveria_delta > 0
                                      ? "bg-purple-500/10 text-purple-400"
                                      : "bg-rose-500/10 text-rose-400"
                                  }`}
                                >
                                  {event.cattiveria_delta > 0 ? `+${event.cattiveria_delta}` : event.cattiveria_delta} Cattiveria 😈
                                </span>
                              )}
                              {event.tokens_delta !== 0 && (
                                <span
                                  className={`text-[9px] font-mono font-bold px-1.5 py-0.5 rounded ${
                                    event.tokens_delta > 0
                                      ? "bg-amber-500/10 text-amber-400"
                                      : "bg-rose-500/10 text-rose-400"
                                  }`}
                                >
                                  {event.tokens_delta > 0 ? `+${event.tokens_delta}` : event.tokens_delta} Token 🪙
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <p className="text-xs text-muted-foreground italic">Nessun evento registrato nella cronologia.</p>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
