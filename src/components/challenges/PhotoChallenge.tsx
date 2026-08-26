import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Camera, Check, Loader2, MapPin, FlipHorizontal, RotateCw, X } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { mediaQuery, type Challenge, type Team } from "@/lib/race";
import { transformImageFile } from "@/lib/imageUtils";

export function PhotoChallenge({
  challenge,
  team,
  completed,
  onComplete,
  completing,
}: {
  challenge: Challenge;
  team: Team | null;
  completed: boolean;
  onComplete: () => void;
  completing: boolean;
}) {
  const queryClient = useQueryClient();
  const media = useQuery(mediaQuery(team?.id));
  const [uploading, setUploading] = useState(false);

  // Selected file preview & transform state before upload
  const [pendingFile, setPendingFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [flipH, setFlipH] = useState(false);
  const [rotation, setRotation] = useState(0);

  const photos = (media.data ?? []).filter((m) => m.challenge_id === challenge.id);

  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  async function getPosition(): Promise<{ lat: number | null; lng: number | null }> {
    if (typeof navigator === "undefined" || !navigator.geolocation) return { lat: null, lng: null };
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => resolve({ lat: null, lng: null }),
        { timeout: 8000 },
      );
    });
  }

  function handleFileSelected(file: File) {
    if (!team) {
      toast.error("Crea prima la tua squadra");
      return;
    }
    if (file.size > 15 * 1024 * 1024) {
      toast.error("Immagine troppo grande (max 15MB)");
      return;
    }
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPendingFile(file);
    setFlipH(false);
    setRotation(0);
    setPreviewUrl(URL.createObjectURL(file));
  }

  function handleCancelPending() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPendingFile(null);
    setPreviewUrl(null);
    setFlipH(false);
    setRotation(0);
  }

  async function handleConfirmUpload() {
    if (!team || !pendingFile) {
      toast.error("Nessuna foto selezionata");
      return;
    }

    setUploading(true);
    try {
      // Apply flip horizontal / rotation if requested
      const processedFile = await transformImageFile(pendingFile, flipH, rotation);

      const coords = await getPosition();
      const ext = processedFile.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const path = `${team.id}/${challenge.id}-${Date.now()}.${ext}`;
      const { error: upErr } = await supabase.storage
        .from("team-media")
        .upload(path, processedFile, { upsert: false, contentType: processedFile.type });
      if (upErr) throw new Error(upErr.message);

      const { error } = await (supabase as any).from("submissions").insert({
        team_id: team.id,
        challenge_id: challenge.id,
        url: path,
        tipo: "photo",
        latitude: coords.lat,
        longitude: coords.lng,
        stato_approvazione: "approved", // approved: team proceeds immediately
      });
      if (error) throw new Error(error.message);

      toast.success("Foto caricata! La prova è completata.");
      handleCancelPending();
      onComplete(); // unlock next challenge immediately
      await queryClient.invalidateQueries();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Upload non riuscito");
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="space-y-4">
      {/* PENDING PHOTO REVIEW & ADJUSTMENT MODAL/CARD */}
      {previewUrl && pendingFile ? (
        <div className="surface p-4 rounded-2xl border-2 border-primary/40 bg-zinc-950/60 space-y-4 shadow-xl animate-in zoom-in-95 duration-200">
          <div className="flex items-center justify-between">
            <h4 className="text-xs font-bold uppercase tracking-wider text-primary flex items-center gap-1.5">
              <Camera className="size-4" /> Anteprima & Regolazione Scatto
            </h4>
            <button
              onClick={handleCancelPending}
              disabled={uploading}
              className="text-muted-foreground hover:text-foreground p-1 rounded-lg hover:bg-muted/10 transition-colors"
            >
              <X className="size-5" />
            </button>
          </div>

          <div className="relative rounded-xl overflow-hidden bg-black/80 flex items-center justify-center min-h-[220px] max-h-[360px] border border-border/30">
            <img
              src={previewUrl}
              alt="Anteprima scatto"
              className="max-h-[340px] w-auto object-contain transition-transform duration-200"
              style={{
                transform: `${flipH ? "scaleX(-1)" : ""} rotate(${rotation}deg)`,
              }}
            />
          </div>

          {/* TRANSFORMATION CONTROLS */}
          <div className="flex flex-wrap items-center justify-center gap-2 pt-1">
            <button
              type="button"
              onClick={() => setFlipH(!flipH)}
              disabled={uploading}
              className={`inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold border transition-colors ${
                flipH
                  ? "bg-primary text-primary-foreground border-primary shadow-sm"
                  : "bg-zinc-900/80 text-foreground border-border/50 hover:bg-zinc-800"
              }`}
            >
              <FlipHorizontal className="size-4" />
              <span>{flipH ? "Ribaltata (Attiva)" : "Ribalta Orizzontale"}</span>
            </button>

            <button
              type="button"
              onClick={() => setRotation((r) => (r + 90) % 360)}
              disabled={uploading}
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-zinc-900/80 text-foreground border border-border/50 hover:bg-zinc-800 transition-colors"
            >
              <RotateCw className="size-4" />
              <span>Ruota 90°</span>
            </button>
          </div>

          {/* CONFIRM / CANCEL BUTTONS */}
          <div className="grid grid-cols-2 gap-3 pt-2">
            <button
              type="button"
              onClick={handleCancelPending}
              disabled={uploading}
              className="px-4 py-3 rounded-xl text-xs font-extrabold text-muted-foreground bg-zinc-900 border border-border/40 hover:bg-zinc-800 transition-colors text-center"
            >
              Scatta di nuovo
            </button>
            <button
              type="button"
              onClick={handleConfirmUpload}
              disabled={uploading}
              className="primary-gradient flex items-center justify-center gap-2 px-4 py-3 rounded-xl text-xs font-extrabold text-primary-foreground shadow-md transition-opacity disabled:opacity-40"
            >
              {uploading ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  <span>Salvataggio...</span>
                </>
              ) : (
                <>
                  <Check className="size-4" />
                  <span>Consegna Foto</span>
                </>
              )}
            </button>
          </div>
        </div>
      ) : (
        <label className="surface flex cursor-pointer flex-col items-center justify-center gap-2 border-2 border-dashed border-border/80 p-5 sm:p-8 text-center transition-colors hover:border-primary w-full min-w-0 box-border">
          {uploading ? (
            <Loader2 className="size-8 animate-spin text-primary" />
          ) : (
            <Camera className="size-8 text-primary" />
          )}
          <span className="font-bold text-sm sm:text-base">Scatta o carica la foto ufficiale</span>
          <span className="text-xs text-muted-foreground">
            Potrai visualizzare l'anteprima, ribaltarla o ruotarla prima dell'invio
          </span>
          <input
            type="file"
            accept="image/*"
            className="hidden"
            disabled={uploading}
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileSelected(file);
              e.target.value = "";
            }}
          />
        </label>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 w-full min-w-0">
        {photos.map((p) => (
          <PhotoCard key={p.id} path={p.url} lat={p.latitude} lng={p.longitude} at={p.created_at} />
        ))}
      </div>

      {completed ? (
        <p className="flex items-center gap-2 rounded-xl bg-success/15 px-4 py-3 text-sm font-bold text-success">
          <Check className="size-4" /> Prova completata
        </p>
      ) : (
        <button
          onClick={onComplete}
          disabled={photos.length === 0 || completing || !!pendingFile}
          className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl py-3.5 font-extrabold text-primary-foreground disabled:opacity-40"
        >
          {completing && <Loader2 className="size-4 animate-spin" />}
          {photos.length === 0 ? "Carica almeno una foto" : "Consegna la foto ufficiale"}
        </button>
      )}
    </div>
  );
}

