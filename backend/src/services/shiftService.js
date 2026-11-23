import { conflict, notFound } from "../lib/errors.js";

export function shiftService({ shifts, units, charges }) {
  const snapshot = (shift) => {
    if (!shift) return { shift: null, totals: { count: 0, amountCents: 0 }, recent: [] };
    const t = charges.shiftTotals(shift.id);
    const unit = units.findById(shift.unitId);
    return {
      shift: { id: shift.id, startedAt: shift.startedAt, unit: { id: unit.id, label: unit.label, route: unit.route, fareCents: unit.fareCents } },
      totals: { count: t.count, amountCents: t.total },
      recent: charges.recentPaidInShift(shift.id).map(paymentView),
      latestSeq: charges.latestSeq(shift.id),
    };
  };

  return {
    current: (driver) => snapshot(shifts.findOpenByDriver(driver.id)),

    start(driver, unitId) {
      const unit = units.findOwned(driver.ownerId, unitId);
      if (!unit?.active) throw notFound("Esa unidad no está disponible.");
      if (shifts.findOpenByDriver(driver.id)) throw conflict("Ya tienes un turno abierto.");
      if (shifts.findOpenByUnit(unit.id)) throw conflict("Esa unidad ya tiene un turno abierto con otro chofer.");
      return snapshot(shifts.start(driver.id, unit.id));
    },

    end(driver) {
      const open = shifts.findOpenByDriver(driver.id);
      if (!open) throw notFound("No tienes un turno abierto.");
      const summary = snapshot(open);
      shifts.end(open.id);
      return summary;
    },

    /** Pagos nuevos desde el consecutivo `afterSeq` (el teléfono los anuncia con voz). */
    newPayments(driver, afterSeq) {
      const open = shifts.findOpenByDriver(driver.id);
      if (!open) return { payments: [], latestSeq: afterSeq };
      const list = charges.paidInShiftAfter(open.id, afterSeq);
      return { payments: list.map(paymentView), latestSeq: list.at(-1)?.paidSeq ?? afterSeq };
    },
  };
}

const paymentView = (c) => ({ seq: c.paidSeq, id: c.id, amountCents: c.amountCents, paidAt: c.paidAt });
