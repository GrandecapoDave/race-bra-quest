import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { AppShell } from "@/components/AppShell";
import { useSession } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { 
  PhoneCall, 
  Clock, 
  CheckCircle, 
  Lock, 
  HelpCircle, 
  MessageSquare, 
  CornerDownRight, 
  ArrowRight,
  Shield,
  Loader2
} from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/passaparola")({
  component: AdminPassaparolaPage,
});

function AdminPassaparolaPage() {
  const { user } = useSession();
  const queryClient = useQueryClient();
  
  // Filter state: 'pending' | 'answered' | 'all'
  const [filter, setFilter] = useState<"pending" | "answered" | "all">("pending");
  const [answeringId, setAnsweringId] = useState<string | null>(null);
  const [internalNotes, setInternalNotes] = useState<Record<string, string>>({});

  // Query teams
  const teamsQuery = useQuery({
    queryKey: ["all-teams-list"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("teams")
        .select("*")
        .eq("active", true);
      if (error) return [];
      return data ?? [];
    },
  });

  // Query transactions
  const transactionsQuery = useQuery({
    queryKey: ["marketplace-transactions-list"],
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("marketplace_transactions")
        .select("*,buyer_team_id:team_id,item_id:marketplace_item_id,timestamp:data_acquisto,request_text:dettagli->>request_text,response_text:dettagli->>response_text,nota_interna:dettagli->>nota_interna")
        .eq("marketplace_item_id", "passaparola")
        .order("data_acquisto", { ascending: false });
      if (error) return [];
      return data ?? [];
    },
  });

  const allTeams = teamsQuery.data ?? [];
  const transactions = transactionsQuery.data ?? [];

  // Filter for Passaparola transactions
  const passaparolaTxs = transactions.filter((t: any) => t.item_id === "passaparola");

  // Filtered lists
  const pendingRequests = passaparolaTxs.filter((t: any) => t.stato === "pending");
  const answeredRequests = passaparolaTxs.filter((t: any) => t.stato === "used");

  const activeList = 
    filter === "pending" 
      ? pendingRequests 
      : filter === "answered" 
        ? answeredRequests 
        : passaparolaTxs;

  const handleRespond = async (transactionId: string, responseVal: "SÌ" | "NO") => {
    if (!user?.id) {
      toast.error("Utente non autenticato.");
      return;
    }
    setAnsweringId(transactionId);
    const noteText = internalNotes[transactionId] || "";

    try {
      const { data, error } = await (supabase as any).rpc("respond_passaparola_request", {
        p_transaction_id: transactionId,
        p_response: responseVal,
        p_nota_interna: noteText || null,
        p_admin_id: user.id,
      });

      if (error) {
        toast.error(`Errore: ${error.message || "Impossibile rispondere alla richiesta"}`);
        return;
      }

      toast.success(`Risposta "${responseVal}" inviata con successo!`);
      // Clear note state
      setInternalNotes(prev => {
        const next = { ...prev };
        delete next[transactionId];
        return next;
      });
      queryClient.invalidateQueries();
    } catch (err: any) {
      toast.error("Si è verificato un errore imprevisto.");
    } finally {
      setAnsweringId(null);
    }
  };

  return (
    <AppShell isAdmin={true}>
      <div className="space-y-6 max-w-4xl mx-auto">
        {/* Title Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div className="space-y-1">
            <h1 className="text-3xl font-display font-black uppercase tracking-wide flex items-center gap-3">
              <PhoneCall className="size-8 text-orange-500 animate-bounce" />
              Gestione Passaparola
            </h1>
            <p className="text-xs text-muted-foreground">
              Rispondi in tempo reale con SÌ o NO alle domande e richieste di aiuto inviate dalle squadre.
            </p>
          </div>
          
          {/* Tabs Filter */}
          <div className="flex bg-zinc-900/60 p-1 rounded-xl border border-zinc-800 shrink-0">
            <button
              onClick={() => setFilter("pending")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
                filter === "pending"
                  ? "bg-orange-500 text-black shadow-sm font-black"
                  : "text-zinc-400 hover:text-white"
              }`}
            >
              <span>In Attesa</span>
              {pendingRequests.length > 0 && (
                <span className={`size-4 rounded-full flex items-center justify-center text-[9px] font-black ${
                  filter === "pending" ? "bg-black text-orange-500" : "bg-orange-500 text-black animate-pulse"
                }`}>
                  {pendingRequests.length}
                </span>
              )}
            </button>
            <button
              onClick={() => setFilter("answered")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                filter === "answered"
                  ? "bg-zinc-800 text-white font-black"
                  : "text-zinc-400 hover:text-white"
              }`}
            >
              Risposti
            </button>
            <button
              onClick={() => setFilter("all")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                filter === "all"
                  ? "bg-zinc-800 text-white font-black"
                  : "text-zinc-400 hover:text-white"
              }`}
            >
              Tutti
            </button>
          </div>
        </div>

        {/* Requests List */}
        <div className="space-y-4">
          {activeList.length === 0 ? (
            <div className="surface border rounded-2xl bg-zinc-950/20 p-12 text-center space-y-3">
              <div className="size-12 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center mx-auto text-zinc-500">
                <HelpCircle className="size-6" />
              </div>
              <p className="text-xs text-muted-foreground italic font-semibold">
                {filter === "pending"
                  ? "Nessuna richiesta di aiuto in attesa al momento."
                  : filter === "answered"
                    ? "Nessuna richiesta risposta finora."
                    : "Nessuna transazione Passaparola trovata."}
              </p>
            </div>
          ) : (
            activeList.map((tr: any) => {
              const team = allTeams.find((t: any) => t.id === tr.buyer_team_id);
              const isPending = tr.stato === "pending";
              const isAnswering = answeringId === tr.id;
              
              return (
                <div 
                  key={tr.id}
                  className="surface border rounded-2xl bg-zinc-900/10 p-5 space-y-4 hover:border-zinc-700/50 transition-all duration-300 relative overflow-hidden"
                  style={{
                    borderLeft: team?.color ? `4px solid ${team.color}` : undefined
                  }}
                >
                  {/* Top line details */}
                  <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2">
                    <div className="flex items-center gap-2.5">
                      <span 
                        className="text-lg shrink-0" 
                        style={{ color: team?.color }}
                      >
                        ●
                      </span>
                      <strong className="text-sm font-black uppercase text-foreground leading-none">
                        {team?.nome_squadra || "Squadra Sconosciuta"}
                      </strong>
                    </div>
                    <div className="flex items-center gap-3 text-[10px] text-zinc-500 font-bold">
                      <div className="flex items-center gap-1">
                        <Clock className="size-3" />
                        <span>
                          {tr.timestamp_request 
                            ? new Date(tr.timestamp_request).toLocaleString("it-IT") 
                            : new Date(tr.timestamp).toLocaleString("it-IT")}
                        </span>
                      </div>
                      <div className={`px-2 py-0.5 rounded uppercase font-black tracking-wider text-[8px] flex items-center gap-1 ${
                        isPending 
                          ? "bg-orange-500/10 text-orange-400 border border-orange-500/20" 
                          : "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                      }`}>
                        {isPending ? "🟠 IN ATTESA" : "🟢 RISPOSTO"}
                      </div>
                    </div>
                  </div>

                  {/* Question Section */}
                  <div className="bg-zinc-950/40 p-4 rounded-xl border border-zinc-800 space-y-1.5">
                    <div className="flex items-center gap-1.5 text-[10px] text-zinc-500 font-extrabold uppercase tracking-wide">
                      <HelpCircle className="size-3.5 text-orange-500" />
                      <span>Domanda della Squadra:</span>
                    </div>
                    <p className="text-xs text-foreground font-semibold leading-relaxed whitespace-pre-wrap pl-5">
                      "{tr.request_text || "Nessun testo specificato."}"
                    </p>
                  </div>

                  {/* Answer Form / View */}
                  {isPending ? (
                    <div className="space-y-3.5 pt-2">
                      {/* Internal Notes Input */}
                      <div className="space-y-1.5">
                        <label className="text-[10px] text-zinc-500 font-extrabold uppercase tracking-wide flex items-center gap-1.5">
                          <MessageSquare className="size-3.5 text-zinc-400" />
                          <span>Nota Interna Regia (Opzionale - Invisibile alla squadra):</span>
                        </label>
                        <input
                          type="text"
                          placeholder="Inserisci un promemoria per la regia..."
                          value={internalNotes[tr.id] || ""}
                          onChange={(e) => setInternalNotes(prev => ({ ...prev, [tr.id]: e.target.value }))}
                          disabled={isAnswering}
                          className="w-full text-xs bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-foreground placeholder-zinc-600 focus:outline-none focus:border-zinc-700 transition-colors"
                        />
                      </div>

                      {/* Action buttons */}
                      <div className="flex items-center gap-3">
                        <button
                          onClick={() => handleRespond(tr.id, "SÌ")}
                          disabled={isAnswering}
                          className="flex-1 py-2.5 rounded-xl bg-emerald-500 text-black font-black text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer flex items-center justify-center gap-1.5"
                        >
                          {isAnswering ? (
                            <Loader2 className="size-3.5 animate-spin" />
                          ) : (
                            <>
                              <span>✅ SÌ</span>
                            </>
                          )}
                        </button>
                        <button
                          onClick={() => handleRespond(tr.id, "NO")}
                          disabled={isAnswering}
                          className="flex-1 py-2.5 rounded-xl bg-rose-500 text-black font-black text-xs uppercase tracking-wider shadow-md hover:brightness-110 active:scale-[0.98] transition-all cursor-pointer flex items-center justify-center gap-1.5"
                        >
                          {isAnswering ? (
                            <Loader2 className="size-3.5 animate-spin" />
                          ) : (
                            <>
                              <span>❌ NO</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  ) : (
                    /* Answer view */
                    <div className="space-y-3 pt-2 border-t border-border/10">
                      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                        <div className="flex items-center gap-2">
                          <CornerDownRight className="size-4 text-emerald-400" />
                          <span className="text-[10px] text-zinc-500 font-extrabold uppercase tracking-wide">
                            Risposta data dalla Regia:
                          </span>
                          <span className={`text-xs font-black px-3 py-1 rounded-lg border ml-2 ${
                            tr.response_text === "SÌ" 
                              ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20" 
                              : "bg-rose-500/10 text-rose-400 border-rose-500/20"
                          }`}>
                            {tr.response_text === "SÌ" ? "✅ SÌ" : "❌ NO"}
                          </span>
                        </div>
                        {tr.response_timestamp && (
                          <span className="text-[9px] text-zinc-600 font-semibold">
                            Risposto il: {new Date(tr.response_timestamp).toLocaleString("it-IT")}
                          </span>
                        )}
                      </div>

                      {/* Internal Notes Display */}
                      {tr.nota_interna && (
                        <div className="bg-zinc-950/20 p-3 rounded-xl border border-dashed border-zinc-800 text-[11px] text-zinc-500 leading-normal pl-8 relative">
                          <Shield className="size-3.5 text-zinc-600 absolute left-3 top-3.5" />
                          <strong>Nota interna Regia:</strong> {tr.nota_interna}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    </AppShell>
  );
}
