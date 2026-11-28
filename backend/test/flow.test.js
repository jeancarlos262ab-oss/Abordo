import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { createHmac } from "node:crypto";
import { createApp } from "../src/app.js";
import { loadConfig } from "../src/config.js";
import { createTestDatabase } from "./helpers/db.js";
import { dayRangeUtc, hourMx, monthRangeUtc, todayMx } from "../src/lib/time.js";

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
  db = await createTestDatabase();
  server = createApp({ config, db, log: { error() {} } }).listen(0);
  base = `http://127.0.0.1:${server.address().port}`;
});
after(async () => { server.close(); await db.close(); });

describe("time", () => {
  it("calcula el día en hora de México", () => {
    assert.deepEqual(dayRangeUtc("2026-11-14"), { from: "2026-11-14T06:00:00.000Z", to: "2026-11-15T06:00:00.000Z" });
    assert.equal(hourMx("2026-11-14T06:30:00.000Z"), 0);
    assert.equal(todayMx(new Date("2026-11-20T03:00:00Z")), "2026-11-19");
    assert.deepEqual(monthRangeUtc(new Date("2026-12-15T12:00:00Z")), { from: "2026-12-01T06:00:00.000Z", to: "2027-01-01T06:00:00.000Z" });
    assert.deepEqual(monthRangeUtc(new Date("2026-12-01T03:00:00Z")), { from: "2026-11-01T06:00:00.000Z", to: "2026-12-01T06:00:00.000Z" }); // aún es 30-nov en México
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
    const raw = (await db.query("SELECT pey_api_key_enc FROM owner_settings")).rows[0].pey_api_key_enc;
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
    const l = await call("POST", "/api/auth/login", { body: { login: "marcos", secret: "1234", role: "driver" } });
    assert.equal(l.status, 200);
    driver = l.body.token;
    assert.equal((await call("GET", "/api/owner/units", { token: driver })).status, 403);
    assert.equal((await call("GET", "/api/driver/shift", { token: owner })).status, 403);
    assert.equal((await call("GET", "/api/driver/shift")).status, 401);
    assert.equal((await call("POST", "/api/auth/login", { body: { login: "marcos", secret: "0000", role: "driver" } })).status, 401);
  });

  it("cada entrada solo acepta a los usuarios de su rol", async () => {
    // El chofer "marcos" con su PIN correcto, pero por la entrada del dueño o del pasajero: rechazado.
    for (const role of ["owner", "passenger"]) {
      const r = await call("POST", "/api/auth/login", { body: { login: "marcos", secret: "1234", role } });
      assert.equal(r.status, 401);
      assert.equal(r.body.error.message, "Usuario o contraseña incorrectos.");
    }
    // Sin indicar la entrada tampoco se puede entrar.
    assert.equal((await call("POST", "/api/auth/login", { body: { login: "marcos", secret: "1234" } })).status, 400);
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
    const liveDb = await createTestDatabase();
    const srv = createApp({ config: liveCfg, db: liveDb, log: { error() {} } }).listen(0);
    const url = `http://127.0.0.1:${srv.address().port}/api/webhooks/pey`;
    const body = JSON.stringify({ id: "abc", estatus: "PAID" });
    try {
      assert.equal((await fetch(url, { method: "POST", body, headers: { "x-pey-signature": "mala" } })).status, 401);
      const sig = createHmac("sha256", "s3cret").update(body).digest("hex");
      assert.equal((await fetch(url, { method: "POST", body, headers: { "x-pey-signature": sig } })).status, 204);
    } finally { srv.close(); await liveDb.close(); }
  });
});

