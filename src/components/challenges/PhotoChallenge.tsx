import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Camera, Check, Loader2, MapPin } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { mediaQuery, type Challenge, type Team } from "@/lib/race";

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

  const photos = (media.data ?? []).filter((m) => m.challenge_id === challenge.id);

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

  async function handleFile(file: File) {
    if (!team) {
      toast.error("Crea prima la tua squadra");
      return;
    }
    if (file.size > 15 * 1024 * 1024) {
      toast.error("Immagine troppo grande (max 15MB)");
      return;
    }
    setUploading(true);
    try {
      const coords = await getPosition();
      const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const path = `${team.id}/${challenge.id}-${Date.now()}.${ext}`;
      const { error: upErr } = await supabase.storage
        .from("team-media")
        .upload(path, file, { upsert: false, contentType: file.type });
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
      <label className="surface flex cursor-pointer flex-col items-center justify-center gap-2 border-2 border-dashed border-border/80 p-5 sm:p-8 text-center transition-colors hover:border-primary w-full min-w-0 box-border">
        {uploading ? (
          <Loader2 className="size-8 animate-spin text-primary" />
        ) : (
          <Camera className="size-8 text-primary" />
        )}
        <span className="font-bold text-sm sm:text-base">Scatta o carica la foto ufficiale</span>
        <span className="text-xs text-muted-foreground">
          Salviamo automaticamente posizione GPS e orario
        </span>
        <input
          type="file"
          accept="image/*"
          capture="environment"
          className="hidden"
          disabled={uploading}
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) handleFile(file);
            e.target.value = "";
          }}
        />
      </label>

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
          disabled={photos.length === 0 || completing}
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
    <figure className="surface animate-pop-in overflow-hidden">
      {url ? (
        <img src={url} alt="Foto ufficiale della squadra" className="h-36 w-full object-cover" />
      ) : (
        <div className="h-36 w-full animate-pulse bg-muted" />
      )}
      <figcaption className="space-y-0.5 p-2 text-[11px] text-muted-foreground">
        <div>{new Date(at).toLocaleString("it-IT")}</div>
        {lat != null && lng != null && (
          <div className="flex items-center gap-1">
            <MapPin className="size-3" />
            {lat.toFixed(4)}, {lng.toFixed(4)}
          </div>
        )}
      </figcaption>
    </figure>
  );
}
