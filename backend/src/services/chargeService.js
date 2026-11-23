import { randomUUID } from "node:crypto";
import { AppError, notFound } from "../lib/errors.js";

/** Vista pública de un cobro: nada del dueño ni del chofer. */
export const chargeView = (c, unit) => ({
  id: c.id,
  status: c.status,
  amountCents: c.amountCents,
  unitLabel: unit?.label,
  route: unit?.route,
  qrPayload: c.qrPayload,
  paymentLink: c.payLink,
  expiresAt: c.expiresAt,
  paidAt: c.paidAt,
});

export function chargeService({ charges, units, shifts, ownerService, pey, config }) {
  /** Sincroniza el estado con pey (plan B del webhook) y vence cobros viejos. */
  async function refresh(charge) {
    if (charge.status !== "pending") return charge;
    try {
      const credentials = ownerService.getPeyCredentials(charge.ownerId);
      const { status } = await pey.getCharge({ credentials, peyRef: charge.peyRef });
      if (status === "paid") return charges.pay(charge.id);
      if (status === "failed" || status === "expired") return charges.setStatus(charge.id, status);
    } catch (e) {
      if (!(e instanceof AppError)) throw e; // si pey no responde, seguimos con el último estado conocido
    }
    return Date.parse(charge.expiresAt) < Date.now() ? charges.setStatus(charge.id, "expired") : charge;
  }

  return {
    async create(unitCode, { payerPhone }) {
      const unit = units.findByCode(unitCode);
      if (!unit?.active) throw notFound("Esa unidad no existe o no está disponible.");
      if (!ownerService.canCharge(unit.ownerId)) {
        throw new AppError(409, "unit_not_ready", "Esta unidad todavía no puede recibir pagos con CoDi.");
      }
      const shift = shifts.findOpenByUnit(unit.id);
      const id = randomUUID();
      const expiresAt = new Date(Date.now() + config.chargeTtlMs).toISOString();
      const { clabe } = ownerService.getSettings(unit.ownerId);
      const r = await pey.createCharge({
        credentials: ownerService.getPeyCredentials(unit.ownerId),
        clabe,
        amountCents: unit.fareCents,
        concept: `Pasaje ${unit.label} ${unit.route}`,
        reference: id,
        payerPhone,
        expiresAt,
      });
      const saved = charges.insert({
        id, ownerId: unit.ownerId, unitId: unit.id, shiftId: shift?.id ?? null, driverId: shift?.driverId ?? null,
        amountCents: unit.fareCents, peyRef: r.peyRef, qrPayload: r.qrPayload, payLink: r.payLink, expiresAt,
      });
      return chargeView(saved, unit);
    },

    async getPublic(id) {
      const c = charges.findById(id);
      if (!c) throw notFound("No encontramos ese cobro.");
      return chargeView(await refresh(c), units.findById(c.unitId));
    },

    /** Webhook de pey: idempotente; ignora referencias desconocidas. */
    applyWebhook({ peyRef, status }) {
      const c = charges.findByPeyRef(peyRef);
      if (!c) return;
      if (status === "paid") charges.pay(c.id);
      else if (status === "failed" || status === "expired") charges.setStatus(c.id, status);
    },
  };
}
