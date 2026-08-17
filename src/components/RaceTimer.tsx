import { useEffect, useState } from "react";

export function RaceTimer({ startedAt }: { startedAt: string | null | undefined }) {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  if (!startedAt) return <span className="font-display text-3xl">--:--</span>;
  const elapsed = Math.max(0, Math.floor((now - new Date(startedAt).getTime()) / 1000));
  const h = Math.floor(elapsed / 3600);
  const m = Math.floor((elapsed % 3600) / 60);
  const s = elapsed % 60;
  const pad = (n: number) => String(n).padStart(2, "0");

  return (
    <span className="font-display text-3xl tabular-nums">
      {h > 0 ? `${h}:` : ""}
      {pad(m)}:{pad(s)}
    </span>
  );
}
