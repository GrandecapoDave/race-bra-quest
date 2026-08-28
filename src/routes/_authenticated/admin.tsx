import { useEffect, useState, useRef, createContext, useContext } from "react";
import { createFileRoute, Outlet, Link, useLocation } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  ShieldAlert,
  Clock,
  MapPin,
  CheckCircle,
  XCircle,
  Loader2,
  Film,
  Camera,
  ShoppingBag,
  Sparkles,
  FlipHorizontal,
  RotateCw,
} from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { challengesQuery, leaderboardQuery, stagesQuery, formatDuration } from "@/lib/race";

export const AdminContext = createContext<any>(null);
export const useAdminContext = () => useContext(AdminContext);

export const Route = createFileRoute("/_authenticated/admin")({
  head: () => ({
    meta: [
      { title: "Regia gara — Pechino Express Bra" },
      { name: "description", content: "Pannello di controllo per la regia di Pechino Express Bra." },
      { property: "og:title", content: "Regia gara — Pechino Express Bra" },
    ],
  }),
  component: AdminLayout,
});


function AdminLayout() {
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const queryClient = useQueryClient();
  
  const stages = useQuery(stagesQuery);
  const challenges = useQuery(challengesQuery);
  const board = useQuery({ ...leaderboardQuery, refetchInterval: 3000 });

  // Share selected team ID across pages if needed (e.g. for overview to timeline transition)
  const [selectedTeamId, setSelectedTeamId] = useState<string | null>(null);

  // Fetch all marketplace transactions
  const marketplaceTransactions = useQuery({
    queryKey: ["admin-marketplace-transactions"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("*,costo:costo_token,timestamp:data_acquisto,buyer_team_id:team_id,item_id:marketplace_item_id,outcome:dettagli")
        .order("data_acquisto", { ascending: false });
      if (error) {
        console.warn("Error marketplaceTransactions:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch game settings
  const gameSettings = useQuery({
    queryKey: ["game-settings"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("game_settings")
        .select("*")
        .single();
      if (error) {
        console.warn("Error gameSettings:", error);
        return { id: "settings_01", marketplace_visible: false, marketplace_active: false, activated_at: null, activated_by: null };
      }
      return data || { id: "settings_01", marketplace_visible: false, marketplace_active: false, activated_at: null, activated_by: null };
    }
  });

  // Fetch all teams with password details
  const allTeams = useQuery({
    queryKey: ["admin-teams-list"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("teams")
        .select("*")
        .order("created_at", { ascending: false });
      if (error) {
        console.warn("Error allTeams:", error);
        return [];
      }
      return data || [];
    },
  });

  // Fetch all submissions
  const allSubmissions = useQuery({
    queryKey: ["admin-submissions-all"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("submissions")
        .select(`
          id,
          risposta:note,
          file_upload:url,
          timestamp:created_at,
          stato_approvazione,
          latitude,
          longitude,
          challenge_id,
          team_id,
          teams ( id, nome_squadra, avatar_url, colore ),
          challenges ( id, titolo, punteggio_massimo, tipo_sfida, stage_id, stages ( id, titolo, numero_tappa ) )
        `)
        .order("created_at", { ascending: false });
      if (error) {
        console.warn("Error allSubmissions:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch team progress rows for detailed view
  const allProgress = useQuery({
    queryKey: ["admin-progress-all"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("team_progress")
        .select("*");
      if (error) {
        console.warn("Error allProgress:", error);
        return [];
      }
      return data || [];
    },
  });

  // Fetch all cattiveria ledger entries
  const allCattiveria = useQuery({
    queryKey: ["admin-cattiveria-all"],
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("cattiveria_ledger")
        .select("*")
        .order("timestamp", { ascending: false });
      if (error) {
        console.warn("Error allCattiveria:", error);
        return [];
      }
      return data || [];
    },
  });

  // Fetch all scores
  const allScores = useQuery({
    queryKey: ["admin-scores-all"],
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("scores")
        .select("*")
        .order("created_at", { ascending: false });
      if (error) {
        console.warn("Error allScores:", error);
        return [];
      }
      return data || [];
    },
  });

  // Fetch bank state for selected team
  const selectedTeamBankState = useQuery({
    queryKey: ["admin-bank-state", selectedTeamId],
    enabled: Boolean(selectedTeamId),
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_bank_state", {
        p_team_id: selectedTeamId,
      });
      if (error) {
        console.warn("Error selectedTeamBankState:", error);
        return null;
      }
      return data as {
        progress: any;
        answers: Array<{ question_number: number; answer: string; extracted_letter: string }>;
        all_questions: Array<{ question_number: number; question_text: string; length: number }>;
      };
    },
  });

  // Fetch all social challenge submissions
  const allSocialSubmissions = useQuery({
    queryKey: ["admin-social-submissions-all"],
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("team_social_submissions")
        .select("*");
      if (error) {
        console.warn("Error allSocialSubmissions:", error);
        return [];
      }
      return (data || []) as any[];
    }
  });

  // Fetch secret code challenge dashboard
  const secretCodeDashboard = useQuery({
    queryKey: ["admin-secret-code-dashboard"],
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase.rpc("admin_get_secret_code_dashboard");
      if (error) throw new Error(error.message);
      return data as {
        full_code: string;
        destination: string;
        parts: Array<{ id: string; team_id: string; code_part: string; part_type: "FIRST_5" | "LAST_5"; assigned_at: string }>;
        matches: Array<{ buyer_team_id: string; seller_team_id: string; required_part: "FIRST_5" | "LAST_5"; token_cost: number; created_at: string }>;
        transactions: Array<{ id: string; buyer_team_id: string; seller_team_id: string; token_cost: number; digits_received: string; timestamp: string }>;
        attempts: Array<{ id: string; team_id: string; inserted_code: string; timestamp: string; success: boolean }>;
        completed_teams: Array<{ team_id: string; nome_squadra: string; completed_at: string }>;
      };
    }
  });

  // Fetch all quiz answers
  const allAnswers = useQuery({
    queryKey: ["admin-answers-all"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("team_answers")
        .select("*");
      if (error) {
        console.warn("Error allAnswers:", error);
        return [];
      }
      return data || [];
    },
  });

  // Fetch all quiz questions
  const quizQuestions = useQuery({
    queryKey: ["admin-quiz-questions-all"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("quiz_questions")
        .select("*");
      if (error) {
        console.warn("Error quizQuestions:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch activity log
  const activityLog = useQuery({
    queryKey: ["admin-activity-log"],
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("activity_log")
        .select("*,timestamp:created_at")
        .order("created_at", { ascending: false });
      if (error) {
        console.warn("Error activityLog:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch settings
  const settings = useQuery({
    queryKey: ["admin-settings"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("settings")
        .select("*");
      if (error) {
        console.warn("Error settings:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch all emoji movies answers
  const allEmojiMovies = useQuery({
    queryKey: ["admin-emoji-movies-all"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("team_emoji_movies")
        .select("*");
      if (error) {
        console.warn("Error allEmojiMovies:", error);
        return [];
      }
      return (data || []) as any[];
    },
  });

  // Fetch all posters
  const allPosters = useQuery({
    queryKey: ["admin-posters-all"],
    queryFn: async () => {
      const { data, error } = await supabase.from("posters").select("*");
      if (error) {
        console.warn("Error allPosters:", error);
        return [];
      }
      return (data || []) as any[];
    }
  });

  // Fetch all team posters
  const allTeamPosters = useQuery({
    queryKey: ["admin-team-posters-all"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase.from("team_posters").select("*");
      if (error) {
        console.warn("Error allTeamPosters:", error);
        return [];
      }
      return (data || []) as any[];
    }
  });

  // Chronometer for elapsed race time (active / frozen when terminated / 00:00:00 when not started)
  const [raceTime, setRaceTime] = useState("00:00:00");
  useEffect(() => {
    const updateTime = () => {
      const startedAtSetting = (settings.data ?? []).find(s => s.id === "game_started_at");
      const statusSetting = (settings.data ?? []).find(s => s.id === "game_status");
      const endedAtSetting = (settings.data ?? []).find(s => s.id === "game_ended_at");

      const status = statusSetting?.value || "Gara non iniziata";

      // 1. NON INIZIATA: timer always 00:00:00
      if (!startedAtSetting?.value || status === "Gara non iniziata") {
        setRaceTime("00:00:00");
        return;
      }

      const startMs = new Date(startedAtSetting.value).getTime();
      if (isNaN(startMs) || startMs <= 0) {
        setRaceTime("00:00:00");
        return;
      }

      // 2. GARA TERMINATA: timer FROZEN at (endedAt - startedAt)
      let endMs = Date.now();
      if (status === "Gara terminata") {
        if (endedAtSetting?.value) {
          const parsedEndMs = new Date(endedAtSetting.value).getTime();
          if (!isNaN(parsedEndMs) && parsedEndMs > 0) {
            endMs = parsedEndMs;
          } else if (statusSetting?.updated_at) {
            endMs = new Date(statusSetting.updated_at).getTime();
          }
        } else if (statusSetting?.updated_at) {
          endMs = new Date(statusSetting.updated_at).getTime();
        }
      }

      // 3. Compute formatted elapsed time
      const diffMs = Math.max(0, endMs - startMs);
      const totalSecs = Math.floor(diffMs / 1000);
      const hours = String(Math.floor(totalSecs / 3600)).padStart(2, "0");
      const minutes = String(Math.floor((totalSecs % 3600) / 60)).padStart(2, "0");
      const seconds = String(totalSecs % 60).padStart(2, "0");
      setRaceTime(`${hours}:${minutes}:${seconds}`);
    };

    updateTime();

    const statusSetting = (settings.data ?? []).find(s => s.id === "game_status");
    // Only tick actively if the race is active
    if (statusSetting?.value === "Gara attiva") {
      const interval = setInterval(updateTime, 1000);
      return () => clearInterval(interval);
    }
    return undefined;
  }, [settings.data]);

  // Global actions and operation states
  const [isConfirmingScore, setIsConfirmingScore] = useState<Record<string, boolean>>({});
  const [isEvaluating, setIsEvaluating] = useState<Record<string, boolean>>({});
  const [isEvaluatingSocial, setIsEvaluatingSocial] = useState<Record<string, boolean>>({});
  const [isForcingCode, setIsForcingCode] = useState<Record<string, boolean>>({});
  const [isUpdatingCodeSettings, setIsUpdatingCodeSettings] = useState(false);
  const [isTogglingMarketplace, setIsTogglingMarketplace] = useState(false);
  const [isProcessingBank, setIsProcessingBank] = useState(false);

  if (isAdmin.isLoading) return <AppShell isAdmin><div className="flex justify-center items-center h-64"><Loader2 className="animate-spin text-primary size-8" /></div></AppShell>;

  if (!isAdmin.data) {
    return (
      <AppShell>
        <div className="surface flex items-center gap-3 p-6 max-w-md mx-auto mt-12">
          <ShieldAlert className="size-6 text-destructive shrink-0" />
          <div>
            <p className="font-bold">Area riservata alla regia</p>
            <p className="text-sm text-muted-foreground">
              Il tuo account non ha il ruolo admin.
            </p>
          </div>
        </div>
      </AppShell>
    );
  }

  // UPDATE GAME STATUS
  async function handleUpdateGameStatus(status: string) {
    const nowIso = new Date().toISOString();
    const updates: { id: string; value: string; updated_at: string }[] = [
      { id: "game_status", value: status, updated_at: nowIso }
    ];

    if (status === "Gara attiva") {
      const startedAtSetting = (settings.data ?? []).find(s => s.id === "game_started_at");
      const currentStatus = (settings.data ?? []).find(s => s.id === "game_status")?.value;
      if (!startedAtSetting?.value || currentStatus === "Gara non iniziata") {
        updates.push({ id: "game_started_at", value: nowIso, updated_at: nowIso });
      }
      updates.push({ id: "game_ended_at", value: "", updated_at: nowIso });
    } else if (status === "Gara terminata") {
      updates.push({ id: "game_ended_at", value: nowIso, updated_at: nowIso });
    } else if (status === "Gara non iniziata") {
      updates.push({ id: "game_started_at", value: "", updated_at: nowIso });
      updates.push({ id: "game_ended_at", value: "", updated_at: nowIso });
    }

    const { error } = await (supabase as any)
      .from("settings")
      .upsert(updates, { onConflict: "id" });

    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success(`Stato gara aggiornato: ${status}`);
    queryClient.invalidateQueries();
  }

  // EVALUATE POSTER
  async function handleEvaluatePoster(submissionId: string, voto: number) {
    setIsEvaluating(prev => ({ ...prev, [submissionId]: true }));
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";

      const { error } = await (supabase as any).rpc("evaluate_poster", {
        p_submission_id: submissionId,
        p_voto: voto,
        p_admin_id: adminId
      });
      if (error) {
        toast.error(error.message);
        return;
      }
      toast.success("Valutazione salvata con successo!");
      queryClient.invalidateQueries();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsEvaluating(prev => ({ ...prev, [submissionId]: false }));
    }
  }

  // CONFIRM PHOTO SCORE
  async function handleConfirmPhotoScore(submissionId: string, points: number) {
    setIsConfirmingScore(prev => ({ ...prev, [submissionId]: true }));
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";

      const { error } = await (supabase as any).rpc("confirm_photo_score", {
        p_submission_id: submissionId,
        p_points: points,
        p_admin_id: adminId
      });
      if (error) {
        toast.error(error.message);
        return;
      }
      toast.success("Punteggio confermato con successo!");
      queryClient.invalidateQueries();
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsConfirmingScore(prev => ({ ...prev, [submissionId]: false }));
    }
  }

  // TOGGLE MARKETPLACE
  async function handleToggleMarketplace(active: boolean) {
    setIsTogglingMarketplace(true);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await (supabase as any).rpc("toggle_marketplace", {
        p_active: active,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore durante il cambio di stato del Marketplace: " + error.message);
        return;
      }
      toast.success(`Marketplace ${active ? "attivato" : "disattivato"} con successo!`);
      queryClient.invalidateQueries();
    } catch (e: any) {
      toast.error("Errore: " + e.message);
    } finally {
      setIsTogglingMarketplace(false);
    }
  }

  // BANK ADMIN CONTROLS
  async function handleForceCompleteBank(teamId: string) {
    if (!confirm("Sei sicuro di voler forzare il completamento de La Banca per questa squadra?")) return;
    setIsProcessingBank(true);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await supabase.rpc("admin_force_complete_bank", {
        p_team_id: teamId,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Sfida completata con successo!");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsProcessingBank(false);
    }
  }

  async function handleResetBank(teamId: string) {
    if (!confirm("Sei sicuro di voler resettare completamente la sfida La Banca per questa squadra?")) return;
    setIsProcessingBank(true);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await supabase.rpc("admin_reset_bank", {
        p_team_id: teamId,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Sfida resettata con successo!");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsProcessingBank(false);
    }
  }

  async function handleEditBankAnswer(teamId: string, qNum: number, correct: boolean) {
    setIsProcessingBank(true);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await supabase.rpc("admin_edit_bank_answer", {
        p_team_id: teamId,
        p_question_number: qNum,
        p_correct: correct,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Risposta aggiornata!");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsProcessingBank(false);
    }
  }

  // SOCIAL CHALLENGE ADMIN EVALUATION
  async function handleEvaluateSocial(submissionId: string, voto: number) {
    setIsEvaluatingSocial(prev => ({ ...prev, [submissionId]: true }));
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";

      const { error } = await supabase.rpc("evaluate_social_challenge", {
        p_submission_id: submissionId,
        p_voto: voto,
        p_admin_id: adminId
      });

      if (error) {
        toast.error("Errore durante la valutazione: " + error.message);
      } else {
        toast.success(`Missione Social valutata: ${voto}/20 PT assegnati!`);
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message || "Errore imprevisto");
    } finally {
      setIsEvaluatingSocial(prev => ({ ...prev, [submissionId]: false }));
    }
  }

  // SECRET CODE CHALLENGE ADMIN HANDLERS
  async function handleForceCompleteCode(teamId: string) {
    setIsForcingCode(prev => ({ ...prev, [teamId]: true }));
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await supabase.rpc("admin_force_complete_secret_code", {
        p_team_id: teamId,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Sfida Codice completata forzatamente!");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsForcingCode(prev => ({ ...prev, [teamId]: false }));
    }
  }

  async function handleEditCodeMatch(buyerId: string, sellerId: string, partType: "FIRST_5" | "LAST_5", tokenCost: number) {
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await supabase.rpc("admin_edit_secret_code_match", {
        p_buyer_team_id: buyerId,
        p_seller_team_id: sellerId,
        p_assigned_part_type: partType,
        p_token_cost: tokenCost,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Configurazione agganciata!");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message);
    }
  }

  async function handleUpdateCodeSettings(fullCode: string, destination: string) {
    if (fullCode.length !== 10) {
      toast.error("Il codice PIN deve essere lungo esattamente 10 cifre");
      return;
    }
    setIsUpdatingCodeSettings(true);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const adminId = userData.user?.id || "11111111-1111-1111-1111-111111111111";
      const { error } = await supabase.rpc("admin_edit_secret_code_settings", {
        p_full_code: fullCode,
        p_destination: destination,
        p_admin_id: adminId
      });
      if (error) {
        toast.error("Errore: " + error.message);
      } else {
        toast.success("Impostazioni globali aggiornate!");
        queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setIsUpdatingCodeSettings(false);
    }
  }

  // Photos are now auto-approved — only count truly pending non-photo submissions
  const pendingApprovals = (allSubmissions.data ?? []).filter(
    (s) => s.stato_approvazione === "pending" && s.risposta !== "photo"
  );

  const statusSetting = (settings.data ?? []).find(s => s.id === "game_status");
  const gameStatus = statusSetting?.value || "Gara attiva";

  const totalTeamsCount = allTeams.data?.length ?? 0;
  const activeTeamsCount = allTeams.data?.filter((t: any) => t.active).length ?? 0;
  const pendingApprovalsCount = pendingApprovals.length;

  // Gather monitor rows in real-time
  const monitorRows = (allTeams.data ?? []).map((t: any) => {
    const teamProgress = (allProgress.data ?? []).filter((p: any) => p.team_id === t.id);
    const completedCount = teamProgress.filter((p: any) => p.stato === "completed" && p.challenge_id !== "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0").length;
    const pendingCount = teamProgress.filter((p: any) => p.stato === "pending_approval").length;
    
    // Determine current stage
    let currentStageName = "Gara non iniziata";
    const completedStages = ((stages.data ?? []) as any[])
      .filter((s: any) => {
        const stageChallenges = (challenges.data ?? []).filter((c: any) => c.stage_id === s.id);
        return stageChallenges.length > 0 && stageChallenges.every((c: any) =>
          teamProgress.some((p: any) => p.challenge_id === c.id && p.stato === "completed")
        );
      });
    
    if (completedStages.length > 0) {
      const sortedCompleted = [...completedStages].sort((a: any, b: any) => b.ordine - a.ordine);
      const nextStage = ((stages.data ?? []) as any[]).find((s: any) => s.ordine === sortedCompleted[0].ordine + 1);
      currentStageName = nextStage ? nextStage.nome_tappa : "Terminato";
    } else if (teamProgress.length > 0) {
      const firstStage = ((stages.data ?? []) as any[]).find((s: any) => s.ordine === 1);
      if (firstStage) currentStageName = firstStage.nome_tappa;
    }

    // Determine last action
    const teamLogs = (activityLog.data ?? []).filter((l: any) => l.team_id === t.id);
    const lastActionText = teamLogs[0]?.action || "Nessuna azione";
    const lastActionTime = teamLogs[0] ? new Date(teamLogs[0].timestamp).toLocaleTimeString("it-IT") : "—";

    // Determine scores and duration
    const teamScores = (allScores.data ?? []).filter((s: any) => s.team_id === t.id);
    const challengesPoints = teamScores.filter((s: any) => s.challenge_id !== null).reduce((sum: number, s: any) => sum + s.punti, 0);
    const modifierPoints = teamScores.filter((s: any) => s.challenge_id === null).reduce((sum: number, s: any) => sum + s.punti, 0);
    const cattiveriaPoints = (allCattiveria.data ?? []).filter((l: any) => l.team_id === t.id).reduce((sum: number, l: any) => sum + l.punti, 0);
    const points = challengesPoints + modifierPoints + cattiveriaPoints;

    // Duration
    let totalDurationSeconds = 0;
    const completions = teamProgress
      .filter((tp: any) => tp.stato === "completed" && tp.completata_at)
      .map((tp: any) => new Date(tp.completata_at).getTime());
    const starts = teamProgress
      .filter((tp: any) => tp.started_at)
      .map((tp: any) => new Date(tp.started_at).getTime());

    if (completions.length > 0 && starts.length > 0) {
      const maxCompletion = Math.max(...completions);
      const minStart = Math.min(...starts);
      totalDurationSeconds = Math.round((maxCompletion - minStart) / 1000);
    }

    // Status: Active, Pending approval, Blocked/Inactive
    let statusLabel = "🟢 Attiva";
    let statusColor = "text-success bg-success/10 border-success/20";
    if (!t.active) {
      statusLabel = "🔴 Disattivata";
      statusColor = "text-destructive bg-destructive/10 border-destructive/20";
    } else if (pendingCount > 0) {
      statusLabel = "🟡 In Attesa";
      statusColor = "text-warning bg-warning/10 border-warning/20";
    }

    return {
      ...t,
      statusLabel,
      statusColor,
      currentStageName,
      lastActionText,
      lastActionTime,
      challengesPoints,
      modifierPoints,
      cattiveriaPoints,
      points,
      totalDurationSeconds,
      completedCount
    };
  });

  const sortedLeaderboard = [...monitorRows].sort((a: any, b: any) => {
    if (b.completedCount !== a.completedCount) {
      return b.completedCount - a.completedCount;
    }
    if (b.points !== a.points) {
      return b.points - a.points;
    }
    return a.totalDurationSeconds - b.totalDurationSeconds;
  });

  const location = useLocation();
  const currentPath = location.pathname;

  const adminNavCategories = [
    {
      name: "Monitoraggio",
      links: [
        { to: "/admin/overview", label: "Panoramica" },
        { to: "/admin/classifica", label: "Classifica" },
        { to: "/admin/teams", label: "Squadre" },
        { to: "/admin/analytics", label: "Analisi" },
        { to: "/admin/resoconto", label: "Resoconto" },
      ],
    },
    {
      name: "Verifiche Media",
      links: [
        { to: "/admin/photos", label: "Foto", badge: pendingApprovalsCount },
        { to: "/admin/posters", label: "Locandine" },
        { to: "/admin/social", label: "Social" },
      ],
    },
    {
      name: "Sfide Speciali",
      links: [
        { to: "/admin/secret-code", label: "Codice" },
        { to: "/admin/enigmi", label: "Enigmi" },
        { to: "/admin/cornhole", label: "Cornhole" },
        { to: "/admin/boxe", label: "Boxe" },
        { to: "/admin/jackpot", label: "Jackpot" },
      ],
    },
    {
      name: "Marketplace & Malus",
      links: [
        { to: "/admin/marketplace", label: "Mercato" },
        { to: "/admin/passaparola", label: "Passaparola" },
        { to: "/admin/partenze", label: "Partenze" },
        { to: "/admin/penalita", label: "Penalità" },
        { to: "/admin/tassa", label: "Tassa" },
      ],
    },
    {
      name: "Regia",
      links: [
        { to: "/admin/settings", label: "Configurazione" },
      ],
    },
  ];

  return (
    <AppShell isAdmin>
      <div className="space-y-4 md:space-y-6">
        {/* HEADER SUPERIORE - STATO GARA (HUD Compatto & Mobile-Friendly) */}
        <div className="hud-panel p-4 md:p-5 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4 border border-border/50 no-print">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="size-11 rounded-xl primary-gradient flex items-center justify-center shrink-0 shadow-md shadow-primary/30">
                <Clock className="size-5 text-white" />
              </div>
              <div>
                <h2 className="text-xl font-display font-black tracking-wider text-foreground">REGIA GARA</h2>
                <div className="flex items-center gap-2">
                  <span className={`inline-block size-2 rounded-full ${
                    gameStatus === "Gara attiva" 
                      ? "bg-emerald-400 animate-pulse" 
                      : gameStatus === "Gara terminata" 
                      ? "bg-red-400" 
                      : "bg-amber-400"
                  }`} />
                  <span className="text-[11px] text-muted-foreground uppercase font-bold tracking-wider">{gameStatus}</span>
                </div>
              </div>
            </div>

            {/* Quick Status Pill for Mobile */}
            <div className="md:hidden flex items-center gap-2 bg-secondary/80 px-3 py-1.5 rounded-xl border border-border/40">
              <span className="text-xs font-mono font-black text-primary">{raceTime}</span>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-between md:justify-end gap-3 md:gap-6 border-t md:border-t-0 pt-3 md:pt-0 border-border/30">
            {/* STATO GARA SELECTOR */}
            <div className="flex flex-col gap-0.5">
              <span className="text-[9px] uppercase tracking-wider text-muted-foreground font-bold">Cambia Stato</span>
              <select
                value={gameStatus}
                onChange={(e) => handleUpdateGameStatus(e.target.value)}
                className="bg-secondary text-xs font-bold text-foreground rounded-lg px-2 py-1.5 border border-border/60 outline-none cursor-pointer"
              >
                <option value="Gara non iniziata" className="bg-zinc-900 text-foreground">Non Iniziata</option>
                <option value="Gara attiva" className="bg-zinc-900 text-foreground">Gara Attiva</option>
                <option value="Gara terminata" className="bg-zinc-900 text-foreground">Gara Terminata</option>
              </select>
            </div>

            {/* QUICK STATS */}
            <div className="flex items-center gap-3 sm:gap-5">
              <div className="text-center bg-secondary/40 px-3 py-1 rounded-lg border border-border/30">
                <p className="text-[9px] uppercase text-muted-foreground font-bold">Squadre</p>
                <p className="text-sm font-black text-foreground">{activeTeamsCount}/{totalTeamsCount}</p>
              </div>
              <div className="text-center bg-secondary/40 px-3 py-1 rounded-lg border border-border/30">
                <p className="text-[9px] uppercase text-muted-foreground font-bold">In Attesa</p>
                <p className={`text-sm font-black ${pendingApprovalsCount > 0 ? "text-amber-400 animate-pulse" : "text-muted-foreground"}`}>
                  {pendingApprovalsCount}
                </p>
              </div>
              <div className="hidden md:block text-center bg-secondary/40 px-3 py-1 rounded-lg border border-border/30">
                <p className="text-[9px] uppercase text-muted-foreground font-bold">Tempo</p>
                <p className="text-sm font-mono font-black text-primary">{raceTime}</p>
              </div>
            </div>
          </div>
        </div>

        {/* SWIPEABLE CATEGORIZED NAVIGATION BAR (Ergonomico su Mobile) */}
        <div className="w-full overflow-x-auto no-scrollbar py-1">
          <div className="flex items-center gap-2 min-w-max pb-1">
            {adminNavCategories.flatMap((cat) =>
              cat.links.map((link) => {
                const isActive = currentPath === link.to;
                return (
                  <Link
                    key={link.to}
                    to={link.to}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all touch-active whitespace-nowrap ${
                      isActive
                        ? "primary-gradient text-white shadow-md shadow-primary/25 scale-[1.02]"
                        : "bg-card/70 hover:bg-card border border-border/50 text-muted-foreground hover:text-foreground"
                    }`}
                  >
                    <span>{link.label}</span>
                    {link.badge && link.badge > 0 ? (
                      <span className="flex size-4 items-center justify-center rounded-full bg-red-500 text-[9px] font-black text-white">
                        {link.badge}
                      </span>
                    ) : null}
                  </Link>
                );
              })
            )}
          </div>
        </div>

        {/* SUBPAGES OUTLET VIEW */}
        <AdminContext.Provider value={{
          stages,
          challenges,
          board,
          marketplaceTransactions,
          gameSettings,
          allTeams,
          allSubmissions,
          allProgress,
          allScores,
          selectedTeamBankState,
          allSocialSubmissions,
          secretCodeDashboard,
          allAnswers,
          quizQuestions,
          activityLog,
          settings,
          allEmojiMovies,
          allPosters,
          allTeamPosters,
          raceTime,
          monitorRows,
          sortedLeaderboard,
          selectedTeamId,
          setSelectedTeamId,
          isConfirmingScore,
          isEvaluating,
          isEvaluatingSocial,
          isForcingCode,
          isUpdatingCodeSettings,
          isTogglingMarketplace,
          isProcessingBank,
          handleUpdateGameStatus,
          handleEvaluatePoster,
          handleConfirmPhotoScore,
          handleToggleMarketplace,
          handleForceCompleteBank,
          handleResetBank,
          handleEditBankAnswer,
          handleEvaluateSocial,
          handleForceCompleteCode,
          handleEditCodeMatch,
          handleUpdateCodeSettings
        }}>
          <Outlet />
        </AdminContext.Provider>
      </div>
    </AppShell>
  );
}

export function StatCard({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-xl border border-border/30 bg-background/35 p-4 shadow-sm">
      <p className="text-[10px] font-extrabold tracking-wider text-muted-foreground uppercase">{title}</p>
      <p className="font-display text-3xl font-extrabold mt-1 text-foreground">{value}</p>
    </div>
  );
}

export function ApprovalCard({
  sub,
  progress,
  scores,
  onConfirmScore,
  isConfirming,
}: {
  sub: any;
  progress: any[];
  scores: any[];
  onConfirmScore: (points: number) => Promise<void>;
  isConfirming: boolean;
}) {
  const [url, setUrl] = useState<string | null>(null);
  const [isFlipped, setIsFlipped] = useState(false);
  const [rotation, setRotation] = useState(0);

  const scoreEntry = (scores ?? []).find(
    (sc: any) => sc.team_id === sub.team_id && sc.challenge_id === sub.challenge_id
  );
  const maxPoints = sub.challenges?.punteggio_massimo ?? 20;
  const currentPoints = scoreEntry?.punti ?? maxPoints;
  const [points, setPoints] = useState<number>(currentPoints);

  useEffect(() => {
    setPoints(currentPoints);
  }, [currentPoints]);

  useEffect(() => {
    if (!sub.file_upload) return;
    let active = true;
    supabase.storage
      .from("team-media")
      .createSignedUrl(sub.file_upload, 3600)
      .then(({ data }: any) => {
        if (active) setUrl(data?.signedUrl ?? null);
      });
    return () => {
      active = false;
    };
  }, [sub.file_upload]);

  const prog = (progress ?? []).find(
    (p: any) => p.team_id === sub.team_id && p.challenge_id === sub.challenge_id
  );
  let durationStr = "—";
  if (prog?.started_at) {
    const elapsedMs = new Date(sub.timestamp).getTime() - new Date(prog.started_at).getTime();
    if (elapsedMs > 0) {
      const totalSecs = Math.round(elapsedMs / 1000);
      const hrs = Math.floor(totalSecs / 3600);
      const mins = Math.floor((totalSecs % 3600) / 60);
      const secs = totalSecs % 60;
      durationStr = `${hrs > 0 ? hrs + "h " : ""}${mins > 0 ? mins + "m " : ""}${secs}s`;
    }
  }

  const handleConfirm = async () => {
    if (sub.stato_approvazione === "confirmed") {
      const confirmChange = window.confirm(
        `Questa prova è già stata verificata con ${currentPoints} punti. Sei sicuro di voler modificare il punteggio in ${points} punti?`
      );
      if (!confirmChange) return;
    }
    await onConfirmScore(points);
  };

  return (
    <div className="surface p-5 space-y-4">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2 border-b border-border/30 pb-3">
        <div>
          <span className="text-[9px] font-extrabold tracking-widest text-primary uppercase bg-primary/10 px-2 py-0.5 rounded">
            {sub.challenges?.stages?.titolo ? `Tappa ${sub.challenges?.stages?.numero_tappa}: ${sub.challenges?.stages?.titolo}` : sub.challenges?.stages?.nome_tappa ?? "Tappa"} · {sub.challenges?.titolo ?? "Prova"}
          </span>
          <h3 className="font-extrabold text-lg mt-1 text-foreground">
            Squadra: {sub.teams?.nome_squadra ?? "Sconosciuta"}
          </h3>
        </div>
        <div className="flex items-center gap-1.5 text-xs text-muted-foreground font-semibold">
          <Clock className="size-3.5" />
          <span>{new Date(sub.timestamp).toLocaleString("it-IT")}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {sub.file_upload && (
          <div className="md:col-span-1">
            {url ? (
              <div className="relative rounded-lg overflow-hidden border border-border/40 shadow-md bg-muted">
                <img
                  src={url}
                  alt="Allegato prova"
                  className="w-full h-44 object-cover transition-transform duration-200"
                  style={{
                    transform: `${isFlipped ? "scaleX(-1)" : ""} rotate(${rotation}deg)`,
                  }}
                />
                <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                  <button
                    type="button"
                    title="Ribalta orizzontale (Specchia)"
                    onClick={() => setIsFlipped(!isFlipped)}
                    className={`p-1.5 rounded-md text-xs font-bold transition-colors ${
                      isFlipped ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                    }`}
                  >
                    <FlipHorizontal className="size-3.5" />
                  </button>
                  <button
                    type="button"
                    title="Ruota 90°"
                    onClick={() => setRotation((r) => (r + 90) % 360)}
                    className="p-1.5 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                  >
                    <RotateCw className="size-3.5" />
                  </button>
                </div>
              </div>
            ) : (
              <div className="w-full h-44 animate-pulse rounded-lg bg-muted" />
            )}
            <div className="mt-2 text-center">
              <a
                href={url ?? "#"}
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs font-bold text-primary hover:underline"
              >
                Vedi allegato ingrandito ↗
              </a>
            </div>
          </div>
        )}

        <div className={sub.file_upload ? "md:col-span-2 space-y-3" : "md:col-span-3 space-y-3"}>
          {sub.risposta && (
            <div>
              <p className="text-[10px] font-extrabold tracking-wider text-muted-foreground uppercase">Risposta Inviata:</p>
              <div className="mt-1 bg-secondary/55 p-3 rounded-lg border border-border/30 text-sm font-semibold text-foreground whitespace-pre-wrap">
                {sub.risposta}
              </div>
            </div>
          )}

          <div className="flex flex-wrap gap-2">
            {sub.latitude != null && sub.longitude != null && (
              <div className="flex items-center gap-1.5 text-xs text-muted-foreground bg-secondary/30 p-2 rounded-lg w-fit">
                <MapPin className="size-4 text-accent" />
                <span>
                  Coordinate GPS: {sub.latitude.toFixed(6)}, {sub.longitude.toFixed(6)}
                </span>
              </div>
            )}

            <div className="flex items-center gap-1.5 text-xs text-muted-foreground bg-secondary/30 p-2 rounded-lg w-fit">
              <Clock className="size-4 text-primary" />
              <span>
                Tempo impiegato: {durationStr}
              </span>
            </div>
          </div>

          <div className="pt-3 border-t border-border/30 flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <label className="text-xs font-bold text-muted-foreground uppercase">Punteggio della Prova:</label>
              <input
                type="number"
                min="0"
                max={maxPoints}
                value={points}
                onChange={(e) => setPoints(Number(e.target.value))}
                className="w-16 rounded-lg border border-input bg-input/40 px-2 py-1 text-sm text-center font-bold text-foreground focus:outline-none"
              />
              <span className="text-xs text-muted-foreground font-semibold">/ {maxPoints} PT</span>
            </div>
            
            <button
              onClick={handleConfirm}
              disabled={isConfirming}
              className="flex items-center gap-1.5 bg-success/20 text-success border border-success/35 hover:bg-success/35 disabled:opacity-40 px-4 py-2 rounded-lg text-xs font-bold transition-colors cursor-pointer"
            >
              {isConfirming ? <Loader2 className="size-4 animate-spin" /> : <CheckCircle className="size-4" />}
              <span>{sub.stato_approvazione === "confirmed" ? "Aggiorna Punteggio" : "Salva Punteggio"}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function LiveMap({ teams, submissions, stages }: { teams: any[]; submissions: any[]; stages: any[] }) {
  const mapRef = useRef<HTMLDivElement>(null);
  const leafletMapRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);

  useEffect(() => {
    if (typeof window === "undefined" || !mapRef.current) return;

    if (!document.getElementById("leaflet-css")) {
      const link = document.createElement("link");
      link.id = "leaflet-css";
      link.rel = "stylesheet";
      link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
      document.head.appendChild(link);
    }

    const initMap = () => {
      const L = (window as any).L;
      if (!L || leafletMapRef.current) {
        if (L && leafletMapRef.current) updateMarkers();
        return;
      }

      const map = L.map(mapRef.current, {
        zoomControl: true,
        scrollWheelZoom: false
      }).setView([44.6982, 7.8507], 14);

      L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 20
      }).addTo(map);

      leafletMapRef.current = map;
      updateMarkers();
    };

    const updateMarkers = () => {
      const L = (window as any).L;
      const map = leafletMapRef.current;
      if (!L || !map) return;

      markersRef.current.forEach((m: any) => m.remove());
      markersRef.current = [];

      stages.forEach((stg: any) => {
        const lat = stg.latitude || stg.lat;
        const lon = stg.longitude || stg.lon || stg.lng;
        if (lat != null && lon != null) {
          const stageNum = stg.order_index || stg.ordine || "";
          const numberIcon = L.divIcon({
            html: `<div style="display: flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 50%; background-color: #f97316; color: #fff; font-weight: 900; font-size: 11px; border: 2px solid #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.3); font-family: sans-serif;">${stageNum}</div>`,
            className: "custom-stage-marker-icon",
            iconSize: [24, 24],
            iconAnchor: [12, 12]
          });
          const cpMarker = L.marker([Number(lat), Number(lon)], {
            icon: numberIcon
          }).addTo(map).bindPopup(`<b>Tappa ${stageNum}:</b> ${stg.nome_tappa || stg.title || ""}`);
          markersRef.current.push(cpMarker);
        }
      });

      teams.forEach(t => {
        const teamSubs = submissions
          .filter(s => s.team_id === t.id && s.latitude && s.longitude)
          .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

        if (teamSubs.length > 0) {
          const latestSub = teamSubs[0];
          const teamColor = t.color || "#f97316";

          const teamMarker = L.circleMarker([latestSub.latitude, latestSub.longitude], {
            radius: 10,
            fillColor: teamColor,
            color: "#fff",
            weight: 2.5,
            opacity: 1,
            fillOpacity: 0.8
          }).addTo(map).bindPopup(`
            <div style="color:#000; font-family: sans-serif; padding: 4px;">
              <b style="font-size: 13px;">${t.nome_squadra}</b><br/>
              <span style="font-size: 10px; color:#555;">Ultima Azione:</span><br/>
              <span style="font-size: 11px; font-weight: bold;">${latestSub.risposta || "Invio file"}</span><br/>
              <span style="font-size: 9px; color:#888;">Aggiornato alle: ${new Date(latestSub.timestamp).toLocaleTimeString("it-IT")}</span>
            </div>
          `);
          markersRef.current.push(teamMarker);
        }
      });
    };

    if (!(window as any).L) {
      const script = document.createElement("script");
      script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
      script.onload = initMap;
      document.head.appendChild(script);
    } else {
      initMap();
    }

    return () => {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, [teams, submissions, stages]);

  return (
    <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-display font-black uppercase tracking-wider text-muted-foreground">Mappa Live</h2>
        <span className="text-[10px] uppercase font-bold text-success animate-pulse">Live Tracking</span>
      </div>
      <div ref={mapRef} className="h-64 md:h-80 w-full rounded-xl border border-border/40 overflow-hidden" />
    </div>
  );
}

export function PosterComparisonCard({
  team,
  poster,
  submission,
  onEvaluate,
  isEvaluating,
}: {
  team: any;
  poster: any;
  submission: any;
  onEvaluate: (submissionId: string, voto: number) => Promise<void>;
  isEvaluating: boolean;
}) {
  const [teamPhotoUrl, setTeamPhotoUrl] = useState<string | null>(null);
  const [selectedVoto, setSelectedVoto] = useState<number>(submission?.voto ?? 15);
  const [isFlipped, setIsFlipped] = useState(false);
  const [rotation, setRotation] = useState(0);

  useEffect(() => {
    let active = true;
    if (submission?.file_upload) {
      supabase.storage
        .from("team-media")
        .createSignedUrl(submission.file_upload, 3600)
        .then(({ data }: any) => {
          if (active) setTeamPhotoUrl(data?.signedUrl ?? null);
        });
    }
    return () => {
      active = false;
    };
  }, [submission?.file_upload]);

  useEffect(() => {
    if (submission?.voto !== null && submission?.voto !== undefined) {
      setSelectedVoto(submission.voto);
    }
  }, [submission?.voto]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!submission) return;

    if (submission.voto !== null && submission.voto !== undefined) {
      const confirmChange = window.confirm(
        `Questa prova è già stata valutata con ${submission.voto} punti. Sei sicuro di voler modificare il voto in ${selectedVoto} punti?`
      );
      if (!confirmChange) return;
    }

    await onEvaluate(submission.id, selectedVoto);
  };

  const posterFileName = poster?.file_name;
  const originalPosterUrl = posterFileName 
    ? (posterFileName.startsWith("/") ? posterFileName : `/POSTER/${posterFileName}`)
    : null;

  return (
    <div className="surface p-5 space-y-6 border border-zinc-800/80 bg-zinc-950/20 rounded-2xl relative overflow-hidden">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-3 border-b border-border/30 pb-3">
        <div>
          <h3 className="font-extrabold text-lg text-foreground flex items-center gap-2">
            <span className="grid size-6 place-items-center rounded-full bg-primary/10 text-primary text-xs font-bold font-mono">
              {team.avatar_url || "🏳️"}
            </span>
            <span>{team.nome_squadra}</span>
          </h3>
          <p className="text-xs text-muted-foreground mt-0.5">
            Assegnato: <span className="text-foreground font-bold">{poster?.titolo || "Locandina non ancora estratta"}</span> {posterFileName && (
              <>· File: <span className="font-mono text-zinc-400">{posterFileName}</span></>
            )}
          </p>
        </div>

        <div>
          {submission ? (
            <span className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded ${
              submission.voto !== null ? "bg-green-950/40 text-success border border-green-900/40" : "bg-primary/20 text-primary border border-primary/20"
            }`}>
              {submission.voto !== null ? `Valutato (${submission.voto} PT)` : "In attesa di voto"}
            </span>
          ) : (
            <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-secondary text-muted-foreground border border-border/20">
              Nessuna Consegna
            </span>
          )}
        </div>
      </div>

      {/* COMPARISON & EVALUATION SECTION */}
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
          {/* ORIGINAL POSTER */}
          <div className="space-y-2">
            <p className="text-xs font-bold text-muted-foreground uppercase text-center flex items-center justify-center gap-1">
              <Film className="size-3 text-red-500" /> Locandina Originale Assegnata
            </p>
            <div className="overflow-hidden rounded-xl border border-zinc-800 bg-zinc-950 flex flex-col justify-center items-center min-h-[260px] p-2 text-center">
              {originalPosterUrl ? (
                <img
                  src={originalPosterUrl}
                  alt={poster?.titolo || "Locandina Originale"}
                  onError={(e) => {
                    // Fallback to lowercase path
                    const target = e.currentTarget;
                    if (target.src.includes("/POSTER/")) {
                      target.src = target.src.replace("/POSTER/", "/poster/");
                    }
                  }}
                  className="h-full w-auto object-contain max-h-[280px] rounded-lg shadow-lg"
                />
              ) : (
                <div className="space-y-1 p-4">
                  <Film className="size-8 text-zinc-700 mx-auto" />
                  <p className="text-xs text-zinc-500 font-semibold">Nessuna locandina ancora assegnata alla squadra</p>
                  <p className="text-[10px] text-zinc-600">Verrà assegnata appena il team aprirà la sfida</p>
                </div>
              )}
            </div>
          </div>

          {/* TEAM RECONSTRUCTION */}
          <div className="space-y-2">
            <p className="text-xs font-bold text-muted-foreground uppercase text-center flex items-center justify-center gap-1">
              <Camera className="size-3 text-red-500" /> Ricostruzione della Squadra
            </p>
            <div className="relative overflow-hidden rounded-xl border border-zinc-800 bg-zinc-950 flex flex-col justify-center items-center min-h-[260px] p-2 text-center">
              {submission ? (
                teamPhotoUrl ? (
                  <>
                    <img
                      src={teamPhotoUrl}
                      alt="Ricostruzione Squadra"
                      className="h-full w-auto object-contain max-h-[280px] rounded-lg shadow-lg transition-transform duration-200"
                      style={{
                        transform: `${isFlipped ? "scaleX(-1)" : ""} rotate(${rotation}deg)`,
                      }}
                    />
                    <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                      <button
                        type="button"
                        title="Ribalta orizzontale (Specchia)"
                        onClick={() => setIsFlipped(!isFlipped)}
                        className={`p-1.5 rounded-md text-xs font-bold transition-colors ${
                          isFlipped ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                        }`}
                      >
                        <FlipHorizontal className="size-3.5" />
                      </button>
                      <button
                        type="button"
                        title="Ruota 90°"
                        onClick={() => setRotation((r) => (r + 90) % 360)}
                        className="p-1.5 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                      >
                        <RotateCw className="size-3.5" />
                      </button>
                    </div>
                  </>
                ) : (
                  <div className="flex flex-col items-center justify-center gap-2">
                    <Loader2 className="size-6 animate-spin text-primary" />
                    <span className="text-xs text-zinc-500">Caricamento foto squadra...</span>
                  </div>
                )
              ) : (
                <div className="space-y-1 p-4">
                  <Camera className="size-8 text-zinc-700 mx-auto" />
                  <p className="text-xs text-zinc-500 font-semibold">In attesa della foto della squadra</p>
                  <p className="text-[10px] text-zinc-600">La squadra non ha ancora completato lo scatto</p>
                </div>
              )}
            </div>
          </div>
        </div>

        {submission && (
          <>
            <div className="text-xs text-muted-foreground text-center font-mono">
              Consegna effettuata il: {new Date(submission.timestamp).toLocaleString("it-IT")}
            </div>

            <form onSubmit={handleSubmit} className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/80 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex-1 space-y-2">
                <div className="flex justify-between items-center text-xs font-bold text-zinc-400 uppercase">
                  <span>Voto (Punteggio):</span>
                  <span className="text-primary font-black text-sm">{selectedVoto} / 15 PT</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="15"
                  step="1"
                  value={selectedVoto}
                  onChange={(e) => setSelectedVoto(parseInt(e.target.value))}
                  className="w-full h-2 bg-zinc-800 rounded-lg appearance-none cursor-pointer accent-red-600 focus:outline-none"
                />
                <div className="flex justify-between text-[10px] text-zinc-600 font-bold px-1">
                  <span>0</span>
                  <span>3</span>
                  <span>6</span>
                  <span>9</span>
                  <span>12</span>
                  <span>15</span>
                </div>
              </div>

              <button
                type="submit"
                disabled={isEvaluating}
                className="primary-gradient px-6 py-3 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 shrink-0 cursor-pointer disabled:opacity-40"
              >
                {isEvaluating ? <Loader2 className="size-4 animate-spin" /> : <Sparkles className="size-4" />}
                {submission.voto !== null ? "Aggiorna Voto" : "Conferma Voto"}
              </button>
            </form>
          </>
        )}
      </div>
    </div>
  );
}

export function SocialSubmissionCard({
  team,
  submission,
  onEvaluate,
  isEvaluating,
}: {
  team: any;
  submission: any;
  onEvaluate: (submissionId: string, voto: number) => Promise<void>;
  isEvaluating: boolean;
}) {
  const [photo1Url, setPhoto1Url] = useState<string | null>(null);
  const [photo2Url, setPhoto2Url] = useState<string | null>(null);
  const [flip1, setFlip1] = useState(false);
  const [flip2, setFlip2] = useState(false);
  const [rot1, setRot1] = useState(0);
  const [rot2, setRot2] = useState(0);
  const [voto, setVoto] = useState<number>(submission?.admin_score ?? 20);

  useEffect(() => {
    let active = true;
    if (submission?.image_1_url) {
      supabase.storage
        .from("team-media")
        .createSignedUrl(submission.image_1_url, 3600)
        .then(({ data }: any) => {
          if (active) setPhoto1Url(data?.signedUrl ?? null);
        });
    }
    if (submission?.image_2_url) {
      supabase.storage
        .from("team-media")
        .createSignedUrl(submission.image_2_url, 3600)
        .then(({ data }: any) => {
          if (active) setPhoto2Url(data?.signedUrl ?? null);
        });
    }
    return () => {
      active = false;
    };
  }, [submission?.image_1_url, submission?.image_2_url]);

  useEffect(() => {
    if (submission?.admin_score !== null && submission?.admin_score !== undefined) {
      setVoto(submission.admin_score);
    }
  }, [submission?.admin_score]);

  const handleSaveScore = async () => {
    if (!submission) return;
    await onEvaluate(submission.id, voto);
  };

  return (
    <div className="surface p-5 space-y-5 border border-zinc-800 bg-zinc-950/20 rounded-2xl relative overflow-hidden">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-3 border-b border-border/30 pb-3">
        <div>
          <h3 className="font-extrabold text-lg text-foreground flex items-center gap-2">
            <span className="grid size-6 place-items-center rounded-full bg-primary/10 text-primary text-xs font-bold font-mono">
              {team.avatar_url || "🏳️"}
            </span>
            <span>{team.nome_squadra}</span>
          </h3>
          <p className="text-xs text-muted-foreground mt-0.5">
            Missione Social · {submission ? `Inviata il: ${new Date(submission.uploaded_at).toLocaleString("it-IT")}` : "Nessuna consegna"}
          </p>
        </div>

        <div>
          {submission ? (
            <span className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded ${
              submission.status === "approved"
                ? "bg-green-950/40 text-success border border-green-900/40"
                : "bg-primary/20 text-primary border border-primary/20"
            }`}>
              {submission.status === "approved"
                ? `Valutata (${submission.admin_score} / 20 PT)`
                : "In attesa di valutazione"}
            </span>
          ) : (
            <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-secondary text-muted-foreground border border-border/20">
              Nessuna Consegna
            </span>
          )}
        </div>
      </div>

      {submission ? (
        <div className="space-y-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <p className="text-xs font-bold text-muted-foreground uppercase text-center">Foto 1 - Sconosciuto #1</p>
              <div className="relative overflow-hidden rounded-xl border border-zinc-900 bg-zinc-950 flex justify-center items-center h-[220px] p-1.5">
                {photo1Url ? (
                  <>
                    <img
                      src={photo1Url}
                      alt="Foto 1"
                      className="h-full w-full object-cover rounded-lg shadow transition-transform duration-200"
                      style={{
                        transform: `${flip1 ? "scaleX(-1)" : ""} rotate(${rot1}deg)`,
                      }}
                    />
                    <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                      <button
                        type="button"
                        title="Ribalta orizzontale"
                        onClick={() => setFlip1(!flip1)}
                        className={`p-1.5 rounded-md text-xs font-bold transition-colors ${
                          flip1 ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                        }`}
                      >
                        <FlipHorizontal className="size-3.5" />
                      </button>
                      <button
                        type="button"
                        title="Ruota 90°"
                        onClick={() => setRot1((r) => (r + 90) % 360)}
                        className="p-1.5 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                      >
                        <RotateCw className="size-3.5" />
                      </button>
                    </div>
                  </>
                ) : (
                  <Loader2 className="size-5 animate-spin text-zinc-500" />
                )}
              </div>
            </div>

            <div className="space-y-1.5">
              <p className="text-xs font-bold text-muted-foreground uppercase text-center">Foto 2 - Sconosciuto #2</p>
              <div className="relative overflow-hidden rounded-xl border border-zinc-900 bg-zinc-950 flex justify-center items-center h-[220px] p-1.5">
                {photo2Url ? (
                  <>
                    <img
                      src={photo2Url}
                      alt="Foto 2"
                      className="h-full w-full object-cover rounded-lg shadow transition-transform duration-200"
                      style={{
                        transform: `${flip2 ? "scaleX(-1)" : ""} rotate(${rot2}deg)`,
                      }}
                    />
                    <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                      <button
                        type="button"
                        title="Ribalta orizzontale"
                        onClick={() => setFlip2(!flip2)}
                        className={`p-1.5 rounded-md text-xs font-bold transition-colors ${
                          flip2 ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                        }`}
                      >
                        <FlipHorizontal className="size-3.5" />
                      </button>
                      <button
                        type="button"
                        title="Ruota 90°"
                        onClick={() => setRot2((r) => (r + 90) % 360)}
                        className="p-1.5 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                      >
                        <RotateCw className="size-3.5" />
                      </button>
                    </div>
                  </>
                ) : (
                  <Loader2 className="size-5 animate-spin text-zinc-500" />
                )}
              </div>
            </div>
          </div>

          <div className="bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/80 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex-1 space-y-2">
              <div className="flex justify-between items-center text-xs font-bold text-zinc-400 uppercase">
                <span>Punteggio (0–20 PT):</span>
                <span className="text-primary font-black text-sm">{voto} / 20 PT</span>
              </div>
              <input
                type="range"
                min="0"
                max="20"
                step="1"
                value={voto}
                onChange={(e) => setVoto(parseInt(e.target.value))}
                className="w-full h-2 bg-zinc-800 rounded-lg appearance-none cursor-pointer accent-primary focus:outline-none"
              />
            </div>

            <div className="flex gap-2 shrink-0">
              <button
                onClick={handleSaveScore}
                disabled={isEvaluating}
                className="primary-gradient px-5 py-2.5 rounded-xl font-extrabold text-xs text-primary-foreground flex items-center gap-1.5 cursor-pointer disabled:opacity-40"
              >
                {isEvaluating ? <Loader2 className="size-3.5 animate-spin" /> : <CheckCircle className="size-3.5" />}
                Salva Punteggio
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="bg-zinc-900/10 p-5 rounded-xl border border-zinc-900 text-center text-sm text-muted-foreground">
          La squadra non ha ancora effettuato il caricamento per questa sfida.
        </div>
      )}
    </div>
  );
}
