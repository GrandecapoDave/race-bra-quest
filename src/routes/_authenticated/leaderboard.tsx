import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Trophy } from "lucide-react";
import { useEffect } from "react";
import { toast } from "sonner";
import { AppShell } from "@/components/AppShell";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import { formatDuration, leaderboardQuery, myTeamQuery, rankLeaderboard } from "@/lib/race";

export const Route = createFileRoute("/_authenticated/leaderboard")({
  head: () => ({
    meta: [
      { title: "Classifica live — Pechino Express Bra" },
      {
        name: "description",
        content: "Ranking live delle squadre per punti, prove completate e tempo di gara.",
      },
      { property: "og:title", content: "Classifica live — Pechino Express Bra" },
      { property: "og:description", content: "Chi guida la gara urbana di Bra?" },
    ],
  }),
  component: LeaderboardPage,
});

const MEDALS = ["🥇", "🥈", "🥉"];

function LeaderboardPage() {
  const navigate = useNavigate();
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const board = useQuery({ ...leaderboardQuery, refetchInterval: 3000 });
  const team = useQuery(myTeamQuery);
  const rows = rankLeaderboard(board.data ?? []);

  useEffect(() => {
    if (!isAdmin.isLoading && !isAdmin.data) {
      toast.error("Accesso negato: puoi visualizzare la classifica live solo acquistando il 'Bonus Classifica' nel Marketplace.");
      navigate({ to: "/dashboard" });
    }
  }, [isAdmin.isLoading, isAdmin.data, navigate]);

  if (isAdmin.isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="text-center space-y-3">
          <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-xs text-muted-foreground uppercase font-black tracking-widest">Caricamento...</p>
        </div>
      </div>
    );
  }

  if (!isAdmin.data) {
    return null; // Will be redirected by useEffect
  }

  return (
    <AppShell isAdmin={isAdmin.data}>
      <h1 className="flex items-center gap-2 text-5xl leading-none">
        <Trophy className="size-8 text-gold" /> Classifica
      </h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Ordinata per punti, prove completate e tempo totale. Bonus arrivo tappa: 1° +20, 2° +15, 3°
        +10.
      </p>

      <ol className="mt-5 space-y-3">
        {rows.length === 0 && (
          <li className="surface p-5 text-sm text-muted-foreground">
            Nessuna squadra in gara: sii il primo a fondarne una.
          </li>
        )}
        {rows.map((r, i) => (
          <li
            key={r.team_id}
            className={`surface animate-pop-in flex items-center gap-3 p-4 ${
              r.team_id === team.data?.id ? "glow" : ""
            }`}
          >
            <span className="font-display w-9 text-center text-3xl">
              {MEDALS[i] ?? `#${i + 1}`}
            </span>
            <span
              className="grid size-11 shrink-0 place-items-center rounded-xl text-2xl"
              style={{ backgroundColor: (r.color ?? "#f97316") + "33" }}
            >
              {r.avatar_url ?? "🏳️"}
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-lg font-extrabold">{r.name}</p>
              <p className="truncate text-xs text-muted-foreground">
                {r.completed_challenges} prove · {formatDuration(r.total_duration_seconds)}
              </p>
            </div>
            <span className="font-display text-3xl text-gold">{r.total_points}</span>
          </li>
        ))}
      </ol>
    </AppShell>
  );
}
