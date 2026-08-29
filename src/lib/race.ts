import { queryOptions } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export type Stage = {
  id: string;
  title: string;
  description: string | null;
  location: string | null;
  order_index: number;
  status: string;
  latitude?: number | null;
  longitude?: number | null;
  stato?: "open" | "closed";
  outcome?: {
    closed_at: string;
    closed_by: string;
    ranking: Array<{
      team_id: string;
      nome_squadra: string;
      avatar_url?: string | null;
      color?: string | null;
      position: number;
      reward: number;
      oldBalance: number;
      newBalance: number;
      actualAdded: number;
      capped: boolean;
    }>;
  } | null;
};

export type Challenge = {
  id: string;
  stage_id: string;
  title: string;
  description: string | null;
  type: string;
  order_index: number;
  points: number;
};

export type Team = {
  id: string;
  name: string;
  motto: string | null;
  avatar_url: string | null;
  color: string;
  owner_id: string;
  created_at: string;
  token_balance?: number;
  freeze_started_at?: string | null;
  freeze_expires_at?: string | null;
  freeze_duration_seconds?: number | null;
};

export type Progress = {
  id: string;
  team_id: string;
  challenge_id: string;
  status: string;
  started_at: string;
  completed_at: string | null;
};

export type QuizQuestion = {
  id: string;
  challenge_id: string;
  question: string;
  options: string[];
  order_index: number;
  points: number;
};

export type TeamAnswer = {
  id: string;
  question_id: string;
  selected_answer: number;
  correct: boolean;
  created_at: string;
};

export type ScoreEvent = {
  id: string;
  points: number;
  reason: string;
  created_at: string;
};

export type MediaItem = {
  id: string;
  url: string;
  type: string;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
  challenge_id: string | null;
};

export type LeaderboardRow = {
  team_id: string;
  name: string;
  color: string;
  avatar_url: string | null;
  motto: string | null;
  challenges_points?: number;
  modifier_points?: number;
  cattiveria_points?: number;
  total_points: number;
  completed_challenges: number;
  total_duration_seconds: number | null;
  last_completion: string | null;
  active?: boolean;
  freeze_started_at?: string | null;
  freeze_expires_at?: string | null;
  rank?: number;
};

export type RaceSession = {
  id: string;
  stage_id: string | null;
  start_time: string;
  end_time: string | null;
  duration_seconds: number | null;
};

function unwrap<T>(res: { data: unknown; error: { message: string } | null }): T {
  if (res.error) {
    console.warn("[race] DB error:", res.error.message);
    return ([] as unknown) as T;
  }
  return (res.data ?? []) as T;
}

export const stagesQuery = queryOptions({
  queryKey: ["stages"],
  queryFn: async () => {
    const raw = unwrap<any[]>(
      await (supabase as any)
        .from("stages")
        .select("id,title:titolo,description:descrizione,order_index:numero_tappa,latitude,longitude,stato,outcome")
        .order("numero_tappa"),
    );
    return raw.map((s) => ({
      ...s,
      location: s.description ? s.description.split(" - ")[0] || "Bra" : "Bra",
      status: s.stato || "open",
    })) as Stage[];
  },
});

export const challengesQuery = queryOptions({
  queryKey: ["challenges"],
  queryFn: async () =>
    unwrap<any[]>(
      await (supabase as any)
        .from("challenges")
        .select("id,stage_id,title:titolo,description:descrizione,type:tipo_sfida,order_index:ordine_sfida,points:punteggio_massimo")
        .order("ordine_sfida"),
    ) as Challenge[],
});

/** Returns lightweight list of all teams with their avatar and color — used to enforce mutual exclusivity in team setup. */
export const allTeamsQuery = queryOptions({
  queryKey: ["all-teams-colors"],
  queryFn: async (): Promise<Array<{ id: string; name: string; avatar_url: string | null; color: string | null }>> => {
    const { data, error } = await (supabase as any)
      .from("teams")
      .select("id,name:nome_squadra,avatar_url,color:colore");
    if (error) {
      console.warn("[race] allTeamsQuery error:", error);
      return [];
    }
    return data ?? [];
  },
});

