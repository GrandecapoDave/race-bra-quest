import { createFileRoute } from "@tanstack/react-router";
import { useAdminContext } from "../admin";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useQueryClient } from "@tanstack/react-query";
import {
  Loader2,
  Sparkles,
  Trash2,
  Lock,
  Film,
  CheckCircle,
  XCircle,
  Coins,
  Plus,
  Minus,
} from "lucide-react";
import { formatDuration } from "@/lib/race";

export const Route = createFileRoute("/_authenticated/admin/teams")({
  component: AdminTeamsPage,
});

const MOVIES = [
  { index: 1, emojis: "🦁👑", title: "Il Re Leone", letter: "V" },
  { index: 2, emojis: "🚢🥶", title: "Titanic", letter: "I" },
  { index: 3, emojis: "🍫🏭", title: "La Fabbrica di Cioccolato", letter: "T" },
  { index: 4, emojis: "🦕🌋", title: "Jurassic Park", letter: "T" },
  { index: 5, emojis: "🤡🎈", title: "It", letter: "O" },
  { index: 6, emojis: "🧙‍♂️💍", title: "Il Signore degli Anelli", letter: "R" },
  { index: 7, emojis: "🚀🪐", title: "Interstellar", letter: "I" },
  { index: 8, emojis: "⚡👓", title: "Harry Potter", letter: "A" }
];