describe("concurrencia y bordes (Postgres)", () => {
  let owner, d1, d2, u1, u2;
  const sql = async (q, p) => (await db.query(q, p)).rows;

  before(async () => {
    owner = (await call("POST", "/api/auth/register-owner", { body: { name: "Dueño Dos", login: "dueno2", secret: "contraseña-segura" } })).body.token;
    await call("PUT", "/api/owner/settings", { token: owner, body: { clabe: "012345678901234567", peyApiKey: "pey_key_abcdef1234", peyApiSecret: "pey_secret_123456" } });
    u1 = (await call("POST", "/api/owner/units", { token: owner, body: { label: "U1", route: "R1", fareCents: 1000 } })).body;
    u2 = (await call("POST", "/api/owner/units", { token: owner, body: { label: "U2", route: "R2", fareCents: 2000 } })).body;
    for (const login of ["cho1", "cho2"]) await call("POST", "/api/owner/drivers", { token: owner, body: { name: `Chofer ${login}`, login, pin: "1234" } });
    d1 = (await call("POST", "/api/auth/login", { body: { login: "cho1", secret: "1234", role: "driver" } })).body.token;
    d2 = (await call("POST", "/api/auth/login", { body: { login: "cho2", secret: "1234", role: "driver" } })).body.token;
  });

  it("registros simultáneos con el mismo usuario: uno gana, el otro recibe 409 (no 500)", async () => {
    const body = { name: "Carrera", login: "Carrera", secret: "contraseña-segura" };
    const rs = await Promise.all([1, 2, 3, 4].map(() => call("POST", "/api/auth/register-owner", { body })));
    assert.deepEqual(rs.map((r) => r.status).sort(), [201, 409, 409, 409]);
    assert.equal((await call("POST", "/api/auth/login", { body: { login: "CARRERA", secret: "contraseña-segura", role: "owner" } })).status, 200); // login sin distinguir mayúsculas
  });

  it("turnos simultáneos: un chofer no abre dos y una unidad no tiene dos choferes", async () => {
    const same = await Promise.all([1, 2, 3].map(() => call("POST", "/api/driver/shift", { token: d1, body: { unitId: u1.id } })));
    assert.deepEqual(same.map((r) => r.status).sort(), [201, 409, 409]);
    const rival = await Promise.all([call("POST", "/api/driver/shift", { token: d2, body: { unitId: u1.id } }), call("POST", "/api/driver/shift", { token: d2, body: { unitId: u1.id } })]);
    assert.ok(rival.every((r) => r.status === 409));
    assert.equal((await sql("SELECT COUNT(*)::int AS n FROM shifts WHERE ended_at IS NULL AND unit_id = $1", [u1.id]))[0].n, 1);
  });

  it("pagos simultáneos: consecutivos únicos y sin saltos; un mismo cobro se paga una sola vez", async () => {
    const created = await Promise.all(Array.from({ length: 12 }, () => call("POST", `/api/public/units/${u1.code}/charges`, { body: {} })));
    assert.ok(created.every((c) => c.status === 201));
    const ids = created.map((c) => c.body.id);
    // 3 consultas simultáneas por cobro: webhook y sondeo "a la vez"
    const polled = await Promise.all(ids.flatMap((id) => [1, 2, 3].map(() => call("GET", `/api/public/charges/${id}`))));
    assert.ok(polled.every((r) => r.body.status === "paid"));
    const seqs = (await sql("SELECT paid_seq FROM charges WHERE status='paid' ORDER BY paid_seq")).map((r) => r.paid_seq);
    assert.equal(new Set(seqs).size, seqs.length, "paid_seq repetido");
    assert.deepEqual(seqs, Array.from({ length: seqs.length }, (_, i) => i + 1), "paid_seq con huecos");
    const mine = await call("GET", "/api/driver/shift/payments?afterSeq=0", { token: d1 });
    assert.equal(mine.body.payments.length, 12);
  });

  it("ids fuera de rango dan 400/404, no 500", async () => {
    assert.equal((await call("POST", "/api/driver/shift", { token: d2, body: { unitId: 99999999999 } })).status, 400);
    assert.equal((await call("GET", "/api/driver/shift/payments?afterSeq=99999999999", { token: d1 })).status, 400);
    assert.equal((await call("PATCH", "/api/owner/units/99999999999", { token: owner, body: { active: false } })).status, 400);
    assert.equal((await call("PATCH", "/api/owner/units/987654", { token: owner, body: { active: false } })).status, 404);
    assert.equal((await call("GET", "/api/owner/charges?offset=99999999999", { token: owner })).status, 400);
    assert.equal((await call("GET", "/api/public/units/99999999")).status, 404);
  });

  it("fechas imposibles dan 400, no 500", async () => {
    assert.equal((await call("GET", "/api/owner/reports/summary?date=2026-02-31", { token: owner })).status, 400);
    assert.equal((await call("GET", "/api/owner/reports/summary?date=2026-13-01", { token: owner })).status, 400);
  });

  it("historial: filtros y paginación en SQL conservan el total", async () => {
    const today = todayMx();
    const all = await call("GET", `/api/owner/charges?date=${today}`, { token: owner });
    assert.equal(all.body.total, 12);
    const page = await call("GET", `/api/owner/charges?date=${today}&limit=5&offset=10`, { token: owner });
    assert.deepEqual([page.body.total, page.body.items.length], [12, 2]);
    const beyond = await call("GET", `/api/owner/charges?date=${today}&offset=500`, { token: owner });
    assert.deepEqual([beyond.body.total, beyond.body.items.length], [12, 0]);
    assert.equal((await call("GET", `/api/owner/charges?date=${today}&unitId=${u2.id}`, { token: owner })).body.total, 0);
    assert.equal((await call("GET", `/api/owner/charges?date=${today}&unitId=${u1.id}`, { token: owner })).body.total, 12);
    const items = all.body.items;
    assert.ok(items.every((i, k) => k === 0 || items[k - 1].paidAt >= i.paidAt), "orden descendente");
    assert.match(items[0].paidAt, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/); // sigue siendo ISO-8601 UTC
  });
});

