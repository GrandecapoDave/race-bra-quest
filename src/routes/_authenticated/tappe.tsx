import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Check, MapPin, X, Lock } from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { ProgressBar } from "@/components/ProgressBar";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import {
  allQuestionsQuery,
  answersQuery,
  challengeState,
  challengesQuery,
  formatDuration,
  mediaQuery,
  myTeamQuery,
  progressQuery,
  sessionsQuery,
  stagesQuery,
  isStageUnlocked,
} from "@/lib/race";

export const Route = createFileRoute("/_authenticated/tappe")({
  head: () => ({
    meta: [
      { title: "Riepilogo tappe — Pechino Express Bra" },
      {
        name: "description",
        content: "Rivedi tappe, prove completate, risposte date e foto caricate.",
      },
      { property: "og:title", content: "Riepilogo tappe — Pechino Express Bra" },
      { property: "og:description", content: "Tutto quello che la tua squadra ha fatto." },
    ],
  }),
  component: TappePage,
});

function TappePage() {
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const team = useQuery(myTeamQuery);
  const stages = useQuery(stagesQuery);
  const challenges = useQuery(challengesQuery);
  const progress = useQuery(progressQuery(team.data?.id));
  const answers = useQuery(answersQuery(team.data?.id));
  const questions = useQuery(allQuestionsQuery);
  const media = useQuery(mediaQuery(team.data?.id));
  const sessions = useQuery(sessionsQuery(team.data?.id));

  const all = challenges.data ?? [];
  const prog = progress.data ?? [];
  const qs = questions.data ?? [];
  const ans = answers.data ?? [];

  return (
    <AppShell isAdmin={isAdmin.data}>
      <h1 className="text-4xl leading-none">Tappe</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Cosa hai fatto in ogni tappa: prove, risposte date e foto.
      </p>

      <div className="mt-5 space-y-5">
        {(stages.data ?? []).map((stage) => {
          const sc = all
            .filter((c) => c.stage_id === stage.id)
            .sort((a, b) => a.order_index - b.order_index);
          const done = sc.filter((c) => challengeState(c, sc, prog) === "completed").length;
          const session = (sessions.data ?? []).find((s) => s.stage_id === stage.id);
          const unlocked = isStageUnlocked(stage, stages.data ?? [], all, prog);

          return (
            <section key={stage.id} className={`surface p-4 transition-opacity ${!unlocked ? "opacity-50 border-dashed" : ""}`}>
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-xs font-bold tracking-widest text-accent uppercase flex items-center gap-1.5">
                    Tappa {stage.order_index} {!unlocked && <Lock className="size-3 text-muted-foreground" />}
                  </p>
                  <h2 className="text-2xl leading-tight">{stage.title}</h2>
                </div>
                {unlocked ? (
                  <Link
                    to="/stage/$stageId"
                    params={{ stageId: stage.id }}
                    className="shrink-0 text-xs font-bold text-primary hover:underline"
                  >
                    Vai →
                  </Link>
                ) : (
                  <div className="flex items-center gap-1 text-xs font-bold text-muted-foreground uppercase tracking-wider bg-secondary/50 px-2 py-1 rounded">
                    <Lock className="size-3" /> Bloccata
                  </div>
                )}
              </div>

              <ProgressBar value={sc.length ? (done / sc.length) * 100 : 0} className="mt-3" />
              <p className="mt-1 text-xs text-muted-foreground">
                {done}/{sc.length} prove · durata {formatDuration(session?.duration_seconds ?? null)}
              </p>

              <div className="mt-4 space-y-3">
                {sc.map((c) => {
                  const state = challengeState(c, sc, prog);
                  const cQs = qs
                    .filter((q) => q.challenge_id === c.id)
                    .sort((a, b) => a.order_index - b.order_index);
                  const cMedia = (media.data ?? []).filter((m) => m.challenge_id === c.id);

                  return (
                    <div key={c.id} className="rounded-xl bg-secondary/50 p-3">
                      <div className="flex items-center justify-between gap-2">
                        <p className="truncate text-sm font-bold">
                          {c.order_index}. {c.title}
                        </p>
                        <span
                          className={`text-[11px] font-bold ${
                            state === "completed"
                              ? "text-success"
                              : state === "available"
                                ? "text-primary"
                                : "text-muted-foreground"
                          }`}
                        >
                          {state === "completed"
                            ? "Completata"
                            : state === "available"
                              ? "Disponibile"
                              : "Bloccata"}
                        </span>
                      </div>

                      {cQs.length > 0 && (
                        <ul className="mt-2 space-y-2">
                          {cQs.map((q) => {
                            const a = ans.find((x) => x.question_id === q.id);
                            return (
                              <li key={q.id} className="text-xs">
                                <p className="font-semibold">{q.question}</p>
                                {a ? (
                                  <p
                                    className={`mt-0.5 flex items-center gap-1 ${
                                      a.correct ? "text-success" : "text-destructive"
                                    }`}
                                  >
                                    {a.correct ? (
                                      <Check className="size-3" />
                                    ) : (
                                      <X className="size-3" />
                                    )}
                                    {q.options[a.selected_answer] ?? "—"}
                                  </p>
                                ) : (
                                  <p className="mt-0.5 text-muted-foreground">
                                    Nessuna risposta data
                                  </p>
                                )}
                              </li>
                            );
                          })}
                        </ul>
                      )}

                      {cMedia.length > 0 && (
                        <div className="mt-2 flex flex-wrap gap-2">
                          {cMedia.map((m) => (
                            <div key={m.id} className="text-[11px] text-muted-foreground">
                              📸 {new Date(m.created_at).toLocaleString("it-IT")}
                              {m.latitude != null && m.longitude != null && (
                                <> · {m.latitude.toFixed(4)}, {m.longitude.toFixed(4)}</>
                              )}
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </section>
          );
        })}
      </div>
    </AppShell>
  );
}
