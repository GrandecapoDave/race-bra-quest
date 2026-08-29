import { createFileRoute } from "@tanstack/react-router";
import { Loader2 } from "lucide-react";
import { PosterComparisonCard, useAdminContext } from "../admin";

export const Route = createFileRoute("/_authenticated/admin/posters")({
  component: AdminPostersPage,
});

function AdminPostersPage() {
  const {
    allPosters,
    allTeamPosters,
    allSubmissions,
    allTeams,
    handleEvaluatePoster,
    isEvaluating
  } = useAdminContext();

  return (
    <div className="space-y-6 animate-pop-in">
      <div>
        <h2 className="text-xl font-bold uppercase tracking-wider text-muted-foreground pl-1">
          Valutazione Locandine Viventi
        </h2>
        <p className="text-xs text-muted-foreground pl-1 mt-0.5">
          Confronta le foto originali dei poster con gli scatti inviati dalle squadre ed assegna da 0 a 15 punti.
        </p>
      </div>

      {allPosters.isLoading || allTeamPosters.isLoading ? (
        <div className="flex flex-col items-center justify-center py-10 space-y-3">
          <Loader2 className="size-6 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Caricamento locandine...</p>
        </div>
      ) : (() => {
        const livingPosterSubmissions = (allSubmissions.data ?? []).filter(
          (sub: any) =>
            sub.challenge_id === "555f4e1f-7443-42e7-9d7a-115f2122888f" ||
            sub.challenges?.tipo_sfida === "living_poster" ||
            sub.tipo === "living_poster" ||
            (sub.challenges?.titolo || "").toLowerCase().includes("locandina")
        );

        const teamsList = allTeams.data ?? [];
        if (teamsList.length === 0) {
          return (
            <p className="surface p-6 text-sm text-muted-foreground">
              Nessuna squadra registrata al momento.
            </p>
          );
        }

        return (
          <div className="grid gap-6">
            {teamsList.map((t: any) => {
              const posterAssignment = (allTeamPosters.data ?? []).find(
                (tp: any) => tp.team_id === t.id
              );
              const poster = posterAssignment
                ? (allPosters.data ?? []).find((p: any) => p.id === posterAssignment.poster_id)
                : null;
              const submission = livingPosterSubmissions.find(
                (sub: any) => sub.team_id === t.id
              );

              return (
                <PosterComparisonCard
                  key={t.id}
                  team={t}
                  poster={poster}
                  submission={submission}
                  onEvaluate={async (submissionId: string, voto: number) => {
                    await handleEvaluatePoster(submissionId, voto);
                  }}
                  isEvaluating={Boolean(isEvaluating[submission?.id || ""])}
                />
              );
            })}
          </div>
        );
      })()}
    </div>
  );
}
