import { Router } from "express";
import { z } from "zod";
import { dateStr, pesosCents, validate, wrap } from "../lib/http.js";
import { todayMx } from "../lib/time.js";

const id = z.object({ id: z.coerce.number().int().positive() });
const unitFields = { label: z.string().trim().min(1).max(40), route: z.string().trim().min(1).max(40), fareCents: pesosCents };
const driverFields = {
  name: z.string().trim().min(2).max(80),
  pin: z.string().regex(/^\d{4,6}$/, "El PIN debe tener de 4 a 6 números"),
};

export function ownerRoutes({ ownerService, reportService, config }) {
  const r = Router();
  const owner = (req) => req.user.id;

  r.get("/settings", (req, res) => res.json(ownerService.settingsView(owner(req))));
  r.put(
    "/settings",
    validate({
      body: z.object({
        businessName: z.string().trim().max(120).optional(),
        clabe: z.string().regex(/^\d{18}$/, "La CLABE tiene 18 dígitos").optional(),
        peyApiKey: z.string().trim().min(8).max(200).optional(),
        peyApiSecret: z.string().trim().min(8).max(200).optional(),
      }),
    }),
    (req, res) => res.json(ownerService.saveSettings(owner(req), req.valid.body)),
  );

  r.get("/units", (req, res) => res.json({ units: ownerService.listUnits(owner(req)) }));
  r.post("/units", validate({ body: z.object({ ...unitFields, fareCents: unitFields.fareCents.default(config.defaultFareCents) }) }), (req, res) =>
    res.status(201).json(ownerService.createUnit(owner(req), req.valid.body)),
  );
  r.patch("/units/:id", validate({ params: id, body: z.object({ ...unitFields, active: z.boolean() }).partial() }), (req, res) =>
    res.json(ownerService.updateUnit(owner(req), req.valid.params.id, req.valid.body)),
  );

  r.get("/drivers", (req, res) => res.json({ drivers: ownerService.listDrivers(owner(req)) }));
  r.post(
    "/drivers",
    validate({ body: z.object({ ...driverFields, login: z.string().trim().min(3).max(40).regex(/^[\w.@-]+$/, "Usa letras, números, punto o guion") }) }),
    wrap(async (req, res) => res.status(201).json(await ownerService.createDriver(owner(req), req.valid.body))),
  );
  r.patch("/drivers/:id", validate({ params: id, body: z.object({ ...driverFields, active: z.boolean() }).partial() }), wrap(async (req, res) =>
    res.json(await ownerService.updateDriver(owner(req), req.valid.params.id, req.valid.body)),
  ));

  r.get("/reports/summary", validate({ query: z.object({ date: dateStr.default(() => todayMx()) }) }), (req, res) =>
    res.json(reportService.summary(owner(req), req.valid.query.date)),
  );
  r.get(
    "/charges",
    validate({
      query: z.object({
        date: dateStr.default(() => todayMx()),
        unitId: z.coerce.number().int().optional(),
        driverId: z.coerce.number().int().optional(),
        limit: z.coerce.number().int().min(1).max(100).default(50),
        offset: z.coerce.number().int().min(0).default(0),
      }),
    }),
    (req, res) => {
      const { date, ...filters } = req.valid.query;
      res.json(reportService.history(owner(req), date, filters));
    },
  );
  return r;
}
