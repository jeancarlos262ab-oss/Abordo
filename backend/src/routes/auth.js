import { Router } from "express";
import rateLimit from "express-rate-limit";
import { z } from "zod";
import { validate, wrap } from "../lib/http.js";

const credentials = z.object({ login: z.string().trim().min(3).max(60), secret: z.string().min(4).max(100) });
// Cada entrada de la app (dueño, chofer, pasajero) solo deja pasar a sus propios usuarios.
const loginBody = credentials.extend({ role: z.enum(["owner", "driver", "passenger"]) });

export function authRoutes({ authService, authenticate }) {
  const r = Router();
  const limiter = rateLimit({ windowMs: 15 * 60_000, limit: 30, standardHeaders: true, legacyHeaders: false, skip: () => process.env.NODE_ENV === "test" });

  r.post("/login", limiter, validate({ body: loginBody }), wrap(async (req, res) => res.json(await authService.login(req.valid.body))));
  const registration = validate({ body: credentials.extend({ name: z.string().trim().min(2).max(80), secret: z.string().min(8).max(100) }) });
  r.post("/register-owner", limiter, registration, wrap(async (req, res) => res.status(201).json(await authService.registerOwner(req.valid.body))));
  r.post("/register-passenger", limiter, registration, wrap(async (req, res) => res.status(201).json(await authService.registerPassenger(req.valid.body))));
  // Foto de perfil (cualquier rol, la suya). Llega como data URI en JSON; el límite del cuerpo se sube
  // solo para esta ruta (el resto de la API conserva 50 kb).
  const avatarBody = z.object({ image: z.string().max(700_000) });
  r.get("/avatar", authenticate, wrap(async (req, res) => res.json({ avatar: await authService.getAvatar(req.user.id) })));
  r.put("/avatar", authenticate, validate({ body: avatarBody }), wrap(async (req, res) => {
    await authService.setAvatar(req.user.id, req.valid.body.image);
    res.json({ avatar: await authService.getAvatar(req.user.id) });
  }));
  r.delete("/avatar", authenticate, wrap(async (req, res) => {
    await authService.clearAvatar(req.user.id);
    res.status(204).end();
  }));
  r.get("/me", authenticate, (req, res) => res.json({ user: authService.me(req.user) }));
  return r;
}
