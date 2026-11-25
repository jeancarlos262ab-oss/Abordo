import pg from "pg";
import { MIGRATIONS } from "./migrations.js";

// COUNT/SUM llegan como int8 (texto por defecto en `pg`); los importes son centavos enteros, caben de sobra en Number.
pg.types.setTypeParser(20, (v) => Number(v));

const MIGRATION_LOCK = 727_001; // lock de asesor: una sola instancia migra a la vez

/**
 * Interfaz mínima que usa el resto del backend (así las pruebas pueden usar otro motor de Postgres):
 *   query(text, params) → { rows, rowCount }     exec(sql)  → varias sentencias, sin parámetros
 *   tx(fn)              → BEGIN/COMMIT/ROLLBACK; `fn` recibe { query, exec } ligados a UNA conexión
 *   close()
 */
export function createPgDatabase({ url, ssl, max = 10, log = console, options }) {
  const pool = new pg.Pool({
    connectionString: url,
    ssl,
    max,
    options,
    keepAlive: true,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 15_000, // Neon puede tardar unos segundos en "despertar" si estaba en reposo
  });
  // Neon/Render cierran conexiones inactivas; sin este handler un 'error' en un cliente ocioso tumbaría el proceso.
  pool.on("error", (err) => log.error("[db] error en una conexión inactiva (se descarta):", err.message));

  const bind = (c) => ({ query: (text, params) => c.query(text, params), exec: (sql) => c.query(sql) });
  return {
    ...bind(pool),
    async tx(fn) {
      const client = await pool.connect();
      let broken = false;
      try {
        await client.query("BEGIN");
        const result = await fn(bind(client));
        await client.query("COMMIT");
        return result;
      } catch (err) {
        try { await client.query("ROLLBACK"); } catch { broken = true; }
        throw err;
      } finally {
        client.release(broken); // si el ROLLBACK falló, la conexión se destruye en vez de reciclarse
      }
    },
    close: () => pool.end(),
  };
}

/**
 * SSL según el entorno. Neon y Render (URL externa) exigen TLS; en local y en la URL interna de Render no se usa.
 *   auto (default): si la URL trae `sslmode=` manda la URL; si no, TLS verificado salvo localhost / hosts internos sin punto.
 *   true: TLS verificado · no-verify: TLS sin verificar el certificado · false: sin TLS
 */
export function resolveSsl(url, mode = "auto") {
  if (mode === "false") return false;
  if (mode === "true") return { rejectUnauthorized: true };
  if (mode === "no-verify") return { rejectUnauthorized: false };
  const u = new URL(url);
  if (u.searchParams.has("sslmode")) return undefined;
  const local = ["localhost", "127.0.0.1", "::1", "[::1]"].includes(u.hostname) || !u.hostname.includes(".");
  return local ? false : { rejectUnauthorized: true };
}

/** Aplica las migraciones pendientes dentro de UNA transacción, serializada entre instancias. */
export async function migrate(db) {
  await db.tx(async (t) => {
    await t.query(`SELECT pg_advisory_xact_lock(${MIGRATION_LOCK})`); // xact-level: compatible con el pooler de Neon (PgBouncer)
    await t.exec("CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())");
    const { rows } = await t.query("SELECT COALESCE(MAX(version), 0) AS v FROM schema_migrations");
    const current = Number(rows[0].v);
    for (let v = current; v < MIGRATIONS.length; v++) {
      await t.exec(MIGRATIONS[v]);
      await t.query("INSERT INTO schema_migrations (version) VALUES ($1)", [v + 1]);
    }
  });
}

export async function openDatabase({ url, ssl = "auto", poolMax = 10, log = console }) {
  const db = createPgDatabase({ url, ssl: resolveSsl(url, ssl), max: poolMax, log });
  try {
    await migrate(db);
  } catch (err) {
    await db.close().catch(() => {});
    throw err;
  }
  return db;
}
