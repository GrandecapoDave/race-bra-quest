import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";

export function useCompleteChallenge() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (challengeId: string) => {
      const { data, error } = await supabase.rpc("complete_challenge", {
        p_challenge: challengeId,
      });
      if (error) throw new Error(error.message);
      return data as unknown as {
        already: boolean;
        points: number;
        bonus: number;
        stage_completed: boolean;
        stage_reward?: number;
      };
    },
    retry: 2,
    onSuccess: async (result) => {
      if (result && !result.already) {
        toast.success(`Prova completata! +${result.points ?? 0} punti`);
        if (result.bonus && result.bonus > 0) toast.success(`Bonus arrivo tappa: +${result.bonus} punti`);
        if (result.stage_completed && result.stage_reward && result.stage_reward > 0) {
          toast.success(`🏁 Tappa Completata! Hai guadagnato +${result.stage_reward} Token! 🪙`);
        }
      }
      await queryClient.invalidateQueries();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Errore di salvataggio"),
  });
}

export function useStartChallenge() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (challengeId: string) => {
      const { error } = await supabase.rpc("start_challenge", { p_challenge: challengeId });
      if (error) throw new Error(error.message);
    },
    retry: 2,
    onSuccess: () => queryClient.invalidateQueries(),
  });
}
