import { forbidden, unauthorized } from "../lib/errors.js";

/** Exige un token válido y deja el usuario en req.user. */
export const authenticate = (auth) => async (req, _res, next) => {
  try {
    const token = /^Bearer (.+)$/.exec(req.headers.authorization ?? "")?.[1];
    const user = token && (await auth.verifyToken(token));
    if (!user) return next(unauthorized("Tu sesión terminó. Inicia sesión otra vez."));
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
};

export const requireRole = (role) => (req, _res, next) => (req.user.role === role ? next() : next(forbidden()));

/**
 * Autenticación opcional para endpoints públicos: si llega un token válido deja el usuario en req.user;
 * sin token, o con uno vencido, la petición sigue como anónima (pagar un pasaje no exige cuenta).
 */
export const optionalAuthenticate = (auth) => async (req, _res, next) => {
  try {
    const token = /^Bearer (.+)$/.exec(req.headers.authorization ?? "")?.[1];
    const user = token && (await auth.verifyToken(token));
    if (user) req.user = user;
    next();
  } catch (err) {
    next(err);
  }
};
