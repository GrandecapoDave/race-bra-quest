import { useState, useEffect, useCallback } from "react";
import {
  ArrowUpLeft,
  ArrowUp,
  ArrowUpRight,
  ArrowLeft,
  ArrowRight,
  ArrowDownLeft,
  ArrowDown,
  ArrowDownRight,
  Check,
  X,
  Loader2,
  Lock,
  ArrowRight as NextIcon
} from "lucide-react";
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

type DirectionKey = "nord-ovest" | "nord" | "nord-est" | "ovest" | "est" | "sud-ovest" | "sud" | "sud-est";

interface DirectionButton {
  key: DirectionKey;
  icon: any;
  label: string;
}

const BUTTONS: Array<DirectionButton | null> = [
  { key: "nord-ovest", icon: ArrowUpLeft, label: "↖" },
  { key: "nord", icon: ArrowUp, label: "↑" },
  { key: "nord-est", icon: ArrowUpRight, label: "↗" },
  { key: "ovest", icon: ArrowLeft, label: "←" },
  null, // central dot
  { key: "est", icon: ArrowRight, label: "→" },
  { key: "sud-ovest", icon: ArrowDownLeft, label: "↙" },
  { key: "sud", icon: ArrowDown, label: "↓" },
  { key: "sud-est", icon: ArrowDownRight, label: "↘" },
];

type ResultState = "idle" | "correct" | "wrong" | "loading";

