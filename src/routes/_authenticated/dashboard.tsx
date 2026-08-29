import { useEffect, useState } from "react";
import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Flag, Sparkles, Timer, Trophy, ChevronRight, Check, Coins, Loader2, Shield, Zap, PhoneCall, Clock } from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { ProgressBar } from "@/components/ProgressBar";
import { CircularProgress } from "@/components/ui/circular-progress";
import { HeroAvatar } from "@/components/ui/avatar";
import { RaceTimer } from "@/components/RaceTimer";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { triggerHaptic } from "@/lib/haptics";
import {
  challengeState,
  challengesQuery,
  formatDuration,
  leaderboardQuery,
  myTeamQuery,
  progressQuery,
  rankLeaderboard,
  sessionsQuery,
  stagesQuery,
  isStageUnlocked,
} from "@/lib/race";

const MARKETPLACE_ITEMS = [
  { id: "bonus_punti", nome: "BONUS PUNTI", categoria: "BONUS" },
  { id: "bonus_scudo", nome: "BONUS SCUDO", categoria: "BONUS" },
  { id: "ruota_fortuna", nome: "RUOTA DELLA FORTUNA", categoria: "BONUS" },
  { id: "passaparola", nome: "PASSAPAROLA", categoria: "BONUS" },
  { id: "bonus_classifica", nome: "BONUS CLASSIFICA", categoria: "BONUS" },
  { id: "partenza_anticipata", nome: "PARTENZA ANTICIPATA", categoria: "BONUS" },
  { id: "freeze_2min", nome: "FREEZE 2 MINUTI", categoria: "MALUS" },
  { id: "enigma_extra", nome: "ENIGMA EXTRA", categoria: "MALUS" },
  { id: "ruota_sfortunata", nome: "RUOTA SFORTUNATA", categoria: "MALUS" },
  { id: "trappola", nome: "TRAPPOLA", categoria: "MALUS" },
  { id: "penalita_punti", nome: "PENALITÀ PUNTI (-20 PT)", categoria: "MALUS" },
  { id: "tassa_passaggio", nome: "TASSA DI PASSAGGIO", categoria: "MALUS" },
];

export const Route = createFileRoute("/_authenticated/dashboard")({
  head: () => ({
    meta: [
      { title: "Dashboard squadra — Pechino Express Bra" },
      {
        name: "description",
        content: "Punti, timer, progresso tappe e prova corrente della tua squadra.",
      },
      { property: "og:title", content: "Dashboard squadra — Pechino Express Bra" },
      { property: "og:description", content: "Segui la tua gara in tempo reale." },
    ],
  }),
  component: Dashboard,
});

