# ABORDO · Backend

Node.js ≥ 22.9 · Express · SQLite (better-sqlite3) · zod · JWT.

```bash
cp .env.example .env
npm install
npm start        # http://localhost:3000   (npm run dev recarga al editar)
npm test         # pruebas de integración de punta a punta
```

## Arquitectura

```
src/
├── config.js          variables de entorno validadas (zod)
├── app.js             composición de dependencias (único lugar donde se "cablea")
├── db/                conexión + migraciones versionadas (PRAGMA user_version)
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
  y la consulta de respaldo a la vez.
- **Aviso de voz sin sockets:** el chofer pide `GET /api/driver/shift/payments?afterSeq=N`; el consecutivo garantiza no perder
  ni repetir avisos aunque se vaya la señal.
- **Un turno abierto por chofer y por unidad** (índices únicos parciales). Los cobros se atribuyen al turno abierto al momento de generarse.
- **Credenciales de pey por dueño**, cifradas con AES-256-GCM (`ENCRYPTION_KEY`). La API nunca las regresa (solo `••••1234`).
- Seguridad: helmet, CORS configurable, rate limit en login y creación de cobros, bcrypt, respuestas de login que no revelan si el usuario existe.

## API

Todo bajo `/api`. Errores: `{ "error": { "code", "message", "details?" } }` con mensajes en español listos para mostrar.

| Método y ruta | Rol | Descripción |
|---|---|---|
| `POST /auth/login` · `POST /auth/register-owner` · `GET /auth/me` | — | Sesión (JWT) |
| `GET /public/units/:code` | público | Datos de la unidad y precio |
| `POST /public/units/:code/charges` | público | Genera el cobro CoDi (`payerPhone` opcional para push) |
| `GET /public/charges/:id` | público | Estado del cobro (consulta a pey si sigue pendiente) |
| `GET /driver/units` · `GET/POST/DELETE /driver/shift` · `GET /driver/shift/payments` | chofer | Turno y pagos nuevos |
| `GET/PUT /owner/settings` | dueño | CLABE y llaves de pey |
| `GET/POST/PATCH /owner/units` · `GET/POST/PATCH /owner/drivers` | dueño | Administración |
| `GET /owner/reports/summary?date=` · `GET /owner/charges?date=` | dueño | Cuadre e historial (día en hora de México) |
| `POST /webhooks/pey` | pey | Estatus del cobro; verifica `x-pey-signature` (HMAC-SHA256 del cuerpo) |

## Conectar el API real de pey

1. Ajusta `src/pey/HttpPeyClient.js` a la documentación (rutas, nombres de campos, firma del webhook). Es el único archivo que lo conoce.
2. `.env`: `PEY_MODE=live`, `PEY_API_BASE_URL`, `PEY_WEBHOOK_SECRET`, y en producción `JWT_SECRET` + `ENCRYPTION_KEY`.
3. Registra `https://TU_DOMINIO/api/webhooks/pey` como webhook de estatus en el Panel de pey.
4. Recuerda: el ambiente productivo de pey requiere validación de la persona/empresa titular; solicítalo con tiempo (regla 8 del Hackatón).
