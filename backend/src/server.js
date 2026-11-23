import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import { openDatabase } from "./db/index.js";

const config = loadConfig();
const db = openDatabase(config.databasePath);
const server = createApp({ config, db }).listen(config.port, () =>
  console.log(`ABORDO API en :${config.port} (pey: ${config.pey.mode})`),
);

const shutdown = () => server.close(() => { db.close(); process.exit(0); });
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
