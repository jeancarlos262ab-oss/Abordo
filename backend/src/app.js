import cors from "cors";
import express from "express";
import helmet from "helmet";
import { createVault } from "./lib/crypto.js";
import { authenticate as authMiddleware, optionalAuthenticate, requireRole } from "./middleware/auth.js";
import { errorHandler, notFoundHandler } from "./middleware/errors.js";
import { createPeyClient } from "./pey/index.js";
import { chargesRepo } from "./repositories/charges.js";
import { passengersRepo } from "./repositories/passengers.js";
import { settingsRepo } from "./repositories/settings.js";
import { shiftsRepo } from "./repositories/shifts.js";
import { unitsRepo } from "./repositories/units.js";
import { usersRepo } from "./repositories/users.js";
import { authRoutes } from "./routes/auth.js";
import { driverRoutes } from "./routes/driver.js";
import { ownerRoutes } from "./routes/owner.js";
import { passengerRoutes } from "./routes/passenger.js";
import { publicRoutes } from "./routes/public.js";
import { webhookRoutes } from "./routes/webhooks.js";
import { authService } from "./services/authService.js";
import { chargeService } from "./services/chargeService.js";
import { ownerService } from "./services/ownerService.js";
import { passengerService } from "./services/passengerService.js";
import { reportService } from "./services/reportService.js";
import { shiftService } from "./services/shiftService.js";

/** Composición de dependencias: único lugar donde se "cablea" la app (facilita las pruebas). */
export function createApp({ config, db, log = console, pey = createPeyClient(config) }) {
  const repos = {
    users: usersRepo(db), units: unitsRepo(db), shifts: shiftsRepo(db),
    charges: chargesRepo(db), settings: settingsRepo(db), passengers: passengersRepo(db),
  };
  const vault = createVault(config.encryptionKey);
  const auth = authService({ users: repos.users, config });
  const owners = ownerService({ ...repos, vault, auth, config });
  const passengerSvc = passengerService(repos);
  const charges = chargeService({ ...repos, ownerService: owners, passengerService: passengerSvc, pey, config });
  const shifts = shiftService(repos);
  const reports = reportService(repos);
  const authenticate = authMiddleware(auth);

  const app = express();
  app.disable("x-powered-by");
  app.set("trust proxy", 1);
  app.use(helmet());
  app.use(cors({ origin: config.corsOrigin === "*" ? true : config.corsOrigin.split(",") }));

  app.get("/health", (_req, res) => res.json({ ok: true, peyMode: config.pey.mode }));
  app.use("/api/webhooks", webhookRoutes({ pey, chargeService: charges })); // antes de express.json: usa cuerpo crudo
  app.use("/api/auth/avatar", express.json({ limit: "1mb" })); // la foto de perfil es la única ruta con cuerpo grande
  app.use(express.json({ limit: "50kb" }));

  app.use("/api/auth", authRoutes({ authService: auth, authenticate }));
  app.use("/api/public", publicRoutes({ units: repos.units, ownerService: owners, chargeService: charges, optionalAuth: optionalAuthenticate(auth) }));
  app.use("/api/driver", authenticate, requireRole("driver"), driverRoutes({ units: repos.units, shiftService: shifts }));
  app.use("/api/passenger", authenticate, requireRole("passenger"), passengerRoutes({ passengerService: passengerSvc }));
  app.use("/api/owner", authenticate, requireRole("owner"), ownerRoutes({ ownerService: owners, reportService: reports, config }));

  app.use(notFoundHandler);
  app.use(errorHandler(log));
  return app;
}
