import { useState } from "react";
import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { toast } from "sonner";
import { z } from "zod";
import { Loader2, Flag, Eye, EyeOff } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: "Accedi — Pechino Express Bra" },
      {
        name: "description",
        content: "Accedi per partecipare alla gara urbana Pechino Express Bra.",
      },
      { property: "og:title", content: "Accedi — Pechino Express Bra" },
      { property: "og:description", content: "Entra in gara con la tua squadra." },
    ],
  }),
  component: AuthPage,
});

const schema = z.object({
  username: z.string().trim().min(3, { message: "Username non valido" }).max(50),
  password: z.string().min(6, { message: "Minimo 6 caratteri" }).max(72),
});

function AuthPage() {
  const navigate = useNavigate();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const parsed = schema.safeParse({ username, password });
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? "Dati non validi");
      return;
    }
    setLoading(true);
    try {
      // Map username to internal Supabase Auth email format
      const formattedUsername = parsed.data.username.trim().toLowerCase();
      const email = `${formattedUsername}@pechino.it`;

      const { error } = await supabase.auth.signInWithPassword(
        { email, password: parsed.data.password },
        { persist: rememberMe }
      );
      if (error) throw error;
      if (formattedUsername === "justdave") {
        navigate({ to: "/admin" });
      } else {
        navigate({ to: "/dashboard" });
      }
    } catch (err) {
      const errMsg = (err as any)?.message || String(err) || "Errore di autenticazione";
      toast.error(errMsg);
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="hero-gradient flex min-h-screen items-center justify-center px-5 py-12">
      <div className="surface w-full max-w-md p-7">
        <Link to="/" className="text-xs font-bold tracking-widest text-primary uppercase">
          ← Pechino Express Bra
        </Link>
        <h1 className="mt-3 text-4xl">Accedi alla Regia o Squadra</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Inserisci lo username e la password forniti per accedere.
        </p>

        <form onSubmit={handleSubmit} className="mt-6 space-y-3">
          {/* Username */}
          <input
            className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-ring"
            placeholder="Username"
            type="text"
            autoComplete="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
          />

          {/* Password with show/hide toggle */}
          <div className="relative">
            <input
              className="w-full rounded-xl border border-input bg-input/40 px-4 py-3 pr-12 text-sm outline-none focus:ring-2 focus:ring-ring"
              placeholder="Password"
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <button
              type="button"
              aria-label={showPassword ? "Nascondi password" : "Mostra password"}
              onClick={() => setShowPassword((v) => !v)}
              className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center justify-center rounded-lg p-1.5 text-muted-foreground transition-colors hover:text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            >
              {showPassword ? (
                <EyeOff className="size-4" aria-hidden="true" />
              ) : (
                <Eye className="size-4" aria-hidden="true" />
              )}
            </button>
          </div>

          {/* Remember me */}
          <label className="flex cursor-pointer items-center gap-3 rounded-xl border border-input/50 bg-input/20 px-4 py-3 transition-colors hover:bg-input/30 select-none">
            <div className="relative flex shrink-0 items-center justify-center">
              <input
                id="remember-me"
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="peer sr-only"
              />
              <div
                className={`size-5 rounded-md border-2 transition-all duration-200 flex items-center justify-center ${
                  rememberMe
                    ? "border-primary bg-primary text-primary-foreground"
                    : "border-input bg-transparent"
                }`}
              >
                {rememberMe && (
                  <svg
                    className="size-3"
                    viewBox="0 0 12 12"
                    fill="none"
                    aria-hidden="true"
                  >
                    <path
                      d="M2 6l3 3 5-5"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                )}
              </div>
            </div>
            <div className="flex flex-col gap-0.5">
              <span className="text-sm font-semibold text-foreground">
                🔐 Ricorda accesso
              </span>
              <span className="text-[11px] text-muted-foreground leading-tight">
                Rimani connesso anche dopo la chiusura del browser
              </span>
            </div>
          </label>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="primary-gradient flex w-full items-center justify-center gap-2 rounded-xl py-3 font-extrabold text-primary-foreground disabled:opacity-60 mt-1"
          >
            {loading ? <Loader2 className="size-4 animate-spin" /> : <Flag className="size-4" />}
            Accedi
          </button>
        </form>
      </div>
    </main>
  );
}
