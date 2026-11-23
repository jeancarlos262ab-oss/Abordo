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

  return {
    getSettings: (ownerId) => settings.get(ownerId),
    settingsView: (ownerId) => view(settings.get(ownerId)),
    saveSettings(ownerId, { businessName, clabe, peyApiKey, peyApiSecret }) {
      return view(
        settings.save(ownerId, {
          businessName,
          clabe,
          peyKeyEnc: peyApiKey ? vault.encrypt(peyApiKey) : undefined,
          peySecretEnc: peyApiSecret ? vault.encrypt(peyApiSecret) : undefined,
          peyKeyHint: peyApiKey ? `••••${peyApiKey.slice(-4)}` : undefined,
        }),
      );
    },
    getPeyCredentials(ownerId) {
      const s = settings.get(ownerId);
      return {
        apiKey: s.peyKeyEnc ? vault.decrypt(s.peyKeyEnc) : null,
        apiSecret: s.peySecretEnc ? vault.decrypt(s.peySecretEnc) : null,
      };
    },
    /** Un dueño puede cobrar si tiene CLABE y credenciales (en modo demo basta con eso, sin validar con pey). */
    canCharge(ownerId) {
      const s = settings.get(ownerId);
      return !!s.clabe && !!s.peyKeyEnc;
    },

    listUnits: (ownerId) => units.list(ownerId).map(unitView),
    createUnit: (ownerId, data) => unitView(units.create(ownerId, data)),
    updateUnit(ownerId, id, data) {
      if (!units.findOwned(ownerId, id)) throw notFound("No encontramos esa unidad.");
      return unitView(units.update(id, data));
    },

    listDrivers: (ownerId) => users.listDrivers(ownerId).map(driverView),
    async createDriver(ownerId, { name, login, pin }) {
      if (users.findByLogin(login)) throw conflict("Ese usuario ya existe. Prueba con otro.");
      return driverView(users.create({ role: "driver", ownerId, name, login, secretHash: await auth.hash(pin) }));
    },
    async updateDriver(ownerId, id, { name, active, pin }) {
      if (!users.findDriver(ownerId, id)) throw notFound("No encontramos a ese chofer.");
      if (name === undefined && active === undefined && pin === undefined) throw badRequest("No hay nada que cambiar.");
      return driverView(users.update(id, { name, active, secretHash: pin ? await auth.hash(pin) : undefined }));
    },
  };
}
