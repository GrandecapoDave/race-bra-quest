import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { ApprovalCard, useAdminContext } from "../admin";

export const Route = createFileRoute("/_authenticated/admin/photos")({
  component: AdminPhotosPage,
});

function AdminPhotosPage() {
  const {
    allSubmissions,
    allProgress,
    allScores,
    handleConfirmPhotoScore,
    isConfirmingScore
  } = useAdminContext();

  const [photoFilter, setPhotoFilter] = useState<"pending" | "confirmed">("pending");

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold uppercase tracking-wider text-muted-foreground pl-1">
            Gestione Punteggi Foto
          </h2>
          <p className="text-xs text-muted-foreground pl-1 mt-0.5">
            Le squadre hanno già proseguito dopo il caricamento. Qui puoi visualizzare le foto e modificare il punteggio assegnato.
          </p>
        </div>

        {/* FILTER BUTTONS */}
        <div className="flex bg-zinc-900/80 p-1 rounded-xl border border-zinc-800/80 w-fit shrink-0 self-start sm:self-auto">
          <button
            onClick={() => setPhotoFilter("pending")}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              photoFilter === "pending"
                ? "bg-primary text-primary-foreground shadow"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Da Valutare ({
              (allSubmissions.data ?? []).filter(
                (s: any) => (s.stato_approvazione === "auto_approved" || s.stato_approvazione === "pending") && s.challenges?.tipo_sfida === "photo"
              ).length
            })
          </button>
          <button
            onClick={() => setPhotoFilter("confirmed")}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              photoFilter === "confirmed"
                ? "bg-primary text-primary-foreground shadow"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Già Valutate ({
              (allSubmissions.data ?? []).filter(
                (s: any) => s.stato_approvazione === "confirmed" && s.challenges?.tipo_sfida === "photo"
              ).length
            })
          </button>
        </div>
      </div>

      {(() => {
        const filteredSubmissions = (allSubmissions.data ?? []).filter(
          (s: any) => {
            if (s.challenges?.tipo_sfida !== "photo") return false;
            if (photoFilter === "pending") return s.stato_approvazione === "auto_approved" || s.stato_approvazione === "pending";
            return s.stato_approvazione === "confirmed";
          }
        );

        if (filteredSubmissions.length === 0) {
          return (
            <p className="surface p-6 text-sm text-muted-foreground">
              Nessuna sottomissione fotografica trovata in questo stato.
            </p>
          );
        }

        return (
          <div className="grid gap-4">
            {filteredSubmissions.map((sub: any) => (
              <ApprovalCard
                key={sub.id}
                sub={sub}
                progress={allProgress.data || []}
                scores={allScores.data || []}
                onConfirmScore={async (points: number) => {
                  await handleConfirmPhotoScore(sub.id, points);
                }}
                isConfirming={Boolean(isConfirmingScore[sub.id])}
              />
            ))}
          </div>
        );
      })()}
    </div>
  );
}
