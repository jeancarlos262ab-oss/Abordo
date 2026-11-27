import { Router } from "express";
import rateLimit from "express-rate-limit";
import { z } from "zod";
import { notFound } from "../lib/errors.js";
import { phoneMx, validate, wrap } from "../lib/http.js";

const code = z.object({ code: z.string().regex(/^\d{4,8}$/, "Código de la unidad inválido") });

/** Endpoints del pasajero: no requieren cuenta. */
export function publicRoutes({ units, ownerService, chargeService, optionalAuth }) {
  const r = Router();
  const limiter = rateLimit({ windowMs: 60_000, limit: 20, standardHeaders: true, legacyHeaders: false, skip: () => process.env.NODE_ENV === "test" });

  r.get("/units/:code", validate({ params: code }), wrap(async (req, res) => {
    const u = await units.findByCode(req.valid.params.code);
    if (!u?.active) throw notFound("No encontramos esa unidad. Revisa el número.");
    res.json({ code: u.code, label: u.label, route: u.route, fareCents: u.fareCents, acceptsPayments: await ownerService.canCharge(u.ownerId) });
  }));

  r.post(
    "/units/:code/charges",
    limiter,
    optionalAuth,
    validate({ params: code, body: z.object({ payerPhone: phoneMx.optional() }) }),
    wrap(async (req, res) => {
      // Con sesión de pasajero el cobro queda en su historial; cualquier otro rol (o nadie) paga como anónimo.
      const passengerId = req.user?.role === "passenger" ? req.user.id : undefined;
      res.status(201).json(await chargeService.create(req.valid.params.code, { ...req.valid.body, passengerId }));
    }),
  );

  r.get("/charges/:id", validate({ params: z.object({ id: z.string().uuid() }) }), wrap(async (req, res) => res.json(await chargeService.getPublic(req.valid.params.id))));
  return r;
}