export const myTeamQuery = queryOptions({
  queryKey: ["my-team"],
  staleTime: 0,
  queryFn: async (): Promise<Team | null> => {
    let teamId: string | null = null;
    try {
      const { data: idData } = await (supabase as any).rpc("current_team_id");
      if (idData) teamId = idData as string;
    } catch (err) {
      console.warn("[race] myTeamQuery rpc error:", err);
    }

    let data: any = null;

    if (teamId) {
      const res = await (supabase as any)
        .from("teams")
        .select("id,name:nome_squadra,motto,avatar_url,color:colore,created_at,token_balance,freeze_started_at,freeze_expires_at,freeze_duration_seconds,owner_id,username")
        .eq("id", teamId)
        .maybeSingle();
      data = res.data;
    }

    // Fallback: match by currently authenticated user
    if (!data) {
      try {
        const { data: authData } = await supabase.auth.getUser();
        const user = authData?.user;
        if (user) {
          const usernameFromEmail = user.email ? user.email.split("@")[0].toLowerCase() : "";
          const res = await (supabase as any)
            .from("teams")
            .select("id,name:nome_squadra,motto,avatar_url,color:colore,created_at,token_balance,freeze_started_at,freeze_expires_at,freeze_duration_seconds,owner_id,username")
            .or(`owner_id.eq.${user.id},id.eq.${user.id},username.eq.${usernameFromEmail},nome_squadra.eq.${usernameFromEmail}`)
            .maybeSingle();
          data = res.data;
        }
      } catch (authErr) {
        console.warn("[race] myTeamQuery auth fallback error:", authErr);
      }
    }

    if (!data) return null;

    return {
      id: data.id,
      name: data.name,
      motto: data.motto,
      avatar_url: data.avatar_url,
      color: data.color || "#f97316",
      owner_id: data.owner_id || data.id,
      created_at: data.created_at,
      token_balance: data.token_balance ?? 0,
      freeze_started_at: data.freeze_started_at,
      freeze_expires_at: data.freeze_expires_at,
      freeze_duration_seconds: data.freeze_duration_seconds,
    } as Team;
  },
});

export const leaderboardQuery = queryOptions({
  queryKey: ["leaderboard"],
  staleTime: 0,
  queryFn: async () => {
    try {
      const { data, error } = await (supabase as any).rpc("get_secure_leaderboard");
      if (!error && data && Array.isArray(data) && data.length > 0) {
        return data as LeaderboardRow[];
      }
    } catch (err) {
      console.warn("[race] leaderboardQuery rpc error:", err);
    }

    // High-resilience direct calculation fallback
    try {
      const { data: teams } = await (supabase as any).from("teams").select("*");
      const { data: scores } = await (supabase as any).from("scores").select("*");
      const { data: progress } = await (supabase as any).from("team_progress").select("*");
      const { data: cattiveria } = await (supabase as any).from("cattiveria_ledger").select("*");
      const { data: penalties } = await (supabase as any).from("time_penalties").select("*");

      if (teams && teams.length > 0) {
        const rows: LeaderboardRow[] = teams.map((t: any) => {
          const teamScores = (scores || []).filter((s: any) => s.team_id === t.id);
          const teamCatt = (cattiveria || []).filter((c: any) => c.team_id === t.id);
          const teamProg = (progress || []).filter(
            (p: any) => p.team_id === t.id && (p.stato === "completed" || p.status === "completed")
          );
          const teamPen = (penalties || []).filter((p: any) => p.team_id === t.id);

          const chPts = teamScores.filter((s: any) => s.challenge_id).reduce((acc: number, s: any) => acc + (s.punti || 0), 0);
          const modPts = teamScores.filter((s: any) => !s.challenge_id).reduce((acc: number, s: any) => acc + (s.punti || 0), 0);
          const cattPts = 0; // Private for Admin / Final Report only
          const totPts = teamScores.reduce((acc: number, s: any) => acc + (s.punti || 0), 0);
          const duration = teamPen.reduce((acc: number, p: any) => acc + (p.minuti_penalita || 0) * 60, 0);

          return {
            team_id: t.id,
            name: t.nome_squadra || t.name,
            color: t.colore || t.color || "#ea580c",
            avatar_url: t.avatar_url,
            motto: t.motto,
            token_balance: t.token_balance ?? 0,
            challenges_points: chPts,
            modifier_points: modPts,
            cattiveria_points: cattPts,
            total_points: totPts,
            completed_challenges: teamProg.length,
            total_duration_seconds: duration,
            last_completion: teamProg.length > 0 ? teamProg[teamProg.length - 1].created_at || null : null,
            active: t.active ?? true,
            freeze_started_at: t.freeze_started_at,
            freeze_expires_at: t.freeze_expires_at,
          } as LeaderboardRow;
        });

        rows.sort((a, b) => (b.total_points || 0) - (a.total_points || 0));
        return rows;
      }
    } catch (fallbackErr) {
      console.warn("[race] leaderboardQuery fallback error:", fallbackErr);
    }

    return [];
  },
  refetchInterval: 5000,
});

