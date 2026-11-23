import { Router } from "express";
import { z } from "zod";
import { validate, wrap } from "../lib/http.js";

export function driverRoutes({ units, shiftService }) {
  const r = Router();
  r.get("/units", (req, res) => res.json({ units: units.list(req.user.ownerId, { onlyActive: true }).map(({ id, label, route, fareCents }) => ({ id, label, route, fareCents })) }));
  r.get("/shift", (req, res) => res.json(shiftService.current(req.user)));
  r.post("/shift", validate({ body: z.object({ unitId: z.number().int() }) }), wrap(async (req, res) => res.status(201).json(shiftService.start(req.user, req.valid.body.unitId))));
  r.delete("/shift", (req, res) => res.json(shiftService.end(req.user)));
  r.get("/shift/payments", validate({ query: z.object({ afterSeq: z.coerce.number().int().min(0).default(0) }) }), (req, res) =>
    res.json(shiftService.newPayments(req.user, req.valid.query.afterSeq)),
  );
  return r;
}
