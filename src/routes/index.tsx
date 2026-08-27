import { createFileRoute, Link } from "@tanstack/react-router";
import { Flag, MapPin, Trophy, Camera } from "lucide-react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Pechino Express Bra — La gara urbana di Bra" },
      {
        name: "description",
        content:
          "Squadre, tappe, prove e classifica live: entra nella gara urbana Pechino Express Bra e conquista Piazza Caduti per la Libertà.",
      },
      { property: "og:title", content: "Pechino Express Bra — La gara urbana di Bra" },
      {
        property: "og:description",
        content: "Crea la tua squadra, supera le prove e scala la classifica live.",
      },
    ],
  }),
  component: Landing,
});

function Landing() {
  return (
    <main className="hero-gradient min-h-screen">
      <div className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center px-5 py-16">
        <h1 className="text-6xl leading-none sm:text-8xl">
          Pechino Express
          <span className="block bg-[image:var(--gradient-primary)] bg-clip-text text-transparent">
            Bra
          </span>
        </h1>
        <p className="mt-5 max-w-lg text-xl sm:text-2xl font-bold text-white/95 tracking-wide">
          Corri, Sfida, Conquista
        </p>

        <div className="mt-8 flex flex-wrap gap-3">
          <Link
            to="/auth"
            className="primary-gradient glow inline-flex items-center gap-2 rounded-full px-7 py-3.5 text-base font-extrabold text-primary-foreground transition-transform hover:scale-[1.03]"
          >
            <Flag className="size-5" /> Entra in gara
          </Link>
        </div>

        <div className="mt-14 grid gap-4 sm:grid-cols-3">
          {[
            { icon: MapPin, title: "Tappe reali", text: "Checkpoint nel cuore di Bra" },
            { icon: Camera, title: "Prove multiple", text: "Quiz, foto GPS e missioni" },
            { icon: Trophy, title: "Ranking live", text: "Punti, tempi e bonus arrivo" },
          ].map((f) => (
            <div key={f.title} className="surface animate-pop-in p-5">
              <f.icon className="size-6 text-primary" />
              <h2 className="mt-3 text-2xl">{f.title}</h2>
              <p className="text-sm text-muted-foreground">{f.text}</p>
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
