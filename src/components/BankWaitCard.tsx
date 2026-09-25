import { MapPin } from "lucide-react";
import { BANK_WAIT_MESSAGE } from "@/lib/race";

/** Messaggio mostrato dopo La Banca: la squadra aspetta il via della Regia prima delle sfide successive. */
export function BankWaitCard({ compact = false }: { compact?: boolean }) {
  return (
    <div
      role="status"
      className="rounded-2xl border border-amber-500/30 bg-amber-500/10 p-4 text-left shadow-lg shadow-amber-950/20"
    >
      <div className="flex items-start gap-3">
        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-amber-500/15 text-amber-300">
          <MapPin className="size-5" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-black uppercase tracking-wide text-amber-300">Fermi in attesa del via</p>
          <p className="mt-1 text-sm font-semibold leading-snug text-zinc-100">{BANK_WAIT_MESSAGE}</p>
          {!compact && (
            <p className="mt-2 text-xs leading-snug text-zinc-400">
              Il tempo di gara continua a scorrere. Le prove successive si sbloccheranno da sole, per tutte le squadre insieme,
              quando la Regia darà il via.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
