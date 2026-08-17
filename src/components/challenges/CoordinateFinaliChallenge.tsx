import { useState, useEffect, useRef } from "react";
import { Check, X, Loader2, MapPin, Navigation, Compass } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import type { Challenge, Team } from "@/lib/race";

interface Props {
  challenge: Challenge;
  team: Team | null;
  completed: boolean;
  onComplete: () => void;
  completing: boolean;
}

type ResultState = "idle" | "correct" | "wrong" | "loading";

const START_LAT = 44.70543755479204;
const START_LNG = 7.843369729815371;

const DEST_LAT = 44.71631488741777;
const DEST_LNG = 7.842901351857487;

const CHURCH_LAT = 44.716975496797886;
const CHURCH_LNG = 7.8429928240833835;

export function CoordinateFinaliChallenge({ challenge, team, completed: initCompleted, onComplete, completing }: Props) {
  const [latInput, setLatInput] = useState("");
  const [lngInput, setLngInput] = useState("");
  const [result, setResult] = useState<ResultState>("idle");
  const [attemptCount, setAttemptCount] = useState(0);
  const [isCompleted, setIsCompleted] = useState(initCompleted);
  const [pointsEarned, setPointsEarned] = useState(0);

  // Map state
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const leafletMapRef = useRef<any>(null);
  const [mapLoaded, setMapLoaded] = useState(false);
  const [routeInfo, setRouteInfo] = useState<{ distance: string; duration: string } | null>(null);
  const [routingError, setRoutingError] = useState(false);

  // Sync state with server on mount
  useEffect(() => {
    if (!team?.id || !challenge?.id) return;
    supabase
      .rpc("get_enigma_state", { p_challenge_id: challenge.id, p_team_id: team.id })
      .then(({ data, error }: { data: any; error: any }) => {
        if (error || !data) return;
        if (data.is_completed) {
          setIsCompleted(true);
          setResult("correct");
        }
        setAttemptCount(data.attempt_count ?? 0);
      });
  }, [team?.id, challenge?.id]);

  async function handleValidate(e: React.FormEvent) {
    e.preventDefault();
    const lat = latInput.trim().replace(",", ".");
    const lng = lngInput.trim().replace(",", ".");

    if (!lat || !lng) {
      toast.warning("Inserisci sia la latitudine che la longitudine.");
      return;
    }

    if (!team?.id || !challenge?.id) return;
    setResult("loading");

    const { data, error } = await supabase.rpc("submit_enigma_answer", {
      p_challenge_id: challenge.id,
      p_answer: { lat, lng },
    });

    if (error || !data) {
      toast.error("Errore di rete. Riprova.");
      setResult("idle");
      return;
    }

    setAttemptCount((prev) => prev + 1);

    if (data.is_correct) {
      setResult("correct");
      setIsCompleted(true);
      setPointsEarned(data.points ?? 0);
      toast.success("Coordinate corrette! Mappa della destinazione sbloccata.");
    } else {
      setResult("wrong");
      setTimeout(() => {
        setLatInput("");
        setLngInput("");
        setResult("idle");
      }, 1800);
    }
  }

  // Load Leaflet and Route dynamically once unlocked
  useEffect(() => {
    if (!isCompleted || !mapContainerRef.current) return;

    // Load Leaflet CSS if not already present
    if (!document.getElementById("leaflet-css")) {
      const link = document.createElement("link");
      link.id = "leaflet-css";
      link.rel = "stylesheet";
      link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
      document.head.appendChild(link);
    }

    const initMap = async () => {
      const L = (window as any).L;
      if (!L || leafletMapRef.current || !mapContainerRef.current) return;

      const map = L.map(mapContainerRef.current, {
        zoomControl: true,
        scrollWheelZoom: false,
      }).setView([START_LAT, START_LNG], 14);

      L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: "abcd",
        maxZoom: 20,
      }).addTo(map);

      leafletMapRef.current = map;

      // Add Start Marker (📍 PARTENZA)
      const startIcon = L.divIcon({
        html: `<div style="display: flex; align-items: center; justify-content: center; width: 28px; height: 28px; border-radius: 50%; bg-gradient: linear(to-b, #ef4444, #b91c1c); color: #fff; font-weight: 900; font-size: 13px; border: 2.5px solid #fff; box-shadow: 0 3px 6px rgba(0,0,0,0.4); font-family: sans-serif; background-color: #ef4444;">P</div>`,
        className: "custom-map-marker-start",
        iconSize: [28, 28],
        iconAnchor: [14, 14],
      });
      L.marker([START_LAT, START_LNG], { icon: startIcon }).addTo(map).bindPopup("<b>PARTENZA</b>");

      // Add Destination Marker (🏁 TAPPA FINALE)
      const destIcon = L.divIcon({
        html: `<div style="display: flex; align-items: center; justify-content: center; width: 34px; height: 34px; border-radius: 50%; color: #fff; font-weight: 900; font-size: 15px; border: 2.5px solid #fff; box-shadow: 0 4px 8px rgba(0,0,0,0.5); font-family: sans-serif; background-color: #f97316;">🏁</div>`,
        className: "custom-map-marker-dest",
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      });
      L.marker([DEST_LAT, DEST_LNG], { icon: destIcon }).addTo(map).bindPopup("<b>🏁 TRAGUARDO FINALE</b>");

      // Add Church of San Matteo Landmark Marker (⛪ Chiesa di San Matteo)
      const churchIcon = L.divIcon({
        html: `<div style="display: flex; align-items: center; justify-content: center; width: 30px; height: 30px; border-radius: 50%; color: #fff; font-weight: 900; font-size: 14px; border: 2px solid #fff; box-shadow: 0 3px 6px rgba(0,0,0,0.4); font-family: sans-serif; background-color: #3b82f6;">⛪</div>`,
        className: "custom-map-marker-church",
        iconSize: [30, 30],
        iconAnchor: [15, 15],
      });
      L.marker([CHURCH_LAT, CHURCH_LNG], { icon: churchIcon }).addTo(map).bindPopup("<b>⛪ Chiesa di San Matteo</b><br/><span style='font-size: 10px; color: #888;'>Punto di Riferimento Visivo</span>");

      // Fetch road routing from OSRM
      try {
        const response = await fetch(
          `https://router.project-osrm.org/route/v1/driving/${START_LNG},${START_LAT};${DEST_LNG},${DEST_LAT}?overview=full&geometries=geojson`
        );
        const data = await response.json();

        if (data.routes && data.routes.length > 0) {
          const route = data.routes[0];
          const distanceKm = (route.distance / 1000).toFixed(1).replace(".", ",");
          const durationMin = Math.round(route.duration / 60);

          setRouteInfo({
            distance: `${distanceKm} km`,
            duration: `${durationMin} min`,
          });

          // Draw polyline route
          const coordinates = route.geometry.coordinates;
          const latLngs = coordinates.map((coords: any) => [coords[1], coords[0]]);

          const polyline = L.polyline(latLngs, {
            color: "#f97316",
            weight: 5.5,
            opacity: 0.95,
          }).addTo(map);

          // Fit bounds
          map.fitBounds(polyline.getBounds(), { padding: [40, 40] });
        } else {
          setRoutingError(true);
          // Fallback line if OSRM fails
          const fallbackLine = L.polyline([[START_LAT, START_LNG], [DEST_LAT, DEST_LNG]], {
            color: "#ef4444",
            dashArray: "5, 10",
            weight: 4,
          }).addTo(map);
          map.fitBounds(fallbackLine.getBounds(), { padding: [40, 40] });
        }
      } catch (err) {
        console.error("OSRM routing error:", err);
        setRoutingError(true);
      }
      setMapLoaded(true);
    };

    if (!(window as any).L) {
      const script = document.createElement("script");
      script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
      script.onload = initMap;
      document.head.appendChild(script);
    } else {
      initMap();
    }

    return () => {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, [isCompleted]);

  // ── Correct Answer/Unlocked Map View ─────────────────────────────────────
  if (isCompleted || result === "correct") {
    return (
      <div className="space-y-5 animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-md mx-auto">
        <div className="surface border border-success/30 bg-success/5 rounded-2xl p-5 text-center space-y-2 shadow-lg shadow-success/5">
          <div className="inline-flex size-14 items-center justify-center rounded-full bg-success/20 border border-success/30 mx-auto">
            <Check className="size-7 text-success" />
          </div>
          <div>
            <h2 className="text-xl font-display font-black uppercase tracking-wider text-success">
              ✓ COORDINATE CORRETTE
            </h2>
            <p className="text-xs text-muted-foreground">Avete trovato la destinazione finale della gara.</p>
          </div>
          {pointsEarned > 0 && (
            <span className="inline-block bg-gold/20 border border-gold/30 text-gold font-black text-xs px-3.5 py-1 rounded-full">
              +{pointsEarned} PT
            </span>
          )}
        </div>

        {/* Map Container */}
        <div className="space-y-2">
          <div className="flex items-center justify-between px-1">
            <p className="text-xs font-bold uppercase tracking-widest text-primary flex items-center gap-1.5 animate-pulse">
              <Compass className="size-4 animate-spin-slow" />
              🗺️ Mappa Sbloccata
            </p>
            {routeInfo && (
              <span className="text-[10px] font-bold text-muted-foreground uppercase">
                Routing stradale attivo
              </span>
            )}
          </div>

          <div className="surface rounded-2xl border border-border/30 overflow-hidden bg-zinc-950 shadow-inner relative">
            <div ref={mapContainerRef} className="w-full h-80 z-10" />
            {!mapLoaded && (
              <div className="absolute inset-0 flex items-center justify-center bg-zinc-950/80 z-20 gap-2">
                <Loader2 className="size-5 animate-spin text-primary" />
                <span className="text-xs font-bold text-muted-foreground">Caricamento percorso...</span>
              </div>
            )}
          </div>
        </div>

        {/* Road Info & Instructions */}
        <div className="surface p-4 rounded-xl border border-border/40 space-y-3">
          <div className="grid grid-cols-2 gap-4 text-center divide-x divide-border/20">
            <div>
              <p className="text-[10px] uppercase text-muted-foreground font-bold tracking-widest">Distanza</p>
              <p className="text-lg font-black text-foreground">{routeInfo?.distance ?? "Calcolo..."}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-muted-foreground font-bold tracking-widest">Percorrenza</p>
              <p className="text-lg font-black text-foreground">{routeInfo?.duration ?? "Calcolo..."}</p>
            </div>
          </div>
          {routingError && (
            <p className="text-[9px] text-destructive text-center font-bold uppercase">
              Rete instabile: visualizzazione percorso in linea retta temporaneo.
            </p>
          )}
          <div className="border-t border-border/10 pt-3 text-center">
            <p className="text-xs font-bold text-primary">🏁 DESTINAZIONE SBLOCCATA</p>
            <p className="text-[10px] text-muted-foreground mt-0.5">Raggiungete il traguardo finale alla Chiesa di San Matteo.</p>
          </div>
        </div>

        <button
          onClick={onComplete}
          disabled={completing}
          className="primary-gradient w-full py-4 rounded-2xl font-extrabold text-primary-foreground flex items-center justify-center gap-2 text-base active:scale-95 transition-all shadow-md shadow-primary/20 cursor-pointer disabled:opacity-50"
        >
          {completing ? (
            <><Loader2 className="size-5 animate-spin" /> Salvataggio...</>
          ) : (
            <>Tappa Successiva <Check className="size-5" /></>
          )}
        </button>
      </div>
    );
  }

  // ── Active Coordinate Input UI ───────────────────────────────────────────
  return (
    <div className={`space-y-6 max-w-md mx-auto transition-transform duration-200 ${result === "wrong" ? "animate-shake" : ""}`}>
      {/* Header Info */}
      <div className="surface p-4 rounded-2xl border border-border/40 space-y-1 text-center">
        <div className="flex items-center justify-center gap-2">
          <Navigation className="size-4 text-primary" />
          <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">
            Le Coordinate Finali
          </p>
        </div>
        <p className="text-[11px] text-muted-foreground leading-relaxed">
          Ogni strada porta da qualche parte. Ma solo una porta alla destinazione finale.
        </p>
        {attemptCount > 0 && (
          <p className="text-[10px] text-muted-foreground mt-1">
            Tentativi effettuati: <span className="font-bold text-foreground">{attemptCount}</span>
          </p>
        )}
      </div>

      {/* Wrong Answer Alert */}
      {result === "wrong" && (
        <div className="bg-destructive/10 border border-destructive/20 text-destructive text-center py-3 rounded-2xl animate-in fade-in duration-200 space-y-1">
          <p className="text-xs font-bold">✕ COORDINATE ERRATE</p>
          <p className="text-sm font-black text-destructive animate-bounce">-8 PUNTI</p>
          <p className="text-[10px] text-muted-foreground/80">Riprova.</p>
        </div>
      )}

      {/* Coordinates Form */}
      <form onSubmit={handleValidate} className="relative surface rounded-3xl border border-border/30 p-6 space-y-4 bg-[#070d1e]/80 shadow-xl shadow-black/25">
        {/* Floating score loss animation inside form container */}
        {result === "wrong" && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-50">
            <span className="animate-score-loss text-red-500 font-display font-black text-6xl tracking-widest drop-shadow-[0_4px_16px_rgba(239,68,68,0.6)]">
              -8
            </span>
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">
              Latitudine
            </label>
            <input
              type="text"
              inputMode="decimal"
              value={latInput}
              onChange={(e) => {
                setLatInput(e.target.value);
                if (result === "wrong") setResult("idle");
              }}
              placeholder="es. 44.12"
              disabled={result === "loading"}
              className="w-full rounded-2xl border border-input bg-input/40 px-4 py-3.5 text-base font-black text-center focus:outline-none focus:ring-2 focus:ring-primary/20 text-foreground transition-all"
              autoComplete="off"
              autoCorrect="off"
              spellCheck={false}
            />
          </div>
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">
              Longitudine
            </label>
            <input
              type="text"
              inputMode="decimal"
              value={lngInput}
              onChange={(e) => {
                setLngInput(e.target.value);
                if (result === "wrong") setResult("idle");
              }}
              placeholder="es. 7.34"
              disabled={result === "loading"}
              className="w-full rounded-2xl border border-input bg-input/40 px-4 py-3.5 text-base font-black text-center focus:outline-none focus:ring-2 focus:ring-primary/20 text-foreground transition-all"
              autoComplete="off"
              autoCorrect="off"
              spellCheck={false}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 pt-2">
          <button
            type="button"
            onClick={() => {
              setLatInput("");
              setLngInput("");
              setResult("idle");
            }}
            disabled={(!latInput && !lngInput) || result === "loading"}
            className="py-3.5 rounded-2xl border border-border/80 font-extrabold text-muted-foreground hover:text-foreground hover:border-foreground/30 transition-all active:scale-95 disabled:opacity-30 cursor-pointer text-sm"
          >
            Cancella
          </button>
          <button
            type="submit"
            disabled={!latInput.trim() || !lngInput.trim() || result === "loading"}
            className="py-3.5 rounded-2xl primary-gradient font-extrabold text-primary-foreground flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-30 cursor-pointer text-sm shadow-lg shadow-primary/25"
          >
            {result === "loading" ? (
              <><Loader2 className="size-4 animate-spin" /> Verifico...</>
            ) : (
              "Valida"
            )}
          </button>
        </div>
      </form>

      {/* Dynamic Keyframe style block for float/scale-loss feedback */}
      <style>{`
        @keyframes scoreLossFloat {
          0% { transform: scale(0.4) translateY(0); opacity: 0; }
          15% { transform: scale(1.2) translateY(-10px); opacity: 1; }
          80% { transform: scale(1) translateY(-30px); opacity: 1; }
          100% { transform: scale(0.7) translateY(-55px); opacity: 0; }
        }
        .animate-score-loss {
          animation: scoreLossFloat 1.4s cubic-bezier(0.25, 1, 0.5, 1) forwards;
        }
        .animate-spin-slow {
          animation: spin 8s linear infinite;
        }
      `}</style>
    </div>
  );
}
