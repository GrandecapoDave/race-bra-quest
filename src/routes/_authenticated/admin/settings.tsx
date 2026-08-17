import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useQueryClient } from "@tanstack/react-query";
import { useAdminContext } from "../admin";
import { useSession } from "@/hooks/useAuth";
import { Loader2, Lock, Unlock, CheckCircle2, Coins, ArrowRightLeft, AlertTriangle } from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/settings")({
  component: AdminSettingsPage,
});

function AdminSettingsPage() {
  const { stages, challenges } = useAdminContext();
  const { user } = useSession();
  const queryClient = useQueryClient();

  // Local state for challenge creation form
  const [chTitle, setChTitle] = useState("");
  const [chStage, setChStage] = useState("");
  const [chType, setChType] = useState("photo");
  const [chPoints, setChPoints] = useState(15);

  // Stage action loader and confirmation modal state
  const [processingStageId, setProcessingStageId] = useState<string | null>(null);
  const [stageToClose, setStageToClose] = useState<{ id: string; name: string; order: number } | null>(null);

  async function handleCreateChallenge() {
    if (!chStage || chTitle.trim().length < 3) {
      toast.error("Dati prova incompleti o non validi");
      return;
    }
    const order = ((challenges.data ?? []) as any[]).filter((c: any) => c.stage_id === chStage).length + 1;
    const { error } = await (supabase as any).from("challenges").insert({
      stage_id: chStage,
      titolo: chTitle.trim(),
      tipo_sfida: chType,
      punteggio_massimo: Math.max(0, Math.min(500, chPoints)),
      ordine: order,
    });
    if (error) {
      toast.error("Errore creazione prova: " + error.message);
      return;
    }
    setChTitle("");
    toast.success("Nuova prova aggiunta con successo!");
    queryClient.invalidateQueries();
  }

  async function executeCloseStage(stageId: string, stageName: string) {
    setProcessingStageId(stageId);
    try {
      const { data, error } = await supabase.rpc("close_stage", {
        p_stage_id: stageId,
        p_admin_id: user?.id || "11111111-1111-1111-1111-111111111111"
      });

      if (error) {
        toast.error("Errore durante la chiusura: " + error.message);
      } else {
        toast.success(`Tappa "${stageName}" conclusa ed archiviata! Token e Punti Cattiveria accreditati.`);
        setStageToClose(null);
        queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setProcessingStageId(null);
    }
  }

  async function handleReopenStage(stageId: string, stageName: string) {
    const confirmReopen = window.confirm(`ATTENZIONE: riaprire la tappa "${stageName}" revocherà i Token e i Punti Cattiveria di fine tappa accreditati alle squadre. Vuoi procedere?`);
    if (!confirmReopen) return;

    setProcessingStageId(stageId);
    try {
      const { data, error } = await supabase.rpc("reopen_stage", {
        p_stage_id: stageId,
        p_admin_id: user?.id || "11111111-1111-1111-1111-111111111111"
      });

      if (error) {
        toast.error("Errore durante la riapertura: " + error.message);
      } else {
        toast.success(`Tappa "${stageName}" riaperta con successo. Token e Punti Cattiveria di fine tappa revocati.`);
        queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setProcessingStageId(null);
    }
  }

  return (
    <div className="space-y-4">
      {/* MODALE CONFERMA CHIUSURA TAPPA */}
      {stageToClose && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="surface max-w-lg w-full p-6 rounded-2xl border border-amber-500/40 bg-zinc-950 shadow-2xl space-y-5">
            <div className="flex items-center gap-3 text-amber-400">
              <AlertTriangle className="size-7 shrink-0" />
              <h3 className="text-lg font-display font-black uppercase tracking-wide">
                Chiusura Ufficiale Tappa {stageToClose.order}
              </h3>
            </div>

            <div className="space-y-3 text-xs leading-relaxed text-zinc-300">
              <p className="font-bold text-sm text-foreground">
                ⚠️ Stai per chiudere definitivamente la tappa "{stageToClose.name}".
              </p>
              <p className="text-muted-foreground">
                La chiusura ufficiale eseguirà automaticamente le seguenti operazioni:
              </p>
              <ul className="space-y-1.5 list-disc list-inside bg-zinc-900/60 p-3.5 rounded-xl border border-zinc-800 text-zinc-300">
                <li><strong>Punti Cattiveria:</strong> calcolerà i Punti Cattiveria di fine tappa (regola <em>"Chi non è cattivo paga"</em>) in base ai Malus usati da ciascuna squadra</li>
                <li><strong>Token di fine tappa:</strong> assegnerà i Token previsti dal regolamento (1ª=15, 2ª=13, 3ª=11, 4ª=9, 5ª=7, 6ª=6, 7ª=5, 8ª=4)</li>
                <li><strong>Blocco tappa:</strong> archivierà la tappa e ne bloccherà le modifiche per i Team</li>
                <li><strong>Classifica Live:</strong> aggiornerà immediatamente la Classifica Live con i punteggi ricalcolati</li>
                <li><strong>Progressione:</strong> permetterà lo sblocco della tappa successiva per le squadre</li>
              </ul>
              <p className="text-amber-400/90 font-medium">
                Questa operazione non dovrebbe essere eseguita accidentalmente. Vuoi continuare?
              </p>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setStageToClose(null)}
                disabled={processingStageId === stageToClose.id}
                className="px-4 py-2.5 rounded-xl border border-border/50 text-xs font-black uppercase tracking-wider text-muted-foreground hover:bg-zinc-900 transition-colors cursor-pointer disabled:opacity-50"
              >
                ANNULLA
              </button>
              <button
                type="button"
                onClick={() => executeCloseStage(stageToClose.id, stageToClose.name)}
                disabled={processingStageId === stageToClose.id}
                className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-black font-black text-xs uppercase tracking-wider transition-all shadow-lg shadow-amber-500/20 flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {processingStageId === stageToClose.id ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Chiusura in corso...
                  </>
                ) : (
                  <>
                    <Lock className="size-4" />
                    CONFERMA CHIUSURA TAPPA
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* LIST OF STAGES & CHALLENGES */}
      <div className="space-y-4">
        <h2 className="text-xl font-display font-black uppercase tracking-wider text-muted-foreground">
          Riepilogo Tappe e Sfide della Gara
        </h2>
        {(stages.data ?? [])
          .sort((a: any, b: any) => a.ordine - b.ordine)
          .map((s: any) => {
            const stageChallenges = (challenges.data ?? [])
              .filter((c: any) => c.stage_id === s.id)
              .sort((a: any, b: any) => a.ordine - b.ordine);

            const isClosed = s.stato === "closed";

            return (
              <div key={s.id} className={`surface p-5 space-y-4 border transition-all ${
                isClosed ? "border-emerald-500/20 bg-emerald-950/5" : "border-border/40 bg-zinc-950/40"
              } rounded-2xl`}>
                <div className="flex items-start justify-between border-b border-border/30 pb-3 flex-wrap gap-2">
                  <div>
                    <h3 className="font-extrabold text-lg text-foreground uppercase tracking-wide">
                      {s.title || `Tappa ${s.ordine} - ${s.nome_tappa}`}
                    </h3>
                    <p className="text-xs text-muted-foreground font-semibold mt-1">
                      Luogo: {s.location || s.nome_tappa || "Non specificato"} · Ordine: {s.ordine}
                    </p>
                  </div>
                  <div>
                    {isClosed ? (
                      <span className="flex items-center gap-1 text-[10px] text-emerald-400 font-black uppercase tracking-wider bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-1 rounded-full">
                        <CheckCircle2 className="size-3.5" />
                        🟢 CHIUSA
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-[10px] text-yellow-400 font-black uppercase tracking-wider bg-yellow-500/10 border border-yellow-500/20 px-2.5 py-1 rounded-full">
                        <Unlock className="size-3.5" />
                        🟡 APERTA
                      </span>
                    )}
                  </div>
                </div>

                {stageChallenges.length === 0 ? (
                  <p className="text-xs text-muted-foreground font-semibold italic">Nessuna prova associata a questa tappa.</p>
                ) : (
                  <div className="divide-y divide-border/20">
                    {stageChallenges.map((c: any, index: number) => (
                      <div key={c.id} className="flex items-center justify-between py-3">
                        <div>
                          <h4 className="font-extrabold text-sm text-foreground">
                            {index + 1}. {c.titolo}
                          </h4>
                          <p className="text-[10px] text-muted-foreground font-semibold uppercase tracking-wider mt-0.5">
                            Tipo: {c.tipo_sfida} · Ordine: {c.ordine}
                          </p>
                        </div>
                        <span className="text-xs font-bold bg-primary/10 text-primary px-2.5 py-1 rounded-lg">
                          {c.punteggio_massimo} PT max
                        </span>
                      </div>
                    ))}
                  </div>
                )}

                {/* STAGE CLOSURE / REWARD PANEL */}
                <div className="pt-4 border-t border-border/30 space-y-4">
                  {isClosed && (
                    <div className="bg-zinc-900/60 p-4 rounded-xl border border-emerald-500/30 space-y-4">
                      <div className="flex items-center justify-between flex-wrap gap-2">
                        <div className="flex items-center gap-2 text-emerald-400 font-black text-xs uppercase tracking-wider">
                          <Lock className="size-4" />
                          🔒 TAPPA CHIUSA
                        </div>
                        <span className="text-[10px] text-zinc-400">
                          Data chiusura: {s.outcome?.closed_at ? new Date(s.outcome.closed_at).toLocaleString("it-IT") : "Archiviata"}
                        </span>
                      </div>

                      {/* Status KPI badges */}
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                        <div className="bg-zinc-950/60 p-2.5 rounded-lg border border-zinc-800 text-center">
                          <p className="text-[9px] text-muted-foreground uppercase font-bold">Squadre elaborate</p>
                          <p className="text-sm font-black text-foreground">{s.outcome?.ranking?.length ?? s.outcome?.teams_processed ?? 0}</p>
                        </div>
                        <div className="bg-zinc-950/60 p-2.5 rounded-lg border border-zinc-800 text-center">
                          <p className="text-[9px] text-muted-foreground uppercase font-bold">Token assegnati</p>
                          <p className="text-sm font-black text-emerald-400">✓ Completato</p>
                        </div>
                        <div className="bg-zinc-950/60 p-2.5 rounded-lg border border-zinc-800 text-center">
                          <p className="text-[9px] text-muted-foreground uppercase font-bold">Punti Cattiveria</p>
                          <p className="text-sm font-black text-purple-400">✓ Calcolati</p>
                        </div>
                        <div className="bg-zinc-950/60 p-2.5 rounded-lg border border-zinc-800 text-center">
                          <p className="text-[9px] text-muted-foreground uppercase font-bold">Classifica Live</p>
                          <p className="text-sm font-black text-amber-400">✓ Aggiornata</p>
                        </div>
                      </div>

                      {s.outcome?.ranking && (
                        <div className="space-y-2 pt-2 border-t border-zinc-800/60">
                          <h4 className="text-xs font-black uppercase tracking-wider text-zinc-300 flex items-center gap-1.5">
                            <Coins className="size-4 text-yellow-500" /> Ricompense Token e Classifica Tappa
                          </h4>
                          <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse text-xs">
                              <thead>
                                <tr className="border-b border-zinc-800 text-zinc-500 font-bold uppercase tracking-wider text-[9px] pb-1">
                                  <th className="pb-1.5 pr-2">Pos.</th>
                                  <th className="pb-1.5 pr-2">Squadra</th>
                                  <th className="pb-1.5 pr-2 text-right">Ricompensa Token</th>
                                  <th className="pb-1.5 pr-2 text-right">Saldo Token</th>
                                  <th className="pb-1.5 text-right">Stato</th>
                                </tr>
                              </thead>
                              <tbody className="divide-y divide-zinc-800/40">
                                {s.outcome.ranking.map((row: any) => (
                                  <tr key={row.team_id} className="hover:bg-zinc-950/20">
                                    <td className="py-2 pr-2 font-bold text-zinc-400">
                                      {row.position === 1 ? "🥇" : row.position === 2 ? "🥈" : row.position === 3 ? "🥉" : `${row.position}°`}
                                    </td>
                                    <td className="py-2 pr-2 font-extrabold text-foreground flex items-center gap-1.5">
                                      <span
                                        className="size-5 rounded text-xs flex items-center justify-center"
                                        style={{ backgroundColor: (row.color ?? "#f97316") + "22", border: `1px solid ${row.color ?? "#f97316"}44` }}
                                      >
                                        {row.avatar_url ?? "🏳️"}
                                      </span>
                                      {row.nome_squadra}
                                    </td>
                                    <td className="py-2 pr-2 text-right text-emerald-400 font-mono font-black">
                                      +{row.reward} TK
                                    </td>
                                    <td className="py-2 pr-2 text-right text-zinc-400 font-mono font-medium">
                                      {row.oldBalance} → {row.newBalance}
                                    </td>
                                    <td className="py-2 text-right font-bold">
                                      {row.capped ? (
                                        <span className="text-[9px] text-amber-500 bg-amber-500/10 px-1.5 py-0.5 rounded border border-amber-500/20 uppercase tracking-widest font-black">
                                          Cap 80
                                        </span>
                                      ) : (
                                        <span className="text-[9px] text-zinc-500 font-medium">OK</span>
                                      )}
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        </div>
                      )}
                    </div>
                  )}

                  <div className="flex justify-between items-center gap-4 flex-wrap">
                    <p className="text-[10px] text-zinc-400 max-w-md leading-relaxed">
                      {isClosed 
                        ? "La tappa è archiviata e i risultati sono finalizzati. Non è possibile modificare le prove o i punteggi se non previa riapertura."
                        : "La chiusura calcola il posizionamento in tempo reale, assegna i Token di tappa e i Punti Cattiveria (regola 'Chi non è cattivo paga'), archiviando la tappa."
                      }
                    </p>

                    <div className="flex gap-2">
                      {isClosed ? (
                        <button
                          onClick={() => handleReopenStage(s.id, s.title || s.nome_tappa)}
                          disabled={processingStageId === s.id}
                          className="px-4 py-2 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-400 font-black text-xs uppercase tracking-wider rounded-xl transition-all flex items-center gap-1.5 disabled:opacity-50 cursor-pointer"
                        >
                          {processingStageId === s.id ? (
                            <Loader2 className="size-3.5 animate-spin" />
                          ) : (
                            <ArrowRightLeft className="size-3.5" />
                          )}
                          Riapri Tappa
                        </button>
                      ) : (
                        <button
                          onClick={() => setStageToClose({ id: s.id, name: s.title || s.nome_tappa, order: s.ordine })}
                          disabled={processingStageId === s.id || stageChallenges.length === 0}
                          className="px-4 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-black font-black text-xs uppercase tracking-wider rounded-xl transition-all shadow-md shadow-amber-500/20 flex items-center gap-1.5 disabled:opacity-50 cursor-pointer"
                        >
                          {processingStageId === s.id ? (
                            <Loader2 className="size-4 animate-spin" />
                          ) : (
                            <Lock className="size-4" />
                          )}
                          🔒 CHIUDI TAPPA
                        </button>
                      )}
                  </div>
                </div>
              </div>
              </div>
            );
          })}
      </div>

      {/* SEZIONE CREAZIONE SFIDA */}
      <div className="surface p-6 border border-border/40 bg-zinc-950/60 rounded-2xl space-y-4">
        <h3 className="text-md font-extrabold text-foreground uppercase tracking-wider border-b border-border/20 pb-2">
          ➕ Aggiungi Nuova Prova (Sfida)
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-zinc-400 uppercase">Titolo Prova</label>
            <input
              type="text"
              value={chTitle}
              onChange={(e) => setChTitle(e.target.value)}
              placeholder="Esempio: Foto ufficiale, Cerca la chiave..."
              className="bg-zinc-900/80 border border-border/40 w-full px-4 py-2 rounded-xl text-sm focus:outline-none focus:border-primary text-foreground"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-bold text-zinc-400 uppercase">Associa a Tappa</label>
            <select
              value={chStage}
              onChange={(e) => setChStage(e.target.value)}
              className="bg-zinc-900/80 border border-border/40 w-full px-4 py-2 rounded-xl text-sm focus:outline-none focus:border-primary text-foreground"
            >
              <option value="">Seleziona una tappa...</option>
              {(stages.data ?? []).map((s: any) => (
                <option key={s.id} value={s.id}>
                  Tappa {s.ordine} - {s.nome_tappa}
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-bold text-zinc-400 uppercase">Tipo Sfida</label>
            <select
              value={chType}
              onChange={(e) => setChType(e.target.value)}
              className="bg-zinc-900/80 border border-border/40 w-full px-4 py-2 rounded-xl text-sm focus:outline-none focus:border-primary text-foreground"
            >
              <option value="photo">Foto</option>
              <option value="quiz">Quiz</option>
              <option value="banca">La Banca</option>
              <option value="social">Missione Social</option>
              <option value="codice">Il Codice Segreto</option>
              <option value="living_poster">Locandina Vivente</option>
              <option value="emoji_movies">Emoji Film</option>
              <option value="team_setup">Creazione Squadra</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-zinc-400 uppercase">Difficoltà</label>
              <select
                onChange={(e) => {
                  const diff = e.target.value;
                  if (diff === "very_low") setChPoints(5);
                  else if (diff === "low") setChPoints(10);
                  else if (diff === "medium") setChPoints(15);
                  else if (diff === "medium_high") setChPoints(20);
                  else if (diff === "high") setChPoints(25);
                }}
                defaultValue="medium"
                className="bg-zinc-900/80 border border-border/40 w-full px-4 py-2 rounded-xl text-sm focus:outline-none focus:border-primary text-foreground"
              >
                <option value="very_low">Molto Bassa (5 PT)</option>
                <option value="low">Bassa (10 PT)</option>
                <option value="medium">Media (15 PT)</option>
                <option value="medium_high">Media-Alta (20 PT)</option>
                <option value="high">Alta (25 PT)</option>
              </select>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-zinc-400 uppercase">Punti Challenge</label>
              <input
                type="number"
                required
                min="0"
                max="100"
                value={chPoints}
                onChange={(e) => setChPoints(Math.max(0, parseInt(e.target.value) || 0))}
                className="bg-zinc-900/80 border border-border/40 w-full px-4 py-2 rounded-xl text-sm font-bold text-primary focus:outline-none focus:border-primary text-foreground"
              />
            </div>
          </div>
        </div>

        <div className="flex justify-end pt-2">
          <button
            onClick={handleCreateChallenge}
            className="primary-gradient px-6 py-2.5 rounded-xl font-extrabold text-sm text-primary-foreground flex items-center gap-2 cursor-pointer hover:scale-[1.02] active:scale-95 transition-all"
          >
            Crea Nuova Prova
          </button>
        </div>
      </div>
    </div>
  );
}
