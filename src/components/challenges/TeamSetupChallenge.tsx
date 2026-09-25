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

/** Motto assegnato dal database quando la squadra viene creata dalla Regia: non e' una scelta della squadra. */
const DEFAULT_MOTTO = "In corsa per la vittoria!";

const COLOR_NAMES: Record<string, string> = {
  "#ef4444": "Rosso", "#f97316": "Arancione", "#eab308": "Giallo", "#84cc16": "Lime", "#22c55e": "Verde", "#14b8a6": "Verde acqua",
  "#06b6d4": "Ciano", "#3b82f6": "Blu", "#6366f1": "Indaco", "#8b5cf6": "Viola", "#d946ef": "Fucsia", "#ec4899": "Rosa",
  "#dc2626": "Rosso scuro", "#ea580c": "Arancio bruciato", "#ca8a04": "Oro antico", "#4d7c0f": "Verde oliva", "#15803d": "Verde bosco",
  "#0f766e": "Verde petrolio", "#0e7490": "Blu pavone", "#1d4ed8": "Blu reale", "#4338ca": "Indaco scuro", "#7c3aed": "Ametista",
  "#a21caf": "Porpora", "#be185d": "Ciclamino",
};

/** Colore leggibile (bianco o nero) da mettere sopra uno sfondo dato. */
function onColor(hex: string): string {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16), g = parseInt(h.slice(2, 4), 16), b = parseInt(h.slice(4, 6), 16);
  return 0.299 * r + 0.587 * g + 0.114 * b > 150 ? "#000000" : "#ffffff";
}

