import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { notify } from "@/lib/notify";

/** Malus con schermata dedicata a tutto schermo (AppShell): niente notifica duplicata. */
const MODAL_MALUS = new Set(["freeze_2min", "enigma_extra", "ruota_sfortunata"]);
/** Malus subiti da segnalare con una notifica. */
const ATTACK_ITEMS = new Set(["trappola", "penalita_punti", "tassa_passaggio", "blackout_mercato", "dimezza_punti"]);

const MAX_SEEN = 300;
const MAX_INDIVIDUAL = 2;

type Tx = {
  id: string;
  buyer_team_id: string;
  target_team_id: string | null;
  item_id: string;
  stato: string;
  outcome: any;
  timestamp: string;
};

function loadSeen(key: string): Set<string> | null {
  try {
    const raw = localStorage.getItem(key);
    if (raw === null) return null;
    const arr = JSON.parse(raw);
    return new Set(Array.isArray(arr) ? arr.map(String) : []);
  } catch {
    return null;
  }
}

function saveSeen(key: string, seen: Set<string>) {
  try {
    localStorage.setItem(key, JSON.stringify([...seen].slice(-MAX_SEEN)));
  } catch {
    // localStorage non disponibile (modalità privata): si perde solo la memoria delle notifiche
  }
}

function ordinal(n: number) {
  return `${n}°`;
}

function describeReward(tx: Tx) {
  const o = tx.outcome ?? {};
  const tokens = o.reward_tokens ?? 0;
  const stageIndex = o.stage_index;
  const title = stageIndex ? `Tappa ${stageIndex} completata` : "Tappa completata";
  const stageName = o.stage_name && !/^Tappa\s*\d*$/i.test(String(o.stage_name)) ? String(o.stage_name) : "";
  const parts = [stageName, o.position ? `${ordinal(o.position)} posto` : "", tokens ? `+${tokens} token` : ""].filter(Boolean);
  const medal = o.position === 1 ? "🥇" : o.position === 2 ? "🥈" : o.position === 3 ? "🥉" : "🏁";
  return { icon: medal, title, description: parts.join(" · ") };
}

function describeAttack(tx: Tx, attackerName: string) {
  const o = tx.outcome ?? {};
  switch (tx.item_id) {
    case "trappola":
      return { icon: "🪤", title: "Trappola!", description: `${attackerName} vi ha rubato ${o.stolen_points ?? "dei"} punti.` };
    case "penalita_punti":
      return { icon: "⚠️", title: "Penalità Punti", description: `${attackerName} vi ha tolto ${o.points_deducted ?? 20} punti.` };
    case "tassa_passaggio":
      return { icon: "💸", title: "Tassa di Passaggio", description: `${attackerName} ha scambiato i punteggi con voi.` };
    case "blackout_mercato":
      return { icon: "🔒", title: "Blackout Mercato", description: `${attackerName} ha bloccato il vostro Marketplace per 6 minuti.` };
    case "dimezza_punti":
      return {
        icon: "✂️",
        title: "Dimezza Punti Tappa",
        description: `${attackerName} ha colpito${o.stage_number ? ` la Tappa ${o.stage_number}` : " una vostra tappa"}: perdete metà dei punti.`,
      };
    default:
      return { icon: "⚠️", title: "Malus subito", description: `${attackerName} vi ha colpito.` };
  }
}

/**
 * Notifiche di gioco per la squadra, valide in TUTTE le pagine (montato in AppShell).
 *  - ogni evento viene mostrato UNA sola volta, anche dopo ricarichi o riaperture dell'app (memoria nel telefono);
 *  - alla prima apertura su un dispositivo gli eventi già esistenti vengono segnati come visti senza mostrarli;
 *  - se ne arrivano molti insieme (app riaperta dopo un po') se ne mostrano 2 e le altre vengono riassunte in una sola.
 */
export function useTeamNotifications(teamId: string | undefined, userId: string | undefined, enabled: boolean) {
  const active = enabled && Boolean(teamId) && Boolean(userId);

  const teamsQuery = useQuery({
    queryKey: ["all-teams-list"],
    enabled: active,
    staleTime: 0,
    refetchInterval: 15000,
    queryFn: async () => {
      const { data } = await (supabase as any).from("teams_public").select("*").eq("active", true);
      return (data || []) as any[];
    },
  });

  const txQuery = useQuery({
    queryKey: ["marketplace-transactions-list"],
    enabled: active,
    staleTime: 0,
    refetchInterval: 4000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id,costo:costo_token,timestamp:data_acquisto,outcome:dettagli")
        .order("data_acquisto", { ascending: false });
      if (error) return [];
      return (data || []) as any[];
    },
  });

  useEffect(() => {
    if (!active || !txQuery.isSuccess) return;
    const key = `notif_seen_v1_${userId}`;
    const txs = (txQuery.data ?? []) as Tx[];

    const relevant = txs.filter((tx) => {
      if (tx.item_id === "reward_stage") return tx.buyer_team_id === teamId && tx.stato === "completed";
      if (ATTACK_ITEMS.has(tx.item_id) && !MODAL_MALUS.has(tx.item_id)) return tx.target_team_id === teamId && tx.buyer_team_id !== teamId;
      return false;
    });

    let seen = loadSeen(key);
    if (seen === null) {
      // primo avvio su questo dispositivo: tutto ciò che esiste già viene considerato visto
      seen = new Set(relevant.map((t) => t.id));
      saveSeen(key, seen);
      return;
    }

    const fresh = relevant
      .filter((tx) => !seen!.has(tx.id))
      .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
    if (fresh.length === 0) return;

    fresh.forEach((tx) => seen!.add(tx.id));
    saveSeen(key, seen);

    const nameOf = (id: string) => (teamsQuery.data ?? []).find((t: any) => t.id === id)?.nome_squadra ?? "Un'altra squadra";

    fresh.slice(0, MAX_INDIVIDUAL).forEach((tx) => {
      if (tx.item_id === "reward_stage") {
        const d = describeReward(tx);
        notify({ tone: "reward", icon: d.icon, title: d.title, description: d.description });
      } else {
        const attacker = tx.outcome?.attacker_name ?? nameOf(tx.buyer_team_id);
        const d = describeAttack(tx, attacker);
        notify({ tone: "attack", icon: d.icon, title: d.title, description: d.description, vibrate: true });
      }
    });

    const extra = fresh.length - MAX_INDIVIDUAL;
    if (extra > 0) {
      notify({
        tone: "info",
        icon: "🔔",
        title: `${extra} ${extra === 1 ? "altra novità" : "altre novità"}`,
        description: "Controlla la Dashboard per il riepilogo.",
      });
    }
  }, [active, userId, teamId, txQuery.isSuccess, txQuery.data, teamsQuery.data]);
}
