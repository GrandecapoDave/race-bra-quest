import { PuzzleIcon } from "lucide-react";
import { STAGE4_WAIT_MESSAGE } from "@/lib/race";

/** Messaggio mostrato per la Tappa 4 (Enigmi): la squadra aspetta il via della Regia, indipendente dal blocco della Banca. */
export function Stage4WaitCard({ compact = false }: { compact?: boolean }) {
  return (
    <div
      role="status"
      className="rounded-2xl border border-indigo-500/30 bg-indigo-500/10 p-4 text-left shadow-lg shadow-indigo-950/20"
    >
      <div className="flex items-start gap-3">
        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-indigo-500/15 text-indigo-300">
          <PuzzleIcon className="size-5" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-black uppercase tracking-wide text-indigo-300">Fermi in attesa del via</p>
          <p className="mt-1 text-sm font-semibold leading-snug text-zinc-100">{STAGE4_WAIT_MESSAGE}</p>
          {!compact && (
            <p className="mt-2 text-xs leading-snug text-zinc-400">
              Il tempo di gara continua a scorrere. La Tappa 4 si sbloccherà da sola, per tutte le squadre insieme,
              quando la Regia darà il via.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
