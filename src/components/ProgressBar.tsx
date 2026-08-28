export function ProgressBar({ value, className = "", showGlow = true }: { value: number; className?: string; showGlow?: boolean }) {
  const clamped = Math.min(100, Math.max(0, value));
  return (
    <div className={`relative h-3 w-full overflow-hidden rounded-full bg-secondary/80 p-0.5 border border-border/40 shadow-inner ${className}`}>
      <div
        className={`primary-gradient h-full rounded-full transition-[width] duration-700 ease-out ${showGlow && clamped > 0 ? "glow-primary" : ""}`}
        style={{ width: `${clamped}%` }}
      />
    </div>
  );
}
