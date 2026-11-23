import { randomBytes } from "node:crypto";

/**
 * Simula el API de pey para desarrollo y demos: sin red, sin dinero real.
 * El cobro se "paga" solo pasados `payDelayMs`. Es stateless: la referencia lleva su fecha.
 */
export class MockPeyClient {
  constructor({ payDelayMs }) {
    this.payDelayMs = payDelayMs;
  }

  async createCharge({ amountCents, concept }) {
    const peyRef = `mock_${Date.now()}_${randomBytes(4).toString("hex")}`;
    return {
      peyRef,
      qrPayload: `codi-mock://cobro/${peyRef}?monto=${amountCents}&concepto=${encodeURIComponent(concept)}`,
      payLink: null, // en demo no hay app de banco a la cual saltar
    };
  }

  async getCharge({ peyRef }) {
    const createdAt = Number(peyRef.split("_")[1]);
    return { status: Date.now() - createdAt >= this.payDelayMs ? "paid" : "pending" };
  }

  parseWebhook(rawBody) {
    const { peyRef, status } = JSON.parse(rawBody.toString("utf8"));
    return { peyRef, status };
  }
}
