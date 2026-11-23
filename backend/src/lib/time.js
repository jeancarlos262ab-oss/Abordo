// México (CDMX) no usa horario de verano desde 2022: UTC−6 fijo.
export const MX_OFFSET_HOURS = -6;
const HOUR = 3600_000;

/** Rango UTC (ISO) que cubre el día calendario `YYYY-MM-DD` en hora de México. */
export function dayRangeUtc(dateStr) {
  const start = Date.parse(`${dateStr}T00:00:00Z`) - MX_OFFSET_HOURS * HOUR;
  return { from: new Date(start).toISOString(), to: new Date(start + 24 * HOUR).toISOString() };
}

export function todayMx(now = new Date()) {
  return new Date(now.getTime() + MX_OFFSET_HOURS * HOUR).toISOString().slice(0, 10);
}

/** Hora local de México (0-23) de un ISO UTC. */
export function hourMx(iso) {
  return new Date(Date.parse(iso) + MX_OFFSET_HOURS * HOUR).getUTCHours();
}

export const nowIso = () => new Date().toISOString();
