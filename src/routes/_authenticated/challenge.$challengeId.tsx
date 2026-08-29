import { useEffect, useState } from "react";
import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Loader2, Lock, ChevronDown, ChevronUp, Film, Puzzle } from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { TeamSetupChallenge } from "@/components/challenges/TeamSetupChallenge";
import { QuizChallenge } from "@/components/challenges/QuizChallenge";
import { PhotoChallenge } from "@/components/challenges/PhotoChallenge";
import { EmojiMoviesChallenge } from "@/components/challenges/EmojiMoviesChallenge";
import { LivingPosterChallenge } from "@/components/challenges/LivingPosterChallenge";
import { BancaChallenge } from "@/components/challenges/BancaChallenge";
import { SocialChallenge } from "@/components/challenges/SocialChallenge";
import { SecretCodeChallenge } from "@/components/challenges/SecretCodeChallenge";
import { EnigmaMusicaleChallenge } from "@/components/challenges/EnigmaMusicaleChallenge";
import { EnigmaTestoChallenge } from "@/components/challenges/EnigmaTestoChallenge";
import { LucchettoDirezionaleChallenge } from "@/components/challenges/LucchettoDirezionaleChallenge";
import { CoordinateFinaliChallenge } from "@/components/challenges/CoordinateFinaliChallenge";
import { CornholeChallenge } from "@/components/challenges/CornholeChallenge";
import { BoxeChallenge } from "@/components/challenges/BoxeChallenge";
import JackpotChallenge from "@/components/challenges/JackpotChallenge";
import { useIsAdmin, useSession } from "@/hooks/useAuth";
import { useCompleteChallenge, useStartChallenge } from "@/hooks/useChallengeActions";
import { challengeState, challengesQuery, myTeamQuery, progressQuery } from "@/lib/race";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/_authenticated/challenge/$challengeId")({
  head: () => ({
    meta: [
      { title: "Prova — Pechino Express Bra" },
      { name: "description", content: "Completa la prova e guadagna punti per la tua squadra." },
      { property: "og:title", content: "Prova — Pechino Express Bra" },
      { property: "og:description", content: "Quiz, foto e missioni della gara urbana di Bra." },
    ],
  }),
  component: ChallengePage,
});

