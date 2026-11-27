import { iso, first } from "./_util.js";

const PAID_SEQ_LOCK = 727_002; // serializa la asignación del consecutivo de pago

const toCharge = (r) =>
  r && {
    id: r.id, ownerId: r.owner_id, unitId: r.unit_id, shiftId: r.shift_id, driverId: r.driver_id, passengerId: r.passenger_id,
    amountCents: r.amount_cents, status: r.status, peyRef: r.pey_ref, qrPayload: r.qr_payload, payLink: r.pay_link,
    createdAt: iso(r.created_at), expiresAt: iso(r.expires_at), paidAt: iso(r.paid_at), paidSeq: r.paid_seq,
  };
const toReportRow = (r) => ({ ...r, paid_at: iso(r.paid_at) });

const REPORT_FROM = `
  FROM charges c JOIN units u ON u.id = c.unit_id LEFT JOIN users d ON d.id = c.driver_id
 WHERE c.owner_id = $1 AND c.status = 'paid' AND c.paid_at >= $2 AND c.paid_at < $3`;
const REPORT_COLS = "c.id, c.amount_cents, c.paid_at, c.unit_id, u.label AS unit_label, c.driver_id, d.name AS driver_name";
const ORDER = "ORDER BY c.paid_at DESC, c.paid_seq DESC";

export function chargesRepo(db) {
  const one = async (sql, params) => toCharge(first(await db.query(sql, params)));
  const many = async (sql, params) => (await db.query(sql, params)).rows.map(toCharge);
  const get = (id) => one("SELECT * FROM charges WHERE id = $1", [id]);

  return {
    findById: get,
    findByPeyRef: (ref) => one("SELECT * FROM charges WHERE pey_ref = $1", [ref]),
    insert: (c) =>
      one(
        `INSERT INTO charges (id, owner_id, unit_id, shift_id, driver_id, amount_cents, status, pey_ref, qr_payload, pay_link, expires_at, passenger_id)
         VALUES ($1,$2,$3,$4,$5,$6,'pending',$7,$8,$9,$10,$11) RETURNING *`,
        [c.id, c.ownerId, c.unitId, c.shiftId, c.driverId, c.amountCents, c.peyRef, c.qrPayload, c.payLink, c.expiresAt, c.passengerId ?? null],
      ),
    /**
     * Idempotente: solo la primera llamada cambia el estado y asigna el consecutivo de pago.
     * Con varias conexiones, MAX+1 podría repetirse (o publicarse fuera de orden) si dos pagos coinciden;
     * el lock transaccional los pone en fila y el consecutivo sale en el mismo orden en que se confirma cada pago.
     */
    async pay(id) {
      await db.tx(async (t) => {
        await t.query(`SELECT pg_advisory_xact_lock(${PAID_SEQ_LOCK})`);
        await t.query(
          `UPDATE charges SET status = 'paid', paid_at = now(), paid_seq = (SELECT COALESCE(MAX(paid_seq), 0) + 1 FROM charges)
            WHERE id = $1 AND status IN ('pending','expired')`,
          [id],
        );
      });
      return get(id);
    },
    async setStatus(id, status) {
      await db.query("UPDATE charges SET status = $1 WHERE id = $2 AND status = 'pending'", [status, id]);
      return get(id);
    },
    /** Cobros pagados de un turno con consecutivo mayor a `afterSeq` (para el aviso de voz). */
    paidInShiftAfter: (shiftId, afterSeq, limit = 50) =>
      many("SELECT * FROM charges WHERE shift_id = $1 AND status = 'paid' AND paid_seq > $2 ORDER BY paid_seq LIMIT $3", [shiftId, afterSeq, limit]),
    async shiftTotals(shiftId) {
      const r = first(await db.query("SELECT COUNT(*)::int AS count, COALESCE(SUM(amount_cents), 0)::int AS total FROM charges WHERE shift_id = $1 AND status = 'paid'", [shiftId]));
      return { count: r.count, total: r.total };
    },
    async latestSeq(shiftId) {
      return first(await db.query("SELECT COALESCE(MAX(paid_seq), 0)::int AS n FROM charges WHERE shift_id = $1", [shiftId])).n;
    },
    recentPaidInShift: (shiftId, limit = 8) =>
      many("SELECT * FROM charges WHERE shift_id = $1 AND status = 'paid' ORDER BY paid_seq DESC LIMIT $2", [shiftId, limit]),

    /**
     * Historial del pasajero, del más reciente al más antiguo. Un cobro pendiente cuyo plazo ya venció
     * se muestra como `expired` (nadie lo consultó, así que en la base sigue "pending").
     */
    async forPassenger(passengerId, limit) {
      const { rows } = await db.query(
        `SELECT c.id, c.amount_cents, c.created_at, u.label AS unit_label, u.route,
                CASE WHEN c.status = 'pending' AND c.expires_at < now() THEN 'expired' ELSE c.status END AS status
           FROM charges c JOIN units u ON u.id = c.unit_id
          WHERE c.passenger_id = $1 ORDER BY c.created_at DESC, c.id LIMIT $2`,
        [passengerId, limit],
      );
      return rows.map((r) => ({ id: r.id, status: r.status, amountCents: r.amount_cents, unitLabel: r.unit_label, route: r.route, createdAt: iso(r.created_at) }));
    },
    /** Total pagado por el pasajero en un rango UTC (el mes en curso). */
    async passengerPaidTotal(passengerId, from, to) {
      const r = first(await db.query(
        "SELECT COALESCE(SUM(amount_cents), 0)::int AS total FROM charges WHERE passenger_id = $1 AND status = 'paid' AND paid_at >= $2 AND paid_at < $3",
        [passengerId, from, to],
      ));
      return r.total;
    },

    /** Cobros pagados de un dueño en un rango UTC, con nombres para reportes. */
    async paidInRange(ownerId, from, to) {
      const { rows } = await db.query(`SELECT ${REPORT_COLS} ${REPORT_FROM} ${ORDER}`, [ownerId, from, to]);
      return rows.map(toReportRow);
    },
    /** Historial paginado EN la base de datos (antes se traía el día completo y se cortaba en memoria). */
    async historyInRange(ownerId, from, to, { unitId, driverId, limit, offset }) {
      const filters = " AND ($4::int IS NULL OR c.unit_id = $4) AND ($5::int IS NULL OR c.driver_id = $5)";
      const base = [ownerId, from, to, unitId || null, driverId || null];
      const [count, page] = await Promise.all([
        db.query(`SELECT COUNT(*)::int AS total ${REPORT_FROM} ${filters}`, base),
        db.query(`SELECT ${REPORT_COLS} ${REPORT_FROM} ${filters} ${ORDER} LIMIT $6 OFFSET $7`, [...base, limit, offset]),
      ]);
      return { total: first(count).total, rows: page.rows.map(toReportRow) };
    },
  };
}
