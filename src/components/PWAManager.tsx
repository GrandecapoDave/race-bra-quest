import { useState, useEffect } from "react";
import { toast } from "sonner";
import { WifiOff, RefreshCw, Download, X, Smartphone, CheckCircle2 } from "lucide-react";

export function PWAManager() {
  const [isOffline, setIsOffline] = useState(typeof navigator !== "undefined" ? !navigator.onLine : false);
  const [isOfflineDismissed, setIsOfflineDismissed] = useState(false);
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [showInstallBanner, setShowInstallBanner] = useState(false);
  const [isIOS, setIsIOS] = useState(false);
  const [isStandalone, setIsStandalone] = useState(false);
  const [showIOSPrompt, setShowIOSPrompt] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    // 1. Check if already installed / running standalone
    const isStandaloneMode =
      window.matchMedia("(display-mode: standalone)").matches ||
      (window.navigator as any).standalone === true;
    setIsStandalone(isStandaloneMode);

    // 2. Check iOS
    const userAgent = window.navigator.userAgent.toLowerCase();
    const isIosDevice = /iphone|ipad|ipod/.test(userAgent);
    setIsIOS(isIosDevice);

    // 3. Online/Offline event handlers
    const handleOnline = () => {
      setIsOffline(false);
      setIsOfflineDismissed(false);
      toast.success("Connessione ripristinata!", {
        description: "L'app si sta risincronizzando con la regia.",
        duration: 3000,
      });
    };

    const handleOffline = () => {
      setIsOffline(true);
      setIsOfflineDismissed(false);
      toast.error("📡 Connessione assente o instabile", {
        description: "I dati live richiedono connessione internet attiva.",
        duration: 5000,
      });
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    // 4. Register Service Worker
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker
        .register("/sw.js")
        .then((registration) => {
          // Check for SW updates
          registration.addEventListener("updatefound", () => {
            const newWorker = registration.installing;
            if (newWorker) {
              newWorker.addEventListener("statechange", () => {
                if (newWorker.state === "installed" && navigator.serviceWorker.controller) {
                  toast("🔄 Nuova versione dell'app disponibile", {
                    description: "Tocca per aggiornare all'ultima versione di gara.",
                    action: {
                      label: "AGGIORNA",
                      onClick: () => {
                        newWorker.postMessage({ type: "SKIP_WAITING" });
                        window.location.reload();
                      },
                    },
                    duration: 10000,
                  });
                }
              });
            }
          });
        })
        .catch((err) => {
          console.warn("[PWA] ServiceWorker registration error:", err);
        });
    }

    // 5. PWA Install Prompt Listener (Android / Chrome / Edge)
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e);
      // Only show banner if not already installed
      if (!isStandaloneMode) {
        setShowInstallBanner(true);
      }
    };

    window.addEventListener("beforeinstallprompt", handleBeforeInstallPrompt);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
      window.removeEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
    };
  }, []);

  async function handleInstallClick() {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const choiceResult = await deferredPrompt.userChoice;
    if (choiceResult.outcome === "accepted") {
      toast.success("Installazione completata!", {
        description: "Ora puoi aprire Pechino Express Bra dalla tua schermata home.",
      });
    }
    setDeferredPrompt(null);
    setShowInstallBanner(false);
  }

  return (
    <>
      {/* ANDROID / DESKTOP INSTALL BANNER */}
      {showInstallBanner && !isStandalone && (
        <div className="fixed bottom-4 left-4 right-4 sm:left-auto sm:right-4 sm:max-w-sm z-50 bg-zinc-950/95 border border-primary/40 p-4 rounded-2xl shadow-2xl backdrop-blur-md flex items-center justify-between gap-3 animate-in slide-in-from-bottom-5 duration-300">
          <div className="flex items-center gap-3">
            <div className="size-10 rounded-xl bg-primary/20 border border-primary/40 flex items-center justify-center text-primary shrink-0">
              <Smartphone className="size-5" />
            </div>
            <div>
              <h4 className="text-xs font-display font-black uppercase tracking-wide text-foreground">
                Installa Pechino Bra
              </h4>
              <p className="text-[10px] text-muted-foreground">
                Usa l'app a schermo intero durante la gara
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => setShowInstallBanner(false)}
              className="p-1 text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Chiudi"
            >
              <X className="size-4" />
            </button>
            <button
              onClick={handleInstallClick}
              className="px-3 py-1.5 bg-primary hover:bg-primary/90 text-primary-foreground font-black text-[10px] uppercase tracking-wider rounded-lg shadow transition-all flex items-center gap-1 cursor-pointer"
            >
              <Download className="size-3" />
              Installa
            </button>
          </div>
        </div>
      )}

      {/* IOS INSTALL GUIDE MODAL */}
      {showIOSPrompt && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/80 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="surface max-w-sm w-full p-5 rounded-2xl border border-primary/40 bg-zinc-950 shadow-2xl space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-primary">
                <Smartphone className="size-5" />
                <h4 className="text-sm font-display font-black uppercase tracking-wide">
                  Installa su iPhone / iPad
                </h4>
              </div>
              <button
                onClick={() => setShowIOSPrompt(false)}
                className="text-muted-foreground hover:text-foreground"
              >
                <X className="size-4" />
              </button>
            </div>

            <div className="space-y-2.5 text-xs text-zinc-300">
              <p className="text-muted-foreground">
                Per installare Pechino Express Bra come app a schermo intero:
              </p>
              <ol className="space-y-2 list-decimal list-inside bg-zinc-900/60 p-3 rounded-xl border border-zinc-800">
                <li>
                  Tocca l'icona <strong>Condividi</strong> (quadrato con freccia verso l'alto ⎋) nella barra di Safari in basso.
                </li>
                <li>
                  Scorri verso il basso e tocca <strong>"Aggiungi alla schermata Home"</strong> ⊞.
                </li>
                <li>
                  Tocca <strong>"Aggiungi"</strong> in alto a destra per completare.
                </li>
              </ol>
            </div>

            <button
              onClick={() => setShowIOSPrompt(false)}
              className="w-full py-2 bg-primary hover:bg-primary/90 text-primary-foreground font-black text-xs uppercase tracking-wider rounded-xl transition-all"
            >
              Ho Capito
            </button>
          </div>
        </div>
      )}
    </>
  );
}
