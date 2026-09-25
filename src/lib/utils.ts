import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** Numero con il segno giusto: "+5", "-17" oppure "0". Evita gli errori tipo "+-17" quando il segno "+" e' scritto a mano. */
export function signed(n: number | null | undefined): string {
  const v = Number(n ?? 0);
  if (!Number.isFinite(v) || v === 0) return "0";
  return v > 0 ? `+${v}` : `-${Math.abs(v)}`;
}
