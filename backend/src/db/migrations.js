/**
 * Migraciones versionadas. Regla de oro: NUNCA edites una migración ya publicada;
 * agrega una nueva al final del arreglo. La versión aplicada se guarda en `schema_migrations`.
 */
export const MIGRATIONS = [
  /* 1 · esquema inicial */
  `
  CREATE TABLE users (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role        TEXT NOT NULL CHECK (role IN ('owner','driver')),
    owner_id    INTEGER REFERENCES users(id),          -- NULL para dueños
    name        TEXT NOT NULL,
    login       TEXT NOT NULL,
    secret_hash TEXT NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  -- Login único sin distinguir mayúsculas (equivale al COLLATE NOCASE de SQLite, sin extensiones).
  CREATE UNIQUE INDEX uq_users_login ON users (lower(login));
  CREATE INDEX idx_users_owner ON users (owner_id);

  CREATE TABLE owner_settings (
    owner_id        INTEGER PRIMARY KEY REFERENCES users(id),
    business_name   TEXT NOT NULL DEFAULT '',
    clabe           TEXT NOT NULL DEFAULT '',
    pey_api_key_enc TEXT,
    pey_secret_enc  TEXT,
    pey_key_hint    TEXT NOT NULL DEFAULT ''
  );

  CREATE TABLE units (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id    INTEGER NOT NULL REFERENCES users(id),
    code        TEXT NOT NULL CONSTRAINT uq_units_code UNIQUE,   -- código público (QR fijo)
    label       TEXT NOT NULL,                                   -- "Unidad 14"
    route       TEXT NOT NULL,                                   -- "Ruta 52"
    fare_cents  INTEGER NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  CREATE INDEX idx_units_owner ON units (owner_id);

  CREATE TABLE shifts (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    driver_id  INTEGER NOT NULL REFERENCES users(id),
    unit_id    INTEGER NOT NULL REFERENCES units(id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at   TIMESTAMPTZ
  );
  -- Un turno abierto por chofer y por unidad (también protege contra carreras entre peticiones).
  CREATE UNIQUE INDEX uq_open_shift_driver ON shifts (driver_id) WHERE ended_at IS NULL;
  CREATE UNIQUE INDEX uq_open_shift_unit   ON shifts (unit_id)   WHERE ended_at IS NULL;

  CREATE TABLE charges (
    id           UUID PRIMARY KEY,                  -- UUID impredecible
    owner_id     INTEGER NOT NULL REFERENCES users(id),
    unit_id      INTEGER NOT NULL REFERENCES units(id),
    shift_id     INTEGER REFERENCES shifts(id),
    driver_id    INTEGER REFERENCES users(id),
    amount_cents INTEGER NOT NULL,
    status       TEXT NOT NULL CHECK (status IN ('pending','paid','failed','expired')),
    pey_ref      TEXT,
    qr_payload   TEXT,
    pay_link     TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ NOT NULL,
    paid_at      TIMESTAMPTZ,
    paid_seq     INTEGER
  );
  CREATE INDEX idx_charges_paid       ON charges (owner_id, paid_at) WHERE status = 'paid';
  CREATE INDEX idx_charges_shift_seq  ON charges (shift_id, paid_seq);
  CREATE INDEX idx_charges_paid_seq   ON charges (paid_seq) WHERE paid_seq IS NOT NULL;
  CREATE UNIQUE INDEX uq_charges_pey_ref ON charges (pey_ref) WHERE pey_ref IS NOT NULL;
  `,

  /* 2 · pasajeros con cuenta: rol, cuenta vinculada para CoDi y cobros atribuidos al pasajero */
  `
  ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
  ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('owner','driver','passenger'));

  CREATE TABLE passenger_accounts (
    passenger_id INTEGER PRIMARY KEY REFERENCES users(id),
    holder       TEXT NOT NULL,
    phone        TEXT NOT NULL,                        -- celular (10 dígitos) registrado en su banco para CoDi
    bank         TEXT NOT NULL,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  ALTER TABLE charges ADD COLUMN passenger_id INTEGER REFERENCES users(id);   -- NULL: pagó sin cuenta
  CREATE INDEX idx_charges_passenger ON charges (passenger_id, created_at DESC) WHERE passenger_id IS NOT NULL;
  `,

  /* 3 · foto de perfil: una por usuario, guardada en la base (JPEG, PNG o WebP de hasta 500 KB) */
  `
  CREATE TABLE user_avatars (
    user_id    INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    mime       TEXT NOT NULL CHECK (mime IN ('image/jpeg','image/png','image/webp')),
    data       BYTEA NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  `,
];
