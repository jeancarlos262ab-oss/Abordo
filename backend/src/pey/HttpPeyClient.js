import { hmacHex, safeEqualHex } from "../lib/crypto.js";
import { AppError } from "../lib/errors.js";

/**
 * Cliente del API real de pey.
 *
 * ⚠️ Los nombres de rutas y campos de abajo son un CONTRATO SUPUESTO: la documentación del API
 * (pey.build) no venía incluida en el material del proyecto. Ajusta únicamente este archivo
 * (rutas, nombres de campos, firma del webhook) cuando tengas la documentación; el resto del
 * backend solo conoce la interfaz {createCharge, getCharge, parseWebhook}.
 *
 * Regla del Hackatón (7, prácticas prohibidas c): cada cobro se genera con las Credenciales del
 * dueño titular de la Cuenta Destino. Por eso las credenciales llegan por llamada y nunca son globales.
 */
const STATUS_MAP = { PAID: "paid", PAGADO: "paid", PENDING: "pending", PENDIENTE: "pending", EXPIRED: "expired", EXPIRADO: "expired", FAILED: "failed", RECHAZADO: "failed" };
const mapStatus = (s) => STATUS_MAP[String(s).toUpperCase()] ?? "pending";

export class HttpPeyClient {
  constructor({ baseUrl, webhookSecret, fetchImpl = fetch }) {
    this.baseUrl = baseUrl;
    this.webhookSecret = webhookSecret;
    this.fetch = fetchImpl;
  }

  async #request(method, path, credentials, body) {
    let res;
    try {
      res = await this.fetch(`${this.baseUrl}${path}`, {
        method,
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${credentials.apiKey}`,
          ...(credentials.apiSecret ? { "x-api-secret": credentials.apiSecret } : {}),
        },
        body: body ? JSON.stringify(body) : undefined,
        signal: AbortSignal.timeout(10_000),
      });
    } catch {
      throw new AppError(502, "pey_unreachable", "No pudimos comunicarnos con CoDi. Intenta de nuevo en un momento.");
    }
    if (!res.ok) throw new AppError(502, "pey_error", "CoDi no pudo generar el cobro. Intenta de nuevo.");
    return res.json();
  }

  async createCharge({ credentials, clabe, amountCents, concept, reference, payerPhone, expiresAt }) {
    const r = await this.#request("POST", "/v1/cobros", credentials, {
      cuentaDestino: clabe,
      monto: amountCents / 100,
      concepto: concept,
      referencia: reference,
      telefonoPagador: payerPhone ?? undefined,
      vigencia: expiresAt,
    });
    return { peyRef: String(r.id), qrPayload: r.qr ?? null, payLink: r.enlace ?? null };
  }

  async getCharge({ credentials, peyRef }) {
    const r = await this.#request("GET", `/v1/cobros/${encodeURIComponent(peyRef)}`, credentials);
    return { status: mapStatus(r.estatus) };
  }

  /** Verifica la firma HMAC-SHA256 (hex) del cuerpo crudo. Lanza si es inválida. */
  parseWebhook(rawBody, signature) {
    if (!this.webhookSecret || !safeEqualHex(hmacHex(this.webhookSecret, rawBody), signature)) {
      throw new AppError(401, "bad_signature", "Firma inválida.");
    }
    const r = JSON.parse(rawBody.toString("utf8"));
    return { peyRef: String(r.id), status: mapStatus(r.estatus) };
  }
}
