import { Link, useNavigate, useLocation } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  LogOut,
  Trophy,
  LayoutDashboard,
  Shield,
  WifiOff,
  Flag,
  History,
  Map,
  Menu,
  ShoppingBag,
  Lock,
  Skull,
  Camera,
  Film,
  Share2,
  Settings,
  BarChart3,
  Users,
  Puzzle,
  Swords,
  Sparkles,
  PhoneCall,
  Zap,
  Snowflake,
  Loader2,
  RefreshCw,
  HelpCircle,
  ShieldAlert,
  FileText,
} from "lucide-react";
import { ReactNode, useState, useEffect, useRef, useCallback } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import {
  myTeamQuery,
  stagesQuery,
  challengesQuery,
  progressQuery,
  isStageUnlocked,
  reportStatusQuery,
  gameSettingsQuery,
} from "@/lib/race";
import { triggerHaptic } from "@/lib/haptics";
import { AdminDecisionModal } from "@/components/AdminDecisionModal";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarTrigger,
  useSidebar,
} from "@/components/ui/sidebar";

export function AppShell({
  children,
  isAdmin,
}: {
  children: ReactNode;
  isAdmin?: boolean | undefined;
}) {
  return (
    <SidebarProvider>
      <AppShellInner isAdmin={isAdmin}>{children}</AppShellInner>
    </SidebarProvider>
  );
}

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
  const d = [
    "M", x, y,
    "L", start.x, start.y,
    "A", radius, radius, 0, largeArcFlag, 0, end.x, end.y,
    "Z"
  ].join(" ");
  return d;
};

const UNLUCKY_WHEEL_SLICES = [
  { id: "freeze_2min", emoji: "❄️", label: "FREEZE (2m)", color: "#06b6d4", text: "#000000" },
  { id: "minus_20_points", emoji: "💸", label: "-20 PUNTI", color: "#dc2626", text: "#ffffff" },
  { id: "minus_10_tokens", emoji: "🪙", label: "-10 TOKEN", color: "#ea580c", text: "#ffffff" },
  { id: "plus_2_min", emoji: "⏱️", label: "+2 MINUTI", color: "#eab308", text: "#000000" },
  { id: "heavy_backpack", emoji: "🎒", label: "ZAINO (+3m)", color: "#16a34a", text: "#ffffff" },
  { id: "minus_10_points_minus_5_tokens", emoji: "💥", label: "-10PT / -5TK", color: "#4f46e5", text: "#ffffff" }
];

