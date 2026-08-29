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
        let earnedPoints = result.points ?? 0;

        try {
          const { data: teamIdData } = await supabase.rpc("current_team_id");
          const teamId = teamIdData || queryClient.getQueryData<any>(["my-team"])?.id;

          if (teamId) {
            // 1. Check for Active Moltiplicatore 2X
            const { data: active2x } = await (supabase as any)
              .from("marketplace_transactions")
              .select("*")
              .eq("team_id", teamId)
              .eq("marketplace_item_id", "moltiplicatore_2x")
              .eq("stato", "completed")
              .maybeSingle();

            if (active2x) {
              const bonus2x = earnedPoints;
              if (bonus2x > 0) {
                await (supabase as any).from("scores").insert({
                  team_id: teamId,
                  punti: bonus2x,
                  tipo_modificatore: "bonus_moltiplicatore_2x",
                  motivo: "Moltiplicatore 2X Tappa (Raddoppio Punti +2X)",
                });
                toast.success(`✨ Moltiplicatore 2X Applicato! Punteggio raddoppiato (+${bonus2x} PT extra)!`, {
                  duration: 6000,
                });
              }
              await (supabase as any)
                .from("marketplace_transactions")
                .update({ stato: "used", data_utilizzo: new Date().toISOString() })
                .eq("id", active2x.id);
            }

            // 2. Check for Received Dimezza Punti Malus
            const { data: activeDimezza } = await (supabase as any)
              .from("marketplace_transactions")
              .select("*")
              .eq("target_team_id", teamId)
              .eq("marketplace_item_id", "dimezza_punti")
              .eq("stato", "completed")
              .maybeSingle();

            if (activeDimezza) {
              const penalty = Math.floor(earnedPoints / 2);
              if (penalty > 0) {
                await (supabase as any).from("scores").insert({
                  team_id: teamId,
                  punti: -penalty,
                  tipo_modificatore: "malus_dimezza_punti",
                  motivo: "Malus Dimezza Punti (-50% Punti Prova)",
                });
                toast.error(`⚠️ Malus Dimezza Punti applicato: Punteggio prova dimezzato (-${penalty} PT)!`, {
                  duration: 6000,
                });
              }
              await (supabase as any)
                .from("marketplace_transactions")
                .update({ stato: "used", data_utilizzo: new Date().toISOString() })
                .eq("id", activeDimezza.id);
            }
          }
        } catch (modErr) {
          console.warn("Error applying challenge modifiers:", modErr);
        }

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
