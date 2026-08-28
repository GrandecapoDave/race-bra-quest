import { useState, useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, Loader2, X, Lock, Sparkles, AlertCircle } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Challenge, Team } from "@/lib/race";

export function BancaChallenge({
  challenge,
  team,
  completed,
  onComplete,
  completing,
}: {
  challenge: Challenge;
  team: Team | null;
  completed: boolean;
  onComplete: () => void;
  completing: boolean;
}) {
  const queryClient = useQueryClient();

  // Fetch bank challenge state
  const { data: bankState, isLoading, refetch } = useQuery({
    queryKey: ["bank-state", team?.id],
    enabled: Boolean(team?.id),
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_bank_state", {
        p_team_id: team?.id,
      });
      if (error) throw new Error(error.message);
      return data as {
        progress: any;
        answers: Array<{ question_number: number; answer: string; extracted_letter: string }>;
        all_questions: Array<{ question_number: number; question_text: string; length: number }>;
      };
    },
    refetchInterval: 3000,
  });

  const [inputs, setInputs] = useState<Record<number, string>>({
    1: "",
    2: "",
    3: "",
    4: "",
  });
  const [submitting, setSubmitting] = useState<Record<number, boolean>>({});

  const solvedQuestions = new Set(
    bankState?.answers?.map((a) => a.question_number) ?? []
  );

  const getExtractedLetter = (qNum: number) => {
    return bankState?.answers?.find((a) => a.question_number === qNum)?.extracted_letter ?? "";
  };

  async function handleSubmit(qNum: number, e: React.FormEvent) {
    e.preventDefault();
    if (!team) {
      toast.error("Crea prima la tua squadra");
      return;
    }

    const answer = inputs[qNum]?.trim();
    if (!answer) {
      toast.error("Inserisci una risposta");
      return;
    }

    setSubmitting((prev) => ({ ...prev, [qNum]: true }));
    try {
      const { data, error } = await supabase.rpc("submit_bank_answer", {
        p_question_number: qNum,
        p_answer: answer,
      });

      if (error) {
        toast.error(error.message || "Errore durante l'invio");
        return;
      }

      const res = data as any;
      if (res?.already_completed) {
        toast.info("Sfida già completata!");
        return;
      }

      if (res?.correct) {
        toast.success(`Corretto! Hai ottenuto la lettera: ${res.letter}`);
        // Clear input
        setInputs((prev) => ({ ...prev, [qNum]: "" }));
        await refetch();
        await queryClient.invalidateQueries();

        if (res.challenge_completed) {
          toast.success("Complimenti! Hai risolto tutti gli enigmi de La Banca!");
        }
      } else {
        toast.error("❌ Risposta errata! Penalità: -5 Punti.");
        await queryClient.invalidateQueries();
      }
    } catch (err: any) {
      toast.error(err.message || "Errore imprevisto");
    } finally {
      setSubmitting((prev) => ({ ...prev, [qNum]: false }));
    }
  }

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-10 space-y-4">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-zinc-400 font-medium">Caricamento enigmi della banca...</p>
      </div>
    );
  }

  const questions = bankState?.all_questions ?? [];
  const isChallengeCompleted = completed || bankState?.progress?.status === "COMPLETED";

  return (
    <div className="space-y-6 sm:space-y-8 max-w-xl mx-auto">
      {/* INTRO BRIEFING */}
      <section className="bg-zinc-950/80 p-5 rounded-2xl border border-border/40 shadow-xl space-y-3">
        <h2 className="text-sm font-extrabold tracking-widest text-primary uppercase flex items-center gap-2">
          🏦 Sfida 1: La Banca
        </h2>
        <p className="text-sm sm:text-base font-serif italic text-zinc-300 leading-relaxed">
          "Quattro indizi, quattro parole, Viaggiatori.
          Risolveteli come veri enigmisti da settimana enigmistica:
          una definizione, una risposta, una sola lettera che conta davvero — la prima."
        </p>
      </section>

      {/* RIDDLES LIST */}
      <div className="space-y-4">
        {questions
          .sort((a, b) => a.question_number - b.question_number)
          .map((q) => {
            const isSolved = solvedQuestions.has(q.question_number);
            const letter = getExtractedLetter(q.question_number);

            return (
              <div
                key={q.question_number}
                className={`surface p-5 border transition-all duration-300 rounded-2xl ${
                  isSolved
                    ? "border-success/30 bg-success/5 shadow-success/5"
                    : "border-border/40 bg-zinc-950/20"
                }`}
              >
                <div className="flex justify-between items-start gap-3">
                  <span className="text-[10px] font-black uppercase tracking-widest bg-zinc-900 px-2.5 py-1 rounded-lg border border-border/20 text-zinc-400">
                    Enigma {q.question_number} · {q.length} Lettere
                  </span>
                  {isSolved && (
                    <span className="flex items-center gap-1 text-xs font-bold text-success">
                      <Check className="size-4" /> Risolto
                    </span>
                  )}
                </div>

                <p className="mt-3 font-semibold text-zinc-200 text-sm sm:text-base leading-relaxed">
                  "{q.question_text}"
                </p>

                {isSolved ? (
                  <div className="mt-4 bg-success/10 border border-success/20 rounded-xl p-3.5 flex items-center justify-between">
                    <div>
                      <p className="text-[10px] text-success font-black uppercase tracking-wider">Lettera ottenuta</p>
                      <p className="text-2xl font-black text-success font-display mt-0.5">{letter}</p>
                    </div>
                    <div className="size-8 rounded-full bg-success/20 flex items-center justify-center text-success">
                      <Check className="size-4" />
                    </div>
                  </div>
                ) : (
                  <form onSubmit={(e) => handleSubmit(q.question_number, e)} className="mt-4 space-y-3">
                    {/* Character slots helper */}
                    <div className="flex gap-1.5 overflow-x-auto py-1">
                      {Array.from({ length: q.length }).map((_, idx) => {
                        const val = inputs[q.question_number]?.[idx] || "";
                        return (
                          <div
                            key={idx}
                            className="size-8 shrink-0 rounded-lg border border-border/40 bg-zinc-900/60 flex items-center justify-center font-display font-black text-sm text-foreground uppercase"
                          >
                            {val}
                          </div>
                        );
                      })}
                    </div>

                    <div className="flex gap-2">
                      <input
                        type="text"
                        maxLength={q.length}
                        value={inputs[q.question_number] || ""}
                        placeholder={`Rispondi (${q.length} lettere)`}
                        disabled={submitting[q.question_number]}
                        onChange={(e) => {
                          const val = e.target.value.replace(/[^a-zA-Z]/g, "").toUpperCase();
                          setInputs((prev) => ({ ...prev, [q.question_number]: val }));
                        }}
                        className="bg-zinc-900/80 border border-border/40 px-4 py-2.5 rounded-xl text-sm font-semibold focus:outline-none focus:border-primary flex-1 uppercase"
                      />
                      <button
                        type="submit"
                        disabled={submitting[q.question_number] || !inputs[q.question_number]}
                        className="primary-gradient px-5 py-2.5 rounded-xl font-bold text-sm text-primary-foreground hover:scale-[1.02] active:scale-95 disabled:opacity-40 transition-all flex items-center gap-1.5 cursor-pointer"
                      >
                        {submitting[q.question_number] && <Loader2 className="size-4 animate-spin" />}
                        Verifica
                      </button>
                    </div>
                  </form>
                )}
              </div>
            );
          })}
      </div>

      {/* COLLECTED LETTERS PANEL */}
      <section className="bg-zinc-950 border border-zinc-900 p-5 rounded-2xl shadow-lg space-y-4">
        <h3 className="text-xs font-extrabold tracking-widest text-zinc-400 uppercase flex items-center gap-2">
          <Lock className="size-3.5 text-zinc-500" /> Lettere raccolte
        </h3>

        <div className="flex justify-center gap-3">
          {[1, 2, 3, 4].map((num) => {
            const letter = getExtractedLetter(num);
            return (
              <div
                key={num}
                className={`size-12 rounded-xl border flex flex-col items-center justify-center font-display font-black text-lg transition-all duration-300 ${
                  letter
                    ? "border-primary bg-primary/10 text-primary scale-110 shadow-lg shadow-primary/5"
                    : "border-zinc-800 bg-zinc-900/40 text-zinc-600"
                }`}
              >
                {letter || <Lock className="size-4 text-zinc-700" />}
                <span className="text-[8px] text-zinc-500 font-sans mt-0.5">#{num}</span>
              </div>
            );
          })}
        </div>

        {isChallengeCompleted && (
          <div className="pt-4 border-t border-zinc-900 space-y-4 animate-pop-in">
            <div className="bg-primary/10 border border-primary/20 rounded-xl p-4 text-center space-y-2">
              <span className="text-[10px] text-primary font-black uppercase tracking-wider block">Soluzione Finale Trovata!</span>
              <p className="text-3xl font-black font-display text-primary flex justify-center items-center gap-2">
                🏦 BPER
              </p>
              <p className="text-xs text-zinc-400 leading-relaxed max-w-sm mx-auto">
                Avete trovato la parola nascosta: <strong>BPER</strong>.
                La sfida è superata con successo!
              </p>
            </div>

            <button
              onClick={onComplete}
              disabled={completing}
              className="primary-gradient w-full py-3.5 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all hover:scale-[1.01]"
            >
              {completing && <Loader2 className="size-4 animate-spin" />}
              <span>Prosegui la Gara</span>
            </button>
          </div>
        )}
      </section>
    </div>
  );
}
