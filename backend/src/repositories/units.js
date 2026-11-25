import { randomInt } from "node:crypto";
import { uniqueViolationOf } from "../db/errors.js";
import { first } from "./_util.js";

const toUnit = (r) => r && { id: r.id, ownerId: r.owner_id, code: r.code, label: r.label, route: r.route, fareCents: r.fare_cents, active: r.active };
const newCode = () => String(randomInt(100_000, 1_000_000)); // 6 dígitos, fácil de teclear

export function unitsRepo(db) {
  const one = async (sql, params) => toUnit(first(await db.query(sql, params)));
  return {
    findById: (id) => one("SELECT * FROM units WHERE id = $1", [id]),
    findByCode: (code) => one("SELECT * FROM units WHERE code = $1", [code]),
    findOwned: (ownerId, id) => one("SELECT * FROM units WHERE id = $1 AND owner_id = $2", [id, ownerId]),
    async list(ownerId, { onlyActive = false } = {}) {
      const { rows } = await db.query(`SELECT * FROM units WHERE owner_id = $1 ${onlyActive ? "AND active" : ""} ORDER BY active DESC, label`, [ownerId]);
      return rows.map(toUnit);
    },
    /** El código se elige al azar y la restricción UNIQUE decide: si choca, se reintenta (sin carreras). */
    async create(ownerId, { label, route, fareCents }) {
      for (let attempt = 0; attempt < 10; attempt++) {
        try {
          return await one("INSERT INTO units (owner_id, code, label, route, fare_cents) VALUES ($1,$2,$3,$4,$5) RETURNING *", [ownerId, newCode(), label, route, fareCents]);
        } catch (err) {
          if (uniqueViolationOf(err) !== "uq_units_code") throw err;
        }
      }
      throw new Error("No se pudo generar un código de unidad único.");
    },
    update: (id, { label, route, fareCents, active }) =>
      one(
        "UPDATE units SET label = COALESCE($1, label), route = COALESCE($2, route), fare_cents = COALESCE($3, fare_cents), active = COALESCE($4, active) WHERE id = $5 RETURNING *",
        [label ?? null, route ?? null, fareCents ?? null, active ?? null, id],
      ),
  };
}
