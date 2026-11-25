import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { uniqueViolationOf } from "../db/errors.js";
import { conflict, unauthorized } from "../lib/errors.js";
import { publicUser } from "../repositories/users.js";

const LOGIN_TAKEN = "Ese usuario ya existe. Prueba con otro.";

export function authService({ users, config }) {
  const sign = (u) => jwt.sign({ sub: u.id, role: u.role }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
  const session = (u) => ({ token: sign(u), user: publicUser(u) });
  const hash = (secret) => bcrypt.hash(secret, config.isProd ? 12 : 4);

  return {
    hash,
    async registerOwner({ name, login, secret }) {
      if (await users.findByLogin(login)) throw conflict(LOGIN_TAKEN);
      const secretHash = await hash(secret);
      try {
        return session(await users.create({ role: "owner", name, login, secretHash }));
      } catch (err) {
        if (uniqueViolationOf(err) === "uq_users_login") throw conflict(LOGIN_TAKEN); // dos registros simultáneos
        throw err;
      }
    },
    async login({ login, secret }) {
      const u = await users.findByLogin(login);
      // Se compara siempre contra un hash para no revelar si el usuario existe por tiempo de respuesta.
      const ok = await bcrypt.compare(secret, u?.secretHash ?? "$2a$04$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvali");
      if (!u || !ok || !u.active) throw unauthorized("Usuario o contraseña incorrectos.");
      return session(u);
    },
    async verifyToken(token) {
      let payload;
      try {
        payload = jwt.verify(token, config.jwtSecret);
      } catch {
        return null;
      }
      // La consulta queda fuera del try: un fallo de base de datos es un 500, no una "sesión terminada".
      const u = await users.findById(payload.sub);
      return u?.active ? u : null;
    },
    me: (user) => publicUser(user),
  };
}
