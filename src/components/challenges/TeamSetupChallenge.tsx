import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, Loader2, Save, Lock } from "lucide-react";
import { z } from "zod";
import { supabase } from "@/integrations/supabase/client";
import { allTeamsQuery, myTeamQuery, membersQuery, type Challenge, type Team } from "@/lib/race";

const COLORS = [
  // Toni vivaci – uno per famiglia cromatica (hue ben spaziati)
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
  // Versioni scure – stessa famiglia, luminosità nettamente inferiore
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
  name: z.string().trim().min(2, "Nome troppo corto").max(40, "Massimo 40 caratteri"),
  motto: z.string().trim().max(120, "Massimo 120 caratteri"),
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
  const [avatar, setAvatar] = useState(team?.avatar_url ?? AVATARS[0]!);
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
      const parsed = teamSchema.parse({ name, motto });
      const { data: userData } = await supabase.auth.getUser();
      const { data, error } = await (supabase as any)
        .from("teams")
        .insert({
          nome_squadra: parsed.name,
          motto: parsed.motto || null,
          color,
          colore: color,
          avatar_url: avatar,
          owner_id: userData.user!.id,
        })
        .select("id")
        .single();
      await supabase
        .from("team_members")
        .insert({ team_id: data.id, name: parsed.name + " · capitano" });
      await supabase.rpc("start_challenge", { p_challenge: challenge.id });
      return data.id;
    },
    onSuccess: async () => {
      toast.success("Squadra creata!");
      await queryClient.invalidateQueries();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Errore"),
  });

  // Autosave: any edit to an existing team is persisted to the database only if challenge is not completed.
  useEffect(() => {
    if (!team || completed) return;
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    const timeout = setTimeout(async () => {
      const parsed = teamSchema.safeParse({ name, motto });
      if (!parsed.success) return;
      const { error } = await (supabase as any)
        .from("teams")
        .update({
          nome_squadra: parsed.data.name,
          motto: parsed.data.motto || null,
          color,
          colore: color,
          avatar_url: avatar,
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
  }, [name, motto, color, avatar, team, completed, queryClient]);

  async function addMember() {
    if (!team || completed || memberName.trim().length < 2) return;
    const { error } = await supabase
      .from("team_members")
      .insert({ team_id: team.id, name: memberName.trim().slice(0, 60) });
    if (error) {
      toast.error("Impossibile aggiungere il membro");
      return;
    }
    setMemberName("");
    members.refetch();
  }

  return (
    <div className="space-y-5">
      {completed && (
        <div className="flex items-center gap-2 rounded-xl border border-success/30 bg-success/10 p-3.5 text-xs font-bold text-success animate-pop-in">
          <Lock className="size-4 shrink-0" />
          <span>Configurazione squadra salvata e bloccata per la durata della gara.</span>
        </div>
      )}

      <div className="grid gap-3">
        <label className="text-xs font-bold tracking-widest text-muted-foreground uppercase">
          Nome squadra
        </label>
        <input
          value={name}
          maxLength={40}
          disabled={completed}
          onChange={(e) => setName(e.target.value)}
          placeholder="Es. I Lupi del Roero"
          className="rounded-xl border border-input bg-input/40 px-4 py-3 outline-none focus:ring-2 focus:ring-ring disabled:opacity-60 disabled:cursor-not-allowed"
        />
        <label className="text-xs font-bold tracking-widest text-muted-foreground uppercase">
          Motto
        </label>
        <input
          value={motto}
          maxLength={120}
          disabled={completed}
          onChange={(e) => setMotto(e.target.value)}
          placeholder="Es. Corriamo con il cuore"
          className="rounded-xl border border-input bg-input/40 px-4 py-3 outline-none focus:ring-2 focus:ring-ring disabled:opacity-60 disabled:cursor-not-allowed"
        />
      </div>

      {/* ── AVATAR GRID ── */}
      <div>
        <p className="text-xs font-bold tracking-widest text-muted-foreground uppercase">Avatar</p>
        <div className="mt-2 flex flex-wrap gap-2">
          {AVATARS.map((a) => {
            const isMine  = avatar === a;
            const isTaken = !isMine && takenAvatars.has(a);
            const owner   = isTaken ? avatarOwner(a) : null;

            return (
              <button
                key={a}
                disabled={completed || isTaken}
                onClick={() => !completed && !isTaken && setAvatar(a)}
                title={completed ? "Prova completata (modifiche bloccate)" : isTaken ? `Già scelto da: ${owner}` : undefined}
                style={{
                  cursor: completed ? "not-allowed" : isTaken ? "not-allowed" : "pointer",
                  pointerEvents: "all",
                }}
                className={[
                  "relative grid size-12 place-items-center rounded-xl border text-2xl transition-all",
                  isMine
                    ? "border-primary bg-primary/15 scale-105 shadow-md shadow-primary/20"
                    : isTaken || completed
                    ? "border-border/30 bg-secondary/40 opacity-40 grayscale"
                    : "border-border bg-secondary hover:scale-105 hover:border-primary/50",
                ].join(" ")}
              >
                {a}
                {isTaken && (
                  <span className="absolute -bottom-1 -right-1 flex size-4 items-center justify-center rounded-full bg-zinc-700 ring-1 ring-background">
                    <Lock className="size-2.5 text-zinc-300" />
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* ── COLOR GRID ── */}
      <div>
        <p className="text-xs font-bold tracking-widest text-muted-foreground uppercase">Colore</p>
        <div className="mt-2 flex flex-wrap gap-2">
          {COLORS.map((c) => {
            const isMine  = color === c;
            const isTaken = !isMine && takenColors.has(c);
            const owner   = isTaken ? colorOwner(c) : null;

            return (
              <button
                key={c}
                disabled={completed || isTaken}
                onClick={() => !completed && !isTaken && setColor(c)}
                title={completed ? "Prova completata (modifiche bloccate)" : isTaken ? `Già scelto da: ${owner}` : c}
                style={{
                  backgroundColor: c,
                  cursor: completed ? "not-allowed" : isTaken ? "not-allowed" : "pointer",
                  pointerEvents: "all",
                  outline: isMine ? `3px solid white` : "none",
                  outlineOffset: "2px",
                }}
                className={[
                  "relative size-10 rounded-full border-2 transition-all",
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

      {team && (
        <div>
          <p className="text-xs font-bold tracking-widest text-muted-foreground uppercase">
            Membri
          </p>
          <ul className="mt-2 space-y-1 text-sm">
            {(members.data ?? []).map((m) => (
              <li key={m.id} className="rounded-lg bg-secondary/60 px-3 py-2">
                {m.name}
              </li>
            ))}
          </ul>
          {!completed && (
            <div className="mt-2 flex gap-2">
              <input
                value={memberName}
                maxLength={60}
                onChange={(e) => setMemberName(e.target.value)}
                placeholder="Aggiungi membro"
                className="flex-1 rounded-xl border border-input bg-input/40 px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring"
              />
              <button
                onClick={addMember}
                className="rounded-xl border border-border bg-secondary px-4 text-sm font-bold"
              >
                Aggiungi
              </button>
            </div>
          )}
        </div>
      )}

      {!completed && savedAt && (
        <p className="flex items-center gap-1.5 text-xs text-success">
          <Save className="size-3.5" /> Salvato automaticamente alle {savedAt}
        </p>
      )}

      {!team ? (
        <button
          onClick={() => createTeam.mutate()}
          disabled={createTeam.isPending}
          className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl py-3.5 font-extrabold text-primary-foreground disabled:opacity-60"
        >
          {createTeam.isPending && <Loader2 className="size-4 animate-spin" />} Crea la squadra
        </button>
      ) : completed ? (
        <p className="flex items-center gap-2 rounded-xl bg-success/15 px-4 py-3 text-sm font-bold text-success">
          <Check className="size-4" /> Prova completata
        </p>
      ) : (
        <button
          onClick={onComplete}
          disabled={completing}
          className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl py-3.5 font-extrabold text-primary-foreground disabled:opacity-60"
        >
          {completing && <Loader2 className="size-4 animate-spin" />} Conferma e sblocca la prova 2
        </button>
      )}
    </div>
  );
}
