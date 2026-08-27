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
    <main className="relative min-h-[100dvh] w-full flex items-center justify-center bg-[#11161d] overflow-x-hidden">
      {/* Background container with responsive mobile framing & full bleed on phones */}
      <div
        className="relative w-full max-w-[500px] min-h-[100dvh] flex flex-col justify-between items-center bg-cover bg-center bg-no-repeat shadow-2xl"
        style={{ backgroundImage: "url('/pechino-hero-bg.jpg')" }}
      >
        {/* Top spacer to align with logo in background */}
        <div className="w-full pt-[370px] sm:pt-[390px] flex flex-col items-center px-6 space-y-6">
          {/* Subtitle text */}
          <p className="text-xl sm:text-2xl font-bold tracking-wider text-white text-center drop-shadow-[0_2px_12px_rgba(0,0,0,0.95)] font-sans">
            Corri, Sfida, Conquista
          </p>

          {/* Golden Button */}
          <div>
            <Link
              to="/auth"
              className="inline-flex items-center justify-center gap-2.5 px-8 py-3.5 rounded-full text-base font-extrabold text-amber-950 bg-gradient-to-b from-[#e5b364] via-[#dca450] to-[#c28f3d] border-2 border-[#f6d799] shadow-[0_0_25px_rgba(229,179,100,0.5)] hover:shadow-[0_0_35px_rgba(229,179,100,0.85)] hover:scale-105 active:scale-95 transition-all duration-300 cursor-pointer"
            >
              <Flag className="size-5 text-amber-950 fill-amber-950/20" />
              <span>Entra in gara</span>
            </Link>
          </div>
        </div>

        {/* Bottom spacing to preserve panoramic city view */}
        <div className="pb-8" />
      </div>
    </main>
  );
}
