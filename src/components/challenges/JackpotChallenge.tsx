import { useState, useEffect, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, Coins, Sparkles, AlertTriangle, ArrowRight, ShieldAlert, Award } from "lucide-react";
import { toast } from "sonner";

interface JackpotChallengeProps {
  challengeId: string;
  teamId: string;
  onComplete: () => void;
}

const SYMBOLS = ["🍒", "🍋", "🔔", "💎"];

export default function JackpotChallenge({ challengeId, teamId, onComplete }: JackpotChallengeProps) {
  const queryClient = useQueryClient();

  // 1. Fetch Jackpot state
  const { data: jackpotState, isLoading: loadingState, refetch: refetchState } = useQuery({
    queryKey: ["jackpot_state", teamId],
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_jackpot_state", {
        p_team_id: teamId || null
      });
      if (error) throw error;
      return data as { played: boolean; play: any | null; current_score: number };
    },
    refetchInterval: 5000
  });

  // UI state hooks (placed top-level)
  const [puntata, setPuntata] = useState<number>(10);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isPlayingAnimation, setIsPlayingAnimation] = useState(false);
  const [reel1, setReel1] = useState("🍒");
  const [reel2, setReel2] = useState("🍋");
  const [reel3, setReel3] = useState("🔔");
  const [isSpinning1, setIsSpinning1] = useState(false);
  const [isSpinning2, setIsSpinning2] = useState(false);
  const [isSpinning3, setIsSpinning3] = useState(false);
  const [showResultCard, setShowResultCard] = useState(false);
  const [animationResult, setAnimationResult] = useState<any>(null);

  // References for intervals
  const interval1Ref = useRef<any>(null);
  const interval2Ref = useRef<any>(null);
  const interval3Ref = useRef<any>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  // 2. Play mutation
  const playMutation = useMutation({
    mutationFn: async (selectedPuntata: number) => {
      const { data, error } = await supabase.rpc("play_jackpot", {
        p_team_id: teamId || null,
        p_puntata: selectedPuntata
      });
      if (error) throw error;
      return data;
    },
    onSuccess: (data: any) => {
      // Start the slot machine animation using the backend results!
      startSlotAnimation(data);
    },
    onError: (err: any) => {
      toast.error(err.message || "Errore durante la giocata.");
      setShowConfirm(false);
    }
  });

  // Handle local state cleanup on unmount
  useEffect(() => {
    return () => {
      if (interval1Ref.current) clearInterval(interval1Ref.current);
      if (interval2Ref.current) clearInterval(interval2Ref.current);
      if (interval3Ref.current) clearInterval(interval3Ref.current);
    };
  }, []);

  // Update initial bet based on available points when loaded
  const currentPoints = jackpotState?.current_score ?? 0;
  useEffect(() => {
    if (jackpotState && !jackpotState.played) {
      const maxPuntata = Math.min(20, currentPoints);
      if (maxPuntata < 5) {
        setPuntata(maxPuntata);
      } else {
        setPuntata(10);
      }
    }
  }, [jackpotState, currentPoints]);

  // Canvas confetti animation helper
  useEffect(() => {
    if (!showResultCard || !animationResult || animationResult.risultato !== "vinta" || !canvasRef.current) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    canvas.width = canvas.parentElement?.clientWidth || 400;
    canvas.height = canvas.parentElement?.clientHeight || 300;

    const colors = ["#f59e0b", "#10b981", "#3b82f6", "#ec4899", "#8b5cf6"];
    const particles = Array.from({ length: 80 }).map(() => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height - canvas.height,
      r: Math.random() * 6 + 4,
      d: Math.random() * canvas.height,
      color: colors[Math.floor(Math.random() * colors.length)],
      tilt: Math.random() * 10 - 5,
      tiltAngleIncremental: Math.random() * 0.07 + 0.02,
      tiltAngle: 0
    }));

    let animationFrameId: number;
    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particles.forEach((p, idx) => {
        p.tiltAngle += p.tiltAngleIncremental;
        p.y += (Math.cos(p.d) + 3 + p.r / 2) / 2;
        p.x += Math.sin(p.tiltAngle);
        p.tilt = Math.sin(p.tiltAngle - idx / 3) * 15;

        ctx.beginPath();
        ctx.lineWidth = p.r;
        ctx.strokeStyle = p.color || "#f59e0b";
        ctx.moveTo(p.x + p.tilt + p.r / 2, p.y);
        ctx.lineTo(p.x + p.tilt, p.y + p.tilt + p.r / 2);
        ctx.stroke();

        // Loop particles when they hit bottom
        if (p.y > canvas.height) {
          particles[idx] = {
            ...p,
            x: Math.random() * canvas.width,
            y: -20,
            tilt: Math.random() * 10 - 5
          };
        }
      });

      animationFrameId = requestAnimationFrame(draw);
    };

    draw();

    return () => {
      cancelAnimationFrame(animationFrameId);
    };
  }, [showResultCard, animationResult]);

  // Slot spinning animation logic
  const startSlotAnimation = (result: any) => {
    setIsPlayingAnimation(true);
    setShowConfirm(false);
    setAnimationResult(result);
    setShowResultCard(false);

    // Extract symbols from backend string: e.g. "🍒,🍋,🔔"
    const finalSymbols = result.simboli.split(",");

    setIsSpinning1(true);
    setIsSpinning2(true);
    setIsSpinning3(true);

    // Reel 1 spin interval
    interval1Ref.current = setInterval(() => {
      setReel1(SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)] || "🍒");
    }, 80);

    // Reel 2 spin interval
    interval2Ref.current = setInterval(() => {
      setReel2(SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)] || "🍒");
    }, 85);

    // Reel 3 spin interval
    interval3Ref.current = setInterval(() => {
      setReel3(SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)] || "🍒");
    }, 90);

    // Stop Reel 1 (after 1.5s)
    setTimeout(() => {
      if (interval1Ref.current) clearInterval(interval1Ref.current);
      setReel1(finalSymbols[0] || "🍒");
      setIsSpinning1(false);
    }, 1500);

    // Stop Reel 2 (after 2.6s)
    setTimeout(() => {
      if (interval2Ref.current) clearInterval(interval2Ref.current);
      setReel2(finalSymbols[1] || "🍒");
      setIsSpinning2(false);
    }, 2600);

    // Stop Reel 3 (after 4.0s for maximum suspense)
    setTimeout(() => {
      if (interval3Ref.current) clearInterval(interval3Ref.current);
      setReel3(finalSymbols[2] || "🍒");
      setIsSpinning3(false);
      
      // Complete animation, show result card
      setTimeout(() => {
        setIsPlayingAnimation(false);
        setShowResultCard(true);
        // Invalidate state to persist results
        queryClient.invalidateQueries({ queryKey: ["jackpot_state", teamId] });
        queryClient.invalidateQueries({ queryKey: ["my-team-score"] });
        queryClient.invalidateQueries({ queryKey: ["leaderboard"] });
        onComplete();
      }, 500);
    }, 4000);
  };

  if (loadingState) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-3">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Inizializzazione Jackpot della Regia...</p>
      </div>
    );
  }

  const alreadyPlayed = jackpotState?.played ?? false;
  const playData = jackpotState?.play ?? null;

  // Render utilized bonus state
  if (alreadyPlayed && playData) {
    const symbolsArr = playData.simboli.split(",");
    const isVinta = playData.risultato === "vinta";

    return (
      <div className="space-y-6 w-full max-w-md mx-auto p-1 animate-in fade-in duration-300">
        <div className="surface p-5 rounded-2xl border border-border/40 text-center space-y-2 relative overflow-hidden bg-gradient-to-b from-[#1c0f16] to-[#0d070b]">
          <div className="absolute top-2 right-2">
            <span className="bg-muted/20 border border-border/30 text-muted-foreground text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full">
              🔒 Bonus Utilizzato
            </span>
          </div>
          <div className="inline-flex size-12 items-center justify-center rounded-full bg-primary/10 border border-primary/20 mx-auto text-primary">
            🎰
          </div>
          <div>
            <h2 className="text-xl font-display font-black uppercase tracking-wider text-foreground">
              Jackpot della Regia
            </h2>
            <p className="text-xs text-muted-foreground">
              Sfida Bonus Facoltativa — Giocata già effettuata
            </p>
          </div>
        </div>

        {/* Display Slot Reels Stopped */}
        <div className="surface p-6 rounded-3xl border border-border/30 bg-zinc-950/80 text-center space-y-6">
          <div className="flex justify-center gap-4 py-2">
            {symbolsArr.map((sym: string, i: number) => (
              <div
                key={i}
                className="size-20 flex items-center justify-center rounded-2xl bg-zinc-900 border border-border/40 text-4xl shadow-inner select-none"
              >
                {sym}
              </div>
            ))}
          </div>

          <div className={`p-4 rounded-2xl border ${
            isVinta 
              ? "bg-success/15 border-success/30 text-success" 
              : "bg-destructive/15 border-destructive/30 text-destructive"
          }`}>
            <h3 className="text-base font-black uppercase tracking-wider">
              {isVinta ? "🏆 VITTORIA!" : "❌ SCONFITTA"}
            </h3>
            <p className="text-xs font-semibold mt-1">
              Puntata: <span className="font-black text-foreground">{playData.puntata} PT</span>
            </p>
            <p className="text-xs font-semibold">
              Variazione: <span className="font-black text-foreground">{isVinta ? `+${playData.puntata}` : `-${playData.puntata}`} PT</span>
            </p>
            <p className="text-[10px] text-muted-foreground/80 mt-2">
              Giocata registrata il {new Date(playData.timestamp).toLocaleString("it-IT", {
                day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit"
              })}
            </p>
          </div>

          <div className="bg-zinc-900/40 p-4 rounded-xl border border-border/20">
            <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">
              Punteggio Generale Aggiornato:
            </p>
            <p className="text-2xl font-black text-primary mt-1">
              {playData.punteggio_attuale} PT
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Minimum points to place a bet is 5.
  // If team has fewer than 5 points, they cannot bet.
  const isEligibleToPlay = currentPoints >= 5;

  return (
    <div className="space-y-6 w-full max-w-md mx-auto p-1 animate-in fade-in duration-300">
      {/* Header Info */}
      <div className="surface p-5 rounded-2xl border border-border/40 text-center space-y-2 relative overflow-hidden bg-gradient-to-b from-[#1c0f16] to-[#0d070b]">
        <div className="absolute top-2 right-2">
          <span className="bg-[#f59e0b]/20 border border-[#f59e0b]/30 text-[#f59e0b] text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full">
            🎁 Facoltativa
          </span>
        </div>
        <div className="inline-flex size-12 items-center justify-center rounded-full bg-primary/10 border border-primary/20 mx-auto text-primary">
          🎰
        </div>
        <div>
          <h2 className="text-xl font-display font-black uppercase tracking-wider text-foreground flex items-center justify-center gap-1.5">
            🎰 Jackpot della Regia
          </h2>
          <p className="text-xs text-muted-foreground mt-1 max-w-xs mx-auto">
            Vuoi rischiare alcuni dei tuoi punti? Puoi giocare una sola volta o proseguire senza scommettere nulla.
          </p>
        </div>
      </div>

      {/* Slots Machine Interactive Panel */}
      {!isPlayingAnimation && !showResultCard && (
        <div className="space-y-6">
          <div className="surface p-6 rounded-3xl border border-border/30 bg-zinc-950/80 space-y-5">
            <div className="text-center space-y-1">
              <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-widest">
                Il tuo punteggio attuale
              </p>
              <p className="text-3xl font-black text-primary flex items-center justify-center gap-1.5">
                <Coins className="size-6 text-gold animate-bounce" /> {currentPoints} <span className="text-xs font-bold text-muted-foreground">PT</span>
              </p>
            </div>

            {/* Betting limits description */}
            <div className="bg-zinc-900/60 p-4 rounded-xl border border-border/20 text-[11px] text-muted-foreground space-y-1.5">
              <p>🎰 <b>Regole della Slot:</b></p>
              <p>• Puoi scommettere da un minimo di <b>5 PT</b> a un massimo di <b>20 PT</b>.</p>
              <p>• Non puoi scommettere più punti di quanti ne possiedi attualmente.</p>
              <p>• La slot ha 3 rulli con 4 simboli (🍒, 🍋, 🔔, 💎) equiprobabili.</p>
              <p>• Se ottieni <b>3 simboli uguali</b> vinci la scommessa. Altrimenti perdi la puntata.</p>
            </div>

            {isEligibleToPlay ? (
              <div className="space-y-5 pt-2">
                {/* Bet Slider Control */}
                <div className="space-y-3">
                  <div className="flex justify-between items-center text-xs font-bold">
                    <span className="text-muted-foreground uppercase">Quanto punti vuoi rischiare?</span>
                    <span className="text-foreground text-sm font-black bg-primary/10 border border-primary/20 px-3 py-1 rounded-lg">
                      {puntata} PT
                    </span>
                  </div>

                  <input
                    type="range"
                    min={5}
                    max={Math.min(20, currentPoints)}
                    value={puntata}
                    onChange={(e) => setPuntata(Number(e.target.value))}
                    className="w-full h-1.5 bg-zinc-800 rounded-lg appearance-none cursor-pointer accent-primary"
                  />

                  <div className="flex justify-between text-[10px] text-muted-foreground font-black uppercase">
                    <span>Min: 5 PT</span>
                    <span>Max: {Math.min(20, currentPoints)} PT</span>
                  </div>
                </div>

                {/* Win / Loss Preview */}
                <div className="grid grid-cols-2 gap-3 text-center text-xs">
                  <div className="p-2.5 rounded-xl bg-success/10 border border-success/20 text-success">
                    <p className="text-[10px] uppercase font-bold tracking-wider opacity-85">Se vinci</p>
                    <p className="font-black text-sm mt-0.5">+{puntata} PT</p>
                  </div>
                  <div className="p-2.5 rounded-xl bg-destructive/10 border border-destructive/20 text-destructive">
                    <p className="text-[10px] uppercase font-bold tracking-wider opacity-85">Se perdi</p>
                    <p className="font-black text-sm mt-0.5">-{puntata} PT</p>
                  </div>
                </div>

                {/* Bet button */}
                <button
                  type="button"
                  onClick={() => setShowConfirm(true)}
                  className="primary-gradient glow w-full py-4 px-6 text-primary-foreground font-black text-sm rounded-2xl shadow-lg transition-transform hover:scale-[1.01] active:scale-95 cursor-pointer flex items-center justify-center gap-2"
                >
                  <Sparkles className="size-4 text-primary-foreground" /> 🎰 GIOCA ORA
                </button>
              </div>
            ) : (
              <div className="p-4 bg-amber-950/20 border border-amber-500/20 rounded-xl text-center space-y-1.5">
                <ShieldAlert className="size-6 text-amber-500 mx-auto" />
                <p className="text-xs font-bold text-amber-500 uppercase">Non idoneo a giocare</p>
                <p className="text-[10px] text-muted-foreground">
                  Possiedi {currentPoints} PT. Per effettuare la scommessa è necessario avere almeno un saldo minimo di 5 punti.
                </p>
              </div>
            )}
          </div>

          {/* Option to skip without playing */}
          <div className="text-center">
            <p className="text-[11px] text-muted-foreground">
              Non vuoi rischiare i tuoi punti? Puoi semplicemente lasciare questa schermata ed accedere al Traguardo Finale.
            </p>
          </div>
        </div>
      )}

      {/* Confirmation Modal overlay */}
      {showConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-zinc-950/70 p-4 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="surface w-full max-w-sm border border-primary/20 bg-zinc-900 rounded-3xl p-6 space-y-6 shadow-2xl animate-in scale-in duration-200">
            <div className="text-center space-y-2">
              <AlertTriangle className="size-10 text-[#f59e0b] mx-auto animate-bounce" />
              <h3 className="text-base font-black uppercase text-foreground">
                Confermi la scommessa?
              </h3>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Stai per rischiare <span className="text-primary font-black">{puntata} punti</span>. 
                Puoi giocare una sola volta e questa operazione è definitiva ed irreversibile.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4 text-center text-xs font-black uppercase tracking-wider">
              <div className="p-3 bg-success/15 border border-success/30 rounded-2xl text-success">
                Vittoria: +{puntata} PT
              </div>
              <div className="p-3 bg-destructive/15 border border-destructive/30 rounded-2xl text-destructive">
                Sconfitta: -{puntata} PT
              </div>
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setShowConfirm(false)}
                disabled={playMutation.isPending}
                className="flex-1 py-3 px-4 bg-zinc-800 hover:bg-zinc-700 text-muted-foreground font-black text-xs rounded-xl active:scale-95 transition-all cursor-pointer disabled:opacity-50"
              >
                ANNULLA
              </button>
              <button
                type="button"
                onClick={() => playMutation.mutate(puntata)}
                disabled={playMutation.isPending}
                className="flex-1 py-3 px-4 primary-gradient glow text-primary-foreground font-black text-xs rounded-xl active:scale-95 transition-transform cursor-pointer disabled:opacity-50 flex items-center justify-center gap-1.5"
              >
                {playMutation.isPending ? (
                  <Loader2 className="size-4 animate-spin" />
                ) : (
                  "CONFERMA E GIOCA"
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Reel spining animation layout */}
      {isPlayingAnimation && (
        <div className="surface p-6 rounded-3xl border border-primary/30 bg-zinc-950/90 text-center space-y-6 relative overflow-hidden">
          <div className="space-y-1">
            <p className="text-[10px] text-primary font-black uppercase tracking-widest animate-pulse">
              🎰 I RULLI STANNO GIRANDO...
            </p>
            <p className="text-xs text-muted-foreground">
              Puntata a rischio: <span className="font-black text-foreground">{puntata} PT</span>
            </p>
          </div>

          <div className="flex justify-center gap-4 py-4 relative z-10">
            {/* Reel 1 */}
            <div className={`size-24 flex items-center justify-center rounded-2xl bg-zinc-900 border ${
              isSpinning1 
                ? "border-primary/50 bg-gradient-to-b from-zinc-900 via-primary/5 to-zinc-900 animate-pulse" 
                : "border-border/40"
            } text-5xl shadow-2xl transition-all duration-300`}>
              {reel1}
            </div>

            {/* Reel 2 */}
            <div className={`size-24 flex items-center justify-center rounded-2xl bg-zinc-900 border ${
              isSpinning2 
                ? "border-primary/50 bg-gradient-to-b from-zinc-900 via-primary/5 to-zinc-900 animate-pulse" 
                : "border-border/40"
            } text-5xl shadow-2xl transition-all duration-300`}>
              {reel2}
            </div>

            {/* Reel 3 */}
            <div className={`size-24 flex items-center justify-center rounded-2xl bg-zinc-900 border ${
              isSpinning3 
                ? "border-primary/50 bg-gradient-to-b from-zinc-900 via-primary/5 to-zinc-900 animate-pulse" 
                : "border-border/40"
            } text-5xl shadow-2xl transition-all duration-300`}>
              {reel3}
            </div>
          </div>

          <div className="py-2">
            <Loader2 className="size-5 animate-spin text-primary mx-auto" />
          </div>
        </div>
      )}

      {/* Result Card overlay */}
      {showResultCard && animationResult && (
        <div className="surface border border-border/30 bg-zinc-950 p-6 rounded-3xl text-center space-y-5 animate-in fade-in duration-500 relative overflow-hidden">
          {/* Confetti canvas hook */}
          <canvas ref={canvasRef} className="absolute inset-0 z-0 pointer-events-none w-full h-full" />

          <div className="relative z-10 space-y-5">
            <div className="flex justify-center gap-4">
              {animationResult.simboli.split(",").map((sym: string, i: number) => (
                <div
                  key={i}
                  className="size-20 flex items-center justify-center rounded-2xl bg-zinc-900 border border-border/40 text-4xl shadow-inner select-none"
                >
                  {sym}
                </div>
              ))}
            </div>

            {animationResult.risultato === "vinta" ? (
              <div className="space-y-3">
                <div className="inline-flex size-14 items-center justify-center rounded-full bg-success/15 border border-success/30 text-success animate-bounce">
                  <Award className="size-7" />
                </div>
                <div>
                  <h3 className="text-xl font-display font-black uppercase tracking-wider text-success">
                    🎉 JACKPOT!
                  </h3>
                  <p className="text-sm font-bold text-foreground mt-1">
                    Hai indovinato la combinazione vincente!
                  </p>
                  <p className="text-base font-black text-success mt-2">
                    +{animationResult.puntata} PUNTI 🏆
                  </p>
                </div>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="inline-flex size-14 items-center justify-center rounded-full bg-destructive/15 border border-destructive/30 text-destructive">
                  💥
                </div>
                <div>
                  <h3 className="text-xl font-display font-black uppercase tracking-wider text-destructive">
                    NIENTE JACKPOT
                  </h3>
                  <p className="text-sm font-bold text-foreground mt-1">
                    Non hai ottenuto tre simboli uguali.
                  </p>
                  <p className="text-base font-black text-destructive mt-2">
                    -{animationResult.puntata} PUNTI 💔
                  </p>
                </div>
              </div>
            )}

            <div className="bg-zinc-900/60 p-4 rounded-2xl border border-border/20 grid grid-cols-2 gap-4 text-xs font-semibold text-muted-foreground">
              <div>
                <p>Punteggio Precedente</p>
                <p className="text-sm font-black text-foreground mt-0.5">{animationResult.punteggio_precedente} PT</p>
              </div>
              <div className="border-l border-border/10">
                <p>Nuovo Punteggio</p>
                <p className="text-sm font-black text-primary mt-0.5">{animationResult.punteggio_attuale} PT</p>
              </div>
            </div>

            <button
              onClick={() => {
                setShowResultCard(false);
                refetchState();
              }}
              className="w-full py-3.5 px-5 bg-zinc-800 hover:bg-zinc-700 text-foreground font-black text-xs rounded-xl active:scale-95 transition-all cursor-pointer flex items-center justify-center gap-1.5"
            >
              ACCEDI AI RISULTATI <ArrowRight className="size-3.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
