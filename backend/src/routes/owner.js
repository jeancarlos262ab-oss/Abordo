import { Router } from "express";
import { z } from "zod";
import { INT4_MAX, dateStr, pesosCents, validate, wrap } from "../lib/http.js";
import { todayMx } from "../lib/time.js";

const id = z.object({ id: z.coerce.number().int().positive().max(INT4_MAX) });
const unitFields = { label: z.string().trim().min(1).max(40), route: z.string().trim().min(1).max(40), fareCents: pesosCents };
const driverFields = {
  name: z.string().trim().min(2).max(80),
  pin: z.string().regex(/^\d{4,6}$/, "El PIN debe tener de 4 a 6 números"),
};

export function ownerRoutes({ ownerService, reportService, config }) {
  const r = Router();
  const owner = (req) => req.user.id;

  r.get("/settings", wrap(async (req, res) => res.json(await ownerService.settingsView(owner(req)))));
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
    wrap(async (req, res) => res.json(await ownerService.saveSettings(owner(req), req.valid.body))),
  );

  r.get("/units", wrap(async (req, res) => res.json({ units: await ownerService.listUnits(owner(req)) })));
  r.post("/units", validate({ body: z.object({ ...unitFields, fareCents: unitFields.fareCents.default(config.defaultFareCents) }) }), wrap(async (req, res) =>
    res.status(201).json(await ownerService.createUnit(owner(req), req.valid.body)),
  ));
  r.patch("/units/:id", validate({ params: id, body: z.object({ ...unitFields, active: z.boolean() }).partial() }), wrap(async (req, res) =>
    res.json(await ownerService.updateUnit(owner(req), req.valid.params.id, req.valid.body)),
  ));

  r.get("/drivers", wrap(async (req, res) => res.json({ drivers: await ownerService.listDrivers(owner(req)) })));
  r.post(
    "/drivers",
    validate({ body: z.object({ ...driverFields, login: z.string().trim().min(3).max(40).regex(/^[\w.@-]+$/, "Usa letras, números, punto o guion") }) }),
    wrap(async (req, res) => res.status(201).json(await ownerService.createDriver(owner(req), req.valid.body))),
  );
  r.patch("/drivers/:id", validate({ params: id, body: z.object({ ...driverFields, active: z.boolean() }).partial() }), wrap(async (req, res) =>
    res.json(await ownerService.updateDriver(owner(req), req.valid.params.id, req.valid.body)),
  ));

  r.get("/reports/summary", validate({ query: z.object({ date: dateStr.default(() => todayMx()) }) }), wrap(async (req, res) =>
    res.json(await reportService.summary(owner(req), req.valid.query.date)),
  ));
  r.get(
    "/charges",
    validate({
      query: z.object({
        date: dateStr.default(() => todayMx()),
        unitId: z.coerce.number().int().min(-INT4_MAX).max(INT4_MAX).optional(),
        driverId: z.coerce.number().int().min(-INT4_MAX).max(INT4_MAX).optional(),
        limit: z.coerce.number().int().min(1).max(100).default(50),
        offset: z.coerce.number().int().min(0).max(INT4_MAX).default(0),
      }),
    }),
    wrap(async (req, res) => {
      const { date, ...filters } = req.valid.query;
      res.json(await reportService.history(owner(req), date, filters));
    }),
  );
  return r;
}
