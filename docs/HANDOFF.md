# Handoff: cerrar el MVP desde el backend

Fecha: 2026-11-07. Entrega: **domingo 8 nov, 1:00 PM**, a hola@aibuilders.lat. Lee antes `AGENTS.md`, `docs/PRODUCTO.md` y `docs/BACKEND.md` (estado desplegado y pendientes al final). Este archivo solo lista lo que falta y cómo hacerlo.

## Cómo trabajar

- Git: feature branch desde `origin/dev` (`feature/<área>-<cambio>`), commits pequeños, `git pull --rebase`, PR a `dev` → `stg` → `main` con los criterios de autoaprobación de `AGENTS.md`. No toques `web/` ni `barrio_app_pey/` salvo lo indicado: los trabajan otras personas.
- El checkout principal de quien te lo pasa puede tener cambios locales ajenos. Usa `git worktree add ../wt-<tema> -b <rama> origin/dev` y no ocultes ni descartes nada.
- Producción es Supabase (`bjbfcxodapjaudawlsvg`). La API es la Edge Function `api`: se empaqueta con `npm run build:edge` en `backend/` y se despliega **pegando `supabase/functions/api/index.ts` (no versionado) en el editor del panel**. Las migraciones se aplican en el SQL Editor del panel y siempre llevan GRANT/REVOKE explícitos.
- El panel de Supabase se maneja desde Chrome (herramientas `mcp__claude-in-chrome__*`; antes carga el skill `claude-in-chrome`). Pide al usuario que haya iniciado sesión en Supabase. Antes de cambiar algo en producción, mira el estado actual (tablas, función, secretos); no hagas cambios destructivos sin confirmar.
- Pruebas de pago solo de $0.01 (no se devuelve).

## Tareas, en orden

### 1. Llave de OpenAI (la entrega el usuario en el chat)

1. **Pide la `OPENAI_API_KEY` al usuario en el chat.** No la inventes ni la busques en archivos. Si prefiere OpenRouter, ver `backend/README.md` (mismo código).
2. Guárdala solo en Supabase → Edge Functions → Secrets (vía Chrome). Nunca en Git, en `web/`, en `barrio_app_pey/`, en logs ni en mensajes de commit. Confirma que quedó sin pegarla de vuelta en ninguna salida.
3. Ejecuta `npm run index:catalog` en `backend/` con credenciales de servidor para generar los vectores del catálogo.
4. Verifica `POST /search/agent` con una frase libre ("algo barato de desayunar abierto ahora"): `meta.mode` debe indicar modelo+RAG, no el fallback determinista. Comprueba que el modelo nunca inventa negocios, precios ni totales y que, sin llave o con timeout, cae al modo determinista.

### 2. Insignias: el schema debe encajar con la app

La app (rama `origin/feature/buyer-achievements-navigation`, commit `fad65cb`, archivos `barrio_app_pey/lib/models/achievement.dart` y `components/sections/achievements_screen.dart`) modela los logros distinto a como los calcula hoy el backend. **No des por hecho que encajan: compáralos y haz que el backend entregue lo que la app necesita.**

Lo que hace la app (hoy con datos de muestra en `DemoAchievements`):

- **Niveles** `bronze`, `silver`, `gold`, con descuento 10 %, 15 % y 20 %. Cada logro es una escalera de 3 escalones.
- **Cuatro tipos**, con sus metas por nivel:
  - `repeatVisits` (mismo negocio): 3 / 8 / 20.
  - `neighborhoodShops` (negocios distintos en tu colonia): 3 / 6 / 12.
  - `boroughsExplored` (alcaldías distintas): 3 / 8 / 16.
  - `boroughShops` (negocios distintos en una alcaldía concreta, 16 alcaldías): 1 / 4 / 8.
- Cada logro trae `id`, título, descripción, `progress`, `target`, `couponBusiness` y `alcaldia?`; desbloqueado cuando `progress >= target`. El nombre de cada alcaldía sale de `I18n.alcaldiasCdmx` (revisa que coincida con los valores válidos de `negocios.zona`).

