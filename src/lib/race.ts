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
  queryFn: async (): Promise<Team | null> => {
    const { data: idData, error: idError } = await (supabase as any).rpc("current_team_id");
    if (idError) {
      console.warn("[race] myTeamQuery rpc error:", idError);
      return null;
    }
    if (!idData) return null;
    const { data, error } = await (supabase as any)
      .from("teams")
      .select("id,name:nome_squadra,motto,avatar_url,color:colore,created_at,token_balance,freeze_started_at,freeze_expires_at,freeze_duration_seconds")
      .eq("id", idData as string)
      .maybeSingle();
    if (error) {
      console.warn("[race] myTeamQuery select error:", error);
      return null;
    }
    if (!data) return null;
    return {
      id: data.id,
      name: data.name,
      motto: data.motto,
      avatar_url: data.avatar_url,
      color: data.color || "#f97316",
      owner_id: data.id,
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
    const { data, error } = await (supabase as any).rpc("get_secure_leaderboard");
    if (error) {
      console.warn("[race] leaderboardQuery error:", error);
      return [];
    }
    return data as LeaderboardRow[];
  },
  refetchInterval: 20000,
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
          .select("id,points:punti,reason:motivo,created_at")
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
    queryFn: async () =>
      unwrap<{ id: string; name: string }[]>(
        await (supabase as any)
          .from("team_members")
          .select("id,name")
          .eq("team_id", teamId!)
          .order("created_at"),
      ),
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

