import { uniqueViolationOf } from "../db/errors.js";
import { badRequest, conflict, notFound } from "../lib/errors.js";

export function ownerService({ users, units, settings, vault, auth, config }) {
  const view = (s) => ({
    businessName: s.businessName,
    clabe: s.clabe,
    peyConfigured: !!s.peyKeyEnc,
    peyKeyHint: s.peyKeyHint,
  });
  const driverView = ({ id, name, login, active }) => ({ id, name, login, active });
  const unitView = (u) => ({ ...u, ownerId: undefined, qrContent: `${config.publicBaseUrl}/u/${u.code}` });

  // Helpers sobre un `settings` ya leído: permiten consultar la base UNA vez por operación.
  const canChargeWith = (s) => !!s.clabe && !!s.peyKeyEnc;
  const credentialsOf = (s) => ({
    apiKey: s.peyKeyEnc ? vault.decrypt(s.peyKeyEnc) : null,
    apiSecret: s.peySecretEnc ? vault.decrypt(s.peySecretEnc) : null,
  });

  return {
    canChargeWith,
    credentialsOf,
    getSettings: (ownerId) => settings.get(ownerId),
    async settingsView(ownerId) {
      return view(await settings.get(ownerId));
    },
    async saveSettings(ownerId, { businessName, clabe, peyApiKey, peyApiSecret }) {
      return view(
        await settings.save(ownerId, {
          businessName,
          clabe,
          peyKeyEnc: peyApiKey ? vault.encrypt(peyApiKey) : undefined,
          peySecretEnc: peyApiSecret ? vault.encrypt(peyApiSecret) : undefined,
          peyKeyHint: peyApiKey ? `••••${peyApiKey.slice(-4)}` : undefined,
        }),
      );
    },
    async getPeyCredentials(ownerId) {
      return credentialsOf(await settings.get(ownerId));
    },
    /** Un dueño puede cobrar si tiene CLABE y credenciales (en modo demo basta con eso, sin validar con pey). */
    async canCharge(ownerId) {
      return canChargeWith(await settings.get(ownerId));
    },

    async listUnits(ownerId) {
      return (await units.list(ownerId)).map(unitView);
    },
    async createUnit(ownerId, data) {
      return unitView(await units.create(ownerId, data));
    },
    async updateUnit(ownerId, id, data) {
      if (!(await units.findOwned(ownerId, id))) throw notFound("No encontramos esa unidad.");
      return unitView(await units.update(id, data));
    },

    async listDrivers(ownerId) {
      return (await users.listDrivers(ownerId)).map(driverView);
    },
    async createDriver(ownerId, { name, login, pin }) {
      if (await users.findByLogin(login)) throw conflict("Ese usuario ya existe. Prueba con otro.");
      const secretHash = await auth.hash(pin);
      try {
        return driverView(await users.create({ role: "driver", ownerId, name, login, secretHash }));
      } catch (err) {
        if (uniqueViolationOf(err) === "uq_users_login") throw conflict("Ese usuario ya existe. Prueba con otro.");
        throw err;
      }
    },
    async updateDriver(ownerId, id, { name, active, pin }) {
      if (!(await users.findDriver(ownerId, id))) throw notFound("No encontramos a ese chofer.");
      if (name === undefined && active === undefined && pin === undefined) throw badRequest("No hay nada que cambiar.");
      return driverView(await users.update(id, { name, active, secretHash: pin ? await auth.hash(pin) : undefined }));
    },
  };
}
