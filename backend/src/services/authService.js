import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { conflict, unauthorized } from "../lib/errors.js";
import { publicUser } from "../repositories/users.js";

export function authService({ users, config }) {
  const sign = (u) => jwt.sign({ sub: u.id, role: u.role }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
  const session = (u) => ({ token: sign(u), user: publicUser(u) });
  const hash = (secret) => bcrypt.hash(secret, config.isProd ? 12 : 4);

  return {
    hash,
    async registerOwner({ name, login, secret }) {
      if (users.findByLogin(login)) throw conflict("Ese usuario ya existe. Prueba con otro.");
      return session(users.create({ role: "owner", name, login, secretHash: await hash(secret) }));
    },
    async login({ login, secret }) {
      const u = users.findByLogin(login);
      // Se compara siempre contra un hash para no revelar si el usuario existe por tiempo de respuesta.
      const ok = await bcrypt.compare(secret, u?.secretHash ?? "$2a$04$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvali");
      if (!u || !ok || !u.active) throw unauthorized("Usuario o contraseña incorrectos.");
      return session(u);
    },
    verifyToken(token) {
      try {
        const p = jwt.verify(token, config.jwtSecret);
        const u = users.findById(p.sub);
        return u?.active ? u : null;
      } catch {
        return null;
      }
    },
    me: (user) => publicUser(user),
  };
}
