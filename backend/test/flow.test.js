import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { createHmac } from "node:crypto";
import { createApp } from "../src/app.js";
import { loadConfig } from "../src/config.js";
import { openDatabase } from "../src/db/index.js";
import { dayRangeUtc, hourMx, todayMx } from "../src/lib/time.js";

process.env.NODE_ENV = "test";
const config = loadConfig({ NODE_ENV: "test", PEY_MOCK_PAY_DELAY_SECONDS: "0" });

let server, base, db;
const call = async (method, path, { token, body } = {}) => {
  const res = await fetch(base + path, {
    method,
    headers: { "content-type": "application/json", ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, body: res.status === 204 ? null : await res.json() };
};

before(async () => {
  db = openDatabase(":memory:");
  server = createApp({ config, db, log: { error() {} } }).listen(0);
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => { server.close(); db.close(); });

describe("time", () => {
  it("calcula el día en hora de México", () => {
    assert.deepEqual(dayRangeUtc("2026-11-14"), { from: "2026-11-14T06:00:00.000Z", to: "2026-11-15T06:00:00.000Z" });
    assert.equal(hourMx("2026-11-14T06:30:00.000Z"), 0);
    assert.equal(todayMx(new Date("2026-11-20T03:00:00Z")), "2026-11-19");
  });
});

describe("flujo completo ABORDO", () => {
  let owner, driver, unit;

  it("registra dueño y configura cuenta", async () => {
    const r = await call("POST", "/api/auth/register-owner", { body: { name: "Lucía Romero", login: "lucia", secret: "contraseña-segura" } });
    assert.equal(r.status, 201);
    owner = r.body.token;
    const s = await call("PUT", "/api/owner/settings", { token: owner, body: { businessName: "Combis Lucía", clabe: "012345678901234567", peyApiKey: "pey_key_abcdef1234", peyApiSecret: "pey_secret_123456" } });
    assert.equal(s.status, 200);
    assert.deepEqual([s.body.peyConfigured, s.body.peyKeyHint], [true, "••••1234"]);
    assert.ok(!JSON.stringify(s.body).includes("abcdef"), "no debe regresar la llave");
    const raw = db.prepare("SELECT pey_api_key_enc FROM owner_settings").get().pey_api_key_enc;
    assert.ok(!raw.includes("abcdef"), "la llave debe estar cifrada en la base");
  });

  it("crea unidad y chofer; valida datos", async () => {
    const u = await call("POST", "/api/owner/units", { token: owner, body: { label: "Unidad 14", route: "Ruta 52", fareCents: 1200 } });
    assert.equal(u.status, 201);
    unit = u.body;
    assert.match(unit.code, /^\d{6}$/);
    assert.equal((await call("POST", "/api/owner/units", { token: owner, body: { label: "", route: "x" } })).status, 400);
    const d = await call("POST", "/api/owner/drivers", { token: owner, body: { name: "Marcos Peña", login: "marcos", pin: "1234" } });
    assert.equal(d.status, 201);
    assert.equal((await call("POST", "/api/owner/drivers", { token: owner, body: { name: "Otro", login: "MARCOS", pin: "1234" } })).status, 409);
  });

  it("separa permisos por rol", async () => {
    const l = await call("POST", "/api/auth/login", { body: { login: "marcos", secret: "1234" } });
    assert.equal(l.status, 200);
    driver = l.body.token;
    assert.equal((await call("GET", "/api/owner/units", { token: driver })).status, 403);
    assert.equal((await call("GET", "/api/driver/shift", { token: owner })).status, 403);
    assert.equal((await call("GET", "/api/driver/shift")).status, 401);
    assert.equal((await call("POST", "/api/auth/login", { body: { login: "marcos", secret: "0000" } })).status, 401);
  });

  it("el chofer abre turno y el pasajero paga", async () => {
    const units = await call("GET", "/api/driver/units", { token: driver });
    assert.equal(units.body.units.length, 1);
    assert.equal((await call("POST", "/api/driver/shift", { token: driver, body: { unitId: unit.id } })).status, 201);
    assert.equal((await call("POST", "/api/driver/shift", { token: driver, body: { unitId: unit.id } })).status, 409);

    const info = await call("GET", `/api/public/units/${unit.code}`);
    assert.deepEqual([info.body.label, info.body.fareCents, info.body.acceptsPayments], ["Unidad 14", 1200, true]);

    const c = await call("POST", `/api/public/units/${unit.code}/charges`, { body: {} });
    assert.equal(c.status, 201);
    assert.equal(c.body.amountCents, 1200);
    const polled = await call("GET", `/api/public/charges/${c.body.id}`);
    assert.equal(polled.body.status, "paid"); // el mock paga al instante con delay 0
    assert.equal((await call("GET", `/api/public/charges/${c.body.id}`)).body.status, "paid"); // idempotente

    const news = await call("GET", "/api/driver/shift/payments?afterSeq=0", { token: driver });
    assert.equal(news.body.payments.length, 1);
    assert.equal((await call("GET", `/api/driver/shift/payments?afterSeq=${news.body.latestSeq}`, { token: driver })).body.payments.length, 0);
    const shift = await call("GET", "/api/driver/shift", { token: driver });
    assert.deepEqual(shift.body.totals, { count: 1, amountCents: 1200 });
  });

  it("el dueño ve el cuadre del día", async () => {
    const s = await call("GET", "/api/owner/reports/summary", { token: owner });
    assert.equal(s.body.totalCents, 1200);
    assert.equal(s.body.byDriver[0].name, "Marcos Peña");
    assert.equal(s.body.byUnit[0].name, "Unidad 14");
    assert.equal(s.body.hourly.length, 24);
    const h = await call("GET", "/api/owner/charges", { token: owner });
    assert.equal(h.body.total, 1);
  });

  it("cierra turno y un cobro sin turno queda 'Sin chofer'", async () => {
    const end = await call("DELETE", "/api/driver/shift", { token: driver });
    assert.equal(end.body.totals.amountCents, 1200);
    const c = await call("POST", `/api/public/units/${unit.code}/charges`, { body: {} });
    await call("GET", `/api/public/charges/${c.body.id}`);
    const s = await call("GET", "/api/owner/reports/summary", { token: owner });
    assert.equal(s.body.totalCents, 2400);
    assert.ok(s.body.byDriver.some((d) => d.name === "Sin chofer"));
  });

  it("rechaza unidades inexistentes y desactivadas", async () => {
    assert.equal((await call("GET", "/api/public/units/999999")).status, 404);
    await call("PATCH", `/api/owner/units/${unit.id}`, { token: owner, body: { active: false } });
    assert.equal((await call("POST", `/api/public/units/${unit.code}/charges`, { body: {} })).status, 404);
  });
});

describe("webhook de pey (modo mock)", () => {
  it("ignora referencias desconocidas", async () => {
    const res = await fetch(`${base}/api/webhooks/pey`, { method: "POST", body: JSON.stringify({ peyRef: "x", status: "paid" }) });
    assert.equal(res.status, 204);
  });
});

describe("webhook de pey (modo live)", () => {
  it("exige firma válida", async () => {
    const liveCfg = loadConfig({ NODE_ENV: "test", PEY_MODE: "live", PEY_WEBHOOK_SECRET: "s3cret" });
    const srv = createApp({ config: liveCfg, db: openDatabase(":memory:"), log: { error() {} } }).listen(0);
    const url = `http://127.0.0.1:${srv.address().port}/api/webhooks/pey`;
    const body = JSON.stringify({ id: "abc", estatus: "PAID" });
    try {
      assert.equal((await fetch(url, { method: "POST", body, headers: { "x-pey-signature": "mala" } })).status, 401);
      const sig = createHmac("sha256", "s3cret").update(body).digest("hex");
      assert.equal((await fetch(url, { method: "POST", body, headers: { "x-pey-signature": sig } })).status, 204);
    } finally { srv.close(); }
  });
});
