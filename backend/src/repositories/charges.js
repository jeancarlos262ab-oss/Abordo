import { nowIso } from "../lib/time.js";

const toCharge = (r) =>
  r && {
    id: r.id, ownerId: r.owner_id, unitId: r.unit_id, shiftId: r.shift_id, driverId: r.driver_id,
    amountCents: r.amount_cents, status: r.status, peyRef: r.pey_ref, qrPayload: r.qr_payload, payLink: r.pay_link,
    createdAt: r.created_at, expiresAt: r.expires_at, paidAt: r.paid_at, paidSeq: r.paid_seq,
  };

export function chargesRepo(db) {
  const get = (id) => toCharge(db.prepare("SELECT * FROM charges WHERE id = ?").get(id));
  const markPaid = db.prepare(
    `UPDATE charges SET status = 'paid', paid_at = ?, paid_seq = (SELECT COALESCE(MAX(paid_seq), 0) + 1 FROM charges)
     WHERE id = ? AND status IN ('pending','expired')`,
  );
  return {
    findById: get,
    findByPeyRef: (ref) => toCharge(db.prepare("SELECT * FROM charges WHERE pey_ref = ?").get(ref)),
    insert(c) {
      db.prepare(
        `INSERT INTO charges (id, owner_id, unit_id, shift_id, driver_id, amount_cents, status, pey_ref, qr_payload, pay_link, created_at, expires_at)
         VALUES (@id, @ownerId, @unitId, @shiftId, @driverId, @amountCents, 'pending', @peyRef, @qrPayload, @payLink, @createdAt, @expiresAt)`,
      ).run({ ...c, createdAt: nowIso() });
      return get(c.id);
    },
    /** Idempotente: solo la primera llamada cambia el estado y asigna el consecutivo de pago. */
    pay(id) {
      markPaid.run(nowIso(), id);
      return get(id);
    },
    setStatus(id, status) {
      db.prepare("UPDATE charges SET status = ? WHERE id = ? AND status = 'pending'").run(status, id);
      return get(id);
    },
    /** Cobros pagados de un turno con consecutivo mayor a `afterSeq` (para el aviso de voz). */
    paidInShiftAfter: (shiftId, afterSeq, limit = 50) =>
      db.prepare("SELECT * FROM charges WHERE shift_id = ? AND status = 'paid' AND paid_seq > ? ORDER BY paid_seq LIMIT ?").all(shiftId, afterSeq, limit).map(toCharge),
    shiftTotals: (shiftId) =>
      db.prepare("SELECT COUNT(*) AS count, COALESCE(SUM(amount_cents),0) AS total FROM charges WHERE shift_id = ? AND status = 'paid'").get(shiftId),
    latestSeq: (shiftId) => db.prepare("SELECT COALESCE(MAX(paid_seq), 0) AS n FROM charges WHERE shift_id = ?").get(shiftId).n,
    recentPaidInShift: (shiftId, limit = 8) =>
      db.prepare("SELECT * FROM charges WHERE shift_id = ? AND status = 'paid' ORDER BY paid_seq DESC LIMIT ?").all(shiftId, limit).map(toCharge),
    /** Cobros pagados de un dueño en un rango UTC, con nombres para reportes. */
    paidInRange: (ownerId, from, to) =>
      db.prepare(
        `SELECT c.id, c.amount_cents, c.paid_at, c.unit_id, u.label AS unit_label, c.driver_id, d.name AS driver_name
           FROM charges c JOIN units u ON u.id = c.unit_id LEFT JOIN users d ON d.id = c.driver_id
          WHERE c.owner_id = ? AND c.status = 'paid' AND c.paid_at >= ? AND c.paid_at < ?
          ORDER BY c.paid_at DESC`,
      ).all(ownerId, from, to),
  };
}
