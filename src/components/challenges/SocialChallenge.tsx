import { useState, useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Camera, Check, Loader2, X, Sparkles, FlipHorizontal, RotateCw } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Challenge, Team } from "@/lib/race";
import { transformImageFile } from "@/lib/imageUtils";

export function SocialChallenge({
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
  const [uploading1, setUploading1] = useState(false);
  const [uploading2, setUploading2] = useState(false);
  const [file1, setFile1] = useState<File | null>(null);
  const [file2, setFile2] = useState<File | null>(null);
  const [preview1, setPreview1] = useState<string | null>(null);
  const [preview2, setPreview2] = useState<string | null>(null);
  const [flipH1, setFlipH1] = useState(false);
  const [flipH2, setFlipH2] = useState(false);
  const [rotation1, setRotation1] = useState(0);
  const [rotation2, setRotation2] = useState(0);
  const [submittedFlip1, setSubmittedFlip1] = useState(false);
  const [submittedFlip2, setSubmittedFlip2] = useState(false);
  const [submittedRot1, setSubmittedRot1] = useState(0);
  const [submittedRot2, setSubmittedRot2] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  // Fetch team social submission status
  const socialSubQuery = useQuery({
    queryKey: ["social-submission", team?.id, challenge.id],
    enabled: Boolean(team?.id),
    staleTime: 0,
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_social_submission");
      if (error) throw new Error(error.message);
      return data as {
        id: string;
        team_id: string;
        challenge_id: string;
        image_1_url: string;
        image_2_url: string;
        uploaded_at: string;
        status: "submitted" | "approved" | "rejected";
        admin_score: number | null;
      } | null;
    },
  });

  const sub = socialSubQuery.data;

  // Resolve signed URLs for existing submissions
  const [img1Url, setImg1Url] = useState<string | null>(null);
  const [img2Url, setImg2Url] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    if (sub?.image_1_url) {
      supabase.storage
        .from("team-media")
        .createSignedUrl(sub.image_1_url, 3600)
        .then(({ data }: any) => {
          if (active) setImg1Url(data?.signedUrl ?? null);
        });
    } else {
      setImg1Url(null);
    }

    if (sub?.image_2_url) {
      supabase.storage
        .from("team-media")
        .createSignedUrl(sub.image_2_url, 3600)
        .then(({ data }: any) => {
          if (active) setImg2Url(data?.signedUrl ?? null);
        });
    } else {
      setImg2Url(null);
    }

    return () => {
      active = false;
    };
  }, [sub?.image_1_url, sub?.image_2_url]);

  // Clean previews on unmount
  useEffect(() => {
    return () => {
      if (preview1) URL.revokeObjectURL(preview1);
      if (preview2) URL.revokeObjectURL(preview2);
    };
  }, [preview1, preview2]);

  function handleFileSelect(index: 1 | 2, file: File) {
    if (sub || completed) {
      toast.error("Hai già inviato gli scatti per questa missione social.");
      return;
    }
    if (file.size > 15 * 1024 * 1024) {
      toast.error("Immagine troppo grande (max 15MB)");
      return;
    }
    const url = URL.createObjectURL(file);
    if (index === 1) {
      if (preview1) URL.revokeObjectURL(preview1);
      setFile1(file);
      setFlipH1(false);
      setRotation1(0);
      setPreview1(url);
    } else {
      if (preview2) URL.revokeObjectURL(preview2);
      setFile2(file);
      setFlipH2(false);
      setRotation2(0);
      setPreview2(url);
    }
  }

  async function handleSend() {
    if (!team) {
      toast.error("Crea prima la tua squadra");
      return;
    }
    if (sub || completed) {
      toast.error("Hai già inviato gli scatti per questa missione social.");
      return;
    }
    if (!file1 || !file2) {
      toast.error("Devi caricare entrambe le fotografie per completare la missione.");
      return;
    }

    setSubmitting(true);
    try {
      // 1. Upload Photo 1 with transformations
      setUploading1(true);
      const processed1 = await transformImageFile(file1, flipH1, rotation1);
      const ext1 = processed1.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const path1 = `${team.id}/social-1-${Date.now()}.${ext1}`;
      const { error: upErr1 } = await supabase.storage
        .from("team-media")
        .upload(path1, processed1, { upsert: false, contentType: processed1.type });
      if (upErr1) throw new Error("Upload Foto 1 fallito: " + upErr1.message);
      setUploading1(false);

      // 2. Upload Photo 2 with transformations
      setUploading2(true);
      const processed2 = await transformImageFile(file2, flipH2, rotation2);
      const ext2 = processed2.name.split(".").pop()?.toLowerCase() ?? "jpg";
      const path2 = `${team.id}/social-2-${Date.now()}.${ext2}`;
      const { error: upErr2 } = await supabase.storage
        .from("team-media")
        .upload(path2, processed2, { upsert: false, contentType: processed2.type });
      if (upErr2) throw new Error("Upload Foto 2 fallito: " + upErr2.message);
      setUploading2(false);

      // 3. Submit challenge via RPC
      const { error: subErr } = await supabase.rpc("submit_social_challenge", {
        p_image_1_path: path1,
        p_image_2_path: path2,
      });

      if (subErr) throw new Error(subErr.message);

      toast.success("Foto inviate con successo!");
      setFile1(null);
      setFile2(null);
      setPreview1(null);
      setPreview2(null);
      setFlipH1(false);
      setFlipH2(false);
      setRotation1(0);
      setRotation2(0);
      await socialSubQuery.refetch();
      await queryClient.invalidateQueries();
    } catch (e: any) {
      toast.error(e.message || "Errore durante l'invio");
    } finally {
      setSubmitting(false);
      setUploading1(false);
      setUploading2(false);
    }
  }

  if (socialSubQuery.isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-10 space-y-4">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-zinc-400 font-medium">Caricamento stato missione social...</p>
      </div>
    );
  }

  const isApproved = sub?.status === "approved";
  const isPendingValuation = sub?.status === "submitted";
  const isRejected = sub?.status === "rejected";

  return (
    <div className="space-y-6 sm:space-y-8 max-w-xl mx-auto">
      {/* MISSION BRIEFING */}
      <section className="bg-zinc-950/80 p-5 rounded-2xl border border-border/40 shadow-xl space-y-4">
        <h2 className="text-sm font-extrabold tracking-widest text-primary uppercase flex items-center gap-2">
          📸 Missione Social
        </h2>
        <div className="space-y-3 text-zinc-300 text-sm sm:text-base leading-relaxed">
          <p className="font-serif italic">
            "Viaggiatori, questa volta la sfida non è contro il tempo, ma contro la vostra capacità di entrare in contatto con il mondo.
            Dimostrate di saper comunicare, convincere e creare un legame con persone mai incontrate prima."
          </p>
          <div className="pt-3 border-t border-zinc-900 space-y-2">
            <h4 className="text-xs font-bold text-zinc-400 uppercase tracking-wide">Obiettivo:</h4>
            <p className="text-zinc-400 text-xs sm:text-sm">
              Trovate e convincete <strong>2 persone sconosciute diverse</strong> a scattare una fotografia con la squadra.
            </p>
            <div className="bg-zinc-900/60 p-3 rounded-xl border border-zinc-800/40 text-[11px] text-zinc-400 space-y-1">
              <p className="font-bold text-zinc-300 uppercase">Regole importanti:</p>
              <p>• Richiede 2 foto differenti con 2 sconosciuti differenti.</p>
              <p>• NO parenti, NO amici, NO organizzatori, NO concorrenti.</p>
              <p>• I membri del team devono essere riconoscibili nello scatto.</p>
            </div>
          </div>
        </div>
      </section>

      {/* STATE VIEW */}
      {isApproved && (
        <section className="bg-green-950/15 border border-green-800/30 rounded-2xl p-5 text-center space-y-4 animate-pop-in">
          <div className="space-y-1.5">
            <h4 className="text-sm font-extrabold text-success uppercase flex items-center gap-1.5 justify-center">
              <Check className="size-4" /> Missione Approvata!
            </h4>
            <p className="text-xs text-zinc-400">
              La regia ha valutato positivamente le foto e ha sbloccato la tappa successiva.
            </p>
          </div>
          <div className="inline-block bg-green-950 border border-green-800 rounded-xl px-5 py-2.5 font-display text-2xl font-black text-green-400 shadow">
            {sub?.admin_score ?? 0} / 20 PT
          </div>

          <div className="grid grid-cols-2 gap-4 mt-4">
            <div className="relative overflow-hidden rounded-xl border border-zinc-800/40 bg-zinc-900/40 h-36 flex justify-center items-center">
              {img1Url ? (
                <>
                  <img
                    src={img1Url}
                    alt="Foto 1 approvata"
                    className="h-full w-full object-cover transition-transform duration-200"
                    style={{
                      transform: `${submittedFlip1 ? "scaleX(-1)" : ""} rotate(${submittedRot1}deg)`,
                    }}
                  />
                  <div className="absolute top-1.5 right-1.5 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                    <button
                      type="button"
                      title="Ribalta orizzontale"
                      onClick={() => setSubmittedFlip1(!submittedFlip1)}
                      className={`p-1 rounded-md text-xs font-bold transition-colors ${
                        submittedFlip1 ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                      }`}
                    >
                      <FlipHorizontal className="size-3" />
                    </button>
                    <button
                      type="button"
                      title="Ruota 90°"
                      onClick={() => setSubmittedRot1((r) => (r + 90) % 360)}
                      className="p-1 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                    >
                      <RotateCw className="size-3" />
                    </button>
                  </div>
                </>
              ) : (
                <Loader2 className="size-4 animate-spin text-zinc-600" />
              )}
            </div>
            <div className="relative overflow-hidden rounded-xl border border-zinc-800/40 bg-zinc-900/40 h-36 flex justify-center items-center">
              {img2Url ? (
                <>
                  <img
                    src={img2Url}
                    alt="Foto 2 approvata"
                    className="h-full w-full object-cover transition-transform duration-200"
                    style={{
                      transform: `${submittedFlip2 ? "scaleX(-1)" : ""} rotate(${submittedRot2}deg)`,
                    }}
                  />
                  <div className="absolute top-1.5 right-1.5 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                    <button
                      type="button"
                      title="Ribalta orizzontale"
                      onClick={() => setSubmittedFlip2(!submittedFlip2)}
                      className={`p-1 rounded-md text-xs font-bold transition-colors ${
                        submittedFlip2 ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                      }`}
                    >
                      <FlipHorizontal className="size-3" />
                    </button>
                    <button
                      type="button"
                      title="Ruota 90°"
                      onClick={() => setSubmittedRot2((r) => (r + 90) % 360)}
                      className="p-1 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                    >
                      <RotateCw className="size-3" />
                    </button>
                  </div>
                </>
              ) : (
                <Loader2 className="size-4 animate-spin text-zinc-600" />
              )}
            </div>
          </div>

          <button
            onClick={onComplete}
            disabled={completing}
            className="primary-gradient w-full py-3.5 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all"
          >
            {completing && <Loader2 className="size-4 animate-spin" />}
            <span>Prosegui la Gara</span>
          </button>
        </section>
      )}

      {isPendingValuation && (
        <section className="bg-zinc-950/80 border border-zinc-900 rounded-2xl p-5 text-center space-y-4 animate-pop-in">
          <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4 text-center space-y-1">
            <h4 className="text-sm font-extrabold text-emerald-400 uppercase flex items-center gap-1.5 justify-center">
              <Check className="size-4" /> Foto inviata il {new Date(sub.uploaded_at).toLocaleString("it-IT")}
            </h4>
            <p className="text-xs text-zinc-400">
              Consegna completata e in attesa di revisione della Regia.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="relative overflow-hidden rounded-xl border border-zinc-800/40 bg-zinc-900/40 h-36 flex justify-center items-center">
              {img1Url ? (
                <>
                  <img
                    src={img1Url}
                    alt="Foto 1 inviata"
                    className="h-full w-full object-cover transition-transform duration-200"
                    style={{
                      transform: `${submittedFlip1 ? "scaleX(-1)" : ""} rotate(${submittedRot1}deg)`,
                    }}
                  />
                  <div className="absolute top-1.5 right-1.5 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                    <button
                      type="button"
                      title="Ribalta orizzontale"
                      onClick={() => setSubmittedFlip1(!submittedFlip1)}
                      className={`p-1 rounded-md text-xs font-bold transition-colors ${
                        submittedFlip1 ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                      }`}
                    >
                      <FlipHorizontal className="size-3" />
                    </button>
                    <button
                      type="button"
                      title="Ruota 90°"
                      onClick={() => setSubmittedRot1((r) => (r + 90) % 360)}
                      className="p-1 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                    >
                      <RotateCw className="size-3" />
                    </button>
                  </div>
                </>
              ) : (
                <Loader2 className="size-4 animate-spin text-zinc-600" />
              )}
            </div>
            <div className="relative overflow-hidden rounded-xl border border-zinc-800/40 bg-zinc-900/40 h-36 flex justify-center items-center">
              {img2Url ? (
                <>
                  <img
                    src={img2Url}
                    alt="Foto 2 inviata"
                    className="h-full w-full object-cover transition-transform duration-200"
                    style={{
                      transform: `${submittedFlip2 ? "scaleX(-1)" : ""} rotate(${submittedRot2}deg)`,
                    }}
                  />
                  <div className="absolute top-1.5 right-1.5 flex items-center gap-1 bg-black/70 backdrop-blur-sm p-1 rounded-lg border border-white/10">
                    <button
                      type="button"
                      title="Ribalta orizzontale"
                      onClick={() => setSubmittedFlip2(!submittedFlip2)}
                      className={`p-1 rounded-md text-xs font-bold transition-colors ${
                        submittedFlip2 ? "bg-primary text-primary-foreground" : "text-white hover:bg-white/20"
                      }`}
                    >
                      <FlipHorizontal className="size-3" />
                    </button>
                    <button
                      type="button"
                      title="Ruota 90°"
                      onClick={() => setSubmittedRot2((r) => (r + 90) % 360)}
                      className="p-1 rounded-md text-xs font-bold text-white hover:bg-white/20 transition-colors"
                    >
                      <RotateCw className="size-3" />
                    </button>
                  </div>
                </>
              ) : (
                <Loader2 className="size-4 animate-spin text-zinc-600" />
              )}
            </div>
          </div>

          <button
            onClick={onComplete}
            disabled={completing}
            className="primary-gradient w-full py-3.5 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all"
          >
            {completing && <Loader2 className="size-4 animate-spin" />}
            <span>Prosegui la Gara</span>
          </button>
        </section>
      )}

      {/* ACTIVE UPLOAD FORM (only when not yet submitted) */}
      {!sub && (
        <section className="space-y-6 animate-pop-in">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {/* PHOTO 1 SLOT */}
            <div className="surface p-4 border border-border/40 bg-zinc-950/20 rounded-2xl flex flex-col justify-between min-h-64 space-y-3">
              <p className="text-[10px] font-black uppercase tracking-widest text-zinc-400">📷 Foto Sconosciuto #1</p>
              
              <div className="flex-1 flex flex-col items-center justify-center">
                {preview1 ? (
                  <div className="space-y-2 w-full flex flex-col items-center">
                    <div className="relative h-32 w-full overflow-hidden rounded-xl border border-zinc-800 bg-zinc-950 flex items-center justify-center p-1">
                      <img
                        src={preview1}
                        alt="Anteprima 1"
                        className="h-full w-auto object-contain transition-transform duration-200"
                        style={{
                          transform: `${flipH1 ? "scaleX(-1)" : ""} rotate(${rotation1}deg)`,
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => {
                          setFile1(null);
                          setPreview1(null);
                          setFlipH1(false);
                          setRotation1(0);
                        }}
                        className="absolute top-1 right-1 bg-black/60 hover:bg-black/80 text-white rounded-full p-1"
                      >
                        <X className="size-3.5" />
                      </button>
                    </div>

                    <div className="flex items-center gap-1.5 pt-1">
                      <button
                        type="button"
                        onClick={() => setFlipH1(!flipH1)}
                        className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold border transition-colors ${
                          flipH1
                            ? "bg-primary text-primary-foreground border-primary"
                            : "bg-zinc-900 text-zinc-300 border-zinc-800 hover:bg-zinc-800"
                        }`}
                      >
                        <FlipHorizontal className="size-3.5" />
                        <span>{flipH1 ? "Ribaltata" : "Ribalta"}</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setRotation1((r) => (r + 90) % 360)}
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold bg-zinc-900 text-zinc-300 border border-zinc-800 hover:bg-zinc-800 transition-colors"
                      >
                        <RotateCw className="size-3.5" />
                        <span>Ruota</span>
                      </button>
                    </div>
                  </div>
                ) : (
                  <label className="flex cursor-pointer flex-col items-center gap-1.5 p-4 text-center rounded-xl hover:bg-zinc-900/30 transition-all border border-dashed border-border/30 w-full justify-center h-32">
                    <Camera className="size-6 text-primary" />
                    <span className="text-[11px] font-bold text-zinc-300">Carica Foto 1</span>
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) handleFileSelect(1, file);
                        e.target.value = "";
                      }}
                    />
                  </label>
                )}
              </div>
            </div>

            {/* PHOTO 2 SLOT */}
            <div className="surface p-4 border border-border/40 bg-zinc-950/20 rounded-2xl flex flex-col justify-between min-h-64 space-y-3">
              <p className="text-[10px] font-black uppercase tracking-widest text-zinc-400">📷 Foto Sconosciuto #2</p>

              <div className="flex-1 flex flex-col items-center justify-center">
                {preview2 ? (
                  <div className="space-y-2 w-full flex flex-col items-center">
                    <div className="relative h-32 w-full overflow-hidden rounded-xl border border-zinc-800 bg-zinc-950 flex items-center justify-center p-1">
                      <img
                        src={preview2}
                        alt="Anteprima 2"
                        className="h-full w-auto object-contain transition-transform duration-200"
                        style={{
                          transform: `${flipH2 ? "scaleX(-1)" : ""} rotate(${rotation2}deg)`,
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => {
                          setFile2(null);
                          setPreview2(null);
                          setFlipH2(false);
                          setRotation2(0);
                        }}
                        className="absolute top-1 right-1 bg-black/60 hover:bg-black/80 text-white rounded-full p-1"
                      >
                        <X className="size-3.5" />
                      </button>
                    </div>

                    <div className="flex items-center gap-1.5 pt-1">
                      <button
                        type="button"
                        onClick={() => setFlipH2(!flipH2)}
                        className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold border transition-colors ${
                          flipH2
                            ? "bg-primary text-primary-foreground border-primary"
                            : "bg-zinc-900 text-zinc-300 border-zinc-800 hover:bg-zinc-800"
                        }`}
                      >
                        <FlipHorizontal className="size-3.5" />
                        <span>{flipH2 ? "Ribaltata" : "Ribalta"}</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setRotation2((r) => (r + 90) % 360)}
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10px] font-bold bg-zinc-900 text-zinc-300 border border-zinc-800 hover:bg-zinc-800 transition-colors"
                      >
                        <RotateCw className="size-3.5" />
                        <span>Ruota</span>
                      </button>
                    </div>
                  </div>
                ) : (
                  <label className="flex cursor-pointer flex-col items-center gap-1.5 p-4 text-center rounded-xl hover:bg-zinc-900/30 transition-all border border-dashed border-border/30 w-full justify-center h-32">
                    <Camera className="size-6 text-primary" />
                    <span className="text-[11px] font-bold text-zinc-300">Carica Foto 2</span>
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) handleFileSelect(2, file);
                        e.target.value = "";
                      }}
                    />
                  </label>
                )}
              </div>
            </div>
          </div>

          <button
            onClick={handleSend}
            disabled={submitting || !file1 || !file2}
            className="primary-gradient w-full py-4 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all hover:scale-[1.01] disabled:opacity-40"
          >
            {submitting && <Loader2 className="size-4 animate-spin" />}
            Invia Missione Social
          </button>
        </section>
      )}
    </div>
  );
}
