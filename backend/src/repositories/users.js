import { nowIso } from "../lib/time.js";

const toUser = (r) => r && { id: r.id, role: r.role, ownerId: r.owner_id, name: r.name, login: r.login, active: !!r.active, secretHash: r.secret_hash };
export const publicUser = ({ id, role, ownerId, name, login, active }) => ({ id, role, ownerId: ownerId ?? id, name, login, active });

export function usersRepo(db) {
  return {
    findById: (id) => toUser(db.prepare("SELECT * FROM users WHERE id = ?").get(id)),
    findByLogin: (login) => toUser(db.prepare("SELECT * FROM users WHERE login = ?").get(login)),
    create({ role, ownerId = null, name, login, secretHash }) {
      const { lastInsertRowid } = db
        .prepare("INSERT INTO users (role, owner_id, name, login, secret_hash, created_at) VALUES (?,?,?,?,?,?)")
        .run(role, ownerId, name, login, secretHash, nowIso());
      return this.findById(Number(lastInsertRowid));
    },
    listDrivers: (ownerId) =>
      db.prepare("SELECT * FROM users WHERE owner_id = ? AND role = 'driver' ORDER BY active DESC, name").all(ownerId).map(toUser),
    findDriver: (ownerId, id) => toUser(db.prepare("SELECT * FROM users WHERE id = ? AND owner_id = ? AND role = 'driver'").get(id, ownerId)),
    update(id, { name, active, secretHash }) {
      db.prepare("UPDATE users SET name = COALESCE(?, name), active = COALESCE(?, active), secret_hash = COALESCE(?, secret_hash) WHERE id = ?")
        .run(name ?? null, active === undefined ? null : +active, secretHash ?? null, id);
      return this.findById(id);
    },
  };
}
