import { useState, useEffect, useCallback } from "react";
import { Check, X, Loader2, Music, ArrowRight } from "lucide-react";
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

const WHITE_KEYS = [
  { note: "Do", label: "Do" },
  { note: "Re", label: "Ré" },
  { note: "Mi", label: "Mi" },
  { note: "Fa", label: "Fa" },
  { note: "Sol", label: "Sol" },
  { note: "La", label: "La" },
  { note: "Si", label: "Si" },
] as const;

const BLACK_KEYS: Array<{ note: string; label: string; leftPercent: number } | null> = [
  { note: "Do#", label: "Do#", leftPercent: 10.2 },
  { note: "Re#", label: "Ré#", leftPercent: 24.5 },
  null,
  { note: "Fa#", label: "Fa#", leftPercent: 52.4 },
  { note: "Sol#", label: "Sol#", leftPercent: 66.6 },
  { note: "La#", label: "La#", leftPercent: 80.9 },
];

type ResultState = "idle" | "correct" | "wrong" | "loading";

export function EnigmaMusicaleChallenge({ challenge, team, completed: initCompleted, onComplete }: Props) {
  const [selectedNotes, setSelectedNotes] = useState<string[]>([]);
  const [result, setResult] = useState<ResultState>("idle");
  const [attemptCount, setAttemptCount] = useState(0);
  const [isCompleted, setIsCompleted] = useState(initCompleted);
  const [pointsEarned, setPointsEarned] = useState(0);
  const [pressedKey, setPressedKey] = useState<string | null>(null);

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

  const handleNotePress = useCallback((note: string) => {
    if (isCompleted || result === "loading" || result === "correct") return;
    if (selectedNotes.length >= 3) return;
    setPressedKey(note);
    setTimeout(() => setPressedKey(null), 200);
    setSelectedNotes((prev) => [...prev, note]);
    if (result === "wrong") setResult("idle");
  }, [isCompleted, result, selectedNotes.length]);

  function handleClear() {
    if (result === "loading") return;
    setSelectedNotes([]);
    setResult("idle");
  }

  async function handleValidate() {
    if (selectedNotes.length !== 3) { toast.warning("Inserisci esattamente 3 note."); return; }
    if (!team?.id || !challenge?.id) return;
    setResult("loading");
    const { data, error } = await supabase.rpc("submit_enigma_answer", {
      p_challenge_id: challenge.id,
      p_answer: selectedNotes,
    });
    if (error || !data) { toast.error("Errore di rete. Riprova."); setResult("idle"); return; }
    setAttemptCount((prev) => prev + 1);
    if (data.is_correct) {
      setResult("correct");
      setIsCompleted(true);
      setPointsEarned(data.points ?? 0);
    } else {
      setResult("wrong");
      setTimeout(() => { setSelectedNotes([]); setResult("idle"); }, 1800);
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
          <p className="text-sm text-muted-foreground">La sequenza di note è corretta.</p>
          {pointsEarned > 0 && (
            <span className="inline-block bg-gold/20 border border-gold/30 text-gold font-black text-sm px-4 py-1.5 rounded-full">
              +{pointsEarned} PT
            </span>
          )}
        </div>
        <button onClick={onComplete} className="primary-gradient w-full py-4 rounded-2xl font-extrabold text-primary-foreground flex items-center justify-center gap-2 text-base active:scale-95 transition-all">
          Enigma Successivo <ArrowRight className="size-5" />
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div className="surface p-4 rounded-2xl border border-border/40 space-y-1">
        <div className="flex items-center gap-2">
          <Music className="size-4 text-primary" />
          <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">Rebus Musicale</p>
        </div>
        <p className="text-xs text-muted-foreground leading-relaxed">
          Osserva il rebus cartaceo, individua le 3 note nell'ordine corretto e premi VALIDA.
        </p>
        {attemptCount > 0 && (
          <p className="text-xs text-muted-foreground mt-1">Tentativi: <span className="font-bold text-foreground">{attemptCount}</span></p>
        )}
      </div>

      <div className="flex justify-center gap-5 py-2">
        {[0, 1, 2].map((i) => {
          const note = selectedNotes[i];
          return (
            <div key={i} className={"flex flex-col items-center gap-1.5 transition-all duration-200 " + (note ? "scale-105" : "scale-100")}>
              <div className={
                "size-14 rounded-full border-2 flex items-center justify-center text-xs font-black transition-all duration-300 " +
                (result === "wrong" ? "border-destructive bg-destructive/20 text-destructive" :
                  note ? "border-primary bg-primary/20 text-primary shadow-lg shadow-primary/20" :
                  "border-border/50 bg-muted/20 text-muted-foreground")
              }>
                {note ? note.slice(0, 3) : "○"}
              </div>
              <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Nota {i + 1}</span>
            </div>
          );
        })}
      </div>

      {result === "wrong" && (
        <div className="bg-destructive/10 border border-destructive/20 text-destructive text-center py-3 rounded-2xl animate-in fade-in duration-200 space-y-1">
          <p className="text-xs font-bold">✕ SEQUENZA ERRATA</p>
          <p className="text-sm font-black text-destructive animate-bounce">-8 PUNTI</p>
          <p className="text-[10px] text-muted-foreground/80">Riprova.</p>
        </div>
      )}

      <div className="relative surface rounded-2xl border border-border/40 p-4 overflow-hidden">
        {/* Floating score loss animation inside piano container */}
        {result === "wrong" && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-50">
            <span className="animate-score-loss text-red-500 font-display font-black text-6xl tracking-widest drop-shadow-[0_4px_16px_rgba(239,68,68,0.6)]">
              -8
            </span>
          </div>
        )}

        <div className="relative mx-auto select-none" style={{ maxWidth: 360 }}>
          <div className="flex gap-[3px]" style={{ height: 130 }}>
            {WHITE_KEYS.map(({ note, label }) => {
              const isPressed = pressedKey === note;
              const isSelected = selectedNotes.includes(note);
              return (
                <button
                  key={note}
                  onPointerDown={() => handleNotePress(note)}
                  disabled={result === "loading" || selectedNotes.length >= 3 || isCompleted}
                  className={
                    "flex-1 rounded-b-xl border flex flex-col items-center justify-end pb-2 transition-all duration-100 cursor-pointer active:scale-y-95 touch-manipulation disabled:opacity-40 disabled:cursor-not-allowed " +
                    (isPressed ? "bg-primary/30 border-primary scale-y-95" :
                      isSelected ? "bg-primary/15 border-primary/60 shadow-inner" :
                      "bg-white/90 border-zinc-300 hover:bg-zinc-100 shadow-sm")
                  }
                  style={{ minHeight: 120 }}
                  aria-label={label}
                >
                  <span className={"text-[11px] font-black leading-none " + (isSelected ? "text-primary" : "text-zinc-700")}>{label}</span>
                </button>
              );
            })}
          </div>
          <div className="absolute top-0 left-0 right-0 pointer-events-none" style={{ height: 80 }}>
            {BLACK_KEYS.map((bk) => {
              if (!bk) return null;
              const isPressed = pressedKey === bk.note;
              const isSelected = selectedNotes.includes(bk.note);
              return (
                <button
                  key={bk.note}
                  onPointerDown={() => handleNotePress(bk.note)}
                  disabled={result === "loading" || selectedNotes.length >= 3 || isCompleted}
                  className={
                    "absolute top-0 rounded-b-lg z-10 pointer-events-auto transition-all duration-100 cursor-pointer active:scale-y-95 touch-manipulation border border-black/40 flex items-end justify-center pb-1.5 disabled:opacity-40 disabled:cursor-not-allowed " +
                    (isPressed ? "bg-primary scale-y-95" : isSelected ? "bg-primary/70" : "bg-zinc-900 hover:bg-zinc-700")
                  }
                  style={{ left: bk.leftPercent + "%", width: "10.5%", height: 80 }}
                  aria-label={bk.label}
                >
                  <span className="text-[8px] font-black text-white/70 leading-none">{bk.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={handleClear}
          disabled={selectedNotes.length === 0 || result === "loading"}
          className="py-4 rounded-2xl border border-border font-extrabold text-muted-foreground hover:text-foreground hover:border-foreground/30 transition-all active:scale-95 disabled:opacity-40 cursor-pointer text-sm"
        >
          Cancella
        </button>
        <button
          onClick={handleValidate}
          disabled={selectedNotes.length !== 3 || result === "loading"}
          className="py-4 rounded-2xl primary-gradient font-extrabold text-primary-foreground flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-40 cursor-pointer text-sm shadow-lg shadow-primary/20"
        >
          {result === "loading" ? "Verifico..." : "VALIDA"}
        </button>
      </div>

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
