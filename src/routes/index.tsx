import { createFileRoute, Link } from "@tanstack/react-router";
import { Flag, MapPin, Trophy, Camera } from "lucide-react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Pechino Express Bra — La gara urbana di Bra" },
      {
        name: "description",
        content:
          "Corri, Sfida, Conquista. Entra nella gara urbana Pechino Express Bra e scala la classifica live.",
      },
      { property: "og:title", content: "Pechino Express Bra" },
      {
        property: "og:description",
        content: "Corri, Sfida, Conquista.",
      },
    ],
  }),
  component: Landing,
});

function Landing() {
  return (
    <main className="relative min-h-[100dvh] w-full flex flex-col justify-center bg-[#0e1218] overflow-x-hidden select-none">
      {/* Sfondo panoramico con sfumatura morbida */}
      <div 
        className="absolute inset-0 bg-cover bg-bottom bg-no-repeat pointer-events-none opacity-40 mix-blend-luminosity"
        style={{ backgroundImage: "url('/hero-bg.jpg')" }}
      />
      <div className="absolute inset-0 bg-gradient-to-t from-[#0e1218] via-[#0e1218]/80 to-[#0e1218]/90 pointer-events-none" />

      {/* Luce d'atmosfera dorata */}
      <div className="absolute top-12 left-1/4 size-96 rounded-full bg-amber-500/10 blur-3xl pointer-events-none" />

      {/* Contenitore principale con struttura originale */}
      <div className="relative z-10 mx-auto flex min-h-[100dvh] max-w-3xl flex-col justify-center px-5 py-12 sm:py-16">
        
        {/* Intestazione: Nuovo Logo + Titolo Ufficiale */}
        <div className="flex items-center gap-4 sm:gap-5 mb-2 animate-fade-in">
          <div className="relative shrink-0">
            <div className="absolute -inset-3 rounded-full bg-amber-400/30 blur-xl animate-pulse" />
            <img
              src="/pechino-emblem.png"
              alt="Pechino Express Logo"
              className="relative size-16 sm:size-20 md:size-24 object-contain drop-shadow-[0_8px_20px_rgba(0,0,0,0.8)]"
            />
          </div>
          <div>
            <h1 className="text-4xl sm:text-6xl md:text-7xl font-display font-black leading-none uppercase tracking-wide text-foreground">
              Pechino Express
              <span className="block bg-gradient-to-r from-[#e5b364] via-[#fce2a6] to-[#c28f3d] bg-clip-text text-transparent">
                Bra
              </span>
            </h1>
          </div>
        </div>

        {/* Slogan: Corri, Sfida, Conquista */}
        <p className="mt-4 max-w-lg text-xl sm:text-2xl font-bold text-white tracking-wide drop-shadow-sm font-sans">
          Corri, Sfida, Conquista
        </p>

        {/* Pulsante CTA Dorato */}
        <div className="mt-8 flex flex-wrap gap-3">
          <Link
            to="/auth"
            className="group relative inline-flex items-center justify-center gap-2.5 px-8 py-3.5 sm:px-9 sm:py-4 rounded-full text-base sm:text-lg font-black tracking-wide text-amber-950 bg-gradient-to-b from-[#e8b96e] via-[#dba24e] to-[#c28f3d] border-2 border-[#f7dba4] shadow-[0_0_30px_rgba(232,185,110,0.6)] hover:shadow-[0_0_45px_rgba(232,185,110,0.95)] hover:scale-105 active:scale-95 transition-all duration-300 cursor-pointer"
          >
            <Flag className="size-5 text-amber-950 fill-amber-950/20 group-hover:rotate-12 transition-transform duration-300" />
            <span>Entra in gara</span>
          </Link>
        </div>

        {/* 3 Card Informative della Struttura Originale */}
        <div className="mt-12 sm:mt-14 grid gap-4 sm:grid-cols-3">
          {[
            { icon: MapPin, title: "Tappe reali", text: "Checkpoint nel cuore di Bra" },
            { icon: Camera, title: "Prove multiple", text: "Quiz, foto GPS e missioni" },
            { icon: Trophy, title: "Ranking live", text: "Punti, tempi e bonus arrivo" },
          ].map((f) => (
            <div
              key={f.title}
              className="surface p-5 rounded-2xl border border-border/40 bg-zinc-950/60 backdrop-blur-md transition-all duration-300 hover:-translate-y-1 hover:border-amber-500/40 shadow-lg"
            >
              <f.icon className="size-6 text-primary mb-3" />
              <h2 className="text-xl font-bold font-display text-foreground">{f.title}</h2>
              <p className="text-sm text-muted-foreground mt-1">{f.text}</p>
            </div>
          ))}
        </div>

      </div>
    </main>
  );
}
