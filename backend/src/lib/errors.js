/** Error esperado de negocio: se serializa tal cual al cliente. */
export class AppError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}
export const badRequest = (msg, details) => new AppError(400, "bad_request", msg, details);
export const unauthorized = (msg = "Inicia sesión para continuar.") => new AppError(401, "unauthorized", msg);
export const forbidden = (msg = "No tienes permiso para esto.") => new AppError(403, "forbidden", msg);
export const notFound = (msg = "No encontramos lo que buscas.") => new AppError(404, "not_found", msg);
export const conflict = (msg) => new AppError(409, "conflict", msg);
