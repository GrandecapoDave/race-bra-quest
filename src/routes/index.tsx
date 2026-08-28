import { createFileRoute, Link } from "@tanstack/react-router";
import { Flag, Compass, Swords, Trophy, ArrowRight, Smartphone } from "lucide-react";

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
    <main className="relative min-h-screen w-full overflow-x-hidden bg-[#070d1e] text-white flex flex-col justify-between selection:bg-orange-500 selection:text-black">
      {/* 1. CINEMATIC BACKGROUND IMAGE WITH DUAL-LAYER OVERLAY */}
      <div className="fixed inset-0 z-0 pointer-events-none overflow-hidden">
        {/* Background Image */}
        <img
          src="/hero-bg.jpg"
          alt="Pechino Express Bra Panorama"
          className="w-full h-full object-cover object-center scale-105 transform animate-in fade-in duration-1000 brightness-[0.7] contrast-[1.05]"
        />

        {/* Deep Gradient Overlay for Maximum Readability */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#070d1e]/90 via-[#070d1e]/75 to-[#070d1e]/95 backdrop-blur-[1px]" />
        
        {/* Ambient Radial Glows */}
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[350px] bg-orange-500/15 rounded-full blur-[120px] pointer-events-none" />
        <div className="absolute bottom-10 left-1/4 w-[400px] h-[250px] bg-cyan-500/10 rounded-full blur-[100px] pointer-events-none" />
      </div>

      {/* 2. MAIN HERO CONTENT */}
      <div className="relative z-10 mx-auto w-full max-w-4xl px-4 sm:px-6 pt-12 sm:pt-20 pb-16 flex flex-col items-center text-center my-auto">
        
        {/* LIVE RACE BADGE */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-zinc-950/70 border border-white/15 backdrop-blur-xl shadow-lg shadow-black/40 mb-6 sm:mb-8 animate-in fade-in slide-in-from-top-4 duration-700">
          <span className="flex size-2 rounded-full bg-emerald-400 animate-ping" />
          <span className="text-[11px] sm:text-xs font-black uppercase tracking-[0.2em] text-zinc-300">
            📍 BRA (CN) · EDIZIONE SPECIALE · <span className="text-emerald-400">GARA ATTIVA</span>
          </span>
        </div>

        {/* MAIN TITLE (EPIC HUD STYLE) */}
        <div className="space-y-1 sm:space-y-2 max-w-3xl">
          <h1 className="font-display font-black text-5xl sm:text-7xl md:text-8xl lg:text-9xl leading-[0.9] uppercase tracking-wider drop-shadow-[0_10px_35px_rgba(0,0,0,0.8)]">
            <span className="block text-white">PECHINO EXPRESS</span>
            <span className="block bg-gradient-to-r from-orange-400 via-amber-300 to-orange-500 bg-clip-text text-transparent drop-shadow-[0_0_35px_rgba(249,115,22,0.4)]">
              BRA
            </span>
          </h1>

          <p className="pt-3 sm:pt-4 text-base sm:text-xl md:text-2xl font-bold text-zinc-200/90 max-w-xl mx-auto leading-snug tracking-wide text-balance">
            Corri tra le vie storiche, risolvi enigmi, gestisci i tuoi token e sferra malus agli avversari.
          </p>
        </div>

        {/* HERO CTA BUTTON */}
        <div className="mt-8 sm:mt-10 flex flex-col sm:flex-row items-center justify-center gap-4 w-full max-w-md">
          <Link
            to="/auth"
            className="group relative w-full sm:w-auto px-8 sm:px-10 py-4 sm:py-5 rounded-2xl bg-gradient-to-r from-orange-500 via-amber-500 to-orange-500 hover:from-orange-400 hover:to-amber-400 text-black font-display font-black text-xl sm:text-2xl uppercase tracking-widest shadow-[0_10px_35px_-5px_rgba(249,115,22,0.6)] hover:shadow-[0_15px_45px_-5px_rgba(249,115,22,0.8)] active:scale-[0.98] transition-all duration-300 flex items-center justify-center gap-3 cursor-pointer overflow-hidden border border-orange-300/40"
          >
            {/* Shimmer Effect */}
            <div className="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-white/30 to-transparent skew-x-12" />
            
            <Flag className="size-6 text-black fill-black/20 stroke-[2.5]" />
            <span>ENTRA IN GARA</span>
            <ArrowRight className="size-6 text-black group-hover:translate-x-1.5 transition-transform duration-300 stroke-[3]" />
          </Link>
        </div>

        <p className="mt-3 text-[11px] sm:text-xs font-semibold text-zinc-400 uppercase tracking-wider">
          Accesso immediato con il codice o PIN della tua squadra
        </p>

        {/* 3. MINI HUD RACE STATS COUNTER BAR */}
        <div className="mt-12 sm:mt-14 w-full max-w-2xl bg-zinc-950/60 border border-white/10 backdrop-blur-xl rounded-2xl p-4 sm:p-5 shadow-2xl shadow-black/60 grid grid-cols-3 divide-x divide-white/10">
          <div className="flex flex-col items-center text-center px-2">
            <span className="text-xl sm:text-3xl font-display font-black text-orange-400">5</span>
            <span className="text-[10px] sm:text-xs font-black uppercase tracking-wider text-zinc-300">Tappe Urbane</span>
          </div>
          <div className="flex flex-col items-center text-center px-2">
            <span className="text-xl sm:text-3xl font-display font-black text-amber-400">15</span>
            <span className="text-[10px] sm:text-xs font-black uppercase tracking-wider text-zinc-300">Prove & Quiz</span>
          </div>
          <div className="flex flex-col items-center text-center px-2">
            <span className="text-xl sm:text-3xl font-display font-black text-cyan-400">LIVE</span>
            <span className="text-[10px] sm:text-xs font-black uppercase tracking-wider text-zinc-300">Malus & Token</span>
          </div>
        </div>

        {/* 4. 3D GLASSMORPHIC FEATURE CARDS */}
        <div className="mt-10 sm:mt-12 grid grid-cols-1 sm:grid-cols-3 gap-4 w-full text-left">
          {/* CARD 1: ESPLORA */}
          <div className="group bg-zinc-950/50 hover:bg-zinc-900/60 border border-white/10 hover:border-orange-500/40 backdrop-blur-xl p-5 rounded-2xl transition-all duration-300 shadow-xl space-y-3">
            <div className="size-11 rounded-xl bg-orange-500/15 border border-orange-500/30 flex items-center justify-center text-orange-400 group-hover:scale-110 transition-transform">
              <Compass className="size-6 stroke-[2.2]" />
            </div>
            <div className="space-y-1">
              <h3 className="font-display font-black text-lg text-white uppercase tracking-wide">
                Esplora & Raggiungi
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed font-medium">
                Scova i checkpoint nel cuore di Bra, supera le prove sul posto e sblocca la tappa successiva.
              </p>
            </div>
          </div>

          {/* CARD 2: STRATEGIA & MALUS */}
          <div className="group bg-zinc-950/50 hover:bg-zinc-900/60 border border-white/10 hover:border-purple-500/40 backdrop-blur-xl p-5 rounded-2xl transition-all duration-300 shadow-xl space-y-3">
            <div className="size-11 rounded-xl bg-purple-500/15 border border-purple-500/30 flex items-center justify-center text-purple-400 group-hover:scale-110 transition-transform">
              <Swords className="size-6 stroke-[2.2]" />
            </div>
            <div className="space-y-1">
              <h3 className="font-display font-black text-lg text-white uppercase tracking-wide">
                Strategia & Malus
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed font-medium">
                Guadagna token, compra Freeze e Ruota Sfortunata nel Marketplace e ostacola le squadre rivali.
              </p>
            </div>
          </div>

          {/* CARD 3: CLASSIFICA & VITTORIA */}
          <div className="group bg-zinc-950/50 hover:bg-zinc-900/60 border border-white/10 hover:border-amber-500/40 backdrop-blur-xl p-5 rounded-2xl transition-all duration-300 shadow-xl space-y-3">
            <div className="size-11 rounded-xl bg-amber-500/15 border border-amber-500/30 flex items-center justify-center text-amber-400 group-hover:scale-110 transition-transform">
              <Trophy className="size-6 stroke-[2.2]" />
            </div>
            <div className="space-y-1">
              <h3 className="font-display font-black text-lg text-white uppercase tracking-wide">
                Traguardo & Gloria
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed font-medium">
                Accumula punti, taglia il traguardo per primo e incassa i bonus tempo e token finali.
              </p>
            </div>
          </div>
        </div>

        {/* 5. FOOTER PWA HINT */}
        <div className="mt-12 flex items-center justify-center gap-2 text-zinc-500 text-[11px] font-semibold">
          <Smartphone className="size-3.5 text-zinc-400" />
          <span>Consiglio: Tocca "Aggiungi a schermata Home" per giocare a schermo intero!</span>
        </div>
      </div>
    </main>
  );
}