function AppShellInner({
  children,
  isAdmin,
}: {
  children: ReactNode;
  isAdmin?: boolean | undefined;
}) {
  const { toggleSidebar, setOpenMobile, isMobile, state } = useSidebar();
  const navigate = useNavigate();
  const location = useLocation();
  const currentPath = location.pathname;
  const queryClient = useQueryClient();

  const closeMobileMenu = () => {
    if (isMobile) {
      setOpenMobile(false);
    }
  };

  // These classes are applied directly to the <Link> via activeProps / className.
  // They MUST NOT override padding/size since sidebarMenuButtonVariants handles
  // those via `group-data-[collapsible=icon]:!size-8 group-data-[collapsible=icon]:!p-2`.
  const activeLinkClass =
    "bg-orange-500/15 text-orange-400 font-bold rounded-lg shadow-sm";
  const inactiveLinkClass =
    "text-slate-400 hover:text-white hover:bg-white/6 transition-all duration-200 rounded-lg";

  const [secondsLeft, setSecondsLeft] = useState(0);
  const [enigmaAnswer, setEnigmaAnswer] = useState("");
  const [isSubmittingEnigma, setIsSubmittingEnigma] = useState(false);
  const [enigmaError, setEnigmaError] = useState("");

  const [unluckyRotation, setUnluckyRotation] = useState(0);
  const [isUnluckySpinning, setIsUnluckySpinning] = useState(false);
  const [showUnluckyPrize, setShowUnluckyPrize] = useState(false);
  const [unluckyOutcome, setUnluckyOutcome] = useState<any>(null);

  // Manual Refresh state & handlers (especially useful when installed as mobile PWA/standalone)
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleManualRefresh = useCallback(async () => {
    if (isRefreshing) return;
    setIsRefreshing(true);
    try {
      await queryClient.invalidateQueries();
      await queryClient.refetchQueries();
      toast.success("Dati aggiornati con successo", { duration: 2000 });
    } catch {
      window.location.reload();
    } finally {
      setTimeout(() => {
        setIsRefreshing(false);
      }, 500);
    }
  }, [isRefreshing, queryClient]);

  const handleHardRefresh = () => {
    toast.info("Ricaricamento completo...");
    setTimeout(() => {
      window.location.reload();
    }, 200);
  };

  // Mobile pull-to-refresh listener for standalone Home Screen mode
  useEffect(() => {
    let startY = 0;
    let isPulling = false;

    const handleTouchStart = (e: TouchEvent) => {
      const touch = e.touches[0];
      if (window.scrollY <= 5 && e.touches.length === 1 && touch) {
        startY = touch.clientY;
        isPulling = true;
      } else {
        isPulling = false;
      }
    };

    const handleTouchMove = (e: TouchEvent) => {
      const touch = e.touches[0];
      if (!isPulling || !touch) return;
      const currentY = touch.clientY;
      const diffY = currentY - startY;
      if (diffY > 110 && window.scrollY <= 5) {
        isPulling = false;
        handleManualRefresh();
      }
    };

    const handleTouchEnd = () => {
      isPulling = false;
    };

    window.addEventListener("touchstart", handleTouchStart, { passive: true });
    window.addEventListener("touchmove", handleTouchMove, { passive: true });
    window.addEventListener("touchend", handleTouchEnd, { passive: true });

    return () => {
      window.removeEventListener("touchstart", handleTouchStart);
      window.removeEventListener("touchmove", handleTouchMove);
      window.removeEventListener("touchend", handleTouchEnd);
    };
  }, [handleManualRefresh]);

  // Query database state to determine if Marketplace is unlocked and active
  const team = useQuery({ ...myTeamQuery, enabled: !isAdmin, refetchInterval: 3000 });

  // Query all teams list to identify attacker name
  const allTeamsQuery = useQuery({
    queryKey: ["all-teams-list-for-freeze"],
    enabled: !isAdmin && !!team.data?.id,
    queryFn: async () => {
      const { data } = await supabase.from("teams").select("id, nome_squadra");
      return data ?? [];
    }
  });

  // Query all active modal malus transactions targeting this team (strictly freeze_2min, enigma_extra, ruota_sfortunata)
  const activeMalusesQuery = useQuery({
    queryKey: ["active-modal-maluses-for-team", team.data?.id],
    enabled: !isAdmin && !!team.data?.id,
    refetchInterval: 2000,
    queryFn: async () => {
      const { data } = await supabase
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id,timestamp:data_acquisto")
        .eq("target_team_id", team.data?.id)
        .in("marketplace_item_id", ["freeze_2min", "enigma_extra", "ruota_sfortunata"])
        .eq("stato", "completed")
        .order("data_acquisto", { ascending: true });
      return data ?? [];
    }
  });

  const handledFreezeIdsRef = useRef<Set<string>>(new Set());

  const pendingMaluses = activeMalusesQuery.data ?? [];
  const queuedMalusesCount = pendingMaluses.length;
  const currentActiveMalusTx = pendingMaluses[0] || null;

  const isCurrentFreeze = currentActiveMalusTx?.item_id === "freeze_2min";
  const isCurrentEnigma = currentActiveMalusTx?.item_id === "enigma_extra";
  const isCurrentWheel = currentActiveMalusTx?.item_id === "ruota_sfortunata";

  const isFrozen = isCurrentFreeze && secondsLeft > 0;

  useEffect(() => {
    if (!isCurrentFreeze || !currentActiveMalusTx) {
      setSecondsLeft(0);
      return;
    }

    const txId = currentActiveMalusTx.id;
    if (handledFreezeIdsRef.current.has(txId)) {
      setSecondsLeft(0);
      return;
    }

    const startMs = currentActiveMalusTx.data_acquisto
      ? new Date(currentActiveMalusTx.data_acquisto).getTime()
      : (currentActiveMalusTx.timestamp ? new Date(currentActiveMalusTx.timestamp).getTime() : Date.now());

    const durationMs = 120 * 1000;
    const targetExpiryMs = startMs + durationMs;

    const updateRemaining = async () => {
      if (handledFreezeIdsRef.current.has(txId)) {
        return;
      }
      const now = Date.now();
      const remaining = Math.ceil((targetExpiryMs - now) / 1000);
      if (remaining <= 0) {
        handledFreezeIdsRef.current.add(txId);
        setSecondsLeft(0);

        toast.success("❄️ FREEZE TERMINATO! Siete di nuovo operativi.");

        await supabase.rpc("consume_marketplace_transaction", {
          p_transaction_id: txId,
        });

        queryClient.invalidateQueries();
      } else {
        setSecondsLeft(remaining);
      }
    };

    updateRemaining();
    const interval = setInterval(updateRemaining, 1000);

    return () => {
      clearInterval(interval);
    };
  }, [isCurrentFreeze, currentActiveMalusTx?.id, queryClient]);

  const pendingUnluckyWheelTx = isCurrentWheel ? currentActiveMalusTx : null;
  const activeEnigmaTx = isCurrentEnigma ? currentActiveMalusTx : null;

  const attackerTeam = currentActiveMalusTx
    ? allTeamsQuery.data?.find((t: any) => t.id === currentActiveMalusTx.buyer_team_id)
    : null;
  const attackerName = attackerTeam?.nome_squadra || "Una squadra avversaria";

  const handleSubmitEnigmaExtra = async (e: any) => {
    e.preventDefault();
    if (!enigmaAnswer.trim() || !currentActiveMalusTx) return;
    setIsSubmittingEnigma(true);
    setEnigmaError("");
    try {
      const { data, error } = await supabase.rpc("submit_enigma_extra_answer", {
        p_answer: enigmaAnswer
      });
      if (error) {
        setEnigmaError(error.message || "Errore di verifica.");
      } else if (data && data.is_correct) {
        const txId = currentActiveMalusTx.id;

        await supabase.rpc("consume_marketplace_transaction", {
          p_transaction_id: txId,
        });

        toast.success("🧩 ENIGMA RISOLTO CORRETTAMENTE! Squadra sbloccata.");
        setEnigmaAnswer("");
        queryClient.invalidateQueries();
      } else {
        setEnigmaError("❌ RISPOSTA ERRATA! Riprova.");
      }
    } catch (err: any) {
      setEnigmaError(err.message || "Errore imprevisto.");
    } finally {
      setIsSubmittingEnigma(false);
    }
  };

  const handleSpinUnluckyWheel = async () => {
    if (isUnluckySpinning || !pendingUnluckyWheelTx) return;
    setIsUnluckySpinning(true);
    setShowUnluckyPrize(false);

    try {
      const { data, error } = await supabase.rpc("spin_unlucky_wheel");
      if (error) {
        toast.error(error.message || "Errore durante lo spin.");
        setIsUnluckySpinning(false);
        return;
      }

      if (data && data.outcome) {
        const outcome = data.outcome;
        setUnluckyOutcome(outcome);
        
        const sliceIndex = UNLUCKY_WHEEL_SLICES.findIndex((s) => s.id === outcome.id);
        if (sliceIndex === -1) {
          toast.error("Errore nell'inizializzazione del risultato.");
          setIsUnluckySpinning(false);
          return;
        }

        const rotationAngle = 360 * 6 + (360 - (sliceIndex * 60 + 30));
        
        requestAnimationFrame(() => {
          setUnluckyRotation(rotationAngle);
        });

        setTimeout(() => {
          setIsUnluckySpinning(false);
          setShowUnluckyPrize(true);
          toast.warning(`🎡 MALUS RICEVUTO: ${outcome.label}`);
          queryClient.invalidateQueries();
        }, 5200);
      } else {
        toast.error("Errore durante l'estrazione.");
        setIsUnluckySpinning(false);
      }
    } catch (e: any) {
      toast.error(e.message || "Errore imprevisto.");
      setIsUnluckySpinning(false);
    }
  };

  const handleDismissUnluckyWheel = async () => {
    triggerHaptic("light");
    if (pendingUnluckyWheelTx) {
      const txId = pendingUnluckyWheelTx.id;
      await supabase.rpc("consume_marketplace_transaction", {
        p_transaction_id: txId,
      });
    }
    setUnluckyRotation(0);
    setIsUnluckySpinning(false);
    setShowUnluckyPrize(false);
    setUnluckyOutcome(null);
    queryClient.invalidateQueries();
  };

  const formatTime = (sec: number) => {
    const m = Math.floor(sec / 60).toString().padStart(2, "0");
    const s = (sec % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  };

  const gameSettings = useQuery(gameSettingsQuery);


  const isMarketplaceActive = gameSettings.data?.marketplace_active === true;

  const progress = useQuery({
    ...progressQuery(team.data?.id),
    enabled: !isAdmin && !!team.data?.id,
  });
  const hasCompletedTappa1 =
    progress.data?.some(
      (p: any) =>
        p.challenge_id === "0147e750-f0a3-4b72-8e76-a003fe2ef143" &&
        (p.stato === "completed" || p.status === "completed")
    ) === true;
  // Query team's bonus_classifica transaction to check lock state
  const classificationTxQuery = useQuery({
    queryKey: ["team-classification-bonus", team.data?.id],
    enabled: !isAdmin && !!team.data?.id,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("id, stato, buyer_team_id:team_id, item_id:marketplace_item_id")
        .eq("team_id", team.data?.id)
        .eq("marketplace_item_id", "bonus_classifica")
        .order("data_acquisto", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error) return null;
      return data;
    },
  });

  const classificationTx = classificationTxQuery.data;
  // Unlocked while: purchased but not yet opened (completed) OR currently being viewed (viewing)
  const isClassificationUnlocked = classificationTx && (classificationTx.stato === "completed" || classificationTx.stato === "viewing");

  // Track route leaving /classifica: immediately consume the bonus if user moves to another page
  const prevPathRef = useRef(currentPath);
  useEffect(() => {
    if (prevPathRef.current === "/classifica" && currentPath !== "/classifica" && classificationTx?.id) {
      if (classificationTx.stato === "completed" || classificationTx.stato === "viewing") {
        (supabase as any).rpc("consume_marketplace_transaction", {
          p_transaction_id: classificationTx.id,
        });
        queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
        queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
      }
    }
    prevPathRef.current = currentPath;
  }, [currentPath, classificationTx?.id, classificationTx?.stato, queryClient]);

  // Query all transactions to count pending Passaparola requests for Admin badge
  const transactionsQuery = useQuery({
    queryKey: ["admin-marketplace-transactions-badge"],
    enabled: !!isAdmin,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("id, item_id:marketplace_item_id, stato")
        .eq("marketplace_item_id", "passaparola")
        .eq("stato", "pending");
      if (error) return [];
      return data ?? [];
    },
  });

  const pendingPassaparolaCount = transactionsQuery.data?.length ?? 0;

  const reportStatus = useQuery(reportStatusQuery);
  const isReportPublished = reportStatus.data?.is_published ?? false;

  async function signOut() {
    await queryClient.cancelQueries();
    queryClient.clear();
    await supabase.auth.signOut();
    navigate({ to: "/auth", replace: true });
  }

  const adminGroups = [
    {
      title: "Monitoraggio",
      items: [
        { to: "/admin/overview", label: "Panoramica", icon: LayoutDashboard },
        { to: "/admin/classifica", label: "Classifica Live", icon: Trophy },
        { to: "/admin/teams", label: "Gestione Squadre", icon: Users },
        { to: "/admin/analytics", label: "Analisi Gara", icon: BarChart3 },
        { to: "/admin/resoconto", label: "Resoconto Gara", icon: FileText },
      ],
    },
    {
      title: "Verifiche Media",
      items: [
        { to: "/admin/photos", label: "Foto Ricevute", icon: Camera },
        { to: "/admin/posters", label: "Locandine Viventi", icon: Film },
        { to: "/admin/social", label: "Missioni Social", icon: Share2 },
      ],
    },
    {
      title: "Sfide Speciali",
      items: [
        { to: "/admin/secret-code", label: "Codice Segreto", icon: Lock },
        { to: "/admin/enigmi", label: "Enigmi", icon: Puzzle },
        { to: "/admin/cornhole", label: "Cornhole (5.1)", icon: Swords },
        { to: "/admin/boxe", label: "Boxe (5.2)", icon: Swords },
        { to: "/admin/jackpot", label: "Jackpot (5.3)", icon: Sparkles },
      ],
    },
    {
      title: "Marketplace & Malus",
      items: [
        { to: "/admin/marketplace", label: "Marketplace", icon: ShoppingBag },
        { to: "/admin/passaparola", label: "Passaparola", icon: PhoneCall, badge: pendingPassaparolaCount },
        { to: "/admin/partenze", label: "Partenze", icon: Zap },
        { to: "/admin/penalita", label: "Penalità Punti", icon: Skull },
        { to: "/admin/tassa", label: "Tassa Passaggio", icon: RefreshCw },
      ],
    },
    {
      title: "Regia & Config",
      items: [
        { to: "/admin/settings", label: "Configurazione", icon: Settings },
      ],
    },
  ];

  const teamNavItems = [
    { to: "/dashboard", label: "Squadra", icon: LayoutDashboard },
    ...(hasCompletedTappa1
      ? [
          {
            to: "/marketplace",
            label: "Marketplace",
            icon: isMarketplaceActive ? ShoppingBag : Lock,
          },
        ]
      : []),
    { to: "/classifica", label: isClassificationUnlocked ? "Classifica" : "Classifica 🔒", icon: Trophy },
    ...(isReportPublished
      ? [
          {
            to: "/resoconto",
            label: "Resoconto Finale",
            icon: FileText,
          },
        ]
      : []),
  ];

  const summaryItems = [
    { to: "/tappe", label: "Tappe", icon: Map },
    { to: "/storico", label: "Storico", icon: History },
  ];

  const mobileNavItems = isAdmin
    ? [
        { to: "/admin/overview", label: "Panoramica", icon: LayoutDashboard },
        { to: "/admin/teams", label: "Squadre", icon: Users },
        { to: "/admin/analytics", label: "Analisi", icon: BarChart3 },
      ]
    : [
        { to: "/dashboard", label: "Squadra", icon: LayoutDashboard },
        { to: "/marketplace", label: "Marketplace", icon: ShoppingBag },
      ];

  return (
    <div className="flex min-h-screen w-full">
      {/* Sidebar */}
      <Sidebar
        collapsible="icon"
        className="border-r border-white/[0.08] bg-[#0c1017] text-white shadow-2xl"
      >
        {/* ── Brand header ── */}
        <SidebarHeader className="px-3 pt-6 pb-4 safe-top group-data-[collapsible=icon]:flex group-data-[collapsible=icon]:items-center group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:px-0 group-data-[collapsible=icon]:py-4">
          <Link
            to={isAdmin ? "/admin" : "/dashboard"}
            onClick={closeMobileMenu}
            className="flex items-center gap-3 px-1 py-0.5 group-data-[collapsible=icon]:px-0 group-data-[collapsible=icon]:justify-center"
          >
            {/* Orange icon badge — always visible */}
            <span className="flex size-8 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-orange-500 to-red-600 text-white shadow-md shadow-orange-500/25">
              <Flag className="size-4" strokeWidth={2.5} />
            </span>
            {/* Wordmark — hidden when collapsed */}
            <span className="truncate text-[13px] font-display font-black tracking-[0.18em] text-white group-data-[collapsible=icon]:hidden uppercase">
              PECHINO <span className="text-orange-400">BRA</span>
            </span>
          </Link>
        </SidebarHeader>

        <SidebarContent className="px-2 py-1">
          {isAdmin ? (
            /* ── Admin categorized navigation ── */
            adminGroups.map((group, gIdx) => (
              <SidebarGroup key={group.title} className={gIdx > 0 ? "mt-3 p-0" : "p-0"}>
                {gIdx > 0 && <div className="mx-2 mb-2 h-px bg-white/[0.06]" />}
                <SidebarGroupLabel className="mb-1 px-2 py-1 text-[9px] font-black tracking-[0.2em] uppercase text-orange-400/80 group-data-[collapsible=icon]:hidden select-none">
                  {group.title}
                </SidebarGroupLabel>
                <SidebarGroupContent>
                  <SidebarMenu className="gap-0.5">
                    {group.items.map((item: any) => (
                      <SidebarMenuItem key={item.to}>
                        <SidebarMenuButton asChild tooltip={item.label}>
                          <Link
                            to={item.to}
                            onClick={closeMobileMenu}
                            activeProps={{ className: activeLinkClass }}
                            className={inactiveLinkClass}
                          >
                            <item.icon className="size-[17px] shrink-0" strokeWidth={1.8} />
                            <span className="truncate group-data-[collapsible=icon]:hidden text-xs">
                              {item.label}
                            </span>
                            {item.badge && item.badge > 0 ? (
                              <span className="ml-auto flex size-4 items-center justify-center rounded-full bg-orange-500 text-[9px] font-black text-black shrink-0 group-data-[collapsible=icon]:hidden animate-pulse">
                                {item.badge}
                              </span>
                            ) : null}
                          </Link>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    ))}
                  </SidebarMenu>
                </SidebarGroupContent>
              </SidebarGroup>
            ))
          ) : (
            <>
              {/* ── Primary nav group — teams ── */}
              <SidebarGroup className="p-0">
                <SidebarGroupLabel className="mb-1 px-2 py-1.5 text-[9px] font-bold tracking-[0.22em] uppercase text-white/35 group-data-[collapsible=icon]:hidden select-none">
                  Gara
                </SidebarGroupLabel>
                <SidebarGroupContent>
                  <SidebarMenu className="gap-0.5">
                    {teamNavItems.map((item) => (
                      <SidebarMenuItem key={item.to}>
                        <SidebarMenuButton asChild tooltip={item.label}>
                          <Link
                            to={item.to}
                            onClick={async () => {
                              closeMobileMenu();
                              if (currentPath === "/classifica" && item.to !== "/classifica" && classificationTx?.id) {
                                await (supabase as any).rpc("consume_marketplace_transaction", {
                                  p_transaction_id: classificationTx.id,
                                });
                                queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
                                queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
                              }
                            }}
                            activeProps={{ className: activeLinkClass }}
                            className={inactiveLinkClass}
                          >
                            <item.icon className="size-[17px] shrink-0" strokeWidth={1.8} />
                            <span className="truncate group-data-[collapsible=icon]:hidden">
                              {item.label}
                            </span>
                          </Link>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    ))}
                  </SidebarMenu>
                </SidebarGroupContent>
              </SidebarGroup>

              {/* ── Summary nav group — teams only ── */}
              <SidebarGroup className="mt-4 p-0">
                <div className="mx-2 mb-3 h-px bg-white/[0.07]" />
                <SidebarGroupLabel className="mb-1 px-2 py-1.5 text-[9px] font-bold tracking-[0.22em] uppercase text-white/35 group-data-[collapsible=icon]:hidden select-none">
                  Riepilogo
                </SidebarGroupLabel>
                <SidebarGroupContent>
                  <SidebarMenu className="gap-0.5">
                    {summaryItems.map((item) => (
                      <SidebarMenuItem key={item.to}>
                        <SidebarMenuButton asChild tooltip={item.label}>
                          <Link
                            to={item.to}
                            onClick={async () => {
                              closeMobileMenu();
                              if (currentPath === "/classifica" && item.to !== "/classifica" && classificationTx?.id) {
                                await (supabase as any).rpc("consume_marketplace_transaction", {
                                  p_transaction_id: classificationTx.id,
                                });
                                queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
                                queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
                              }
                            }}
                            activeProps={{ className: activeLinkClass }}
                            className={inactiveLinkClass}
                          >
                            <item.icon className="size-[17px] shrink-0" strokeWidth={1.8} />
                            <span className="truncate group-data-[collapsible=icon]:hidden">
                              {item.label}
                            </span>
                          </Link>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    ))}
                  </SidebarMenu>
                </SidebarGroupContent>
              </SidebarGroup>
            </>
          )}
        </SidebarContent>

        {/* ── Footer — Logout ── */}
        <SidebarFooter className="px-2 pb-8 pt-2 safe-bottom">
          <div className="mx-2 mb-2 h-px bg-white/[0.07]" />
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton
                onClick={() => {
                  closeMobileMenu();
                  signOut();
                }}
                tooltip="Esci"
                className="text-slate-400 hover:text-red-400 hover:bg-red-500/10 transition-all duration-200 rounded-lg py-2.5"
              >
                <LogOut className="size-[17px] shrink-0" strokeWidth={1.8} />
                <span className="text-[13px] font-semibold tracking-wide group-data-[collapsible=icon]:hidden">
                  Esci
                </span>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarFooter>
      </Sidebar>

      {/* ── Main content ── */}
      <SidebarInset className="min-w-0 w-full max-w-full flex-1 pb-24 md:pb-0 overflow-x-hidden box-border">
        <header className="sticky top-0 z-30 w-full border-b border-white/[0.06] bg-background/80 backdrop-blur-md safe-top">
          <div className="mx-auto flex w-full max-w-3xl items-center justify-between gap-2 px-3 sm:px-4 py-3 box-border">
            <div className="flex items-center gap-2 min-w-0">
              <SidebarTrigger />
              <Link
                to={isAdmin ? "/admin" : "/dashboard"}
                className="truncate text-lg sm:text-xl leading-none md:hidden font-display tracking-wide uppercase"
              >
                PECHINO EXPRESS <span className="text-primary">BRA</span>
              </Link>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                onClick={handleManualRefresh}
                onDoubleClick={handleHardRefresh}
                disabled={isRefreshing}
                className="flex items-center gap-1.5 rounded-full border border-white/10 bg-white/5 px-2.5 py-1.5 text-xs font-semibold text-slate-300 transition-all duration-200 hover:text-primary hover:border-primary/40 hover:bg-primary/10 active:scale-95 cursor-pointer disabled:opacity-50"
                aria-label="Aggiorna dati e schermata"
                title="Tocca per aggiornare i dati • Doppio tocco per ricaricare la pagina"
              >
                <RefreshCw
                  className={`size-3.5 ${isRefreshing ? "animate-spin text-primary" : ""}`}
                  strokeWidth={2}
                />
                <span className="text-[11px] font-bold uppercase tracking-wider hidden xs:inline">
                  {isRefreshing ? "Aggiorno..." : "Aggiorna"}
                </span>
              </button>

              <button
                onClick={signOut}
                className="rounded-full border border-white/10 p-2 text-slate-500 transition-all duration-200 hover:text-red-400 hover:border-red-500/30 active:scale-95 cursor-pointer"
                aria-label="Esci"
                title="Esci"
              >
                <LogOut className="size-4" strokeWidth={1.8} />
              </button>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-3xl min-w-0 px-3 sm:px-4 py-4 sm:py-5 pb-28 md:pb-12 box-border overflow-x-hidden">
          {isFrozen && !isUnluckySpinning && !showUnluckyPrize ? (
            <div className="flex flex-col items-center justify-center bg-zinc-950/40 border border-cyan-500/20 backdrop-blur-md rounded-3xl p-8 py-16 text-center space-y-6 my-10 animate-in fade-in zoom-in-95 duration-300 max-w-lg mx-auto shadow-2xl shadow-cyan-950/20">
              <div className="size-20 rounded-full bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center animate-pulse shadow-lg shadow-cyan-500/5">
                <Snowflake className="size-10 text-cyan-400 animate-spin-slow" />
              </div>
              <div className="space-y-2">
                <div className="flex flex-col items-center gap-1.5">
                  {queuedMalusesCount > 1 && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-cyan-950/80 border border-cyan-500/40 text-cyan-300 text-[10px] font-black uppercase tracking-wider animate-pulse mb-1">
                      <span>⚡ Coda Malus Attiva:</span>
                      <span className="bg-cyan-400 text-black px-1.5 py-0.2 rounded font-black">1 di {queuedMalusesCount}</span>
                      <span className="opacity-80">({queuedMalusesCount - 1} altri in attesa)</span>
                    </span>
                  )}
                  <h2 className="text-2xl font-display font-black text-cyan-400 uppercase tracking-widest drop-shadow-[0_0_15px_rgba(34,211,238,0.4)]">
                    Sei in Freeze!
                  </h2>
                </div>
                <p className="text-xs text-zinc-300 max-w-xs mx-auto leading-relaxed font-semibold">
                  La squadra <strong className="text-white font-extrabold">{attackerName}</strong> vi ha colpito con un Malus. Tutte le vostre attività sono temporaneamente bloccate.
                </p>
              </div>

              <div className="text-5xl font-black font-mono text-cyan-400 tracking-widest bg-zinc-950/80 px-8 py-5 rounded-2xl border border-cyan-500/20 shadow-inner drop-shadow-[0_0_12px_rgba(34,211,238,0.25)]">
                {formatTime(secondsLeft)}
              </div>

              <p className="text-[10px] text-zinc-500 uppercase tracking-wider font-extrabold">
                Le azioni di gara riprenderanno automaticamente alla scadenza del timer
              </p>
            </div>
          ) : activeEnigmaTx && !isUnluckySpinning && !showUnluckyPrize ? (
            <div className="flex flex-col items-center justify-center bg-zinc-950/40 border border-purple-500/20 backdrop-blur-md rounded-3xl p-6 sm:p-8 py-12 text-center space-y-6 my-10 animate-in fade-in zoom-in-95 duration-300 max-w-lg mx-auto shadow-2xl shadow-purple-950/20">
              <div className="size-20 rounded-full bg-purple-500/10 border border-purple-500/30 flex items-center justify-center animate-pulse shadow-lg shadow-purple-500/5">
                <Puzzle className="size-10 text-purple-400" />
              </div>
              
              <div className="space-y-2">
                <div className="flex flex-col items-center gap-1.5">
                  {queuedMalusesCount > 1 && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-950/80 border border-purple-500/40 text-purple-300 text-[10px] font-black uppercase tracking-wider animate-pulse mb-1">
                      <span>⚡ Coda Malus Attiva:</span>
                      <span className="bg-purple-400 text-black px-1.5 py-0.2 rounded font-black">1 di {queuedMalusesCount}</span>
                      <span className="opacity-80">({queuedMalusesCount - 1} altri in attesa)</span>
                    </span>
                  )}
                  <h2 className="text-2xl font-display font-black text-purple-400 uppercase tracking-widest drop-shadow-[0_0_15px_rgba(192,132,252,0.4)]">
                    Enigma Extra!
                  </h2>
                </div>
                <p className="text-xs text-zinc-300 max-w-xs mx-auto leading-relaxed font-semibold">
                  La squadra <strong className="text-white font-extrabold">{attackerName}</strong> vi ha assegnato un enigma extra. Risolvilo per poter sbloccare la squadra e continuare la gara.
                </p>
              </div>

              <div className="bg-zinc-950/80 p-5 rounded-2xl border border-purple-500/10 text-left space-y-4 max-w-md w-full shadow-inner">
                <h4 className="text-[11px] uppercase tracking-wider text-purple-400 font-extrabold border-b border-purple-500/10 pb-1.5 flex items-center gap-1.5">
                  🧩 Il Codice del Viaggiatore (Difficoltà: 7/10)
                </h4>
                
                <div className="text-xs text-zinc-300 font-medium leading-relaxed space-y-3">
                  <p className="font-semibold text-zinc-400 italic">
                    "Un viaggiatore ha lasciato questo messaggio:"
                  </p>
                  <div className="bg-zinc-900/60 py-2.5 text-center rounded-lg border border-zinc-800 text-lg font-black tracking-widest font-mono text-white select-all">
                    ODQWHUQD
                  </div>
                  <p className="font-semibold text-zinc-400 italic">
                    "Dice che la parola è stata scritta seguendo una semplice regola. Ha lasciato anche questi tre indizi:"
                  </p>
                  <ul className="list-decimal list-inside space-y-1 font-semibold text-[11px] text-zinc-300 bg-zinc-900/20 p-2.5 rounded-lg border border-zinc-800/40">
                    <li>Non devi riordinare le lettere.</li>
                    <li>Devi guardare ciò che viene subito dopo.</li>
                    <li>La chiave è nascosta nel numero dei lati di un triangolo.</li>
                  </ul>
                  <p className="text-center font-bold text-white pt-1 text-[11px] uppercase tracking-wider text-purple-300">
                    Qual è la parola nascosta?
                  </p>
                </div>
              </div>

              <form onSubmit={handleSubmitEnigmaExtra} className="space-y-3 w-full max-w-md">
                <div className="space-y-1">
                  <input
                    type="text"
                    value={enigmaAnswer}
                    onChange={(e) => {
                      setEnigmaAnswer(e.target.value);
                      setEnigmaError("");
                    }}
                    placeholder="Inserisci la soluzione..."
                    className="w-full bg-zinc-950 border border-zinc-800 focus:border-purple-500 text-white rounded-xl py-3 px-4 text-center font-mono font-black uppercase tracking-widest focus:ring-1 focus:ring-purple-500/30 transition-all text-sm outline-none"
                    disabled={isSubmittingEnigma}
                  />
                  {enigmaError && (
                    <p className={`text-[11px] font-bold ${enigmaError.startsWith("✅") ? "text-emerald-400" : "text-red-400"}`}>
                      {enigmaError}
                    </p>
                  )}
                </div>
                
                <button
                  type="submit"
                  disabled={isSubmittingEnigma || !enigmaAnswer.trim()}
                  className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-700 disabled:from-zinc-900 disabled:to-zinc-900 disabled:text-zinc-500 text-white font-extrabold text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-1.5"
                >
                  {isSubmittingEnigma ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    "Verifica Soluzione"
                  )}
                </button>
              </form>
            </div>
          ) : (pendingUnluckyWheelTx || isUnluckySpinning || showUnluckyPrize) ? (
            <div className="flex flex-col items-center justify-center bg-zinc-950/40 border border-amber-500/20 backdrop-blur-md rounded-3xl p-6 sm:p-8 py-12 text-center space-y-6 my-10 animate-in fade-in zoom-in-95 duration-300 max-w-lg mx-auto shadow-2xl shadow-amber-950/20">
              <div className="size-20 rounded-full bg-amber-500/10 border border-amber-500/30 flex items-center justify-center animate-pulse shadow-lg shadow-amber-500/5">
                <ShieldAlert className="size-10 text-amber-400" />
              </div>
              
              <div className="space-y-2">
                <h2 className="text-2xl font-display font-black text-amber-400 uppercase tracking-widest drop-shadow-[0_0_15px_rgba(245,158,11,0.4)] animate-pulse">
                  Ruota Sfortunata!
                </h2>
                <p className="text-xs text-zinc-300 max-w-xs mx-auto leading-relaxed font-semibold">
                  La squadra <strong className="text-white font-extrabold">{attackerName}</strong> vi ha lanciato un Malus! Gira la ruota sfortunata per conoscere la tua penalità.
                </p>
              </div>

              {!showUnluckyPrize ? (
                <>
                  <div className="text-center space-y-1">
                    <p className="text-[10px] uppercase font-bold text-amber-500/80 tracking-wider">
                      La decisione è definitiva
                    </p>
                    <p className="text-[9px] text-zinc-500 leading-normal px-6">
                      La ruota non potrà essere girata una seconda volta. L'effetto verrà applicato immediatamente.
                    </p>
                  </div>

                  {/* SVG Wheel */}
                  <div className="relative w-[280px] h-[280px] sm:w-[320px] sm:h-[320px] shrink-0 my-2">
                    <svg
                      viewBox="0 0 400 400"
                      className="w-full h-full select-none"
                      style={{
                        transform: `rotate(${unluckyRotation}deg)`,
                        transition: isUnluckySpinning ? "transform 5000ms cubic-bezier(0.2, 0.8, 0.2, 1)" : "none",
                      }}
                    >
                      <circle cx="200" cy="200" r="192" fill="#09090b" stroke="#27272a" strokeWidth="8" />
                      <circle cx="200" cy="200" r="186" fill="none" stroke="#f59e0b" strokeWidth="2.5" opacity="0.4" />

                      {UNLUCKY_WHEEL_SLICES.map((slice, i) => {
                        const startAngle = i * 60;
                        const endAngle = (i + 1) * 60;
                        const midAngle = startAngle + 30;
                        return (
                          <g key={slice.id}>
                            <path
                              d={describeArc(200, 200, 180, startAngle, endAngle)}
                              fill={slice.color}
                              stroke="#09090b"
                              strokeWidth="2.5"
                            />
                            <g transform={`rotate(${midAngle} 200 200)`}>
                              {/* Large Emoji */}
                              <text
                                x="200"
                                y="65"
                                textAnchor="middle"
                                dominantBaseline="central"
                                fontSize="26"
                                transform="rotate(90 200 65)"
                              >
                                {slice.emoji}
                              </text>
                              {/* Crisp Bold Label */}
                              <text
                                x="200"
                                y="122"
                                textAnchor="middle"
                                dominantBaseline="central"
                                fill={slice.text}
                                fontSize="13.5"
                                fontWeight="900"
                                letterSpacing="0.4"
                                transform="rotate(90 200 122)"
                              >
                                {slice.label}
                              </text>
                            </g>
                          </g>
                        );
                      })}

                      {/* Inner pin */}
                      <circle cx="200" cy="200" r="26" fill="#09090b" stroke="#f59e0b" strokeWidth="3.5" />
                      <circle cx="200" cy="200" r="10" fill="#f59e0b" />
                    </svg>

                    {/* Pointer */}
                    <div className="absolute top-[-8px] left-[50%] translate-x-[-50%] z-10 w-0 h-0 border-l-[14px] border-l-transparent border-r-[14px] border-r-transparent border-t-[22px] border-t-amber-400 drop-shadow-[0_4px_6px_rgba(0,0,0,0.8)]" />
                  </div>

                  <button
                    onClick={handleSpinUnluckyWheel}
                    disabled={isUnluckySpinning}
                    className="w-full max-w-xs py-3 rounded-xl bg-gradient-to-r from-amber-600 to-red-600 hover:from-amber-500 hover:to-red-500 text-white font-extrabold text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-1.5"
                  >
                    {isUnluckySpinning ? (
                      <>
                        <Loader2 className="size-4 animate-spin" />
                        GIRANDO...
                      </>
                    ) : (
                      <>
                        <HelpCircle className="size-4" />
                        GIRA LA RUOTA
                      </>
                    )}
                  </button>
                </>
              ) : (
                /* Prize Outcome display */
                <div className="w-full text-center space-y-6 animate-in zoom-in-95 duration-300">
                  <div className="text-5xl animate-bounce">⚡</div>
                  <div className="space-y-2">
                    <span className="text-[10px] uppercase font-extrabold tracking-widest text-red-400 font-mono">
                      PENALITÀ ESTRATTA:
                    </span>
                    <h4 className="text-xl font-display font-black text-white uppercase tracking-wider text-amber-400">
                      {unluckyOutcome?.label || "Esito applicato"}
                    </h4>
                    <p className="text-xs text-zinc-400 max-w-xs mx-auto leading-relaxed font-medium">
                      {unluckyOutcome?.id === "freeze_2min" && "L'account della tua squadra è stato congelato per 120 secondi. Non potrai compiere alcuna azione."}
                      {unluckyOutcome?.id === "minus_20_points" && "20 punti sono stati immediatamente sottratti dal vostro punteggio globale."}
                      {unluckyOutcome?.id === "minus_10_tokens" && "10 Token sono stati detratti dal vostro saldo di squadra."}
                      {unluckyOutcome?.id === "plus_2_min" && "Una penalità temporale di +2 minuti è stata applicata al vostro tempo ufficiale."}
                      {unluckyOutcome?.id === "heavy_backpack" && "Zaino Pesante! +3 minuti di penalità sono stati aggiunti al vostro tempo ufficiale."}
                      {unluckyOutcome?.id === "minus_10_points_minus_5_tokens" && "10 punti e 5 Token sono stati sottratti dal vostro punteggio e dal saldo."}
                    </p>
                  </div>
                  
                  <button
                    onClick={handleDismissUnluckyWheel}
                    className="w-full max-w-xs py-3 rounded-xl bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-white font-extrabold text-xs uppercase tracking-wider shadow-md transition-all active:scale-[0.98]"
                  >
                    Accetta Destino
                  </button>
                </div>
              )}
            </div>
          ) : (
            <>
              <AdminDecisionModal isAdmin={isAdmin} />
              {children}
            </>
          )}
        </main>
      </SidebarInset>

      {/* ── Mobile bottom nav ── */}
      <nav className="fixed inset-x-0 bottom-0 z-40 w-full border-t border-border/40 bg-background/90 backdrop-blur-2xl md:hidden shadow-2xl shadow-black/80 safe-bottom">
        <div className="mx-auto flex w-full max-w-3xl items-center justify-around px-2 py-2 min-h-16 box-border">
          {mobileNavItems.map((item) => (
            <NavItem
              key={item.to}
              to={item.to}
              onClick={async () => {
                if (currentPath === "/classifica" && item.to !== "/classifica" && classificationTx?.id) {
                  await (supabase as any).rpc("consume_marketplace_transaction", {
                    p_transaction_id: classificationTx.id,
                  });
                  queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
                  queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
                }
              }}
              icon={
                <item.icon
                  className="size-5 transition-transform"
                  strokeWidth={2}
                />
              }
              label={item.label}
            />
          ))}
          <button
            onClick={async () => {
              if (currentPath === "/classifica" && classificationTx?.id) {
                await (supabase as any).rpc("consume_marketplace_transaction", {
                  p_transaction_id: classificationTx.id,
                });
                queryClient.invalidateQueries({ queryKey: ["team-classification-bonus"] });
                queryClient.invalidateQueries({ queryKey: ["team-classification-bonus-detail"] });
                navigate({ to: "/dashboard" });
              }
              toggleSidebar();
            }}
            className="flex flex-1 flex-col items-center justify-center gap-1 py-1 text-[11px] font-semibold text-muted-foreground transition-all hover:text-primary active:scale-95 cursor-pointer min-w-0"
            aria-label="Apri menu"
          >
            <Menu className="size-5" strokeWidth={2} />
            <span className="tracking-tight truncate max-w-full text-center px-0.5">Menu</span>
          </button>
        </div>
      </nav>
    </div>
  );
}

function NavItem({
  to,
  icon,
  label,
  onClick,
}: {
  to: string;
  icon: ReactNode;
  label: string;
  onClick?: () => void;
}) {
  return (
    <Link
      to={to}
      onClick={(e) => {
        triggerHaptic("light");
        if (onClick) onClick();
      }}
      activeProps={{ className: "text-primary scale-105 font-bold drop-shadow-[0_0_8px_rgba(249,115,22,0.4)]" }}
      inactiveProps={{ className: "text-muted-foreground font-medium hover:text-foreground" }}
      className="flex flex-1 flex-col items-center justify-center gap-1 py-1 text-[11px] transition-all touch-active min-w-0"
    >
      {icon}
      <span className="tracking-tight truncate max-w-full text-center px-0.5">{label}</span>
    </Link>
  );
}
