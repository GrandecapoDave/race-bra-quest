import { useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ChevronDown, Eye, History, Sparkles, Zap } from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { myTeamQuery } from "@/lib/race";

export const Route = createFileRoute("/_authenticated/acquisti")({
  head: () => ({
    meta: [
      { title: "I miei acquisti — Pechino Express Bra" },
      { name: "description", content: "Bonus acquistati, malus inviati e ricevuti e storico completo degli acquisti." },
    ],
  }),
  component: AcquistiPage,
});

type SectionId = "bonus" | "sent" | "received" | "history";
const SECTION_IDS: SectionId[] = ["bonus", "sent", "received", "history"];

function fmtDate(v: unknown, withTime = false): string {
  const d = v ? new Date(v as string) : null;
  if (!d || Number.isNaN(d.getTime())) return "—";
  return withTime ? d.toLocaleString("it-IT") : d.toLocaleDateString("it-IT");
}

function AcquistiPage() {
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const team = useQuery(myTeamQuery);

  const items = useQuery({
    queryKey: ["acquisti-items"],
    staleTime: 60_000,
    queryFn: async () => {
      const { data } = await supabase.from("marketplace_items").select("id,nome,tipo,costo_token");
      return (data ?? []) as any[];
    },
  });
  const teams = useQuery({
    queryKey: ["acquisti-teams"],
    staleTime: 30_000,
    queryFn: async () => {
      const { data } = await (supabase as any).from("teams_public").select("id,nome_squadra");
      return (data ?? []) as any[];
    },
  });
  const transactions = useQuery({
    queryKey: ["acquisti-transactions", team.data?.id],
    enabled: Boolean(team.data?.id),
    refetchInterval: 6000,
    queryFn: async () => {
      const { data } = await supabase
        .from("marketplace_transactions")
        .select("id,team_id,target_team_id,marketplace_item_id,costo_token,stato,data_acquisto,dettagli")
        .order("data_acquisto", { ascending: false });
      return (data ?? []) as any[];
    },
  });

  // sezioni aperte/chiuse: la scelta resta sul telefono
  const [open, setOpen] = useState<Record<SectionId, boolean>>(() => {
    const init = { bonus: true, sent: true, received: true, history: true } as Record<SectionId, boolean>;
    try {
      for (const id of SECTION_IDS) {
        const v = localStorage.getItem(`acquisti-open:${id}`);
        if (v === "0") init[id] = false;
      }
    } catch { /* ignore */ }
    return init;
  });
  const setSection = (id: SectionId, value: boolean) => {
    setOpen((prev) => ({ ...prev, [id]: value }));
    try { localStorage.setItem(`acquisti-open:${id}`, value ? "1" : "0"); } catch { /* ignore */ }
  };
  const setAll = (value: boolean) => SECTION_IDS.forEach((id) => setSection(id, value));

  const meId = team.data?.id;
  const itemById = new Map((items.data ?? []).map((i: any) => [i.id, i]));
  const teamName = (id?: string | null) => (teams.data ?? []).find((t: any) => t.id === id)?.nome_squadra;
  const all = transactions.data ?? [];
  const mine = meId ? all.filter((t) => t.team_id === meId) : [];
  const isMalus = (t: any) => String(itemById.get(t.marketplace_item_id)?.tipo ?? "").toLowerCase() === "malus";
  const isBonus = (t: any) =>
    String(itemById.get(t.marketplace_item_id)?.tipo ?? "").toLowerCase() === "bonus" &&
    t.marketplace_item_id !== "reward_stage" &&
    t.marketplace_item_id !== "admin_token_adjust";
  const bonuses = mine.filter(isBonus);
  const sent = mine.filter(isMalus);
  const received = meId ? all.filter((t) => t.target_team_id === meId) : [];
  const itemName = (id: string) => itemById.get(id)?.nome ?? id;

  return (
    <AppShell isAdmin={isAdmin.data}>
      <div className="mx-auto max-w-2xl space-y-4 pb-10">
        <div className="flex items-end justify-between gap-3">
          <div>
            <h1 className="text-3xl sm:text-4xl leading-none">I miei acquisti</h1>
            <p className="mt-1.5 text-[11px] sm:text-sm text-muted-foreground">Bonus, malus e storico della tua squadra.</p>
          </div>
          <div className="flex shrink-0 gap-1.5">
            <button
              type="button"
              onClick={() => setAll(true)}
              className="h-9 rounded-xl border border-border/50 bg-secondary/50 px-3 text-[11px] font-black uppercase tracking-wider text-foreground hover:bg-secondary cursor-pointer"
            >
              Apri tutte
            </button>
            <button
              type="button"
              onClick={() => setAll(false)}
              className="h-9 rounded-xl border border-border/50 bg-secondary/50 px-3 text-[11px] font-black uppercase tracking-wider text-foreground hover:bg-secondary cursor-pointer"
            >
              Chiudi tutte
            </button>
          </div>
        </div>

        <Section id="bonus" title="🎁 Bonus acquistati" count={bonuses.length} icon={<Sparkles className="size-4" />} tone="text-emerald-400" open={open.bonus} onToggle={setSection}>
          {bonuses.length === 0 ? (
            <p className="py-3 text-center text-xs italic text-muted-foreground">Nessun bonus acquistato.</p>
          ) : (
            <ul className="space-y-2">
              {bonuses.map((b) => {
                const used = b.stato === "used";
                const isClassifica = b.marketplace_item_id === "bonus_classifica";
                return (
                  <li key={b.id} className="space-y-2 rounded-xl border border-zinc-800 bg-zinc-900/40 p-3 text-xs">
                    <div className="flex items-start justify-between gap-2">
                      <span className="min-w-0 break-words font-extrabold text-foreground">{itemName(b.marketplace_item_id)}</span>
                      <span className="shrink-0 text-[10px] font-bold text-emerald-400">-{b.costo_token ?? 0} 🪙</span>
                    </div>
                    <div className="flex items-center justify-between text-[10px] text-zinc-500">
                      <span>Stato: <strong className="text-zinc-300">{used ? "Utilizzato" : b.stato === "blocked" ? "Bloccato" : "Attivo"}</strong></span>
                      <span>{fmtDate(b.data_acquisto)}</span>
                    </div>
                    {isClassifica && (
                      <div className="flex justify-end border-t border-border/5 pt-1.5">
                        {used ? (
                          <span className="text-[10px] font-bold uppercase italic tracking-wider text-zinc-500">Visualizzata 👁️</span>
                        ) : (
                          <Link
                            to="/classifica"
                            className="flex items-center gap-1 rounded-lg border border-emerald-500/20 bg-emerald-500/10 px-2.5 py-1 text-[9px] font-black uppercase tracking-wider text-emerald-400 transition-all active:scale-[0.97]"
                          >
                            <Eye className="size-3" /> Vedi classifica live
                          </Link>
                        )}
                      </div>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
        </Section>

        <Section id="sent" title="⚔️ Malus inviati" count={sent.length} icon={<Zap className="size-4" />} tone="text-rose-400" open={open.sent} onToggle={setSection}>
          {sent.length === 0 ? (
            <p className="py-3 text-center text-xs italic text-muted-foreground">Nessun malus inviato.</p>
          ) : (
            <ul className="space-y-2">
              {sent.map((m) => (
                <li key={m.id} className="space-y-1 rounded-xl border border-zinc-800 bg-zinc-900/40 p-3 text-xs">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-extrabold text-foreground">{itemName(m.marketplace_item_id)}</span>
                    <span className="text-[10px] font-bold text-rose-500">-{m.costo_token ?? 0} 🪙</span>
                  </div>
                  <div className="flex items-center justify-between text-[10px] text-zinc-500">
                    <span>Colpita: <strong className="text-rose-400/90">{teamName(m.target_team_id) || "Sconosciuta"}</strong></span>
                    <span>{fmtDate(m.data_acquisto)}</span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Section>

        <Section id="received" title="⚠️ Malus ricevuti" count={received.length} icon={<AlertTriangle className="size-4" />} tone="text-amber-500" open={open.received} onToggle={setSection}>
          {received.length === 0 ? (
            <p className="py-3 text-center text-xs italic text-muted-foreground">Nessun malus ricevuto. Siete al sicuro!</p>
          ) : (
            <ul className="space-y-2">
              {received.map((m) => {
                const blocked = m.stato === "expired" || Boolean(m.dettagli?.blocked_by_shield_id);
                return (
                  <li key={m.id} className="space-y-1 rounded-xl border border-zinc-800 bg-zinc-900/40 p-3 text-xs">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-extrabold text-foreground">{itemName(m.marketplace_item_id)}</span>
                      <span className={`text-[10px] font-bold ${blocked ? "text-emerald-400" : "text-amber-500"}`}>
                        {blocked ? "🛡️ Bloccato da Scudo" : "Ricevuto"}
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-[10px] text-zinc-500">
                      <span>Mandato da: <strong className="text-amber-400">{teamName(m.team_id) || "Anonimo"}</strong></span>
                      <span>{fmtDate(m.data_acquisto)}</span>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </Section>

        <Section id="history" title="Storico completo acquisti gara" count={mine.length} icon={<History className="size-4" />} tone="text-orange-500" open={open.history} onToggle={setSection}>
          {mine.length === 0 ? (
            <p className="py-3 text-center text-xs italic text-muted-foreground">Nessuna transazione effettuata.</p>
          ) : (
            <div className="divide-y divide-border/10">
              {mine.map((t) => {
                const isReward = t.marketplace_item_id === "reward_stage" || Number(t.costo_token ?? 0) < 0;
                const cat = String(itemById.get(t.marketplace_item_id)?.tipo ?? "").toUpperCase();
                const target = teamName(t.target_team_id);
                const cost = Math.abs(Number(t.costo_token ?? 0));
                const label = isReward ? `🏁 RICOMPENSA TAPPA ${t.dettagli?.stage_index ?? ""}` : itemName(t.marketplace_item_id);
                return (
                  <div key={t.id} className="flex min-w-0 items-start justify-between gap-2 py-3 text-xs">
                    <div className="min-w-0 space-y-0.5">
                      <p className="flex min-w-0 flex-wrap items-center gap-1.5 font-extrabold text-foreground">
                        <span className="min-w-0 break-words">{label}</span>
                        <span className={`shrink-0 rounded px-1.5 py-0.5 text-[9px] font-black uppercase ${
                          isReward ? "bg-yellow-500/10 text-yellow-400" : cat === "BONUS" ? "bg-emerald-500/10 text-emerald-400" : "bg-red-500/10 text-red-400"
                        }`}>
                          {isReward ? "RICOMPENSA" : cat || "N/A"}
                        </span>
                      </p>
                      <p className="text-[10px] text-zinc-500">
                        {fmtDate(t.data_acquisto, true)}
                        {target && <span> · Bersaglio: <strong className="text-zinc-400">{target}</strong></span>}
                        {isReward && t.dettagli?.position && <span> · Posizione: <strong className="text-zinc-400">{t.dettagli.position}ª</strong></span>}
                      </p>
                    </div>
                    <span className={`flex shrink-0 items-center gap-0.5 font-black ${isReward ? "text-emerald-400" : "text-red-500"}`}>
                      {isReward ? "+" : "-"}{cost} 🪙
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </Section>
      </div>
    </AppShell>
  );
}

function Section({
  id, title, count, icon, tone, open, onToggle, children,
}: {
  id: SectionId;
  title: string;
  count: number;
  icon: React.ReactNode;
  tone: string;
  open: boolean;
  onToggle: (id: SectionId, value: boolean) => void;
  children: React.ReactNode;
}) {
  return (
    <section className="overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950/20">
      <button
        type="button"
        onClick={() => onToggle(id, !open)}
        aria-expanded={open}
        className="flex w-full min-h-12 cursor-pointer items-center justify-between gap-3 px-4 py-3 text-left"
      >
        <span className={`flex items-center gap-2 text-sm font-black uppercase tracking-wider ${tone}`}>
          {icon} {title}
        </span>
        <span className="flex items-center gap-2">
          <span className="min-w-6 rounded-full border border-border/50 bg-secondary/70 px-2 py-0.5 text-center text-[11px] font-black text-foreground">{count}</span>
          <ChevronDown className={`size-4 text-zinc-400 transition-transform ${open ? "rotate-180" : ""}`} />
        </span>
      </button>
      {open && <div className="border-t border-border/20 px-4 pb-4 pt-3">{children}</div>}
    </section>
  );
}