export function LucchettoDirezionaleChallenge({ challenge, team, completed: initCompleted, onComplete }: Props) {
  const [selectedDirections, setSelectedDirections] = useState<DirectionKey[]>([]);
  const [result, setResult] = useState<ResultState>("idle");
  const [attemptCount, setAttemptCount] = useState(0);
  const [isCompleted, setIsCompleted] = useState(initCompleted);
  const [pointsEarned, setPointsEarned] = useState(0);
  const [activeBtn, setActiveBtn] = useState<DirectionKey | null>(null);

  // Sync state with server on mount
  useEffect(() => {
    if (!team?.id || !challenge?.id) return;
    supabase
      .rpc("get_enigma_state", { p_challenge_id: challenge.id, p_team_id: team.id })
      .then(({ data, error }: { data: any; error: any }) => {
        if (error || !data) return;
        if (data.is_completed) {
          setIsCompleted(true);
          setResult("correct");
        }
        setAttemptCount(data.attempt_count ?? 0);
      });
  }, [team?.id, challenge?.id]);

  const handleDirectionPress = useCallback((dir: DirectionKey) => {
    if (isCompleted || result === "loading" || result === "correct") return;
    if (selectedDirections.length >= 4) return;

    // Haptic feedback (vibration)
    if (typeof window !== "undefined" && window.navigator && window.navigator.vibrate) {
      window.navigator.vibrate(30);
    }

    setActiveBtn(dir);
    setTimeout(() => setActiveBtn(null), 150);

    setSelectedDirections((prev) => [...prev, dir]);
    if (result === "wrong") setResult("idle");
  }, [isCompleted, result, selectedDirections.length]);

  function handleClear() {
    if (result === "loading") return;
    setSelectedDirections([]);
    setResult("idle");
  }

  async function handleValidate() {
    if (selectedDirections.length !== 4) {
      toast.warning("Inserisci esattamente 4 direzioni prima di confermare.");
      return;
    }
    if (!team?.id || !challenge?.id) return;
    setResult("loading");

    const { data, error } = await supabase.rpc("submit_enigma_answer", {
      p_challenge_id: challenge.id,
      p_answer: selectedDirections,
    });

    if (error || !data) {
      toast.error("Errore di rete. Riprova.");
      setResult("idle");
      return;
    }

    setAttemptCount((prev) => prev + 1);

    if (data.is_correct) {
      setResult("correct");
      setIsCompleted(true);
      setPointsEarned(data.points ?? 0);
      toast.success("Enigma risolto con successo!");
    } else {
      setResult("wrong");
      // Auto-clear sequence after delay for another attempt
      setTimeout(() => {
        setSelectedDirections([]);
        setResult("idle");
      }, 1500);
    }
  }

  // ── Correct/Completed State View ─────────────────────────────────────────
  if (isCompleted || result === "correct") {
    return (
      <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-sm mx-auto">
        <div className="surface border border-success/30 bg-success/5 rounded-2xl p-6 text-center space-y-4 shadow-lg shadow-success/5">
          <div className="inline-flex size-16 items-center justify-center rounded-full bg-success/20 border border-success/30 mx-auto">
            <Check className="size-8 text-success" />
          </div>
          <div className="space-y-1">
            <h2 className="text-2xl font-display font-black uppercase tracking-wider text-success">
              ✓ ENIGMA RISOLTO
            </h2>
            <p className="text-xs text-muted-foreground">La combinazione del lucchetto è corretta.</p>
          </div>
          {pointsEarned > 0 && (
            <span className="inline-block bg-gold/20 border border-gold/30 text-gold font-black text-sm px-4 py-1.5 rounded-full">
              +{pointsEarned} PT
            </span>
          )}
        </div>

        <button
          onClick={onComplete}
          className="primary-gradient w-full py-4 rounded-2xl font-extrabold text-primary-foreground flex items-center justify-center gap-2 text-base active:scale-95 transition-all shadow-md shadow-primary/20 cursor-pointer"
        >
          Prossima Prova <NextIcon className="size-5" />
        </button>
      </div>
    );
  }

  // ── Active Lucchetto UI ──────────────────────────────────────────────────
  return (
    <div className={`space-y-6 max-w-sm mx-auto transition-transform duration-200 ${result === "wrong" ? "animate-shake" : ""}`}>
      {/* Header Info Panel */}
      <div className="surface p-4 rounded-2xl border border-border/40 space-y-1 text-center">
        <div className="flex items-center justify-center gap-2">
          <Lock className="size-4 text-primary" />
          <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">
            Lucchetto Direzionale
          </p>
        </div>
        <p className="text-[11px] text-muted-foreground leading-relaxed">
          Risolvi l'enigma su carta per trovare la sequenza corretta di 4 direzioni.
        </p>
        {attemptCount > 0 && (
          <p className="text-[10px] text-muted-foreground mt-1">
            Tentativi effettuati: <span className="font-bold text-foreground">{attemptCount}</span>
          </p>
        )}
      </div>

      {/* Top Indicators */}
      <div className="flex justify-center gap-5 py-2">
        {[0, 1, 2, 3].map((i) => {
          const hasDir = selectedDirections[i] !== undefined;
          return (
            <div
              key={i}
              className={`
                size-5 rounded-full border-2 transition-all duration-300 flex items-center justify-center
                ${result === "wrong"
                  ? "border-destructive bg-destructive/30 scale-105"
                  : hasDir
                  ? "border-primary bg-primary shadow-lg shadow-primary/30 scale-110"
                  : "border-muted-foreground/30 bg-transparent"
                }
              `}
            >
              {hasDir && <div className="size-1.5 rounded-full bg-white animate-pop-in" />}
            </div>
          );
        })}
      </div>

      {/* Grid Status Message */}
      {result === "wrong" && (
        <div className="bg-destructive/10 border border-destructive/20 text-destructive text-center py-3 rounded-2xl animate-in fade-in duration-200 space-y-1">
          <p className="text-xs font-bold">✕ SEQUENZA ERRATA</p>
          <p className="text-sm font-black text-destructive animate-bounce">-8 PUNTI</p>
          <p className="text-[10px] text-muted-foreground/80">Riprova.</p>
        </div>
      )}

      {/* 3x3 Directional Pad */}
      <div className="relative surface rounded-3xl border border-border/30 p-6 flex justify-center items-center bg-[#070d1e]/80 shadow-xl shadow-black/20">
        {/* Floating score loss animation inside the pad container */}
        {result === "wrong" && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-50">
            <span className="animate-score-loss text-red-500 font-display font-black text-6xl tracking-widest drop-shadow-[0_4px_16px_rgba(239,68,68,0.6)]">
              -8
            </span>
          </div>
        )}
        
        <div className="grid grid-cols-3 gap-4 w-64 h-64">
          {BUTTONS.map((btn, index) => {
            if (btn === null) {
              // Central dot
              return (
                <div key="dot" className="flex items-center justify-center">
                  <div className="size-3.5 rounded-full bg-muted-foreground/30" />
                </div>
              );
            }

            const Icon = btn.icon;
            const isActive = activeBtn === btn.key;
            const isDisabled = result === "loading" || selectedDirections.length >= 4;

            return (
              <button
                key={btn.key}
                type="button"
                onPointerDown={() => handleDirectionPress(btn.key)}
                disabled={isDisabled}
                className={`
                  flex items-center justify-center rounded-2xl border transition-all duration-150 select-none
                  aspect-square touch-manipulation cursor-pointer active:scale-95
                  ${isActive
                    ? "bg-primary/20 border-primary text-primary scale-95 shadow-inner"
                    : "bg-secondary/20 border-border/40 text-foreground/80 hover:bg-secondary/40 hover:text-foreground"
                  }
                  disabled:opacity-40 disabled:cursor-not-allowed
                `}
                aria-label={btn.key}
              >
                <Icon className={`size-7 transition-transform ${isActive ? "scale-110" : ""}`} />
              </button>
            );
          })}
        </div>
      </div>

      {/* Lower Buttons */}
      <div className="grid grid-cols-2 gap-3">
        <button
          type="button"
          onClick={handleClear}
          disabled={selectedDirections.length === 0 || result === "loading"}
          className="py-4 rounded-2xl border border-border/80 font-extrabold text-muted-foreground hover:text-foreground hover:border-foreground/30 transition-all active:scale-95 disabled:opacity-30 cursor-pointer text-sm"
        >
          Cancella
        </button>
        <button
          type="button"
          onClick={handleValidate}
          disabled={selectedDirections.length !== 4 || result === "loading"}
          className="py-4 rounded-2xl primary-gradient font-extrabold text-primary-foreground flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-30 cursor-pointer text-sm shadow-lg shadow-primary/25"
        >
          {result === "loading" ? (
            <><Loader2 className="size-4 animate-spin" /> Verifico...</>
          ) : (
            "Conferma"
          )}
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
