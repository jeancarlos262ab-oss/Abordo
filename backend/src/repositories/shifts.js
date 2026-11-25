import { iso, first } from "./_util.js";

const toShift = (r) => r && { id: r.id, driverId: r.driver_id, unitId: r.unit_id, startedAt: iso(r.started_at), endedAt: iso(r.ended_at) };

export function shiftsRepo(db) {
  const one = async (sql, params) => toShift(first(await db.query(sql, params)));
  return {
    findOpenByDriver: (driverId) => one("SELECT * FROM shifts WHERE driver_id = $1 AND ended_at IS NULL", [driverId]),
    findOpenByUnit: (unitId) => one("SELECT * FROM shifts WHERE unit_id = $1 AND ended_at IS NULL", [unitId]),
    start: (driverId, unitId) => one("INSERT INTO shifts (driver_id, unit_id) VALUES ($1, $2) RETURNING *", [driverId, unitId]),
    end: (id) => one("UPDATE shifts SET ended_at = now() WHERE id = $1 RETURNING *", [id]),
  };
}
