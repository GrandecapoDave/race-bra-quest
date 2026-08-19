import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import {
  Coins,
  ShoppingBag,
  Sparkles,
  Shield,
  HelpCircle,
  HelpCircle as WheelIcon,
  MessageSquare,
  Eye,
  Zap,
  Clock,
  Puzzle,
  Skull,
  ShieldAlert,
  ArrowDownCircle,
  PiggyBank,
  Check,
  Loader2,
  RefreshCw,
  AlertTriangle,
  History,
  Lock,
  ChevronRight,
  User,
  Users,
  Trophy,
  PhoneCall,
  Snowflake,
} from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { myTeamQuery, stagesQuery, challengesQuery, progressQuery, isStageUnlocked, leaderboardQuery, rankLeaderboard, formatDuration } from "@/lib/race";

export const Route = createFileRoute("/_authenticated/marketplace")({
  head: () => ({
    meta: [
      { title: "Marketplace — Pechino Express Bra" },
      {
        name: "description",
        content: "Acquista bonus e malus strategici con i tuoi token di gara.",
      },
    ],
  }),
  component: MarketplacePage,
});

// Full items catalog mapping to metadata
const MARKETPLACE_ITEMS = [
  // BONUS
  {
    id: "bonus_punti",
    nome: "BONUS PUNTI",
    categoria: "BONUS",
    costo: 40,
    effetto: "+20 PT",
    descrizione: "Aggiunge immediatamente +20 PT al punteggio della vostra squadra.",
    icon: Sparkles,
    color: "from-amber-400 to-yellow-500",
  },
  {
    id: "bonus_scudo",
    nome: "BONUS SCUDO",
    categoria: "BONUS",
    costo: 35,
    effetto: "Protegge la squadra da un singolo Malus avversario.",
    descrizione: "Uno scudo invisibile protegge il vostro viaggio dagli attacchi degli avversari.",
    icon: Shield,
    color: "from-blue-500 to-cyan-500",
  },
  {
    id: "ruota_fortuna",
    nome: "RUOTA DELLA FORTUNA",
    categoria: "BONUS",
    costo: 25,
    effetto: "Gira la ruota per vincere premi immediati in punti o token.",
    descrizione: "La fortuna decide il vostro destino. Siete pronti a rischiare?",
    icon: WheelIcon,
    color: "from-purple-500 to-pink-500",
  },
  {
    id: "passaparola",
    nome: "PASSAPAROLA",
    categoria: "BONUS",
    costo: 20,
    effetto: "Un aiuto SÌ/NO dalla Regia su un enigma, una prova o un checkpoint.",
    descrizione: "Quando siete bloccati, chiedete aiuto al regista della gara.",
    icon: PhoneCall,
    color: "from-orange-500 to-amber-500",
  },
  {
    id: "bonus_classifica",
    nome: "BONUS CLASSIFICA",
    categoria: "BONUS",
    costo: 30,
    effetto: "Permette di visualizzare temporaneamente la classifica generale della gara.",
    descrizione: "Visualizza temporaneamente la classifica generale.",
    icon: Eye,
    color: "from-indigo-500 to-purple-600",
  },
  {
    id: "partenza_anticipata",
    nome: "PARTENZA ANTICIPATA",
    categoria: "BONUS",
    costo: 35,
    effetto: "−2 minuti sul tempo di partenza della squadra.",
    descrizione: "Comunica alla Regia di voler utilizzare questo bonus prima della partenza.",
    icon: Zap,
    color: "from-yellow-400 to-orange-500",
  },
  // MALUS
  {
    id: "freeze_2min",
    nome: "FREEZE 2 MINUTI",
    categoria: "MALUS",
    costo: 20,
    effetto: "Blocca la squadra avversaria per 2 minuti.",
    descrizione: "Il tempo si ferma per i vostri rivali.",
    icon: Snowflake,
    color: "from-sky-400 to-blue-600",
  },
  {
    id: "enigma_extra",
    nome: "ENIGMA EXTRA",
    categoria: "MALUS",
    costo: 25,
    effetto: "La squadra bersaglio deve completare un enigma aggiuntivo.",
    descrizione: "Un nuovo ostacolo compare sulla strada degli avversari.",
    icon: Puzzle,
    color: "from-rose-500 to-red-600",
  },
  {
    id: "ruota_sfortunata",
    nome: "RUOTA SFORTUNATA",
    categoria: "MALUS",
    costo: 20,
    effetto: "La squadra bersaglio gira una ruota con possibili penalità casuali.",
    descrizione: "La fortuna degli altri potrebbe trasformarsi nella loro sfortuna.",
    icon: ShieldAlert,
    color: "from-amber-600 to-red-500",
  },
  {
    id: "trappola",
    nome: "TRAPPOLA",
    categoria: "MALUS",
    costo: 40,
    effetto: "Ruba fino a 30 Punti Squadra al bersaglio",
    descrizione: "I punti sottratti verranno trasferiti direttamente alla tua squadra.",
    icon: Skull,
    color: "from-red-600 to-purple-800",
  },
  {
    id: "penalita_punti",
    nome: "PENALITÀ PUNTI (-20 PT)",
    categoria: "MALUS",
    costo: 30,
    effetto: "−20 PT",
    descrizione: "Un colpo diretto alla classifica degli avversari.",
    icon: ArrowDownCircle,
    color: "from-rose-600 to-red-800",
  },
  {
    id: "tassa_passaggio",
    nome: "TASSA DI PASSAGGIO",
    categoria: "MALUS",
    costo: 70,
    effetto: "Scambia integralmente i Punti Squadra correnti con quelli di una squadra avversaria.",
    descrizione: "Prendi la posizione in classifica di un tuo rivale scambiando i vostri punteggi.",
    icon: RefreshCw,
    color: "from-blue-600 to-indigo-800",
  },
];

const WHEEL_SLICES = [
  { id: "jackpot", label: "🏆 JACKPOT (+20 PT)", color: "#eab308", text: "#000000" },
  { id: "dave_help", label: "🧠 AIUTO DAVE 📞", color: "#a855f7", text: "#ffffff" },
  { id: "mega_bonus", label: "💎 MEGA (+15 PT)", color: "#3b82f6", text: "#ffffff" },
  { id: "bonus", label: "⭐ BONUS (+10 PT)", color: "#10b981", text: "#ffffff" },
  { id: "piccolo_bonus", label: "🎁 PICCOLO (+5 PT)", color: "#f97316", text: "#ffffff" },
  { id: "gettoni_bonus", label: "🪙 GETTONI (+10 TK)", color: "#06b6d4", text: "#000000" },
  { id: "doppio_premio", label: "🎯 DOPPIO (+5/5)", color: "#ec4899", text: "#ffffff" },
  { id: "fortuna", label: "🍀 FORTUNA (+5 TK)", color: "#84cc16", text: "#ffffff" },
  { id: "sorpresa", label: "🎉 SORPRESA (+3 PT)", color: "#ef4444", text: "#ffffff" },
];

const polarToCartesian = (centerX: number, centerY: number, radius: number, angleInDegrees: number) => {
  const angleInRadians = ((angleInDegrees - 90) * Math.PI) / 180.0;
  return {
    x: centerX + radius * Math.cos(angleInRadians),
    y: centerY + radius * Math.sin(angleInRadians),
  };
};

const describeArc = (x: number, y: number, radius: number, startAngle: number, endAngle: number) => {
  const start = polarToCartesian(x, y, radius, endAngle);
  const end = polarToCartesian(x, y, radius, startAngle);
  const largeArcFlag = endAngle - startAngle <= 180 ? "0" : "1";
  return [
    "M", x, y,
    "L", start.x, start.y,
    "A", radius, radius, 0, largeArcFlag, 0, end.x, end.y,
    "Z"
  ].join(" ");
};

