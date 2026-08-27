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
      {/* SFONDO PULITO AD ALTA RISOLUZIONE: Cielo scuro + Mappa antica + Città di Bra alla base */}
      <div 
        className="absolute inset-0 bg-cover bg-bottom bg-no-repeat pointer-events-none"
        style={{ backgroundImage: "url('/hero-bg.jpg')" }}
      />

      {/* Sfumatura morbida superiore per profondità e contrasto */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#0e1218]/70 via-transparent to-black/30 pointer-events-none" />

      {/* CONTENUTO CENTRALE PERFETTAMENTE RESPONSIVE */}
      <div className="relative z-10 w-full max-w-md mx-auto min-h-[100dvh] flex flex-col justify-between items-center px-6 py-10 sm:py-14">
        {/* Blocco Centrale: Logo, Titoli, Slogan e Bottone */}
        <div className="w-full flex flex-col items-center text-center space-y-4 pt-4 sm:pt-8 animate-fade-in">
          {/* Logo Circolare con Bagliore Dorato */}
          <div className="relative">
            <div className="absolute -inset-4 rounded-full bg-amber-400/30 blur-2xl animate-pulse" />
            <img
              src="/pechino-emblem.png"
              alt="Pechino Express Logo"
              className="relative size-28 sm:size-36 object-contain drop-shadow-[0_10px_25px_rgba(0,0,0,0.8)]"
            />
          </div>

          {/* Titolo Vettoriale Pulito */}
          <div className="space-y-0.5">
            <h1 className="text-3xl sm:text-4xl md:text-5xl font-display font-black tracking-widest text-[#1a2d48] drop-shadow-[0_0_18px_rgba(255,255,255,0.85)] uppercase">
              Pechino Express
            </h1>
            <p className="text-2xl sm:text-3xl md:text-4xl font-display font-black tracking-[0.3em] bg-gradient-to-r from-[#e5b364] via-[#fce2a6] to-[#c28f3d] bg-clip-text text-transparent uppercase drop-shadow-md">
              Bra
            </p>
          </div>

          {/* Slogan Richiesto: Corri, Sfida, Conquista */}
          <div className="pt-2">
            <p className="text-xl sm:text-2xl font-bold tracking-wide text-white text-center drop-shadow-[0_2px_12px_rgba(0,0,0,0.95)] font-sans">
              Corri, Sfida, Conquista
            </p>
          </div>

          {/* Bottone Dorato "Entra in gara" */}
          <div className="pt-3">
            <Link
              to="/auth"
              className="group relative inline-flex items-center justify-center gap-2.5 px-9 py-4 rounded-full text-base sm:text-lg font-black tracking-wide text-amber-950 bg-gradient-to-b from-[#e8b96e] via-[#dba24e] to-[#c28f3d] border-2 border-[#f7dba4] shadow-[0_0_30px_rgba(232,185,110,0.6)] hover:shadow-[0_0_45px_rgba(232,185,110,0.95)] hover:scale-105 active:scale-95 transition-all duration-300 cursor-pointer"
            >
              <Flag className="size-5 text-amber-950 fill-amber-950/20 group-hover:rotate-12 transition-transform duration-300" />
              <span>Entra in gara</span>
            </Link>
          </div>
        </div>

        {/* Spazio inferiore per preservare la visibilità della piazza storica di Bra */}
        <div className="w-full pb-4 pointer-events-none" />
      </div>
    </main>
  );
}
