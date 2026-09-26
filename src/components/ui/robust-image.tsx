import { useEffect, useState, type ImgHTMLAttributes } from "react";
import { Loader2, RefreshCw } from "lucide-react";

const MAX_TRIES = 4;

// Aggiunge un parametro per forzare un nuovo download al tentativo successivo (foto firmate e locandine).
function withRetry(src: string, attempt: number) {
  if (attempt === 0 || src.startsWith("blob:") || src.startsWith("data:")) return src;
  return src + (src.includes("?") ? "&" : "?") + "r=" + attempt;
}

/**
 * <img> che non mostra mai un'immagine a meta': scarica e decodifica il file per intero, poi lo mostra.
 * Se il download si interrompe (rete mobile debole) ritenta da solo; alla fine offre un pulsante "Riprova".
 * Sostituisce il rettangolo nero con la striscia in alto visto sui telefoni.
 */
export function RobustImage({ src, alt, className, style, onError: _onError, ...rest }: ImgHTMLAttributes<HTMLImageElement>) {
  const [attempt, setAttempt] = useState(0);
  const [ready, setReady] = useState<string | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setAttempt(0);
    setReady(null);
    setFailed(false);
  }, [src]);

  useEffect(() => {
    if (!src || failed) return;
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const url = withRetry(src, attempt);
    const probe = new Image();
    probe.decoding = "async";
    const fail = () => {
      if (cancelled) return;
      if (attempt + 1 >= MAX_TRIES) setFailed(true);
      else timer = setTimeout(() => !cancelled && setAttempt(attempt + 1), 1200 * (attempt + 1));
    };
    probe.onload = () => {
      // decode() garantisce che l'immagine sia completa prima di mostrarla
      const done = () => !cancelled && setReady(url);
      if (typeof probe.decode === "function") probe.decode().then(done).catch(fail);
      else done();
    };
    probe.onerror = fail;
    probe.src = url;
    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
      probe.onload = null;
      probe.onerror = null;
    };
  }, [src, attempt, failed]);

  if (!src) return null;

  if (failed) {
    return (
      <button
        type="button"
        onClick={() => {
          setFailed(false);
          setAttempt(0);
        }}
        className="flex flex-col items-center justify-center gap-2 min-h-[160px] w-full text-xs font-semibold text-zinc-400"
      >
        <RefreshCw className="size-5" />
        Immagine non caricata: tocca per riprovare
      </button>
    );
  }

  if (!ready) {
    return (
      <div className="flex items-center justify-center min-h-[160px] w-full" role="status" aria-label="Caricamento immagine">
        <Loader2 className="size-6 animate-spin text-zinc-500" />
      </div>
    );
  }

  return <img src={ready} alt={alt} className={className} style={style} decoding="async" {...rest} />;
}
