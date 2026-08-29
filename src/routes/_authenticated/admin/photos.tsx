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
      const type = s.challenges?.tipo_sfida;
      return type === "photo" || type === "living_poster" || Boolean(s.file_upload);
    });
  }, [allSubmissions.data]);

  // Derived available challenges based on selected stage
  const availableChallenges = useMemo(() => {
    const challengesList = (challenges.data ?? []) as any[];
    if (selectedStageId === "all") {
      return challengesList.filter((c: any) => c.tipo_sfida === "photo" || c.tipo_sfida === "living_poster");
    }
    return challengesList.filter((c: any) => c.stage_id === selectedStageId && (c.tipo_sfida === "photo" || c.tipo_sfida === "living_poster"));
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

        {/* STATUS TABS (HeroUI Pill Tabs with Badge) */}
        <div className="flex bg-zinc-900/90 p-1.5 rounded-2xl border border-zinc-800/80 w-fit shrink-0 self-start md:self-auto gap-1.5 shadow-lg backdrop-blur-md">
          <button
            onClick={() => setPhotoFilter("pending")}
            className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 ${
              photoFilter === "pending"
                ? "bg-primary text-primary-foreground shadow-lg shadow-primary/30 scale-[1.02]"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <Clock className="size-3.5" />
            <span>Da Valutare</span>
            <Badge
              color={photoFilter === "pending" ? "default" : "warning"}
              variant="solid"
              size="sm"
              className="bg-black/30 text-white font-bold"
            >
              {pendingCount}
            </Badge>
          </button>
          <button
            onClick={() => setPhotoFilter("confirmed")}
            className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 ${
              photoFilter === "confirmed"
                ? "bg-emerald-500 text-black shadow-lg shadow-emerald-500/30 scale-[1.02]"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <CheckCircle className="size-3.5" />
            <span>Confermate</span>
            <Badge
              color="success"
              variant="solid"
              size="sm"
              className="bg-black/30 text-white font-bold"
            >
              {confirmedCount}
            </Badge>
          </button>
          <button
            onClick={() => setPhotoFilter("all")}
            className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 ${
              photoFilter === "all"
                ? "bg-zinc-800 text-white shadow-md scale-[1.02]"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <span>Tutte</span>
            <Badge
              color="default"
              variant="solid"
              size="sm"
              className="bg-black/30 text-white font-bold"
            >
              {allPhotoSubmissions.length}
            </Badge>
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
