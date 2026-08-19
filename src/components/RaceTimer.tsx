import { useEffect, useState } from "react";

export function RaceTimer({
  startedAt,
  endedAt,
  status,
}: {
  startedAt?: string | null;
  endedAt?: string | null;
  status?: string | null;
}) {
  const [now, setNow] = useState(() => Date.now());

  const isTerminated = status === "Gara terminata" || status === "completed" || status === "finished";
  const isNotStarted = !startedAt || status === "Gara non iniziata" || status === "not_started";

  useEffect(() => {
    if (isTerminated || isNotStarted) return;
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, [isTerminated, isNotStarted]);

  if (isNotStarted) {
    return <span className="font-display text-3xl tabular-nums">00:00:00</span>;
  }

  const startMs = new Date(startedAt!).getTime();
  let endMs = now;
  if (isTerminated && endedAt) {
    const parsedEnd = new Date(endedAt).getTime();
    if (!isNaN(parsedEnd) && parsedEnd > 0) {
      endMs = parsedEnd;
    }
  }

  const elapsed = Math.max(0, Math.floor((endMs - startMs) / 1000));
  const h = Math.floor(elapsed / 3600);
  const m = Math.floor((elapsed % 3600) / 60);
  const s = elapsed % 60;
  const pad = (n: number) => String(n).padStart(2, "0");

  return (
    <span className="font-display text-3xl tabular-nums">
      {pad(h)}:{pad(m)}:{pad(s)}
    </span>
  );
}
