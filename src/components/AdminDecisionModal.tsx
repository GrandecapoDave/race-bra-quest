import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Crown, Sparkles, Coins, ArrowUpRight, ArrowDownRight, Check, ShieldAlert } from "lucide-react";
import { triggerHaptic } from "@/lib/haptics";
import { scoreEventsQuery, myTeamQuery } from "@/lib/race";

export function AdminDecisionModal({ isAdmin }: { isAdmin?: boolean }) {
  // Only regular player teams should see notifications about admin actions on their team
  if (isAdmin) return null;

  const team = useQuery(myTeamQuery);
  const teamId = team.data?.id;

  const scoreEvents = useQuery({
    ...scoreEventsQuery(teamId),
    enabled: Boolean(teamId),
    refetchInterval: 3000,
  });

  const tokenTransactions = useQuery({
    queryKey: ["team-admin-token-adjustments", teamId],
    enabled: Boolean(teamId),
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("id, item_id:marketplace_item_id, costo_token, dettagli, timestamp:data_acquisto")
        .eq("team_id", teamId!)
        .eq("marketplace_item_id", "admin_token_adjust")
        .order("data_acquisto", { ascending: false })
        .limit(10);
      if (error) return [];
      return data || [];
    },
  });

  const [dismissedIds, setDismissedIds] = useState<string[]>(() => {
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem("dismissed_admin_decisions");
        return stored ? JSON.parse(stored) : [];
      } catch {
        return [];
      }
    }
    return [];
  });

  // Combine unread score adjustments and token adjustments
  const pendingScoreDecisions = (scoreEvents.data || [])
    .filter(
      (s: any) =>
        (s.tipo_modificatore === "admin_adjustment" || !s.challenge_id) &&
        s.reason &&
        s.reason.trim().length > 0 &&
        !dismissedIds.includes(s.id)
    )
    .map((s) => ({
      id: s.id,
      type: "points" as const,
      amount: s.points,
      reason: s.reason,
      timestamp: s.created_at,
    }));

  const pendingTokenDecisions = (tokenTransactions.data || [])
    .filter((t: any) => !dismissedIds.includes(t.id))
    .map((t: any) => {
      const amount = t.dettagli?.amount ?? t.costo_token ?? 0;
      const reason = t.dettagli?.reason || "Regolazione manuale Regia";
      return {
        id: t.id,
        type: "tokens" as const,
        amount: amount,
        reason: reason,
        timestamp: t.timestamp,
      };
    });

  const allPending = [...pendingScoreDecisions, ...pendingTokenDecisions].sort(
    (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  );

  const activeDecision = allPending[0];

  const handleDismiss = (id: string) => {
    triggerHaptic("medium");
    const updated = [...dismissedIds, id];
    setDismissedIds(updated);
    if (typeof window !== "undefined") {
      localStorage.setItem("dismissed_admin_decisions", JSON.stringify(updated));
    }
  };

  if (!activeDecision) return null;

  const isPositive = activeDecision.amount > 0;
  const isPoints = activeDecision.type === "points";

  return (
    <div className="fixed inset-x-0 top-0 z-[100] px-3.5 sm:px-4 pt-[max(1.25rem,env(safe-area-inset-top))] pb-3 pointer-events-none animate-in slide-in-from-top-6 duration-300">
      <div className="max-w-md mx-auto pointer-events-auto bg-[#0d131f]/95 border border-white/15 backdrop-blur-2xl rounded-3xl p-5 shadow-[0_20px_60px_-15px_rgba(0,0,0,0.9)] space-y-4">
        {/* Top Header with Crown */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="flex size-7 items-center justify-center rounded-xl bg-orange-500/20 border border-orange-500/30 text-orange-400">
              <Crown className="size-4" strokeWidth={2.5} />
            </span>
            <span className="text-[11px] font-black uppercase tracking-[0.18em] text-orange-400">
              Decisione della Regia
            </span>
          </div>
          <span className="text-[10px] font-mono text-zinc-500 font-bold">
            {new Date(activeDecision.timestamp).toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })}
          </span>
        </div>

        {/* Change Display Card */}
        <div
          className={`p-4 rounded-2xl border flex items-center justify-between ${
            isPositive
              ? "bg-emerald-950/20 border-emerald-500/30 text-emerald-400"
              : "bg-rose-950/20 border-rose-500/30 text-rose-400"
          }`}
        >
          <div className="flex items-center gap-3">
            <div
              className={`size-10 rounded-xl flex items-center justify-center shrink-0 border ${
                isPositive
                  ? "bg-emerald-500/20 border-emerald-500/30 text-emerald-400"
                  : "bg-rose-500/20 border-rose-500/30 text-rose-400"
              }`}
            >
              {isPositive ? (
                <ArrowUpRight className="size-6 stroke-[3]" />
              ) : (
                <ArrowDownRight className="size-6 stroke-[3]" />
              )}
            </div>
            <div>
              <p className="text-[10px] font-black uppercase tracking-wider text-muted-foreground">
                {isPositive ? "Accredito Ufficiale" : "Detrazione Ufficiale"}
              </p>
              <p className="text-xl sm:text-2xl font-black font-display tracking-wide">
                {isPositive ? `+${activeDecision.amount}` : activeDecision.amount}{" "}
                {isPoints ? "Punti 🏆" : "Token 🪙"}
              </p>
            </div>
          </div>
        </div>

        {/* Motivation / Reason */}
        <div className="bg-zinc-950/50 rounded-xl p-3.5 border border-zinc-800 space-y-1">
          <p className="text-[10px] uppercase font-black tracking-wider text-zinc-400">
            Motivazione della Regia:
          </p>
          <p className="text-xs text-foreground font-semibold leading-relaxed italic">
            "{activeDecision.reason}"
          </p>
        </div>

        {/* Action Button */}
        <button
          onClick={() => handleDismiss(activeDecision.id)}
          className="w-full py-3 rounded-xl bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-400 hover:to-amber-400 text-black font-black text-xs uppercase tracking-widest shadow-lg shadow-orange-500/20 active:scale-[0.98] transition-all cursor-pointer flex items-center justify-center gap-2"
        >
          <Check className="size-4 stroke-[3]" />
          <span>OK, Ho Capito</span>
        </button>
      </div>
    </div>
  );
}
