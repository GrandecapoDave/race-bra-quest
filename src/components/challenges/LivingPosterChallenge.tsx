import { useState, useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Camera, Check, Loader2, MapPin, Film, Sparkles } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Challenge, Team } from "@/lib/race";

export function LivingPosterChallenge({
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
  const [uploading, setUploading] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  // Fetch or assign poster for the team
  const posterQuery = useQuery({
    queryKey: ["assigned-poster", team?.id],
    enabled: Boolean(team?.id),
    queryFn: async () => {
      const res = await supabase.rpc("get_or_assign_poster", { p_team_id: team!.id });
      if (res.error) throw new Error(res.error.message);
      return res.data as { assigned: any; poster: any };
    }
  });

  // Fetch the submission if it exists
  const subQuery = useQuery({
    queryKey: ["living-poster-sub", team?.id, challenge.id],
    enabled: Boolean(team?.id && challenge.id),
    queryFn: async () => {
      const { data, error } = await supabase
        .from("submissions")
        .select("*")
        .eq("team_id", team!.id)
        .eq("challenge_id", challenge.id)
        .maybeSingle();
      if (error) throw new Error(error.message);
      return data;
    }
  });

  const poster = posterQuery.data?.poster;
  const submission = subQuery.data;

  // Resolve team submission image URL
  const [subPhotoUrl, setSubPhotoUrl] = useState<string | null>(null);
  useEffect(() => {
    if (submission?.file_upload) {
      supabase.storage
        .from("team-media")
        .createSignedUrl(submission.file_upload, 3600)
        .then(({ data }: any) => {
          setSubPhotoUrl(data?.signedUrl ?? null);
        });
    } else {
      setSubPhotoUrl(null);
    }
  }, [submission?.file_upload]);

  // Cleanup previewUrl on unmount
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

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 15 * 1024 * 1024) {
      toast.error("Immagine troppo grande (max 15MB)");
      return;
    }

    setSelectedFile(file);
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
  }

  async function handleUpload() {
    if (!team || !selectedFile || !poster) {
      toast.error("Impossibile procedere con l'invio.");
      return;
    }

    setUploading(true);
    try {
      const coords = await getPosition();
      const ext = selectedFile.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const path = `${team.id}/${challenge.id}-${Date.now()}.${ext}`;

      // Upload file to supabase mock storage
      const { error: upErr } = await supabase.storage
        .from("team-media")
        .upload(path, selectedFile, { upsert: false, contentType: selectedFile.type });
      
      if (upErr) throw new Error(upErr.message);

      const { error: insErr } = await (supabase as any).from("submissions").insert({
        team_id: team.id,
        challenge_id: challenge.id,
        url: path,
        tipo: "living_poster",
        latitude: coords.lat,
        longitude: coords.lng,
        stato_approvazione: "approved", // team proceeds immediately
        note: `Locandina: ${poster.titolo}`,
      });

      if (insErr) throw new Error(insErr.message);

      toast.success("Foto della locandina inviata! La sfida è completata.");
      
      // Complete challenge to unlock next stage immediately
      onComplete();

      // Refetch
      await queryClient.invalidateQueries();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Invio non riuscito");
    } finally {
      setUploading(false);
    }
  }

  if (posterQuery.isLoading || subQuery.isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-10 space-y-4">
        <Loader2 className="size-8 animate-spin text-red-600" />
        <p className="text-sm text-zinc-400 font-medium">Caricamento locandina assegnata...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 sm:space-y-8 bg-zinc-950 p-4 sm:p-6 rounded-xl sm:rounded-2xl border border-red-950 shadow-2xl relative overflow-hidden">
      {/* Cinematic decorative elements */}
      <div className="absolute top-0 left-0 right-0 h-1 bg-red-600 shadow-[0_0_15px_rgba(220,38,38,0.7)]" />
      <div className="absolute -top-12 -left-12 size-36 bg-red-900/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-12 -right-12 size-36 bg-red-900/10 rounded-full blur-3xl pointer-events-none" />

      {/* MISSION BRIEFING */}
      <section className="bg-zinc-900/40 p-5 rounded-xl border border-zinc-800/60 space-y-4">
        <h2 className="text-sm font-extrabold tracking-widest text-red-500 uppercase flex items-center gap-2">
          <Film className="size-4 animate-pulse" /> Sfida: La Locandina Vivente
        </h2>
        <div className="space-y-4 text-zinc-300">
          <p className="text-sm sm:text-base font-serif italic leading-relaxed">
            La vostra squadra ha appena ricevuto la locandina di un film iconico.
          </p>
          <p className="text-sm sm:text-base font-serif italic leading-relaxed">
            Il vostro obiettivo è ricreare dal vivo la posa esatta del soggetto ritratto nella locandina.
          </p>
          
          <div className="space-y-4 pt-2 text-xs sm:text-sm">
            <div className="flex gap-2">
              <span className="shrink-0 text-base">🎬</span>
              <div>
                <strong className="text-red-500 font-bold uppercase tracking-wider block mb-0.5">Location</strong>
                <p className="text-zinc-400">Scattate la foto davanti al cinema, oppure scegliete il luogo che ritenete più scenografico e adatto per ricreare lo sfondo originale.</p>
              </div>
            </div>

            <div className="flex gap-2">
              <span className="shrink-0 text-base">🎭</span>
              <div>
                <strong className="text-red-500 font-bold uppercase tracking-wider block mb-0.5">Costumi di scena</strong>
                <p className="text-zinc-400">Dovrete arrangiarvi con ingegno! Utilizzate solo oggetti di fortuna recuperati sul momento o in prestito (borse, sciarpe, occhiali, ecc.).</p>
              </div>
            </div>

            <div className="flex gap-2">
              <span className="shrink-0 text-base">🏆</span>
              <div>
                <strong className="text-red-500 font-bold uppercase tracking-wider block mb-0.5">Punteggio</strong>
                <p className="text-zinc-400">
                  I dettagli faranno la differenza.
                  <span className="block mt-1">Più la vostra composizione sarà fedele alla locandina originale, più vi avvicinerete al punteggio massimo di 15 punti.</span>
                </p>
              </div>
            </div>
          </div>

          <p className="text-sm sm:text-base font-serif italic leading-relaxed pt-2 text-zinc-200">
            Mettete in moto la creatività: che vinca l'interpretazione migliore!
          </p>
        </div>
      </section>

      {/* ASSIGNED POSTER CONTAINER */}
      {poster && (
        <section className="space-y-4 text-center">
          <div className="inline-block bg-zinc-900 text-zinc-400 text-xs font-bold uppercase tracking-wider px-3.5 py-1.5 rounded-full border border-zinc-800">
            Locandina Assegnata
          </div>

          <div className="flex justify-center max-w-sm mx-auto overflow-hidden rounded-xl border border-red-950/60 shadow-2xl bg-zinc-900">
            <img
              src={`/POSTER/${poster.file_name}`}
              alt="Locandina Assegnata"
              className="w-full h-auto object-contain max-h-[420px]"
            />
          </div>
        </section>
      )}

      {/* SUBMISSION / UPLOAD FORM */}
      <section className="border-t border-zinc-900 pt-6 sm:pt-8 space-y-4">
        <h3 className="text-base font-bold text-zinc-200">La vostra ricostruzione</h3>

        {submission ? (
          // COMPLETED STATE
          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <p className="text-xs font-bold text-zinc-500 uppercase text-center">Locandina Originale</p>
                <div className="overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900 flex justify-center max-h-[220px]">
                  <img
                    src={`/POSTER/${poster?.file_name}`}
                    alt="Locandina Originale"
                    className="h-full w-auto object-contain"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <p className="text-xs font-bold text-zinc-500 uppercase text-center">La vostra ricostruzione</p>
                <div className="overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900 flex justify-center max-h-[220px]">
                  {subPhotoUrl ? (
                    <img
                      src={subPhotoUrl}
                      alt="Vostra ricostruzione"
                      className="h-full w-auto object-contain"
                    />
                  ) : (
                    <div className="h-[220px] w-full animate-pulse bg-muted" />
                  )}
                </div>
              </div>
            </div>

            {submission.voto !== null ? (
              <div className="bg-green-950/20 border border-green-800/30 rounded-xl p-4 flex flex-col sm:flex-row items-center justify-between gap-3 text-center sm:text-left">
                <div>
                  <h4 className="text-sm font-extrabold text-green-500 uppercase flex items-center gap-1.5 justify-center sm:justify-start">
                    <Sparkles className="size-4" /> Valutata dalla Regia!
                  </h4>
                  <p className="text-xs text-zinc-400 mt-1">
                    La giuria ha espresso il verdetto per la vostra interpretazione.
                  </p>
                </div>
                <div className="bg-green-950 border border-green-800 rounded-lg px-4 py-2 font-display text-xl font-black text-green-400">
                  {submission.voto} / 15 PT
                </div>
              </div>
            ) : (
              <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4 flex items-center gap-3">
                <Check className="size-5 text-green-500 shrink-0" />
                <div>
                  <p className="text-sm font-bold text-zinc-300">Foto consegnata con successo!</p>
                  <p className="text-xs text-zinc-500 mt-0.5">
                    Sfida superata. La regia valuterà l'interpretazione ed assegnerà a breve il punteggio extra.
                  </p>
                </div>
              </div>
            )}
          </div>
        ) : (
          // ACTIVE UPLOAD STATE
          <div className="space-y-4">
            {!previewUrl ? (
              <label className="surface flex cursor-pointer flex-col items-center gap-3 border-dashed border-red-950/30 bg-zinc-950 hover:bg-zinc-900/20 p-8 text-center rounded-xl transition-all">
                {uploading ? (
                  <Loader2 className="size-8 animate-spin text-red-600" />
                ) : (
                  <Camera className="size-8 text-red-600 animate-pulse" />
                )}
                <span className="font-bold text-zinc-200">Scatta o carica la vostra ricostruzione</span>
                <span className="text-xs text-zinc-500">
                  Formati ammessi: JPG, JPEG, PNG (max 15MB)
                </span>
                <input
                  type="file"
                  accept="image/*"
                  capture="environment"
                  className="hidden"
                  disabled={uploading}
                  onChange={handleFileSelect}
                />
              </label>
            ) : (
              <div className="space-y-4">
                <div className="relative max-w-sm mx-auto overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900 flex justify-center">
                  <img src={previewUrl} alt="Anteprima caricamento" className="max-h-[300px] object-contain" />
                  <button
                    onClick={() => {
                      setSelectedFile(null);
                      setPreviewUrl(null);
                    }}
                    className="absolute top-2 right-2 bg-black/60 hover:bg-black/80 text-white rounded-full p-2 text-xs font-bold"
                  >
                    Annulla
                  </button>
                </div>

                <button
                  onClick={handleUpload}
                  disabled={uploading || completing}
                  className="primary-gradient w-full py-3.5 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer disabled:opacity-40"
                >
                  {(uploading || completing) && <Loader2 className="size-4 animate-spin" />}
                  Invia Foto locandina
                </button>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
