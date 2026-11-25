import express, { Router } from "express";
import { wrap } from "../lib/http.js";

/** Webhook de estatus de pey. Necesita el cuerpo CRUDO para verificar la firma. */
export function webhookRoutes({ pey, chargeService }) {
  const r = Router();
  r.post("/pey", express.raw({ type: "*/*", limit: "100kb" }), wrap(async (req, res) => {
    await chargeService.applyWebhook(pey.parseWebhook(req.body, req.headers["x-pey-signature"]));
    res.status(204).end();
  }));
  return r;
}
