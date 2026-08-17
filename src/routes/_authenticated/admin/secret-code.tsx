import { createFileRoute } from "@tanstack/react-router";
import { useState, useEffect } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useQueryClient } from "@tanstack/react-query";
import { Key, Loader2 } from "lucide-react";
import { useAdminContext } from "../admin";

export const Route = createFileRoute("/_authenticated/admin/secret-code")({
  component: AdminSecretCodePage,
});

function AdminSecretCodePage() {
  const {
    secretCodeDashboard,
    allTeams,
    isUpdatingCodeSettings,
    isForcingCode,
    handleUpdateCodeSettings,
    handleEditCodeMatch,
    handleForceCompleteCode
  } = useAdminContext();

  const queryClient = useQueryClient();

  const data = secretCodeDashboard.data;
  const teamsList = allTeams.data ?? [];

  // Local state for settings form
  const [tempCode, setTempCode] = useState("");
  const [tempDest, setTempDest] = useState("");

  // Sync tempCode and tempDest with dashboard configuration data
  useEffect(() => {
    if (data) {
      setTempCode(data.full_code || "");
      setTempDest(data.destination || "");
    }
  }, [data]);

  // Local state for editing individual row match details
  const [editingCodeTeamId, setEditingCodeTeamId] = useState<string | null>(null);
  const [editSellerId, setEditSellerId] = useState("");
  const [editPartType, setEditPartType] = useState<"FIRST_5" | "LAST_5">("FIRST_5");
  const [editCost, setEditCost] = useState(3);

  if (secretCodeDashboard.isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-10 space-y-3">
        <Loader2 className="size-6 animate-spin text-primary" />
        <p className="text-sm text-muted-foreground">Caricamento impostazioni codice...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-pop-in">
      {/* GLOBAL SETTINGS CARD */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h3 className="text-base font-extrabold text-foreground uppercase tracking-wider flex items-center gap-1.5">
          <Key className="size-4.5 text-primary" /> Configurazione PIN Globale
        </h3>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleUpdateCodeSettings(tempCode, tempDest);
          }}
          className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end"
        >
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold uppercase text-zinc-400">PIN Finale (10 Cifre)</label>
            <input
              type="text"
              maxLength={10}
              value={tempCode}
              onChange={(e) => setTempCode(e.target.value.replace(/[^0-9]/g, ""))}
              className="w-full rounded-xl border border-input bg-input/40 px-3 py-2 text-sm font-mono tracking-widest text-center focus:outline-none"
            />
          </div>

          <div className="space-y-1.5 md:col-span-2 flex gap-4 items-end">
            <div className="flex-1 space-y-1.5">
              <label className="text-[10px] font-bold uppercase text-zinc-400">Destinazione Sbloccata</label>
              <input
                type="text"
                value={tempDest}
                onChange={(e) => setTempDest(e.target.value)}
                className="w-full rounded-xl border border-input bg-input/40 px-3 py-2 text-sm focus:outline-none"
              />
            </div>
            <button
              type="submit"
              disabled={isUpdatingCodeSettings || tempCode.length !== 10}
              className="primary-gradient px-5 py-2.5 rounded-xl font-extrabold text-xs text-primary-foreground shadow shrink-0 cursor-pointer disabled:opacity-40"
            >
              {isUpdatingCodeSettings ? <Loader2 className="size-3.5 animate-spin" /> : "Salva Impostazioni"}
            </button>
          </div>
        </form>
      </div>

      {/* TEAMS CODE MATCHES TABLE */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <div className="flex justify-between items-center">
          <div>
            <h3 className="text-base font-extrabold text-foreground uppercase tracking-wider">
              Assegnazioni e Abbinamenti
            </h3>
            <p className="text-xs text-muted-foreground mt-0.5">
              Controlla i frammenti distribuiti, le associazioni commerciali e lo stato di decifrazione del PIN.
            </p>
          </div>
          <button
            onClick={async () => {
              if (confirm("Sei sicuro di voler auto-generare/resettare gli accoppiamenti delle squadre attive? Le modifiche manuali andranno perse.")) {
                const { error } = await supabase.rpc("initialize_secret_code_challenge");
                if (error) toast.error(error.message);
                else {
                  toast.success("Abbinamenti inizializzati con successo!");
                  queryClient.invalidateQueries();
                }
              }
            }}
            className="px-4 py-2 bg-primary/10 hover:bg-primary/20 text-primary border border-primary/20 rounded-xl font-bold text-xs transition-all cursor-pointer"
          >
            Auto-Genera Ciclo
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-left border-collapse text-sm">
            <thead>
              <tr className="border-b border-border/40 text-[10px] text-muted-foreground uppercase font-bold tracking-widest">
                <th className="pb-3 pr-4">Squadra Acquirente</th>
                <th className="pb-3 pr-4">Frammento Posseduto</th>
                <th className="pb-3 pr-4">Partner Venditore</th>
                <th className="pb-3 pr-4">Costo Frammento</th>
                <th className="pb-3 pr-4">Stato Acquisto</th>
                <th className="pb-3 pr-4">Stato PIN</th>
                <th className="pb-3 text-right">Azioni</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/20">
              {teamsList.filter((t: any) => t.active).map((team: any) => {
                const part = data?.parts.find((p: any) => p.team_id === team.id);
                const match = data?.matches.find((m: any) => m.buyer_team_id === team.id);
                const sellerTeam = match ? teamsList.find((t: any) => t.id === match.seller_team_id) : null;
                const hasPurchased = data?.transactions.some((tx: any) => tx.buyer_team_id === team.id) || false;
                const isCompleted = data?.completed_teams.some((ct: any) => ct.team_id === team.id) || false;

                const isEditingThis = editingCodeTeamId === team.id;

                return (
                  <tr key={team.id} className="hover:bg-zinc-900/30 transition-colors">
                    <td className="py-3 pr-4 font-black text-foreground flex items-center gap-2">
                      <span>{team.avatar_url || "🏳️"}</span>
                      <span>{team.nome_squadra}</span>
                    </td>

                    <td className="py-3 pr-4">
                      {isEditingThis ? (
                        <select
                          value={editPartType}
                          onChange={(e) => setEditPartType(e.target.value as any)}
                          className="bg-zinc-900 border border-zinc-800 text-xs rounded p-1 text-foreground"
                        >
                          <option value="FIRST_5">FIRST_5 (Prime 5)</option>
                          <option value="LAST_5">LAST_5 (Ultime 5)</option>
                        </select>
                      ) : part ? (
                        <span className="text-xs font-mono bg-zinc-900 px-2 py-1 rounded border border-zinc-800 text-zinc-300">
                          {part.part_type} ({part.code_part})
                        </span>
                      ) : (
                        <span className="text-xs text-muted-foreground italic">Non assegnato</span>
                      )}
                    </td>

                    <td className="py-3 pr-4">
                      {isEditingThis ? (
                        <select
                          value={editSellerId}
                          onChange={(e) => setEditSellerId(e.target.value)}
                          className="bg-zinc-900 border border-zinc-800 text-xs rounded p-1 text-foreground max-w-[150px]"
                        >
                          <option value="">Nessuno</option>
                          {teamsList.filter((t: any) => t.id !== team.id && t.active).map((t: any) => (
                            <option key={t.id} value={t.id}>{t.nome_squadra}</option>
                          ))}
                        </select>
                      ) : sellerTeam ? (
                        <span className="font-bold text-zinc-300">{sellerTeam.nome_squadra}</span>
                      ) : (
                        <span className="text-xs text-muted-foreground italic">Nessuno</span>
                      )}
                    </td>

                    <td className="py-3 pr-4 font-bold">
                      {isEditingThis ? (
                        <input
                          type="number"
                          min={1}
                          max={5}
                          value={editCost}
                          onChange={(e) => setEditCost(parseInt(e.target.value) || 3)}
                          className="bg-zinc-900 border border-zinc-800 text-xs rounded p-1 text-foreground w-16 text-center"
                        />
                      ) : match ? (
                        <span className="text-yellow-400 font-mono">{match.token_cost} Token</span>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>

                    <td className="py-3 pr-4">
                      <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded ${
                        hasPurchased ? "bg-green-950/40 text-success border border-green-900/40" : "bg-zinc-900 text-zinc-500 border border-zinc-800"
                      }`}>
                        {hasPurchased ? "Acquistato" : "Non acquistato"}
                      </span>
                    </td>

                    <td className="py-3 pr-4">
                      <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded ${
                        isCompleted ? "bg-gold/20 text-gold border border-gold/20 animate-pulse" : "bg-zinc-900 text-zinc-500 border border-zinc-800"
                      }`}>
                        {isCompleted ? "Decifrato" : "Bloccato"}
                      </span>
                    </td>

                    <td className="py-3 text-right">
                      <div className="flex justify-end gap-2">
                        {isEditingThis ? (
                          <>
                            <button
                              onClick={() => setEditingCodeTeamId(null)}
                              className="px-2 py-1 bg-zinc-900 hover:bg-zinc-800 text-zinc-400 rounded text-xs cursor-pointer"
                            >
                              Annulla
                            </button>
                            <button
                              onClick={async () => {
                                await handleEditCodeMatch(team.id, editSellerId, editPartType, editCost);
                                setEditingCodeTeamId(null);
                              }}
                              className="px-2.5 py-1 bg-primary text-primary-foreground rounded text-xs font-bold cursor-pointer"
                            >
                              Salva
                            </button>
                          </>
                        ) : (
                          <>
                            <button
                              onClick={() => {
                                setEditingCodeTeamId(team.id);
                                setEditSellerId(match?.seller_team_id || "");
                                setEditPartType(part?.part_type || "FIRST_5");
                                setEditCost(match?.token_cost || 3);
                              }}
                              className="px-2 py-1 bg-zinc-900 hover:bg-zinc-800 text-zinc-300 rounded text-xs cursor-pointer"
                            >
                              Modifica
                            </button>
                            {!isCompleted && (
                              <button
                                onClick={() => handleForceCompleteCode(team.id)}
                                disabled={isForcingCode[team.id]}
                                className="px-2 py-1 bg-gold/10 hover:bg-gold/20 text-gold border border-gold/20 rounded text-xs font-bold cursor-pointer disabled:opacity-40"
                              >
                                Forza Fine
                              </button>
                            )}
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* THREE COLUMN DETAILS SECTION */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 1. ORDINE DI COMPLETAMENTO */}
        <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl h-fit">
          <h4 className="text-sm font-black uppercase text-gold tracking-widest flex items-center gap-1.5">
            🏆 Ordine di Decifrazione
          </h4>
          {data?.completed_teams.length === 0 ? (
            <p className="text-xs text-muted-foreground italic">Nessuna squadra ha ancora decifrato il PIN.</p>
          ) : (
            <ol className="space-y-2 text-xs">
              {data?.completed_teams.map((ct: any, idx: number) => (
                <li key={ct.team_id} className="flex justify-between items-center p-2.5 bg-zinc-900/40 rounded-xl border border-zinc-800/40">
                  <span className="font-bold flex items-center gap-2">
                    <span className="text-gold font-black">{idx + 1}.</span>
                    <span>{ct.nome_squadra}</span>
                  </span>
                  <span className="text-zinc-500 font-mono text-[10px]">
                    {new Date(ct.completed_at).toLocaleTimeString("it-IT")}
                  </span>
                </li>
              ))}
            </ol>
          )}
        </div>

        {/* 2. REGISTRO ACQUISTI (TRANSACTIONS) */}
        <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl lg:col-span-2">
          <h4 className="text-sm font-black uppercase text-zinc-400 tracking-widest flex items-center gap-1.5">
            🪙 Registro Transazioni Codice
          </h4>
          {data?.transactions.length === 0 ? (
            <p className="text-xs text-muted-foreground italic">Nessun acquisto registrato.</p>
          ) : (
            <div className="overflow-y-auto max-h-[220px] space-y-2 pr-1">
              {data?.transactions.map((tx: any) => {
                const buyer = teamsList.find((t: any) => t.id === tx.buyer_team_id);
                const seller = teamsList.find((t: any) => t.id === tx.seller_team_id);
                return (
                  <div key={tx.id} className="p-3 bg-zinc-900/40 rounded-xl border border-zinc-800/40 text-xs flex justify-between items-center">
                    <div>
                      <p className="font-bold">
                        <span className="text-primary">{buyer?.nome_squadra}</span> ha comprato da{" "}
                        <span className="text-zinc-300">{seller?.nome_squadra}</span>
                      </p>
                      <p className="text-[10px] text-zinc-500 font-mono mt-0.5">
                        Cifre ricevute: {tx.digits_received} · {new Date(tx.timestamp).toLocaleString("it-IT")}
                      </p>
                    </div>
                    <span className="text-yellow-400 font-black shrink-0 font-mono">
                      -{tx.token_cost} Token
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* PIN ATTEMPTS LIST */}
      <div className="surface p-5 space-y-4 border border-border/40 bg-zinc-950/40 rounded-2xl">
        <h4 className="text-sm font-black uppercase text-zinc-400 tracking-widest flex items-center gap-1.5">
          🛡️ Tentativi Inserimento PIN
        </h4>
        {data?.attempts.length === 0 ? (
          <p className="text-xs text-muted-foreground italic">Nessun tentativo registrato.</p>
        ) : (
          <div className="overflow-x-auto max-h-[250px]">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-border/40 text-[9px] text-muted-foreground uppercase font-black tracking-widest">
                  <th className="pb-2 pr-4">Squadra</th>
                  <th className="pb-2 pr-4">Codice Inserito</th>
                  <th className="pb-2 pr-4">Esito</th>
                  <th className="pb-2">Timestamp</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/20">
                {data?.attempts.slice().reverse().map((att: any) => {
                  const teamObj = teamsList.find((t: any) => t.id === att.team_id);
                  return (
                    <tr key={att.id} className="hover:bg-zinc-900/30">
                      <td className="py-2 pr-4 font-bold text-zinc-300">{teamObj?.nome_squadra || "Sconosciuta"}</td>
                      <td className="py-2 pr-4 font-mono font-bold tracking-widest">{att.inserted_code}</td>
                      <td className="py-2 pr-4">
                        <span className={`font-bold px-1.5 py-0.5 rounded text-[9px] uppercase ${
                          att.success ? "bg-green-950/40 text-success border border-green-900/40" : "bg-destructive/10 text-destructive border border-destructive/20"
                        }`}>
                          {att.success ? "Corretto" : "Errato"}
                        </span>
                      </td>
                      <td className="py-2 text-zinc-500 font-mono">{new Date(att.timestamp).toLocaleString("it-IT")}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
