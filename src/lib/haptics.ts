/**
 * Haptic feedback no-op utility (disabled).
 */

export type HapticType = "light" | "medium" | "heavy" | "success" | "warning" | "error" | "spin";

export function triggerHaptic(_type: HapticType = "light"): void {
  // Intentionally disabled
}