describe("pasajero con cuenta", () => {
  let owner, unit, pax;

  before(async () => {
    owner = (await call("POST", "/api/auth/register-owner", { body: { name: "Dueña Pax", login: "duenapax", secret: "contraseña-segura" } })).body.token;
    await call("PUT", "/api/owner/settings", { token: owner, body: { clabe: "012345678901234567", peyApiKey: "pey_key_abcdef1234", peyApiSecret: "pey_secret_123456" } });
    unit = (await call("POST", "/api/owner/units", { token: owner, body: { label: "Unidad 7", route: "Ruta 9", fareCents: 1500 } })).body;
  });

  it("se registra, entra y no puede usar rutas de dueño ni chofer", async () => {
    const body = { name: "Ana Pasajera", login: "ana", secret: "contraseña-segura" };
    const r = await call("POST", "/api/auth/register-passenger", { body });
    assert.equal(r.status, 201);
    assert.equal(r.body.user.role, "passenger");
    pax = r.body.token;
    assert.equal((await call("POST", "/api/auth/register-passenger", { body: { ...body, login: "ANA" } })).status, 409);
    assert.equal((await call("POST", "/api/auth/register-passenger", { body: { ...body, login: "ana2", secret: "corta" } })).status, 400);
    assert.equal((await call("POST", "/api/auth/login", { body: { login: "ana", secret: body.secret, role: "passenger" } })).status, 200);
    assert.equal((await call("GET", "/api/auth/me", { token: pax })).body.user.role, "passenger");
    assert.equal((await call("GET", "/api/owner/units", { token: pax })).status, 403);
    assert.equal((await call("GET", "/api/driver/shift", { token: pax })).status, 403);
  });

  it("/passenger exige sesión de pasajero", async () => {
    assert.equal((await call("GET", "/api/passenger/me")).status, 401);
    assert.equal((await call("GET", "/api/passenger/me", { token: owner })).status, 403);
    assert.equal((await call("GET", "/api/passenger/payments", { token: owner })).status, 403);
  });

  it("vincula, enmascara y quita la cuenta", async () => {
    assert.deepEqual((await call("GET", "/api/passenger/me", { token: pax })).body, { name: "Ana Pasajera", login: "ana", account: null });
    assert.equal((await call("PUT", "/api/passenger/account", { token: pax, body: { holder: "Ana", phone: "55123", bank: "BBVA" } })).status, 400);
    const put = await call("PUT", "/api/passenger/account", { token: pax, body: { holder: "Ana Pasajera", phone: "5512345678", bank: "BBVA" } });
    assert.equal(put.status, 200);
    assert.deepEqual(put.body.account, { holder: "Ana Pasajera", phone: "••••••5678", bank: "BBVA" });
    // cambiar de banco reemplaza, no duplica
    await call("PUT", "/api/passenger/account", { token: pax, body: { holder: "Ana Pasajera", phone: "5512345678", bank: "Nu" } });
    assert.equal((await call("GET", "/api/passenger/me", { token: pax })).body.account.bank, "Nu");
    assert.equal((await db.query("SELECT COUNT(*)::int AS n FROM passenger_accounts")).rows[0].n, 1);
    assert.ok(!JSON.stringify((await call("GET", "/api/passenger/me", { token: pax })).body).includes("5512345678"), "el celular no debe salir completo");
    assert.equal((await call("DELETE", "/api/passenger/account", { token: pax })).status, 204);
    assert.equal((await call("GET", "/api/passenger/me", { token: pax })).body.account, null);
    await call("PUT", "/api/passenger/account", { token: pax, body: { holder: "Ana Pasajera", phone: "5512345678", bank: "Nu" } });
  });

  it("sus pagos quedan en el historial y suman al mes; los anónimos no", async () => {
    const mine = await call("POST", `/api/public/units/${unit.code}/charges`, { token: pax, body: {} });
    assert.equal(mine.status, 201);
    await call("GET", `/api/public/charges/${mine.body.id}`); // el mock paga al instante
    const anon = await call("POST", `/api/public/units/${unit.code}/charges`, { body: {} });
    await call("GET", `/api/public/charges/${anon.body.id}`);
    // el dueño con su propio token tampoco cuenta como pasajero
    await call("POST", `/api/public/units/${unit.code}/charges`, { token: owner, body: {} });

    const h = await call("GET", "/api/passenger/payments?limit=100", { token: pax });
    assert.equal(h.status, 200);
    assert.equal(h.body.payments.length, 1);
    assert.deepEqual(
      [h.body.payments[0].id, h.body.payments[0].status, h.body.payments[0].amountCents, h.body.payments[0].unitLabel, h.body.payments[0].route],
      [mine.body.id, "paid", 1500, "Unidad 7", "Ruta 9"],
    );
    assert.match(h.body.payments[0].createdAt, /^\d{4}-\d{2}-\d{2}T/);
    assert.equal(h.body.monthCents, 1500);
    assert.equal((await call("GET", "/api/passenger/payments?limit=0", { token: pax })).status, 400);
  });

  it("un token vencido o ajeno en el cobro público no lo rompe; y un cobro vencido se ve como tal", async () => {
    assert.equal((await call("POST", `/api/public/units/${unit.code}/charges`, { token: "basura", body: {} })).status, 201);
    const c = await call("POST", `/api/public/units/${unit.code}/charges`, { token: pax, body: {} });
    await db.query("UPDATE charges SET expires_at = now() - interval '1 minute' WHERE id = $1", [c.body.id]);
    const h = await call("GET", "/api/passenger/payments", { token: pax });
    assert.equal(h.body.payments.find((p) => p.id === c.body.id).status, "expired");
  });
});