function MarketplacePage() {
  const navigate = useNavigate();
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const queryClient = useQueryClient();

  const teamQuery = useQuery(myTeamQuery);
  const stages = useQuery(stagesQuery);
  const challenges = useQuery(challengesQuery);
  const progress = useQuery(progressQuery(teamQuery.data?.id));

  // State for Malus target selection modal
  const [selectedMalus, setSelectedMalus] = useState<typeof MARKETPLACE_ITEMS[0] | null>(null);
  const [targetTeamId, setTargetTeamId] = useState<string>("");
  const [buyingId, setBuyingId] = useState<string | null>(null);

  const [isLeaderboardOpen, setIsLeaderboardOpen] = useState(false);
  const [consumingId, setConsumingId] = useState<string | null>(null);

  // Wheel of Fortune states
  const [wheelOutcome, setWheelOutcome] = useState<any | null>(null);
  const [isWheelOpen, setIsWheelOpen] = useState(false);
  const [wheelRotation, setWheelRotation] = useState(0);
  const [isSpinning, setIsSpinning] = useState(false);
  const [showPrize, setShowPrize] = useState(false);

  // Confirmation state for high-stakes items
  const [confirmBonusItem, setConfirmBonusItem] = useState<any | null>(null);

  // Trappola Animation States
  const [trapSuccessData, setTrapSuccessData] = useState<any | null>(null);
  const [isTrapAnimationActive, setIsTrapAnimationActive] = useState(false);
  const [trapAnimStep, setTrapAnimStep] = useState(0);

  // Penalita Punti Success States
  const [penaltySuccessData, setPenaltySuccessData] = useState<any | null>(null);
  const [isPenaltySuccessActive, setIsPenaltySuccessActive] = useState(false);

  // Tassa di Passaggio Success States
  const [switchSuccessData, setSwitchSuccessData] = useState<any | null>(null);
  const [isSwitchSuccessActive, setIsSwitchSuccessActive] = useState(false);
  const [switchAnimStep, setSwitchAnimStep] = useState(0);

  // Passaparola use state
  const [usePassaparolaTx, setUsePassaparolaTx] = useState<any | null>(null);
  const [passaparolaText, setPassaparolaText] = useState("");
  const [isSendingPassaparola, setIsSendingPassaparola] = useState(false);

  // Hook for leaderboard query, enabled unconditionally
  const boardQuery = useQuery({
    ...leaderboardQuery,
    refetchInterval: 3000,
  });

  const handleViewLeaderboard = (transactionId: string) => {
    navigate({ to: "/classifica" });
  };

  const handleSpinWheel = () => {
    if (isSpinning || !wheelOutcome) return;

    let sliceIndex = WHEEL_SLICES.findIndex((s) => s.id === wheelOutcome.id || s.id === wheelOutcome.outcome_id);
    if (sliceIndex === -1 && wheelOutcome.outcome_label) {
      const labelLower = String(wheelOutcome.outcome_label).toLowerCase();
      sliceIndex = WHEEL_SLICES.findIndex((s) => labelLower.includes(s.id) || labelLower.includes(s.label.toLowerCase().slice(2, 7)));
    }
    if (sliceIndex === -1) {
      sliceIndex = 0;
    }

    setIsSpinning(true);
    setShowPrize(false);
    
    // 360 * 5 is 5 full rotations. (360 - (sliceIndex * 40 + 20)) degrees aligns the selected slice under the pointer
    const rotationAngle = 360 * 5 + (360 - (sliceIndex * 40 + 20));
    setWheelRotation(rotationAngle);

    setTimeout(() => {
      setIsSpinning(false);
      setShowPrize(true);
      queryClient.invalidateQueries();
    }, 5000);
  };

  // Fetch all active teams in the game
  const teamsQuery = useQuery({
    queryKey: ["all-teams-list"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("teams")
        .select("*")
        .eq("active", true);
      if (error) {
        console.warn("Error teamsQuery:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch marketplace items from database
  const marketplaceItemsQuery = useQuery({
    queryKey: ["marketplace-items-list"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_items")
        .select("*");
      if (error) {
        console.warn("Error marketplaceItemsQuery:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch all transactions
  const transactionsQuery = useQuery({
    queryKey: ["marketplace-transactions-list"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id,timestamp:data_acquisto,outcome:dettagli")
        .order("data_acquisto", { ascending: false });
      if (error) {
        console.warn("Error transactionsQuery:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch game settings
  const gameSettingsQuery = useQuery({
    queryKey: ["game-settings"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("game_settings")
        .select("*")
        .single();
      if (error) {
        console.warn("Error gameSettingsQuery:", error);
        return { marketplace_visible: false, marketplace_active: false, activated_at: null, activated_by: null };
      }
      return data || { marketplace_visible: false, marketplace_active: false, activated_at: null, activated_by: null };
    }
  });

  const settings = gameSettingsQuery.data as any;
  const isMarketplaceVisible = settings?.marketplace_visible === true;
  const isMarketplaceActive = settings?.marketplace_active === true;

  const hasCompletedTappa1 = progress.data?.some(
    (p: any) => p.challenge_id === "0147e750-f0a3-4b72-8e76-a003fe2ef143" && (p.stato === "completed" || p.status === "completed")
  ) === true;

  const isAccessible = isAdmin.data || (isMarketplaceActive && hasCompletedTappa1);

  // Render access denied for players who haven't discovered the Marketplace yet or if it is closed
  if (!isAccessible && !teamQuery.isLoading && !gameSettingsQuery.isLoading) {
    return (
      <AppShell isAdmin={false}>
        <div className="surface p-8 max-w-lg mx-auto text-center space-y-6 border border-dashed border-red-500/30 rounded-3xl mt-12 bg-red-950/5">
          <div className="size-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto border border-red-500/20 text-red-500">
            <Lock className="size-8" />
          </div>
          <div className="space-y-2">
            <h1 className="text-3xl font-display font-black uppercase text-red-500">Area Riservata</h1>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {!hasCompletedTappa1
                ? "Il Marketplace si sbloccherà automaticamente dopo il completamento della Tappa 1 (Foto ufficiale)."
                : "Il Marketplace è temporaneamente chiuso dalla Regia."}
            </p>
          </div>
        </div>
      </AppShell>
    );
  }

  const team = teamQuery.data;
  const myScore = boardQuery.data?.find((r) => r.team_id === team?.id);
  const currentPoints = myScore?.total_points ?? 0;
  const transactions = transactionsQuery.data ?? [];
  const teams = teamsQuery.data ?? [];

  const dbItems = marketplaceItemsQuery.data ?? [];
  const mergedItems = dbItems.map((dbItem: any) => {
    const staticItem = (MARKETPLACE_ITEMS.find((i) => i.id === dbItem.id) || {}) as any;
    return {
      ...staticItem,
      ...dbItem,
      costo: dbItem.costo_token ?? staticItem.costo,
      nome: dbItem.nome ?? staticItem.nome,
      categoria: dbItem.categoria ?? staticItem.categoria,
      descrizione: dbItem.descrizione ?? staticItem.descrizione,
      active: dbItem.active ?? true,
    };
  });

  const bonusItems = mergedItems
    .filter((i: any) => i.categoria === "BONUS" && i.active !== false)
    .sort((a: any, b: any) => {
      if (b.costo !== a.costo) {
        return b.costo - a.costo;
      }
      return a.nome.localeCompare(b.nome);
    });

  const malusItems = mergedItems
    .filter((i: any) => i.categoria === "MALUS" && i.active !== false)
    .sort((a: any, b: any) => {
      if (b.costo !== a.costo) {
        return b.costo - a.costo;
      }
      return a.nome.localeCompare(b.nome);
    });

  // Filter transactions
  const myPurchases = team ? transactions.filter((t) => t.buyer_team_id === team.id) : [];
  const myBonuses = myPurchases.filter((t) => {
    const item = MARKETPLACE_ITEMS.find((i) => i.id === t.item_id);
    return item?.categoria === "BONUS";
  });
  const mySentMaluses = myPurchases.filter((t) => {
    const item = MARKETPLACE_ITEMS.find((i) => i.id === t.item_id);
    return item?.categoria === "MALUS";
  });
  const myReceivedMaluses = team ? transactions.filter((t) => t.target_team_id === team.id) : [];

  const balance = team?.token_balance ?? 50;

  // Handle Purchase RPC
  const handlePurchase = async (itemId: string, targetId?: string) => {
    if (!isMarketplaceActive) {
      toast.error("Il Marketplace è chiuso. Non puoi effettuare acquisti.");
      return;
    }
    setBuyingId(itemId);
    try {
      const { data, error } = await (supabase as any).rpc("buy_marketplace_item", {
        p_item_id: itemId,
        p_target_team_id: targetId || null,
      });

      if (error) {
        toast.error(error.message || "Errore durante l'acquisto.");
        return;
      }

      if (itemId === "ruota_fortuna") {
        if (data && data.outcome) {
          setWheelOutcome(data.outcome);
          setWheelRotation(0);
          isSpinning && setIsSpinning(false);
          showPrize && setShowPrize(false);
          setIsWheelOpen(true);
        } else {
          toast.error("Errore durante l'estrazione del premio.");
        }
      } else {
        if (data && data.blockedByShield === true) {
          toast.error("🛡️ MALUS BLOCCATO!", {
            description: "La squadra bersaglio era protetta da uno Scudo. Il tuo Malus non ha avuto effetto.",
            duration: 6000,
          });
        } else if (itemId === "trappola") {
          if (data && data.outcome) {
            const targetName = (teamsQuery.data ?? []).find((t: any) => t.id === targetTeamId)?.nome_squadra || "Bersaglio";
            setTrapSuccessData({
              targetName,
              pointsStolen: data.outcome.points_stolen,
              targetPointsBefore: data.outcome.target_points_before,
              targetPointsAfter: data.outcome.target_points_after,
              buyerPointsBefore: data.outcome.buyer_points_before,
              buyerPointsAfter: data.outcome.buyer_points_after,
            });

            setIsTrapAnimationActive(true);
            setTrapAnimStep(0);

            setTimeout(() => {
              setTrapAnimStep(1);
            }, 1500);

            setTimeout(() => {
              setTrapAnimStep(2);
            }, 3000);

            setTimeout(() => {
              setTrapAnimStep(3);
            }, 4500);
          } else {
            toast.error("Errore durante il furto dei punti.");
          }
        } else if (itemId === "penalita_punti") {
          if (data && data.outcome) {
            const targetName = (teamsQuery.data ?? []).find((t: any) => t.id === targetTeamId)?.nome_squadra || "Bersaglio";
            setPenaltySuccessData({
              targetName,
              pointsDeducted: data.outcome.points_deducted,
              targetPointsBefore: data.outcome.target_points_before,
              targetPointsAfter: data.outcome.target_points_after,
            });
            setIsPenaltySuccessActive(true);
          } else {
            toast.error("Errore durante l'applicazione della penalità.");
          }
        } else if (itemId === "tassa_passaggio") {
          if (data && data.outcome) {
            const targetName = (teamsQuery.data ?? []).find((t: any) => t.id === targetTeamId)?.nome_squadra || "Bersaglio";
            setSwitchSuccessData({
              targetName,
              buyerPointsBefore: data.outcome.buyer_points_before,
              buyerPointsAfter: data.outcome.buyer_points_after,
              targetPointsBefore: data.outcome.target_points_before,
              targetPointsAfter: data.outcome.target_points_after,
            });

            setIsSwitchSuccessActive(true);
            setSwitchAnimStep(0);

            setTimeout(() => {
              setSwitchAnimStep(1);
            }, 1500);

            setTimeout(() => {
              setSwitchAnimStep(2);
            }, 3000);
          } else {
            toast.error("Errore durante lo switch dei punti.");
          }
        } else if (itemId === "bonus_punti") {
          const cost = mergedItems.find((i) => i.id === "bonus_punti")?.costo ?? 40;
          toast.success("✨ +20 PT ✨ BONUS PUNTI ATTIVATO!", {
            description: `Il tuo punteggio è stato aggiornato: ${(currentPoints + 20)} PT. Saldo residuo: ${(balance - cost)} Token.`,
            duration: 6000,
          });
        } else if (itemId === "passaparola") {
          toast.success("📞 PASSAPAROLA ACQUISTATO!", {
            description: "Inserisci ora la domanda per la Regia per ricevere una risposta SÌ o NO.",
            duration: 5000,
          });
          if (data?.transaction_id) {
            setUsePassaparolaTx({ id: data.transaction_id });
          }
        } else {
          toast.success("Acquisto completato con successo!");
        }
        setSelectedMalus(null);
        setTargetTeamId("");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message || "Questo oggetto è già stato utilizzato oppure non possiedi abbastanza token.");
    } finally {
      setBuyingId(null);
    }
  };
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


  const openMalusModal = (item: typeof MARKETPLACE_ITEMS[0]) => {
    setSelectedMalus(item);
  };

  return (
    <AppShell isAdmin={isAdmin.data}>
      <div className="space-y-8 pb-10">
        {/* HEADER SECTION */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="flex items-center gap-2.5 text-4xl sm:text-5xl leading-none">
              <ShoppingBag className="size-8 text-primary animate-bounce" /> Marketplace
            </h1>
            <p className="mt-1.5 text-xs sm:text-sm text-muted-foreground">
              PECHINO EXPRESS BRA — Budget iniziale: 50 Token 🪙. Massimo un acquisto per singolo prodotto durante la gara.
            </p>
          </div>

          {/* TOKEN BALANCE */}
          <div className="relative overflow-hidden flex items-center gap-3.5 bg-zinc-950/40 p-4 px-6 rounded-2xl border border-orange-500/20 shadow-lg shadow-orange-500/5 min-w-[200px]">
            <div className="absolute top-0 right-0 w-24 h-24 bg-orange-500/5 rounded-full blur-2xl pointer-events-none" />
            <div className="size-10 rounded-xl bg-orange-500/10 flex items-center justify-center shrink-0 border border-orange-500/20">
              <Coins className="size-5 text-orange-500" />
            </div>
            <div>
              <span className="text-[10px] uppercase font-extrabold tracking-widest text-muted-foreground block">
                Token Disponibili
              </span>
              <span className="text-2xl font-black text-foreground flex items-center gap-1.5">
                {balance} <span className="text-xs text-orange-500 font-bold">🪙</span>
              </span>
            </div>
          </div>
        </div>

        {/* HERO STATUS BANNER */}
        {!isMarketplaceActive ? (
          <div className="surface p-6 border border-warning/30 bg-warning/5 rounded-2xl flex flex-col md:flex-row items-center gap-4 animate-pulse">
            <div className="size-12 rounded-full bg-warning/10 flex items-center justify-center text-warning shrink-0 border border-warning/20">
              <Lock className="size-6 animate-pulse" />
            </div>
            <div className="text-center md:text-left space-y-1">
              <h3 className="font-extrabold text-sm text-warning uppercase tracking-wide">🔒 Marketplace chiuso</h3>
              <p className="text-xs text-zinc-300">
                Il Marketplace è stato scoperto, ma il Regista non ha ancora aperto gli scambi. Rimanete pronti: l'apertura potrebbe avvenire in qualsiasi momento.
              </p>
            </div>
          </div>
        ) : (
          <div className="surface p-6 border border-emerald-500/30 bg-emerald-500/5 rounded-2xl flex flex-col md:flex-row items-center gap-4 animate-in fade-in slide-in-from-top duration-300">
            <div className="size-12 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-400 shrink-0 border border-emerald-500/20">
              <ShoppingBag className="size-6 text-emerald-400 animate-bounce" />
            </div>
            <div className="text-center md:text-left space-y-1">
              <h3 className="font-extrabold text-sm text-emerald-400 uppercase tracking-wide">🟢 Marketplace Aperto</h3>
              <p className="text-xs text-zinc-300">
                Il Marketplace è ufficialmente aperto! Potete utilizzare i vostri Token.
              </p>
            </div>
          </div>
        )}

        {/* SHOP GRID */}
        <div className="space-y-6">
          {/* BONUS SECTION */}
          <div className="space-y-3">
            <h2 className="text-lg font-black uppercase tracking-wider text-emerald-500 flex items-center gap-2 border-b border-emerald-500/10 pb-2">
              <span className="inline-block w-2.5 h-2.5 rounded-full bg-emerald-500" /> 🟢 BONUS
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {bonusItems.map((item) => {
                const alreadyPurchased = myPurchases.some((t) => t.item_id === item.id);
                const canAfford = balance >= item.costo;
                const isBuying = buyingId === item.id;

                return (
                  <div
                    key={item.id}
                    className={`surface p-5 flex flex-col justify-between border rounded-2xl transition-all relative overflow-hidden ${
                      alreadyPurchased
                        ? "border-zinc-800/40 bg-zinc-950/10 opacity-60"
                        : "border-zinc-800/80 bg-zinc-950/20 hover:border-zinc-700/80"
                    }`}
                  >
                    <div className="space-y-3">
                      <div className="flex justify-between items-start gap-2">
                        <div className="flex items-center gap-3">
                          <div className={`size-10 rounded-xl bg-gradient-to-br ${item.color} flex items-center justify-center shrink-0 text-white shadow-md`}>
                            <item.icon className="size-5" />
                          </div>
                          <div>
                            <h3 className="font-extrabold text-sm text-foreground leading-tight">{item.nome}</h3>
                            <span className="text-[10px] text-emerald-400 font-bold font-mono">{item.effetto}</span>
                          </div>
                        </div>
                        <span className="text-xs font-black bg-zinc-900 px-2.5 py-1.5 rounded-xl border border-zinc-800 text-orange-400 shrink-0 flex items-center gap-1">
                          {item.costo} 🪙
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground leading-relaxed">{item.descrizione}</p>
                    </div>

                    <div className="mt-4 pt-3 border-t border-border/10">
                      {alreadyPurchased ? (
                        item.id === "ruota_fortuna" ? (
                          (() => {
                            const tx = myPurchases.find((t) => t.item_id === "ruota_fortuna");
                            const outcomeLabel = tx?.outcome?.label || "Ruota utilizzata";
                            return (
                              <div className="flex flex-col gap-1 text-center bg-purple-500/5 p-2.5 rounded-xl border border-purple-500/10 justify-center">
                                <span className="text-[10px] text-purple-400 font-bold uppercase tracking-wider">🎡 Ruota Utilizzata</span>
                                <span className="text-xs text-white font-extrabold">{outcomeLabel}</span>
                              </div>
                            );
                          })()
                        ) : item.id === "bonus_scudo" ? (
                          (() => {
                            const tx = myPurchases.find((t) => t.item_id === "bonus_scudo");
                            const isUsed = tx?.stato === "used";
                            return isUsed ? (
                              <div className="flex items-center gap-1.5 text-xs text-zinc-500 font-extrabold bg-zinc-900/40 p-2.5 rounded-xl border border-zinc-800 justify-center">
                                <span>🛡️ SCUDO CONSUMATO</span>
                              </div>
                            ) : (
                              <div className="flex items-center gap-1.5 text-xs text-blue-400 font-extrabold bg-blue-500/10 p-2.5 rounded-xl border border-blue-500/20 justify-center">
                                <span>🛡️ SCUDO ATTIVO</span>
                              </div>
                            );
                          })()
                        ) : item.id === "passaparola" ? (
                          (() => {
                            const tx = myPurchases.find((t) => t.item_id === "passaparola");
                            if (!tx) return null;
                            const requestText = tx.request_text || tx.outcome?.request_text || tx.dettagli?.request_text || "";
                            const responseText = tx.response_text || tx.outcome?.response_text || tx.dettagli?.response_text || "";
                            if (tx.stato === "completed") {
                              return (
                                <button
                                  onClick={() => setUsePassaparolaTx(tx)}
                                  className="w-full py-2.5 rounded-xl bg-orange-500 text-black font-black text-xs uppercase tracking-wider flex items-center justify-center gap-1.5 transition-all shadow-md hover:brightness-110 active:scale-[0.98] cursor-pointer"
                                >
                                  <PhoneCall className="size-3.5" />
                                  <span>Fai Domanda alla Regia</span>
                                </button>
                              );
                            }
                            if (tx.stato === "pending") {
                              return (
                                <div className="flex flex-col gap-1.5 text-center bg-orange-500/5 p-3 rounded-xl border border-orange-500/10 justify-center">
                                  <span className="text-[10px] text-orange-400 font-extrabold uppercase tracking-wider animate-pulse flex items-center justify-center gap-1">
                                    <Clock className="size-3" />
                                    IN ATTESA DI RISPOSTA
                                  </span>
                                  {requestText && (
                                    <p className="text-[11px] text-zinc-400 italic">
                                      "{requestText}"
                                    </p>
                                  )}
                                </div>
                              );
                            }
                            // stato === 'used'
                            return (
                              <div className="flex flex-col gap-2 bg-emerald-500/5 p-3 rounded-xl border border-emerald-500/10 text-left">
                                <div className="flex items-center justify-between">
                                  <span className="text-[10px] text-emerald-400 font-extrabold uppercase tracking-wider">
                                    📞 RISPOSTA REGIA
                                  </span>
                                  <span className="text-[10px] text-zinc-500 font-bold">
                                    Concluso
                                  </span>
                                </div>
                                {requestText && (
                                  <div className="text-[11px] text-zinc-400 italic border-l-2 border-zinc-700 pl-2">
                                    "{requestText}"
                                  </div>
                                )}
                                <div className="flex items-center gap-1.5 pt-1.5 border-t border-white/5">
                                  <span className="text-[11px] text-zinc-500">Risposta:</span>
                                  <span className={`text-[11px] font-black px-2 py-0.5 rounded ${
                                    responseText === "SÌ" ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" : "bg-rose-500/10 text-rose-400 border border-rose-500/20"
                                  }`}>
                                    {responseText === "SÌ" ? "✅ SÌ" : "❌ NO"}
                                  </span>
                                </div>
                              </div>
                            );
                          })()
                        ) : item.id === "partenza_anticipata" ? (
                          (() => {
                            const tx = myPurchases.find((t) => t.item_id === "partenza_anticipata");
                            const isUsed = tx?.stato === "used";
                            return isUsed ? (
                              <div className="flex flex-col gap-1.5 text-center bg-zinc-900/40 p-3 rounded-xl border border-zinc-800 justify-center">
                                <span className="text-[10px] text-emerald-400 font-extrabold uppercase tracking-wider flex items-center justify-center gap-1">
                                  🟢 UTILIZZATO
                                </span>
                                <span className="text-[10px] text-zinc-500">Vantaggio già usufruito</span>
                              </div>
                            ) : (
                              <div className="flex flex-col gap-2 bg-yellow-500/5 p-3 rounded-xl border border-yellow-500/10">
                                <span className="text-[10px] text-yellow-400 font-extrabold uppercase tracking-wider flex items-center justify-center gap-1">
                                  🟡 DISPONIBILE
                                </span>
                                <p className="text-[10px] text-zinc-400 text-center leading-relaxed">
                                  📢 <strong>Comunica alla Regia</strong> che vuoi utilizzare questo Bonus prima della partenza.
                                </p>
                              </div>
                            );
                          })()
                        ) : item.id === "bonus_punti" ? (
                          <div className="flex items-center gap-1.5 text-xs text-amber-500/85 font-extrabold bg-amber-500/5 p-2.5 rounded-xl border border-amber-500/10 justify-center">
                            <Check className="size-3.5 text-amber-500 stroke-[3]" />
                            <span>UTILIZZATO</span>
                          </div>
                        ) : item.categoria === "MALUS" ? (
                          (() => {
                            const tx = myPurchases.find((t) => t.item_id === item.id && t.stato !== "blocked");
                            const targetTeam = tx
                              ? (teamsQuery.data ?? []).find((tm: any) => tm.id === tx.target_team_id)
                              : null;
                            const targetName = targetTeam?.nome_squadra || "avversario";
                            return (
                              <div className="flex flex-col gap-1 text-center bg-red-500/5 p-2.5 rounded-xl border border-red-500/10 justify-center">
                                <span className="text-[10px] text-red-400 font-bold uppercase tracking-wider">⚔️ Malus Utilizzato</span>
                                <span className="text-xs text-white font-extrabold">Contro: {targetName}</span>
                              </div>
                            );
                          })()
                        ) : (
                          <div className="flex items-center gap-1 text-xs text-emerald-500/85 font-extrabold bg-emerald-500/5 p-2 rounded-xl border border-emerald-500/10 justify-center">
                            <Check className="size-3.5" />
                            <span>Bonus acquistato e attivo</span>
                          </div>
                        )
                      ) : (
                        <button
                          onClick={() => {
                            if (item.id === "bonus_punti" || item.id === "passaparola") {
                              setConfirmBonusItem(item);
                            } else {
                              handlePurchase(item.id);
                            }
                          }}
                          disabled={!canAfford || isBuying || !isMarketplaceActive}
                          className={`w-full py-2.5 rounded-xl text-xs font-black uppercase tracking-wider flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                            canAfford && isMarketplaceActive
                              ? "primary-gradient text-primary-foreground shadow-md hover:brightness-110 active:scale-[0.98]"
                              : "bg-zinc-900 border border-zinc-800 text-muted-foreground cursor-not-allowed"
                          }`}
                        >
                          {isBuying ? <Loader2 className="size-3.5 animate-spin" /> : <Coins className="size-3.5" />}
                          {!isMarketplaceActive ? "Scambi chiusi" : (canAfford ? `Acquista bonus` : "Token insufficienti")}
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* MALUS SECTION */}
          <div className="space-y-3 pt-4">
            <h2 className="text-lg font-black uppercase tracking-wider text-red-500 flex items-center gap-2 border-b border-red-500/10 pb-2">
              <span className="inline-block w-2.5 h-2.5 rounded-full bg-red-500" /> 🔴 MALUS
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {malusItems.map((item) => {
                const alreadyPurchased = myPurchases.some((t) => t.item_id === item.id);
                const canAfford = balance >= item.costo;
                const isBuying = buyingId === item.id;

                return (
                  <div
                    key={item.id}
                    className={`surface p-5 flex flex-col justify-between border rounded-2xl transition-all relative overflow-hidden ${
                      alreadyPurchased
                        ? "border-zinc-800/40 bg-zinc-950/10 opacity-60"
                        : "border-zinc-800/80 bg-zinc-950/20 hover:border-zinc-700/80"
                    }`}
                  >
                    <div className="space-y-3">
                      <div className="flex justify-between items-start gap-2">
                        <div className="flex items-center gap-3">
                          <div className={`size-10 rounded-xl bg-gradient-to-br ${item.color} flex items-center justify-center shrink-0 text-white shadow-md`}>
                            <item.icon className="size-5" />
                          </div>
                          <div>
                            <h3 className="font-extrabold text-sm text-foreground leading-tight">{item.nome}</h3>
                            <span className="text-[10px] text-red-400 font-bold font-mono">{item.effetto}</span>
                          </div>
                        </div>
                        <span className="text-xs font-black bg-zinc-900 px-2.5 py-1.5 rounded-xl border border-zinc-800 text-orange-400 shrink-0 flex items-center gap-1">
                          {item.costo} 🪙
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground leading-relaxed">{item.descrizione}</p>
                    </div>

                    <div className="mt-4 pt-3 border-t border-border/10">
                      {alreadyPurchased ? (
                        <div className="flex items-center gap-1 text-xs text-red-500/85 font-extrabold bg-red-500/5 p-2 rounded-xl border border-red-500/10 justify-center">
                          <Check className="size-3.5" />
                          <span>Malus già utilizzato in gara</span>
                        </div>
                      ) : (
                        <button
                          onClick={() => openMalusModal(item)}
                          disabled={!canAfford || isBuying || !isMarketplaceActive}
                          className={`w-full py-2.5 rounded-xl text-xs font-black uppercase tracking-wider flex items-center justify-center gap-1.5 transition-all cursor-pointer ${
                            canAfford && isMarketplaceActive
                              ? "bg-gradient-to-r from-red-600 to-rose-700 text-white shadow-md hover:brightness-110 active:scale-[0.98]"
                              : "bg-zinc-900 border border-zinc-800 text-muted-foreground cursor-not-allowed"
                          }`}
                        >
                          <Coins className="size-3.5" />
                          {!isMarketplaceActive ? "Scambi chiusi" : (canAfford ? `Acquista & Colpisci` : "Token insufficienti")}
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* TEAM DASHBOARD METRICS */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4">
          {/* BONUS DISPONIBILI */}
          <div className="surface p-5 space-y-4 border border-zinc-800 bg-zinc-950/20 rounded-2xl">
            <h3 className="text-sm font-black uppercase tracking-wider text-emerald-400 flex items-center gap-2 border-b border-border/20 pb-2">
              <Sparkles className="size-4 text-emerald-400" /> 🎁 Bonus Acquistati
            </h3>
            {myBonuses.length === 0 ? (
              <p className="text-xs text-muted-foreground italic text-center py-4">Nessun bonus attivo.</p>
            ) : (
              <ul className="space-y-2">
                {myBonuses.map((b) => {
                  const details = MARKETPLACE_ITEMS.find((i) => i.id === b.item_id);
                  const isClassifica = b.item_id === "bonus_classifica";
                  const isUsed = b.stato === "used";

                  return (
                    <li key={b.id} className="flex flex-col gap-2 bg-zinc-900/40 p-3 rounded-xl border border-zinc-800 text-xs">
                      <div className="flex justify-between items-center">
                        <span className="font-extrabold text-foreground">{details?.nome || b.item_id}</span>
                        <span className="text-[10px] text-zinc-500 font-semibold">{new Date(b.timestamp).toLocaleDateString("it-IT")}</span>
                      </div>
                      {isClassifica && (
                        <div className="flex justify-end pt-1.5 border-t border-border/5">
                          {isUsed ? (
                            <span className="text-[10px] text-zinc-500 font-bold uppercase tracking-wider italic">
                              Visualizzata 👁️
                            </span>
                          ) : (
                            <button
                              onClick={() => handleViewLeaderboard(b.id)}
                              disabled={consumingId === b.id}
                              className="px-2.5 py-1 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 font-black uppercase tracking-wider text-[9px] transition-all flex items-center gap-1 border border-emerald-500/20 active:scale-[0.97] cursor-pointer"
                            >
                              {consumingId === b.id ? (
                                <Loader2 className="size-3 animate-spin" />
                              ) : (
                                <Eye className="size-3" />
                              )}
                              Vedi classifica live
                            </button>
                          )}
                        </div>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}
          </div>

          {/* MALUS INVIATI */}
          <div className="surface p-5 space-y-4 border border-zinc-800 bg-zinc-950/20 rounded-2xl">
            <h3 className="text-sm font-black uppercase tracking-wider text-rose-400 flex items-center gap-2 border-b border-border/20 pb-2">
              <Zap className="size-4 text-rose-400" /> ⚔️ Malus Inviati
            </h3>
            {mySentMaluses.length === 0 ? (
              <p className="text-xs text-muted-foreground italic text-center py-4">Nessun malus inviato.</p>
            ) : (
              <ul className="space-y-2">
                {mySentMaluses.map((m) => {
                  const details = MARKETPLACE_ITEMS.find((i) => i.id === m.item_id);
                  const target = teams.find((t) => t.id === m.target_team_id);
                  return (
                    <li key={m.id} className="bg-zinc-900/40 p-2.5 rounded-xl border border-zinc-800 text-xs space-y-1">
                      <div className="flex justify-between items-center">
                        <span className="font-extrabold text-foreground">{details?.nome || m.item_id}</span>
                        <span className="text-[10px] text-rose-500 font-bold">-{m.costo} 🪙</span>
                      </div>
                      <div className="flex justify-between items-center text-[10px] text-zinc-500">
                        <span>Colpita: <strong className="text-rose-400/90">{target?.nome_squadra || "Sconosciuta"}</strong></span>
                        <span>{new Date(m.timestamp).toLocaleDateString("it-IT")}</span>
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>

          {/* MALUS RICEVUTI */}
          <div className="surface p-5 space-y-4 border border-zinc-800 bg-zinc-950/20 rounded-2xl">
            <h3 className="text-sm font-black uppercase tracking-wider text-amber-500 flex items-center gap-2 border-b border-border/20 pb-2">
              <AlertTriangle className="size-4 text-amber-500" /> ⚠️ Malus Ricevuti
            </h3>
            {myReceivedMaluses.length === 0 ? (
              <p className="text-xs text-muted-foreground italic text-center py-4">Nessun malus ricevuto. Siete al sicuro!</p>
            ) : (
              <ul className="space-y-2">
                {myReceivedMaluses.map((m) => {
                  const details = MARKETPLACE_ITEMS.find((i) => i.id === m.item_id);
                  const buyer = teams.find((t) => t.id === m.buyer_team_id);
                  return (
                    <li key={m.id} className="bg-zinc-900/40 p-2.5 rounded-xl border border-zinc-800 text-xs space-y-1">
                      <div className="flex justify-between items-center">
                        <span className="font-extrabold text-foreground">{details?.nome || m.item_id}</span>
                        <span className="text-[10px] text-amber-500 font-bold">Ricevuto</span>
                      </div>
                      <div className="flex justify-between items-center text-[10px] text-zinc-500">
                        <span>Mandato da: <strong className="text-amber-400">{buyer?.nome_squadra || "Anonimo"}</strong></span>
                        <span>{new Date(m.timestamp).toLocaleDateString("it-IT")}</span>
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </div>

        {/* TRANSACTIONS HISTORY LOG */}
        <div className="surface p-5 space-y-4 border border-zinc-800 bg-zinc-950/20 rounded-2xl">
          <h2 className="text-base font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-2 border-b border-border/20 pb-2">
            <History className="size-4 text-orange-500" /> Storico Completo Acquisti Gara
          </h2>
          {myPurchases.length === 0 ? (
            <p className="text-xs text-muted-foreground italic text-center py-4">Nessuna transazione effettuata.</p>
          ) : (
            <div className="divide-y divide-border/10">
              {myPurchases.map((t) => {
                const isReward = t.item_id === "reward_stage";
                const details = isReward ? {
                  nome: `🏁 RICOMPENSA TAPPA ${t.outcome?.stage_index ?? ""}`,
                  categoria: "RICOMPENSA"
                } : MARKETPLACE_ITEMS.find((i) => i.id === t.item_id);
                const target = teams.find((tm) => tm.id === t.target_team_id);
                return (
                  <div key={t.id} className="flex justify-between items-center py-3 text-xs">
                    <div className="space-y-0.5">
                      <p className="font-extrabold text-foreground flex items-center gap-1.5">
                        {details?.nome || t.item_id}
                        <span className={`text-[9px] uppercase px-1.5 py-0.5 rounded font-black ${
                          isReward 
                            ? "bg-yellow-500/10 text-yellow-400"
                            : details?.categoria === "BONUS"
                            ? "bg-emerald-500/10 text-emerald-400"
                            : "bg-red-500/10 text-red-400"
                        }`}>
                          {details?.categoria || "N/A"}
                        </span>
                      </p>
                      <p className="text-[10px] text-zinc-500">
                        {new Date(t.timestamp).toLocaleString("it-IT")}
                        {target && (
                          <span> · Bersaglio: <strong className="text-zinc-400">{target.nome_squadra}</strong></span>
                        )}
                        {isReward && t.outcome && (
                          <span> · Posizione: <strong className="text-zinc-400">{t.outcome.position}ª</strong>{t.outcome.capped ? " (Limite 80 raggiunto)" : ""}</span>
                        )}
                      </p>
                    </div>
                    {isReward ? (
                      <span className="font-black text-emerald-400 flex items-center gap-0.5 shrink-0">
                        +{Math.abs(t.costo)} 🪙
                      </span>
                    ) : (
                      <span className="font-black text-red-500 flex items-center gap-0.5 shrink-0">
                        -{t.costo} 🪙
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* TARGET TEAM SELECTION MODAL */}
      {selectedMalus && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-200">
          <div className="surface border border-zinc-800 bg-[#070d1e] max-w-md w-full rounded-2xl p-6 shadow-2xl space-y-6 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-red-500/5 rounded-full blur-3xl pointer-events-none" />

            <div className="space-y-2">
              <h3 className="text-xl font-black text-foreground uppercase tracking-wide flex items-center gap-2">
                <Skull className="size-5 text-red-500" /> Colpisci una Squadra
              </h3>
              <p className="text-xs text-muted-foreground">
                Scegli la squadra avversaria da colpire con il malus: <strong className="text-red-400">{selectedMalus.nome}</strong> (costo {selectedMalus.costo} 🪙).
              </p>
            </div>

            {/* TEAM SELECT LIST */}
            <div className="space-y-2.5 max-h-[220px] overflow-y-auto pr-1">
              {teams
                .filter((t) => t.id !== team?.id) // exclude self
                .map((t) => (
                  <button
                    key={t.id}
                    onClick={() => setTargetTeamId(t.id)}
                    className={`w-full flex items-center justify-between p-3 rounded-xl border transition-all text-left ${
                      targetTeamId === t.id
                        ? "border-red-500 bg-red-500/10 shadow-md shadow-red-500/5 text-foreground"
                        : "border-zinc-800 bg-zinc-900/40 hover:border-zinc-700 hover:bg-zinc-900/60 text-muted-foreground"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="size-7 rounded-lg flex items-center justify-center" style={{ backgroundColor: `${t.color}15`, border: `1px solid ${t.color}` }}>
                        <Users className="size-3.5" style={{ color: t.color }} />
                      </div>
                      <span className="font-extrabold text-sm text-foreground">{t.nome_squadra}</span>
                    </div>
                    {targetTeamId === t.id && (
                      <span className="size-4 rounded-full bg-red-500 flex items-center justify-center shrink-0">
                        <Check className="size-2.5 text-white stroke-[4]" />
                      </span>
                    )}
                  </button>
                ))}

              {teams.filter((t) => t.id !== team?.id).length === 0 && (
                <p className="text-xs text-muted-foreground italic text-center py-4">Nessun'altra squadra attiva presente nel gioco.</p>
              )}
            </div>
            {targetTeamId && (
              selectedMalus.id === "trappola" ? (
                <div className="bg-red-500/5 p-4 rounded-xl border border-red-500/10 text-xs space-y-2 animate-in fade-in slide-in-from-top-2 duration-200">
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Malus da lanciare:</span>
                    <span className="text-red-400 font-extrabold flex items-center gap-1">
                      🪤 TRAPPOLA
                    </span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Costo:</span>
                    <span className="text-orange-400 font-mono font-black">40 Token 🪙</span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>🎯 Squadra bersaglio:</span>
                    <strong className="text-white font-extrabold">
                      {teams.find((t) => t.id === targetTeamId)?.nome_squadra || "Sconosciuta"}
                    </strong>
                  </p>
                  <p className="text-[10px] text-zinc-400 font-semibold leading-relaxed border-t border-zinc-900 pt-1.5 mt-1.5">
                    ℹ️ <strong>Effetto:</strong> Ruba fino a 30 Punti Squadra al bersaglio e li trasferisce direttamente alla tua squadra.
                  </p>
                  <div className="flex justify-between text-[10px] text-zinc-500 font-mono pt-1">
                    <span>Token disponibili: {balance}</span>
                    <span>Dopo acquisto: {balance - 40}</span>
                  </div>
                </div>
              ) : selectedMalus.id === "tassa_passaggio" ? (
                <div className="bg-blue-500/5 p-4 rounded-xl border border-blue-500/10 text-xs space-y-2.5 animate-in fade-in slide-in-from-top-2 duration-200">
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Malus da lanciare:</span>
                    <span className="text-blue-400 font-extrabold flex items-center gap-1">
                      🔄 TASSA DI PASSAGGIO
                    </span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Costo:</span>
                    <span className="text-orange-400 font-mono font-black">70 Token 🪙</span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>🎯 Squadra bersaglio:</span>
                    <strong className="text-white font-extrabold">
                      {teams.find((t) => t.id === targetTeamId)?.nome_squadra || "Sconosciuta"}
                    </strong>
                  </p>

                  <div className="border-t border-zinc-900 pt-2 space-y-1.5 text-[10px] text-zinc-400">
                    <p className="leading-relaxed">
                      I punti della tua squadra verranno scambiati con quelli del bersaglio. Il punteggio del bersaglio non verrà mostrato.
                    </p>
                    <p className="text-orange-400/90 font-semibold">
                      ⚠️ I punteggi delle altre squadre non sono visibili.
                    </p>
                    
                    <div className="bg-zinc-950/60 p-2.5 rounded border border-zinc-900 font-mono text-[9px] space-y-1 mt-1">
                      <div className="flex justify-between">
                        <span>Token disponibili:</span>
                        <span className="text-white">{balance}</span>
                      </div>
                      <div className="flex justify-between text-red-400">
                        <span>Costo:</span>
                        <span>-70</span>
                      </div>
                      <div className="flex justify-between text-emerald-400 border-t border-zinc-900 pt-1 font-bold">
                        <span>Token dopo:</span>
                        <span>{balance - 70}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ) : selectedMalus.id === "penalita_punti" ? (
                <div className="bg-red-500/5 p-4 rounded-xl border border-red-500/10 text-xs space-y-2 animate-in fade-in slide-in-from-top-2 duration-200">
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Malus da lanciare:</span>
                    <span className="text-red-400 font-extrabold flex items-center gap-1">
                      ⚠️ PENALITÀ PUNTI
                    </span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Costo:</span>
                    <span className="text-orange-400 font-mono font-black">30 Token 🪙</span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>🎯 Squadra bersaglio:</span>
                    <strong className="text-white font-extrabold">
                      {teams.find((t) => t.id === targetTeamId)?.nome_squadra || "Sconosciuta"}
                    </strong>
                  </p>
                  <p className="text-[10px] text-zinc-400 font-semibold leading-relaxed border-t border-zinc-900 pt-1.5 mt-1.5">
                    ℹ️ <strong>Effetto:</strong> La squadra bersaglio perderà 20 Punti Squadra. I punti verranno rimossi dalla classifica e <strong>non verranno trasferiti</strong> alla tua squadra.
                  </p>
                </div>
              ) : (
                <div className="bg-red-500/5 p-4 rounded-xl border border-red-500/10 text-xs space-y-1.5 animate-in fade-in slide-in-from-top-2 duration-200">
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Malus da lanciare:</span>
                    <span className="text-red-400 font-extrabold flex items-center gap-1">
                      {selectedMalus.id === "freeze_2min" ? "❄️" : "💀"} {selectedMalus.nome}
                    </span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>Costo:</span>
                    <span className="text-orange-400 font-mono font-black">{selectedMalus.costo} Token 🪙</span>
                  </p>
                  <p className="text-zinc-300 font-semibold flex justify-between">
                    <span>🎯 Squadra bersaglio:</span>
                    <strong className="text-white font-extrabold">
                      {teams.find((t) => t.id === targetTeamId)?.nome_squadra || "Sconosciuta"}
                    </strong>
                  </p>
                </div>
              )
            )}

            {/* ACTION BUTTONS */}
            <div className="flex items-center gap-3 pt-3 border-t border-border/10">
              <button
                onClick={() => {
                  setSelectedMalus(null);
                  setTargetTeamId("");
                }}
                className="flex-1 py-2.5 rounded-xl border border-zinc-800 hover:bg-zinc-900 text-xs font-bold text-muted-foreground transition-all"
              >
                Annulla
              </button>
              <button
                disabled={!targetTeamId || buyingId === selectedMalus.id}
                onClick={() => handlePurchase(selectedMalus.id, targetTeamId)}
                className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-red-600 to-rose-700 disabled:from-zinc-950 disabled:to-zinc-950 disabled:border-zinc-850 text-white font-extrabold text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-1.5 disabled:cursor-not-allowed"
              >
                {buyingId === selectedMalus.id ? (
                  <Loader2 className="size-3.5 animate-spin" />
                ) : (
                  <Coins className="size-3.5" />
                )}
                {selectedMalus.id === "trappola" ? "CONFERMA TRAPPOLA" : selectedMalus.id === "tassa_passaggio" ? "CONFERMA SWITCH" : selectedMalus.id === "penalita_punti" ? "CONFERMA ACQUISTO" : "Conferma Malus"}
              </button>
            </div>
          </div>
        </div>
      )}
      {/* MONOUSO LEADERBOARD MODAL */}
      {isLeaderboardOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-zinc-950/80 backdrop-blur-md animate-in fade-in duration-200">
          <div className="surface w-full max-w-lg p-6 max-h-[85vh] flex flex-col border border-orange-500/20 bg-zinc-950/95 shadow-2xl animate-in scale-in duration-250 rounded-2xl">
            {/* MODAL HEADER */}
            <div className="flex items-center justify-between border-b border-white/10 pb-4 mb-4 shrink-0">
              <h3 className="font-display text-3xl text-gold flex items-center gap-2">
                <Trophy className="size-6 text-gold animate-pulse" /> Classifica Live
              </h3>
              <button
                onClick={() => setIsLeaderboardOpen(false)}
                className="text-xs font-black uppercase tracking-wider text-muted-foreground hover:text-white px-3 py-1.5 rounded-lg hover:bg-zinc-900 border border-zinc-800 transition-all cursor-pointer"
              >
                Chiudi ✕
              </button>
            </div>

            {/* MODAL BODY (SCROLLABLE LEADERBOARD ROWS) */}
            <div className="overflow-y-auto flex-1 space-y-2.5 pr-1">
              {boardQuery.isLoading ? (
                <div className="text-center py-12 space-y-3">
                  <Loader2 className="size-8 animate-spin text-primary mx-auto" />
                  <p className="text-xs text-muted-foreground uppercase font-black tracking-widest">Caricamento classifica...</p>
                </div>
              ) : boardQuery.error ? (
                <p className="text-xs text-red-500 text-center py-6">Errore nel caricamento della classifica.</p>
              ) : (
                rankLeaderboard(boardQuery.data ?? []).map((r, i) => {
                  const MEDALS = ["🥇", "🥈", "🥉"];
                  const isMyTeam = r.team_id === team?.id;

                  return (
                    <div
                      key={r.team_id}
                      className={`flex items-center gap-3 p-3 rounded-xl border ${
                        isMyTeam
                          ? "border-orange-500/30 bg-orange-500/5 shadow-md shadow-orange-500/5 text-foreground"
                          : "border-zinc-850 bg-zinc-900/20 text-muted-foreground"
                      }`}
                    >
                      <span className="font-display w-7 text-center text-xl shrink-0">
                        {MEDALS[i] ?? `#${i + 1}`}
                      </span>
                      <span
                        className="grid size-9 shrink-0 place-items-center rounded-lg text-lg"
                        style={{ backgroundColor: `${r.color || "#f97316"}20` }}
                      >
                        {r.avatar_url ?? "🏳️"}
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-extrabold text-foreground">{r.name}</p>
                        <p className="truncate text-[10px] text-muted-foreground">
                          {r.completed_challenges} prove · {formatDuration(r.total_duration_seconds)}
                        </p>
                      </div>
                      <span className="font-display text-xl text-gold shrink-0">{r.total_points}</span>
                    </div>
                  );
                })
              )}
            </div>

            {/* MODAL FOOTER */}
            <div className="mt-4 pt-3 border-t border-white/10 shrink-0 flex items-center justify-between text-[10px] text-muted-foreground">
              <span>⚠️ Visualizzazione monouso: non chiudere la schermata.</span>
              <span className="font-mono text-gold font-bold">LIVE 🟢</span>
            </div>
          </div>
        </div>
      )}
      {/* RUOTA DELLA FORTUNA MODAL */}
      {isWheelOpen && wheelOutcome && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-zinc-950/85 backdrop-blur-md animate-in fade-in duration-200">
          <div className="surface w-full max-w-md p-6 max-h-[90vh] flex flex-col border border-purple-500/20 bg-zinc-950/95 shadow-2xl animate-in scale-in duration-250 rounded-2xl relative overflow-hidden">
            {/* Background decorative glow */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-64 h-64 bg-purple-500/5 rounded-full blur-3xl pointer-events-none" />

            {/* MODAL HEADER */}
            <div className="flex items-center justify-between border-b border-white/10 pb-4 mb-4 shrink-0">
              <h3 className="font-display text-2xl text-purple-400 flex items-center gap-2">
                <WheelIcon className="size-6 text-purple-400 animate-spin-slow" /> Ruota della Fortuna
              </h3>
              {!isSpinning && !showPrize && (
                <button
                  onClick={() => setIsWheelOpen(false)}
                  className="text-xs font-black uppercase tracking-wider text-muted-foreground hover:text-white px-3 py-1.5 rounded-lg hover:bg-zinc-900 border border-zinc-800 transition-all cursor-pointer"
                >
                  Annulla
                </button>
              )}
            </div>

            {/* MODAL BODY */}
            <div className="flex-1 flex flex-col justify-center items-center py-4 space-y-6 overflow-y-auto">
              {!showPrize ? (
                <>
                  <div className="text-center space-y-1">
                    <p className="text-xs font-black uppercase tracking-wider text-amber-400 animate-pulse">
                      Hai una sola possibilità!
                    </p>
                    <p className="text-[10px] text-muted-foreground leading-normal px-6">
                      La decisione è definitiva. La ruota non potrà essere girata una seconda volta.
                    </p>
                  </div>

                  {/* Graphic rotating SVG Wheel */}
                  <div className="relative w-[280px] h-[280px] sm:w-[300px] sm:h-[300px] shrink-0 my-2">
                    {/* The Wheel SVG */}
                    <svg
                      viewBox="0 0 400 400"
                      className="w-full h-full select-none"
                      style={{
                        transform: `rotate(${wheelRotation}deg)`,
                        transition: isSpinning ? "transform 5000ms cubic-bezier(0.2, 0.8, 0.2, 1)" : "none",
                      }}
                    >
                      <circle cx="200" cy="200" r="190" fill="#18181b" stroke="#27272a" strokeWidth="8" />
                      <circle cx="200" cy="200" r="186" fill="none" stroke="#a855f7" strokeWidth="2" opacity="0.3" />

                      {WHEEL_SLICES.map((slice, i) => {
                        const startAngle = i * 40;
                        const endAngle = (i + 1) * 40;
                        const midAngle = startAngle + 20;
                        return (
                          <g key={slice.id}>
                            <path
                              d={describeArc(200, 200, 180, startAngle, endAngle)}
                              fill={slice.color}
                              stroke="#18181b"
                              strokeWidth="2.5"
                            />
                            <g transform={`rotate(${midAngle} 200 200)`}>
                              <text
                                x="200"
                                y="52"
                                textAnchor="middle"
                                fill={slice.text}
                                fontSize="8.5"
                                fontWeight="900"
                                transform="rotate(90 200 52)"
                              >
                                {slice.label}
                              </text>
                            </g>
                          </g>
                        );
                      })}

                      {/* Inner center pin */}
                      <circle cx="200" cy="200" r="24" fill="#18181b" stroke="#a855f7" strokeWidth="3" />
                      <circle cx="200" cy="200" r="8" fill="#a855f7" />
                    </svg>

                    {/* Pointer - stationary at top pointing down */}
                    <div className="absolute top-[-6px] left-[50%] translate-x-[-50%] z-10 w-0 h-0 border-l-[12px] border-l-transparent border-r-[12px] border-r-transparent border-t-[20px] border-t-purple-400 drop-shadow-[0_3px_5px_rgba(0,0,0,0.6)]" />
                  </div>

                  {/* SPIN BUTTON */}
                  <button
                    onClick={handleSpinWheel}
                    disabled={isSpinning}
                    className="px-8 py-3.5 rounded-2xl bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white font-black text-sm uppercase tracking-widest shadow-lg shadow-purple-500/10 active:scale-[0.98] transition-all disabled:opacity-40 flex items-center gap-2 cursor-pointer"
                  >
                    {isSpinning ? (
                      <>
                        <Loader2 className="size-4 animate-spin" />
                        GIRANDO...
                      </>
                    ) : (
                      <>
                        <WheelIcon className="size-4 animate-spin-slow" />
                        GIRA LA RUOTA!
                      </>
                    )}
                  </button>
                </>
              ) : (
                /* PRIZE DETAILS OVERLAY */
                <div className="w-full py-4 text-center space-y-6">
                  {wheelOutcome.id === "dave_help" ? (
                    <div className="space-y-5 animate-in zoom-in-95 duration-300">
                      <div className="size-20 bg-purple-500/10 rounded-full flex items-center justify-center mx-auto border border-purple-500/20 text-purple-400 animate-pulse">
                        <HelpCircle className="size-10 text-purple-400" />
                      </div>
                      <div className="space-y-2">
                        <h4 className="text-xl font-display font-black text-purple-400 uppercase tracking-wider">
                          🧠 AIUTO EXTRA DI DAVE!
                        </h4>
                        <p className="text-xs text-muted-foreground leading-relaxed px-6">
                          La fortuna è dalla vostra parte! Per ricevere il vostro aiuto extra dovete chiamare Dave al telefono.
                        </p>
                      </div>
                      <div className="pt-2">
                        <a
                          href="tel:+393333333333"
                          className="inline-flex items-center gap-2 px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-extrabold text-xs uppercase tracking-wider transition-all shadow-lg active:scale-[0.98] cursor-pointer"
                        >
                          📞 CHIAMA DAVE
                        </a>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-5 animate-in zoom-in-95 duration-300">
                      <div className="text-5xl animate-bounce">🎉</div>
                      <div className="space-y-2">
                        <span className="text-[10px] uppercase font-extrabold tracking-widest text-emerald-400 font-mono">
                          HAI VINTO!
                        </span>
                        <h4 className="text-xl font-display font-black text-white uppercase tracking-wider">
                          {wheelOutcome.label}
                        </h4>
                        <p className="text-xs text-muted-foreground">
                          {wheelOutcome.points > 0 && `+${wheelOutcome.points} Punti `}
                          {wheelOutcome.points > 0 && wheelOutcome.tokens > 0 && "e "}
                          {wheelOutcome.tokens > 0 && `+${wheelOutcome.tokens} Token`}
                        </p>
                      </div>
                      
                      <div className="bg-zinc-900/60 p-4 rounded-xl border border-zinc-800 text-left space-y-1.5 max-w-xs mx-auto text-xs">
                        {wheelOutcome.points > 0 && (
                          <div className="flex justify-between">
                            <span className="text-zinc-500 font-medium">Nuovo Punteggio:</span>
                            <span className="font-extrabold text-gold">
                              {(currentPoints + wheelOutcome.points)} PT
                            </span>
                          </div>
                        )}
                        {wheelOutcome.tokens > 0 && (
                          <div className="flex justify-between">
                            <span className="text-zinc-500 font-medium">Nuovo Saldo:</span>
                            <span className="font-extrabold text-orange-400">
                              {(balance + wheelOutcome.tokens)} 🪙
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  <button
                    onClick={() => {
                      setIsWheelOpen(false);
                      setWheelOutcome(null);
                      setWheelRotation(0);
                      setShowPrize(false);
                      queryClient.invalidateQueries();
                    }}
                    className="px-6 py-2.5 rounded-xl border border-zinc-800 hover:bg-zinc-900 text-xs font-black uppercase tracking-wider text-foreground hover:text-white transition-all cursor-pointer"
                  >
                    Conferma
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
      {/* CONFIRMATION MODAL */}
      {confirmBonusItem && (() => {
        const isPunti = confirmBonusItem.id === "bonus_punti";
        const costStr = isPunti ? "40 Token 🪙" : "20 Token 🪙";
        const rewardStr = isPunti ? "+20 PT ⭐" : "Un indizio SÌ/NO dalla Regia 📞";
        const descText = isPunti 
          ? "Confermi l'acquisto del Bonus Punti?"
          : "Confermi l'acquisto del Passaparola? Potrai utilizzare la Regia una sola volta per ottenere un aiuto SÌ/NO. Questa azione non può essere annullata.";
        
        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-zinc-950/80 backdrop-blur-md animate-in fade-in duration-200">
            <div className="surface max-w-sm w-full rounded-2xl p-6 shadow-2xl border border-zinc-800 bg-[#070d1e] space-y-6 relative overflow-hidden text-center">
              <div className="absolute top-0 right-0 w-24 h-24 bg-yellow-500/5 rounded-full blur-3xl pointer-events-none" />
              <div className="size-16 rounded-full bg-yellow-500/10 flex items-center justify-center mx-auto border border-yellow-500/20 text-yellow-500 animate-pulse">
                {isPunti ? <Sparkles className="size-8" /> : <PhoneCall className="size-8 text-orange-500" />}
              </div>
              <div className="space-y-2">
                <h3 className="text-lg font-black text-foreground uppercase tracking-wide">
                  Conferma Acquisto
                </h3>
                <p className="text-xs text-muted-foreground leading-relaxed px-2">
                  {descText}
                </p>
              </div>
              <div className="bg-zinc-900/40 p-3 rounded-xl border border-zinc-800 text-left text-xs space-y-1.5 max-w-xs mx-auto">
                <div className="flex justify-between">
                  <span className="text-zinc-500">Costo:</span>
                  <span className="font-extrabold text-orange-400">{costStr}</span>
                </div>
                <div className="flex flex-col gap-0.5">
                  <span className="text-zinc-500">Ricompensa / Effetto:</span>
                  <span className="font-extrabold text-emerald-400">{rewardStr}</span>
                </div>
                <div className="pt-1.5 border-t border-white/5 text-[9px] text-zinc-500 text-center uppercase tracking-wider font-semibold">
                  ⚠️ Questa azione è monouso e irreversibile
                </div>
              </div>
              <div className="flex gap-3">
                <button
                  onClick={() => setConfirmBonusItem(null)}
                  className="flex-1 py-2.5 rounded-xl border border-zinc-800 hover:bg-zinc-900 text-xs font-black uppercase text-muted-foreground transition-all cursor-pointer"
                >
                  Annulla
                </button>
                <button
                  onClick={() => {
                    handlePurchase(confirmBonusItem.id);
                    setConfirmBonusItem(null);
                  }}
                  className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-600 text-black font-black text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer"
                >
                  Conferma
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* TRAPPOLA SUCCESS ANIMATION & REPORT OVERLAY */}
      {isTrapAnimationActive && trapSuccessData && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/95 backdrop-blur-lg animate-in fade-in duration-300">
          <div className="surface border border-red-500/20 bg-[#070d1e] max-w-md w-full rounded-3xl p-6 sm:p-8 shadow-2xl text-center space-y-6 relative overflow-hidden animate-in zoom-in-95 duration-300">
            {/* Background elements */}
            <div className="absolute inset-0 bg-radial-gradient from-red-500/10 to-transparent pointer-events-none" />

            {trapAnimStep === 0 && (
              <div className="space-y-6 py-8 animate-in zoom-in-95 duration-500">
                <div className="size-24 rounded-full bg-red-500/10 border border-red-500/30 flex items-center justify-center mx-auto animate-bounce shadow-lg shadow-red-500/10">
                  <Skull className="size-12 text-red-500" />
                </div>
                <h2 className="text-2xl font-display font-black text-red-500 uppercase tracking-widest animate-pulse">
                  🪤 TRAPPOLA ATTIVATA!
                </h2>
                <p className="text-xs text-zinc-400 font-semibold max-w-xs mx-auto leading-relaxed">
                  Innesco trappola completato contro la squadra <strong className="text-white font-black">{trapSuccessData.targetName}</strong>.
                </p>
              </div>
            )}

            {trapAnimStep === 1 && (
              <div className="space-y-6 py-8 animate-in zoom-in-95 duration-500">
                <div className="size-24 rounded-full bg-rose-500/10 border border-rose-500/30 flex items-center justify-center mx-auto animate-pulse">
                  <span className="text-4xl font-black text-rose-500">-</span>
                </div>
                <h2 className="text-3xl font-display font-black text-rose-500 uppercase tracking-widest">
                  💥 -{trapSuccessData.pointsStolen} PT
                </h2>
                <p className="text-xs text-zinc-400 font-semibold max-w-xs mx-auto leading-relaxed">
                  Sottratti con successo da <strong className="text-white font-black">{trapSuccessData.targetName}</strong>!
                </p>
              </div>
            )}

            {trapAnimStep === 2 && (
              <div className="space-y-6 py-8 animate-in zoom-in-95 duration-500">
                <div className="size-24 rounded-full bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center mx-auto animate-bounce">
                  <span className="text-4xl font-black text-emerald-500">+</span>
                </div>
                <h2 className="text-3xl font-display font-black text-emerald-500 uppercase tracking-widest">
                  🏆 +{trapSuccessData.pointsStolen} PT
                </h2>
                <p className="text-xs text-zinc-400 font-semibold max-w-xs mx-auto leading-relaxed">
                  I punti rubati sono stati accreditati alla tua squadra!
                </p>
              </div>
            )}

            {trapAnimStep === 3 && (
              <div className="space-y-6 animate-in fade-in duration-500">
                <div className="size-16 rounded-full bg-red-500/10 border border-red-500/30 flex items-center justify-center mx-auto shadow-md">
                  <Skull className="size-8 text-red-500" />
                </div>
                
                <h3 className="text-xl font-display font-black text-white uppercase tracking-wider">
                  Riepilogo Trappola
                </h3>

                <div className="bg-zinc-950/80 p-4 rounded-2xl border border-zinc-800 text-left text-xs space-y-2.5 shadow-inner">
                  <div className="flex justify-between border-b border-zinc-900 pb-1.5 font-semibold text-zinc-400">
                    <span>Bersaglio:</span>
                    <strong className="text-white">{trapSuccessData.targetName}</strong>
                  </div>
                  <div className="flex justify-between font-semibold text-zinc-400">
                    <span>Punti prima del bersaglio:</span>
                    <span className="text-zinc-300 font-mono">{trapSuccessData.targetPointsBefore} PT</span>
                  </div>
                  <div className="flex justify-between font-semibold text-zinc-400">
                    <span>Punti rubati:</span>
                    <span className="text-red-400 font-mono font-bold">-{trapSuccessData.pointsStolen} PT</span>
                  </div>
                  <div className="flex justify-between border-b border-zinc-900 pb-1.5 font-semibold text-zinc-400">
                    <span>Punti bersaglio dopo:</span>
                    <span className="text-zinc-300 font-mono">{trapSuccessData.targetPointsAfter} PT</span>
                  </div>
                  <div className="flex justify-between font-semibold text-zinc-400">
                    <span>La tua squadra:</span>
                    <span className="text-emerald-400 font-mono font-bold">+{trapSuccessData.pointsStolen} PT</span>
                  </div>
                  <div className="flex justify-between font-semibold text-zinc-400">
                    <span>Costo:</span>
                    <span className="text-orange-400 font-mono font-bold">-40 Token 🪙</span>
                  </div>
                </div>

                <button
                  onClick={() => {
                    setIsTrapAnimationActive(false);
                    setTrapSuccessData(null);
                    setSelectedMalus(null);
                    setTargetTeamId("");
                    queryClient.invalidateQueries();
                  }}
                  className="w-full py-3 rounded-xl bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-white font-extrabold text-xs uppercase tracking-wider shadow-md transition-all active:scale-[0.98]"
                >
                  Concludi Operazione
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* PENALITÀ PUNTI SUCCESS MODAL */}
      {isPenaltySuccessActive && penaltySuccessData && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md animate-in fade-in duration-200">
          <div className="surface border border-red-500/20 bg-[#070d1e] max-w-sm w-full rounded-2xl p-6 shadow-2xl space-y-5 text-center relative overflow-hidden">
            <div className="absolute top-0 right-0 w-24 h-24 bg-red-500/5 rounded-full blur-3xl pointer-events-none" />
            <div className="size-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto border border-red-500/25 text-red-500">
              <Skull className="size-8" />
            </div>
            
            <div className="space-y-2">
              <h3 className="text-lg font-black text-foreground uppercase tracking-wide">
                ✅ Penalità Acquistata
              </h3>
              <p className="text-xs text-emerald-400 font-extrabold uppercase tracking-wide">
                ⚡ Penalità Applicata
              </p>
              <p className="text-xs text-zinc-300 px-2 font-medium">
                La squadra <strong className="text-white font-black">{penaltySuccessData.targetName}</strong> ha perso <strong className="text-red-400 font-black">{penaltySuccessData.pointsDeducted} PT</strong>.
                {penaltySuccessData.pointsDeducted < 20 && (
                  <span className="block mt-1 text-[10px] text-orange-400 italic font-semibold">
                    Il punteggio non può scendere sotto 0.
                  </span>
                )}
              </p>
            </div>

            <div className="bg-zinc-950/80 p-4 rounded-xl border border-zinc-800 text-left text-xs space-y-2 max-w-xs mx-auto">
              <div className="flex justify-between border-b border-zinc-900 pb-1.5">
                <span className="text-zinc-500">Bersaglio:</span>
                <strong className="text-white font-bold">{penaltySuccessData.targetName}</strong>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-500">Costo sostenuto:</span>
                <span className="font-extrabold text-orange-400">30 Token 🪙</span>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-500">Penalità nominale:</span>
                <span className="font-bold text-red-400">-20 PT</span>
              </div>
              <div className="flex justify-between">
                <span className="text-zinc-500">Punti prima:</span>
                <span className="font-mono text-zinc-300">{penaltySuccessData.targetPointsBefore} PT</span>
              </div>
              <div className="flex justify-between border-t border-zinc-900 pt-1.5">
                <span className="text-zinc-500 font-bold">Punti dopo:</span>
                <span className="font-mono font-extrabold text-white">{penaltySuccessData.targetPointsAfter} PT</span>
              </div>
            </div>

            <button
              onClick={() => {
                setIsPenaltySuccessActive(false);
                setPenaltySuccessData(null);
                setSelectedMalus(null);
                setTargetTeamId("");
                queryClient.invalidateQueries();
              }}
              className="w-full py-2.5 rounded-xl bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-white font-black text-xs uppercase tracking-wider transition-all"
            >
              Concludi
            </button>
          </div>
        </div>
      )}

      {/* TASSA DI PASSAGGIO SUCCESS OVERLAY */}
      {isSwitchSuccessActive && switchSuccessData && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/95 backdrop-blur-lg animate-in fade-in duration-300">
          <div className="surface border border-blue-500/20 bg-[#070d1e] max-w-md w-full rounded-3xl p-6 sm:p-8 shadow-2xl text-center space-y-6 relative overflow-hidden animate-in zoom-in-95 duration-300">
            <div className="absolute inset-0 bg-radial-gradient from-blue-500/10 to-transparent pointer-events-none" />

            {switchAnimStep === 0 && (
              <div className="space-y-6 py-8 animate-in zoom-in-95 duration-500">
                <div className="size-24 rounded-full bg-blue-500/10 border border-blue-500/30 flex items-center justify-center mx-auto animate-bounce shadow-lg shadow-blue-500/10">
                  <RefreshCw className="size-12 text-blue-500 animate-spin duration-1000" />
                </div>
                <h2 className="text-2xl font-display font-black text-blue-400 uppercase tracking-widest animate-pulse">
                  🔄 TASSA DI PASSAGGIO
                </h2>
                <p className="text-xs text-zinc-400 font-semibold max-w-xs mx-auto leading-relaxed">
                  Lettura dei punteggi live in corso... Collegamento al database stabilito.
                </p>
              </div>
            )}

            {switchAnimStep === 1 && (
              <div className="space-y-6 py-8 animate-in zoom-in-95 duration-500">
                <div className="size-24 rounded-full bg-indigo-500/10 border border-indigo-500/30 flex items-center justify-center mx-auto animate-pulse">
                  <RefreshCw className="size-12 text-indigo-500 animate-spin duration-300" />
                </div>
                <h2 className="text-2xl font-display font-black text-indigo-400 uppercase tracking-widest">
                  ⚡ SCAMBIO PUNTEGGI...
                </h2>
                <p className="text-xs text-zinc-400 font-semibold max-w-xs mx-auto leading-relaxed">
                  Switching dei Punti Squadra con <strong className="text-white font-black">{switchSuccessData.targetName}</strong>...
                </p>
              </div>
            )}

            {switchAnimStep === 2 && (
              <div className="space-y-6 animate-in fade-in duration-500">
                <div className="size-16 rounded-full bg-blue-500/10 border border-blue-500/30 flex items-center justify-center mx-auto shadow-md">
                  <RefreshCw className="size-8 text-blue-400 animate-spin duration-1000" />
                </div>
                
                <h3 className="text-xl font-display font-black text-white uppercase tracking-wider">
                  Switch Applicato!
                </h3>

                <div className="bg-zinc-950/80 p-4 rounded-2xl border border-zinc-800 text-left text-xs space-y-2.5 shadow-inner">
                  <div className="flex justify-between border-b border-zinc-900 pb-1.5 font-semibold text-zinc-400">
                    <span>Bersaglio colpito:</span>
                    <strong className="text-white">{switchSuccessData.targetName}</strong>
                  </div>
                  
                  <div className="space-y-1.5 pt-1">
                    <span className="block text-[10px] text-zinc-500 font-black uppercase tracking-wider">Stato Punteggio:</span>
                    <p className="text-zinc-400 leading-normal">
                      I tuoi punti sono stati aggiornati.
                    </p>
                    <div className="flex justify-between font-semibold text-zinc-400">
                      <span>Punteggio attuale:</span>
                      <strong className="text-emerald-400 font-mono font-extrabold text-sm">
                        {switchSuccessData.buyerPointsAfter} PT
                      </strong>
                    </div>
                  </div>

                  <div className="flex justify-between border-t border-zinc-900 pt-2 font-semibold text-zinc-400">
                    <span>Costo switch:</span>
                    <span className="text-orange-400 font-mono font-bold">-70 Token 🪙</span>
                  </div>
                </div>

                <button
                  onClick={() => {
                    setIsSwitchSuccessActive(false);
                    setSwitchSuccessData(null);
                    setSelectedMalus(null);
                    setTargetTeamId("");
                    queryClient.invalidateQueries();
                  }}
                  className="w-full py-3 rounded-xl bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-white font-extrabold text-xs uppercase tracking-wider shadow-md transition-all active:scale-[0.98]"
                >
                  Concludi Operazione
                </button>
              </div>
            )}
          </div>
        </div>
      )}

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
              ⚠️ <strong>Nessuna risposta automatica:</strong> La richiesta verrà notificata alla Regia fisica che vi risponderà manualmente con un <strong>SÌ</strong> o con un <strong>NO</strong>. Non potrete effettuare una seconda richiesta.
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
    </AppShell>
  );
}
