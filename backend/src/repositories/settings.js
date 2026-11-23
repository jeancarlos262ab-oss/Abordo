const toSettings = (r) =>
  r && {
    ownerId: r.owner_id,
    businessName: r.business_name,
    clabe: r.clabe,
    peyKeyEnc: r.pey_api_key_enc,
    peySecretEnc: r.pey_secret_enc,
    peyKeyHint: r.pey_key_hint,
  };

export function settingsRepo(db) {
  return {
    get(ownerId) {
      db.prepare("INSERT OR IGNORE INTO owner_settings (owner_id) VALUES (?)").run(ownerId);
      return toSettings(db.prepare("SELECT * FROM owner_settings WHERE owner_id = ?").get(ownerId));
    },
    save(ownerId, { businessName, clabe, peyKeyEnc, peySecretEnc, peyKeyHint }) {
      this.get(ownerId);
      db.prepare(
        `UPDATE owner_settings SET
           business_name   = COALESCE(?, business_name),
           clabe           = COALESCE(?, clabe),
           pey_api_key_enc = COALESCE(?, pey_api_key_enc),
           pey_secret_enc  = COALESCE(?, pey_secret_enc),
           pey_key_hint    = COALESCE(?, pey_key_hint)
         WHERE owner_id = ?`,
      ).run(businessName ?? null, clabe ?? null, peyKeyEnc ?? null, peySecretEnc ?? null, peyKeyHint ?? null, ownerId);
      return this.get(ownerId);
    },
  };
}
