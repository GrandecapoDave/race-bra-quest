import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { ChevronRight, Sparkles } from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import {
  challengesQuery,
  myTeamQuery,
  progressQuery,
  scoreEventsQuery,
  stagesQuery,
} from "@/lib/race";

export const Route = createFileRoute("/_authenticated/storico")({
  head: () => ({
    meta: [
      { title: "Storico attività — Pechino Express Bra" },
      {
        name: "description",
        content: "Riepilogo dei punti ottenuti, ordinato per tappa e per prova.",
      },
      { property: "og:title", content: "Storico attività — Pechino Express Bra" },
      { property: "og:description", content: "Ogni punto guadagnato, prova per prova." },
    ],
  }),
  component: StoricoPage,
});

function StoricoPage() {
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const team = useQuery(myTeamQuery);
  const stages = useQuery(stagesQuery);
  const challenges = useQuery(challengesQuery);
  const progress = useQuery({ ...progressQuery(team.data?.id), refetchInterval: 3000 });
  const events = useQuery({ ...scoreEventsQuery(team.data?.id), refetchInterval: 3000 });

  const all = challenges.data ?? [];
  const prog = progress.data ?? [];
  const evs = events.data ?? [];

  const matchEvents = (title: string) =>
    evs.filter((e) => e.reason.toLowerCase().includes(title.toLowerCase()));

  const usedIds = new Set<string>();
  const groups = (stages.data ?? []).map((stage) => {
    const rows = all
      .filter((c) => c.stage_id === stage.id)
      .sort((a, b) => a.order_index - b.order_index)
      .map((c) => {
        const p = prog.find((x) => x.challenge_id === c.id);
        const related = matchEvents(c.title);
        related.forEach((e) => usedIds.add(e.id));
        return {
          challenge: c,
          status: p?.status ?? "not_started",
          completedAt: p?.completed_at ?? null,
          points: related.reduce((s, e) => s + e.points, 0),
          events: related,
        };
      });
    return { stage, rows };
  });

  const others = evs.filter((e) => !usedIds.has(e.id));
  const total = evs.reduce((s, e) => s + e.points, 0);

  return (
    <AppShell isAdmin={isAdmin.data}>
      <h1 className="text-4xl leading-none">Storico attività</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Riepilogo ordinato per tappa e per prova · totale{" "}
        <span className="font-bold text-gold">{total} punti</span>
      </p>

      <div className="mt-5 space-y-5">
        {groups.map(({ stage, rows }) => (
          <section key={stage.id}>
            <div className="flex items-center justify-between">
              <h2 className="text-xl">
                Tappa {stage.order_index} · {stage.title}
              </h2>
              <Link
                to="/stage/$stageId"
                params={{ stageId: stage.id }}
                className="text-xs font-bold text-primary"
              >
                Apri <ChevronRight className="inline size-3" />
              </Link>
            </div>
            <ul className="mt-2 space-y-2">
              {rows.map((r) => (
                <li key={r.challenge.id} className="surface p-3.5">
                  <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-bold">
                        {r.challenge.order_index}. {r.challenge.title}
                      </p>
                      <p className="text-[11px] text-muted-foreground">
                        {r.status === "completed"
                          ? `Completata${r.completedAt ? ` il ${new Date(r.completedAt).toLocaleString("it-IT")}` : ""}`
                          : r.status === "in_progress"
                            ? "In corso"
                            : "Non iniziata"}
                      </p>
                    </div>
                    <span className="font-display text-2xl text-gold">
                      {r.points > 0 ? `+${r.points}` : r.points}
                    </span>
                  </div>
                  {r.events.length > 0 && (
                    <ul className="mt-2 space-y-1 border-t border-border/60 pt-2">
                      {r.events.map((e) => (
                        <li
                          key={e.id}
                          className="flex items-center justify-between gap-2 text-[11px] text-muted-foreground"
                        >
                          <span className="truncate">{e.reason}</span>
                          <span className="shrink-0 font-bold text-foreground">
                            {e.points > 0 ? `+${e.points}` : e.points}
                          </span>
                        </li>
                      ))}
                    </ul>
                  )}
                </li>
              ))}
            </ul>
          </section>
        ))}

        {others.length > 0 && (
          <section>
            <h2 className="flex items-center gap-2 text-xl">
              <Sparkles className="size-4 text-accent" /> Bonus e altri punti
            </h2>
            <ul className="mt-2 space-y-2">
              {others.map((e) => (
                <li key={e.id} className="surface flex items-center justify-between p-3.5">
                  <div className="min-w-0">
                    <p className="truncate text-sm font-semibold">{e.reason}</p>
                    <p className="text-[11px] text-muted-foreground">
                      {new Date(e.created_at).toLocaleString("it-IT")}
                    </p>
                  </div>
                  <span className="font-display text-2xl text-gold">
                    {e.points > 0 ? `+${e.points}` : e.points}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        )}

        {evs.length === 0 && (
          <p className="surface p-5 text-sm text-muted-foreground">
            Nessuna attività registrata: inizia la prima prova.
          </p>
        )}
      </div>
    </AppShell>
  );
}
