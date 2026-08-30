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
        base_points?: number;
        multiplier_2x_bonus?: number;
        dimezza_penalty?: number;
        polizza_refund?: number;
        bonus?: number;
        stage_completed: boolean;
        stage_reward?: number;
        stage_position?: number;
        cattiveria_delta?: number;
      };
    },
    retry: 2,
    onSuccess: async (result) => {
      if (result && !result.already) {
        if (result.multiplier_2x_bonus && result.multiplier_2x_bonus > 0) {
          toast.success(`✨ Moltiplicatore 2X Applicato! Punteggio raddoppiato (+${result.multiplier_2x_bonus} PT extra)!`, {
            duration: 6000,
          });
        }
        if (result.dimezza_penalty && result.dimezza_penalty > 0) {
          toast.error(`⚠️ Malus Dimezza Punti subito: Punteggio prova dimezzato (-${result.dimezza_penalty} PT)!`, {
            duration: 6000,
          });
        }
        if (result.polizza_refund && result.polizza_refund > 0) {
          toast.success(`🛡️ Polizza Diretta attivata! Rimborso del 50% del malus (+${result.polizza_refund} PT)!`, {
            duration: 6000,
          });
        }

        toast.success(`Prova completata! +${result.points ?? 0} punti`);
        if (result.bonus && result.bonus > 0) {
          toast.success(`Bonus arrivo tappa: +${result.bonus} punti`);
        }
        if (result.stage_completed && result.stage_reward && result.stage_reward > 0) {
          const medals = ["🥇", "🥈", "🥉"];
          const pos = result.stage_position ?? 1;
          const medal = medals[pos - 1] || `${pos}°`;
          const placementText = pos === 1 ? "Hai completato la tappa per primo!" : `Posizione di arrivo: ${pos}°`;
          toast.success(
            `${medal} ${pos}° POSTO IN TAPPA!\n${placementText}\n+${result.stage_reward} Token accreditati! 🪙`,
            { duration: 8000 }
          );
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
