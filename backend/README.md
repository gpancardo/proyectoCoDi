# Backend Barrio

API HTTP para la aplicación standalone. Este corte entrega **Descubrir** y **Buscar con Barrio**; la app nunca accede directamente a Supabase ni a secretos.

## Estado

Implementado: catálogo público, filtros y ranking determinista, perfil por señales explícitas, recuperación vectorial opcional, agente con JSON Schema y fallback sin OpenAI.

También: cotización, pedidos, gestión del negocio, intentos de cobro, webhook de pey (`/webhooks/pey`), barrido/reconciliación, cupones e insignias (ver `docs/BACKEND.md`). Pendiente: prueba end-to-end contra Supabase y pey reales. Variables nuevas en `.env.example` (`PEY_API_KEY`, `PEY_MOCK`, `PEY_WEBHOOK_SECRET`, `CRON_SECRET`).

## Operación local

1. Copia `.env.example` a `.env`; los secretos viven solo en el servidor.
2. Aplica las migraciones de `supabase/migrations/`.
3. Ejecuta `npm run index:catalog` después de publicar un menú o desde un cron seguro.
4. Ejecuta `npm start`. `GET /health` responde `{ "ok": true }`.

Usa `npm run check` y `npm test` antes de integrar.

## Garantías

`GET /api/v1/discovery` organiza categorías y carruseles; `GET /api/v1/catalog/search` devuelve motivos de coincidencia; `POST /api/v1/search/agent` limita al agente a los candidatos recuperados y conserva el fallback; `POST /api/v1/discovery/events` acepta solo `search`, `view`, `save` y `order`.

La sesión se valida con Supabase Auth y el backend busca al comprador por `sujeto_auth`; nunca acepta un comprador enviado por la app. El perfil no usa cobros ni datos sensibles.

## Pagos

Cada cobro debe vivir en `intentos_cobro`, no en un campo de la orden: referencia pey, vía, monto en centavos, vencimiento, estado e idempotency key. Una restricción parcial impide más de un intento vigente. El webhook guarda primero su ID de evento, verifica firma/cuerpo crudo, referencia y monto, y solo entonces hace una transición condicional. La reconciliación consulta pey para intentos vivos. Un pago tardío de un intento vencido requiere revisión y jamás confirma un intento nuevo.
