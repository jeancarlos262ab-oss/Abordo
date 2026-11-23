import { Router } from "express";
import rateLimit from "express-rate-limit";
import { z } from "zod";
import { notFound } from "../lib/errors.js";
import { phoneMx, validate, wrap } from "../lib/http.js";

const code = z.object({ code: z.string().regex(/^\d{4,8}$/, "Código de la unidad inválido") });

/** Endpoints del pasajero: no requieren cuenta. */
export function publicRoutes({ units, ownerService, chargeService }) {
  const r = Router();
  const limiter = rateLimit({ windowMs: 60_000, limit: 20, standardHeaders: true, legacyHeaders: false, skip: () => process.env.NODE_ENV === "test" });

  r.get("/units/:code", validate({ params: code }), wrap(async (req, res) => {
    const u = units.findByCode(req.valid.params.code);
    if (!u?.active) throw notFound("No encontramos esa unidad. Revisa el número.");
    res.json({ code: u.code, label: u.label, route: u.route, fareCents: u.fareCents, acceptsPayments: ownerService.canCharge(u.ownerId) });
  }));

  r.post(
    "/units/:code/charges",
    limiter,
    validate({ params: code, body: z.object({ payerPhone: phoneMx.optional() }) }),
    wrap(async (req, res) => res.status(201).json(await chargeService.create(req.valid.params.code, req.valid.body))),
  );

  r.get("/charges/:id", validate({ params: z.object({ id: z.string().uuid() }) }), wrap(async (req, res) => res.json(await chargeService.getPublic(req.valid.params.id))));
  return r;
}