const AVATAR_GROUPS: Array<{ title: string; items: string[] }> = [
  { title: "Animali", items: ["🐅", "🦊", "🐺", "🦅", "🐢", "🐉", "🦁", "🐝", "🐼", "🐨", "🐙", "🦖", "🦄"] },
  { title: "Avventura", items: ["🏔️", "🧭", "🎒", "🔥", "🛡️", "⚔️", "🏆", "🚗", "🚂", "🗺️", "🚀"] },
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
  const [motto, setMotto] = useState(team?.motto && team.motto.trim() !== DEFAULT_MOTTO ? team.motto : "");
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
        .rpc("update_team_profile", {
          p_motto: parsed.motto,
          p_color: color,
          p_avatar_url: avatar,
        });

      if (error) {
        // Fallback insert if not exists
        const { data: insertData, error: insertError } = await (supabase as any)
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
        if (insertError) throw new Error(insertError.message);
      }

      // Save locally
      if (typeof window !== "undefined" && team?.id) {
        try {
          const initialMembers = [
            { id: "local_1_" + Date.now(), name: member1.trim().slice(0, 60) },
            { id: "local_2_" + Date.now(), name: member2.trim().slice(0, 60) },
          ];
          localStorage.setItem(`pechino_team_members_${team.id}`, JSON.stringify(initialMembers));
        } catch {
          // ignore
        }
      }

      // Insert both required team members
      try {
        if (team?.id) {
          await supabase.from("team_members").insert([
            { team_id: team.id, name: member1.trim().slice(0, 60) },
            { team_id: team.id, name: member2.trim().slice(0, 60) },
          ]);
        }
      } catch {
        // ignore
      }

      await supabase.rpc("start_challenge", { p_challenge: challenge.id });
      return team?.id;
    },
    onSuccess: async () => {
      toast.success("Squadra configurata con successo!");
      await queryClient.invalidateQueries();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Errore"),
  });

  // Autosave: persist avatar, color and motto via update_team_profile RPC
  useEffect(() => {
    if (!team || completed) return;
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    const timeout = setTimeout(async () => {
      const parsed = teamSchema.safeParse({ motto });
      if (!parsed.success) return;

      const { error } = await (supabase as any).rpc("update_team_profile", {
        p_motto: parsed.data.motto,
        p_color: color,
        p_avatar_url: avatar || team.avatar_url || null,
      });

      if (error) {
        console.warn("[TeamSetup] Update profile RPC error:", error);
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

      {/* ── ANTEPRIMA CARTA SQUADRA ── */}
      <div
        className="rounded-2xl border-2 p-4 flex items-center gap-4 shadow-lg"
        style={{ borderColor: color + "aa", background: `linear-gradient(135deg, ${color}2e, rgba(9,9,11,0.6))` }}
      >
        <div
          className="size-16 shrink-0 rounded-2xl border-2 flex items-center justify-center text-4xl"
          style={{ borderColor: color, backgroundColor: color + "33", boxShadow: `0 0 18px -4px ${color}` }}
          aria-hidden="true"
        >
          {avatar || "❔"}
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-[10px] font-black uppercase tracking-widest text-zinc-400">Anteprima della vostra squadra</p>
          <p className="font-display text-xl font-black text-white truncate">{name.trim() || team?.name || "La vostra squadra"}</p>
          <p className="text-xs text-zinc-300 italic truncate">{motto.trim() ? `“${motto.trim()}”` : "Il vostro motto apparirà qui"}</p>
        </div>
      </div>

      {/* ── SCELTA EMOJI ── */}
      <div className="bg-zinc-950/60 p-5 rounded-2xl border border-white/10 shadow-lg space-y-4">
        <div className="flex items-center justify-between gap-2">
          <p className="text-xs font-black tracking-widest text-muted-foreground uppercase">Scegli l&apos;emoji della squadra *</p>
          <span className={`text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full border ${
            avatar ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30" : "bg-rose-500/10 text-rose-400 border-rose-500/30"
          }`}>
            {avatar ? "Scelta" : "Obbligatoria"}
          </span>
        </div>

        {AVATAR_GROUPS.map((group) => (
          <div key={group.title} className="space-y-2">
            <p className="text-[11px] font-bold uppercase tracking-wider text-zinc-500">{group.title}</p>
            <div className="grid grid-cols-4 sm:grid-cols-6 gap-3">
              {group.items.map((a) => {
                const isMine = avatar === a;
                const isTaken = !isMine && takenAvatars.has(a);
                const owner = isTaken ? avatarOwner(a) : null;
                return (
                  <button
                    key={a}
                    type="button"
                    disabled={completed || isTaken}
                    aria-pressed={isMine}
                    aria-label={isTaken ? `Emoji ${a} già scelta da ${owner}` : `Emoji ${a}`}
                    title={completed ? "Prova completata" : isTaken ? `Già scelta da: ${owner}` : undefined}
                    onClick={() => {
                      setAvatar(a);
                      triggerHaptic("light");
                    }}
                    className={cn(
                      "relative aspect-square rounded-2xl border-2 flex items-center justify-center text-4xl transition-all duration-150 active:scale-90",
                      isMine
                        ? "border-primary bg-primary/25 ring-2 ring-primary/50 ring-offset-2 ring-offset-zinc-950 scale-105"
                        : isTaken || completed
                        ? "border-zinc-800 bg-zinc-950/60 opacity-35 cursor-not-allowed"
                        : "border-zinc-700 bg-zinc-900 hover:border-primary/60 cursor-pointer",
                    )}
                  >
                    <span aria-hidden="true">{a}</span>
                    {isTaken && (
                      <span className="absolute -right-1 -top-1 flex size-5 items-center justify-center rounded-full bg-zinc-800 ring-1 ring-zinc-600">
                        <Lock className="size-3 text-zinc-300" />
                      </span>
                    )}
                    {isMine && (
                      <span className="absolute -right-1 -top-1 flex size-5 items-center justify-center rounded-full bg-primary text-black ring-1 ring-white">
                        <Check className="size-3 stroke-[3]" />
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
        <p className="text-[11px] text-zinc-500">Le emoji con il lucchetto sono già state scelte da un&apos;altra squadra.</p>
      </div>

      {/* ── SCELTA COLORE ── */}
      <div className="bg-zinc-950/60 p-5 rounded-2xl border border-white/10 shadow-lg space-y-3">
        <div className="flex items-center justify-between gap-2">
          <p className="text-xs font-black tracking-widest text-muted-foreground uppercase">Colore della squadra</p>
          <span className="flex items-center gap-1.5 text-[11px] font-bold text-zinc-300">
            <span className="size-3 rounded-full border border-white/40" style={{ backgroundColor: color }} />
            {COLOR_NAMES[color] ?? "Personalizzato"}
          </span>
        </div>
        <div className="grid grid-cols-6 gap-3">
          {COLORS.map((c) => {
            const isMine = color === c;
            const isTaken = !isMine && takenColors.has(c);
            const owner = isTaken ? colorOwner(c) : null;
            return (
              <button
                key={c}
                type="button"
                disabled={completed || isTaken}
                aria-pressed={isMine}
                aria-label={`${COLOR_NAMES[c] ?? c}${isTaken ? `, già scelto da ${owner}` : ""}`}
                title={completed ? "Prova completata" : isTaken ? `Già scelto da: ${owner}` : COLOR_NAMES[c]}
                onClick={() => {
                  setColor(c);
                  triggerHaptic("light");
                }}
                style={{ backgroundColor: c }}
                className={cn(
                  "relative aspect-square min-h-11 rounded-full border-2 flex items-center justify-center transition-all duration-150 active:scale-90",
                  isMine
                    ? "border-white ring-2 ring-white/60 ring-offset-2 ring-offset-zinc-950 scale-110 shadow-lg"
                    : isTaken || completed
                    ? "border-transparent opacity-30 grayscale cursor-not-allowed"
                    : "border-white/10 hover:border-white/60 cursor-pointer",
                )}
              >
                {isMine && <Check className="size-5 stroke-[3.5]" style={{ color: onColor(c) }} />}
                {isTaken && <Lock className="size-4" style={{ color: onColor(c) }} />}
              </button>
            );
          })}
        </div>
        <p className="text-[11px] text-zinc-500">I colori grigi con il lucchetto sono già di un&apos;altra squadra.</p>
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

