import { first } from "./_util.js";

const toUser = (r) => r && { id: r.id, role: r.role, ownerId: r.owner_id, name: r.name, login: r.login, active: r.active, secretHash: r.secret_hash };
export const publicUser = ({ id, role, ownerId, name, login, active }) => ({ id, role, ownerId: ownerId ?? id, name, login, active });

export function usersRepo(db) {
  const one = async (sql, params) => toUser(first(await db.query(sql, params)));
  return {
    findById: (id) => one("SELECT * FROM users WHERE id = $1", [id]),
    findByLogin: (login) => one("SELECT * FROM users WHERE lower(login) = lower($1)", [login]),
    create: ({ role, ownerId = null, name, login, secretHash }) =>
      one("INSERT INTO users (role, owner_id, name, login, secret_hash) VALUES ($1,$2,$3,$4,$5) RETURNING *", [role, ownerId, name, login, secretHash]),
    async listDrivers(ownerId) {
      const { rows } = await db.query("SELECT * FROM users WHERE owner_id = $1 AND role = 'driver' ORDER BY active DESC, name", [ownerId]);
      return rows.map(toUser);
    },
    async getAvatar(userId) {
      const r = first(await db.query("SELECT mime, data FROM user_avatars WHERE user_id = $1", [userId]));
      return r && { mime: r.mime, data: Buffer.from(r.data) };
    },
    async setAvatar(userId, mime, data) {
      await db.query(
        `INSERT INTO user_avatars (user_id, mime, data) VALUES ($1,$2,$3)
         ON CONFLICT (user_id) DO UPDATE SET mime = EXCLUDED.mime, data = EXCLUDED.data, updated_at = now()`,
        [userId, mime, data],
      );
    },
    async clearAvatar(userId) {
      await db.query("DELETE FROM user_avatars WHERE user_id = $1", [userId]);
    },
    findDriver: (ownerId, id) => one("SELECT * FROM users WHERE id = $1 AND owner_id = $2 AND role = 'driver'", [id, ownerId]),
    update: (id, { name, active, secretHash }) =>
      one(
        "UPDATE users SET name = COALESCE($1, name), active = COALESCE($2, active), secret_hash = COALESCE($3, secret_hash) WHERE id = $4 RETURNING *",
        [name ?? null, active ?? null, secretHash ?? null, id],
      ),
  };
}
