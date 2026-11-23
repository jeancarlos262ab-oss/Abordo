import { HttpPeyClient } from "./HttpPeyClient.js";
import { MockPeyClient } from "./MockPeyClient.js";

export const createPeyClient = ({ pey }) =>
  pey.mode === "live"
    ? new HttpPeyClient({ baseUrl: pey.baseUrl, webhookSecret: pey.webhookSecret })
    : new MockPeyClient({ payDelayMs: pey.mockPayDelayMs });
