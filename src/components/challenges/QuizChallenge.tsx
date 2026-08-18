import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, Loader2, X } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { answersQuery, questionsQuery, type Challenge, type Team } from "@/lib/race";

type Feedback = { correct: boolean; points: number };

export function QuizChallenge({
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
  const questions = useQuery(questionsQuery(challenge.id));
  const answers = useQuery(answersQuery(team?.id));
  const [feedback, setFeedback] = useState<Record<string, Feedback>>({});
  const [pending, setPending] = useState<string | null>(null);

  const answered = new Map((answers.data ?? []).map((a) => [a.question_id, a]));
  const allAnswered =
    (questions.data?.length ?? 0) > 0 &&
    (questions.data ?? []).every((q) => answered.has(q.id));

  async function submit(questionId: string, index: number) {
    if (!team) {
      toast.error("Crea prima la tua squadra");
      return;
    }
    setPending(questionId);
    const { data, error } = await supabase.rpc("submit_quiz_answer", {
      p_question: questionId,
      p_selected: index,
    });
    setPending(null);
    if (error) {
      toast.error("Risposta non registrata, riprova");
      return;
    }
    const result = data as unknown as { correct: boolean; points: number };
    setFeedback((f) => ({ ...f, [questionId]: result }));
    if (result.correct) toast.success(`Corretto! +${result.points} punti`);
    else toast.error("Risposta errata");
    queryClient.invalidateQueries();
  }

  if (questions.isLoading) {
    return <Loader2 className="size-5 animate-spin text-muted-foreground" />;
  }

  return (
    <div className="space-y-4">
      {(questions.data ?? []).map((q, qi) => {
        const prior = answered.get(q.id);
        const fb = feedback[q.id];
        const options = (q.options as unknown as string[]) ?? [];
        return (
          <div key={q.id} className="surface animate-pop-in p-4">
            <p className="text-xs font-bold tracking-widest text-primary uppercase">
              Domanda {qi + 1} · {q.points} pt
            </p>
            <p className="mt-1 font-semibold">{q.question}</p>
            <div className="mt-3 grid gap-2">
              {options.map((opt, oi) => {
                const chosen = prior?.selected_answer === oi;
                const isCorrectChoice = chosen && prior?.correct;
                const isWrongChoice = chosen && prior && !prior.correct;
                return (
                  <button
                    key={opt}
                    disabled={Boolean(prior) || pending === q.id}
                    onClick={() => submit(q.id, oi)}
                    className={`flex items-center justify-between gap-2.5 rounded-xl border px-3.5 sm:px-4 py-3 text-left text-sm transition-colors w-full min-w-0 box-border ${
                      isCorrectChoice
                        ? "border-success bg-success/15 text-success"
                        : isWrongChoice
                          ? "border-destructive bg-destructive/15 text-destructive"
                          : "border-border bg-secondary/60 hover:border-primary disabled:opacity-60"
                    }`}
                  >
                    <span className="flex-1 min-w-0 break-words leading-snug">{opt}</span>
                    {isCorrectChoice && <Check className="size-4 shrink-0 text-success" />}
                    {isWrongChoice && <X className="size-4 shrink-0 text-destructive" />}
                  </button>
                );
              })}
            </div>
            {(fb || prior) && (
              <p
                className={`mt-2 text-sm font-bold ${
                  (fb?.correct ?? prior?.correct) ? "text-success" : "text-destructive"
                }`}
              >
                {(fb?.correct ?? prior?.correct)
                  ? `Corretto · +${fb?.points ?? q.points} punti`
                  : "Errato · 0 punti"}
              </p>
            )}
          </div>
        );
      })}

      {completed ? (
        <p className="flex items-center gap-2 rounded-xl bg-success/15 px-4 py-3 text-sm font-bold text-success">
          <Check className="size-4" /> Prova completata
        </p>
      ) : (
        <button
          onClick={onComplete}
          disabled={!allAnswered || completing}
          className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl py-3.5 font-extrabold text-primary-foreground disabled:opacity-40"
        >
          {completing && <Loader2 className="size-4 animate-spin" />}
          {allAnswered ? "Concludi il quiz" : "Rispondi a tutte le domande"}
        </button>
      )}
    </div>
  );
}
