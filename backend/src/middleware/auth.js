import { forbidden, unauthorized } from "../lib/errors.js";

/** Exige un token válido y deja el usuario en req.user. */
export const authenticate = (auth) => (req, _res, next) => {
  const token = /^Bearer (.+)$/.exec(req.headers.authorization ?? "")?.[1];
  const user = token && auth.verifyToken(token);
  if (!user) return next(unauthorized("Tu sesión terminó. Inicia sesión otra vez."));
  req.user = user;
  next();
};

export const requireRole = (role) => (req, _res, next) => (req.user.role === role ? next() : next(forbidden()));
