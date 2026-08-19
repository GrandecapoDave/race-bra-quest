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
  Award,
  Calculator,
  RefreshCw,
  Eye,
  Check,
  Flame,
  ArrowRight,
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
  const [showReopenModal, setShowReopenModal] = useState(false);
  const [isCalculating, setIsCalculating] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);
  const [isReopening, setIsReopening] = useState(false);

  const reportStatus = useQuery(reportStatusQuery);
  const reportQuery = useQuery(gameReportQuery(user?.id));

  const status = reportStatus.data?.status || reportQuery.data?.status || "NOT_CALCULATED";
  const isCalculated = status === "CALCULATED" || status === "PUBLISHED";
  const isPublished = status === "PUBLISHED";
  const calculatedAt = reportStatus.data?.calculated_at || reportQuery.data?.calculated_at;
  const publishedAt = reportStatus.data?.published_at || reportQuery.data?.published_at;
  const reportData = reportQuery.data?.report;

  function toggleStage(teamId: string, stageId: string) {
    const key = `${teamId}_${stageId}`;
    setOpenStages((prev) => ({ ...prev, [key]: !prev[key] }));
  }

  // Action: Calculate / Recalculate Final Results
  async function handleCalculateResults() {
    setIsCalculating(true);
    try {
      const adminId = user?.id || "11111111-1111-1111-1111-111111111111";
      const { data, error } = await supabase.rpc("calculate_final_game_results", {
        p_admin_id: adminId,
      });

      if (error) {
        toast.error("Errore durante il calcolo: " + error.message);
      } else {
        toast.success("Risultati finali calcolati con successo! La classifica è ora disponibile privatamente per la Regia.");
        await queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setIsCalculating(false);
    }
  }

  // Action: Publish Final Report
  async function handlePublishReport() {
    setIsPublishing(true);
    try {
      const adminId = user?.id || "11111111-1111-1111-1111-111111111111";
      const { data, error } = await supabase.rpc("publish_game_report", {
        p_admin_id: adminId,
      });

      if (error) {
        toast.error("Errore durante la pubblicazione: " + error.message);
      } else {
        toast.success("Resoconto Finale pubblicato ufficialmente! Ora è visibile a tutte le squadre.");
        setShowPublishModal(false);
        await queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setIsPublishing(false);
    }
  }

  // Action: Reopen Results for Admin Edits
  async function handleReopenResults() {
    setIsReopening(true);
    try {
      const adminId = user?.id || "11111111-1111-1111-1111-111111111111";
      const { data, error } = await supabase.rpc("admin_reopen_game_results", {
        p_admin_id: adminId,
      });

      if (error) {
        toast.error("Errore durante la riapertura: " + error.message);
      } else {
        toast.success("Risultati riaperti. Il resoconto è tornato in stato privato per la Regia.");
        setShowReopenModal(false);
        await queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setIsReopening(false);
    }
  }

  if (reportQuery.isLoading || reportStatus.isLoading) {
    return (
      <div className="surface p-12 text-center rounded-2xl border border-border/40 space-y-4">
        <Loader2 className="size-8 animate-spin mx-auto text-primary" />
        <p className="text-sm font-black uppercase tracking-wider text-muted-foreground">
          Caricamento Resoconto Gara in corso...
        </p>
      </div>
    );
  }

  const teams = reportData?.teams || [];
  const stages = reportData?.stages || [];
  const filteredTeams = selectedTeamId === "ALL" ? teams : teams.filter((t: any) => t.team_id === selectedTeamId);

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      {/* ===================================================================== */}
      {/* MODALE CONFERMA PUBBLICAZIONE */}
      {/* ===================================================================== */}
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
                ⚠️ Sei sicuro di voler pubblicare il resoconto finale?
              </p>
              <p className="text-muted-foreground">
                Una volta pubblicato, tutte le squadre potranno vedere il risultato completo della gara, inclusi punti, tempi, token, bonus, malus e classifica.
              </p>
              <ul className="space-y-1.5 list-disc list-inside bg-zinc-900/60 p-3.5 rounded-xl border border-zinc-800 text-zinc-300">
                <li><strong>Snapshot Definitivo:</strong> Congela il punteggio e il tempo calcolati sul server.</li>
                <li><strong>Trasparenza Totale:</strong> Tutte le squadre potranno consultare il dettaglio completo di tutti i team.</li>
                <li><strong>Accessibilità:</strong> La voce <em>"📊 Resoconto Finale"</em> sarà sbloccata per tutti.</li>
              </ul>
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
                className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-black font-black text-xs uppercase tracking-wider transition-all shadow-lg shadow-amber-500/20 flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {isPublishing ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Pubblicazione in corso...
                  </>
                ) : (
                  <>
                    <Sparkles className="size-4" />
                    PUBBLICA RISULTATO FINALE
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ===================================================================== */}
      {/* MODALE RIAPERTURA RISULTATI */}
      {/* ===================================================================== */}
      {showReopenModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="surface max-w-lg w-full p-6 rounded-2xl border border-rose-500/40 bg-zinc-950 shadow-2xl space-y-5">
            <div className="flex items-center gap-3 text-rose-400">
              <AlertTriangle className="size-7 shrink-0" />
              <h3 className="text-lg font-display font-black uppercase tracking-wide">
                Riapertura Risultati di Gara
              </h3>
            </div>

            <div className="space-y-3 text-xs leading-relaxed text-zinc-300">
              <p className="font-bold text-sm text-foreground">
                ⚠️ Vuoi riportare il resoconto in stato PRIVATO per la Regia?
              </p>
              <p className="text-muted-foreground">
                Le squadre non potranno più visualizzare il resoconto pubblico fino a nuova pubblicazione esplicita. Potrai correggere eventuali punteggi o prove e ricalcolare i risultati.
              </p>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setShowReopenModal(false)}
                disabled={isReopening}
                className="px-4 py-2.5 rounded-xl border border-border/50 text-xs font-black uppercase tracking-wider text-muted-foreground hover:bg-zinc-900 transition-colors cursor-pointer disabled:opacity-50"
              >
                ANNULLA
              </button>
              <button
                type="button"
                onClick={handleReopenResults}
                disabled={isReopening}
                className="px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-black text-xs uppercase tracking-wider transition-all shadow-lg shadow-rose-600/20 flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {isReopening ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Riapertura in corso...
                  </>
                ) : (
                  <>
                    <Lock className="size-4" />
                    CONFERMA RIAPERTURA
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ===================================================================== */}
      {/* SEZIONE 1: STATO GARA & AZIONI REGIA */}
      {/* ===================================================================== */}
      <div className="surface p-6 rounded-2xl border border-border/40 bg-zinc-950/60 space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-3 flex-wrap">
              <h1 className="text-2xl font-display font-black tracking-wide uppercase text-foreground flex items-center gap-2">
                <FileText className="size-6 text-primary" />
                Resoconto Gara & Chiusura
              </h1>

              {status === "PUBLISHED" ? (
                <span className="flex items-center gap-1.5 text-xs font-black uppercase tracking-wider bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 px-3.5 py-1 rounded-full">
                  <CheckCircle2 className="size-4" />
                  🟢 RESOCONTO PUBBLICATO (VISIBILE A TUTTI)
                </span>
              ) : status === "CALCULATED" ? (
                <span className="flex items-center gap-1.5 text-xs font-black uppercase tracking-wider bg-amber-500/10 border border-amber-500/30 text-amber-400 px-3.5 py-1 rounded-full">
                  <Eye className="size-4" />
                  🟡 RISULTATI CALCOLATI (PRIVATA ADMIN)
                </span>
              ) : (
                <span className="flex items-center gap-1.5 text-xs font-black uppercase tracking-wider bg-zinc-800 border border-zinc-700 text-zinc-400 px-3.5 py-1 rounded-full">
                  <Clock className="size-4" />
                  ⚪ GARA IN CORSO / NON CALCOLATO
                </span>
              )}
            </div>

            <p className="text-xs text-muted-foreground font-semibold mt-1">
              {status === "PUBLISHED"
                ? `Pubblicato ufficialmente il ${new Date(publishedAt).toLocaleString("it-IT")} · Tutte le squadre possono consultare la classifica e i dettagli.`
                : status === "CALCULATED"
                ? `Ultimo calcolo server: ${new Date(calculatedAt).toLocaleString("it-IT")} · Solo la Regia può vedere questa schermata.`
                : "La gara è in corso o i risultati finali non sono ancora stati calcolati dal server."}
            </p>
          </div>

          {/* ACTION BUTTONS */}
          <div className="flex items-center gap-3 flex-wrap">
            {status === "NOT_CALCULATED" && (
              <button
                type="button"
                onClick={handleCalculateResults}
                disabled={isCalculating}
                className="px-6 py-3 bg-primary hover:bg-primary/90 text-primary-foreground font-black text-xs uppercase tracking-wider rounded-xl transition-all shadow-lg shadow-primary/20 flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {isCalculating ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Calcolo in corso...
                  </>
                ) : (
                  <>
                    <Calculator className="size-4" />
                    🧮 CALCOLA RISULTATI FINALI
                  </>
                )}
              </button>
            )}

            {status === "CALCULATED" && (
              <>
                <button
                  type="button"
                  onClick={handleCalculateResults}
                  disabled={isCalculating}
                  className="px-4 py-2.5 bg-zinc-900 hover:bg-zinc-800 border border-zinc-700 text-zinc-200 font-black text-xs uppercase tracking-wider rounded-xl transition-all flex items-center gap-2 cursor-pointer disabled:opacity-50"
                >
                  <RefreshCw className={`size-3.5 ${isCalculating ? "animate-spin" : ""}`} />
                  RICALCOLA
                </button>

                <button
                  type="button"
                  onClick={() => setShowPublishModal(true)}
                  disabled={isPublishing}
                  className="px-6 py-3 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-black font-black text-xs uppercase tracking-wider rounded-xl transition-all shadow-lg shadow-amber-500/20 flex items-center gap-2 cursor-pointer disabled:opacity-50"
                >
                  <Trophy className="size-4" />
                  🏆 PUBBLICA RESOCONTO FINALE
                </button>
              </>
            )}

            {status === "PUBLISHED" && (
              <button
                type="button"
                onClick={() => setShowReopenModal(true)}
                className="px-4 py-2.5 bg-zinc-900/80 hover:bg-rose-950/40 border border-zinc-800 hover:border-rose-500/40 text-muted-foreground hover:text-rose-400 font-bold text-xs uppercase tracking-wider rounded-xl transition-all flex items-center gap-2 cursor-pointer"
              >
                <AlertTriangle className="size-3.5" />
                ⚠️ RIAPRI RISULTATI
              </button>
            )}
          </div>
        </div>

        {/* INFO CALLOUT */}
        <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/80 grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
          <div className="space-y-1">
            <span className="font-bold text-zinc-400 uppercase text-[10px] tracking-wider">Formula Punteggio Finale</span>
            <p className="font-mono text-zinc-300 text-[11px]">
              <strong className="text-foreground">PUNTI FINALI</strong> = Base + Bonus Tempo + Bonus Token
            </p>
          </div>
          <div className="space-y-1">
            <span className="font-bold text-zinc-400 uppercase text-[10px] tracking-wider">Bonus Tempo Dinamico</span>
            <p className="font-mono text-zinc-300 text-[11px]">
              1°: <span className="text-amber-400">+30</span> | 2°: <span className="text-amber-400">+25</span> | 3°: <span className="text-amber-400">+20</span> | 4°: +17 | 5°: +14 ...
            </p>
          </div>
          <div className="space-y-1">
            <span className="font-bold text-zinc-400 uppercase text-[10px] tracking-wider">Bonus Efficienza Token</span>
            <p className="font-mono text-zinc-300 text-[11px]">
              <span className="text-amber-400">+1 PT</span> ogni 5 Token rimasti (<code className="text-zinc-400">⌊Token/5⌋</code>)
            </p>
          </div>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* SEZIONE 2: CLASSIFICA FINALE (PRIVATA / UFFICIALE) */}
      {/* ===================================================================== */}
      {teams.length > 0 ? (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-display font-black uppercase tracking-wider text-foreground flex items-center gap-2">
              <Trophy className="size-5 text-gold" />
              {isPublished ? "Classifica Finale Ufficiale" : "Classifica Finale (Privata Regia)"}
            </h2>
            <span className="text-xs text-muted-foreground font-mono">
              {teams.length} Squadre Partecipanti
            </span>
          </div>

          {/* TABLE RANKING */}
          <div className="surface rounded-2xl border border-border/50 bg-zinc-950/40 overflow-hidden shadow-xl">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-border/40 bg-zinc-900/60 font-black text-muted-foreground uppercase text-[10px] tracking-wider">
                    <th className="py-3.5 px-4 text-center w-16">Pos</th>
                    <th className="py-3.5 px-4">Squadra</th>
                    <th className="py-3.5 px-3 text-center">Prove</th>
                    <th className="py-3.5 px-3 text-right">Punti Base</th>
                    <th className="py-3.5 px-3 text-center">Tempo Totale</th>
                    <th className="py-3.5 px-3 text-right">Bonus Tempo</th>
                    <th className="py-3.5 px-3 text-center">Token Rimasti</th>
                    <th className="py-3.5 px-3 text-right">Bonus Token</th>
                    <th className="py-3.5 px-4 text-right">PUNTI FINALI</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/20">
                  {teams.map((t: any) => {
                    const pos = t.final_rank ?? t.rank ?? t.position ?? 1;
                    const basePts = t.base_score ?? t.total_score_before_final_bonuses ?? t.challenges_points + (t.modifier_points ?? 0) + (t.cattiveria_points ?? 0);
                    const timeBonus = t.time_bonus ?? t.bonus_tempo ?? 0;
                    const tokenBonus = t.token_efficiency_bonus ?? t.bonus_token ?? Math.floor((t.token_balance ?? 50) / 5);
                    const finalScore = t.final_score ?? t.total_points ?? (basePts + timeBonus + tokenBonus);
                    const teamName = t.nome_squadra || t.name || t.team_name || "Squadra";

                    const isTop1 = pos === 1;
                    const isTop2 = pos === 2;
                    const isTop3 = pos === 3;

                    return (
                      <tr
                        key={t.team_id}
                        className={`hover:bg-zinc-900/40 transition-colors ${
                          isTop1
                            ? "bg-gold/5 font-semibold"
                            : isTop2
                            ? "bg-zinc-800/10"
                            : isTop3
                            ? "bg-amber-950/10"
                            : ""
                        }`}
                      >
                        {/* POS */}
                        <td className="py-3.5 px-4 text-center">
                          <span
                            className={`inline-flex items-center justify-center size-7 rounded-xl font-black text-xs ${
                              isTop1
                                ? "bg-gold text-black shadow-md shadow-gold/20"
                                : isTop2
                                ? "bg-zinc-400 text-black"
                                : isTop3
                                ? "bg-amber-700 text-white"
                                : "bg-zinc-800 text-zinc-300 font-mono"
                            }`}
                          >
                            {pos}
                          </span>
                        </td>

                        {/* TEAM */}
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-3">
                            <span
                              className="size-8 rounded-xl text-sm flex items-center justify-center shadow-inner border shrink-0"
                              style={{
                                backgroundColor: (t.color ?? "#f97316") + "22",
                                borderColor: (t.color ?? "#f97316") + "55",
                              }}
                            >
                              {t.avatar_url ?? "🏳️"}
                            </span>
                            <div>
                              <p className="font-extrabold text-sm text-foreground uppercase tracking-wide">
                                {teamName}
                              </p>
                              {t.motto && (
                                <p className="text-[10px] text-muted-foreground truncate max-w-[200px]">
                                  "{t.motto}"
                                </p>
                              )}
                            </div>
                          </div>
                        </td>

                        {/* COMPLETED CHALLENGES */}
                        <td className="py-3.5 px-3 text-center font-mono font-bold text-zinc-300">
                          {t.completed_challenges ?? 0} / 15
                        </td>

                        {/* BASE SCORE */}
                        <td className="py-3.5 px-3 text-right font-mono font-bold text-zinc-200">
                          {basePts} PT
                        </td>

                        {/* TOTAL TIME */}
                        <td className="py-3.5 px-3 text-center font-mono text-[11px] text-zinc-400">
                          <div>{formatDuration(t.total_time_seconds ?? t.total_duration_seconds ?? 0)}</div>
                          <span className="text-[9px] text-muted-foreground uppercase font-bold">
                            #{t.time_rank ?? pos} tempo
                          </span>
                        </td>

                        {/* TIME BONUS */}
                        <td className="py-3.5 px-3 text-right font-mono font-bold text-amber-400">
                          +{timeBonus} PT
                        </td>

                        {/* TOKENS */}
                        <td className="py-3.5 px-3 text-center font-mono font-bold text-amber-300">
                          {t.token_balance ?? 50} 🪙
                        </td>

                        {/* TOKEN BONUS */}
                        <td className="py-3.5 px-3 text-right font-mono font-bold text-emerald-400">
                          +{tokenBonus} PT
                        </td>

                        {/* FINAL SCORE */}
                        <td className="py-3.5 px-4 text-right">
                          <span className="text-base font-display font-black text-primary px-2.5 py-1 rounded-lg bg-primary/10 border border-primary/20">
                            {finalScore} PT
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : (
        <div className="surface p-8 text-center rounded-2xl border border-border/40 bg-zinc-950/40 space-y-3">
          <Calculator className="size-8 mx-auto text-primary" />
          <h3 className="font-display font-black text-foreground uppercase tracking-wide">
            Risultati non ancora calcolati
          </h3>
          <p className="text-xs text-muted-foreground max-w-md mx-auto">
            Premi il pulsante <strong>"🧮 CALCOLA RISULTATI FINALI"</strong> in alto per generare la classifica finale server-side con i bonus tempo e token.
          </p>
        </div>
      )}

      {/* ===================================================================== */}
      {/* SEZIONE 3: DETTAGLIO COMPLETO SQUADRE */}
      {/* ===================================================================== */}
      {teams.length > 0 && (
        <div className="space-y-6 pt-4 border-t border-border/40">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h2 className="text-lg font-display font-black uppercase tracking-wider text-foreground flex items-center gap-2">
                <Layers className="size-5 text-primary" /> Dettaglio Completo Squadre
              </h2>
              <p className="text-xs text-muted-foreground">
                Seleziona una squadra per visualizzare la cronologia, le prove per tappa, i bonus, malus e movimenti token.
              </p>
            </div>

            {/* TEAM SELECTOR TABS */}
            <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-thin">
              <button
                onClick={() => setSelectedTeamId("ALL")}
                className={`px-3.5 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all whitespace-nowrap cursor-pointer ${
                  selectedTeamId === "ALL"
                    ? "bg-primary text-primary-foreground shadow-md shadow-primary/20"
                    : "surface border border-border/40 text-muted-foreground hover:text-foreground"
                }`}
              >
                Tutte ({teams.length})
              </button>
              {teams.map((t: any) => {
                const tName = t.nome_squadra || t.name || t.team_name || "Squadra";
                return (
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
                    {tName}
                  </button>
                );
              })}
            </div>
          </div>

          {/* TEAMS ACCORDIONS */}
          <div className="space-y-8">
            {filteredTeams.map((team: any) => {
              const teamPos = team.final_rank ?? team.position ?? team.rank ?? 1;
              const teamName = team.nome_squadra || team.name || team.team_name || "Squadra";
              const initialTokens = team.tokens_initial ?? 50;
              const gainedTokens = team.tokens_gained_rewards ?? team.tokens_gained_stage_rewards ?? 0;
              const spentTokens = team.tokens_spent_marketplace ?? 0;
              const balanceTokens = team.token_balance ?? 50;
              const basePts = team.base_score ?? team.challenges_points + (team.modifier_points ?? 0) + (team.cattiveria_points ?? 0);
              const timeBonus = team.time_bonus ?? 0;
              const tokenBonus = team.token_efficiency_bonus ?? Math.floor(balanceTokens / 5);
              const finalScore = team.final_score ?? team.total_points ?? (basePts + timeBonus + tokenBonus);

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
                            {teamPos === 1 ? "🥇 1° Posto" : teamPos === 2 ? "🥈 2° Posto" : teamPos === 3 ? "🥉 3° Posto" : `#${teamPos} in Classifica`}
                          </span>
                          <h3 className="text-2xl font-display font-black text-foreground uppercase tracking-wide">
                            {teamName}
                          </h3>
                        </div>
                        <p className="text-xs text-muted-foreground font-semibold mt-1">
                          {team.motto ? `"${team.motto}" · ` : ""}
                          Prove: {team.completed_challenges ?? 0}/15 · Tempo: {formatDuration(team.total_time_seconds ?? team.total_duration_seconds ?? 0)} (#{team.time_rank ?? teamPos} tempo)
                        </p>
                      </div>
                    </div>

                    {/* SCORE BLOCKS */}
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                      <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                        <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Finali</span>
                        <p className="text-xl font-display font-black text-primary">{finalScore} PT</p>
                      </div>
                      <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                        <span className="text-[10px] uppercase font-bold text-muted-foreground">Punti Base</span>
                        <p className="text-lg font-mono font-black text-zinc-200">{basePts} PT</p>
                      </div>
                      <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                        <span className="text-[10px] uppercase font-bold text-muted-foreground">Bonus Tempo</span>
                        <p className="text-lg font-mono font-black text-amber-400">+{timeBonus} PT</p>
                      </div>
                      <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800 text-center">
                        <span className="text-[10px] uppercase font-bold text-muted-foreground">Bonus Token</span>
                        <p className="text-lg font-mono font-black text-emerald-400">+{tokenBonus} PT</p>
                      </div>
                    </div>
                  </div>

                  {/* MOVIMENTO TOKEN */}
                  <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/80 space-y-2">
                    <h4 className="text-xs font-black uppercase tracking-wider text-zinc-400 flex items-center gap-1.5">
                      <Coins className="size-4 text-amber-400" /> Movimento Token
                    </h4>
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                      <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                        <p className="text-[9px] text-muted-foreground uppercase font-bold">Iniziali</p>
                        <p className="font-mono font-bold text-zinc-300">+{initialTokens} TK</p>
                      </div>
                      <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                        <p className="text-[9px] text-muted-foreground uppercase font-bold">Guadagnati Fine Tappa</p>
                        <p className="font-mono font-bold text-emerald-400">+{gainedTokens} TK</p>
                      </div>
                      <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                        <p className="text-[9px] text-muted-foreground uppercase font-bold">Spesi nel Marketplace</p>
                        <p className="font-mono font-bold text-rose-400">−{spentTokens} TK</p>
                      </div>
                      <div className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800">
                        <p className="text-[9px] text-muted-foreground uppercase font-bold">Saldo Finale</p>
                        <p className="font-mono font-black text-amber-400">{balanceTokens} TK</p>
                      </div>
                    </div>
                  </div>

                  {/* DETTAGLIO TAPPE ACCORDION */}
                  <div className="space-y-3">
                    <h4 className="text-xs font-display font-black uppercase tracking-wider text-muted-foreground flex items-center gap-2">
                      <Layers className="size-4 text-primary" /> Dettaglio per Tappa
                    </h4>

                    <div className="space-y-3">
                      {(team.stages_breakdown ?? team.stages ?? []).map((sb: any) => {
                        const stageKey = `${team.team_id}_${sb.stage_id}`;
                        const isOpen = openStages[stageKey] ?? true;

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
                                    Punti Tappa: {sb.stage_total_points} PT
                                  </p>
                                </div>
                              </div>

                              <div className="flex items-center gap-4">
                                <span className="text-xs font-mono font-black text-primary">
                                  {sb.stage_total_points} PT
                                </span>
                                {isOpen ? <ChevronUp className="size-4 text-muted-foreground" /> : <ChevronDown className="size-4 text-muted-foreground" />}
                              </div>
                            </button>

                            {isOpen && (
                              <div className="p-4 pt-0 border-t border-zinc-800/60 space-y-4">
                                {/* SFIDE NELLA TAPPA */}
                                <div className="space-y-2 pt-3">
                                  <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground">
                                    Prove di Tappa
                                  </span>
                                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                                    {(sb.challenges ?? []).map((c: any) => (
                                      <div
                                        key={c.challenge_id}
                                        className={`p-3 rounded-lg border text-xs space-y-1 ${
                                          c.completed
                                            ? "bg-emerald-950/20 border-emerald-500/30 text-emerald-300"
                                            : "bg-zinc-950/40 border-zinc-800 text-muted-foreground"
                                        }`}
                                      >
                                        <div className="flex items-center justify-between">
                                          <span className="font-bold">{c.title}</span>
                                          {c.completed ? (
                                            <CheckCircle2 className="size-3.5 text-emerald-400" />
                                          ) : (
                                            <span className="text-[10px] text-zinc-500">Non completata</span>
                                          )}
                                        </div>
                                        <div className="flex items-center justify-between text-[10px] text-zinc-400 font-mono">
                                          <span>Max: {c.max_points} PT</span>
                                          <span className="font-bold text-foreground">
                                            Ottenuti: {c.points_awarded} PT
                                          </span>
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                </div>

                                {/* BONUS USATI */}
                                {(sb.bonuses_used ?? []).length > 0 && (
                                  <div className="space-y-2">
                                    <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                      <Shield className="size-3 text-emerald-400" /> Bonus Acquistati in Tappa
                                    </span>
                                    <div className="space-y-1.5">
                                      {(sb.bonuses_used ?? []).map((b: any) => (
                                        <div
                                          key={b.transaction_id}
                                          className="p-2.5 bg-emerald-950/10 border border-emerald-500/20 rounded-lg text-xs flex items-center justify-between"
                                        >
                                          <span className="font-semibold text-emerald-300">{b.name}</span>
                                          <span className="font-mono text-[11px] text-amber-400">-{b.cost_tokens} TK</span>
                                        </div>
                                      ))}
                                    </div>
                                  </div>
                                )}

                                {/* MALUS USATI (ATTACCO) */}
                                {(sb.maluses_used ?? []).length > 0 && (
                                  <div className="space-y-2">
                                    <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                      <Zap className="size-3 text-purple-400" /> Malus Sferrati contro Avversari
                                    </span>
                                    <div className="space-y-1.5">
                                      {(sb.maluses_used ?? []).map((m: any) => (
                                        <div
                                          key={m.transaction_id}
                                          className="p-2.5 bg-purple-950/10 border border-purple-500/20 rounded-lg text-xs flex items-center justify-between flex-wrap gap-2"
                                        >
                                          <div className="flex items-center gap-2">
                                            <span className="font-semibold text-purple-300">{m.name}</span>
                                            <ArrowRight className="size-3 text-muted-foreground" />
                                            <span className="font-bold text-foreground">{m.target_team_name}</span>
                                          </div>
                                          <div className="flex items-center gap-3 font-mono text-[11px]">
                                            <span className="text-amber-400">-{m.cost_tokens} TK</span>
                                            <span className="text-purple-400">+{m.cattiveria_delta} 😈</span>
                                          </div>
                                        </div>
                                      ))}
                                    </div>
                                  </div>
                                )}

                                {/* MALUS SUBITI (VITTIMA) */}
                                {(sb.maluses_suffered ?? []).length > 0 && (
                                  <div className="space-y-2">
                                    <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                      <Skull className="size-3 text-rose-400" /> Malus Subiti da Altre Squadre
                                    </span>
                                    <div className="space-y-1.5">
                                      {(sb.maluses_suffered ?? []).map((ms: any) => (
                                        <div
                                          key={ms.transaction_id}
                                          className="p-2.5 bg-rose-950/10 border border-rose-500/20 rounded-lg text-xs flex items-center justify-between"
                                        >
                                          <span className="font-semibold text-rose-300">{ms.name}</span>
                                          <span className="text-muted-foreground text-[11px]">
                                            Da: <strong className="text-foreground">{ms.attacker_team_name}</strong>
                                          </span>
                                        </div>
                                      ))}
                                    </div>
                                  </div>
                                )}

                                {/* REGISTRO CATTIVERIA */}
                                {(sb.cattiveria_entries ?? []).length > 0 && (
                                  <div className="space-y-2">
                                    <span className="text-[10px] uppercase font-black tracking-wider text-muted-foreground flex items-center gap-1">
                                      <Flame className="size-3 text-purple-400" /> Variazioni Punti Cattiveria
                                    </span>
                                    <div className="space-y-1">
                                      {(sb.cattiveria_entries ?? []).map((ce: any) => (
                                        <div
                                          key={ce.id}
                                          className="p-2 bg-zinc-950/60 rounded-lg border border-zinc-800 text-[11px] flex items-center justify-between"
                                        >
                                          <span className="text-zinc-300">{ce.motivo}</span>
                                          <span
                                            className={`font-mono font-bold ${
                                              ce.punti >= 0 ? "text-purple-400" : "text-rose-400"
                                            }`}
                                          >
                                            {ce.punti > 0 ? `+${ce.punti}` : ce.punti} 😈
                                          </span>
                                        </div>
                                      ))}
                                    </div>
                                  </div>
                                )}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
