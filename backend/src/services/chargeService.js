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

export function chargeService({ charges, units, shifts, ownerService, passengerService, pey, config }) {
  /** Sincroniza el estado con pey (plan B del webhook) y vence cobros viejos. */
  async function refresh(charge) {
    if (charge.status !== "pending") return charge;
    try {
      const credentials = await ownerService.getPeyCredentials(charge.ownerId);
      const { status } = await pey.getCharge({ credentials, peyRef: charge.peyRef });
      if (status === "paid") return await charges.pay(charge.id);
      if (status === "failed" || status === "expired") return await charges.setStatus(charge.id, status);
    } catch (e) {
      if (!(e instanceof AppError)) throw e; // si pey no responde, seguimos con el último estado conocido
    }
    return Date.parse(charge.expiresAt) < Date.now() ? charges.setStatus(charge.id, "expired") : charge;
  }

  return {
    async create(unitCode, { payerPhone, passengerId }) {
      const unit = await units.findByCode(unitCode);
      if (!unit?.active) throw notFound("Esa unidad no existe o no está disponible.");
      const settings = await ownerService.getSettings(unit.ownerId);
      if (!ownerService.canChargeWith(settings)) {
        throw new AppError(409, "unit_not_ready", "Esta unidad todavía no puede recibir pagos con CoDi.");
      }
      const shift = await shifts.findOpenByUnit(unit.id);
      // Un pasajero con cuenta vinculada recibe el aviso en su banco aunque no escriba el celular.
      payerPhone ??= passengerId ? await passengerService.linkedPhone(passengerId) : undefined;
      const id = randomUUID();
      const expiresAt = new Date(Date.now() + config.chargeTtlMs).toISOString();
      const r = await pey.createCharge({
        credentials: ownerService.credentialsOf(settings),
        clabe: settings.clabe,
        amountCents: unit.fareCents,
        concept: `Pasaje ${unit.label} ${unit.route}`,
        reference: id,
        payerPhone,
        expiresAt,
      });
      const saved = await charges.insert({
        id, ownerId: unit.ownerId, unitId: unit.id, shiftId: shift?.id ?? null, driverId: shift?.driverId ?? null,
        amountCents: unit.fareCents, peyRef: r.peyRef, qrPayload: r.qrPayload, payLink: r.payLink, expiresAt, passengerId,
      });
      return chargeView(saved, unit);
    },

    async getPublic(id) {
      const c = await charges.findById(id);
      if (!c) throw notFound("No encontramos ese cobro.");
      return chargeView(await refresh(c), await units.findById(c.unitId));
    },

    /** Webhook de pey: idempotente; ignora referencias desconocidas. */
    async applyWebhook({ peyRef, status }) {
      const c = await charges.findByPeyRef(peyRef);
      if (!c) return;
      if (status === "paid") await charges.pay(c.id);
      else if (status === "failed" || status === "expired") await charges.setStatus(c.id, status);
    },
  };
}
