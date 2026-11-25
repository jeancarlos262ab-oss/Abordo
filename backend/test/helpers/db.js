import { randomBytes } from "node:crypto";
import { PGlite } from "@electric-sql/pglite";
import { createPgDatabase, migrate, resolveSsl } from "../../src/db/index.js";

/**
 * Base de datos para pruebas, con la misma interfaz que usa la app.
 *  - Por defecto: PGlite (Postgres real compilado a WASM, en memoria; no hay que instalar nada).
 *  - Con TEST_DATABASE_URL: un Postgres real, en un esquema temporal propio que se borra al cerrar
 *    (nunca toca tus tablas).
 */
export async function createTestDatabase() {
  const url = process.env.TEST_DATABASE_URL;
  return url ? realPostgres(url) : inMemory();
}

async function inMemory() {
  const lite = new PGlite();
  await lite.waitReady;
  const bind = (c) => ({
    query: async (text, params) => {
      const r = await c.query(text, params);
      return { rows: r.rows, rowCount: r.affectedRows ?? r.rows.length };
    },
    exec: async (sql) => void (await c.exec(sql)),
  });
  const db = { ...bind(lite), tx: (fn) => lite.transaction((t) => fn(bind(t))), close: () => lite.close() };
  await migrate(db);
  return db;
}

async function realPostgres(url) {
  const ssl = resolveSsl(url);
  const schema = `test_${randomBytes(4).toString("hex")}`;
  const admin = createPgDatabase({ url, ssl, max: 1 });
  await admin.exec(`CREATE SCHEMA ${schema}`);
  const db = createPgDatabase({ url, ssl, max: 5, options: `-c search_path=${schema}` });
  await migrate(db);
  const close = db.close;
  db.close = async () => {
    await close();
    await admin.exec(`DROP SCHEMA ${schema} CASCADE`);
    await admin.close();
  };
  return db;
}
