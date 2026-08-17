import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Check, Lock, MapPin, Play } from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { ProgressBar } from "@/components/ProgressBar";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import {
  challengeState,
  challengesQuery,
  myTeamQuery,
  progressQuery,
  stagesQuery,
  isStageUnlocked,
} from "@/lib/race";

export const Route = createFileRoute("/_authenticated/stage/$stageId")({
  head: () => ({
    meta: [
      { title: "Tappa — Pechino Express Bra" },
      { name: "description", content: "Le prove della tappa, sbloccate progressivamente." },
      { property: "og:title", content: "Tappa — Pechino Express Bra" },
      { property: "og:description", content: "Supera le prove per sbloccare la successiva." },
    ],
  }),
  component: StagePage,
});

function StagePage() {
  const { stageId } = Route.useParams();
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const stages = useQuery(stagesQuery);
  const challenges = useQuery(challengesQuery);
  const team = useQuery(myTeamQuery);
  const progress = useQuery(progressQuery(team.data?.id));

  const stage = (stages.data ?? []).find((s) => s.id === stageId);
  const stageChallenges = (challenges.data ?? []).filter((c) => c.stage_id === stageId);
  const prog = progress.data ?? [];
  const done = stageChallenges.filter((c) => challengeState(c, stageChallenges, prog) === "completed");

  const unlocked = stage ? isStageUnlocked(stage, stages.data ?? [], challenges.data ?? [], prog) : true;

  if (!unlocked && !isAdmin.data) {
    return (
      <AppShell isAdmin={isAdmin.data}>
        <div className="max-w-md mx-auto text-center space-y-6 py-12">
          <div className="inline-flex size-20 items-center justify-center rounded-3xl bg-destructive/10 border border-destructive/20 text-destructive animate-pulse">
            <Lock className="size-10" />
          </div>
          <div className="space-y-2">
            <h1 className="text-3xl font-display font-black uppercase tracking-wider text-foreground">
              Tappa Bloccata
            </h1>
            <p className="text-sm text-muted-foreground">
              Questa tappa è accessibile esclusivamente dopo il completamento di tutte le prove della tappa precedente.
            </p>
          </div>
          <Link
            to="/dashboard"
            className="primary-gradient glow inline-flex items-center gap-2 rounded-xl px-6 py-3 font-extrabold text-primary-foreground text-sm"
          >
            Torna alla Dashboard
          </Link>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell isAdmin={isAdmin.data}>
      <Link to="/dashboard" className="text-xs font-bold tracking-widest text-primary uppercase">
        ← Dashboard
      </Link>
      <p className="mt-4 text-xs font-bold tracking-widest text-accent uppercase">
        Tappa {stage?.order_index}
      </p>
      <h1 className="mt-1 text-5xl leading-none">{stage?.title ?? "Tappa"}</h1>
      <ProgressBar
        value={stageChallenges.length ? (done.length / stageChallenges.length) * 100 : 0}
        className="mt-4"
      />

      <div className="mt-5 space-y-3">
        {stageChallenges.map((c, i) => {
          const state = challengeState(c, stageChallenges, prog);
          const isJackpot = c.type === "jackpot";

          const circleColorClass = state === "completed"
            ? "bg-success/20 text-success"
            : state === "available"
              ? isJackpot
                ? "bg-gradient-to-r from-purple-600 to-indigo-600 text-white border border-purple-500/40 shadow-lg shadow-purple-950/20"
                : "primary-gradient text-primary-foreground"
              : "bg-muted text-muted-foreground";

          const content = (
            <div className="flex items-center gap-4">
              <span
                className={`grid size-11 shrink-0 place-items-center rounded-xl font-display text-2xl ${circleColorClass}`}
              >
                {state === "completed" ? (
                  <Check className="size-5" />
                ) : state === "locked" ? (
                  <Lock className="size-4" />
                ) : isJackpot ? (
                  "🎰"
                ) : (
                  i + 1
                )}
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 flex-wrap">
                  <p className="text-lg font-extrabold">{c.title}</p>
                  {isJackpot && (
                    <span className="bg-purple-950/40 border border-purple-500/30 text-purple-400 text-[9px] font-black uppercase px-2 py-0.5 rounded-full">
                      Facoltativa
                    </span>
                  )}
                </div>
                <p className="truncate text-sm text-muted-foreground">{c.description}</p>
                {isJackpot ? (
                  <p className="text-[10px] font-black text-purple-400 uppercase tracking-wider mt-0.5">Scommessa Bonus</p>
                ) : (
                  <p className="text-xs font-bold text-gold">{c.points} punti</p>
                )}
              </div>
              {state === "available" && <Play className="size-5 text-primary" />}
            </div>
          );

          return state === "locked" ? (
            <div key={c.id} className="surface p-4 opacity-50">
              {content}
            </div>
          ) : (
            <Link
              key={c.id}
              to="/challenge/$challengeId"
              params={{ challengeId: c.id }}
              className="surface block p-4 transition-transform hover:scale-[1.01]"
            >
              {content}
            </Link>
          );
        })}
      </div>
    </AppShell>
  );
}
