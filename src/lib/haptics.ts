/**
 * Haptic Feedback utility for mobile devices (Vibration API).
 * Safely checks for navigator.vibrate support and falls back gracefully.
 */

export type HapticType = "light" | "medium" | "heavy" | "success" | "warning" | "error" | "spin";

export function triggerHaptic(type: HapticType = "light"): void {
  if (typeof window === "undefined" || !("vibrate" in navigator)) {
    return;
  }

  try {
    switch (type) {
      case "light":
        // Subtle tap for tabs, navigation, minor clicks
        navigator.vibrate(15);
        break;
      case "medium":
        // Standard button press / toggle
        navigator.vibrate(30);
        break;
      case "heavy":
        // Important confirmation / unlock
        navigator.vibrate(60);
        break;
      case "success":
        // Double pulse for correct answer, reward, purchase complete
        navigator.vibrate([30, 40, 50]);
        break;
      case "warning":
        // Attention grabber (e.g. malus incoming)
        navigator.vibrate([60, 50, 60]);
        break;
      case "error":
        // Three sharp pulses for wrong answer or failure
        navigator.vibrate([80, 40, 80, 40, 80]);
        break;
      case "spin":
        // Rhythmic tick for wheel spin start
        navigator.vibrate([20, 30, 20, 30, 40]);
        break;
      default:
        navigator.vibrate(20);
    }
  } catch {
    // Graceful no-op if vibration is blocked or restricted by browser
  }
}
