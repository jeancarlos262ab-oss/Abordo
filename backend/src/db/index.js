import Database from "better-sqlite3";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";

const MIGRATIONS = [
  `
  CREATE TABLE users (
    id            INTEGER PRIMARY KEY,
    role          TEXT NOT NULL CHECK (role IN ('owner','driver')),
    owner_id      INTEGER REFERENCES users(id),      -- NULL para dueños
    name          TEXT NOT NULL,
    login         TEXT NOT NULL UNIQUE COLLATE NOCASE,
    secret_hash   TEXT NOT NULL,
    active        INTEGER NOT NULL DEFAULT 1,
    created_at    TEXT NOT NULL
  );
  CREATE TABLE owner_settings (
    owner_id        INTEGER PRIMARY KEY REFERENCES users(id),
    business_name   TEXT NOT NULL DEFAULT '',
    clabe           TEXT NOT NULL DEFAULT '',
    pey_api_key_enc TEXT,
    pey_secret_enc  TEXT,
    pey_key_hint    TEXT NOT NULL DEFAULT ''
  );
  CREATE TABLE units (
    id          INTEGER PRIMARY KEY,
    owner_id    INTEGER NOT NULL REFERENCES users(id),
    code        TEXT NOT NULL UNIQUE,               -- código público (QR fijo)
    label       TEXT NOT NULL,                      -- "Unidad 14"
    route       TEXT NOT NULL,                      -- "Ruta 52"
    fare_cents  INTEGER NOT NULL,
    active      INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL
  );
  CREATE INDEX idx_units_owner ON units(owner_id);
  CREATE TABLE shifts (
    id         INTEGER PRIMARY KEY,
    driver_id  INTEGER NOT NULL REFERENCES users(id),
    unit_id    INTEGER NOT NULL REFERENCES units(id),
    started_at TEXT NOT NULL,
    ended_at   TEXT
  );
  CREATE UNIQUE INDEX uq_open_shift_driver ON shifts(driver_id) WHERE ended_at IS NULL;
  CREATE UNIQUE INDEX uq_open_shift_unit   ON shifts(unit_id)   WHERE ended_at IS NULL;
  CREATE TABLE charges (
    id           TEXT PRIMARY KEY,                  -- UUID impredecible
    owner_id     INTEGER NOT NULL REFERENCES users(id),
    unit_id      INTEGER NOT NULL REFERENCES units(id),
    shift_id     INTEGER REFERENCES shifts(id),
    driver_id    INTEGER REFERENCES users(id),
    amount_cents INTEGER NOT NULL,
    status       TEXT NOT NULL CHECK (status IN ('pending','paid','failed','expired')),
    pey_ref      TEXT,
    qr_payload   TEXT,
    pay_link     TEXT,
    created_at   TEXT NOT NULL,
    expires_at   TEXT NOT NULL,
    paid_at      TEXT,
    paid_seq     INTEGER
  );
  CREATE INDEX idx_charges_paid ON charges(owner_id, paid_at) WHERE status = 'paid';
  CREATE INDEX idx_charges_shift_seq ON charges(shift_id, paid_seq);
  CREATE UNIQUE INDEX uq_charges_pey_ref ON charges(pey_ref) WHERE pey_ref IS NOT NULL;
  `,
];

export function openDatabase(path) {
  if (path !== ":memory:") mkdirSync(dirname(path), { recursive: true });
  const db = new Database(path);
  db.pragma("journal_mode = WAL");
  db.pragma("foreign_keys = ON");
  const version = db.pragma("user_version", { simple: true });
  MIGRATIONS.slice(version).forEach((sql, i) => {
    db.transaction(() => {
      db.exec(sql);
      db.pragma(`user_version = ${version + i + 1}`);
    })();
  });
  return db;
}
