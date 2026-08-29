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
          // Get teamId from query cache (current_team_id RPC may not exist)
          const teamId = queryClient.getQueryData<any>(["my-team"])?.id;

          if (teamId) {
            // 1. Check for Active Moltiplicatore 2X
            const { data: active2x } = await (supabase as any)
              .from("marketplace_transactions")
              .select("id, stato")
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
                .update({ stato: "used" })
                .eq("id", active2x.id);
            }

            // 2. Check for Received Dimezza Punti Malus
            const { data: activeDimezza } = await (supabase as any)
              .from("marketplace_transactions")
              .select("id, stato")
              .eq("target_team_id", teamId)
              .eq("marketplace_item_id", "dimezza_punti")
              .eq("stato", "completed")
              .maybeSingle();

            if (activeDimezza) {
              const penalty = Math.floor(earnedPoints / 2);

              // 3. Check for Polizza Diretta before applying dimezza (logic #6 of 6)
              const { data: activePolizza } = await (supabase as any)
                .from("marketplace_transactions")
                .select("id, stato")
                .eq("team_id", teamId)
                .eq("marketplace_item_id", "polizza_diretta")
                .eq("stato", "completed")
                .maybeSingle();

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

                // Polizza: refund 50% of the penalty (= 25% of original points)
                if (activePolizza) {
                  const refund = Math.floor(penalty / 2);
                  if (refund > 0) {
                    await (supabase as any).from("scores").insert({
                      team_id: teamId,
                      punti: refund,
                      tipo_modificatore: "bonus_polizza_rimborso",
                      motivo: `Polizza Diretta: Rimborso 50% del malus (+${refund} PT)`,
                    });
                    toast.success(`🛡️ Polizza Diretta attivata! Rimborso del 50% del malus (+${refund} PT)`, {
                      duration: 6000,
                    });
                  }
                  await (supabase as any)
                    .from("marketplace_transactions")
                    .update({ stato: "used" })
                    .eq("id", activePolizza.id);
                }
              }
              await (supabase as any)
                .from("marketplace_transactions")
                .update({ stato: "used" })
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
