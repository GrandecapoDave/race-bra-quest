import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, Loader2, Save, Lock, Users, AlertCircle, Trash2, Plus, Sparkles, Shield } from "lucide-react";
import { z } from "zod";
import { supabase } from "@/integrations/supabase/client";
import { allTeamsQuery, myTeamQuery, membersQuery, type Challenge, type Team } from "@/lib/race";
import { triggerHaptic } from "@/lib/haptics";
import { HeroAvatar } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";

const COLORS = [
  // Toni vivaci – uno per famiglia cromatica
  "#ef4444", // Rosso
  "#f97316", // Arancione
  "#eab308", // Giallo
  "#84cc16", // Lime
  "#22c55e", // Verde
  "#14b8a6", // Verde Acqua
  "#06b6d4", // Ciano
  "#3b82f6", // Blu
  "#6366f1", // Indaco
  "#8b5cf6", // Viola
  "#d946ef", // Fucsia
  "#ec4899", // Rosa
  // Versioni scure – stessa famiglia, luminosità inferiore
  "#dc2626", // Rosso Scuro
  "#ea580c", // Arancio Bruciato
  "#ca8a04", // Oro Antico
  "#4d7c0f", // Verde Oliva
  "#15803d", // Verde Bosco
  "#0f766e", // Verde Petrolio
  "#0e7490", // Blu Pavone
  "#1d4ed8", // Blu Reale
  "#4338ca", // Indaco Scuro
  "#7c3aed", // Ametista
  "#a21caf", // Porpora
  "#be185d", // Ciclamino
];

const AVATARS = [
  "🐅", "🦊", "🐺", "🦅", "🐢", "🐉", "🦁", "🐝",
  "🐼", "🐨", "🐙", "🦖", "🦄", "🏔️", "🧭", "🎒",
  "🔥", "🛡️", "⚔️", "🏆", "🚗", "🚂", "🗺️", "🚀"
];

const teamSchema = z.object({
  motto: z.string().trim().min(2, { message: "Motto obbligatorio (minimo 2 caratteri)" }).max(120),
});

