import { Router } from "express";
import rateLimit from "express-rate-limit";
import { z } from "zod";
import { validate, wrap } from "../lib/http.js";

const credentials = z.object({ login: z.string().trim().min(3).max(60), secret: z.string().min(4).max(100) });

export function authRoutes({ authService, authenticate }) {
  const r = Router();
  const limiter = rateLimit({ windowMs: 15 * 60_000, limit: 30, standardHeaders: true, legacyHeaders: false, skip: () => process.env.NODE_ENV === "test" });

  r.post("/login", limiter, validate({ body: credentials }), wrap(async (req, res) => res.json(await authService.login(req.valid.body))));
  r.post(
    "/register-owner",
    limiter,
    validate({ body: credentials.extend({ name: z.string().trim().min(2).max(80), secret: z.string().min(8).max(100) }) }),
    wrap(async (req, res) => res.status(201).json(await authService.registerOwner(req.valid.body))),
  );
  r.get("/me", authenticate, (req, res) => res.json({ user: authService.me(req.user) }));
  return r;
}