function PhotoCard({
  path,
  lat,
  lng,
  at,
}: {
  path: string;
  lat: number | null;
  lng: number | null;
  at: string;
}) {
  const [url, setUrl] = useState<string | null>(null);
  const [isFlipped, setIsFlipped] = useState(false);
  const [rotation, setRotation] = useState(0);

  useEffect(() => {
    let active = true;
    supabase.storage
      .from("team-media")
      .createSignedUrl(path, 3600)
      .then(({ data }: any) => {
        if (active) setUrl(data?.signedUrl ?? null);
      });
    return () => {
      active = false;
    };
  }, [path]);

  return (
    <figure className="surface animate-pop-in overflow-hidden rounded-xl border border-border/40 bg-zinc-950/40 relative group">
      {url ? (
        <div className="relative h-40 w-full overflow-hidden bg-black/60 flex items-center justify-center">
          <img
            src={url}
            alt="Foto ufficiale della squadra"
            className="h-full w-full object-cover transition-transform duration-200"
            style={{
              transform: `${isFlipped ? "scaleX(-1)" : ""} rotate(${rotation}deg)`,
            }}
          />
          <div className="absolute top-2 right-2 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10 opacity-90 hover:opacity-100 transition-opacity">
            <button
              type="button"
              title="Ribalta orizzontale (Specchia)"
              onClick={(e) => {
                e.stopPropagation();
                setIsFlipped(!isFlipped);
              }}
              className={`p-1.5 rounded-md text-xs font-bold transition-colors ${
                isFlipped ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
              }`}
            >
              <FlipHorizontal className="size-3.5" />
            </button>
            <button
              type="button"
              title="Ruota 90°"
              onClick={(e) => {
                e.stopPropagation();
                setRotation((r) => (r + 90) % 360);
              }}
              className="p-1.5 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
            >
              <RotateCw className="size-3.5" />
            </button>
          </div>
        </div>
      ) : (
        <div className="h-40 w-full animate-pulse bg-muted" />
      )}
      <figcaption className="space-y-0.5 p-2.5 text-[11px] text-muted-foreground bg-zinc-900/60">
        <div>{new Date(at).toLocaleString("it-IT")}</div>
        {lat != null && lng != null && (
          <div className="flex items-center gap-1 text-[10px]">
            <MapPin className="size-3 text-primary" />
            {lat.toFixed(4)}, {lng.toFixed(4)}
          </div>
        )}
      </figcaption>
    </figure>
  );
}
