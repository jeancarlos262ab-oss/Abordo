import { nowIso } from "../lib/time.js";

const toShift = (r) => r && { id: r.id, driverId: r.driver_id, unitId: r.unit_id, startedAt: r.started_at, endedAt: r.ended_at };

export function shiftsRepo(db) {
  return {
    findOpenByDriver: (driverId) => toShift(db.prepare("SELECT * FROM shifts WHERE driver_id = ? AND ended_at IS NULL").get(driverId)),
    findOpenByUnit: (unitId) => toShift(db.prepare("SELECT * FROM shifts WHERE unit_id = ? AND ended_at IS NULL").get(unitId)),
    start(driverId, unitId) {
      const { lastInsertRowid } = db.prepare("INSERT INTO shifts (driver_id, unit_id, started_at) VALUES (?,?,?)").run(driverId, unitId, nowIso());
      return toShift(db.prepare("SELECT * FROM shifts WHERE id = ?").get(lastInsertRowid));
    },
    end(id) {
      db.prepare("UPDATE shifts SET ended_at = ? WHERE id = ?").run(nowIso(), id);
      return toShift(db.prepare("SELECT * FROM shifts WHERE id = ?").get(id));
    },
  };
}
