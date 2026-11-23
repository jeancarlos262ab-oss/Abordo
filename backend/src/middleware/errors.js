import { AppError } from "../lib/errors.js";

export const notFoundHandler = (_req, _res, next) => next(new AppError(404, "not_found", "Ruta no encontrada."));

// eslint-disable-next-line no-unused-vars
export const errorHandler = (log) => (err, _req, res, _next) => {
  if (err instanceof AppError) return res.status(err.status).json({ error: { code: err.code, message: err.message, details: err.details } });
  if (err.type === "entity.parse.failed") return res.status(400).json({ error: { code: "bad_json", message: "El cuerpo de la petición no es JSON válido." } });
  log.error(err);
  res.status(500).json({ error: { code: "internal", message: "Algo salió mal de nuestro lado. Intenta de nuevo." } });
};
