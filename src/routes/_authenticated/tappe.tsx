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
      <div className="space-y-6">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-black tracking-widest text-primary uppercase bg-primary/15 border border-primary/30 px-2 py-0.5 rounded">
              Mappa di Gara
            </span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-display font-extrabold uppercase tracking-wide text-foreground mt-1">
            ITINERARIO TAPPE
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground font-semibold">
            Segui l'avanzamento della tua squadra lungo tutte le tappe di Pechino Express Bra.
          </p>
        </div>

        <div className="space-y-5">
          {(stages.data ?? []).map((stage, idx) => {
            const sc = all
              .filter((c) => c.stage_id === stage.id)
              .sort((a, b) => a.order_index - b.order_index);
            const done = sc.filter((c) => challengeState(c, sc, prog) === "completed").length;
            const isStageDone = sc.length > 0 && done === sc.length;
            const session = (sessions.data ?? []).find((s) => s.stage_id === stage.id);
            const unlocked = isStageUnlocked(stage, stages.data ?? [], all, prog);
            const isCurrent = unlocked && !isStageDone;

            return (
              <section
                key={stage.id}
                className={`p-5 rounded-2xl transition-all duration-300 ${
                  isCurrent
                    ? "hud-panel-glow"
                    : isStageDone
                    ? "hud-panel border-emerald-500/30 bg-emerald-950/15"
                    : "hud-panel opacity-60 border-dashed"
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 space-y-1">
                    <div className="flex items-center gap-2">
                      <span className={`text-[10px] font-black tracking-widest uppercase px-2 py-0.5 rounded ${
                        isStageDone
                          ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30"
                          : isCurrent
                          ? "bg-primary/20 text-primary border border-primary/40 animate-pulse"
                          : "bg-secondary text-muted-foreground"
                      }`}>
                        Tappa {stage.order_index} {isStageDone ? "✓ Completata" : isCurrent ? "★ In Corso" : "🔒 Bloccata"}
                      </span>
                    </div>
                    <h2 className="text-xl sm:text-2xl font-black text-foreground uppercase tracking-wide pt-0.5">
                      {stage.title}
                    </h2>
                  </div>

                  {unlocked ? (
                    <Link
                      to="/stage/$stageId"
                      params={{ stageId: stage.id }}
                      className="px-4 py-2 rounded-xl primary-gradient text-white text-xs font-black uppercase tracking-wider shadow-md hover:brightness-110 active:scale-95 transition-all shrink-0"
                    >
                      Apri →
                    </Link>
                  ) : (
                    <div className="flex items-center gap-1 text-xs font-bold text-muted-foreground uppercase tracking-wider bg-secondary/80 px-2.5 py-1.5 rounded-lg border border-border/40 shrink-0">
                      <Lock className="size-3.5" /> Bloccata
                    </div>
                  )}
                </div>

                <ProgressBar
                  value={sc.length ? (done / sc.length) * 100 : 0}
                  className={`mt-4 h-2.5 ${isStageDone ? "bg-emerald-500/20" : ""}`}
                />
                <div className="mt-2 flex items-center justify-between text-xs text-muted-foreground font-semibold">
                  <span>{done}/{sc.length} prove completate</span>
                  <span>{session?.duration_seconds ? `Tempo: ${formatDuration(session.duration_seconds)}` : "—"}</span>
                </div>

                {/* CHALLENGES MINI-LIST */}
                <div className="mt-4 space-y-2.5 pt-3 border-t border-border/40">
                  {sc.map((c) => {
                    const state = challengeState(c, sc, prog);
                    const cQs = qs
                      .filter((q) => q.challenge_id === c.id)
                      .sort((a, b) => a.order_index - b.order_index);
                    const cMedia = (media.data ?? []).filter((m) => m.challenge_id === c.id);

                    return (
                      <div key={c.id} className="rounded-xl bg-secondary/60 border border-border/40 p-3.5 space-y-2">
                        <div className="flex items-center justify-between gap-2">
                          <p className="truncate text-xs sm:text-sm font-bold text-foreground">
                            {c.order_index}. {c.title}
                          </p>
                          <span
                            className={`text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded ${
                              state === "completed"
                                ? "bg-emerald-500/20 text-emerald-300"
                                : state === "available"
                                ? "bg-primary/20 text-primary animate-pulse"
                                : "bg-zinc-800 text-muted-foreground"
                            }`}
                          >
                            {state === "completed"
                              ? "Fatta"
                              : state === "available"
                              ? "Attiva"
                              : "Bloccata"}
                          </span>
                        </div>

                        {cQs.length > 0 && (
                          <ul className="mt-1 space-y-1.5 pl-1">
                            {cQs.map((q) => {
                              const a = ans.find((x) => x.question_id === q.id);
                              return (
                                <li key={q.id} className="text-xs">
                                  <p className="font-semibold text-muted-foreground">{q.question}</p>
                                  {a ? (
                                    <p
                                      className={`mt-0.5 flex items-center gap-1 font-bold ${
                                        a.correct ? "text-emerald-400" : "text-rose-400"
                                      }`}
                                    >
                                      {a.correct ? (
                                        <Check className="size-3.5 stroke-[3]" />
                                      ) : (
                                        <X className="size-3.5 stroke-[3]" />
                                      )}
                                      {q.options[a.selected_answer] ?? "—"}
                                    </p>
                                  ) : (
                                    <p className="mt-0.5 text-[11px] text-muted-foreground/70 italic">
                                      Nessuna risposta data
                                    </p>
                                  )}
                                </li>
                              );
                            })}
                          </ul>
                        )}

                        {cMedia.length > 0 && (
                          <div className="mt-1 flex flex-wrap gap-2 text-[11px] text-muted-foreground font-semibold">
                            {cMedia.map((m) => (
                              <div key={m.id} className="bg-secondary/80 px-2 py-0.5 rounded border border-border/30">
                                📸 {new Date(m.created_at).toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })}
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
      </div>
    </AppShell>
  );
}
