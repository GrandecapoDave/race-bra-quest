import { createFileRoute, Link } from "@tanstack/react-router";
import { Flag } from "lucide-react";

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
    <main className="relative min-h-[100dvh] w-full flex flex-col items-center justify-between bg-[#0e1218] overflow-hidden select-none">
      {/* 1. LAYER SFONDO: Mappa antica + sfumatura scura */}
      <div 
        className="absolute inset-0 bg-cover bg-center opacity-25 mix-blend-luminosity pointer-events-none"
        style={{ backgroundImage: "url('/pechino-landscape-bg.jpg')" }}
      />

      {/* 2. LAYER SFONDO: Scorcio della città di Bra alla base */}
      <div
        className="absolute inset-x-0 bottom-0 h-[40vh] sm:h-[45vh] max-h-[420px] bg-cover bg-bottom bg-no-repeat pointer-events-none opacity-85"
        style={{ backgroundImage: "url('/bra-city-bottom.jpg')" }}
      >
        <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-[#0e1218]" />
      </div>

      {/* 3. LAYER LUCE RADIALE CENTRALE */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 size-72 sm:size-96 rounded-full bg-amber-500/15 blur-3xl pointer-events-none" />

      {/* 4. CONTENUTO CENTRALE RESPONSIVE */}
      <div className="relative z-10 w-full max-w-md mx-auto min-h-[100dvh] flex flex-col justify-between items-center px-6 py-10 sm:py-14">
        {/* Blocco Superiore: Logo + Titolo + Slogan */}
        <div className="w-full flex flex-col items-center text-center space-y-4 pt-4 sm:pt-8 animate-fade-in">
          {/* Logo Circolare con Bagliore */}
          <div className="relative">
            <div className="absolute -inset-3 rounded-full bg-amber-400/25 blur-xl animate-pulse" />
            <img
              src="/pechino-emblem.png"
              alt="Pechino Express Emblem"
              className="relative size-28 sm:size-32 md:size-36 object-contain drop-shadow-[0_10px_25px_rgba(0,0,0,0.8)]"
            />
          </div>

          {/* Scritte del Titolo */}
          <div className="space-y-0.5">
            <h1 className="text-3xl sm:text-4xl font-display font-black tracking-widest text-[#1a2d48] drop-shadow-[0_0_16px_rgba(255,255,255,0.75)] uppercase">
              Pechino Express
            </h1>
            <p className="text-2xl sm:text-3xl font-display font-black tracking-[0.3em] bg-gradient-to-r from-[#e5b364] via-[#fce2a6] to-[#c28f3d] bg-clip-text text-transparent uppercase drop-shadow-md">
              Bra
            </p>
          </div>

          {/* Slogan Richiesto: Corri, Sfida, Conquista */}
          <div className="pt-2">
            <p className="text-lg sm:text-xl font-bold tracking-wide text-white text-center drop-shadow-[0_2px_10px_rgba(0,0,0,0.95)]">
              Corri, Sfida, Conquista
            </p>
          </div>

          {/* Bottone CTA Dorato "Entra in gara" */}
          <div className="pt-3">
            <Link
              to="/auth"
              className="group relative inline-flex items-center justify-center gap-2.5 px-8 py-3.5 sm:px-9 sm:py-4 rounded-full text-base sm:text-lg font-black tracking-wide text-amber-950 bg-gradient-to-b from-[#e8b96e] via-[#dba24e] to-[#c28f3d] border-2 border-[#f7dba4] shadow-[0_0_30px_rgba(232,185,110,0.55)] hover:shadow-[0_0_45px_rgba(232,185,110,0.9)] hover:scale-105 active:scale-95 transition-all duration-300 cursor-pointer"
            >
              <Flag className="size-5 text-amber-950 fill-amber-950/20 group-hover:rotate-12 transition-transform duration-300" />
              <span>Entra in gara</span>
            </Link>
          </div>
        </div>

        {/* Spazio inferiore per preservare la visibilità della piazza di Bra */}
        <div className="w-full pb-4 pointer-events-none" />
      </div>
    </main>
  );
}
