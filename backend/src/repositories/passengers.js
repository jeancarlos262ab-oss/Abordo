import { first } from "./_util.js";

const toAccount = (r) => r && { holder: r.holder, phone: r.phone, bank: r.bank };

/** Cuenta (celular y banco para CoDi) que un pasajero vincula. */
export function passengersRepo(db) {
  return {
    async findAccount(passengerId) {
      return toAccount(first(await db.query("SELECT * FROM passenger_accounts WHERE passenger_id = $1", [passengerId])));
    },
    async saveAccount(passengerId, { holder, phone, bank }) {
      return toAccount(first(await db.query(
        `INSERT INTO passenger_accounts (passenger_id, holder, phone, bank) VALUES ($1,$2,$3,$4)
         ON CONFLICT (passenger_id) DO UPDATE SET holder = $2, phone = $3, bank = $4, updated_at = now()
         RETURNING *`,
        [passengerId, holder, phone, bank],
      )));
    },
    async removeAccount(passengerId) {
      await db.query("DELETE FROM passenger_accounts WHERE passenger_id = $1", [passengerId]);
    },
  };
}
