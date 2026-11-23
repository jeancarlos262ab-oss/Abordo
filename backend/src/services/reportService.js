import { dayRangeUtc, hourMx } from "../lib/time.js";

const NO_DRIVER = "Sin chofer";

function groupBy(rows, keyFn, nameFn) {
  const map = new Map();
  for (const r of rows) {
    const k = keyFn(r);
    const g = map.get(k) ?? { id: k, name: nameFn(r), totalCents: 0, count: 0 };
    g.totalCents += r.amount_cents;
    g.count += 1;
    map.set(k, g);
  }
  return [...map.values()].sort((a, b) => b.totalCents - a.totalCents);
}

export function reportService({ charges }) {
  const rowsOf = (ownerId, date) => {
    const { from, to } = dayRangeUtc(date);
    return charges.paidInRange(ownerId, from, to);
  };
  return {
    summary(ownerId, date) {
      const rows = rowsOf(ownerId, date);
      const hourly = Array.from({ length: 24 }, (_, hour) => ({ hour, totalCents: 0 }));
      for (const r of rows) hourly[hourMx(r.paid_at)].totalCents += r.amount_cents;
      return {
        date,
        totalCents: rows.reduce((s, r) => s + r.amount_cents, 0),
        count: rows.length,
        hourly,
        byDriver: groupBy(rows, (r) => r.driver_id ?? 0, (r) => r.driver_name ?? NO_DRIVER),
        byUnit: groupBy(rows, (r) => r.unit_id, (r) => r.unit_label),
      };
    },
    history(ownerId, date, { unitId, driverId, limit, offset }) {
      let rows = rowsOf(ownerId, date);
      if (unitId) rows = rows.filter((r) => r.unit_id === unitId);
      if (driverId) rows = rows.filter((r) => r.driver_id === driverId);
      return {
        total: rows.length,
        items: rows.slice(offset, offset + limit).map((r) => ({
          id: r.id, amountCents: r.amount_cents, paidAt: r.paid_at, unitLabel: r.unit_label, driverName: r.driver_name ?? NO_DRIVER,
        })),
      };
    },
  };
}
