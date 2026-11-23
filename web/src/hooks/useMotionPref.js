import { useState } from "react";

// Arranca en "pausado" si la persona pidió menos movimiento en su sistema.
export default function useMotionPref() {
  return useState(() => typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
}