function ChallengePage() {
  const { challengeId } = Route.useParams();
  const navigate = useNavigate();
  const { user } = useSession();
  const isAdmin = useIsAdmin(user);
  const challenges = useQuery(challengesQuery);
  const team = useQuery(myTeamQuery);
  const progress = useQuery(progressQuery(team.data?.id));
  const complete = useCompleteChallenge();
  const start = useStartChallenge();
  const [showBriefingDropdown, setShowBriefingDropdown] = useState(false);

  const challenge = (challenges.data ?? []).find((c) => c.id === challengeId);
  const isRebusVisivo = challenge?.id === "999f4e1f-7443-42e7-9d7a-115f2122888f";
  const stageChallenges = (challenges.data ?? []).filter((c) => c.stage_id === challenge?.stage_id);
  const prog = progress.data ?? [];
  const state = challenge ? challengeState(challenge, stageChallenges, prog) : "locked";
  const started = prog.some((p) => p.challenge_id === challengeId);

  const gameSettings = useQuery({
    queryKey: ["game-settings"],
    staleTime: 0,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("game_settings")
        .select("*")
        .single();
      if (error) return null;
      return data;
    }
  });

  const isEnigma = challenge?.type === "enigma_musicale" || challenge?.type === "enigma_testo" || challenge?.type === "lucchetto_direzionale" || challenge?.type === "enigma_coordinate";

  useEffect(() => {
    if (team.data && challenge && state === "available" && !started && !start.isPending) {
      if (challenge.type === "emoji_movies") return;
      if (isRebusVisivo) return;
      if (isEnigma) return; // Enigma challenges self-manage their start via submit_enigma_answer
      start.mutate(challenge.id);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [team.data?.id, challenge?.id, state, started, isRebusVisivo, isEnigma]);

  function onComplete() {
    if (!challenge) return;
    complete.mutate(challenge.id, {
      onSuccess: () => navigate({ to: "/stage/$stageId", params: { stageId: challenge.stage_id } }),
    });
  }

  if (challenges.isLoading || !challenge) {
    return (
      <AppShell isAdmin={isAdmin.data}>
        <Loader2 className="size-6 animate-spin text-muted-foreground" />
      </AppShell>
    );
  }

  if (gameSettings.data?.race_status === "completed" && !isAdmin.data) {
    return (
      <AppShell isAdmin={false}>
        <div className="surface p-8 max-w-lg mx-auto text-center space-y-6 border border-dashed border-red-500/30 rounded-3xl mt-12 bg-red-950/5">
          <div className="size-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto border border-red-500/20 text-red-500">
            <Lock className="size-8" />
          </div>
          <div className="space-y-2">
            <h1 className="text-3xl font-display font-black uppercase text-red-500">Gara Terminata</h1>
            <p className="text-sm text-muted-foreground leading-relaxed">
              La gara è ufficialmente conclusa. Tutte le prove e i punteggi sono stati congelati.
            </p>
          </div>
        </div>
      </AppShell>
    );
  }

  if (isRebusVisivo) {
    if (!started && state !== "completed") {
      return (
        <AppShell isAdmin={isAdmin.data}>
          <div className="max-w-md mx-auto py-10 space-y-6">
            <Link
              to="/stage/$stageId"
              params={{ stageId: challenge.stage_id }}
              className="text-xs font-bold tracking-widest text-primary uppercase"
            >
              ← Torna alla tappa
            </Link>
            <div className="surface p-6 sm:p-8 space-y-6 bg-card/45 border border-border/40 rounded-2xl animate-pop-in">
              <span className="animate-float-badge accent-gradient w-fit rounded-full px-3 py-1 text-xs font-extrabold tracking-widest text-accent-foreground uppercase">
                Missione
              </span>
              <p className="text-lg font-serif italic text-foreground leading-relaxed">
                "A volte, Viaggiatori, non serve decifrare: serve solo... sapere.
                <span className="block mt-4">
                  Questa immagine non nasconde suoni né sillabe. È un simbolo, puro e semplice.
                </span>
                <span className="block mt-4">
                  Chi conosce davvero Bra, sa già dove correre."
                </span>
              </p>
              <button
                onClick={() => start.mutate(challenge.id)}
                disabled={start.isPending}
                className="primary-gradient w-full py-4 rounded-xl font-extrabold text-primary-foreground shadow-lg hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-2"
              >
                {start.isPending && <Loader2 className="size-4 animate-spin" />}
                Inizia Missione
              </button>
            </div>
          </div>
        </AppShell>
      );
    }

    return (
      <AppShell isAdmin={isAdmin.data}>
        <div className="max-w-md mx-auto py-8 space-y-6 text-center">
          <div className="flex justify-between items-center">
            <Link
              to="/stage/$stageId"
              params={{ stageId: challenge.stage_id }}
              className="text-xs font-bold tracking-widest text-primary uppercase"
            >
              ← Torna alla tappa
            </Link>
          </div>

          <div className="surface border border-border/40 bg-zinc-950/20 rounded-xl overflow-hidden text-left shadow-sm">
            <button
              onClick={() => setShowBriefingDropdown(!showBriefingDropdown)}
              className="w-full flex items-center justify-between px-4 py-3 text-xs font-bold uppercase tracking-wider text-muted-foreground hover:text-foreground hover:bg-muted/5 transition-colors"
            >
              <span>Promemoria Missione</span>
              {showBriefingDropdown ? <ChevronUp className="size-4" /> : <ChevronDown className="size-4" />}
            </button>
            {showBriefingDropdown && (
              <div className="px-4 pb-4 pt-1 border-t border-border/20 bg-zinc-950/40 animate-in slide-in-from-top-2 duration-200">
                <p className="text-sm font-serif italic text-muted-foreground leading-relaxed mt-2">
                  "A volte, Viaggiatori, non serve decifrare: serve solo... sapere.
                  <span className="block mt-2">
                    Questa immagine non nasconde suoni né sillabe. È un simbolo, puro e semplice.
                  </span>
                  <span className="block mt-2">
                    Chi conosce davvero Bra, sa già dove correre."
                  </span>
                </p>
              </div>
            )}
          </div>
          
          <div className="py-6 flex justify-center items-center">
            <span className="text-8xl select-none animate-pulse hover:scale-110 transition-transform duration-300">
              🐌
            </span>
          </div>

          <div className="text-left">
            <PhotoChallenge
              challenge={challenge}
              team={team.data ?? null}
              completed={state === "completed"}
              onComplete={onComplete}
              completing={complete.isPending}
            />
          </div>
        </div>
      </AppShell>
    );
  }



  // Briefing/start screen for the movie emoji challenge
  if (challenge.type === "emoji_movies" && !started && state !== "completed") {
    return (
      <AppShell isAdmin={isAdmin.data}>
        <div className="max-w-md mx-auto py-10 space-y-6">
          <Link
            to="/stage/$stageId"
            params={{ stageId: challenge.stage_id }}
            className="text-xs font-bold tracking-widest text-primary uppercase"
          >
            ← Torna alla tappa
          </Link>
          <div className="surface p-6 sm:p-8 space-y-6 bg-zinc-950 border border-red-950 rounded-2xl animate-pop-in relative overflow-hidden shadow-2xl">
            <div className="absolute top-0 left-0 right-0 h-1 bg-red-600 shadow-[0_0_15px_rgba(220,38,38,0.7)]" />
            <span className="bg-red-950 text-red-500 w-fit rounded-full px-3 py-1 text-xs font-extrabold tracking-widest uppercase border border-red-900/40 flex items-center gap-1.5">
              <Film className="size-3.5 animate-pulse" /> Missione Cinema
            </span>
            <p className="text-sm sm:text-base font-serif italic text-zinc-200 leading-relaxed whitespace-pre-line">
              "Viaggiatori, si spengono le luci, si alza il sipario: benvenuti nella sala più insolita della caccia!

              Otto locandine, otto enigmi fatti di sole immagini.

              Ogni film che indovinerete vi regalerà una lettera: la prima del suo titolo, e nient'altro.

              Mettete le otto lettere in fila, nell'ordine in cui vi ho mostrato le locandine, e scoprirete non un film... ma il prossimo luogo da raggiungere."
            </p>
            <button
              onClick={() => start.mutate(challenge.id)}
              disabled={start.isPending}
              className="primary-gradient w-full py-4 rounded-xl font-extrabold text-primary-foreground shadow-lg hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
            >
              {start.isPending && <Loader2 className="size-4 animate-spin" />}
              Entra in Sala & Inizia la Sfida
            </button>
          </div>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell isAdmin={isAdmin.data}>
      <Link
        to="/stage/$stageId"
        params={{ stageId: challenge.stage_id }}
        className="text-xs font-bold tracking-widest text-primary uppercase"
      >
        ← Torna alla tappa
      </Link>
      <h1 className="mt-2 text-2xl sm:text-4xl font-display leading-tight sm:leading-none break-words">
        {challenge.title}
      </h1>
      <p className="mt-2 text-sm text-muted-foreground">{challenge.description}</p>
      <p className="mt-1 text-xs font-bold text-gold">{challenge.points} punti in palio</p>

      <div className="mt-6 w-full min-w-0">
        {state === "locked" ? (
          <p className="surface flex items-center gap-2 p-5 text-sm text-muted-foreground">
            <Lock className="size-4" /> Completa prima le prove precedenti.
          </p>
        ) : challenge.type === "team_setup" ? (
          <TeamSetupChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "quiz" ? (
          <QuizChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "photo" ? (
          <PhotoChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "emoji_movies" ? (
          <EmojiMoviesChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "living_poster" ? (
          <LivingPosterChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "banca" ? (
          <BancaChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "social" ? (
          <SocialChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "codice" ? (
          <SecretCodeChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "enigma_musicale" ? (
          <EnigmaMusicaleChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "enigma_testo" ? (
          <EnigmaTestoChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "lucchetto_direzionale" ? (
          <LucchettoDirezionaleChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "enigma_coordinate" ? (
          <CoordinateFinaliChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "cornhole" ? (
          <CornholeChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "boxe" ? (
          <BoxeChallenge
            challenge={challenge}
            team={team.data ?? null}
            completed={state === "completed"}
            onComplete={onComplete}
            completing={complete.isPending}
          />
        ) : challenge.type === "jackpot" ? (
          <JackpotChallenge
            challengeId={challenge.id}
            teamId={team.data?.id || ""}
            onComplete={onComplete}
          />
        ) : (
          <div className="surface space-y-4 p-5">
            <p className="text-sm text-muted-foreground">
              Prova libera: conferma il completamento quando l'avete portata a termine.
            </p>
            <button
              onClick={onComplete}
              disabled={state === "completed" || complete.isPending}
              className="primary-gradient w-full rounded-xl py-3.5 font-extrabold text-primary-foreground disabled:opacity-40"
            >
              {state === "completed" ? "Completata" : "Completa la prova"}
            </button>
          </div>
        )}
      </div>
    </AppShell>
  );
}
