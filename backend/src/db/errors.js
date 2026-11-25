/** Si `err` es una violación de UNIQUE de Postgres (23505) devuelve el nombre de la restricción; si no, null. */
export const uniqueViolationOf = (err) => (err?.code === "23505" ? (err.constraint ?? "") : null);
