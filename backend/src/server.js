import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import { openDatabase } from "./db/index.js";

const config = loadConfig();

let db;
try {
  db = await openDatabase({ url: config.database.url, ssl: config.database.ssl, poolMax: config.database.poolMax });
} catch (err) {
  console.error("No se pudo conectar o migrar la base de datos:", err.message);
  process.exit(1);
}

const server = createApp({ config, db }).listen(config.port, () =>
  console.log(`ABORDO API en :${config.port} (pey: ${config.pey.mode})`),
);

let closing = false;
const shutdown = (signal) => {
  if (closing) return;
  closing = true;
  console.log(`${signal}: cerrando…`);
  setTimeout(() => process.exit(1), 10_000).unref(); // por si algo se queda colgado
  server.close(async () => {
    await db.close().catch(() => {});
    process.exit(0);
  });
  server.closeIdleConnections(); // conexiones keep-alive ociosas no deben retrasar el apagado
};
process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
