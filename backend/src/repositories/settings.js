import { first } from "./_util.js";

const toSettings = (r) => ({
  ownerId: r.owner_id,
  businessName: r.business_name,
  clabe: r.clabe,
  peyKeyEnc: r.pey_api_key_enc,
  peySecretEnc: r.pey_secret_enc,
  peyKeyHint: r.pey_key_hint,
});
const empty = (ownerId) => toSettings({ owner_id: ownerId, business_name: "", clabe: "", pey_api_key_enc: null, pey_secret_enc: null, pey_key_hint: "" });

export function settingsRepo(db) {
  return {
    /** Solo lectura: un dueño sin configuración devuelve valores vacíos (ya no se escribe en cada consulta). */
    async get(ownerId) {
      const r = first(await db.query("SELECT * FROM owner_settings WHERE owner_id = $1", [ownerId]));
      return r ? toSettings(r) : empty(ownerId);
    },
    save: (ownerId, { businessName, clabe, peyKeyEnc, peySecretEnc, peyKeyHint }) =>
      db.tx(async (t) => {
        await t.query("INSERT INTO owner_settings (owner_id) VALUES ($1) ON CONFLICT (owner_id) DO NOTHING", [ownerId]);
        const { rows } = await t.query(
          `UPDATE owner_settings SET
             business_name   = COALESCE($1, business_name),
             clabe           = COALESCE($2, clabe),
             pey_api_key_enc = COALESCE($3, pey_api_key_enc),
             pey_secret_enc  = COALESCE($4, pey_secret_enc),
             pey_key_hint    = COALESCE($5, pey_key_hint)
           WHERE owner_id = $6
           RETURNING *`,
          [businessName ?? null, clabe ?? null, peyKeyEnc ?? null, peySecretEnc ?? null, peyKeyHint ?? null, ownerId],
        );
        return toSettings(rows[0]);
      }),
  };
}
