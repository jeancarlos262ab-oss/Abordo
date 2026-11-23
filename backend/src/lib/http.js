import { z } from "zod";
import { badRequest } from "./errors.js";

/** Envuelve handlers async para que los errores lleguen al middleware de errores. */
export const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

/** Valida body / query / params con zod y deja los valores ya tipados en req.valid. */
export const validate = (schemas) => (req, _res, next) => {
  req.valid = {};
  for (const part of ["params", "query", "body"]) {
    if (!schemas[part]) continue;
    const r = schemas[part].safeParse(req[part]);
    if (!r.success) {
      return next(badRequest("Revisa los datos enviados.", r.error.issues.map((i) => ({ campo: i.path.join("."), mensaje: i.message }))));
    }
    req.valid[part] = r.data;
  }
  next();
};

export const dateStr = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Fecha con formato AAAA-MM-DD");
export const pesosCents = z.number().int().min(100).max(100_000);
export const phoneMx = z.string().regex(/^\d{10}$/, "Teléfono de 10 dígitos");
