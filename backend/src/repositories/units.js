import { randomInt } from "node:crypto";
import { nowIso } from "../lib/time.js";

const toUnit = (r) => r && { id: r.id, ownerId: r.owner_id, code: r.code, label: r.label, route: r.route, fareCents: r.fare_cents, active: !!r.active };

export function unitsRepo(db) {
  const newCode = () => {
    for (;;) {
      const code = String(randomInt(100_000, 1_000_000)); // 6 dígitos, fácil de teclear
      if (!db.prepare("SELECT 1 FROM units WHERE code = ?").get(code)) return code;
    }
  };
  return {
    findById: (id) => toUnit(db.prepare("SELECT * FROM units WHERE id = ?").get(id)),
    findByCode: (code) => toUnit(db.prepare("SELECT * FROM units WHERE code = ?").get(code)),
    findOwned: (ownerId, id) => toUnit(db.prepare("SELECT * FROM units WHERE id = ? AND owner_id = ?").get(id, ownerId)),
    list: (ownerId, { onlyActive = false } = {}) =>
      db.prepare(`SELECT * FROM units WHERE owner_id = ? ${onlyActive ? "AND active = 1" : ""} ORDER BY active DESC, label`).all(ownerId).map(toUnit),
    create(ownerId, { label, route, fareCents }) {
      const { lastInsertRowid } = db
        .prepare("INSERT INTO units (owner_id, code, label, route, fare_cents, created_at) VALUES (?,?,?,?,?,?)")
        .run(ownerId, newCode(), label, route, fareCents, nowIso());
      return this.findById(Number(lastInsertRowid));
    },
    update(id, { label, route, fareCents, active }) {
      db.prepare(
        "UPDATE units SET label = COALESCE(?, label), route = COALESCE(?, route), fare_cents = COALESCE(?, fare_cents), active = COALESCE(?, active) WHERE id = ?",
      ).run(label ?? null, route ?? null, fareCents ?? null, active === undefined ? null : +active, id);
      return this.findById(id);
    },
  };
}
