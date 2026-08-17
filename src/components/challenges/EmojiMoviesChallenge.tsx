import { useState, useEffect } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, X, Lock, Film, Sparkles, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Challenge, Team } from "@/lib/race";

export const MOVIES = [
  { index: 1, emojis: "🖤👅🕷️👹", title: "Venom", letter: "V" },
  { index: 2, emojis: "🧠😢😡🤢😱", title: "Inside Out", letter: "I" },
  { index: 3, emojis: "🚢🧊💔🎻", title: "Titanic", letter: "T" },
  { index: 4, emojis: "🤠🚀🧸👦", title: "Toy Story", letter: "T" },
  { index: 5, emojis: "🌊👑🐔🌴", title: "Oceania", letter: "O" },
  { index: 6, emojis: "🐭👨‍🍳🍽️🇫🇷", title: "Ratatouille", letter: "R" },
  { index: 7, emojis: "🤡🎈🔴🚸", title: "It", letter: "I" },
  { index: 8, emojis: "💙🌳🪐👽", title: "Avatar", letter: "A" }
];

export function EmojiMoviesChallenge({
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
  const [inputs, setInputs] = useState<Record<number, string>>({});

  // Query team answers for this specific challenge
  const answersQuery = useQuery({
    queryKey: ["emoji-movies-answers", team?.id],
    enabled: !!team?.id,
    queryFn: async () => {
      const { data, error } = await (supabase as any)
        .from("team_emoji_movies")
        .select("*")
        .eq("team_id", team!.id);
      if (error) throw new Error(error.message);
      return data as any[];
    },
  });

  const answers = answersQuery.data ?? [];

  // Helper to get state of a specific movie
  const getMovieState = (index: number) => {
    const ans = answers.find((a) => a.movie_index === index);
    return {
      attempts: ans?.attempts ?? 0,
      isCorrect: ans?.is_correct ?? false,
      lastAnswer: ans?.last_answer ?? "",
      letter: ans?.letter ?? null,
      isResolved: (ans?.is_correct ?? false) || (ans?.attempts ?? 0) >= 3,
    };
  };

  // Submit mutation for single movie
  const submitAnswer = useMutation({
    mutationFn: async ({ index, answer }: { index: number; answer: string }) => {
      if (!team) return;
      const movie = MOVIES.find((m) => m.index === index);
      if (!movie) return;

      const currentState = getMovieState(index);
      const nextAttempts = currentState.attempts + 1;

      // Validate answer (case insensitive, trimmed)
      const cleanInput = answer.trim().toLowerCase();
      const cleanSolution = movie.title.trim().toLowerCase();
      const isCorrect = cleanInput === cleanSolution;
      const points = isCorrect ? 1 : 0;
      const letter = movie.letter;

      // Save or update answer in team_emoji_movies table
      const existing = answers.find((a) => a.movie_index === index);
      if (existing) {
        const { error } = await (supabase as any)
          .from("team_emoji_movies")
          .update({
            attempts: nextAttempts,
            last_answer: answer,
            is_correct: isCorrect,
            points,
            letter,
            timestamp: new Date().toISOString()
          })
          .eq("id", existing.id);
        if (error) throw new Error(error.message);
      } else {
        const { error } = await (supabase as any)
          .from("team_emoji_movies")
          .insert({
            team_id: team.id,
            movie_index: index,
            attempts: nextAttempts,
            last_answer: answer,
            is_correct: isCorrect,
            points,
            letter,
            timestamp: new Date().toISOString()
          });
        if (error) throw new Error(error.message);
      }

      // If answer is correct, log a score record immediately
      if (isCorrect) {
        const { error: scoreErr } = await (supabase as any)
          .from("scores")
          .insert({
            team_id: team.id,
            challenge_id: challenge.id,
            punti: 1,
            motivazione: `Indovinato film dalle emoji: ${movie.title} (${index}/8)`
          });
        if (scoreErr) throw new Error(scoreErr.message);
      }

      return { isCorrect, nextAttempts, title: movie.title };
    },
    onSuccess: (data, variables) => {
      if (data?.isCorrect) {
        toast.success(`Esatto! Hai indovinato: ${data.title}`);
      } else {
        toast.error(`Sbagliato! ${data?.nextAttempts === 3 ? `Risposta corretta: ${data.title}` : `Tentativo ${data?.nextAttempts} di 3.`}`);
      }
      queryClient.invalidateQueries();
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Errore"),
  });

  const handleConfirm = (index: number) => {
    const val = inputs[index] || "";
    if (!val.trim()) {
      toast.error("Inserisci una risposta prima di confermare");
      return;
    }
    submitAnswer.mutate({ index, answer: val });
  };

  // Determine if all 8 movies have been resolved (either correct or out of attempts)
  const resolvedCount = MOVIES.filter((m) => getMovieState(m.index).isResolved).length;
  const allResolved = resolvedCount === 8;

  // Compute final word letters array
  const finalWord = MOVIES.map((m) => {
    const state = getMovieState(m.index);
    return state.isResolved ? m.letter : "_";
  });

  return (
    <div className="space-y-6 sm:space-y-8 bg-zinc-950 p-4 sm:p-6 rounded-xl sm:rounded-2xl border border-red-950 shadow-2xl relative overflow-hidden">
      {/* Cinematic decorative elements */}
      <div className="absolute top-0 left-0 right-0 h-1 bg-red-600 shadow-[0_0_15px_rgba(220,38,38,0.7)]" />
      <div className="absolute -top-12 -left-12 size-36 bg-red-900/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-12 -right-12 size-36 bg-red-900/10 rounded-full blur-3xl pointer-events-none" />

      {/* MISSION BRIEFING */}
      <section className="bg-zinc-900/40 p-5 rounded-xl border border-zinc-800/60 space-y-4">
        <h2 className="text-sm font-extrabold tracking-widest text-red-500 uppercase flex items-center gap-2">
          <Film className="size-4" /> Missione Cinema
        </h2>
        <p className="text-sm sm:text-base font-serif italic text-zinc-300 leading-relaxed whitespace-pre-line">
          "Viaggiatori, si spengono le luci, si alza il sipario: benvenuti nella sala più insolita della caccia!

          Otto locandine, otto enigmi fatti di sole immagini.

          Ogni film che indovinerete vi regalerà una lettera: la prima del suo titolo, e nient'altro.

          Mettete le otto lettere in fila, nell'ordine in cui vi ho mostrato le locandine, e scoprirete non un film... ma il prossimo luogo da raggiungere."
        </p>
      </section>

      {/* CHALLENGE TABLE */}
      <div className="overflow-hidden rounded-xl border border-zinc-800/80 bg-zinc-900/20">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-sm">
            <thead>
              <tr className="bg-zinc-900/80 text-xs text-zinc-400 font-extrabold uppercase tracking-wider border-b border-zinc-800">
                <th className="py-3 px-2 w-8 text-center">#</th>
                <th className="py-3 px-2 w-24 sm:w-36 text-center">Emoji</th>
                <th className="py-3 px-3">Film da indovinare</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-900">
              {MOVIES.map((movie) => {
                const state = getMovieState(movie.index);
                const inputVal = inputs[movie.index] ?? "";

                return (
                  <tr
                    key={movie.index}
                    className={`transition-colors duration-150 ${
                      state.isCorrect
                        ? "bg-green-950/10 hover:bg-green-950/15"
                        : state.attempts >= 3
                        ? "bg-red-950/10 hover:bg-red-950/15"
                        : "hover:bg-zinc-900/30"
                    }`}
                  >
                    <td className="py-3.5 px-2 font-mono font-bold text-center text-zinc-500">
                      {movie.index}
                    </td>
                    <td className="py-3.5 px-2 text-center w-24 sm:w-36">
                      <div className="whitespace-nowrap text-center text-lg sm:text-2xl filter drop-shadow-[0_2px_4px_rgba(0,0,0,0.5)] tracking-wide select-none">
                        {movie.emojis}
                      </div>
                    </td>
                    <td className="py-3.5 px-3">
                      {state.isCorrect ? (
                        <div className="flex items-center gap-1.5 text-green-500 font-bold bg-green-950/20 border border-green-800/30 rounded-xl px-3 py-2 text-xs sm:text-sm">
                          <Check className="size-4 shrink-0" />
                          <span>{movie.title}</span>
                        </div>
                      ) : state.attempts >= 3 ? (
                        <div className="flex items-center gap-1.5 text-red-400 font-medium bg-red-950/20 border border-red-900/30 rounded-xl px-3 py-2 text-xs sm:text-sm">
                          <Lock className="size-4 shrink-0" />
                          <span>{movie.title} <span className="text-[10px] text-zinc-500 font-normal sm:inline hidden">(Risposta corretta)</span></span>
                        </div>
                      ) : (
                        <div className="space-y-1">
                          <div className="flex gap-1.5">
                            <input
                              type="text"
                              value={inputVal}
                              disabled={submitAnswer.isPending}
                              onChange={(e) =>
                                setInputs((prev) => ({ ...prev, [movie.index]: e.target.value }))
                              }
                              placeholder="Titolo..."
                              onKeyDown={(e) => e.key === "Enter" && handleConfirm(movie.index)}
                              className="flex-1 min-w-0 bg-zinc-950 border border-zinc-800 rounded-xl px-2.5 py-1.5 text-xs sm:text-sm outline-none focus:ring-1 focus:ring-red-600 focus:border-red-600 transition-all text-white placeholder:text-zinc-600"
                            />
                            <button
                              onClick={() => handleConfirm(movie.index)}
                              disabled={submitAnswer.isPending}
                              className="px-3 sm:px-4 py-1.5 bg-red-700 hover:bg-red-600 active:bg-red-800 rounded-xl text-[10px] sm:text-xs font-bold text-white uppercase tracking-wider transition-colors duration-150 flex items-center justify-center shrink-0 cursor-pointer disabled:opacity-40"
                            >
                              Conferma
                            </button>
                          </div>
                          {state.attempts > 0 && (
                            <p className="text-[10px] text-red-400 flex items-center gap-1 font-semibold pl-1">
                              <AlertCircle className="size-3" /> Tentativo {state.attempts} di 3.
                            </p>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* FINAL LETTERS DISPLAY */}
      <div className="bg-zinc-900/80 border border-zinc-800 rounded-xl p-5 text-center space-y-4">
        <p className="text-xs font-extrabold tracking-widest text-zinc-400 uppercase">
          Iniziali in ordine
        </p>
        <div className="flex justify-center gap-2.5 sm:gap-4 py-2">
          {finalWord.map((letter, idx) => (
            <span
              key={idx}
              className={`grid size-9 sm:size-12 place-items-center rounded-lg font-display text-lg sm:text-2xl font-black transition-all duration-300 ${
                letter !== "_"
                  ? "bg-red-600 text-white shadow-md shadow-red-600/30 scale-105 border border-red-500"
                  : "bg-zinc-950 text-zinc-700 border border-zinc-800"
              }`}
            >
              {letter}
            </span>
          ))}
        </div>
      </div>

      {/* FINAL ANIMATED REVELATION */}
      {allResolved && (
        <div className="space-y-6 pt-6 border-t border-red-950/80 text-center animate-in fade-in-50 slide-in-from-bottom-4 duration-500">
          <div className="relative inline-block">
            <h3 className="text-5xl sm:text-7xl font-display font-black text-red-500 tracking-[0.2em] pl-[0.2em] uppercase select-none animate-pulse drop-shadow-[0_0_15px_rgba(239,68,68,0.6)]">
              VITTORIA
            </h3>
            <span className="absolute -top-3 -right-3">
              <Sparkles className="size-6 text-yellow-500 animate-spin duration-1000" />
            </span>
          </div>

          <div className="bg-red-950/15 border border-red-900/30 rounded-xl p-5 max-w-md mx-auto space-y-2">
            <p className="text-sm font-bold text-red-400 uppercase tracking-widest">
              Codice sbloccato!
            </p>
            <p className="text-sm sm:text-base font-medium text-zinc-200">
              La parola nascosta è <span className="font-extrabold text-red-400">VITTORIA</span>.
            </p>
            <p className="text-sm sm:text-base text-zinc-300 font-serif italic">
              Complimenti Viaggiatori! È questo il prossimo luogo da raggiungere.
            </p>
          </div>

          <button
            onClick={onComplete}
            disabled={completing}
            className="primary-gradient glow px-8 py-4 rounded-xl font-extrabold text-primary-foreground text-sm tracking-wider uppercase hover:scale-[1.03] active:scale-95 transition-all w-full max-w-xs cursor-pointer flex items-center justify-center gap-2"
          >
            {completing ? <Loader2 className="size-4 animate-spin" /> : <Film className="size-4" />}
            Concludi Tappa 2
          </button>
        </div>
      )}
    </div>
  );
}
