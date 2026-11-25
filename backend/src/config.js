import { randomBytes } from "node:crypto";
import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().default(3000),
  PUBLIC_BASE_URL: z.string().url().default("https://abordo.example.mx"),
  CORS_ORIGIN: z.string().default("*"),
  JWT_SECRET: z.string().min(16).optional(),
  JWT_EXPIRES_IN: z.string().default("7d"),
  ENCRYPTION_KEY: z.string().regex(/^[0-9a-fA-F]{64}$/, "ENCRYPTION_KEY debe ser hex de 64 caracteres").optional().or(z.literal("")),
  DATABASE_URL: z.string().regex(/^postgres(ql)?:\/\//, "DATABASE_URL debe empezar con postgres:// o postgresql://").optional(),
  DATABASE_SSL: z.enum(["auto", "true", "false", "no-verify"]).default("auto"),
  DATABASE_POOL_MAX: z.coerce.number().int().min(1).max(100).default(10),
  PEY_MODE: z.enum(["mock", "live"]).default("mock"),
  PEY_API_BASE_URL: z.string().default("https://api.pey.example"),
  PEY_WEBHOOK_SECRET: z.string().default(""),
  PEY_MOCK_PAY_DELAY_SECONDS: z.coerce.number().default(6),
  CHARGE_TTL_SECONDS: z.coerce.number().int().default(300),
  DEFAULT_FARE_CENTS: z.coerce.number().int().default(1200),
});

export function loadConfig(env = process.env) {
  const e = schema.parse(env);
  const prod = e.NODE_ENV === "production";
  if (prod && (!e.JWT_SECRET || !e.ENCRYPTION_KEY)) {
    throw new Error("En producción JWT_SECRET y ENCRYPTION_KEY son obligatorios.");
  }
  if (prod && !e.DATABASE_URL) {
    throw new Error("En producción DATABASE_URL es obligatorio.");
  }
  if (prod && e.PEY_MODE === "live" && !e.PEY_WEBHOOK_SECRET) {
    throw new Error("PEY_WEBHOOK_SECRET es obligatorio con PEY_MODE=live.");
  }
  // En desarrollo se generan claves efímeras para no bloquear el arranque.
  return Object.freeze({
    env: e.NODE_ENV,
    isProd: prod,
    port: e.PORT,
    publicBaseUrl: e.PUBLIC_BASE_URL.replace(/\/$/, ""),
    corsOrigin: e.CORS_ORIGIN,
    jwtSecret: e.JWT_SECRET ?? randomBytes(32).toString("hex"),
    jwtExpiresIn: e.JWT_EXPIRES_IN,
    encryptionKey: Buffer.from(e.ENCRYPTION_KEY || randomBytes(32).toString("hex"), "hex"),
    database: {
      url: e.DATABASE_URL ?? "postgres://postgres:postgres@localhost:5432/abordo",
      ssl: e.DATABASE_SSL,
      poolMax: e.DATABASE_POOL_MAX,
    },
    pey: {
      mode: e.PEY_MODE,
      baseUrl: e.PEY_API_BASE_URL.replace(/\/$/, ""),
      webhookSecret: e.PEY_WEBHOOK_SECRET,
      mockPayDelayMs: e.PEY_MOCK_PAY_DELAY_SECONDS * 1000,
    },
    chargeTtlMs: e.CHARGE_TTL_SECONDS * 1000,
    defaultFareCents: e.DEFAULT_FARE_CENTS,
  });
}
