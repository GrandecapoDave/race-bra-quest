import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Loader2, Pause, Play, Lock, Unlock, Landmark } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { BANK_CHALLENGE_ID } from "@/lib/race";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface Props {
  gameSettings: any;
  allTeams: any[];
  allProgress: any[];
}

/** Pausa/ripresa del tempo e sblocco delle sfide dopo La Banca: comandi della Regia, effetto immediato su tutte le squadre. */
export function AdminRaceControls({ gameSettings, allTeams, allProgress }: Props) {
  const queryClient = useQueryClient();
  const [busy, setBusy] = useState<string | null>(null);
  const [confirm, setConfirm] = useState<null | "gate-open" | "gate-close" | "pause">(null);

  const raceStatus: string = gameSettings?.race_status ?? "not_started";
  const inProgress = raceStatus === "in_progress";
  const paused = gameSettings?.race_paused === true;
  const gateOpen = gameSettings?.bank_gate_open === true;

  const activeTeams = (allTeams ?? []).filter((t: any) => t.active);
  const bankDone = new Set(
    (allProgress ?? [])
      .filter((p: any) => p.challenge_id === BANK_CHALLENGE_ID && (p.stato === "completed" || p.status === "completed"))
      .map((p: any) => p.team_id),
  );
  const atBank = activeTeams.filter((t: any) => bankDone.has(t.id)).length;

  async function run(key: string, fn: string, args: Record<string, unknown>, okMsg: string) {
    setBusy(key);
    try {
      const { data: userData } = await supabase.auth.getUser();
      const { error } = await (supabase as any).rpc(fn, { ...args, p_admin_id: userData.user?.id ?? null });
      if (error) throw new Error(error.message);
      toast.success(okMsg);
      await queryClient.invalidateQueries();
    } catch (e: any) {
      toast.error(e?.message || "Operazione non riuscita");
    } finally {
      setBusy(null);
      setConfirm(null);
    }
  }

  return (
    <div className="grid gap-3 sm:gap-4 sm:grid-cols-2">
      {/* PAUSA / RIPRESA */}
      <div className={`surface space-y-2.5 sm:space-y-3 rounded-2xl border p-3.5 sm:p-4 ${paused ? "border-cyan-500/40 bg-cyan-500/5" : "border-border/40 bg-zinc-950/40"}`}>
        <div className="flex items-center justify-between gap-2">
          <h3 className="text-sm font-black uppercase tracking-wider text-muted-foreground">Tempo di gara</h3>
          <span className={`rounded-full border px-2.5 py-0.5 text-[10px] font-black uppercase ${
            paused ? "border-cyan-500/40 bg-cyan-500/15 text-cyan-300" : inProgress ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-300" : "border-zinc-700 bg-zinc-800 text-zinc-400"
          }`}>
            {paused ? "In pausa" : inProgress ? "In corso" : raceStatus === "completed" ? "Terminata" : "Non iniziata"}
          </span>
        </div>
        <p className={`text-xs leading-snug text-muted-foreground ${paused ? "" : "hidden sm:block"}`}>
          {paused
            ? "Il tempo è fermo su tutti i telefoni. Prove, risposte e acquisti sono sospesi. Alla ripresa il tempo riparte per tutti insieme."
            : "La pausa ferma il tempo di tutte le squadre nello stesso istante e sospende prove e acquisti."}
        </p>
        {paused ? (
          <button
            type="button"
            disabled={busy !== null}
            onClick={() => run("resume", "resume_global_race", {}, "▶️ Gara ripresa: il tempo riparte per tutte le squadre")}
            className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl px-4 py-3 text-sm font-extrabold text-primary-foreground disabled:opacity-50"
          >
            {busy === "resume" ? <Loader2 className="size-4 animate-spin" /> : <Play className="size-4" />}
            Riprendi la gara
          </button>
        ) : (
          <button
            type="button"
            disabled={!inProgress || busy !== null}
            onClick={() => setConfirm("pause")}
            className="flex w-full items-center justify-center gap-2 rounded-xl border border-cyan-500/40 bg-cyan-500/10 px-4 py-3 text-sm font-extrabold text-cyan-200 disabled:opacity-40"
          >
            <Pause className="size-4" />
            Metti in pausa
          </button>
        )}
      </div>

      {/* BLOCCO BANCA */}
      <div className={`surface space-y-2.5 sm:space-y-3 rounded-2xl border p-3.5 sm:p-4 ${gateOpen ? "border-emerald-500/30 bg-emerald-500/5" : "border-amber-500/30 bg-amber-500/5"}`}>
        <div className="flex items-center justify-between gap-2">
          <h3 className="flex items-center gap-1.5 text-sm font-black uppercase tracking-wider text-muted-foreground">
            <Landmark className="size-4" /> Banca BPER
          </h3>
          <span className={`rounded-full border px-2.5 py-0.5 text-[10px] font-black uppercase ${
            gateOpen ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-300" : "border-amber-500/40 bg-amber-500/15 text-amber-300"
          }`}>
            {gateOpen ? "Sbloccato" : "Bloccato"}
          </span>
        </div>
        <p className="text-xs leading-snug text-muted-foreground">
          Squadre arrivate alla banca (Banca risolta):{" "}
          <strong className="text-foreground">{atBank} / {activeTeams.length}</strong>.{" "}
          <span className={gateOpen ? "hidden sm:inline" : ""}>
            {gateOpen
              ? "Le sfide successive sono aperte a tutte le squadre."
              : "Le squadre che hanno risolto la Banca restano ferme: le sfide successive si aprono per tutte insieme quando sblocchi."}
          </span>
        </p>
        {gateOpen ? (
          <button
            type="button"
            disabled={busy !== null}
            onClick={() => setConfirm("gate-close")}
            className="flex w-full items-center justify-center gap-2 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm font-extrabold text-amber-200 disabled:opacity-40"
          >
            <Lock className="size-4" /> Rimetti il blocco
          </button>
        ) : (
          <button
            type="button"
            disabled={busy !== null}
            onClick={() => setConfirm("gate-open")}
            className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl px-4 py-3 text-sm font-extrabold text-primary-foreground disabled:opacity-50"
          >
            {busy === "gate-open" ? <Loader2 className="size-4 animate-spin" /> : <Unlock className="size-4" />}
            Sblocca tutte le squadre
          </button>
        )}
      </div>

      <AlertDialog open={confirm !== null} onOpenChange={(open) => { if (!open) setConfirm(null); }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {confirm === "pause" && "Mettere in pausa la gara?"}
              {confirm === "gate-open" && "Sbloccare le sfide dopo la banca?"}
              {confirm === "gate-close" && "Rimettere il blocco dopo la banca?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {confirm === "pause" && "Il tempo si ferma su tutti i telefoni e prove e acquisti vengono sospesi finché non riprendi la gara."}
              {confirm === "gate-open" && `Le sfide successive si apriranno subito per tutte le squadre (${atBank} su ${activeTeams.length} sono arrivate alla banca).`}
              {confirm === "gate-close" && "Le squadre che non hanno ancora iniziato le sfide successive alla banca torneranno in attesa."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Annulla</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (confirm === "pause") void run("pause", "pause_global_race", {}, "⏸️ Gara in pausa: il tempo è fermo per tutte le squadre");
                else if (confirm === "gate-open") void run("gate-open", "set_bank_gate", { p_open: true }, "🔓 Sfide sbloccate per tutte le squadre");
                else if (confirm === "gate-close") void run("gate-close", "set_bank_gate", { p_open: false }, "🔒 Blocco dopo la banca rimesso");
              }}
            >
              Conferma
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
