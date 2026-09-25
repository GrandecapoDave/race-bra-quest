import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export interface RaceTimeAdjustment {
  label: string;
  /** secondi: positivo = tempo aggiunto (penalità), negativo = tempo tolto (bonus) */
  seconds: number;
}

interface MyRaceTimes {
  started: boolean;
  finished: boolean;
  paused: boolean;
  status?: string;
  real_seconds: number;
  official_seconds: number;
  adjustments: RaceTimeAdjustment[];
}

export interface RaceClock {
  /** true dopo il primo caricamento dal server */
  ready: boolean;
  started: boolean;
  paused: boolean;
  /** la squadra ha completato tutte le prove obbligatorie: il suo tempo è fermo */
  finished: boolean;
  /** tempo di gara effettivo della squadra (pause escluse), si aggiorna ogni secondo */
  realSeconds: number | null;
  /** tempo ufficiale: effettivo + penalità - bonus (è quello che conta per la classifica) */
  officialSeconds: number | null;
  adjustments: RaceTimeAdjustment[];
}

/**
 * Orologio della squadra, guidato dal SERVER (get_my_race_times):
 *  - si ferma per tutte le squadre insieme quando la Regia mette la gara in pausa e riparte alla ripresa;
 *  - si ferma alla fine delle prove obbligatorie della squadra o alla fine gara;
 *  - non dipende dall'orologio del telefono (si usa solo il tempo trascorso dall'ultimo aggiornamento).
 */
export function useRaceClock(enabled: boolean): RaceClock {
  const timesQuery = useQuery({
    queryKey: ["my-race-times"],
    enabled,
    staleTime: 0,
    refetchInterval: 4000,
    queryFn: async (): Promise<MyRaceTimes | null> => {
      const { data, error } = await (supabase as any).rpc("get_my_race_times");
      if (error) return null;
      return (data as MyRaceTimes | null) ?? null;
    },
  });

  // istante locale in cui è arrivato l'ultimo dato: serve solo per contare i secondi tra un aggiornamento e l'altro
  const [tick, setTick] = useState(() => Date.now());
  useEffect(() => {
    if (!enabled) return undefined;
    const id = setInterval(() => setTick(Date.now()), 1000);
    return () => clearInterval(id);
  }, [enabled]);

  const data = timesQuery.data;
  if (!enabled || !data) {
    return { ready: false, started: false, paused: false, finished: false, realSeconds: null, officialSeconds: null, adjustments: [] };
  }
  if (!data.started) {
    return { ready: true, started: false, paused: false, finished: false, realSeconds: null, officialSeconds: null, adjustments: [] };
  }

  const running = !data.paused && !data.finished && data.status !== "completed";
  const fetchedAt = timesQuery.dataUpdatedAt || tick;
  const extra = running ? Math.max(0, Math.floor((tick - fetchedAt) / 1000)) : 0;

  return {
    ready: true,
    started: true,
    paused: data.paused,
    finished: data.finished,
    realSeconds: data.real_seconds + extra,
    officialSeconds: data.official_seconds + extra,
    adjustments: data.adjustments ?? [],
  };
}
