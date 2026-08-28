/**
 * Dual-Engine Haptic Feedback utility for iOS (Safari Web Audio Taptic Pulse)
 * and Android (Navigator Vibration API).
 * Safely initializes on the first user interaction.
 */

export type HapticType = "light" | "medium" | "heavy" | "success" | "warning" | "error" | "spin";

let audioCtx: AudioContext | null = null;
let isAudioUnlocked = false;

function initAudioContext(): AudioContext | null {
  if (typeof window === "undefined") return null;
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (AudioContextClass) {
      audioCtx = new AudioContextClass();
    }
  }
  if (audioCtx && audioCtx.state === "suspended") {
    audioCtx.resume().catch(() => {});
  }
  return audioCtx;
}

// Automatically unlock audio context on very first user touch or click
if (typeof window !== "undefined") {
  const unlockAudio = () => {
    if (isAudioUnlocked) return;
    try {
      const ctx = initAudioContext();
      if (ctx) {
        if (ctx.state === "suspended") {
          ctx.resume().catch(() => {});
        }
        isAudioUnlocked = true;
      }
    } catch {
      // Ignore
    } finally {
      window.removeEventListener("touchstart", unlockAudio);
      window.removeEventListener("pointerdown", unlockAudio);
      window.removeEventListener("click", unlockAudio);
    }
  };

  window.addEventListener("touchstart", unlockAudio, { passive: true });
  window.addEventListener("pointerdown", unlockAudio, { passive: true });
  window.addEventListener("click", unlockAudio, { passive: true });
}

/**
 * Synthesizes a low-latency crisp sub-bass micro-impulse on iOS devices
 * that triggers the iPhone speaker/taptic resonance.
 */
function playIosTapticPulse(freq: number, durationMs: number, gainValue = 0.9) {
  try {
    const ctx = initAudioContext();
    if (!ctx) return;

    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(freq, now);

    const durSec = durationMs / 1000;
    gain.gain.setValueAtTime(gainValue, now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + durSec);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + durSec);
  } catch {
    // Graceful no-op if blocked
  }
}

export function triggerHaptic(type: HapticType = "light"): void {
  if (typeof window === "undefined") return;

  // 1. Android Vibration API
  if ("vibrate" in navigator && typeof navigator.vibrate === "function") {
    try {
      switch (type) {
        case "light":
          navigator.vibrate(15);
          break;
        case "medium":
          navigator.vibrate(30);
          break;
        case "heavy":
          navigator.vibrate(60);
          break;
        case "success":
          navigator.vibrate([25, 40, 35]);
          break;
        case "warning":
          navigator.vibrate([50, 40, 50]);
          break;
        case "error":
          navigator.vibrate([70, 40, 70, 40, 70]);
          break;
        case "spin":
          navigator.vibrate([15, 25, 15, 25, 30]);
          break;
        default:
          navigator.vibrate(20);
      }
    } catch {
      // Ignored
    }
  }

  // 2. iOS Taptic Synth Engine (Web Audio Micro-Impulses)
  try {
    switch (type) {
      case "light":
        playIosTapticPulse(160, 14, 0.7);
        break;
      case "medium":
        playIosTapticPulse(140, 22, 0.85);
        break;
      case "heavy":
        playIosTapticPulse(110, 35, 1.0);
        break;
      case "success":
        playIosTapticPulse(180, 16, 0.8);
        setTimeout(() => playIosTapticPulse(240, 24, 0.9), 60);
        break;
      case "warning":
        playIosTapticPulse(130, 30, 0.9);
        setTimeout(() => playIosTapticPulse(110, 30, 0.9), 70);
        break;
      case "error":
        playIosTapticPulse(90, 40, 1.0);
        setTimeout(() => playIosTapticPulse(80, 40, 1.0), 80);
        break;
      case "spin":
        playIosTapticPulse(200, 12, 0.6);
        setTimeout(() => playIosTapticPulse(220, 14, 0.7), 50);
        break;
      default:
        playIosTapticPulse(150, 16, 0.75);
    }
  } catch {
    // Ignored
  }
}