export const progressQuery = (teamId: string | undefined) =>
  queryOptions({
    queryKey: ["progress", teamId],
    enabled: Boolean(teamId),
    staleTime: 0,
    queryFn: async () =>
      unwrap<any[]>(
        await (supabase as any)
          .from("team_progress")
          .select("id,team_id,challenge_id,status:stato,started_at:created_at,completed_at:completata_il")
          .eq("team_id", teamId!),
      ) as Progress[],
  });

export const scoreEventsQuery = (teamId: string | undefined) =>
  queryOptions({
    queryKey: ["score-events", teamId],
    enabled: Boolean(teamId),
    queryFn: async () =>
      unwrap<any[]>(
        await (supabase as any)
          .from("scores")
          .select("id,points:punti,reason:motivo,tipo_modificatore,challenge_id,created_at")
          .eq("team_id", teamId!)
          .order("created_at", { ascending: false })
          .limit(40),
      ) as ScoreEvent[],
  });

export const questionsQuery = (challengeId: string | undefined) =>
  queryOptions({
    queryKey: ["questions", challengeId],
    enabled: Boolean(challengeId),
    queryFn: async () =>
      unwrap<QuizQuestion[]>(
        await (supabase as any)
          .from("quiz_questions_public")
          .select("id,challenge_id,question,options,order_index,points")
          .eq("challenge_id", challengeId!)
          .order("order_index"),
      ),
  });

export const allQuestionsQuery = queryOptions({
  queryKey: ["questions", "all"],
  queryFn: async () =>
    unwrap<QuizQuestion[]>(
      await (supabase as any)
        .from("quiz_questions_public")
        .select("id,challenge_id,question,options,order_index,points")
        .order("order_index"),
    ),
});

export const answersQuery = (teamId: string | undefined) =>
  queryOptions({
    queryKey: ["answers", teamId],
    enabled: Boolean(teamId),
    queryFn: async () =>
      unwrap<TeamAnswer[]>(
        await (supabase as any)
          .from("team_answers")
          .select("id,question_id,selected_answer,correct,created_at")
          .eq("team_id", teamId!),
      ),
  });

export const mediaQuery = (teamId: string | undefined) =>
  queryOptions({
    queryKey: ["media", teamId],
    enabled: Boolean(teamId),
    staleTime: 0,
    refetchOnMount: "always" as const,
    queryFn: async () =>
      unwrap<any[]>(
        await (supabase as any)
          .from("submissions")
          .select("id,url,type:tipo,latitude,longitude,created_at,challenge_id")
          .eq("team_id", teamId!)
          .order("created_at", { ascending: false }),
      ).map((m) => ({
        ...m,
        url: m.url || "",
        type: m.type || "photo",
      })) as MediaItem[],
  });

export const sessionsQuery = (teamId: string | undefined) =>
  queryOptions({
    queryKey: ["sessions", teamId],
    enabled: Boolean(teamId),
    queryFn: async () =>
      unwrap<RaceSession[]>(
        await (supabase as any)
          .from("race_sessions")
          .select("id,stage_id,start_time,end_time,duration_seconds")
          .eq("team_id", teamId!),
      ),
  });