describe("foto de perfil", () => {
  let tok, other;
  // PNG real de 1x1 píxel.
  const png = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

  before(async () => {
    tok = (await call("POST", "/api/auth/register-passenger", { body: { name: "Foto Uno", login: "fotouno", secret: "contraseña-segura" } })).body.token;
    other = (await call("POST", "/api/auth/register-passenger", { body: { name: "Foto Dos", login: "fotodos", secret: "contraseña-segura" } })).body.token;
  });

  it("sin foto devuelve null; guarda, lee y quita la suya", async () => {
    assert.equal((await call("GET", "/api/auth/avatar", { token: tok })).body.avatar, null);
    const put = await call("PUT", "/api/auth/avatar", { token: tok, body: { image: png } });
    assert.equal(put.status, 200);
    assert.equal(put.body.avatar, png);
    assert.equal((await call("GET", "/api/auth/avatar", { token: tok })).body.avatar, png);
    assert.equal((await call("GET", "/api/auth/avatar", { token: other })).body.avatar, null); // cada quien la suya
    assert.equal((await call("DELETE", "/api/auth/avatar", { token: tok })).status, 204);
    assert.equal((await call("GET", "/api/auth/avatar", { token: tok })).body.avatar, null);
  });

  it("rechaza lo que no es imagen, el tipo falso y a quien no inició sesión", async () => {
    const fakeText = "data:image/png;base64," + Buffer.from("esto no es una imagen").toString("base64");
    assert.equal((await call("PUT", "/api/auth/avatar", { token: tok, body: { image: fakeText } })).status, 400);
    assert.equal((await call("PUT", "/api/auth/avatar", { token: tok, body: { image: png.replace("image/png", "image/jpeg") } })).status, 400); // PNG disfrazado de JPEG
    assert.equal((await call("PUT", "/api/auth/avatar", { token: tok, body: { image: "data:text/html;base64,PGI+" } })).status, 400);
    assert.equal((await call("PUT", "/api/auth/avatar", { body: { image: png } })).status, 401);
  });
});
