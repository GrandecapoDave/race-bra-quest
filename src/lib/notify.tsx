import { toast } from "sonner";
import type { ReactNode } from "react";
import { X } from "lucide-react";

export type NotifyTone = "reward" | "attack" | "info" | "success";

const TONE_STYLES: Record<NotifyTone, { border: string; iconBg: string; title: string }> = {
  reward: { border: "border-l-amber-400", iconBg: "bg-amber-400/15", title: "text-amber-300" },
  attack: { border: "border-l-rose-500", iconBg: "bg-rose-500/15", title: "text-rose-300" },
  info: { border: "border-l-sky-400", iconBg: "bg-sky-400/15", title: "text-sky-300" },
  success: { border: "border-l-emerald-400", iconBg: "bg-emerald-400/15", title: "text-emerald-300" },
};

interface NotificationCardProps {
  id: string | number;
  tone: NotifyTone;
  icon: string;
  title: string;
  description?: ReactNode;
}

function NotificationCard({ id, tone, icon, title, description }: NotificationCardProps) {
  const s = TONE_STYLES[tone];
  return (
    <div
      role="status"
      aria-live={tone === "attack" ? "assertive" : "polite"}
      className={`flex w-full items-start gap-3 rounded-2xl border border-zinc-800 border-l-4 ${s.border} bg-zinc-950/95 p-3.5 shadow-2xl backdrop-blur-xl`}
    >
      <div className={`flex size-9 shrink-0 items-center justify-center rounded-xl text-lg ${s.iconBg}`} aria-hidden="true">
        {icon}
      </div>
      <div className="min-w-0 flex-1">
        <p className={`text-sm font-extrabold leading-snug ${s.title}`}>{title}</p>
        {description ? <p className="mt-0.5 text-xs leading-snug text-zinc-300">{description}</p> : null}
      </div>
      <button
        type="button"
        aria-label="Chiudi notifica"
        onClick={() => toast.dismiss(id)}
        className="-mr-1 -mt-1 flex size-8 shrink-0 items-center justify-center rounded-lg text-zinc-500 active:bg-zinc-800"
      >
        <X className="size-4" />
      </button>
    </div>
  );
}

interface NotifyOptions {
  tone: NotifyTone;
  icon: string;
  title: string;
  description?: ReactNode;
  /** durata in ms: default 6000 (attacchi 9000) */
  duration?: number;
  /** vibrazione breve (funziona su Android; iPhone la ignora) */
  vibrate?: boolean;
}

/** Notifica "ricca" di gioco: carta scura con icona e tono coerenti con il tema. */
export function notify({ tone, icon, title, description, duration, vibrate }: NotifyOptions) {
  if (vibrate && typeof navigator !== "undefined" && typeof navigator.vibrate === "function") {
    try {
      navigator.vibrate(tone === "attack" ? [120, 60, 120] : 80);
    } catch {
      // vibrazione non supportata: si ignora
    }
  }
  return toast.custom(
    (id) => <NotificationCard id={id} tone={tone} icon={icon} title={title} description={description} />,
    { duration: duration ?? (tone === "attack" ? 9000 : 6000) },
  );
}

// ---------------------------------------------------------------------------------------------
// Messaggi di errore tecnici -> testo comprensibile
// ---------------------------------------------------------------------------------------------

const FRIENDLY_ERRORS: Array<[RegExp, string]> = [
  [/row-level security|violates row|permission denied|not authorized|non autorizzato/i, "Operazione non consentita. Riprova o avvisa la Regia."],
  [/jwt|token.*expired|session.*(expired|missing)|invalid.*(refresh|login)|auth session/i, "Sessione scaduta. Ricarica la pagina ed accedi di nuovo."],
  [/failed to fetch|networkerror|network request failed|load failed|fetch failed/i, "Connessione assente o instabile. Controlla la rete e riprova."],
  [/duplicate key|already exists|unique constraint/i, "Operazione già registrata."],
  [/timeout|timed out/i, "Il server ha impiegato troppo. Riprova tra un istante."],
];

export function friendlyMessage(raw: unknown): unknown {
  if (typeof raw !== "string") return raw;
  for (const [re, text] of FRIENDLY_ERRORS) {
    if (re.test(raw)) return text;
  }
  return raw;
}

let sanitizerInstalled = false;

/** Sostituisce i messaggi tecnici dei toast di errore/avviso con testo comprensibile (si installa una sola volta). */
export function installToastSanitizer() {
  if (sanitizerInstalled) return;
  sanitizerInstalled = true;
  const wrap = (fn: (message: any, data?: any) => string | number) =>
    ((message: any, data?: any) => fn(friendlyMessage(message), data)) as typeof fn;
  toast.error = wrap(toast.error.bind(toast));
  toast.warning = wrap(toast.warning.bind(toast));
}
