import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Loader2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { CornholeChallenge } from "@/components/challenges/CornholeChallenge";
import { toast } from "sonner";

const CORNHOLE_CHALLENGE_ID = "c5c5c5c5-d6d6-e7e7-f8f8-a9a9a0a0a0a0";

export const Route = createFileRoute("/_authenticated/admin/cornhole")({
  component: AdminCornholePage,
});

function AdminCornholePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [isClosing, setIsClosing] = useState(false);

  // Fetch challenge detail
  const { data: challenge, isLoading: loadingChallenge } = useQuery({
    queryKey: ["challenge_detail_cornhole"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("challenges")
        .select("*")
        .eq("id", CORNHOLE_CHALLENGE_ID)
        .single();
      if (error) throw error;
      return data;
    }
  });

  // Fetch progress of any team to check if already marked completed globally
  const { data: progressList, refetch: refetchProgress } = useQuery({
    queryKey: ["challenge_progress_cornhole"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("team_progress")
        .select("*")
        .eq("challenge_id", CORNHOLE_CHALLENGE_ID);
      if (error) throw error;
      return data || [];
    }
  });

  const isCompleted = progressList && progressList.length > 0 && progressList.every((p: any) => p.stato === "completed");

  const handleTournamentRefresh = async () => {
    try {
      await queryClient.invalidateQueries();
      await refetchProgress();
    } catch (e: any) {
      console.error(e);
    }
  };

  if (loadingChallenge) {
    return (
      <div className="flex flex-col items-center justify-center py-12 gap-3 min-h-[50vh]">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Caricamento configurazione sfida...</p>
      </div>
    );
  }

  if (!challenge) {
    return (
      <div className="text-center py-12 text-destructive">
        Sfida Cornhole non trovata nel database.
      </div>
    );
  }

  return (
    <div className="p-4 sm:p-6 space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-border/10 pb-4">
        <div>
          <h1 className="text-2xl font-display font-black uppercase tracking-wider text-foreground">
            Gestione Torneo Cornhole
          </h1>
          <p className="text-xs text-muted-foreground mt-0.5">
            Regia console per la Tappa 5 - Sfida 5.1
          </p>
        </div>
        <button
          onClick={() => navigate({ to: "/admin" })}
          className="self-start sm:self-auto inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-semibold bg-white/5 hover:bg-white/10 text-muted-foreground hover:text-foreground border border-white/10 transition-colors"
        >
          ← Torna alla Panoramica
        </button>
      </div>

      <CornholeChallenge
        challenge={challenge}
        team={null}
        completed={isCompleted}
        onComplete={handleTournamentRefresh}
        completing={false}
      />
    </div>
  );
}
