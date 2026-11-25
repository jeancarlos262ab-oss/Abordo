import { uniqueViolationOf } from "../db/errors.js";
import { conflict, notFound } from "../lib/errors.js";

const paymentView = (c) => ({ seq: c.paidSeq, id: c.id, amountCents: c.amountCents, paidAt: c.paidAt });

export function shiftService({ shifts, units, charges }) {
  const snapshot = async (shift) => {
    if (!shift) return { shift: null, totals: { count: 0, amountCents: 0 }, recent: [] };
    const [t, unit, recent, latestSeq] = await Promise.all([
      charges.shiftTotals(shift.id),
      units.findById(shift.unitId),
      charges.recentPaidInShift(shift.id),
      charges.latestSeq(shift.id),
    ]);
    return {
      shift: { id: shift.id, startedAt: shift.startedAt, unit: { id: unit.id, label: unit.label, route: unit.route, fareCents: unit.fareCents } },
      totals: { count: t.count, amountCents: t.total },
      recent: recent.map(paymentView),
      latestSeq,
    };
  };

  return {
    async current(driver) {
      return snapshot(await shifts.findOpenByDriver(driver.id));
    },

    async start(driver, unitId) {
      const unit = await units.findOwned(driver.ownerId, unitId);
      if (!unit?.active) throw notFound("Esa unidad no está disponible.");
      if (await shifts.findOpenByDriver(driver.id)) throw conflict("Ya tienes un turno abierto.");
      if (await shifts.findOpenByUnit(unit.id)) throw conflict("Esa unidad ya tiene un turno abierto con otro chofer.");
      try {
        return await snapshot(await shifts.start(driver.id, unit.id));
      } catch (err) {
        // Dos peticiones simultáneas: los índices únicos parciales deciden y aquí se traducen al mismo mensaje.
        const c = uniqueViolationOf(err);
        if (c === "uq_open_shift_driver") throw conflict("Ya tienes un turno abierto.");
        if (c === "uq_open_shift_unit") throw conflict("Esa unidad ya tiene un turno abierto con otro chofer.");
        throw err;
      }
    },

    async end(driver) {
      const open = await shifts.findOpenByDriver(driver.id);
      if (!open) throw notFound("No tienes un turno abierto.");
      const summary = await snapshot(open);
      await shifts.end(open.id);
      return summary;
    },

    /** Pagos nuevos desde el consecutivo `afterSeq` (el teléfono los anuncia con voz). */
    async newPayments(driver, afterSeq) {
      const open = await shifts.findOpenByDriver(driver.id);
      if (!open) return { payments: [], latestSeq: afterSeq };
      const list = await charges.paidInShiftAfter(open.id, afterSeq);
      return { payments: list.map(paymentView), latestSeq: list.at(-1)?.paidSeq ?? afterSeq };
    },
  };
}
