# Backend Barrio

API HTTP de Barrio para la web y la app. Corre como **Supabase Edge Function** `api` (`edge/api.js` adapta `src/server.js`) o como servidor Node local. Ni la web ni la app tocan Supabase directamente ni conocen secretos. Sin dependencias de npm.

## Estado

Implementado y probado contra la base real (`npm run e2e:live`, 23 pasos, pey en mock; cobro real de $0.01 por push CoDi probado aparte): Descubrir, búsqueda determinista, perfil, agente con fallback, cotización, pedidos idempotentes, gestión del negocio, intentos de cobro, webhook de pey, reconciliación al consultar el cobro, cupones e insignias. Contrato completo: [`docs/BACKEND.md`](../docs/BACKEND.md). Pendientes: [`docs/BACKEND.md#estado-desplegado-y-pendientes`](../docs/BACKEND.md#estado-desplegado-y-pendientes).

Variables (`.env.example`): `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` (en Edge Functions las inyecta Supabase), `PEY_API_KEY`, `PEY_MOCK`, `PEY_WEBHOOK_SECRET`, `CRON_SECRET`, `APP_RETURN_URL`, `ALLOWED_ORIGINS`, `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`, `OPENAI_EMBEDDING_MODEL`.

## Operación local

1. Copia `.env.example` a `.env`; los secretos viven solo en el servidor.
2. Aplica las migraciones de `supabase/migrations/` (SQL Editor o `supabase db push`).
3. Ejecuta `npm run index:catalog` después de publicar un menú o desde un cron seguro.
4. Ejecuta `npm start`. `GET /health` responde `{ "ok": true }`.

Usa `npm run check` y `npm test` antes de integrar.

## Garantías

`GET /api/v1/discovery` organiza categorías y carruseles; `GET /api/v1/catalog/search` devuelve motivos de coincidencia; `POST /api/v1/search/agent` limita al agente a los candidatos recuperados y conserva el fallback; `POST /api/v1/discovery/events` acepta solo `search`, `view`, `save` y `order`.

La sesión se valida con Supabase Auth y el backend busca al comprador por `sujeto_auth`; nunca acepta un comprador enviado por la app. El perfil no usa cobros ni datos sensibles.

## Pagos

Cada cobro debe vivir en `intentos_cobro`, no en un campo de la orden: referencia pey, vía, monto en centavos, vencimiento, estado e idempotency key. Una restricción parcial impide más de un intento vigente. El webhook guarda primero su ID de evento, verifica firma/cuerpo crudo, referencia y monto, y solo entonces hace una transición condicional. La reconciliación consulta pey para intentos vivos. Un pago tardío de un intento vencido requiere revisión y jamás confirma un intento nuevo.

## Despliegue y prueba real

- **Desplegar:** `npm run build:edge` genera `supabase/functions/api/index.ts` (no versionado). Pégalo en Supabase → Edge Functions → `api` → Code y pulsa *Deploy updates* (o `npx supabase functions deploy api --no-verify-jwt` con la CLI enlazada). La función debe tener *Verify JWT* apagado. Secretos en Edge Functions → Secrets; `SUPABASE_*` los inyecta Supabase. Webhook de pey: `https://<proyecto>.supabase.co/functions/v1/api/webhooks/pey`.
- `npm run e2e:live` (con `E2E_CONFIRM=1`): recorre cotización → pedido → aceptación → cobro → webhook firmado → pagado → cupón → insignias contra la base real, con pey en mock, y borra sus datos. Última corrida: 23 pasos correctos (7 nov 2026).
- Un negocio queda activo al registrarse con su cuenta (`POST /businesses`); no hay verificación manual. Para ligar uno existente: `update negocios set sujeto_auth = '<uuid de Auth>', verificado = true where id = <id>;`.
- **Modelo de IA (OpenAI u OpenRouter):** el mismo código sirve a ambos. OpenRouter: `OPENAI_BASE_URL=https://openrouter.ai/api/v1`, `OPENAI_MODEL=openai/gpt-4o-mini`, `OPENAI_EMBEDDING_MODEL=openai/text-embedding-3-small` y la llave de OpenRouter en `OPENAI_API_KEY`. OpenAI: quita `OPENAI_BASE_URL` y usa `gpt-4o-mini` / `text-embedding-3-small`. Los embeddings son los mismos (1536), no hay que reindexar.
