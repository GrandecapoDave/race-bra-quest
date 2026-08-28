import { createFileRoute, Link } from "@tanstack/react-router";
import { Flag, ArrowRight } from "lucide-react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Pechino Express Bra — La grande avventura urbana" },
      {
        name: "description",
        content:
          "Squadre, tappe, prove, malus e classifica live: entra nella gara urbana Pechino Express Bra e conquista la vittoria.",
      },
      { property: "og:title", content: "Pechino Express Bra — La grande avventura urbana" },
      {
        property: "og:description",
        content: "Crea la tua squadra, supera le prove, lancia malus e scala la classifica live.",
      },
    ],
  }),
  component: Landing,
});

function Landing() {
  return (
    <main className="relative min-h-screen w-full overflow-hidden bg-[#070d1e] text-white flex flex-col justify-center items-center selection:bg-orange-500 selection:text-black">
      {/* 1. CINEMATIC BACKGROUND IMAGE WITH CLEAN GRADIENT OVERLAY */}
      <div className="fixed inset-0 z-0 pointer-events-none overflow-hidden">
        <img
          src="/hero-bg.jpg"
          alt="Pechino Express Bra Panorama"
          className="w-full h-full object-cover object-center scale-105 transform brightness-[0.75] contrast-[1.05]"
        />

        {/* Soft, Clean Gradient Overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#070d1e]/80 via-[#070d1e]/60 to-[#070d1e]/90" />
        
        {/* Subtle Ambient Center Glow */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[300px] bg-orange-500/10 rounded-full blur-[140px] pointer-events-none" />
      </div>

      {/* 2. MAIN HERO CONTENT */}
      <div className="relative z-10 mx-auto w-full max-w-2xl px-5 py-12 flex flex-col items-center text-center my-auto space-y-7 sm:space-y-9">
        
        {/* MAIN TITLE */}
        <div className="space-y-2">
          <h1 className="font-display font-black text-6xl sm:text-7xl md:text-8xl lg:text-9xl leading-[0.9] uppercase tracking-wider drop-shadow-[0_10px_30px_rgba(0,0,0,0.8)]">
            <span className="block text-white">PECHINO EXPRESS</span>
            <span className="block bg-gradient-to-r from-orange-400 via-amber-300 to-orange-500 bg-clip-text text-transparent drop-shadow-[0_0_30px_rgba(249,115,22,0.4)]">
              BRA
            </span>
          </h1>

          <p className="pt-2 text-base sm:text-xl font-bold text-zinc-200/90 max-w-md mx-auto leading-relaxed tracking-wide">
            La grande avventura urbana nel cuore di Bra.
          </p>
        </div>

        {/* MINI STATS COUNTERS */}
        <div className="w-full max-w-lg bg-zinc-950/50 border border-white/10 backdrop-blur-md rounded-2xl py-3 px-4 shadow-xl grid grid-cols-3 divide-x divide-white/10">
          <div className="flex flex-col items-center text-center px-1">
            <span className="text-xl sm:text-2xl font-display font-black text-orange-400">5</span>
            <span className="text-[10px] sm:text-[11px] font-black uppercase tracking-wider text-zinc-300">Tappe</span>
          </div>
          <div className="flex flex-col items-center text-center px-1">
            <span className="text-xl sm:text-2xl font-display font-black text-amber-400">15</span>
            <span className="text-[10px] sm:text-[11px] font-black uppercase tracking-wider text-zinc-300">Prove</span>
          </div>
          <div className="flex flex-col items-center text-center px-1">
            <span className="text-xl sm:text-2xl font-display font-black text-cyan-400">LIVE</span>
            <span className="text-[10px] sm:text-[11px] font-black uppercase tracking-wider text-zinc-300">Market & Malus</span>
          </div>
        </div>

        {/* REFINED SLEEK CTA BUTTON */}
        <div className="pt-1">
          <Link
            to="/auth"
            className="group relative px-8 py-3.5 sm:px-10 sm:py-4 rounded-full bg-gradient-to-r from-orange-500 via-amber-500 to-orange-500 hover:from-orange-400 hover:to-amber-400 text-black font-display font-black text-lg sm:text-xl uppercase tracking-widest shadow-xl shadow-orange-500/25 hover:shadow-orange-500/40 hover:scale-[1.03] active:scale-[0.98] transition-all duration-300 flex items-center justify-center gap-2.5 cursor-pointer border border-orange-300/30"
          >
            <Flag className="size-5 text-black fill-black/20 stroke-[2.5]" />
            <span>Entra in Gara</span>
            <ArrowRight className="size-5 text-black group-hover:translate-x-1 transition-transform duration-300 stroke-[3]" />
          </Link>
        </div>

      </div>
    </main>
  );
}
