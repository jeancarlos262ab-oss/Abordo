import { createCipheriv, createDecipheriv, createHmac, randomBytes, timingSafeEqual } from "node:crypto";

/** Cifrado AES-256-GCM para guardar las credenciales de pey de cada dueño. */
export function createVault(key) {
  return {
    encrypt(plain) {
      const iv = randomBytes(12);
      const c = createCipheriv("aes-256-gcm", key, iv);
      const data = Buffer.concat([c.update(plain, "utf8"), c.final()]);
      return Buffer.concat([iv, c.getAuthTag(), data]).toString("base64");
    },
    decrypt(token) {
      const raw = Buffer.from(token, "base64");
      const d = createDecipheriv("aes-256-gcm", key, raw.subarray(0, 12));
      d.setAuthTag(raw.subarray(12, 28));
      return Buffer.concat([d.update(raw.subarray(28)), d.final()]).toString("utf8");
    },
  };
}

export function hmacHex(secret, payload) {
  return createHmac("sha256", secret).update(payload).digest("hex");
}

export function safeEqualHex(a, b) {
  const x = Buffer.from(a ?? "", "utf8");
  const y = Buffer.from(b ?? "", "utf8");
  return x.length === y.length && timingSafeEqual(x, y);
}
