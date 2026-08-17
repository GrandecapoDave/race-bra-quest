import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Loader2 } from "lucide-react";
import { SocialSubmissionCard, useAdminContext } from "../admin";

export const Route = createFileRoute("/_authenticated/admin/social")({
  component: AdminSocialPage,
});

function AdminSocialPage() {
  const {
    allSocialSubmissions,
    allTeams,
    handleEvaluateSocial,
    isEvaluatingSocial
  } = useAdminContext();

  const [socialFilter, setSocialFilter] = useState<"submitted" | "approved" | "all">("submitted");

  return (
    <div className="space-y-6 animate-pop-in">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold uppercase tracking-wider text-muted-foreground pl-1">
            Valutazione Missioni Social
          </h2>
          <p className="text-xs text-muted-foreground pl-1 mt-0.5">
            Visualizza le foto scattate con i 2 sconosciuti ed assegna il punteggio (0–20 PT).
          </p>
        </div>

        {/* FILTER BUTTONS */}
        <div className="flex flex-wrap bg-zinc-900/80 p-1 rounded-xl border border-zinc-800/80 w-fit shrink-0 gap-1">
          {[
            { id: "submitted", label: "In Attesa" },
            { id: "approved", label: "Valutate" },
            { id: "all", label: "Tutte" }
          ].map((f) => {
            const count = (allSocialSubmissions.data ?? []).filter(
              (s: any) => f.id === "all" ? true : s.status === f.id
            ).length;
            return (
              <button
                key={f.id}
                onClick={() => setSocialFilter(f.id as any)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  socialFilter === f.id
                    ? "bg-primary text-primary-foreground shadow"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                {f.label} ({count})
              </button>
            );
          })}
        </div>
      </div>

      {allSocialSubmissions.isLoading ? (
        <div className="flex flex-col items-center justify-center py-10 space-y-3">
          <Loader2 className="size-6 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Caricamento sottomissioni social...</p>
        </div>
      ) : (() => {
        const list = allSocialSubmissions.data ?? [];
        const filteredList = list.filter((s: any) => {
          if (socialFilter === "all") return true;
          return s.status === socialFilter;
        });

        const teamsList = allTeams.data ?? [];
        if (teamsList.length === 0) {
          return (
            <p className="surface p-6 text-sm text-muted-foreground">
              Nessuna squadra registrata al momento.
            </p>
          );
        }

        if (filteredList.length === 0) {
          return (
            <p className="surface p-6 text-sm text-muted-foreground">
              Nessuna missione social trovata per questo filtro.
            </p>
          );
        }

        return (
          <div className="grid gap-6">
            {filteredList.map((submission: any) => {
              const teamObj = teamsList.find((t: any) => t.id === submission.team_id);
              if (!teamObj) return null;

              return (
                <SocialSubmissionCard
                  key={submission.id}
                  team={teamObj}
                  submission={submission}
                  onEvaluate={async (submissionId: string, voto: number) => {
                    await handleEvaluateSocial(submissionId, voto);
                  }}
                  isEvaluating={Boolean(isEvaluatingSocial[submission.id])}
                />
              );
            })}
          </div>
        );
      })()}
    </div>
  );
}

