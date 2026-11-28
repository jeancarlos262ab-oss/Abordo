import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { uniqueViolationOf } from "../db/errors.js";
import { badRequest, conflict, unauthorized } from "../lib/errors.js";
import { publicUser } from "../repositories/users.js";

const MAX_AVATAR_BYTES = 500 * 1024;
const MIME_BY_MAGIC = [
  ["image/jpeg", (b) => b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff],
  ["image/png", (b) => b.length > 8 && b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))],
  ["image/webp", (b) => b.length > 12 && b.toString("ascii", 0, 4) === "RIFF" && b.toString("ascii", 8, 12) === "WEBP"],
];

const LOGIN_TAKEN = "Ese usuario ya existe. Prueba con otro.";

export function authService({ users, config }) {
  const sign = (u) => jwt.sign({ sub: u.id, role: u.role }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
  const session = (u) => ({ token: sign(u), user: publicUser(u) });
  const hash = (secret) => bcrypt.hash(secret, config.isProd ? 12 : 4);

  async function register(role, { name, login, secret }) {
    if (await users.findByLogin(login)) throw conflict(LOGIN_TAKEN);
    const secretHash = await hash(secret);
    try {
      return session(await users.create({ role, name, login, secretHash }));
    } catch (err) {
      if (uniqueViolationOf(err) === "uq_users_login") throw conflict(LOGIN_TAKEN); // dos registros simultáneos
      throw err;
    }
  }

  return {
    hash,
    registerOwner: (data) => register("owner", data),
    registerPassenger: (data) => register("passenger", data),
    async login({ login, secret, role }) {
      const u = await users.findByLogin(login);
      // Se compara siempre contra un hash para no revelar si el usuario existe por tiempo de respuesta.
      const ok = await bcrypt.compare(secret, u?.secretHash ?? "$2a$04$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvali");
      // Si el usuario es de otro rol (p. ej. un dueño entrando por la puerta del pasajero) se responde igual
      // que con una contraseña mala: no se revela que existe en otra entrada.
      if (!u || !ok || !u.active || u.role !== role) throw unauthorized("Usuario o contraseña incorrectos.");
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

    /** Foto de perfil como data URI (o null si no tiene). */
    async getAvatar(userId) {
      const a = await users.getAvatar(userId);
      return a ? `data:${a.mime};base64,${a.data.toString("base64")}` : null;
    },
    /** Guarda la foto. Se verifica el contenido real (no solo lo que diga el cliente) y el tamaño. */
    async setAvatar(userId, dataUri) {
      const m = /^data:(image\/(?:jpeg|png|webp));base64,([A-Za-z0-9+/]+={0,2})$/.exec(dataUri);
      if (!m) throw badRequest("La foto debe ser JPG, PNG o WebP.");
      const data = Buffer.from(m[2], "base64");
      if (data.length > MAX_AVATAR_BYTES) throw badRequest("La foto pesa demasiado. Elige una de menos de 500 KB.");
      const real = MIME_BY_MAGIC.find(([, ok]) => ok(data));
      if (!real || real[0] !== m[1]) throw badRequest("Ese archivo no es una imagen válida.");
      await users.setAvatar(userId, real[0], data);
    },
    clearAvatar: (userId) => users.clearAvatar(userId),
  };
}
