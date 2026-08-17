import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Lock, Unlock, Key, Coins, Loader2, MapPin, Sparkles, AlertCircle } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Challenge, Team } from "@/lib/race";

export function SecretCodeChallenge({
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
  const [pin, setPin] = useState("");
  const [buying, setBuying] = useState(false);
  const [submittingPin, setSubmittingPin] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const codeStateQuery = useQuery({
    queryKey: ["secret-code-state", team?.id],
    enabled: Boolean(team?.id),
    staleTime: 0,
    refetchInterval: 3000,
    queryFn: async () => {
      const { data, error } = await supabase.rpc("get_secret_code_state", {
        p_team_id: team?.id,
      });
      if (error) throw new Error(error.message);
      return data as {
        part: {
          code_part: string;
          part_type: "FIRST_5" | "LAST_5";
        };
        match: {
          seller_team_id: string;
          seller_name: string;
          required_part: "FIRST_5" | "LAST_5";
          token_cost: number;
        } | null;
        has_purchased: boolean;
        purchased_digits: string | null;
        completed: boolean;
        destination: string;
      };
    },
  });

  async function handleBuyPart() {
    if (!team) return;
    setBuying(true);
    try {
      const { data, error } = await supabase.rpc("buy_secret_code_part");
      if (error) {
        toast.error(error.message || "Errore durante l'acquisto del frammento");
      } else {
        toast.success("Frammento acquistato con successo!");
        await codeStateQuery.refetch();
        await queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message || "Errore imprevisto");
    } finally {
      setBuying(false);
    }
  }

  async function handleSubmitPin(e: React.FormEvent) {
    e.preventDefault();
    if (pin.length !== 10) {
      toast.error("Il codice PIN deve essere composto esattamente da 10 cifre");
      return;
    }

    setSubmittingPin(true);
    setErrorMessage(null);
    try {
      const { data, error } = await supabase.rpc("submit_secret_code_pin", {
        p_inserted_code: pin,
      });

      if (error) {
        setErrorMessage(error.message || "Verifica codice fallita");
      } else if (data && !(data as any).success) {
        setErrorMessage((data as any).message || "Codice errato. Controlla attentamente le cifre.");
      } else {
        toast.success("Codice sbloccato!");
        await codeStateQuery.refetch();
        await queryClient.invalidateQueries();
      }
    } catch (e: any) {
      toast.error(e.message || "Errore di connessione");
    } finally {
      setSubmittingPin(false);
    }
  }

  if (codeStateQuery.isLoading) {
    return (
      <div className="flex flex-col items-center justify-center py-10 space-y-4">
        <Loader2 className="size-8 animate-spin text-primary" />
        <p className="text-sm text-zinc-400 font-medium">Lettura cifre segrete...</p>
      </div>
    );
  }

  const stateData = codeStateQuery.data;
  const isChallengeCompleted = completed || stateData?.completed;

  // Render narrative screen if completed
  if (isChallengeCompleted) {
    return (
      <div className="space-y-6 sm:space-y-8 max-w-xl mx-auto animate-pop-in">
        <section className="bg-zinc-950/80 p-6 rounded-2xl border border-gold/30 shadow-[0_0_25px_rgba(218,165,32,0.15)] text-center space-y-6">
          <div className="mx-auto size-16 bg-gold/10 border border-gold/30 text-gold rounded-full flex items-center justify-center shadow-lg shadow-gold/5 animate-pulse">
            <Unlock className="size-8" />
          </div>

          <div className="space-y-2">
            <span className="text-[10px] font-black uppercase tracking-widest text-gold">🎉 Codice Segreto Risolto</span>
            <h2 className="text-2xl font-black uppercase tracking-wider text-foreground">
              Codice Sbloccato!
            </h2>
          </div>

          <div className="bg-zinc-900/60 p-4 rounded-xl border border-zinc-800/80 inline-flex flex-col items-center space-y-1">
            <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Prossima Destinazione</span>
            <span className="text-sm sm:text-base font-black text-primary flex items-center gap-1.5 justify-center">
              <MapPin className="size-4 shrink-0 text-primary" /> {stateData?.destination || "Parco Giochi Madonna dei Fiori (lato piazzale grigio)"}
            </span>
          </div>

          <p className="text-sm text-zinc-300 font-serif italic leading-relaxed text-left border-t border-zinc-900 pt-4">
            "Viaggiatori, la tensione sale: stiamo entrando ufficialmente nelle fasi finali di questa spietata competizione!
            Non c'è più tempo per respirare. Zaini in spalla, recuperate subito i vostri mezzi e lanciatevi verso la prossima meta:
            vi aspetto al Parco Giochi Madonna dei Fiori (lato piazzale grigio).
            Correte e non guardatevi indietro, perché la prima squadra che raggiungerà questo traguardo si aggiudicherà un vantaggio cruciale
            che potrebbe ribaltare le sorti dell'intera gara. Il traguardo è vicino... via, via, via!"
          </p>

          <button
            onClick={onComplete}
            disabled={completing}
            className="primary-gradient w-full py-4 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all"
          >
            {completing && <Loader2 className="size-4 animate-spin" />}
            <span>Prosegui alla Tappa Successiva</span>
          </button>
        </section>
      </div>
    );
  }

  // Determine current fragment digits views
  const myPart = stateData?.part;
  const match = stateData?.match;
  const hasPurchased = stateData?.has_purchased || false;
  const partnerDigits = stateData?.purchased_digits;

  // Layout presentation for first and second 5 digit slots
  const first5Str = myPart?.part_type === "FIRST_5" ? myPart.code_part : (hasPurchased ? partnerDigits : "_ _ _ _ _");
  const last5Str = myPart?.part_type === "LAST_5" ? myPart.code_part : (hasPurchased ? partnerDigits : "_ _ _ _ _");



  return (
    <div className="space-y-6 sm:space-y-8 max-w-xl mx-auto">
      {/* EXPLANATORY HEADER */}
      <section className="bg-zinc-950/80 p-5 rounded-2xl border border-border/40 shadow-xl space-y-3">
        <h2 className="text-sm font-extrabold tracking-widest text-primary uppercase flex items-center gap-2">
          🔐 Il Codice Segreto
        </h2>
        <p className="text-xs sm:text-sm text-zinc-300 leading-relaxed font-serif italic">
          "Ogni squadra ha ricevuto solo metà del codice a 10 cifre di cui ha bisogno. Per completare la chiave e sbloccare il traguardo finale,
          dovete acquistare il frammento mancante dal partner assegnato a costo fisso di Token."
        </p>
      </section>

      {/* CODE DISPLAY PANEL */}
      <section className="surface p-6 bg-zinc-950 border border-zinc-800/40 rounded-2xl text-center space-y-6 relative overflow-hidden shadow-2xl">
        <div className="absolute top-0 left-0 right-0 h-[3px] bg-primary" />
        
        <div className="space-y-1">
          <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500">Stato Codice PIN</span>
          <div className="flex justify-center items-center gap-4 text-xl sm:text-2xl font-mono font-black tracking-wider py-3 px-6 bg-zinc-900/60 rounded-xl border border-zinc-800/60 inline-flex mx-auto">
            <span className={myPart?.part_type === "FIRST_5" ? "text-primary" : "text-zinc-500"}>
              {first5Str}
            </span>
            <span className="text-zinc-700 font-sans text-lg">·</span>
            <span className={myPart?.part_type === "LAST_5" ? "text-primary" : "text-zinc-500"}>
              {last5Str}
            </span>
          </div>
        </div>

        {/* STEP 1: NEED TO PURCHASE */}
        {!hasPurchased && match && (
          <div className="border-t border-zinc-900 pt-5 space-y-5 animate-pop-in">
            <div className="flex flex-col items-center text-center space-y-2">
              <Key className="size-8 text-primary" />
              <p className="text-xs sm:text-sm text-zinc-300 max-w-sm">
                Devi recuperare il secondo frammento dalla squadra <strong className="text-white">{match.seller_name}</strong>.
              </p>
            </div>

            <div className="bg-zinc-900/40 rounded-xl p-4 border border-zinc-800/80 flex items-center justify-between">
              <div className="flex items-center gap-2 text-left">
                <Coins className="size-5 text-yellow-500" />
                <div>
                  <p className="text-[10px] font-bold text-zinc-500 uppercase">Costo frammento</p>
                  <p className="text-sm font-black text-yellow-400">{match.token_cost} Token</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-[10px] font-bold text-zinc-500 uppercase">Tuo Saldo</p>
                <p className="text-sm font-black text-zinc-300">{(team?.token_balance || 0)} Token</p>
              </div>
            </div>

            <button
              onClick={handleBuyPart}
              disabled={buying}
              className="primary-gradient w-full py-4 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all hover:scale-[1.01]"
            >
              {buying && <Loader2 className="size-4 animate-spin" />}
              Conferma Acquisto ({match.token_cost} Token)
            </button>
          </div>
        )}

        {/* STEP 2: PURCHASED, INPUT PIN */}
        {hasPurchased && (
          <div className="border-t border-zinc-900 pt-5 space-y-5 animate-pop-in">
            <div className="flex items-center gap-2 bg-green-950/15 border border-green-800/30 rounded-xl p-3 text-left">
              <Unlock className="size-4.5 text-success shrink-0" />
              <span className="text-xs text-zinc-300">
                Frammento ricevuto! Ora possiedi il codice PIN completo. Inserisci le 10 cifre per sbloccare la gara.
              </span>
            </div>

            <form onSubmit={handleSubmitPin} className="space-y-4">
              <div className="space-y-1.5 text-left">
                <label className="text-[10px] font-bold uppercase tracking-wider text-zinc-400">
                  🔐 Inserisci il Codice Segreto (10 Cifre)
                </label>
                <input
                  type="text"
                  maxLength={10}
                  pattern="[0-9]*"
                  inputMode="numeric"
                  value={pin}
                  onChange={(e) => {
                    const val = e.target.value.replace(/[^0-9]/g, "");
                    setPin(val);
                  }}
                  placeholder="Esempio: 1234567890"
                  className="w-full font-mono text-center tracking-widest text-lg rounded-xl border border-border/40 bg-zinc-950 px-4 py-3.5 focus:border-primary focus:ring-1 focus:ring-primary"
                />
              </div>

              {errorMessage && (
                <div className="bg-destructive/10 border border-destructive/20 rounded-xl p-3 flex gap-2.5 text-left text-xs">
                  <AlertCircle className="size-4.5 text-destructive shrink-0" />
                  <span className="text-destructive font-semibold">{errorMessage}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={submittingPin || pin.length !== 10}
                className="primary-gradient w-full py-4 rounded-xl font-extrabold text-primary-foreground shadow-lg flex items-center justify-center gap-2 cursor-pointer transition-all disabled:opacity-40"
              >
                {submittingPin ? <Loader2 className="size-4 animate-spin" /> : <Sparkles className="size-4" />}
                Conferma Codice
              </button>
            </form>
          </div>
        )}
      </section>
    </div>
  );
}