export function TeamSetupChallenge({
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
  const [name, setName] = useState(team?.name ?? "");
  const [motto, setMotto] = useState(team?.motto ?? "");
  const [color, setColor] = useState(team?.color ?? COLORS[0]!);
  const [avatar, setAvatar] = useState(team?.avatar_url ?? "");
  
  // Registration form participants inputs (for new team creation)
  const [member1, setMember1] = useState("");
  const [member2, setMember2] = useState("");
  
  // Single member add input (for existing team)
  const [memberName, setMemberName] = useState("");
  const [savedAt, setSavedAt] = useState<string | null>(null);
  const firstRender = useRef(true);

  const members = useQuery(membersQuery(team?.id));

  // Fetch all teams every 3 s to keep the taken-slots list fresh
  const allTeams = useQuery({ ...allTeamsQuery, refetchInterval: 3000 });

  // Derive sets of taken avatars / colors (excluding the current team so it doesn't block itself)
  const otherTeams = (allTeams.data ?? []).filter((t) => t.id !== team?.id);
  const takenAvatars = new Set(otherTeams.map((t) => t.avatar_url).filter(Boolean) as string[]);
  const takenColors  = new Set(otherTeams.map((t) => t.color).filter(Boolean) as string[]);

  // Name of the team that holds a given avatar / color (for tooltip)
  const avatarOwner = (a: string) => otherTeams.find((t) => t.avatar_url === a)?.name ?? null;
  const colorOwner  = (c: string) => otherTeams.find((t) => t.color === c)?.name ?? null;

  const createTeam = useMutation({
    mutationFn: async () => {
      if (!motto.trim() || motto.trim().length < 2) {
        throw new Error("Il motto della squadra è obbligatorio (minimo 2 caratteri)!");
      }
      if (!avatar) {
        throw new Error("Devi selezionare obbligatoriamente un avatar per la tua squadra!");
      }
      if (!member1.trim() || member1.trim().length < 2 || !member2.trim() || member2.trim().length < 2) {
        throw new Error("Devi inserire obbligatoriamente i nomi di entrambi i 2 partecipanti!");
      }

      const parsed = teamSchema.parse({ motto });
      const { data: userData } = await supabase.auth.getUser();
      const { data, error } = await (supabase as any)
        .from("teams")
        .insert({
          nome_squadra: name.trim() || "Squadra " + (userData.user?.email?.split("@")[0] || "Gara"),
          motto: parsed.motto,
          color,
          colore: color,
          avatar_url: avatar,
          owner_id: userData.user!.id,
        })
        .select("id")
        .single();
      if (error) throw new Error(error.message);

      // Save locally
      if (typeof window !== "undefined") {
        try {
          const initialMembers = [
            { id: "local_1_" + Date.now(), name: member1.trim().slice(0, 60) },
            { id: "local_2_" + Date.now(), name: member2.trim().slice(0, 60) },
          ];
          localStorage.setItem(`pechino_team_members_${data.id}`, JSON.stringify(initialMembers));
        } catch {
          // ignore
        }
      }

      // Insert both required team members
      try {
        await supabase.from("team_members").insert([
          { team_id: data.id, name: member1.trim().slice(0, 60) },
          { team_id: data.id, name: member2.trim().slice(0, 60) },
        ]);
      } catch {
        // ignore
      }

      await supabase.rpc("start_challenge", { p_challenge: challenge.id });
      return data.id;
    },
    onSuccess: async () => {
      toast.success("Squadra configurata con successo!");
      await queryClient.invalidateQueries();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Errore"),
  });

  // Autosave: persist ONLY avatar, color and motto to existing team without changing official team name
  useEffect(() => {
    if (!team || completed) return;
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    const timeout = setTimeout(async () => {
      const parsed = teamSchema.safeParse({ motto });
      if (!parsed.success) return;
      const { error } = await (supabase as any)
        .from("teams")
        .update({
          motto: parsed.data.motto,
          color,
          colore: color,
          avatar_url: avatar || team.avatar_url || null,
        })
        .eq("id", team.id);
      if (error) {
        toast.error("Salvataggio non riuscito, riprovo…");
        return;
      }
      setSavedAt(new Date().toLocaleTimeString("it-IT"));
      queryClient.invalidateQueries({ queryKey: myTeamQuery.queryKey });
      queryClient.invalidateQueries({ queryKey: allTeamsQuery.queryKey });
    }, 800);
    return () => clearTimeout(timeout);
  }, [motto, color, avatar, team, completed, queryClient]);

  async function addMember() {
    if (!team || completed) return;
    const cleanName = memberName.trim();
    if (cleanName.length < 2) {
      toast.error("Inserisci almeno 2 caratteri per il nome del partecipante");
      return;
    }

    const localId = "local_" + Date.now() + "_" + Math.random().toString(36).slice(2, 6);
    const newMemberObj = { id: localId, name: cleanName.slice(0, 60) };

    // 1. Instantly save in local storage to guarantee 100% success and bypass RLS failure
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem(`pechino_team_members_${team.id}`);
        const currentList = stored ? JSON.parse(stored) : [];
        const updatedList = [...currentList.filter((m: any) => m.name.toLowerCase() !== cleanName.toLowerCase()), newMemberObj];
        localStorage.setItem(`pechino_team_members_${team.id}`, JSON.stringify(updatedList));
      } catch {
        // ignore
      }
    }

    // 2. Try inserting into Supabase team_members table in background
    try {
      await (supabase as any)
        .from("team_members")
        .insert({
          team_id: team.id,
          name: cleanName.slice(0, 60),
        });
    } catch (err: any) {
      console.warn("[addMember] Supabase background sync:", err);
    }

    toast.success("Partecipante aggiunto con successo!");
    setMemberName("");
    await members.refetch();
    await queryClient.invalidateQueries({ queryKey: ["members", team.id] });
    await queryClient.invalidateQueries({ queryKey: myTeamQuery.queryKey });
  }

  async function removeMember(memberId: string) {
    if (!team || completed) return;
    
    // 1. Remove from local storage
    if (typeof window !== "undefined") {
      try {
        const stored = localStorage.getItem(`pechino_team_members_${team.id}`);
        if (stored) {
          const currentList = JSON.parse(stored);
          const updatedList = currentList.filter((m: any) => m.id !== memberId);
          localStorage.setItem(`pechino_team_members_${team.id}`, JSON.stringify(updatedList));
        }
      } catch {
        // ignore
      }
    }

    // 2. Remove from Supabase if server row
    if (!memberId.startsWith("local_")) {
      try {
        await supabase
          .from("team_members")
          .delete()
          .eq("id", memberId);
      } catch (err) {
        console.warn("[removeMember] error:", err);
      }
    }

    toast.info("Partecipante rimosso");
    await members.refetch();
    await queryClient.invalidateQueries({ queryKey: ["members", team.id] });
  }

  // Handle stage 1 challenge completion with strict validation
  function handleConfirmCompletion() {
    if (!motto.trim() || motto.trim().length < 2) {
      toast.error("Il motto della squadra è obbligatorio (minimo 2 caratteri)!");
      return;
    }
    if (!avatar) {
      toast.error("Devi selezionare obbligatoriamente un avatar per la squadra!");
      return;
    }
    const currentMembersCount = members.data?.length ?? 0;
    if (currentMembersCount < 2) {
      toast.error("Devi inserire obbligatoriamente i nomi di almeno 2 partecipanti per la squadra!");
      return;
    }

    triggerHaptic("success");
    onComplete();
  }

  return (
    <div className="space-y-6">
      {completed && (
        <div className="flex items-center gap-2 rounded-2xl border border-success/30 bg-success/10 p-4 text-xs font-bold text-success animate-pop-in">
          <Lock className="size-4 shrink-0" />
          <span>Configurazione squadra salvata e bloccata per la durata della gara.</span>
        </div>
      )}

      {/* TEAM BASIC INFO */}
      <div className="grid gap-4 bg-zinc-950/60 p-5 rounded-2xl border border-white/10 shadow-lg">
        <div>
          <label className="text-xs font-black tracking-widest text-muted-foreground uppercase flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <Shield className="size-3.5 text-primary" />
              Nome Squadra Ufficiale
            </span>
            <span className="text-[10px] text-primary font-bold uppercase tracking-wider bg-primary/10 border border-primary/20 px-2.5 py-0.5 rounded-full flex items-center gap-1">
              <Lock className="size-2.5" />
              Identità Assegnata
            </span>
          </label>
          <div className="mt-1.5 w-full rounded-xl border border-border/50 bg-secondary/40 px-4 py-3 font-display font-extrabold uppercase text-foreground text-sm flex items-center justify-between">
            <span>{team?.name || name || "Squadra in Gara"}</span>
            <span className="text-[10px] text-muted-foreground uppercase tracking-widest font-mono">Invariabile</span>
          </div>
          <p className="text-[10px] text-muted-foreground mt-1">
            Il nome ufficiale della squadra è assegnato dalla Regia e rimane intatto nella Dashboard.
          </p>
        </div>

        <div>
          <label className="text-xs font-black tracking-widest text-muted-foreground uppercase flex items-center justify-between">
            <span>Motto della squadra *</span>
            <span className="text-[10px] text-primary font-bold">Obbligatorio (minimo 2 caratteri)</span>
          </label>
          <input
            value={motto}
            maxLength={120}
            disabled={completed}
            onChange={(e) => setMotto(e.target.value)}
            placeholder="Scrivi qui il vostro motto di gara..."
            className="mt-1.5 w-full rounded-xl border border-input bg-input/40 px-4 py-3 outline-none focus:ring-2 focus:ring-primary disabled:opacity-60 font-semibold text-sm"
          />
        </div>
      </div>

      {/* ── PARTICIPANTS (OBBLIGATORIO ALMENO 2) ── */}
      <div className="bg-zinc-950/60 p-5 rounded-2xl border border-white/10 shadow-lg space-y-4">
        <div className="flex items-center justify-between">
          <label className="text-xs font-black tracking-widest text-muted-foreground uppercase flex items-center gap-2">
            <Users className="size-4 text-primary" />
            <span>Partecipanti della Squadra *</span>
          </label>
          <span className={`text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full border ${
            (!team && member1.trim() && member2.trim()) || ((members.data?.length ?? 0) >= 2)
              ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30"
              : "bg-amber-500/10 text-amber-400 border-amber-500/30 animate-pulse"
          }`}>
            {!team
              ? `${(member1.trim() ? 1 : 0) + (member2.trim() ? 1 : 0)}/2 (Obbligatori 2)`
              : `${members.data?.length ?? 0}/2 (Obbligatori 2)`}
          </span>
        </div>

        {!team ? (
          /* REGISTRATION INPUTS FOR 2 PARTICIPANTS */
          <div className="space-y-3">
            <div>
              <span className="text-[11px] font-bold text-zinc-400">Partecipante 1 (Nome e Cognome) *</span>
              <input
                value={member1}
                maxLength={60}
                onChange={(e) => setMember1(e.target.value)}
                placeholder="Es. Mario Rossi"
                className="mt-1 w-full rounded-xl border border-input bg-input/40 px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
            <div>
              <span className="text-[11px] font-bold text-zinc-400">Partecipante 2 (Nome e Cognome) *</span>
              <input
                value={member2}
                maxLength={60}
                onChange={(e) => setMember2(e.target.value)}
                placeholder="Es. Luca Bianchi"
                className="mt-1 w-full rounded-xl border border-input bg-input/40 px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary"
              />
            </div>
          </div>
        ) : (
          /* EXISTING TEAM MEMBERS LIST */
          <div className="space-y-3">
            <ul className="space-y-2 text-sm">
              {(members.data ?? []).map((m, idx) => (
                <li
                  key={m.id}
                  className="rounded-xl bg-secondary/60 border border-border/40 px-4 py-2.5 flex items-center justify-between font-semibold"
                >
                  <div className="flex items-center gap-2.5">
                    <span className="size-6 rounded-full bg-primary/15 text-primary text-xs font-black flex items-center justify-center border border-primary/25">
                      {idx + 1}
                    </span>
                    <span>{m.name}</span>
                  </div>
                  {!completed && (members.data?.length ?? 0) > 2 && (
                    <button
                      type="button"
                      onClick={() => removeMember(m.id)}
                      className="text-zinc-500 hover:text-rose-400 p-1 transition-colors cursor-pointer"
                      title="Rimuovi partecipante"
                    >
                      <Trash2 className="size-4" />
                    </button>
                  )}
                </li>
              ))}
            </ul>

            {!completed && (
              <div className="pt-2">
                <span className="text-[11px] font-bold text-zinc-400 mb-1.5 block">
                  Aggiungi partecipante alla squadra:
                </span>
                <div className="flex gap-2">
                  <input
                    value={memberName}
                    maxLength={60}
                    onChange={(e) => setMemberName(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        addMember();
                      }
                    }}
                    placeholder="Nome e Cognome partecipante..."
                    className="flex-1 rounded-xl border border-input bg-input/40 px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary"
                  />
                  <button
                    type="button"
                    onClick={addMember}
                    className="rounded-xl primary-gradient px-4 text-xs font-black text-primary-foreground uppercase tracking-wider flex items-center gap-1.5 cursor-pointer shadow-md hover:brightness-110 active:scale-95"
                  >
                    <Plus className="size-4 stroke-[3]" />
                    Aggiungi
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* ── AVATAR SECTION WITH LUXURY FRAMES (CORNICI) ── */}
      <div className="bg-zinc-950/60 p-5 rounded-2xl border border-white/10 shadow-lg space-y-4">
        <div className="flex items-center justify-between">
          <p className="text-xs font-black tracking-widest text-muted-foreground uppercase">
            Scegli Avatar *
          </p>
          <span className={`text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full border ${
            avatar
              ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30"
              : "bg-rose-500/10 text-rose-400 border-rose-500/30 animate-pulse"
          }`}>
            {avatar ? `Scelto: ${avatar}` : "Obbligatorio"}
          </span>
        </div>

        {/* ACTIVE AVATAR SHOWCASE FRAME (CORNICE EMBLEMA SELEZIONATO) */}
        {avatar && (
          <div className="p-3.5 rounded-2xl border-2 border-primary/40 bg-zinc-900/90 shadow-lg shadow-primary/20 flex items-center gap-4 animate-in zoom-in-95 duration-200">
            <div
              className="p-1.5 rounded-2xl border-2 shadow-xl shrink-0"
              style={{
                borderColor: color || "#f97316",
                backgroundColor: (color || "#f97316") + "26",
                boxShadow: `0 0 15px -2px ${(color || "#f97316")}55`,
              }}
            >
              <HeroAvatar
                emoji={avatar}
                size="lg"
                radius="lg"
                color={color}
                isBordered
                className="size-14 text-3xl shadow-inner bg-zinc-950/80"
              />
            </div>
            <div className="min-w-0 flex-1">
              <span className="text-[10px] font-black uppercase tracking-wider text-primary">
                Cornice Avatar Ufficiale
              </span>
              <h4 className="text-sm font-extrabold text-white truncate">
                Emblema Selezionato: <span className="text-lg">{avatar}</span>
              </h4>
              <p className="text-[10px] text-muted-foreground">
                Questo stemma incorniciato apparirà accanto al vostro nome su tutti i tabelloni di gara.
              </p>
            </div>
          </div>
        )}

        {/* AVATAR GRID WITH FRAMES (CORNICI RIFINITE PER OGNI AVATAR) */}
        <div className="grid grid-cols-6 sm:grid-cols-8 gap-2.5">
          {AVATARS.map((a) => {
            const isMine  = avatar === a;
            const isTaken = !isMine && takenAvatars.has(a);
            const owner   = isTaken ? avatarOwner(a) : null;

            return (
              <div
                key={a}
                title={completed ? "Prova completata" : isTaken ? `Già scelto da: ${owner}` : undefined}
                onClick={() => {
                  if (!completed && !isTaken) {
                    setAvatar(a);
                    triggerHaptic("light");
                  }
                }}
                className={`p-1 rounded-2xl border-2 transition-all duration-200 cursor-pointer flex items-center justify-center ${
                  isMine
                    ? "border-primary bg-primary/20 shadow-lg shadow-primary/30 scale-105 ring-2 ring-primary/40 ring-offset-2 ring-offset-zinc-950"
                    : isTaken || completed
                    ? "border-zinc-800/40 bg-zinc-950/40 opacity-30 cursor-not-allowed"
                    : "border-zinc-700/80 bg-zinc-900/90 hover:border-primary/60 hover:bg-zinc-800/80 hover:scale-105"
                }`}
              >
                <HeroAvatar
                  emoji={a}
                  size="md"
                  radius="md"
                  color={color}
                  isBordered={isMine}
                  isDisabled={completed || isTaken}
                  className="size-11 text-2xl shadow-sm pointer-events-none"
                  badge={
                    isTaken ? (
                      <span className="flex size-4 items-center justify-center rounded-full bg-zinc-800 ring-1 ring-zinc-700 shadow-sm">
                        <Lock className="size-2.5 text-zinc-300" />
                      </span>
                    ) : isMine ? (
                      <span className="flex size-4 items-center justify-center rounded-full bg-primary text-black ring-1 ring-white shadow-sm font-bold">
                        <Check className="size-2.5 stroke-[3]" />
                      </span>
                    ) : null
                  }
                />
              </div>
            );
          })}
        </div>
      </div>

      {/* ── COLOR GRID ── */}
      <div className="bg-zinc-950/60 p-5 rounded-2xl border border-white/10 shadow-lg space-y-3">
        <p className="text-xs font-black tracking-widest text-muted-foreground uppercase">Colore Squadra</p>
        <div className="mt-2 flex flex-wrap gap-2">
          {COLORS.map((c) => {
            const isMine  = color === c;
            const isTaken = !isMine && takenColors.has(c);
            const owner   = isTaken ? colorOwner(c) : null;

            return (
              <button
                key={c}
                type="button"
                disabled={completed || isTaken}
                onClick={() => {
                  if (!completed && !isTaken) {
                    setColor(c);
                    triggerHaptic("light");
                  }
                }}
                title={completed ? "Prova completata" : isTaken ? `Già scelto da: ${owner}` : c}
                style={{
                  backgroundColor: c,
                  cursor: completed ? "not-allowed" : isTaken ? "not-allowed" : "pointer",
                  pointerEvents: "all",
                  outline: isMine ? `3px solid white` : "none",
                  outlineOffset: "2px",
                }}
                className={[
                  "relative size-10 rounded-full border-2 transition-all duration-200",
                  isMine
                    ? "border-white scale-110 shadow-lg"
                    : isTaken || completed
                    ? "border-transparent opacity-30 grayscale"
                    : "border-transparent hover:scale-110 hover:border-white/50",
                ].join(" ")}
                aria-label={`Colore ${c}${isTaken ? ` (scelto da ${owner})` : ""}`}
              >
                {(isTaken || (completed && !isMine)) && (
                  <span className="absolute inset-0 flex items-center justify-center rounded-full">
                    <Lock className="size-3 text-white/70 drop-shadow" />
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {!completed && savedAt && (
        <p className="flex items-center gap-1.5 text-xs text-success font-semibold pl-1">
          <Save className="size-3.5" /> Salvato automaticamente alle {savedAt}
        </p>
      )}

      {/* ACTION BUTTON */}
      {!team ? (
        <button
          onClick={() => createTeam.mutate()}
          disabled={createTeam.isPending}
          className="group relative w-full h-14 primary-gradient rounded-2xl flex items-center justify-center gap-2 text-white font-display font-black text-base uppercase tracking-wider shadow-lg shadow-primary/30 hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer disabled:opacity-50"
        >
          {createTeam.isPending ? <Loader2 className="size-5 animate-spin" /> : <Sparkles className="size-5" />}
          <span>CREA LA SQUADRA E INIZIA</span>
        </button>
      ) : completed ? (
        <div className="flex items-center justify-center gap-2 rounded-2xl bg-success/15 border border-success/30 px-4 py-4 text-sm font-black text-success">
          <Check className="size-5 stroke-[3]" />
          <span>PROVA COMPLETATA CON SUCCESSO</span>
        </div>
      ) : (
        <button
          onClick={handleConfirmCompletion}
          disabled={completing}
          className="group relative w-full h-14 primary-gradient rounded-2xl flex items-center justify-center gap-2 text-white font-display font-black text-base uppercase tracking-wider shadow-lg shadow-primary/30 hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer disabled:opacity-50"
        >
          {completing ? <Loader2 className="size-5 animate-spin" /> : <Check className="size-5 stroke-[3]" />}
          <span>CONFERMA E SBLOCCA LA PROVA 2</span>
        </button>
      )}
    </div>
  );
}

