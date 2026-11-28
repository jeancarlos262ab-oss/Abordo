# ABORDO · Backend

Node.js ≥ 22.9 · Express · PostgreSQL (`pg`) · zod · JWT.

```bash
cp .env.example .env     # ajusta DATABASE_URL (ver "Base de datos")
npm install
npm start                # http://localhost:3000   (npm run dev recarga al editar); migra la BD al arrancar
npm test                 # pruebas de integración de punta a punta (no requiere instalar Postgres)
```

## Base de datos

PostgreSQL 14+ (probado en 16). Las tablas se crean/actualizan solas al arrancar (migraciones versionadas en
`src/db/migrations.js`, tabla `schema_migrations`, seguras con varias instancias a la vez).

| Dónde | `DATABASE_URL` |
|---|---|
| Local | `postgres://postgres:postgres@localhost:5432/abordo` (p. ej. `docker run -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16`) |
| **Neon** | La cadena **Pooled connection** del panel (`…-pooler…neon.tech/…?sslmode=require`). Si la BD está en reposo, la primera petición tarda unos segundos en despertarla. |
| **Render** | **Internal Database URL** si el servicio web está en Render (misma región); no necesita TLS. La *External* solo para conectarte desde tu máquina (usa TLS automáticamente). |

Variables: `DATABASE_SSL` (`auto` | `true` | `no-verify` | `false`; con `auto` manda el `?sslmode=` de la URL, si lo hay) y
`DATABASE_POOL_MAX` (default 10; mantenlo bajo con planes gratuitos). En producción `DATABASE_URL` es obligatoria.

**Pruebas.** Por defecto usan PGlite (Postgres real en WASM, en memoria). Para correrlas contra un Postgres de verdad:
`TEST_DATABASE_URL=postgres://… npm test` (crea un esquema temporal propio y lo borra al terminar; no toca tus tablas).

## Arquitectura

```
src/
├── config.js          variables de entorno validadas (zod)
├── app.js             composición de dependencias (único lugar donde se "cablea")
├── db/                pool de Postgres + migraciones versionadas (schema_migrations)
├── repositories/      SQL; nada de reglas de negocio
├── services/          reglas de negocio (auth, cobros, turnos, dueño, reportes)
├── routes/            HTTP: validación con zod + llamada al servicio
├── middleware/        autenticación por rol, manejo de errores
├── pey/               cliente del API de pey: Mock (demo) y Http (real)
└── lib/               errores, cifrado, fechas (hora de México), helpers HTTP
```

Decisiones clave:

- **Dinero en centavos enteros.** Nunca decimales.
- **Idempotencia:** un cobro solo cambia a `paid` una vez (y recibe su consecutivo `paid_seq`), aunque llegue el webhook
  y la consulta de respaldo a la vez. Con Postgres hay varias conexiones en paralelo, así que la asignación del consecutivo
  va en una transacción con `pg_advisory_xact_lock`: sin repetidos ni huecos, en el orden en que se confirman los pagos.
- **Aviso de voz sin sockets:** el chofer pide `GET /api/driver/shift/payments?afterSeq=N`; el consecutivo garantiza no perder
  ni repetir avisos aunque se vaya la señal.
- **Un turno abierto por chofer y por unidad** (índices únicos parciales). Los cobros se atribuyen al turno abierto al momento de generarse.
- **Credenciales de pey por dueño**, cifradas con AES-256-GCM (`ENCRYPTION_KEY`). La API nunca las regresa (solo `••••1234`).
- Seguridad: helmet, CORS configurable, rate limit en login y creación de cobros, bcrypt, respuestas de login que no revelan si el usuario existe.

## API

Todo bajo `/api`. Errores: `{ "error": { "code", "message", "details?" } }` con mensajes en español listos para mostrar.

| Método y ruta | Rol | Descripción |
|---|---|---|
| `GET/PUT/DELETE /auth/avatar` (foto de perfil, JPG/PNG/WebP hasta 500 KB, se guarda en la base) · `POST /auth/login` (con `role`: `owner`, `driver` o `passenger`) · `POST /auth/register-owner` · `POST /auth/register-passenger` · `GET /auth/me` | — | Sesión (JWT) |
| `GET /public/units/:code` | público | Datos de la unidad y precio |
| `POST /public/units/:code/charges` | público | Genera el cobro CoDi (`payerPhone` opcional para push). Con token de pasajero el cobro queda en su historial y, si no manda `payerPhone`, usa el celular de su cuenta vinculada |
| `GET /public/charges/:id` | público | Estado del cobro (consulta a pey si sigue pendiente) |
| `GET /driver/units` · `GET/POST/DELETE /driver/shift` · `GET /driver/shift/payments` | chofer | Turno y pagos nuevos |
| `GET /passenger/me` · `PUT/DELETE /passenger/account` · `GET /passenger/payments?limit=` | pasajero | Perfil, cuenta vinculada (celular enmascarado `••••••1234`), historial y total pagado del mes |
| `GET/PUT /owner/settings` | dueño | CLABE y llaves de pey |
| `GET/POST/PATCH /owner/units` · `GET/POST/PATCH /owner/drivers` | dueño | Administración |
| `GET /owner/reports/summary?date=` · `GET /owner/charges?date=` | dueño | Cuadre e historial (día en hora de México) |
| `POST /webhooks/pey` | pey | Estatus del cobro; verifica `x-pey-signature` (HMAC-SHA256 del cuerpo) |

## Conectar el API real de pey

1. Ajusta `src/pey/HttpPeyClient.js` a la documentación (rutas, nombres de campos, firma del webhook). Es el único archivo que lo conoce.
2. `.env`: `PEY_MODE=live`, `PEY_API_BASE_URL`, `PEY_WEBHOOK_SECRET`, y en producción `JWT_SECRET` + `ENCRYPTION_KEY`.
3. Registra `https://TU_DOMINIO/api/webhooks/pey` como webhook de estatus en el Panel de pey.
4. Recuerda: el ambiente productivo de pey requiere validación de la persona/empresa titular; solicítalo con tiempo (regla 8 del Hackatón).
