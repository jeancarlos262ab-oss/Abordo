import { monthRangeUtc } from "../lib/time.js";

/** El celular nunca sale completo del servidor: la app solo necesita mostrar los últimos 4 dígitos. */
const maskPhone = (phone) => `••••••${phone.slice(-4)}`;
const accountView = (a) => (a ? { holder: a.holder, phone: maskPhone(a.phone), bank: a.bank } : null);

export function passengerService({ passengers, charges }) {
  return {
    async profile(user) {
      return { name: user.name, login: user.login, account: accountView(await passengers.findAccount(user.id)) };
    },
    async linkAccount(user, data) {
      return accountView(await passengers.saveAccount(user.id, data));
    },
    unlinkAccount: (user) => passengers.removeAccount(user.id),
    /** Celular vinculado (completo), para avisar al banco del pasajero al generar su cobro. */
    async linkedPhone(passengerId) {
      return (await passengers.findAccount(passengerId))?.phone;
    },
    async payments(user, limit) {
      const { from, to } = monthRangeUtc();
      const [items, monthCents] = await Promise.all([charges.forPassenger(user.id, limit), charges.passengerPaidTotal(user.id, from, to)]);
      return { payments: items, monthCents };
    },
  };
}