export const membersQuery = (teamId: string | undefined) =>
  queryOptions({
    queryKey: ["members", teamId],
    enabled: Boolean(teamId),
    queryFn: async () => {
      let serverMembers: { id: string; name: string }[] = [];
      try {
        const res = await (supabase as any)
          .from("team_members")
          .select("id,name")
          .eq("team_id", teamId!)
          .order("created_at");
        if (res.data) serverMembers = res.data;
      } catch (err) {
        console.warn("[race] membersQuery server error:", err);
      }

      // Check for locally synced members if RLS blocked server insert
      if (typeof window !== "undefined" && teamId) {
        try {
          const localStored = localStorage.getItem(`pechino_team_members_${teamId}`);
          if (localStored) {
            const localMembers = JSON.parse(localStored);
            if (Array.isArray(localMembers)) {
              // Merge by name, avoiding duplicates
              const names = new Set(serverMembers.map((m) => m.name.toLowerCase().trim()));
              for (const lm of localMembers) {
                if (lm?.name && !names.has(lm.name.toLowerCase().trim())) {
                  serverMembers.push(lm);
                  names.add(lm.name.toLowerCase().trim());
                }
              }
            }
          }
        } catch {
          // ignore
        }
      }

      return serverMembers;
    },
  });

export function challengeState(
  challenge: Challenge,
  stageChallenges: Challenge[],
  progress: Progress[],
): "locked" | "available" | "completed" {
  // Accept both 'status' (aliased) and 'stato' (raw DB field) for resilience
  const isCompleted = (p: any) => (p.status || p.stato) === "completed";
  const done = new Set(
    progress.filter(isCompleted).map((p) => p.challenge_id),
  );
  if (done.has(challenge.id)) return "completed";
  const earlier = stageChallenges.filter((c) => c.order_index < challenge.order_index && c.type !== "jackpot");
  return earlier.every((c) => done.has(c.id)) ? "available" : "locked";
}

export function formatDuration(seconds: number | null | undefined): string {
  if (seconds == null) return "--:--";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  const pad = (n: number) => String(n).padStart(2, "0");
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
}

export function rankLeaderboard(rows: LeaderboardRow[]): LeaderboardRow[] {
  return [...rows].sort((a, b) => {
    if (b.completed_challenges !== a.completed_challenges)
      return b.completed_challenges - a.completed_challenges;
    if (b.total_points !== a.total_points) return b.total_points - a.total_points;
    const da = a.total_duration_seconds ?? Number.MAX_SAFE_INTEGER;
    const db = b.total_duration_seconds ?? Number.MAX_SAFE_INTEGER;
    return da - db;
  });
}

export function isStageUnlocked(
  stage: Stage,
  allStages: Stage[],
  allChallenges: Challenge[],
  progress: Progress[],
): boolean {
  if (stage.order_index === 1) return true;
  
  const prevStage = allStages.find((s) => s.order_index === stage.order_index - 1);
  if (!prevStage) return true;
  
  const prevChallenges = allChallenges.filter((c) => c.stage_id === prevStage.id);
  if (prevChallenges.length === 0) return true;
  
  const completedIds = new Set(
    progress.filter((p: any) => (p.status || p.stato) === "completed").map((p) => p.challenge_id)
  );
  return prevChallenges.every((c) => completedIds.has(c.id));
}

export type ReportStatus = {
  status: "NOT_CALCULATED" | "CALCULATED" | "PUBLISHED";
  is_calculated: boolean;
  is_published: boolean;
  calculated_at: string | null;
  published_at: string | null;
};

export const reportStatusQuery = queryOptions({
  queryKey: ["report-status"],
  staleTime: 3000,
  queryFn: async () => {
    const { data, error } = await supabase.rpc("get_report_status");
    if (error) throw error;
    return data as ReportStatus;
  },
  refetchInterval: 5000,
});

export const gameReportQuery = (userId?: string) =>
  queryOptions({
    queryKey: ["game-report", userId],
    staleTime: 3000,
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_game_report", { p_user_id: userId });
      if (error) throw error;
      return data;
    },
    refetchInterval: 5000,
  });

