import { createFileRoute } from "@tanstack/react-router";
import { useState, useMemo } from "react";
import { Camera, CheckCircle, Clock, Filter, Image as ImageIcon, Layers } from "lucide-react";
import { ApprovalCard, useAdminContext } from "../admin";
import { Badge } from "@/components/ui/badge";

export const Route = createFileRoute("/_authenticated/admin/photos")({
  component: AdminPhotosPage,
});

function AdminPhotosPage() {
  const {
    allSubmissions,
    allProgress,
    allScores,
    stages,
    challenges,
    handleConfirmPhotoScore,
    isConfirmingScore
  } = useAdminContext();

  const [photoFilter, setPhotoFilter] = useState<"pending" | "confirmed" | "all">("pending");
  const [selectedStageId, setSelectedStageId] = useState<string>("all");
  const [selectedChallengeId, setSelectedChallengeId] = useState<string>("all");

  const stagesList = (stages.data ?? []) as any[];

  const allPhotoSubmissions = useMemo(() => {
    const rawSubmissions = (allSubmissions.data ?? []) as any[];
    return rawSubmissions.filter((s: any) => {
      const type = s.challenges?.tipo_sfida || s.tipo;
      const isLivingPoster =
        type === "living_poster" ||
        s.challenge_id === "555f4e1f-7443-42e7-9d7a-115f2122888f" ||
        (s.challenges?.titolo || "").toLowerCase().includes("locandina") ||
        (s.note || "").toLowerCase().includes("locandina");
      const isSocial =
        type === "social" ||
        s.challenge_id === "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0" ||
        (s.challenges?.titolo || "").toLowerCase().includes("social");

      if (isLivingPoster || isSocial) return false;
      return type === "photo" || Boolean(s.file_upload);
    });
  }, [allSubmissions.data]);

  // Derived available challenges based on selected stage
  const availableChallenges = useMemo(() => {
    const challengesList = (challenges.data ?? []) as any[];
    return challengesList.filter((c: any) => {
      if (c.tipo_sfida !== "photo") return false;
      if (c.id === "555f4e1f-7443-42e7-9d7a-115f2122888f" || (c.titolo || "").toLowerCase().includes("locandina")) return false;
      if (c.id === "f5f5f5f5-a6a6-47e7-b8b8-c9c9c0c0c0c0" || (c.titolo || "").toLowerCase().includes("social")) return false;
      if (selectedStageId !== "all" && c.stage_id !== selectedStageId) return false;
      return true;
    });
  }, [challenges.data, selectedStageId]);

  // Filtered submissions based on status, stage, challenge
  const filteredSubmissions = useMemo(() => {
    return allPhotoSubmissions.filter((s: any) => {
      // Status filter
      const isConfirmed = s.stato_approvazione === "confirmed";
      if (photoFilter === "pending" && isConfirmed) return false;
      if (photoFilter === "confirmed" && !isConfirmed) return false;

      // Stage filter
      if (selectedStageId !== "all") {
        const stageId = s.challenges?.stage_id || s.challenges?.stages?.id;
        if (stageId !== selectedStageId) return false;
      }

      // Challenge filter
      if (selectedChallengeId !== "all") {
        if (s.challenge_id !== selectedChallengeId) return false;
      }

      return true;
    });
  }, [allPhotoSubmissions, photoFilter, selectedStageId, selectedChallengeId]);

  const pendingCount = allPhotoSubmissions.filter((s: any) => s.stato_approvazione !== "confirmed").length;
  const confirmedCount = allPhotoSubmissions.filter((s: any) => s.stato_approvazione === "confirmed").length;

  return (
    <div className="space-y-6 animate-pop-in">
      {/* HEADER */}
      <div className="flex flex-col md:flex-row justify-between md:items-center gap-4 bg-zinc-950/60 p-5 rounded-2xl border border-border/40 shadow-lg">
        <div>
          <div className="flex items-center gap-2">
            <Camera className="size-5 text-primary" />
            <h2 className="text-xl font-black uppercase tracking-wider text-foreground">
              Foto Ricevute dalle Squadre
            </h2>
          </div>
          <p className="text-xs text-muted-foreground mt-1">
            Visualizza, filtra e valuta tutte le fotografie consegnate dalle squadre per ciascuna tappa e sfida.
          </p>
        </div>

        {/* STATUS TABS */}
        <div className="flex flex-wrap sm:flex-nowrap bg-zinc-900/90 p-1.5 rounded-2xl border border-zinc-800/80 w-full sm:w-auto shrink-0 gap-1.5 shadow-lg backdrop-blur-md">
          <button
            onClick={() => setPhotoFilter("pending")}
            className={`flex-1 sm:flex-none px-3.5 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer flex items-center justify-center gap-2 whitespace-nowrap ${
              photoFilter === "pending"
                ? "bg-primary text-primary-foreground shadow-lg shadow-primary/30 scale-[1.02]"
                : "text-muted-foreground hover:text-foreground hover:bg-zinc-800/50"
            }`}
          >
            <Clock className="size-3.5 shrink-0" />
            <span>Da Valutare</span>
            <span className="px-2 py-0.5 rounded-full bg-black/40 text-[11px] font-mono font-bold text-white leading-none shrink-0 min-w-[20px] text-center">
              {pendingCount}
            </span>
          </button>
          <button
            onClick={() => setPhotoFilter("confirmed")}
            className={`flex-1 sm:flex-none px-3.5 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer flex items-center justify-center gap-2 whitespace-nowrap ${
              photoFilter === "confirmed"
                ? "bg-emerald-500 text-black shadow-lg shadow-emerald-500/30 scale-[1.02]"
                : "text-muted-foreground hover:text-foreground hover:bg-zinc-800/50"
            }`}
          >
            <CheckCircle className="size-3.5 shrink-0" />
            <span>Confermate</span>
            <span className="px-2 py-0.5 rounded-full bg-black/40 text-[11px] font-mono font-bold text-white leading-none shrink-0 min-w-[20px] text-center">
              {confirmedCount}
            </span>
          </button>
          <button
            onClick={() => setPhotoFilter("all")}
            className={`flex-1 sm:flex-none px-3.5 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer flex items-center justify-center gap-2 whitespace-nowrap ${
              photoFilter === "all"
                ? "bg-zinc-800 text-white shadow-md scale-[1.02]"
                : "text-muted-foreground hover:text-foreground hover:bg-zinc-800/50"
            }`}
          >
            <ImageIcon className="size-3.5 shrink-0" />
            <span>Tutte</span>
            <span className="px-2 py-0.5 rounded-full bg-black/40 text-[11px] font-mono font-bold text-white leading-none shrink-0 min-w-[20px] text-center">
              {allPhotoSubmissions.length}
            </span>
          </button>
        </div>
      </div>

      {/* FILTER CONTROLS (TAPPA & SFIDA) */}
      <div className="flex flex-wrap items-center gap-3 bg-zinc-900/40 p-4 rounded-xl border border-zinc-800/60">
        <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-zinc-400">
          <Filter className="size-3.5 text-primary" /> Filtra:
        </div>

        {/* TAPPA FILTER */}
        <div className="flex items-center gap-1.5">
          <Layers className="size-3.5 text-zinc-500" />
          <select
            value={selectedStageId}
            onChange={(e) => {
              setSelectedStageId(e.target.value);
              setSelectedChallengeId("all");
            }}
            className="bg-zinc-950 border border-zinc-800 text-xs font-bold rounded-lg px-3 py-1.5 text-foreground focus:outline-none focus:border-primary"
          >
            <option value="all">Tutte le Tappe</option>
            {stagesList.map((st: any) => (
              <option key={st.id} value={st.id}>
                Tappa {st.numero_tappa || st.ordine}: {st.titolo || st.nome_tappa}
              </option>
            ))}
          </select>
        </div>

        {/* SFIDA FILTER */}
        <div className="flex items-center gap-1.5">
          <Camera className="size-3.5 text-zinc-500" />
          <select
            value={selectedChallengeId}
            onChange={(e) => setSelectedChallengeId(e.target.value)}
            className="bg-zinc-950 border border-zinc-800 text-xs font-bold rounded-lg px-3 py-1.5 text-foreground focus:outline-none focus:border-primary"
          >
            <option value="all">Tutte le Sfide Foto</option>
            {availableChallenges.map((c: any) => (
              <option key={c.id} value={c.id}>
                {c.titolo} ({c.tipo_sfida === "living_poster" ? "Locandina" : "Foto"})
              </option>
            ))}
          </select>
        </div>

        {(selectedStageId !== "all" || selectedChallengeId !== "all") && (
          <button
            onClick={() => {
              setSelectedStageId("all");
              setSelectedChallengeId("all");
            }}
            className="text-[11px] font-bold text-primary hover:underline ml-auto cursor-pointer"
          >
            Azzera Filtri
          </button>
        )}
      </div>

      {/* SUBMISSION LIST */}
      {filteredSubmissions.length === 0 ? (
        <div className="surface p-12 text-center space-y-3 rounded-2xl border border-zinc-800/40">
          <Camera className="size-10 text-zinc-600 mx-auto animate-pulse" />
          <h3 className="text-sm font-bold text-zinc-300 uppercase tracking-wider">
            Nessuna Foto Trovata
          </h3>
          <p className="text-xs text-muted-foreground max-w-md mx-auto">
            Non ci sono consegne fotografiche per i criteri di filtro selezionati.
          </p>
        </div>
      ) : (
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
      )}
    </div>
  );
}