function Dashboard() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);

  const [usePassaparolaTx, setUsePassaparolaTx] = useState<any | null>(null);
  const [passaparolaText, setPassaparolaText] = useState("");
  const [isSendingPassaparola, setIsSendingPassaparola] = useState(false);

  const [dismissedShieldId, setDismissedShieldId] = useState<string | null>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("dismissed_shield_notification");
    }
    return null;
  });

  const handleDismissShieldAlert = (shieldId: string) => {
    localStorage.setItem("dismissed_shield_notification", shieldId);
    setDismissedShieldId(shieldId);
  };

  const [dismissedRewards, setDismissedRewards] = useState<string[]>(() => {
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("dismissed_stage_rewards");
      return stored ? JSON.parse(stored) : [];
    }
    return [];
  });

  const handleDismissReward = (stageId: string) => {
    const updated = [...dismissedRewards, stageId];
    localStorage.setItem("dismissed_stage_rewards", JSON.stringify(updated));
    setDismissedRewards(updated);
  };

  const team = useQuery(myTeamQuery);
  const stages = useQuery(stagesQuery);
  const challenges = useQuery(challengesQuery);
  const progress = useQuery({ ...progressQuery(team.data?.id), refetchInterval: 3000 });
  const sessions = useQuery({ ...sessionsQuery(team.data?.id), refetchInterval: 3000 });
  const board = useQuery({ ...leaderboardQuery, refetchInterval: 3000 });

  // Fetch all transactions
  const transactionsQuery = useQuery({
    queryKey: ["marketplace-transactions-list"],
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id,costo:costo_token,timestamp:data_acquisto,outcome:dettagli")
        .order("data_acquisto", { ascending: false });
      if (error) {
        console.warn("Error transactionsQuery dashboard:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch all teams
  const teamsQuery = useQuery({
    queryKey: ["all-teams-list"],
    staleTime: 0,
    refetchInterval: 5000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("teams")
        .select("*")
        .eq("active", true);
      if (error) {
        console.warn("Error teamsQuery dashboard:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  const [totalElapsed, setTotalElapsed] = useState<number | null>(null);

  useEffect(() => {
    if (!stages.data || !challenges.data || !progress.data) return;

    const allStages = stages.data;
    const allChs = challenges.data;
    const progList = progress.data;

    const updateTimer = () => {
      let sumSeconds = 0;

      allStages.forEach((s) => {
        const stageChs = allChs.filter((c) => c.stage_id === s.id);
        if (stageChs.length === 0) return;

        const stageProgs = progList.filter((p) => stageChs.some((c) => c.id === p.challenge_id));
        if (stageProgs.length === 0) return;

        const startTimes = stageProgs.map((p) => p.started_at ? new Date(p.started_at).getTime() : 0).filter(Boolean);
        if (startTimes.length === 0) return;
        const minStart = Math.min(...startTimes);

        const completedChs = stageProgs.filter((p) => p.status === "completed");
        const allCompleted = stageChs.every((c) => completedChs.some((p) => p.challenge_id === c.id));

        if (allCompleted) {
          const completionTimes = completedChs.map((p) => p.completed_at ? new Date(p.completed_at).getTime() : 0).filter(Boolean);
          if (completionTimes.length > 0) {
            const maxCompletion = Math.max(...completionTimes);
            const duration = Math.max(0, Math.round((maxCompletion - minStart) / 1000));
            sumSeconds += duration;
          }
        } else {
          const duration = Math.max(0, Math.round((Date.now() - minStart) / 1000));
          sumSeconds += duration;
        }
      });

      setTotalElapsed(sumSeconds);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [stages.data, challenges.data, progress.data]);

  useEffect(() => {
    if (isAdmin.data) {
      navigate({ to: "/admin", replace: true });
    }
  }, [isAdmin.data, navigate]);

  if (isAdmin.isLoading || isAdmin.data) {
    return (
      <AppShell isAdmin={isAdmin.data}>
        <div className="flex flex-col items-center justify-center py-20 space-y-4">
          <Loader2 className="size-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Inizializzazione sessione...</p>
        </div>
      </AppShell>
    );
  }

  const myScore = board.data?.find((r) => r.team_id === team.data?.id);
  const position = myScore?.rank ?? (rankLeaderboard(board.data ?? []).findIndex((r) => r.team_id === team.data?.id) + 1);

  const allChallenges = challenges.data ?? [];
  const allChallengeIds = new Set(allChallenges.map((c) => c.id));
  const prog = progress.data ?? [];
  // Only count progress entries whose challenge actually exists in the DB
  const completedCount = prog.filter((p) => p.status === "completed" && allChallengeIds.has(p.challenge_id)).length;
  const percent = allChallenges.length ? (completedCount / allChallenges.length) * 100 : 0;

  const currentStage = (stages.data ?? []).find((s) =>
    allChallenges
      .filter((c) => c.stage_id === s.id)
      .some((c) => challengeState(c, allChallenges.filter((x) => x.stage_id === s.id), prog) !== "completed"),
  );
  const stageChallenges = allChallenges.filter((c) => c.stage_id === currentStage?.id);
  const nextChallenge = stageChallenges.find(
    (c) => challengeState(c, stageChallenges, prog) === "available",
  );
  const activeSession = (sessions.data ?? []).find((s) => s.stage_id === currentStage?.id);

  // Check if Tappa 3 is unlocked
  const stage3 = stages.data?.find((s) => s.id === "3a3c3d3e-4f4a-4b4b-8c8c-9c9c9c9c9c9c");
  const isMarketplaceUnlocked = stage3 && stages.data && challenges.data && progress.data
    ? isStageUnlocked(stage3, stages.data, challenges.data, progress.data)
    : false;

  const transactions = transactionsQuery.data ?? [];
  const allTeams = teamsQuery.data ?? [];
  const myPurchases = team.data?.id ? transactions.filter((t) => t.buyer_team_id === team.data?.id) : [];
  
  const myBonuses = myPurchases.filter((t) => {
    const item = MARKETPLACE_ITEMS.find((i) => i.id === t.item_id);
    return item?.categoria === "BONUS";
  });

  const mySentMaluses = myPurchases.filter((t) => {
    const item = MARKETPLACE_ITEMS.find((i) => i.id === t.item_id);
    return item?.categoria === "MALUS";
  });

  const myReceivedMaluses = team.data?.id ? transactions.filter((t) => t.target_team_id === team.data?.id) : [];

  const activeShield = myPurchases.find((t) => t.item_id === "bonus_scudo" && t.stato === "completed");
  const consumedShield = myPurchases.find((t) => t.item_id === "bonus_scudo" && t.stato === "used");
  const blockedMalusItem = consumedShield?.blocked_info?.item_id;
  const blockedMalusDetails = blockedMalusItem ? MARKETPLACE_ITEMS.find((i) => i.id === blockedMalusItem) : null;
  const blockedMalusLabel = blockedMalusDetails?.nome || blockedMalusItem || "avversario";

  const activePartenza = myPurchases.find((t) => t.item_id === "partenza_anticipata" && t.stato === "completed");
  const usedPartenza = myPurchases.find((t) => t.item_id === "partenza_anticipata" && t.stato === "used");

  const activePassaparola = myPurchases.find((t) => t.item_id === "passaparola" && t.stato === "completed");
  const pendingPassaparola = myPurchases.find((t) => t.item_id === "passaparola" && t.stato === "pending");
  const answeredPassaparola = myPurchases.find((t) => t.item_id === "passaparola" && t.stato === "used");

  const handleSendPassaparola = async () => {
    if (!usePassaparolaTx) return;
    if (!passaparolaText.trim()) {
      toast.error("Inserisci la domanda per la Regia.");
      return;
    }
    setIsSendingPassaparola(true);
    try {
      const { data, error } = await (supabase as any).rpc("submit_passaparola_request", {
        p_transaction_id: usePassaparolaTx.id,
        p_request_text: passaparolaText.trim(),
      });
      if (error) {
        toast.error(`Errore: ${error.message || "Impossibile inviare la richiesta"}`);
        return;
      }
      toast.success("Richiesta inviata con successo alla Regia! Attendi risposta.");
      setUsePassaparolaTx(null);
      setPassaparolaText("");
      queryClient.invalidateQueries();
    } catch (err) {
      toast.error("Si è verificato un errore durante l'invio.");
    } finally {
      setIsSendingPassaparola(false);
    }
  };

  const isTeamFrozen = team.data?.freeze_expires_at && new Date(team.data.freeze_expires_at).getTime() > Date.now();
  const activeEnigma = myReceivedMaluses.find((t) => t.item_id === "enigma_extra" && t.stato === "completed");
  const solvedEnigma = myReceivedMaluses.find((t) => t.item_id === "enigma_extra" && t.stato === "used");
  const activeRuota = myReceivedMaluses.find((t) => t.item_id === "ruota_sfortunata" && t.stato === "completed");
  const solvedRuota = myReceivedMaluses.find((t) => t.item_id === "ruota_sfortunata" && t.stato === "used");

  // Find any closed stage rewards that need to be shown to the team
  const closedStageRewards = (stages.data ?? [])
    .filter((s: any) => (s.status === "closed" || s.stato === "closed") && !dismissedRewards.includes(s.id))
    .map((s: any) => {
      const tx = transactions.find(
        (t: any) => t.buyer_team_id === team.data?.id && t.item_id === "reward_stage" && t.outcome?.stage_id === s.id
      );
      if (!tx) return null;
      return { stage: s, tx };
    })
    .filter(Boolean) as Array<{ stage: any, tx: any }>;

  return (
    <AppShell isAdmin={isAdmin.data}>
      <div className="space-y-6 md:space-y-8 max-w-2xl mx-auto">
        
        {/* STAGE REWARD NOTIFICATIONS */}
        {closedStageRewards.map(({ stage, tx }) => {
          const outcome = tx.outcome;
          if (!outcome) return null;
          const medals = ["🥇", "🥈", "🥉"];
          const positionLabel = outcome.position === 1 ? "1ª" : outcome.position === 2 ? "2ª" : outcome.position === 3 ? "3ª" : `${outcome.position}ª`;
          const medal = medals[outcome.position - 1] ?? "🏁";

          return (
            <div
              key={stage.id}
              className="bg-yellow-500/10 border border-yellow-500/35 text-yellow-400 p-5 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-xs animate-in slide-in-from-top-4 duration-300 shadow-lg shadow-yellow-950/20"
            >
              <div className="flex items-start gap-3">
                <span className="text-3xl shrink-0 select-none mt-0.5">{medal}</span>
                <div className="space-y-1">
                  <h4 className="text-sm font-black uppercase tracking-wider">
                    Tappa Conclusa: {stage.title || stage.nome_tappa}
                  </h4>
                  <p className="text-zinc-300 text-xs leading-relaxed">
                    La Regia ha chiuso ufficialmente la tappa! La vostra squadra si è classificata in <strong className="text-yellow-400 font-extrabold">{positionLabel}</strong> posizione.
                  </p>
                  <div className="text-zinc-400 text-[11px] flex flex-wrap items-center gap-1.5 font-semibold mt-1">
                    <span>Accreditati: <strong className="text-emerald-400 font-extrabold">+{outcome.reward_tokens} Token</strong></span>
                    <span className="opacity-40">·</span>
                    <span>Saldo: {outcome.old_balance} → <strong className="text-yellow-400 font-extrabold">🪙 {outcome.new_balance} Token</strong></span>
                    {outcome.capped && (
                      <>
                        <span className="opacity-40">·</span>
                        <span className="bg-amber-500/20 text-amber-400 px-2 py-0.5 rounded text-[9px] font-black border border-amber-500/30 uppercase tracking-widest leading-none">
                          Limite 80 Raggiunto
                        </span>
                      </>
                    )}
                  </div>
                </div>
              </div>
              <button
                onClick={() => handleDismissReward(stage.id)}
                className="primary-gradient glow shrink-0 px-4 py-2.5 rounded-xl text-primary-foreground font-black text-xs uppercase tracking-wider cursor-pointer hover:scale-[1.02] active:scale-95 transition-all w-full sm:w-auto text-center shadow-md shadow-yellow-500/10"
              >
                OK, Ricevi
              </button>
            </div>
          );
        })}

        {/* CONSUMED SHIELD NOTIFICATION */}
        {consumedShield && dismissedShieldId !== consumedShield.id && (
          <div className="bg-blue-950/20 border border-blue-500/30 text-blue-400 p-4 rounded-2xl flex items-center justify-between text-xs animate-in slide-in-from-top-4 duration-300">
            <div className="flex items-center gap-3">
              <div className="size-8 rounded-full bg-blue-500/10 flex items-center justify-center shrink-0 border border-blue-500/20">
                <Shield className="size-4 text-blue-400 stroke-[2.5]" />
              </div>
              <div>
                <strong className="block text-sm uppercase tracking-wide font-black">🛡️ SCUDO ATTIVATO!</strong>
                <span className="text-muted-foreground">
                  Il Malus <strong className="text-foreground">{blockedMalusLabel}</strong> è stato completamente bloccato. Il tuo Scudo è stato consumato.
                </span>
              </div>
            </div>
            <button
              onClick={() => handleDismissShieldAlert(consumedShield.id)}
              className="text-xs font-black hover:text-white px-2 py-1 rounded hover:bg-white/5 transition-all shrink-0 ml-4 cursor-pointer"
            >
              ✕
            </button>
          </div>
        )}

        {/* TEAM COCKPIT HERO (UI/UX Pro Max Edition) */}
        <section
          className="hud-panel-glow animate-pop-in relative overflow-hidden p-5 sm:p-7 transition-all duration-300 w-full min-w-0 box-border"
          style={{
            borderColor: team.data?.color ? `${team.data.color}66` : undefined,
          }}
        >
          {/* BADGES CONTAINER (HeroUI Chip variant="dot" style) */}
          {(activeEnigma || solvedEnigma || activeRuota || solvedRuota || isTeamFrozen || activeShield || activePassaparola || pendingPassaparola || activePartenza || usedPartenza) && (
            <div className="flex flex-wrap items-center gap-1.5 mb-3 sm:absolute sm:top-5 sm:right-5 sm:mb-0 sm:flex-col sm:items-end z-10">
              {activeEnigma && (
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-950/60 border border-purple-500/40 text-purple-300 text-[10px] font-black uppercase tracking-wider shadow-sm backdrop-blur-md">
                  <span className="size-2 rounded-full bg-purple-400 animate-ping" />
                  <span>🧩 Enigma Extra</span>
                </div>
              )}
              {activeRuota && (
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-950/60 border border-amber-500/40 text-amber-300 text-[10px] font-black uppercase tracking-wider shadow-sm backdrop-blur-md">
                  <span className="size-2 rounded-full bg-amber-400 animate-ping" />
                  <span>🎡 Ruota Sfortunata</span>
                </div>
              )}
              {isTeamFrozen && (
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-950/60 border border-cyan-500/40 text-cyan-300 text-[10px] font-black uppercase tracking-wider shadow-sm backdrop-blur-md">
                  <span className="size-2 rounded-full bg-cyan-400 animate-ping" />
                  <span>❄️ Congelato</span>
                </div>
              )}
              {activeShield && (
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-950/60 border border-blue-500/40 text-blue-300 text-[10px] font-black uppercase tracking-wider shadow-sm backdrop-blur-md">
                  <span className="size-2 rounded-full bg-blue-400 animate-ping" />
                  <Shield className="size-3 text-blue-300 stroke-[3]" />
                  <span>Scudo Attivo</span>
                </div>
              )}
              {activePassaparola && (
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-950/60 border border-orange-500/40 text-orange-300 text-[10px] font-black uppercase tracking-wider shadow-sm backdrop-blur-md">
                  <span className="size-2 rounded-full bg-orange-400 animate-ping" />
                  <PhoneCall className="size-3 stroke-[3]" />
                  <span>Passaparola Disp.</span>
                </div>
              )}
            </div>
          )}

          {/* TEAM PROFILE ROW (HeroUI Avatar & Typography with Luxury Frame) */}
          <div className="flex items-center gap-4 sm:gap-5 min-w-0">
            <div
              className="p-1.5 rounded-3xl border-2 shadow-2xl transition-transform hover:scale-105 shrink-0"
              style={{
                borderColor: team.data?.color ?? "#f97316",
                backgroundColor: (team.data?.color ?? "#f97316") + "26",
                boxShadow: `0 0 25px -2px ${(team.data?.color ?? "#f97316")}66`,
              }}
            >
              <HeroAvatar
                emoji={team.data?.avatar_url ?? "🏳️"}
                color={team.data?.color ?? "#f97316"}
                isBordered
                radius="lg"
                size="xl"
                className="size-16 sm:size-20 text-3xl sm:text-4xl shadow-inner bg-zinc-950/80"
              />
            </div>
            <div className="min-w-0 flex-1">
              <h1 className="truncate text-2xl sm:text-4xl font-display font-extrabold uppercase tracking-wide text-foreground drop-shadow-sm">
                {team.data?.name ?? "Nessuna squadra"}
              </h1>
              {team.data?.motto && (
                <p className="truncate text-xs sm:text-sm text-muted-foreground font-semibold italic">
                  "{team.data.motto}"
                </p>
              )}
            </div>
          </div>

          {/* GAME METERS / GAUGES (HeroUI isBordered style with glow) */}
          <div className="mt-5 grid grid-cols-3 gap-2 sm:gap-3">
            {/* PUNTI */}
            <div className="group rounded-2xl bg-secondary/50 hover:bg-secondary/70 border border-border/60 hover:border-primary/40 p-3 sm:p-4 text-center flex flex-col justify-between shadow-sm transition-all duration-200">
              <div className="flex items-center justify-center gap-1 text-[10px] sm:text-[11px] font-black uppercase tracking-wider text-muted-foreground group-hover:text-primary transition-colors">
                <Sparkles className="size-3.5 text-primary" />
                <span>Punti</span>
              </div>
              <div className="font-display text-2xl sm:text-4xl font-black text-foreground mt-0.5 tracking-tight">
                {myScore?.total_points ?? 0}
              </div>
            </div>

            {/* TOKEN */}
            <div className="group rounded-2xl bg-secondary/50 hover:bg-secondary/70 border border-border/60 hover:border-amber-500/40 p-3 sm:p-4 text-center flex flex-col justify-between shadow-sm transition-all duration-200">
              <div className="flex items-center justify-center gap-1 text-[10px] sm:text-[11px] font-black uppercase tracking-wider text-muted-foreground group-hover:text-amber-400 transition-colors">
                <Coins className="size-3.5 text-amber-400" />
                <span>Token</span>
              </div>
              <div className="font-display text-2xl sm:text-4xl font-black text-amber-400 mt-0.5 tracking-tight drop-shadow-[0_0_8px_rgba(245,158,11,0.3)]">
                {team.data?.token_balance ?? 50}
              </div>
            </div>

            {/* TEMPO */}
            <div className="group rounded-2xl bg-secondary/50 hover:bg-secondary/70 border border-border/60 hover:border-cyan-500/40 p-3 sm:p-4 text-center flex flex-col justify-between shadow-sm transition-all duration-200">
              <div className="flex items-center justify-center gap-1 text-[10px] sm:text-[11px] font-black uppercase tracking-wider text-muted-foreground group-hover:text-cyan-400 transition-colors">
                <Timer className="size-3.5 text-accent" />
                <span>Tempo</span>
              </div>
              <div className="font-display text-2xl sm:text-4xl font-black text-foreground mt-0.5 tracking-tight">
                {totalElapsed !== null ? formatDuration(totalElapsed) : "--:--"}
              </div>
            </div>
          </div>

          {/* OVERALL RACE PROGRESS WITH CIRCULARPROGRESS RING (HeroUI CircularProgress Style) */}
          <div className="mt-5 pt-4 border-t border-border/40 flex items-center justify-between gap-4">
            <div className="space-y-1 min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <span className="uppercase tracking-widest text-[10px] font-black text-muted-foreground">Avanzamento Tappe</span>
                <span className="text-[10px] font-black text-primary bg-primary/10 px-2 py-0.5 rounded-full border border-primary/20">
                  {completedCount}/{allChallenges.length} Prove
                </span>
              </div>
              <ProgressBar value={percent} className="h-2.5 rounded-full bg-zinc-900" />
            </div>

            <div className="shrink-0">
              <CircularProgress
                value={percent}
                size={52}
                strokeWidth={5}
                color="text-primary"
                trackColor="text-zinc-800"
              >
                <span className="text-[11px] font-black text-foreground font-display">
                  {Math.round(percent)}%
                </span>
              </CircularProgress>
            </div>
          </div>
        </section>

        {/* PASSAPAROLA ACTIVE / PENDING / ANSWERED BANNER */}
        {activePassaparola && (
          <div className="hud-panel p-4.5 rounded-2xl bg-orange-500/10 border border-orange-500/35 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-lg shadow-orange-500/10 animate-fade-in">
            <div className="flex items-center gap-3">
              <div className="size-11 rounded-xl bg-orange-500/20 text-orange-400 flex items-center justify-center shrink-0 border border-orange-500/30">
                <PhoneCall className="size-5" />
              </div>
              <div className="space-y-0.5">
                <h4 className="text-xs font-black uppercase text-orange-400 tracking-wider">
                  📞 Bonus Passaparola Disponibile
                </h4>
                <p className="text-[11px] text-muted-foreground">
                  Hai un Passaparola attivo. Invia una domanda alla Regia per ricevere un <strong>SÌ</strong> o <strong>NO</strong>.
                </p>
              </div>
            </div>
            <button
              onClick={() => setUsePassaparolaTx(activePassaparola)}
              className="w-full sm:w-auto px-5 py-3 rounded-xl primary-gradient text-white font-black text-xs uppercase tracking-wider hover:brightness-110 active:scale-95 transition-all cursor-pointer whitespace-nowrap shadow-md flex items-center justify-center gap-2"
            >
              <PhoneCall className="size-4" />
              <span>Fai la Domanda</span>
            </button>
          </div>
        )}

        {pendingPassaparola && (
          <div className="hud-panel p-4 rounded-2xl bg-orange-500/5 border border-orange-500/20 space-y-2 shadow-sm animate-fade-in">
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-orange-400 font-extrabold uppercase tracking-wider flex items-center gap-1.5 animate-pulse">
                <Clock className="size-3.5" />
                Passaparola: In attesa di risposta dalla Regia
              </span>
              <span className="text-[9px] text-zinc-500 font-semibold">Inviato</span>
            </div>
            <div className="bg-zinc-950/40 p-3 rounded-xl border border-zinc-800/80 text-xs text-foreground font-semibold italic">
              "{pendingPassaparola.request_text || pendingPassaparola.outcome?.request_text || pendingPassaparola.dettagli?.request_text}"
            </div>
          </div>
        )}

        {answeredPassaparola && (
          <div className="hud-panel p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/20 space-y-2.5 shadow-sm animate-fade-in">
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-emerald-400 font-extrabold uppercase tracking-wider flex items-center gap-1.5">
                <PhoneCall className="size-3.5 text-emerald-400" />
                Risposta Regia Passaparola
              </span>
              <span className={`text-xs font-black px-2.5 py-0.5 rounded-lg border ${
                (answeredPassaparola.response_text || answeredPassaparola.outcome?.response_text || answeredPassaparola.dettagli?.response_text) === "SÌ"
                  ? "bg-emerald-500/20 text-emerald-300 border-emerald-500/30"
                  : "bg-rose-500/20 text-rose-300 border-rose-500/30"
              }`}>
                Risposta: {(answeredPassaparola.response_text || answeredPassaparola.outcome?.response_text || answeredPassaparola.dettagli?.response_text) === "SÌ" ? "✅ SÌ" : "❌ NO"}
              </span>
            </div>
            <div className="bg-zinc-950/40 p-3 rounded-xl border border-zinc-800/80 text-xs text-zinc-300 italic">
              "{answeredPassaparola.request_text || answeredPassaparola.outcome?.request_text || answeredPassaparola.dettagli?.request_text}"
            </div>
          </div>
        )}

        {/* MEGA-CARD: MISSIONE ATTIVA (HeroUI Card isFooterBlurred & Button variant="shadow") */}
        <section className="space-y-2.5">
          <div className="flex items-center justify-between pl-1">
            <h2 className="text-sm font-black uppercase tracking-widest text-primary flex items-center gap-2">
              <span className="inline-block size-2 rounded-full bg-primary animate-ping" />
              Missione Attiva
            </h2>
            {nextChallenge && (
              <span className="inline-flex items-center gap-1.5 text-[11px] font-black text-amber-400 bg-amber-500/10 px-2.5 py-0.5 rounded-full border border-amber-500/25">
                <span className="size-1.5 rounded-full bg-amber-400 animate-pulse" />
                +{nextChallenge.points} Punti
              </span>
            )}
          </div>

          {nextChallenge && currentStage ? (
            <div className="relative overflow-hidden rounded-3xl bg-zinc-950/70 border border-primary/30 p-5 sm:p-6 shadow-2xl shadow-black/60 space-y-4">
              {/* Top ambient glow */}
              <div className="absolute top-0 right-0 w-48 h-48 bg-primary/10 rounded-full blur-3xl pointer-events-none" />

              <div className="flex items-start justify-between gap-3 relative z-10">
                <div className="space-y-1.5 min-w-0">
                  <span className="text-[10px] font-black tracking-widest text-accent uppercase bg-accent/15 px-2.5 py-0.5 rounded-full border border-accent/30 inline-block">
                    {currentStage.title}
                  </span>
                  <h3 className="text-xl sm:text-2xl font-black text-foreground pt-0.5 tracking-tight leading-tight">
                    {nextChallenge.title}
                  </h3>
                  <p className="text-xs text-muted-foreground font-semibold leading-relaxed">
                    {nextChallenge.description || (nextChallenge.type === "jackpot" ? "Scommessa Bonus (Facoltativa)" : "Completa la prova per sbloccare il prossimo checkpoint.")}
                  </p>
                </div>
                <span className="primary-gradient grid size-12 shrink-0 place-items-center rounded-2xl text-white shadow-lg shadow-primary/30 border border-white/20">
                  {nextChallenge.type === "jackpot" ? "🎰" : <Flag className="size-6" />}
                </span>
              </div>

              {/* HEROUI ISFOOTERBLURRED ACTION BAR WITH GLOW BUTTON */}
              <div className="relative z-10 pt-2">
                <Link
                  to="/challenge/$challengeId"
                  params={{ challengeId: nextChallenge.id }}
                  onClick={() => triggerHaptic("medium")}
                  className="group relative w-full h-14 primary-gradient rounded-2xl flex items-center justify-center gap-2 text-white font-display font-black text-base uppercase tracking-wider shadow-lg shadow-primary/35 hover:shadow-primary/50 hover:brightness-110 active:scale-[0.97] transition-all duration-200 cursor-pointer overflow-hidden border border-white/20"
                >
                  <div className="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-700 bg-gradient-to-r from-transparent via-white/20 to-transparent" />
                  <span>VAI ALLA PROVA</span>
                  <ChevronRight className="size-5 stroke-[3] group-hover:translate-x-1 transition-transform" />
                </Link>
              </div>
            </div>
          ) : (
            <div className="rounded-3xl p-6 flex items-center gap-3.5 bg-emerald-950/30 border border-emerald-500/30 shadow-lg backdrop-blur-md">
              <div className="size-10 rounded-full bg-emerald-500/20 flex items-center justify-center text-emerald-400 shrink-0 border border-emerald-500/30 shadow-sm">
                <Check className="size-5 stroke-[3]" />
              </div>
              <p className="text-sm font-bold text-emerald-300">
                Tutte le prove disponibili sono state completate. Ottimo lavoro!
              </p>
            </div>
          )}
        </section>

        {/* MARKETPLACE SUMMARY SECTION */}
        {isMarketplaceUnlocked && (
          <section className="space-y-3 animate-fade-in">
            <div className="flex justify-between items-center pl-1">
              <h2 className="text-xl sm:text-2xl font-bold uppercase tracking-wider text-muted-foreground/80">
                🛒 Marketplace
              </h2>
              <Link
                to="/marketplace"
                className="text-xs font-extrabold text-primary hover:underline flex items-center gap-1"
              >
                Vai al Negozio <ChevronRight className="size-3" />
              </Link>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Bonus Acquistati */}
              <div className="hud-panel p-4 rounded-2xl space-y-2 flex flex-col justify-between">
                <div>
                  <span className="text-[10px] uppercase font-black tracking-widest text-emerald-400 block">
                    🎁 Bonus Acquistati
                  </span>
                  <div className="mt-2 space-y-1.5 max-h-[120px] overflow-y-auto pr-1">
                    {myBonuses.length === 0 ? (
                      <p className="text-[11px] text-muted-foreground italic font-semibold">Nessun bonus attivo</p>
                    ) : (
                      myBonuses.map((b) => {
                        const item = MARKETPLACE_ITEMS.find((i) => i.id === b.item_id);
                        const name = item?.nome || b.item_id;
                        const cost = b.costo ?? b.costo_token ?? (item as any)?.costo ?? 0;
                        return (
                          <div key={b.id} className="text-xs font-bold text-foreground bg-secondary/70 px-2.5 py-1.5 rounded-lg border border-border/50 flex items-center justify-between gap-1">
                            <span className="truncate">{name}</span>
                            <span className="text-[10px] text-emerald-400 font-black shrink-0">-{cost} 🪙</span>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>
              </div>

              {/* Malus Inviati */}
              <div className="hud-panel p-4 rounded-2xl space-y-2 flex flex-col justify-between">
                <div>
                  <span className="text-[10px] uppercase font-black tracking-widest text-rose-400 block">
                    ⚔️ Malus Inviati
                  </span>
                  <div className="mt-2 space-y-1.5 max-h-[120px] overflow-y-auto pr-1">
                    {mySentMaluses.length === 0 ? (
                      <p className="text-[11px] text-muted-foreground italic font-semibold">Nessun malus inviato</p>
                    ) : (
                      mySentMaluses.map((m) => {
                        const item = MARKETPLACE_ITEMS.find((i) => i.id === m.item_id);
                        const name = item?.nome || m.item_id;
                        const target = allTeams.find((t) => t.id === m.target_team_id)?.nome_squadra || "Sconosciuta";
                        const cost = m.costo ?? m.costo_token ?? (item as any)?.costo ?? 0;
                        return (
                          <div key={m.id} className="text-[11px] font-bold text-foreground bg-secondary/70 px-2.5 py-1.5 rounded-lg border border-border/50 flex flex-col gap-0.5 min-w-0">
                            <div className="flex items-center justify-between gap-1">
                              <span className="truncate">{name}</span>
                              <span className="text-[10px] text-rose-400 font-black shrink-0">-{cost} 🪙</span>
                            </div>
                            <span className="text-[9px] text-rose-400/90 font-extrabold truncate">→ {target}</span>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>
              </div>

              {/* Malus Ricevuti */}
              <div className="hud-panel p-4 rounded-2xl space-y-2 flex flex-col justify-between">
                <div>
                  <span className="text-[10px] uppercase font-black tracking-widest text-amber-400 block">
                    ⚠️ Malus Ricevuti
                  </span>
                  <div className="mt-2 space-y-1.5 max-h-[120px] overflow-y-auto pr-1">
                    {myReceivedMaluses.length === 0 ? (
                      <p className="text-[11px] text-muted-foreground italic font-semibold">Nessun malus ricevuto</p>
                    ) : (
                      myReceivedMaluses.map((m) => {
                        const name = MARKETPLACE_ITEMS.find((i) => i.id === m.item_id)?.nome || m.item_id;
                        const buyer = allTeams.find((t) => t.id === (m.buyer_team_id || m.team_id))?.nome_squadra || "Sconosciuta";
                        const isBlocked = m.stato === "expired" || (m.outcome && m.outcome.blocked_by_shield_id);
                        return (
                          <div key={m.id} className="text-[11px] font-bold text-foreground bg-secondary/70 px-2.5 py-1.5 rounded-lg border border-border/50 flex flex-col gap-0.5 min-w-0">
                            <div className="flex items-center justify-between gap-1">
                              <span className="truncate">{name}</span>
                              {isBlocked && <span className="text-[9px] text-emerald-400 font-black shrink-0">🛡️ Bloccato</span>}
                            </div>
                            <span className="text-[9px] text-amber-400 font-extrabold truncate">← {buyer}</span>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>
              </div>
            </div>
          </section>
        )}

        {/* TAPPE LIST */}
        <section className="space-y-3">
          <h2 className="text-sm font-black uppercase tracking-widest text-muted-foreground pl-1">
            Tappe di Gara
          </h2>
          <div className="space-y-3">
            {(stages.data ?? []).map((stage) => {
              const sc = allChallenges.filter((c) => c.stage_id === stage.id);
              const done = sc.filter(
                (c) => challengeState(c, sc, prog) === "completed",
              ).length;
              const isStageDone = sc.length > 0 && done === sc.length;

              return (
                <Link
                  key={stage.id}
                  to="/stage/$stageId"
                  params={{ stageId: stage.id }}
                  className={`hud-panel block p-4.5 transition-all duration-200 active:scale-[0.98] group ${
                    isStageDone ? "border-emerald-500/40 bg-emerald-950/15" : "hover:border-primary/50"
                  }`}
                >
                  <div className="flex items-center justify-between gap-4">
                    <div className="space-y-1 min-w-0">
                      <p className={`text-[9px] font-black tracking-widest uppercase ${
                        isStageDone ? "text-emerald-400" : "text-primary"
                      }`}>
                        Tappa {stage.order_index}
                      </p>
                      <p className="text-base sm:text-lg font-black text-foreground truncate group-hover:text-primary transition-colors">
                        {stage.title}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className={`text-[10px] font-black px-2.5 py-1 rounded-lg border ${
                        isStageDone ? "bg-emerald-500/20 text-emerald-300 border-emerald-500/30" : "bg-secondary text-muted-foreground border-border/50"
                      }`}>
                        {done}/{sc.length} prove
                      </span>
                      <ChevronRight className="size-4 text-muted-foreground group-hover:text-primary transition-transform group-hover:translate-x-0.5" />
                    </div>
                  </div>
                  <ProgressBar 
                    value={sc.length ? (done / sc.length) * 100 : 0} 
                    className={`mt-3 h-2 ${isStageDone ? "bg-emerald-500/20" : ""}`}
                  />
                </Link>
              );
            })}
          </div>
        </section>

        {/* USE PASSAPAROLA MODAL */}
        {usePassaparolaTx && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-zinc-950/80 backdrop-blur-md animate-in fade-in duration-200">
            <div className="surface max-w-md w-full rounded-2xl p-6 shadow-2xl border border-zinc-800 bg-[#070d1e] space-y-5 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-orange-500/5 rounded-full blur-3xl pointer-events-none" />
              
              <div className="flex items-center gap-3">
                <div className="size-10 rounded-full bg-orange-500/10 flex items-center justify-center border border-orange-500/25 text-orange-500 shrink-0">
                  <PhoneCall className="size-5" />
                </div>
                <div className="space-y-0.5">
                  <h3 className="text-md font-black text-foreground uppercase tracking-wide leading-none">
                    Usa Passaparola
                  </h3>
                  <p className="text-[11px] text-muted-foreground">
                    Scrivi brevemente su cosa ti serve l'aiuto SÌ/NO della Regia.
                  </p>
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] text-zinc-500 font-extrabold uppercase tracking-wider">
                  Descrivi l'enigma, la prova o il dubbio...
                </label>
                <textarea
                  placeholder="Esempio: Nel rebus al checkpoint dobbiamo considerare anche il titolo?"
                  value={passaparolaText}
                  onChange={(e) => setPassaparolaText(e.target.value)}
                  disabled={isSendingPassaparola}
                  rows={4}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-xl p-3 text-xs text-foreground placeholder-zinc-600 focus:outline-none focus:border-zinc-700 transition-colors resize-none"
                />
              </div>

              <div className="bg-zinc-950/40 p-3 rounded-xl border border-zinc-800 text-[10px] text-zinc-500 leading-normal">
                ⚠️ <strong>Nessuna risposta automatica:</strong> La richiesta verrà notificata alla Regia fisica che vi risponderà manualmente con un <strong>SÌ</strong> o con un <strong>NO</strong>.
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setUsePassaparolaTx(null);
                    setPassaparolaText("");
                  }}
                  disabled={isSendingPassaparola}
                  className="flex-1 py-2.5 rounded-xl border border-zinc-800 hover:bg-zinc-900 text-xs font-black uppercase text-muted-foreground transition-all cursor-pointer"
                >
                  Annulla
                </button>
                <button
                  onClick={handleSendPassaparola}
                  disabled={isSendingPassaparola || !passaparolaText.trim()}
                  className="flex-1 py-2.5 rounded-xl bg-orange-500 text-black font-black text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer flex items-center justify-center gap-1.5"
                >
                  {isSendingPassaparola ? <Loader2 className="size-3.5 animate-spin" /> : <span>Invia alla Regia</span>}
                </button>
              </div>
            </div>
          </div>
        )}

      </div>
    </AppShell>
  );
}

function Stat({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="rounded-xl bg-background/35 border border-border/30 p-3 sm:p-3.5 shadow-sm hover:border-primary/20 hover:bg-background/50 transition-all duration-300 flex flex-col justify-between">
      <div className="flex items-center gap-1 text-[9px] sm:text-[10px] font-extrabold tracking-wider text-muted-foreground uppercase">
        {icon}
        <span className="truncate">{label}</span>
      </div>
      <div className="font-display text-2xl sm:text-3xl font-bold mt-1 text-foreground tracking-wide leading-none">
        {value}
      </div>
    </div>
  );
}
