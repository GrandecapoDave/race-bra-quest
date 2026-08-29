import { createFileRoute } from "@tanstack/react-router";
import { Coins, History, Loader2, ShoppingBag, Snowflake } from "lucide-react";
import { useAdminContext } from "../admin";
import { useState, useEffect } from "react";

export const Route = createFileRoute("/_authenticated/admin/marketplace")({
  component: AdminMarketplacePage,
});

function AdminMarketplacePage() {
  const {
    marketplaceTransactions,
    gameSettings,
    allTeams,
    handleToggleMarketplace,
    isTogglingMarketplace
  } = useAdminContext();

  const MARKETPLACE_ITEMS = [
    { id: "bonus_punti", nome: "BONUS PUNTI (+20 PT)", categoria: "BONUS", costo: 40, desc: "Aggiunge +20 PT alla classifica." },
    { id: "bonus_scudo", nome: "BONUS SCUDO", categoria: "BONUS", costo: 35, desc: "Protegge la squadra da un malus attivo." },
    { id: "ruota_fortuna", nome: "RUOTA DELLA FORTUNA", categoria: "BONUS", costo: 25, desc: "Gira la ruota per vincere premi immediati." },
    { id: "passaparola", nome: "PASSAPAROLA", categoria: "BONUS", costo: 20, desc: "Ricevi un aiuto dalla regia (Sì/No)." },
    { id: "bonus_classifica", nome: "BONUS CLASSIFICA", categoria: "BONUS", costo: 30, desc: "Visualizza temporaneamente la classifica generale." },
    { id: "partenza_anticipata", nome: "PARTENZA ANTICIPATA", categoria: "BONUS", costo: 35, desc: "Riduce di 2 minuti il tempo di partenza." },
    { id: "moltiplicatore_2x", nome: "MOLTIPLICATORE 2X TAPPA", categoria: "BONUS", costo: 45, desc: "Raddoppia (x2) il punteggio della tappa." },
    { id: "polizza_diretta", nome: "POLIZZA RIMBORSO 50%", categoria: "BONUS", costo: 30, desc: "Rimborsa il 50% dei punti persi da un malus." },
    { id: "freeze_2min", nome: "FREEZE 2 MINUTI", categoria: "MALUS", costo: 20, desc: "Blocca una squadra avversaria per 2 minuti." },
    { id: "enigma_extra", nome: "ENIGMA EXTRA", categoria: "MALUS", costo: 25, desc: "Obbliga gli avversari a risolvere un enigma aggiuntivo." },
    { id: "ruota_sfortunata", nome: "RUOTA SFORTUNATA", categoria: "MALUS", costo: 20, desc: "Obbliga gli avversari a fare uno spin sfortunato." },
    { id: "trappola", nome: "TRAPPOLA", categoria: "MALUS", costo: 40, desc: "Ruba fino a 30 punti alla squadra bersaglio." },
    { id: "penalita_punti", nome: "PENALITÀ PUNTI (-20 PT)", categoria: "MALUS", costo: 30, desc: "Sottrae 20 punti ad una squadra avversaria." },
    { id: "tassa_passaggio", nome: "TASSA DI PASSAGGIO", categoria: "MALUS", costo: 70, desc: "Scambia il punteggio con la squadra bersaglio." },
    { id: "blackout_mercato", nome: "BLACKOUT MERCATO 6 MINUTI", categoria: "MALUS", costo: 35, desc: "Blocca il Marketplace al bersaglio per 6 minuti." },
    { id: "dimezza_punti", nome: "DIMEZZA PUNTI PROSSIMA SFIDA", categoria: "MALUS", costo: 40, desc: "Dimezza del 50% i punti della prossima sfida superata dal bersaglio." },
  ];
  
  const [time, setTime] = useState(Date.now());
  useEffect(() => {
    const interval = setInterval(() => setTime(Date.now()), 1000);
    return () => clearInterval(interval);
  }, []);

  const transactions = marketplaceTransactions.data ?? [];
  const frozenTeams = (allTeams.data ?? []).filter((t: any) => {
    return t.freeze_expires_at && new Date(t.freeze_expires_at).getTime() > Date.now();
  });

  const settings = gameSettings.data as any;
  const isMarketplaceActive = settings?.marketplace_active === true;
  const totalPurchases = transactions.length;
  const totalTokensSpent = transactions.reduce((acc: number, t: any) => {
    const c = t.costo ?? t.costo_token ?? 0;
    return c > 0 ? acc + c : acc;
  }, 0);
  const activatedAt = settings?.activated_at ? new Date(settings.activated_at).toLocaleString("it-IT") : "Non disponibile";
  const activatedBy = settings?.activated_by || "Non disponibile";

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-2xl font-display font-black uppercase tracking-wider text-muted-foreground">
            Monitoraggio Marketplace
          </h2>
          <p className="text-xs text-muted-foreground mt-0.5">
            Visualizza i saldi dei token delle squadre, i bonus acquistati, i malus scambiati e lo storico complessivo della gara.
          </p>
        </div>
      </div>

      {/* CONTROLLO MARKETPLACE CARD */}
      <div className="surface p-6 border rounded-2xl bg-zinc-950/40 border-zinc-800 shadow-xl space-y-6">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-border/10 pb-4">
          <div>
            <h3 className="font-extrabold text-sm uppercase tracking-wider text-primary flex items-center gap-2">
              <ShoppingBag className="size-4 text-orange-500" /> Controllo Marketplace
            </h3>
            <p className="text-[10px] text-muted-foreground mt-0.5">
              Abilita o disabilita gli acquisti per tutti i partecipanti in tempo reale.
            </p>
          </div>
          <div className="flex items-center gap-2 bg-zinc-900 px-3 py-1.5 rounded-xl border border-zinc-800 shrink-0">
            <span className="text-xs text-muted-foreground font-bold">Stato:</span>
            <span className={`text-xs font-black px-2 py-0.5 rounded flex items-center gap-1 ${
              isMarketplaceActive ? "bg-emerald-500/10 text-emerald-400" : "bg-red-500/10 text-red-400"
            }`}>
              <span className="size-1.5 rounded-full bg-current animate-pulse" />
              {isMarketplaceActive ? "🟢 Attivo" : "🔴 Chiuso"}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-zinc-900/30 p-3 rounded-xl border border-border/5 space-y-1">
            <span className="text-[8px] uppercase tracking-wider text-muted-foreground font-extrabold block">Data Apertura</span>
            <span className="text-xs font-black text-foreground block truncate">{activatedAt}</span>
          </div>
          <div className="bg-zinc-900/30 p-3 rounded-xl border border-border/5 space-y-1">
            <span className="text-[8px] uppercase tracking-wider text-muted-foreground font-extrabold block">Aperto da (Admin)</span>
            <span className="text-xs font-black text-foreground block truncate">{activatedBy}</span>
          </div>
          <div className="bg-zinc-900/30 p-3 rounded-xl border border-border/5 space-y-1">
            <span className="text-[8px] uppercase tracking-wider text-muted-foreground font-extrabold block">Numero Totale Acquisti</span>
            <span className="text-sm font-black text-orange-400 block">{totalPurchases}</span>
          </div>
          <div className="bg-zinc-900/30 p-3 rounded-xl border border-border/5 space-y-1">
            <span className="text-[8px] uppercase tracking-wider text-muted-foreground font-extrabold block">Token Totali Spesi</span>
            <span className="text-sm font-black text-amber-500 block">{totalTokensSpent} 🪙</span>
          </div>
        </div>

        <div className="flex flex-wrap gap-3 pt-2">
          <button
            onClick={() => handleToggleMarketplace(true)}
            disabled={isMarketplaceActive || isTogglingMarketplace}
            className={`px-4 py-2.5 rounded-xl text-xs font-black uppercase tracking-wider flex items-center gap-1.5 transition-all cursor-pointer ${
              isMarketplaceActive
                ? "bg-zinc-900 border border-zinc-800 text-muted-foreground cursor-not-allowed"
                : "bg-emerald-600 hover:bg-emerald-500 text-white shadow-md shadow-emerald-500/10 active:scale-[0.98]"
            }`}
          >
            {isTogglingMarketplace ? <Loader2 className="size-3.5 animate-spin" /> : <span className="size-2 rounded-full bg-white animate-pulse" />}
            Apri Marketplace
          </button>

          <button
            onClick={() => handleToggleMarketplace(false)}
            disabled={!isMarketplaceActive || isTogglingMarketplace}
            className={`px-4 py-2.5 rounded-xl text-xs font-black uppercase tracking-wider flex items-center gap-1.5 transition-all cursor-pointer ${
              !isMarketplaceActive
                ? "bg-zinc-900 border border-zinc-800 text-muted-foreground cursor-not-allowed"
                : "bg-red-600 hover:bg-red-500 text-white shadow-md shadow-red-500/10 active:scale-[0.98]"
            }`}
          >
            {isTogglingMarketplace ? <Loader2 className="size-3.5 animate-spin" /> : <span className="size-2 rounded-full bg-white animate-pulse" />}
            Chiudi Marketplace
          </button>
        </div>
      </div>

      {/* TEAM TOKENS AND DETAILS GRID */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Saldi Token e Stato Squadre */}
        <div className="lg:col-span-1 space-y-4">
          <h3 className="text-sm font-black uppercase tracking-wider text-primary flex items-center gap-2 border-b border-border/20 pb-2">
            <Coins className="size-4 text-orange-500" /> Saldi Token Squadre
          </h3>
          <div className="space-y-3">
            {(allTeams.data ?? []).map((t: any) => {
              const teamPurchases = transactions.filter((tr: any) => tr.buyer_team_id === t.id);
              const bonuses = teamPurchases.filter((tr: any) => {
                const item = MARKETPLACE_ITEMS.find((i) => i.id === tr.item_id);
                return item?.categoria === "BONUS";
              });
              const sentMaluses = teamPurchases.filter((tr: any) => {
                const item = MARKETPLACE_ITEMS.find((i) => i.id === tr.item_id);
                return item?.categoria === "MALUS";
              });
              const receivedMaluses = transactions.filter((tr: any) => tr.target_team_id === t.id);

              return (
                <div
                  key={t.id}
                  className="surface p-4 border rounded-xl space-y-3 bg-zinc-950/40 relative overflow-hidden transition-all hover:border-zinc-700"
                  style={{ borderLeft: `3px solid ${t.color}` }}
                >
                  <div className="flex justify-between items-center">
                    <div className="flex items-center gap-2 min-w-0">
                      <span className="text-base shrink-0">{t.avatar_url ?? "🏳️"}</span>
                      <span className="font-extrabold text-sm text-foreground truncate">{t.nome_squadra}</span>
                    </div>
                    <span className="text-xs font-black bg-zinc-900 px-2 py-1 rounded border border-zinc-800 text-orange-400">
                      {t.token_balance ?? 50} 🪙
                    </span>
                  </div>

                  {/* Summary details */}
                  <div className="grid grid-cols-3 gap-1 pt-2 border-t border-border/10 text-[10px] text-zinc-400">
                    <div className="space-y-0.5">
                      <span className="block text-[8px] uppercase tracking-wider text-emerald-400 font-extrabold">🎁 Bonus</span>
                      <span className="font-black text-foreground">{bonuses.length}</span>
                    </div>
                    <div className="space-y-0.5">
                      <span className="block text-[8px] uppercase tracking-wider text-rose-400 font-extrabold">⚔️ Inviati</span>
                      <span className="font-black text-foreground">{sentMaluses.length}</span>
                    </div>
                    <div className="space-y-0.5">
                      <span className="block text-[8px] uppercase tracking-wider text-amber-500 font-extrabold">⚠️ Ricevuti</span>
                      <span className="font-black text-foreground">{receivedMaluses.length}</span>
                    </div>
                  </div>

                  {/* List details */}
                  <div className="space-y-1.5 pt-2 border-t border-border/10 text-[9px] leading-relaxed">
                    {bonuses.length > 0 && (
                      <div>
                        <strong className="text-emerald-400 font-bold block">Bonus acquistati:</strong>
                        <span className="text-zinc-400 truncate block">
                          {bonuses.map((b: any) => MARKETPLACE_ITEMS.find((i) => i.id === b.item_id)?.nome || b.item_id).join(", ")}
                        </span>
                      </div>
                    )}
                    {sentMaluses.length > 0 && (
                      <div>
                        <strong className="text-rose-400 font-bold block">Malus inviati:</strong>
                        <div className="space-y-0.5 max-h-[50px] overflow-y-auto pr-1">
                          {sentMaluses.map((m: any) => {
                            const details = MARKETPLACE_ITEMS.find((i) => i.id === m.item_id);
                            const target = (allTeams.data ?? []).find((tm: any) => tm.id === m.target_team_id);
                            return (
                              <div key={m.id} className="text-zinc-400 flex justify-between gap-1">
                                <span className="truncate">{details?.nome}</span>
                                <span className="text-rose-500 font-extrabold shrink-0">→ {target?.nome_squadra || "Sconosciuta"}</span>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                    {receivedMaluses.length > 0 && (
                      <div>
                        <strong className="text-amber-500 font-bold block">Malus subiti:</strong>
                        <div className="space-y-0.5 max-h-[50px] overflow-y-auto pr-1">
                          {receivedMaluses.map((m: any) => {
                            const details = MARKETPLACE_ITEMS.find((i) => i.id === m.item_id);
                            const buyer = (allTeams.data ?? []).find((tm: any) => tm.id === m.buyer_team_id);
                            return (
                              <div key={m.id} className="text-zinc-400 flex justify-between gap-1">
                                <span className="truncate">{details?.nome}</span>
                                <span className="text-amber-500 font-extrabold shrink-0">← {buyer?.nome_squadra || "Anonimo"}</span>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Storico Completo Transazioni */}
        <div className="lg:col-span-2 space-y-6">
          {/* MONITORAGGIO FREEZE ATTIVI */}
          {frozenTeams.length > 0 && (
            <div className="surface p-5 border border-cyan-500/20 bg-cyan-950/5 rounded-2xl space-y-3 animate-in fade-in zoom-in-95 duration-300">
              <h3 className="font-extrabold text-sm uppercase tracking-wider text-cyan-400 flex items-center gap-2">
                <Snowflake className="size-4 text-cyan-400 animate-pulse" /> Monitoraggio Freeze Attivi
              </h3>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-cyan-500/10 text-cyan-500 font-bold uppercase tracking-wider text-[9px] pb-1.5">
                      <th className="pb-2">Squadra Bersaglio</th>
                      <th className="pb-2">Attaccante</th>
                      <th className="pb-2 text-right">Inizio</th>
                      <th className="pb-2 text-right">Fine Prevista</th>
                      <th className="pb-2 text-right">Tempo Residuo</th>
                      <th className="pb-2 text-right">Stato</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-cyan-500/10">
                    {frozenTeams.map((t: any) => {
                      const activeTx = transactions.find(
                        (tr: any) => tr.target_team_id === t.id && tr.item_id === "freeze_2min" && tr.stato === "completed"
                      );
                      const attacker = (allTeams.data ?? []).find((tm: any) => tm.id === activeTx?.buyer_team_id);
                      
                      const expiresMs = t.freeze_expires_at ? new Date(t.freeze_expires_at).getTime() : 0;
                      const remainingSec = Math.max(0, Math.ceil((expiresMs - Date.now()) / 1000));
                      
                      const formatTime = (sec: number) => {
                        const mm = Math.floor(sec / 60).toString().padStart(2, "0");
                        const ss = (sec % 60).toString().padStart(2, "0");
                        return `${mm}:${ss}`;
                      };

                      return (
                        <tr key={t.id} className="hover:bg-cyan-500/5">
                          <td className="py-2.5 font-extrabold text-foreground flex items-center gap-1.5">
                            <span style={{ color: t.color }}>●</span>
                            <span>{t.avatar_url} {t.nome_squadra}</span>
                          </td>
                          <td className="py-2.5 font-semibold text-zinc-300">
                            {attacker ? `${attacker.avatar_url} ${attacker.nome_squadra}` : "Sconosciuta"}
                          </td>
                          <td className="py-2.5 text-right text-zinc-400 font-mono">
                            {t.freeze_started_at ? new Date(t.freeze_started_at).toLocaleTimeString("it-IT") : "—"}
                          </td>
                          <td className="py-2.5 text-right text-zinc-400 font-mono">
                            {t.freeze_expires_at ? new Date(t.freeze_expires_at).toLocaleTimeString("it-IT") : "—"}
                          </td>
                          <td className="py-2.5 text-right text-cyan-400 font-mono font-black animate-pulse">
                            {formatTime(remainingSec)}
                          </td>
                          <td className="py-2.5 text-right">
                            <span className="text-[9px] bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 px-2 py-0.5 rounded font-black uppercase tracking-widest">
                              🟡 ATTIVO
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          <div className="space-y-4">
            <h3 className="text-sm font-black uppercase tracking-wider text-primary flex items-center gap-2 border-b border-border/20 pb-2">
              <History className="size-4 text-orange-500" /> Registro Transazioni Globale
            </h3>
          <div className="surface border rounded-2xl bg-zinc-950/20 p-5">
            {transactions.length === 0 ? (
              <p className="text-xs text-muted-foreground italic text-center py-10 font-semibold">
                Nessuna transazione effettuata nel gioco finora.
              </p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-border/20 text-muted-foreground font-black uppercase tracking-wider text-[10px] pb-2">
                      <th className="py-2.5">Squadra</th>
                      <th className="py-2.5">Articolo</th>
                      <th className="py-2.5">Tipo</th>
                      <th className="py-2.5">Bersaglio</th>
                      <th className="py-2.5">Costo</th>
                      <th className="py-2.5 text-right">Data/Ora</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/10">
                    {transactions.map((tr: any) => {
                      const buyerTeam = (allTeams.data ?? []).find((t: any) => t.id === tr.buyer_team_id);
                      const targetTeam = (allTeams.data ?? []).find((t: any) => t.id === tr.target_team_id);
                      const isReward = tr.item_id === "reward_stage";
                      const details = isReward ? {
                        nome: `🏁 RICOMPENSA TAPPA ${tr.outcome?.stage_index ?? ""}`,
                        categoria: "RICOMPENSA"
                      } : MARKETPLACE_ITEMS.find((i) => i.id === tr.item_id);

                      return (
                        <tr key={tr.id} className="hover:bg-zinc-900/20 transition-colors">
                          <td className="py-3 font-extrabold text-foreground flex items-center gap-1.5">
                            <span style={{ color: buyerTeam?.color }}>●</span>
                            {buyerTeam?.nome_squadra || "Sconosciuta"}
                          </td>
                          <td className="py-3 font-bold text-foreground">
                            <div>
                              <span>{details?.nome || tr.item_id}</span>
                              {tr.item_id === "bonus_scudo" && (
                                <span className={`block text-[9px] font-black uppercase mt-0.5 ${
                                  tr.stato === "used" ? "text-zinc-500" : "text-blue-400 animate-pulse"
                                }}`}>
                                  {tr.stato === "used" ? "🛡️ CONSUMATO" : "🛡️ ATTIVO"}
                                </span>
                              )}
                              {tr.item_id === "bonus_scudo" && tr.stato === "used" && (() => {
                                const blockedInfo = tr.blocked_info;
                                const blockedMalusDetails = blockedInfo ? MARKETPLACE_ITEMS.find((i) => i.id === blockedInfo.item_id) : null;
                                const attackerTeam = blockedInfo ? (allTeams.data ?? []).find((t: any) => t.id === blockedInfo.attacker_team_id) : null;
                                return (
                                  <span className="block text-[9px] text-zinc-500 italic font-medium mt-0.5 leading-normal">
                                    Ha bloccato: {blockedMalusDetails?.nome || blockedInfo?.item_id || "Malus"} di {attackerTeam?.nome_squadra || "avversario"}
                                  </span>
                                );
                              })()}
                              {tr.stato === "blocked" && (
                                <span className="block text-[9px] text-red-500 font-black uppercase mt-0.5">
                                  🛡️ BLOCCATO DA SCUDO
                                </span>
                              )}
                              {tr.item_id === "bonus_classifica" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  <span className={`block font-black uppercase ${
                                    tr.stato === "used" ? "text-zinc-500" : "text-purple-400 animate-pulse"
                                  }`}>
                                    {tr.stato === "used" ? "🔒 CONSUMATO" : "🔓 VISUALIZZABILE"}
                                  </span>
                                  {tr.outcome?.snapshot && (
                                    <div className="bg-zinc-950/40 p-1.5 rounded border border-zinc-900 font-semibold space-y-0.5 mt-1 leading-normal">
                                      <strong className="block text-[8px] text-zinc-400 uppercase tracking-wide">Snapshot Classifica:</strong>
                                      {tr.outcome.snapshot.map((row: any, idx: number) => (
                                        <div key={row.team_id} className="flex justify-between gap-2 text-zinc-500">
                                          <span>{idx + 1}° {row.name}</span>
                                          <span className="font-mono">{row.total_points} PT</span>
                                        </div>
                                      ))}
                                    </div>
                                  )}
                                </div>
                              )}
                              {tr.item_id === "freeze_2min" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  {(() => {
                                    if (tr.stato === "blocked") return null;
                                    const target = (allTeams.data ?? []).find((tm: any) => tm.id === tr.target_team_id);
                                    const isActive = target && target.freeze_expires_at === tr.outcome?.freeze_expires_at && new Date(target.freeze_expires_at).getTime() > Date.now();
                                    return (
                                      <>
                                        <span className={`block font-black uppercase ${
                                          isActive ? "text-cyan-400 animate-pulse" : "text-emerald-400"
                                        }`}>
                                          {isActive ? "❄️ ATTIVO" : "🟢 CONCLUSO"}
                                        </span>
                                        {tr.outcome && (
                                          <span className="block text-[8px] text-zinc-500 leading-normal">
                                            Inizio: {new Date(tr.outcome.freeze_started_at).toLocaleTimeString("it-IT")} · Fine: {new Date(tr.outcome.freeze_expires_at).toLocaleTimeString("it-IT")}
                                          </span>
                                        )}
                                      </>
                                    );
                                  })()}
                                </div>
                              )}
                              {tr.item_id === "enigma_extra" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  {(() => {
                                    if (tr.stato === "blocked") return null;
                                    const isActive = tr.stato === "completed";
                                    return (
                                      <>
                                        <span className={`block font-black uppercase ${
                                          isActive ? "text-purple-400 animate-pulse" : "text-emerald-400"
                                        }`}>
                                          {isActive ? "🟡 ATTIVO" : "🟢 COMPLETATO"}
                                        </span>
                                        {tr.outcome && (
                                          <div className="text-[8px] text-zinc-500 space-y-0.5 leading-normal mt-1">
                                            <span className="block text-purple-400 font-bold">Soluzione: LANTERNA</span>
                                            <span className="block">Assegnato: {new Date(tr.outcome.assigned_at).toLocaleString("it-IT")}</span>
                                            {tr.outcome.solved_at && (
                                              <>
                                                <span className="block">Risolto: {new Date(tr.outcome.solved_at).toLocaleString("it-IT")}</span>
                                                <span className="block text-zinc-400 font-semibold">
                                                  Risposta inviata: <strong className="text-white">"{tr.outcome.submitted_answer}"</strong>
                                                </span>
                                              </>
                                            )}
                                          </div>
                                        )}
                                      </>
                                    );
                                  })()}
                                </div>
                              )}
                              {tr.item_id === "ruota_sfortunata" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  {(() => {
                                    if (tr.stato === "blocked") return null;
                                    const isActive = tr.stato === "completed";
                                    return (
                                      <>
                                        <span className={`block font-black uppercase ${
                                          isActive ? "text-amber-500 animate-pulse" : "text-emerald-400"
                                        }`}>
                                          {isActive ? "🟡 IN ATTESA DI SPIN" : "🟢 COMPLETATO"}
                                        </span>
                                        {tr.outcome && (
                                          <div className="text-[8px] text-zinc-500 space-y-0.5 leading-normal mt-1">
                                            <span className="block text-amber-400 font-bold">Risultato: {tr.outcome.label}</span>
                                            {tr.outcome.spun_at && (
                                              <span className="block">Ora Spin: {new Date(tr.outcome.spun_at).toLocaleTimeString("it-IT")}</span>
                                            )}
                                          </div>
                                        )}
                                      </>
                                    );
                                  })()}
                                </div>
                              )}
                              {tr.item_id === "trappola" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  {(() => {
                                    if (tr.stato === "blocked") return null;
                                    return (
                                      <>
                                        <span className="block font-black text-emerald-400 uppercase">
                                          🟢 APPLICATA
                                        </span>
                                        {tr.outcome && (
                                          <div className="text-[8px] text-zinc-500 space-y-0.5 leading-normal mt-1 bg-zinc-950/40 p-2 rounded-lg border border-zinc-900/60 max-w-[240px]">
                                            <div className="flex justify-between text-zinc-400 font-bold border-b border-zinc-900 pb-0.5">
                                              <span>Punti nominali:</span>
                                              <span>{tr.outcome.nominal_points || 30} PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti rubati:</span>
                                              <span className="text-red-400 font-bold">-{tr.outcome.points_stolen} PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti bersaglio:</span>
                                              <span>{tr.outcome.target_points_before} → {tr.outcome.target_points_after} PT</span>
                                            </div>
                                            <div className="flex justify-between border-t border-zinc-900 pt-0.5">
                                              <span>Punti acquirente:</span>
                                              <span className="text-emerald-400 font-bold">+{tr.outcome.points_stolen} PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti acquirente:</span>
                                              <span>{tr.outcome.buyer_points_before} → {tr.outcome.buyer_points_after} PT</span>
                                            </div>
                                          </div>
                                        )}
                                      </>
                                    );
                                  })()}
                                </div>
                              )}
                              {tr.item_id === "penalita_punti" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  {(() => {
                                    if (tr.stato === "blocked") return null;
                                    return (
                                      <>
                                        <span className="block font-black text-emerald-400 uppercase">
                                          🟢 APPLICATA
                                        </span>
                                        {tr.outcome && (
                                          <div className="text-[8px] text-zinc-500 space-y-0.5 leading-normal mt-1 bg-zinc-950/40 p-2 rounded-lg border border-zinc-900/60 max-w-[240px]">
                                            <div className="flex justify-between text-zinc-400 font-bold border-b border-zinc-900 pb-0.5">
                                              <span>Penalità nominale:</span>
                                              <span>-20 PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti sottratti:</span>
                                              <span className="text-red-400 font-bold">-{tr.outcome.points_deducted} PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti bersaglio prima:</span>
                                              <span>{tr.outcome.target_points_before} PT</span>
                                            </div>
                                            <div className="flex justify-between border-t border-zinc-900 pt-0.5">
                                              <span>Punti bersaglio dopo:</span>
                                              <span>{tr.outcome.target_points_after} PT</span>
                                            </div>
                                            {tr.outcome.points_deducted < 20 && (
                                              <div className="text-[7px] text-orange-400 italic mt-0.5">
                                                Motivo: Punteggio insufficiente
                                              </div>
                                            )}
                                          </div>
                                        )}
                                      </>
                                    );
                                  })()}
                                </div>
                              )}
                              {tr.item_id === "tassa_passaggio" && (
                                <div className="space-y-0.5 mt-1 text-[9px] text-zinc-500 font-medium">
                                  {(() => {
                                    if (tr.stato === "blocked") return null;
                                    return (
                                      <>
                                        <span className="block font-black text-emerald-400 uppercase">
                                          🟢 APPLICATO
                                        </span>
                                        {tr.outcome && (
                                          <div className="text-[8px] text-zinc-500 space-y-0.5 leading-normal mt-1 bg-zinc-950/40 p-2 rounded-lg border border-zinc-900/60 max-w-[240px]">
                                            <div className="flex justify-between text-zinc-400 font-bold border-b border-zinc-900 pb-0.5">
                                              <span>Tipo:</span>
                                              <span>SWITCH LIVE PUNTI</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti acquirente prima:</span>
                                              <span>{tr.outcome.buyer_points_before} PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti acquirente dopo:</span>
                                              <span className="text-emerald-400 font-bold">{tr.outcome.buyer_points_after} PT</span>
                                            </div>
                                            <div className="flex justify-between border-t border-zinc-900 pt-0.5">
                                              <span>Punti bersaglio prima:</span>
                                              <span>{tr.outcome.target_points_before} PT</span>
                                            </div>
                                            <div className="flex justify-between">
                                              <span>Punti bersaglio dopo:</span>
                                              <span className="text-red-400 font-bold">{tr.outcome.target_points_after} PT</span>
                                            </div>
                                          </div>
                                        )}
                                      </>
                                    );
                                  })()}
                                </div>
                              )}
                              {isReward && tr.outcome && (
                                <span className="block text-[9px] text-zinc-500 italic font-medium mt-0.5 leading-normal">
                                  Posizione: {tr.outcome.position}ª · Saldo: {tr.outcome.old_balance} → {tr.outcome.new_balance} {tr.outcome.capped ? "(CAP)" : ""}
                                </span>
                              )}
                            </div>
                          </td>
                          <td className="py-3">
                            <span className={`text-[9px] uppercase px-1.5 py-0.5 rounded font-black ${
                              isReward
                                ? "bg-yellow-500/10 text-yellow-400"
                                : details?.categoria === "BONUS"
                                ? "bg-emerald-500/10 text-emerald-400"
                                : "bg-red-500/10 text-red-400"
                            }`}>
                              {details?.categoria || "N/A"}
                            </span>
                          </td>
                          <td className="py-3 font-semibold text-zinc-400">
                            {targetTeam ? targetTeam.nome_squadra : "—"}
                          </td>
                          {(() => {
                            const cost = tr.costo ?? tr.costo_token ?? 0;
                            return isReward || cost < 0 ? (
                              <td className="py-3 font-mono font-black text-emerald-400">+{Math.abs(cost)} 🪙</td>
                            ) : (
                              <td className="py-3 font-mono font-black text-rose-500">-{Math.abs(cost)} 🪙</td>
                            );
                          })()}
                          <td className="py-3 text-right text-zinc-500 text-[10px]">
                            {new Date(tr.timestamp || tr.data_acquisto).toLocaleString("it-IT")}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* CATALOGO ARTICOLI & LISTINO UFFICIALE */}
      <div className="surface p-6 border rounded-2xl bg-zinc-950/40 border-zinc-800 shadow-xl space-y-4">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 border-b border-border/10 pb-4">
          <div>
            <h3 className="font-extrabold text-sm uppercase tracking-wider text-primary flex items-center gap-2">
              <ShoppingBag className="size-4 text-orange-500" /> 📦 Catalogo Articoli & Listino Ufficiale
            </h3>
            <p className="text-[10px] text-muted-foreground mt-0.5">
              Tutti i 16 articoli ufficiali del Marketplace (8 Bonus e 8 Malus) con relative tariffe e regole di funzionamento.
            </p>
          </div>
          <span className="text-xs font-black bg-zinc-900 px-3 py-1 rounded-xl border border-zinc-800 text-zinc-300">
            16 Articoli Attivi
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {MARKETPLACE_ITEMS.map((item) => (
            <div
              key={item.id}
              className="p-4 rounded-xl bg-zinc-900/30 border border-zinc-800/80 flex items-start justify-between gap-3"
            >
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className={`text-[9px] font-black uppercase px-2 py-0.5 rounded ${
                    item.categoria === "BONUS" ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" : "bg-red-500/10 text-red-400 border border-red-500/20"
                  }`}>
                    {item.categoria}
                  </span>
                  <h4 className="text-xs font-extrabold text-foreground">{item.nome}</h4>
                </div>
                <p className="text-[11px] text-muted-foreground leading-relaxed">{item.desc}</p>
              </div>
              <span className="text-xs font-black font-mono px-2.5 py-1 rounded-lg bg-zinc-900 border border-zinc-800 text-amber-400 shrink-0">
                {item.costo} 🪙
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
  );
}
