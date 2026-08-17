import { useState, useEffect, useRef } from "react";
import { Check, X, Loader2, Puzzle, ArrowRight } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import type { Challenge, Team } from "@/lib/race";

interface Props {
  challenge: Challenge;
  team: Team | null;
  completed: boolean;
  onComplete: () => void;
  completing: boolean;
}

type ResultState = "idle" | "correct" | "wrong" | "loading";

export function EnigmaTestoChallenge({ challenge, team, completed: initCompleted, onComplete }: Props) {
  const [answer, setAnswer] = useState("");
  const [result, setResult] = useState<ResultState>("idle");
  const [attemptCount, setAttemptCount] = useState(0);
  const [isCompleted, setIsCompleted] = useState(initCompleted);
  const [pointsEarned, setPointsEarned] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!team?.id || !challenge?.id) return;
    supabase
      .rpc("get_enigma_state", { p_challenge_id: challenge.id, p_team_id: team.id })
      .then(({ data, error }: { data: any; error: any }) => {
        if (error || !data) return;
        if (data.is_completed) { setIsCompleted(true); setResult("correct"); }
        setAttemptCount(data.attempt_count ?? 0);
      });
  }, [team?.id, challenge?.id]);

  async function handleValidate(e?: React.FormEvent) {
    if (e) e.preventDefault();
    const trimmed = answer.trim();
    if (!trimmed) { toast.warning("Inserisci una risposta."); return; }
    if (!team?.id || !challenge?.id) return;
    setResult("loading");
    const { data, error } = await supabase.rpc("submit_enigma_answer", {
      p_challenge_id: challenge.id,
      p_answer: trimmed,
    });
    if (error || !data) { toast.error("Errore di rete. Riprova."); setResult("idle"); return; }
    setAttemptCount((prev) => prev + 1);
    if (data.is_correct) {
      setResult("correct");
      setIsCompleted(true);
      setPointsEarned(data.points ?? 0);
    } else {
      setResult("wrong");
      setTimeout(() => {
        setAnswer("");
        setResult("idle");
        inputRef.current?.focus();
      }, 1800);
    }
  }

  if (isCompleted || result === "correct") {
    return (
      <div className="space-y-5 animate-in fade-in slide-in-from-bottom-4 duration-500">
        <div className="surface border border-success/30 bg-success/5 rounded-2xl p-6 text-center space-y-3">
          <div className="inline-flex size-16 items-center justify-center rounded-full bg-success/20 border border-success/30 mx-auto">
            <Check className="size-8 text-success" />
          </div>
          <h2 className="text-2xl font-display font-black uppercase tracking-wider text-success">Enigma Risolto!</h2>
          <p className="text-sm text-muted-foreground">La risposta è corretta.</p>
          {pointsEarned > 0 && (
            <span className="inline-block bg-gold/20 border border-gold/30 text-gold font-black text-sm px-4 py-1.5 rounded-full">
              +{pointsEarned} PT
            </span>
          )}
        </div>
        <button onClick={onComplete} className="primary-gradient w-full py-4 rounded-2xl font-extrabold text-primary-foreground flex items-center justify-center gap-2 text-base active:scale-95 transition-all">
          {challenge.order_index < 3 ? "Enigma Successivo" : "Tappa Completata!"} <ArrowRight className="size-5" />
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div className="surface p-4 rounded-2xl border border-border/40 space-y-1">
        <div className="flex items-center gap-2">
          <Puzzle className="size-4 text-primary" />
          <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">{challenge.title}</p>
        </div>
        <p className="text-xs text-muted-foreground leading-relaxed">
          Osserva l'enigma cartaceo e inserisci la soluzione qui sotto. La risposta non è case-sensitive.
        </p>
        {attemptCount > 0 && (
          <p className="text-xs text-muted-foreground mt-1">Tentativi: <span className="font-bold text-foreground">{attemptCount}</span></p>
        )}
      </div>

      {result === "wrong" && (
        <div className="bg-destructive/10 border border-destructive/20 text-destructive text-center py-3 rounded-2xl animate-in fade-in duration-200 space-y-1">
          <p className="text-xs font-bold">✕ RISPOSTA ERRATA</p>
          <p className="text-sm font-black text-destructive animate-bounce">-8 PUNTI</p>
          <p className="text-[10px] text-muted-foreground/80">Riprova.</p>
        </div>
      )}

      <form onSubmit={handleValidate} className="relative space-y-3">
        {/* Floating score loss animation inside form container */}
        {result === "wrong" && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-50">
            <span className="animate-score-loss text-red-500 font-display font-black text-6xl tracking-widest drop-shadow-[0_4px_16px_rgba(239,68,68,0.6)]">
              -8
            </span>
          </div>
        )}

        <div className="space-y-1.5">
          <label className="text-xs font-bold text-muted-foreground uppercase tracking-wider">La tua risposta</label>
          <input
            ref={inputRef}
            type="text"
            value={answer}
            onChange={(e) => {
              setAnswer(e.target.value);
              if (result === "wrong") setResult("idle");
            }}
            placeholder="Scrivi la soluzione..."
            disabled={result === "loading"}
            className={
              "w-full rounded-2xl border px-5 py-4 text-base font-bold bg-input/40 focus:outline-none focus:ring-2 transition-all " +
              (result === "wrong"
                ? "border-destructive/50 focus:ring-destructive/20 text-destructive"
                : "border-input focus:ring-primary/20 text-foreground")
            }
            autoComplete="off"
            autoCorrect="off"
            spellCheck={false}
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <button
            type="button"
            onClick={() => { setAnswer(""); setResult("idle"); }}
            disabled={!answer || result === "loading"}
            className="py-4 rounded-2xl border border-border font-extrabold text-muted-foreground hover:text-foreground hover:border-foreground/30 transition-all active:scale-95 disabled:opacity-40 cursor-pointer text-sm"
          >
            Cancella
          </button>
          <button
            type="submit"
            disabled={!answer.trim() || result === "loading"}
            className="py-4 rounded-2xl primary-gradient font-extrabold text-primary-foreground flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-40 cursor-pointer text-sm shadow-lg shadow-primary/20"
          >
            {result === "loading" ? "Verifico..." : "VALIDA"}
          </button>
        </div>
      </form>

      {/* Dynamic Keyframe style block for float/scale-loss feedback */}
      <style>{`
        @keyframes scoreLossFloat {
          0% { transform: scale(0.4) translateY(0); opacity: 0; }
          15% { transform: scale(1.2) translateY(-10px); opacity: 1; }
          80% { transform: scale(1) translateY(-30px); opacity: 1; }
          100% { transform: scale(0.7) translateY(-55px); opacity: 0; }
        }
        .animate-score-loss {
          animation: scoreLossFloat 1.4s cubic-bezier(0.25, 1, 0.5, 1) forwards;
        }
      `}</style>
    </div>
  );
}
