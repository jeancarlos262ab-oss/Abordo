import { Router } from "express";
import { z } from "zod";
import { INT4_MAX, validate, wrap } from "../lib/http.js";

export function driverRoutes({ units, shiftService }) {
  const r = Router();
  r.get("/units", wrap(async (req, res) => {
    const list = await units.list(req.user.ownerId, { onlyActive: true });
    res.json({ units: list.map(({ id, label, route, fareCents }) => ({ id, label, route, fareCents })) });
  }));
  r.get("/shift", wrap(async (req, res) => res.json(await shiftService.current(req.user))));
  r.post("/shift", validate({ body: z.object({ unitId: z.number().int().max(INT4_MAX) }) }), wrap(async (req, res) => res.status(201).json(await shiftService.start(req.user, req.valid.body.unitId))));
  r.delete("/shift", wrap(async (req, res) => res.json(await shiftService.end(req.user))));
  r.get("/shift/payments", validate({ query: z.object({ afterSeq: z.coerce.number().int().min(0).max(INT4_MAX).default(0) }) }), wrap(async (req, res) =>
    res.json(await shiftService.newPayments(req.user, req.valid.query.afterSeq)),
  ));
  return r;
}