function AdminTeamsPage() {
  const {
    allTeams,
    allScores,
    allProgress,
    challenges,
    allSubmissions,
    stages,
    allAnswers,
    quizQuestions,
    allEmojiMovies,
    selectedTeamId,
    setSelectedTeamId,
  } = useAdminContext();

  const queryClient = useQueryClient();

  // Form states locally managed to declutter Layout route
  const [teamName, setTeamName] = useState("");
  const [teamUser, setTeamUser] = useState("");
  const [teamPass, setTeamPass] = useState("");

  const [editName, setEditName] = useState("");
  const [editPass, setEditPass] = useState("");
  const [editingTeamId, setEditingTeamId] = useState<string | null>(null);

  const [adjPoints, setAdjPoints] = useState("");
  const [adjReason, setAdjReason] = useState("");
  const [isAdjusting, setIsAdjusting] = useState(false);

  // Token management state
  const [tokenTargetId, setTokenTargetId] = useState<string | null>(null); // null = all teams
  const [tokenAmount, setTokenAmount] = useState("");
  const [tokenReason, setTokenReason] = useState("");
  const [isAdjustingTokens, setIsAdjustingTokens] = useState(false);

  // CRUD handlers matching original functions
  async function handleCreateTeam(e: React.FormEvent) {
    e.preventDefault();
    if (teamName.trim().length < 2 || teamUser.trim().length < 3 || teamPass.trim().length < 6) {
      toast.error("Compila tutti i campi correttamente (Password min. 6 caratteri)");
      return;
    }
    const { error } = await (supabase as any).from("teams").insert({
      nome_squadra: teamName.trim(),
      username: teamUser.trim().toLowerCase(),
      password_plain: teamPass.trim(),
    });
    if (error) {
      toast.error("Errore: " + error.message);
      return;
    }
    setTeamName("");
    setTeamUser("");
    setTeamPass("");
    toast.success("Squadra creata con successo!");
    queryClient.invalidateQueries();
  }

  async function handleDeleteTeam(id: string) {
    if (!confirm("Sei sicuro di voler eliminare questa squadra? Verranno eliminati tutti i suoi progressi e sottomissioni.")) return;
    const { error } = await (supabase as any).from("teams").delete().eq("id", id);
    if (error) {
      toast.error("Errore: " + error.message);
      return;
    }
    toast.success("Squadra eliminata");
    queryClient.invalidateQueries();
  }

  async function handleUpdateTeam(id: string) {
    if (editName.trim().length < 2) {
      toast.error("Nome squadra non valido");
      return;
    }
    const updatePayload: any = { nome_squadra: editName.trim() };
    if (editPass.trim().length >= 6) {
      updatePayload.password_plain = editPass.trim();
    }
    const { error } = await (supabase as any).from("teams").update(updatePayload).eq("id", id);
    if (error) {
      toast.error(error.message);
      return;
    }
    setEditingTeamId(null);
    setEditPass("");
    toast.success("Squadra aggiornata con successo");
    queryClient.invalidateQueries();
  }

  async function toggleTeamActive(id: string, currentActive: boolean) {
    const { error } = await (supabase as any)
      .from("teams")
      .update({ active: !currentActive })
      .eq("id", id);
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success(`Squadra ${!currentActive ? "attivata" : "disattivata"}`);
    queryClient.invalidateQueries();
  }

  async function handleAdjustPoints(e: React.FormEvent) {
    e.preventDefault();
    const pointsNum = parseInt(adjPoints);
    if (isNaN(pointsNum)) {
      toast.error("Inserisci un punteggio valido");
      return;
    }
    if (adjReason.trim().length < 3) {
      toast.error("Inserisci una motivazione valida");
      return;
    }
    setIsAdjusting(true);
    try {
      const { error } = await (supabase as any).from("scores").insert({
        team_id: selectedTeamId,
        punti: pointsNum,
        motivo: adjReason.trim(),
      });
      if (error) throw error;
      toast.success("Punteggio regolato con successo");
      setAdjPoints("");
      setAdjReason("");
      queryClient.invalidateQueries();
    } catch (err: any) {
      toast.error("Errore regolazione: " + err.message);
    } finally {
      setIsAdjusting(false);
    }
  }

  async function handleDeleteScore(scoreId: string) {
    if (!confirm("Sei sicuro di voler eliminare questa regolazione manuale?")) return;
    const { error } = await (supabase as any).from("scores").delete().eq("id", scoreId);
    if (error) {
      toast.error("Errore eliminazione score: " + error.message);
      return;
    }
    toast.success("Regolazione eliminata");
    queryClient.invalidateQueries();
  }

  // Token management handler
  async function handleAdjustTokens(e: React.FormEvent, teamId: string | null) {
    e.preventDefault();
    const amount = parseInt(tokenAmount);
    if (isNaN(amount) || amount === 0) {
      toast.error("Inserisci una quantità token valida (diversa da 0)");
      return;
    }
    setIsAdjustingTokens(true);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";

      const teamsToUpdate = teamId
        ? [(allTeams.data ?? []).find((t: any) => t.id === teamId)].filter(Boolean)
        : (allTeams.data ?? []).filter((t: any) => t.active);

      const errors: string[] = [];
      for (const team of teamsToUpdate) {
        const { error } = await supabase.rpc("admin_adjust_team_tokens", {
          p_team_id: team.id,
          p_amount: amount,
          p_reason: tokenReason.trim() || undefined,
          p_admin_id: adminId,
        });
        if (error) {
          errors.push(`${team.nome_squadra}: ${error.message}`);
        } else {
          await (supabase as any).from("marketplace_transactions").insert({
            team_id: team.id,
            marketplace_item_id: "admin_token_adjust",
            costo_token: amount,
            stato: "completed",
            dettagli: {
              reason: tokenReason.trim() || "Regolazione manuale Regia",
              amount: amount,
              type: amount > 0 ? "reward" : "penalty",
            },
          });
        }
      }

      if (errors.length > 0) {
        toast.error("Errori: " + errors.join(", "));
      } else {
        const label = teamId ? (allTeams.data ?? []).find((t: any) => t.id === teamId)?.nome_squadra : "tutte le squadre attive";
        const direction = amount > 0 ? "aggiunti" : "rimossi";
        toast.success(`${Math.abs(amount)} token ${direction} a ${label}!`);
        setTokenAmount("");
        setTokenReason("");
        setTokenTargetId(null);
        queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error("Errore: " + err.message);
    } finally {
      setIsAdjustingTokens(false);
    }
  }

  return (
    <div className="space-y-4">
      {selectedTeamId ? (
        <div className="space-y-6">
          {/* BACK BUTTON & HEADER */}
          <div className="flex items-center gap-4">
            <button
              onClick={() => setSelectedTeamId(null)}
              className="px-3 py-1.5 border border-border rounded-lg text-xs font-bold hover:bg-secondary/65 transition-colors cursor-pointer"
            >
              ← Torna alla lista
            </button>
            <div>
              <h2 className="text-2xl font-display font-extrabold uppercase tracking-wide">
                Storico Attività Squadra
              </h2>
            </div>
          </div>

          {/* TEAM INFORMATION CARD */}
          {(() => {
            const team = (allTeams.data ?? []).find((t: any) => t.id === selectedTeamId);
            if (!team) return <p className="surface p-4 text-sm">Squadra non trovata.</p>;
            return (
              <div className="surface p-5 space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div>
                    <h3 className="text-xl font-extrabold flex items-center gap-2">
                      <span>{team.nome_squadra}</span>
                      <span className={`text-xs font-extrabold px-2 py-0.5 rounded ${
                        team.active ? "bg-success/20 text-success" : "bg-destructive/20 text-destructive"
                      }`}>
                        {team.active ? "Attivo" : "Disattivato"}
                      </span>
                    </h3>
                    <p className="text-xs text-muted-foreground mt-1">
                      Username: <span className="font-mono">{team.username}</span> · Password (in chiaro): <span className="font-mono">{team.password_plain}</span>
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      Data Creazione: {new Date(team.created_at).toLocaleString("it-IT")}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => toggleTeamActive(team.id, team.active)}
                      className={`px-3 py-2 border rounded-lg text-xs font-bold transition-colors ${
                        team.active
                          ? "border-destructive/35 text-destructive hover:bg-destructive/10"
                          : "border-success/35 text-success hover:bg-success/10"
                      }`}
                    >
                      {team.active ? "Disattiva Account" : "Attiva Account"}
                    </button>
                  </div>
                </div>
              </div>
            );
          })()}

          {/* STATS BREAKDOWN */}
          {(() => {
            const teamScores = (allScores.data ?? []).filter((s: any) => s.team_id === selectedTeamId);
            const totalPoints = teamScores.reduce((sum: number, s: any) => sum + s.punti, 0);
            const teamProg = (allProgress.data ?? []).filter((p: any) => p.team_id === selectedTeamId && p.stato === "completed");
            return (
              <div className="grid grid-cols-2 gap-4">
                <div className="surface p-4 text-center">
                  <p className="text-xs font-extrabold tracking-wider text-muted-foreground uppercase">Punti Totali</p>
                  <p className="font-display text-4xl font-extrabold text-gold mt-1">{totalPoints} PT</p>
                </div>
                <div className="surface p-4 text-center">
                  <p className="text-xs font-extrabold tracking-wider text-muted-foreground uppercase">Prove Completate</p>
                  <p className="font-display text-4xl font-extrabold text-primary mt-1">{teamProg.length} / {(challenges.data ?? []).length}</p>
                </div>
              </div>
            );
          })()}

          {/* REGOLAZIONE PUNTEGGIO & STORICO REGOLAZIONI */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Form to Adjust Points */}
            <div className="surface p-5 space-y-4">
              <h3 className="text-lg font-bold uppercase tracking-wider text-muted-foreground">Regola Punteggio</h3>
              <form onSubmit={handleAdjustPoints} className="space-y-3">
                <div>
                  <label className="block text-xs font-semibold text-muted-foreground uppercase mb-1">
                    Punti (es. +10 per aggiungere, -5 per togliere)
                  </label>
                  <input
                    type="number"
                    placeholder="Es. +10 o -5"
                    value={adjPoints}
                    onChange={(e) => setAdjPoints(e.target.value)}
                    className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:ring-2 focus:ring-ring focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-muted-foreground uppercase mb-1">
                    Motivazione / Commento
                  </label>
                  <textarea
                    rows={2}
                    placeholder="Es. Bonus orientamento tappa 1, penalità comportamento..."
                    value={adjReason}
                    onChange={(e) => setAdjReason(e.target.value)}
                    className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:ring-2 focus:ring-ring focus:outline-none resize-none"
                  />
                </div>
                <button
                  type="submit"
                  disabled={isAdjusting}
                  className="primary-gradient w-full py-3 rounded-xl font-extrabold text-primary-foreground disabled:opacity-60 flex items-center justify-center gap-2 cursor-pointer"
                >
                  {isAdjusting ? <Loader2 className="size-4 animate-spin" /> : <Sparkles className="size-4" />}
                  Applica Regolazione
                </button>
              </form>
            </div>

            {/* List of Manual Adjustments / Score History */}
            <div className="surface p-5 space-y-4 flex flex-col justify-between">
              <div className="flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="text-lg font-bold uppercase tracking-wider text-muted-foreground mb-3">Storico Modifiche Manuali</h3>
                  {(() => {
                    const manualScores = (allScores.data ?? []).filter(
                      (s: any) => s.team_id === selectedTeamId && !s.challenge_id
                    );
                    if (manualScores.length === 0) {
                      return (
                        <p className="text-sm text-muted-foreground py-4">
                          Nessuna regolazione manuale registrata per questa squadra.
                          </p>
                      );
                    }
                    return (
                      <div className="max-h-[200px] overflow-y-auto pr-1 space-y-2">
                        {manualScores.map((s: any) => (
                          <div key={s.id} className="bg-background/40 border border-border/30 rounded-xl p-3 flex justify-between items-start gap-4">
                            <div className="space-y-1 min-w-0">
                              <p className="text-xs font-bold text-foreground break-words">{s.motivazione}</p>
                              <p className="text-[10px] text-muted-foreground font-medium">
                                {new Date(s.created_at).toLocaleString("it-IT")}
                              </p>
                            </div>
                            <div className="flex items-center gap-2 shrink-0">
                              <span className={`font-display text-sm font-black ${
                                s.punti > 0 ? "text-success" : "text-destructive"
                              }`}>
                                {s.punti > 0 ? `+${s.punti}` : s.punti} PT
                              </span>
                              <button
                                onClick={() => handleDeleteScore(s.id)}
                                className="p-1 hover:bg-destructive/10 text-muted-foreground hover:text-destructive rounded transition-colors cursor-pointer"
                                title="Elimina questa regolazione"
                              >
                                <Trash2 className="size-3.5" />
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    );
                  })()}
                </div>
              </div>
            </div>
          </div>

          {/* DETTAGLI SFIDA EMOJI MOVIES */}
          {(() => {
            const emojiChallengeProg = (allProgress.data ?? []).find(
              (p: any) => p.team_id === selectedTeamId && p.challenge_id === "777f4e1f-7443-42e7-9d7a-115f2122888f"
            );
            if (!emojiChallengeProg) return null;

            const teamEmojiAnswers = (allEmojiMovies.data ?? []).filter(
              (a: any) => a.team_id === selectedTeamId
            );

            const getMovieState = (index: number) => {
              const ans = teamEmojiAnswers.find((a: any) => a.movie_index === index);
              const movie = MOVIES.find((m) => m.index === index);
              return {
                emojis: movie?.emojis ?? "",
                title: movie?.title ?? "",
                letter: movie?.letter ?? "",
                attempts: ans?.attempts ?? 0,
                isCorrect: ans?.is_correct ?? false,
                lastAnswer: ans?.last_answer ?? "",
                isResolved: (ans?.is_correct ?? false) || (ans?.attempts ?? 0) >= 3,
              };
            };

            const totalPoints = teamEmojiAnswers.reduce((sum: number, a: any) => sum + (a.points || 0), 0);
            const isCompleted = emojiChallengeProg.stato === "completed";

            // Duration Calculation
            let durationStr = "In corso...";
            if (emojiChallengeProg.started_at && emojiChallengeProg.completata_at) {
              const ms = new Date(emojiChallengeProg.completata_at).getTime() - new Date(emojiChallengeProg.started_at).getTime();
              durationStr = formatDuration(Math.round(ms / 1000));
            } else if (emojiChallengeProg.started_at) {
              const ms = Date.now() - new Date(emojiChallengeProg.started_at).getTime();
              durationStr = formatDuration(Math.round(ms / 1000));
            }

            // Final Word
            const finalWord = MOVIES.map((m) => {
              const state = getMovieState(m.index);
              return state.isResolved ? state.letter : "_";
            });

            return (
              <div className="surface p-5 space-y-4 border border-red-950/40 bg-zinc-950/20 rounded-2xl">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border/30 pb-3">
                  <div>
                    <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
                      <Film className="size-5 text-red-500" />
                      <span>Dettaglio Prova: Indovina il film dalle Emoji</span>
                    </h3>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      Stato Prova: <span className={`font-bold ${isCompleted ? "text-success" : "text-primary"}`}>{isCompleted ? "Completata" : "In Corso"}</span> · Tempo Impiegato: <span className="font-mono">{durationStr}</span>
                    </p>
                  </div>
                  <div className="text-right sm:text-right">
                    <p className="text-[10px] uppercase font-bold text-muted-foreground">Punteggio</p>
                    <p className="text-2xl font-black text-red-500">{totalPoints} / 8 PT</p>
                  </div>
                </div>

                {/* Final word preview */}
                <div className="bg-background/40 border border-border/30 rounded-xl p-3 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div>
                    <p className="text-xs font-bold text-muted-foreground uppercase">Lettere sbloccate:</p>
                    <div className="flex gap-1.5 mt-1.5">
                      {finalWord.map((letter, idx) => (
                        <span
                          key={idx}
                          className={`grid size-7 place-items-center rounded font-display text-sm font-black ${
                            letter !== "_" ? "bg-red-600 text-white" : "bg-secondary text-muted-foreground"
                          }`}
                        >
                          {letter}
                        </span>
                      ))}
                    </div>
                  </div>
                  {finalWord.join("") === "VITTORIA" && (
                    <span className="bg-success/20 text-success text-xs font-black uppercase tracking-wider px-3 py-1 rounded flex items-center gap-1">
                      <Sparkles className="size-3.5" /> Parola Sbloccata!
                    </span>
                  )}
                </div>

                {/* Movie List Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                  {MOVIES.map((movie) => {
                    const state = getMovieState(movie.index);
                    return (
                      <div
                        key={movie.index}
                        className={`p-3.5 rounded-xl border flex flex-col justify-between gap-2.5 ${
                          state.isCorrect
                            ? "bg-green-950/10 border-green-900/30"
                            : state.attempts >= 3
                            ? "bg-red-950/10 border-red-900/30"
                            : "bg-background/40 border-border/30"
                        }`}
                      >
                        <div className="flex justify-between items-start">
                          <span className="text-[10px] font-bold text-muted-foreground font-mono">
                            Locandina #{movie.index}
                          </span>
                          <span className={`text-[10px] font-extrabold uppercase px-1.5 py-0.5 rounded ${
                            state.isCorrect
                              ? "bg-success/20 text-success"
                              : state.attempts >= 3
                              ? "bg-destructive/20 text-destructive"
                              : state.attempts > 0
                              ? "bg-primary/20 text-primary"
                              : "bg-secondary text-muted-foreground"
                          }`}>
                            {state.isCorrect ? "Indovinato" : state.attempts >= 3 ? "Fallito" : state.attempts > 0 ? "In Corso" : "Non Iniziato"}
                          </span>
                        </div>

                        <div className="text-center py-2">
                          <span className="text-3xl filter drop-shadow">{state.emojis}</span>
                        </div>

                        <div className="space-y-1">
                          <p className="text-xs text-muted-foreground font-semibold">
                            Film: <span className="text-foreground font-bold">{state.title}</span>
                          </p>
                          {state.lastAnswer && (
                            <p className="text-[11px] text-muted-foreground truncate" title={state.lastAnswer}>
                              Ultima risp: <span className="font-mono italic text-foreground/80">"{state.lastAnswer}"</span>
                            </p>
                          )}
                          <p className="text-[10px] text-muted-foreground">
                            Tentativi: <span className="font-bold text-foreground">{state.attempts} / 3</span>
                          </p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })()}

          {/* TIMELINE TABLE */}
          <div className="surface p-5 space-y-4 overflow-x-auto border border-zinc-800/80 bg-zinc-950/40 rounded-2xl">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border/30 pb-3">
              <div>
                <h3 className="text-lg font-display font-black uppercase tracking-wider text-foreground">
                  Storico Timeline Prove
                </h3>
                <p className="text-xs text-muted-foreground">
                  Riepilogo cronologico di tutte le prove, risposte, durate e punteggi assegnati alla squadra.
                </p>
              </div>
            </div>

            <table className="w-full min-w-[780px] text-left border-collapse">
              <thead>
                <tr className="border-b border-border/40 text-xs text-muted-foreground uppercase tracking-wider font-bold">
                  <th className="py-2.5 pr-4">Tappa</th>
                  <th className="py-2.5 pr-4">Gioco / Prova</th>
                  <th className="py-2.5 pr-4">Stato</th>
                  <th className="py-2.5 pr-4">Risposta / Esito</th>
                  <th className="py-2.5 pr-4">Durata / Orario</th>
                  <th className="py-2.5 pr-4">Punteggio</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/20 text-sm">
                {(() => {
                  const stagesList = (stages.data ?? []) as any[];
                  const challengesList = (challenges.data ?? []) as any[];

                  const sortedChallenges = [...challengesList].sort((a: any, b: any) => {
                    const stageA = stagesList.find((s: any) => s.id === a.stage_id);
                    const stageB = stagesList.find((s: any) => s.id === b.stage_id);
                    const stageOrderA = stageA?.numero_tappa ?? stageA?.ordine ?? 0;
                    const stageOrderB = stageB?.numero_tappa ?? stageB?.ordine ?? 0;
                    if (stageOrderA !== stageOrderB) return stageOrderA - stageOrderB;
                    const chOrderA = a.ordine_sfida ?? a.ordine ?? a.order_index ?? 0;
                    const chOrderB = b.ordine_sfida ?? b.ordine ?? b.order_index ?? 0;
                    return chOrderA - chOrderB;
                  });

                  if (sortedChallenges.length === 0) {
                    return (
                      <tr>
                        <td colSpan={6} className="py-6 text-center text-xs text-muted-foreground">
                          Nessuna prova configurata nel sistema.
                        </td>
                      </tr>
                    );
                  }

                  return sortedChallenges.map((c: any) => {
                    const stage = stagesList.find((s: any) => s.id === c.stage_id);
                    const stageName = stage?.titolo || stage?.nome_tappa || (stage?.numero_tappa ? `Tappa ${stage.numero_tappa}` : "—");

                    const prog = (allProgress.data ?? []).find(
                      (p: any) => p.team_id === selectedTeamId && p.challenge_id === c.id
                    );
                    const sub = (allSubmissions.data ?? []).find(
                      (s: any) => s.team_id === selectedTeamId && s.challenge_id === c.id
                    );
                    const score = (allScores.data ?? []).find(
                      (s: any) => s.team_id === selectedTeamId && s.challenge_id === c.id
                    );

                    const chTitle = c.titolo || c.title || "Prova";
                    const chType = c.tipo_sfida || c.type || "sfida";
                    const maxPoints = c.punteggio_massimo ?? c.points ?? 15;

                    const isCompleted = prog?.stato === "completed" || prog?.status === "completed" || Boolean(score && score.punti > 0);
                    const isPending = prog?.stato === "pending_approval" || prog?.status === "pending_approval" || sub?.stato_approvazione === "pending";
                    const isStarted = !isCompleted && !isPending && (prog?.stato === "started" || prog?.status === "started" || prog?.status === "in_progress");

                    // Calculate duration & timestamps
                    const startTime = prog?.started_at || prog?.created_at || prog?.iniziata_il;
                    const endTime = prog?.completata_il || prog?.completed_at || prog?.completata_at || sub?.timestamp || sub?.created_at;

                    let durationStr = "—";
                    let completionTimeStr = "";
                    if (startTime && endTime) {
                      const ms = new Date(endTime).getTime() - new Date(startTime).getTime();
                      durationStr = formatDuration(Math.max(0, Math.round(ms / 1000)));
                      completionTimeStr = `alle ${new Date(endTime).toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })}`;
                    } else if (endTime) {
                      durationStr = `alle ${new Date(endTime).toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })}`;
                    } else if (startTime && isStarted) {
                      const ms = Date.now() - new Date(startTime).getTime();
                      durationStr = `${formatDuration(Math.max(0, Math.round(ms / 1000)))} (in corso)`;
                    }

                    // Answer formatting
                    const quizAns = (allAnswers.data ?? []).filter(
                      (ta: any) => ta.team_id === selectedTeamId && (quizQuestions.data ?? []).some((q: any) => q.id === ta.question_id && q.challenge_id === c.id)
                    );
                    const movieAns = (allEmojiMovies.data ?? []).filter(
                      (m: any) => m.team_id === selectedTeamId
                    );

                    let answerDisplay: React.ReactNode = "—";
                    if (sub?.file_upload || sub?.file_url) {
                      answerDisplay = (
                        <span className="inline-flex items-center gap-1 text-xs font-semibold text-primary">
                          📷 Foto / File consegnato
                        </span>
                      );
                    } else if (chType === "quiz" && quizAns.length > 0) {
                      const correctCount = quizAns.filter((a: any) => a.correct).length;
                      answerDisplay = (
                        <span className="text-xs font-medium text-zinc-300">
                          {correctCount} / {quizAns.length} risposte corrette
                        </span>
                      );
                    } else if (chType === "emoji" && movieAns.length > 0) {
                      const solvedMovies = movieAns.filter((m: any) => m.indovinato || m.is_correct).length;
                      answerDisplay = (
                        <span className="text-xs font-medium text-zinc-300">
                          {solvedMovies} / 8 film indovinati
                        </span>
                      );
                    } else if (sub?.risposta || sub?.risposta_testo || sub?.note) {
                      answerDisplay = (
                        <span className="text-xs font-medium text-zinc-300 truncate max-w-xs block" title={sub.risposta || sub.risposta_testo || sub.note}>
                          "{sub.risposta || sub.risposta_testo || sub.note}"
                        </span>
                      );
                    } else if (isCompleted) {
                      answerDisplay = (
                        <span className="text-xs text-zinc-400 font-semibold">
                          Completata con successo
                        </span>
                      );
                    }

                    return (
                      <tr key={c.id} className="hover:bg-muted/10 transition-colors">
                        <td className="py-3 pr-4 font-bold text-xs text-muted-foreground">
                          {stageName}
                        </td>
                        <td className="py-3 pr-4">
                          <p className="font-extrabold text-foreground">{chTitle}</p>
                          <span className="inline-block text-[9px] font-bold uppercase tracking-wider text-muted-foreground px-1.5 py-0.5 rounded bg-zinc-900 border border-zinc-800 mt-0.5">
                            {chType}
                          </span>
                        </td>
                        <td className="py-3 pr-4">
                          <span
                            className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded border ${
                              isCompleted
                                ? "bg-emerald-950/40 text-emerald-400 border-emerald-800/40"
                                : isPending
                                ? "bg-amber-950/40 text-amber-400 border-amber-800/40"
                                : isStarted
                                ? "bg-blue-950/40 text-blue-400 border-blue-800/40"
                                : "bg-zinc-900/60 text-zinc-500 border-zinc-800/60"
                            }`}
                          >
                            {isCompleted
                              ? "Completata"
                              : isPending
                              ? "In Valutazione"
                              : isStarted
                              ? "In Corso"
                              : "Non Iniziata"}
                          </span>
                        </td>
                        <td className="py-3 pr-4 max-w-xs">
                          {answerDisplay}
                        </td>
                        <td className="py-3 pr-4 font-mono text-xs">
                          <span className="text-foreground font-semibold">{durationStr}</span>
                          {completionTimeStr && (
                            <span className="text-[10px] text-zinc-500 block font-normal">{completionTimeStr}</span>
                          )}
                        </td>
                        <td className="py-3 pr-4">
                          {score && score.punti !== undefined && score.punti !== null ? (
                            <span className="font-mono font-black text-amber-400 text-sm">
                              +{score.punti}{" "}
                              <span className="text-[10px] text-zinc-500 font-normal">/ {maxPoints} PT</span>
                            </span>
                          ) : isCompleted ? (
                            <span className="font-mono font-bold text-zinc-400 text-xs">
                              0 <span className="text-[10px] text-zinc-500">/ {maxPoints} PT</span>
                            </span>
                          ) : (
                            <span className="text-xs text-zinc-600 font-mono">
                              — <span className="text-[10px] text-zinc-700">/ {maxPoints} PT</span>
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  });
                })()}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* NEW TEAM FORM */}
          <div className="surface p-5 space-y-4 h-fit">
            <h2 className="text-xl font-bold uppercase tracking-wider text-muted-foreground">Crea Squadra</h2>
            <form onSubmit={handleCreateTeam} className="space-y-3">
              <input
                value={teamName}
                onChange={(e) => setTeamName(e.target.value)}
                placeholder="Nome squadra (es. I Lupi)"
                className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:outline-none"
              />
              <input
                value={teamUser}
                onChange={(e) => setTeamUser(e.target.value)}
                placeholder="Username (es. lupi)"
                className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:outline-none"
              />
              <input
                value={teamPass}
                onChange={(e) => setTeamPass(e.target.value)}
                placeholder="Password"
                type="password"
                className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:outline-none"
              />
              <button type="submit" className="primary-gradient w-full py-3 rounded-xl font-extrabold text-primary-foreground cursor-pointer">
                Crea Squadra
              </button>
            </form>
          </div>

          {/* TOKEN MANAGEMENT PANEL */}
          <div className="surface p-5 space-y-4 h-fit">
            <div>
              <h2 className="text-xl font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-2">
                <Coins className="size-5 text-yellow-500" />
                Gestione Token
              </h2>
              <p className="text-xs text-muted-foreground mt-1">
                Aggiungi o rimuovi token da una squadra specifica o da tutte le squadre attive.
              </p>
            </div>

            <form onSubmit={(e) => handleAdjustTokens(e, tokenTargetId)} className="space-y-3">
              {/* Target selector */}
              <div>
                <label className="block text-xs font-bold text-muted-foreground uppercase mb-1">Squadra destinataria</label>
                <select
                  value={tokenTargetId ?? ""}
                  onChange={(e) => setTokenTargetId(e.target.value || null)}
                  className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:outline-none"
                >
                  <option value="">Tutte le squadre attive</option>
                  {(allTeams.data ?? []).filter((t: any) => t.active).map((t: any) => (
                    <option key={t.id} value={t.id}>{t.nome_squadra} ({t.token_balance ?? 50} token)</option>
                  ))}
                </select>
              </div>

              {/* Amount */}
              <div>
                <label className="block text-xs font-bold text-muted-foreground uppercase mb-1">
                  Quantità (negativo per togliere)
                </label>
                <div className="flex gap-2 items-center w-full">
                  <button
                    type="button"
                    onClick={() => setTokenAmount(String((parseInt(tokenAmount) || 0) - 5))}
                    className="size-11 shrink-0 rounded-full border border-border hover:bg-secondary/50 transition-colors cursor-pointer flex items-center justify-center"
                  >
                    <Minus className="size-4" />
                  </button>
                  <input
                    type="number"
                    placeholder="Es. +10 o -3"
                    value={tokenAmount}
                    onChange={(e) => setTokenAmount(e.target.value)}
                    className="flex-1 min-w-0 rounded-xl border border-input bg-input/40 px-4 py-3 text-sm text-center font-bold focus:outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                  />
                  <button
                    type="button"
                    onClick={() => setTokenAmount(String((parseInt(tokenAmount) || 0) + 5))}
                    className="size-11 shrink-0 rounded-full border border-border hover:bg-secondary/50 transition-colors cursor-pointer flex items-center justify-center"
                  >
                    <Plus className="size-4" />
                  </button>
                </div>
              </div>

              {/* Reason */}
              <div>
                <label className="block text-xs font-bold text-muted-foreground uppercase mb-1">Motivazione (opzionale)</label>
                <input
                  type="text"
                  placeholder="Es. Bonus orientamento..."
                  value={tokenReason}
                  onChange={(e) => setTokenReason(e.target.value)}
                  className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={(e) => { setTokenAmount("-5"); handleAdjustTokens(e as any, tokenTargetId); }}
                  disabled={isAdjustingTokens}
                  className="py-2.5 rounded-xl border border-destructive/30 text-destructive font-bold text-xs hover:bg-destructive/10 transition-all cursor-pointer disabled:opacity-40"
                >
                  − 5 Token
                </button>
                <button
                  type="button"
                  onClick={(e) => { setTokenAmount("5"); handleAdjustTokens(e as any, tokenTargetId); }}
                  disabled={isAdjustingTokens}
                  className="py-2.5 rounded-xl border border-success/30 text-success font-bold text-xs hover:bg-success/10 transition-all cursor-pointer disabled:opacity-40"
                >
                  + 5 Token
                </button>
              </div>

              <button
                type="submit"
                disabled={isAdjustingTokens || !tokenAmount}
                className="primary-gradient w-full py-3 rounded-xl font-extrabold text-primary-foreground disabled:opacity-60 flex items-center justify-center gap-2 cursor-pointer"
              >
                {isAdjustingTokens ? <Loader2 className="size-4 animate-spin" /> : <Coins className="size-4" />}
                Applica Token
              </button>
            </form>
          </div>

          {/* TEAMS LIST */}
          <div className="lg:col-span-2 space-y-4">
            <h2 className="text-xl font-bold uppercase tracking-wider text-muted-foreground pl-1">Squadre in Gara</h2>
            <div className="grid gap-3">
              {(allTeams.data ?? []).map((t: any) => {
                const isEditing = editingTeamId === t.id;
                const teamProg = (allProgress.data ?? []).filter((p: any) => p.team_id === t.id);
                const completed = teamProg.filter((p: any) => p.stato === "completed").length;

                return (
                  <div key={t.id} className="surface p-4 space-y-3">
                    {isEditing ? (
                      <div className="space-y-3">
                        <input
                          value={editName}
                          onChange={(e) => setEditName(e.target.value)}
                          placeholder="Modifica nome squadra"
                          className="w-full rounded-xl border border-input bg-input/40 px-4 py-2 text-sm focus:outline-none"
                        />
                        <input
                          value={editPass}
                          onChange={(e) => setEditPass(e.target.value)}
                          placeholder="Nuova Password (lascia vuoto per non cambiare)"
                          type="password"
                          className="w-full rounded-xl border border-input bg-input/40 px-4 py-2 text-sm focus:outline-none"
                        />
                        <div className="flex gap-2 justify-end">
                          <button
                            onClick={() => setEditingTeamId(null)}
                            className="px-3 py-1.5 rounded-lg border border-border text-xs font-bold cursor-pointer"
                          >
                            Annulla
                          </button>
                          <button
                            onClick={() => handleUpdateTeam(t.id)}
                            className="px-3 py-1.5 rounded-lg bg-primary text-primary-foreground text-xs font-bold cursor-pointer"
                          >
                            Salva
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                        <div>
                          <h3 className="font-extrabold text-lg flex items-center gap-1.5">
                            <span className={t.active ? "" : "text-muted-foreground line-through"}>{t.nome_squadra}</span>
                            <span className="text-xs text-muted-foreground font-semibold">({t.username})</span>
                            <span className={`text-[9px] font-extrabold px-1.5 py-0.5 rounded ${
                              t.active ? "bg-success/20 text-success" : "bg-destructive/20 text-destructive"
                            }`}>
                              {t.active ? "Attiva" : "Disattivata"}
                            </span>
                          </h3>
                          <p className="text-xs text-muted-foreground mt-0.5">
                            Creato il: {new Date(t.created_at).toLocaleDateString("it-IT")} · Progresso: {completed} prove
                          </p>
                          <p className="text-xs text-yellow-500 font-bold mt-0.5 flex items-center gap-1">
                            <Coins className="size-3" />
                            {t.token_balance ?? 50} Token disponibili
                          </p>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => setSelectedTeamId(t.id)}
                            className="px-3 py-1.5 border border-border rounded-lg text-xs font-bold hover:bg-secondary/65 transition-colors cursor-pointer"
                          >
                            Vedi Storico
                          </button>
                          <button
                            onClick={() => toggleTeamActive(t.id, t.active)}
                            className={`p-2 border rounded-lg transition-colors cursor-pointer ${
                              t.active
                                ? "border-success/35 text-success hover:bg-success/15"
                                : "border-warning/35 text-warning hover:bg-warning/15"
                            }`}
                            title={t.active ? "Disattiva account" : "Attiva account"}
                          >
                            {t.active ? <CheckCircle className="size-4" /> : <XCircle className="size-4" />}
                          </button>
                          <button
                            onClick={() => {
                              setEditingTeamId(t.id);
                              setEditName(t.nome_squadra);
                              setEditPass("");
                            }}
                            className="p-2 border border-border rounded-lg text-muted-foreground hover:text-foreground hover:bg-secondary/65 transition-colors cursor-pointer"
                            title="Modifica squadra / Reset password"
                          >
                            <Lock className="size-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteTeam(t.id)}
                            className="p-2 border border-border rounded-lg text-destructive hover:bg-destructive/10 transition-colors cursor-pointer"
                            title="Elimina squadra"
                          >
                            <Trash2 className="size-4" />
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