Lo que hace el backend hoy (`backend/src/pedidos.js`, `REGLAS_INSIGNIAS`, `calcularInsignias`; `GET /me/profile`):

- Tres alcances planos, **sin niveles ni descuento**: `colonia` (3 pedidos pagados), `alcaldia` (5), `negocio` (3). Cuenta **pedidos** pagados, no **negocios distintos**; la app cuenta negocios/alcaldías distintos en tres de sus cuatro tipos. Derivadas de pedidos, sin tabla.
- El cupón se ofrece desde el negocio (`cupones` → `cupon_canjes`), no se otorga por insignia.

Qué hacer:

1. Lee ambos lados completos y escribe aquí abajo (sección "Decisión de insignias") una tabla corta de diferencias y la decisión.
2. Decide con el usuario qué manda. Recomendación: la app es la fuente de producto (escaleras de 3 niveles con 4 tipos); el backend se adapta. Mantén las reglas de dominio de `AGENTS.md`: el servidor calcula, el cliente no decide nada de dinero.
3. Adapta `calcularInsignias` y `GET /me/profile` para devolver, por logro: `id` estable, `tipo`, `nivel`, `progreso`, `meta`, `obtenida`, `alcaldia?` y `descuento_porcentaje`, usando negocios/alcaldías **distintos** donde la app lo pide. Cuenta solo pedidos `pagada` o `lista`. Cubre las reglas con pruebas en `backend/test/pedidos.test.js` (son reglas de estado/dinero).
4. Si el descuento por nivel debe aplicarse, hazlo en el servidor al cotizar (`POST /orders/quotes`), reutilizando el mecanismo de cupones (`descuento_minor`, total mínimo $1, `usado` con compare-and-set). Si no es necesario para el MVP, deja el valor solo como dato de presentación y dilo explícito.
5. Si falta algo en el schema (por ejemplo `negocios.colonia` nula en negocios existentes, `zona` fuera del catálogo de alcaldías, o una tabla para registrar logros canjeados), crea una migración nueva con GRANT/REVOKE, aplícala **desde Chrome en el SQL Editor de Supabase** y súbela al repo. Revisa los datos reales antes (negocios de demo sin colonia dejan los logros en cero).
6. Actualiza `docs/BACKEND.md` (sección Cupones e insignias) y `docs/PRODUCTO.md` con el contrato final, y avisa a quien lleva la app el formato exacto del JSON.

### 3. Pagos con pey

1. Registrar el webhook de pey en `https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api/webhooks/pey` y guardar su secreto como `PEY_WEBHOOK_SECRET`. Existe una Edge Function `pey-webhook` anterior con el esquema viejo: retírala o repunta pey.
2. Registrar una CLABE de `docs/PEY.md` en el portal de pey y guardar su `bankAccountId` en `negocios.pey_bank_account_id`.
3. Prueba de punta a punta con cobro real de $0.01 (`npm run e2e:live` cubre 23 pasos con pey en mock; el cobro real ya se verificó por push CoDi una vez). Confirma firma, idempotencia, monto suficiente y que un pago tardío de un intento vencido queda para revisión.

### 4. Lo que aún no está en el backend

Prioriza según el tiempo que quede; todo es opcional para entregar:

- Ubicación por distancia en el ranking (las coordenadas se guardan pero no ordenan).
- `tsvector`/trigramas en la búsqueda (hoy compara texto en memoria con acentos normalizados).
- Paginación por cursor y rate limits propios.
- La app Flutter (`barrio_app_pey/`) aún no consume la API: coordina el contrato con quien la lleva, no la edites sin acordarlo.

### 5. Antes de entregar

- `npm test` en `backend/` y `supabase/tests/run.sh` en verde; CI en verde en cada PR.
- `docs/BACKEND.md` y este archivo actualizados con lo que quedó hecho y lo que no. Cada flujo de compra/cobro tocado se refleja en `docs/PRODUCTO.md` y `docs/BACKEND.md`.
- Confirmar que la URL de la web publicada coincide con Site URL y redirects de Supabase Auth (Authentication → URL Configuration).

## Decisión de insignias

_(Rellena aquí tras comparar app y backend: diferencias, decisión y contrato JSON final.)_
