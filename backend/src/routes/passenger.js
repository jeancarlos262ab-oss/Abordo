import { Router } from "express";
import { z } from "zod";
import { phoneMx, validate, wrap } from "../lib/http.js";

const account = z.object({
  holder: z.string().trim().min(2).max(80),
  phone: phoneMx,
  bank: z.string().trim().min(2).max(40),
});

/** Cuenta del pasajero con sesión: perfil, celular/banco vinculado e historial de pagos. */
export function passengerRoutes({ passengerService }) {
  const r = Router();
  r.get("/me", wrap(async (req, res) => res.json(await passengerService.profile(req.user))));
  r.put("/account", validate({ body: account }), wrap(async (req, res) => res.json({ account: await passengerService.linkAccount(req.user, req.valid.body) })));
  r.delete("/account", wrap(async (req, res) => {
    await passengerService.unlinkAccount(req.user);
    res.status(204).end();
  }));
  r.get(
    "/payments",
    validate({ query: z.object({ limit: z.coerce.number().int().min(1).max(200).default(50) }) }),
    wrap(async (req, res) => res.json(await passengerService.payments(req.user, req.valid.query.limit))),
  );
  return r;
}
