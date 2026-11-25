/** Postgres devuelve TIMESTAMPTZ como Date; la API siempre ha expuesto ISO-8601 UTC (string). */
export const iso = (d) => (d instanceof Date ? d.toISOString() : (d ?? null));

/** Primera fila (o undefined) de un resultado de `db.query`. */
export const first = (result) => result.rows[0];
