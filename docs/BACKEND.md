# Backend de Barrio

> Estado: implementado y desplegado como Supabase Edge Function `api`. Este documento describe lo que existe; lo que falta está al final ("Estado desplegado y pendientes"). Base: `https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api` + `/api/v1/...`.

## Responsabilidades

- La app habla únicamente con la API HTTPS de Barrio. No consulta tablas de negocio directamente ni contiene llaves de servidor.
- El backend autentica sesiones, valida entradas y permisos, ejecuta reglas de pedidos, entrega Descubrir y Buscar con Barrio (RAG), consulta Supabase y crea/consulta cobros con pey.
- Postgres es la fuente de verdad de catálogo, disponibilidad, pedidos y pagos. El backend impone autorización por comprador o negocio.
- El webhook de pey valida firma, idempotencia y monto; puede actualizar el pedido una sola vez. La app observa el estado por consulta o canal en tiempo real autenticado.

```text
App ──HTTPS + sesión──► API Barrio ──service credential──► Postgres
                               ├──► OpenRouter u OpenAI (solo interpretación asistida)
                               └──► pey ──webhook firmado──► estado del pedido
```

No se debe exponer `SUPABASE_SECRET_KEY`, `PEY_API_KEY` ni `OPENAI_API_KEY` al cliente. No se debe autorizar al cliente a cambiar estados de orden directamente.

## Descubrir, perfil y búsqueda con Barrio

La API ofrece dos experiencias que comparten catálogo y reglas. **Descubrir** funciona sin modelo y organiza categorías/carruseles. **Buscar con Barrio** recupera candidatos reales antes de invocar al modelo; no es un chat que consulte ni altere la base libremente.

1. **Filtros exactos en SQL:** texto/categoría, zona o coordenadas, abierto ahora, disponibilidad, rango de precio y restricciones del usuario. Estos filtros siempre se aplican antes de ordenar resultados.
2. **Orden estable inspirado en marketplaces:** disponibilidad, distancia, coincidencia de texto/categoría, calidad/completitud del catálogo y señales operativas. Definir pesos con producto; desempate estable por `negocio_id` y producto. No usar pagos ni datos sensibles para ranking.
3. **Búsqueda textual determinista:** normalización de acentos/caso, alias explícitos y `tsvector`/trigramas en nombre, categoría y producto. Retornar por qué coincide.
4. **RAG acotado:** cada negocio tiene un documento de catálogo regenerado cuando cambia su información. La consulta obtiene sus vecinos vectoriales; solo esos candidatos se muestran al agente junto con filtros y datos públicos.
5. **Agente:** interpreta frases libres y devuelve filtros tipados y una explicación breve bajo JSON Schema estricto. Su salida se valida y los filtros explícitos de la app tienen prioridad. El agente no inventa artículos, disponibilidad ni precios y no calcula totales.
6. **Perfil:** el backend registra `search`, `view`, `save` y `order`, y agrega afinidad por categoría. Se usa como señal leve, reproducible y visible; nunca para precio, elegibilidad, pago o datos sensibles.
7. **Fallback:** ante timeout o indisponibilidad de embeddings/modelo, buscar sobre el catálogo completo con texto, categorías y filtros navegables.

El trigger invalida el vector al cambiar un catálogo; el proceso seguro `npm run index:catalog` lo vuelve a generar con credenciales de servidor. Debe ejecutarse al publicar cambios o desde un cron del backend, nunca desde la app.

Cada resultado incluye `match_reasons`, distancia si existe, estado de apertura/disponibilidad y datos necesarios para decidir. Evitar personalización opaca en el MVP; hacer el orden explicable y reproducible.

## Contrato HTTP (v1, implementado)

Prefijo `/api/v1`; JSON UTF-8; errores `{ "error": { "code", "message", "field?" } }`. Importes enteros en centavos (`*_minor`). Sesión: cabecera `Authorization: Bearer <token de Supabase Auth>`. Roles: el comprador se crea solo al registrarse (trigger); el negocio se crea con `POST /businesses` y queda activo. CORS abierto por defecto (`ALLOWED_ORIGINS` lo restringe). Las rutas de pedido devuelven 404 si el recurso no es de la sesión.

| Método y ruta | Auth | Uso |
|---|---|---|
| `GET /health` | — | Estado del servicio |
| `GET /discovery` | opcional | Categorías y carruseles deterministas; afinidad ligera si hay sesión |
| `GET /catalog/search?q=&zone=&category=&open_now=&min_amount_minor=&max_amount_minor=` | opcional | Búsqueda determinista con `match_reasons` y `score` |
| `POST /search/agent` | opcional | Buscar con Barrio: `{ query, filters? }`; usa modelo + RAG si hay llave, si no cae al modo determinista (`meta.mode`) |
| `POST /discovery/events` | comprador | Señal `search`/`view`/`save`/`order` para el perfil |
| `GET /businesses/{id}` | — | Perfil público y menú (sin teléfono ni datos de cobro) |
| `GET /me`, `POST /me` | sesión | Comprador/negocio de la sesión; actualizar nombre, celular (10 dígitos, para el push), zona, colonia, ubicación |
| `GET /me/profile` | comprador | Pedidos pagados e insignias (obtenidas y en progreso) |
| `GET /me/notifications`, `POST /coupons/{id}/accept\|decline` | comprador | Avisos de cupones; aceptar los autoaplica |
| `POST /businesses` | sesión | Alta del negocio de la sesión (activo al registrarse) |
| `GET /business`, `PATCH /business` | negocio | Abrir/cerrar, aceptar en automático, descripción y menú |
| `GET/POST /business/coupons`, `DELETE /business/coupons/{id}` | negocio | Cupones (porcentaje o monto, mínimo, vencimiento); se avisa a quien ya pagó ahí |
| `POST /orders/quotes` | comprador | Cotiza desde el catálogo del servidor; autoaplica el mejor cupón aceptado; caduca a los 10 min |
| `POST /orders` | comprador | Crea el pedido desde `quote_id` con `Idempotency-Key` y `confirmed_total_minor` igual al total cotizado |
| `GET /orders`, `GET /orders/{id}` | sesión | Pedidos propios o del negocio; `codigo` de recogida solo al comprador desde `pagada` |
| `POST /orders/{id}/cancel` | comprador | Solo en `pendiente`, `aceptada` o `vencida` |
| `POST /orders/{id}/accept\|reject\|ready` | negocio | Aceptar (genera el cobro), rechazar, marcar listo |
| `POST /orders/{id}/payments` | comprador | Nuevo intento de cobro; si hay uno vigente devuelve ese |
| `GET /orders/{id}/payments/current` | sesión | Estado del cobro; al comprador le devuelve `link`/`qr_image` y reconcilia con pey si sigue vigente |
| `POST /webhooks/pey` | firma | Webhook de pey (Standard Webhooks, dedupe por `webhook-id`) |
| `POST /internal/sweep` | `CRON_SECRET` | Barrido manual (reconciliación con pey, vencimientos); en producción lo cubren `pg_cron` y la reconciliación al consultar el cobro |

**No implementado todavía:** paginación por cursor, rate limits propios, `tsvector`/trigramas (la búsqueda normaliza acentos y compara texto en memoria), ubicación por distancia en el ranking (las coordenadas se guardan, aún no ordenan).

La cotización calcula precios y total desde el catálogo del servidor y conserva copia de nombre/precio/cantidad. `POST /orders` nunca acepta un total del cliente o del modelo como autoridad; la misma `Idempotency-Key` devuelve el pedido original.

### Estados y pagos

Conservar y formalizar la máquina de estados existente en migraciones/código. Toda transición usa compare-and-set (estado anterior esperado); solo se crea otro intento de cobro cuando el anterior vence. Un webhook firmado es idempotente y solo confirma si la referencia corresponde y el monto pagado cubre el pedido. Un proceso de reconciliación consulta a pey como respaldo. La respuesta al cliente no revela datos bancarios ni secretos.

Implementado en `20261107020000_pedidos_pagos_promos.sql`: `intentos_cobro` y `eventos_webhook`; no reutiliza `ordenes.pey_ref` como historial. Un intento guarda vía, referencia de pey, monto en centavos, vencimiento, estado e idempotency key. Una restricción parcial impide dos intentos vigentes por pedido. El webhook persiste primero su identificador para deduplicar, localiza el intento por referencia, valida monto y actualiza con condición de estado. Un pago tardío de un intento vencido requiere revisión; nunca confirma automáticamente un intento nuevo.

### Seguridad mínima

- Identidad: Supabase Auth; el sujeto externo se guarda como `sujeto_auth` (UUID), no como teléfono.
- Roles comprador/negocio y autorización por objeto en cada ruta.
- Límite de cuerpo (30 KB), validación de entradas y logs sin credenciales ni datos de pago. Rate limits: pendiente.
- CORS: `*` por defecto (la sesión va en cabecera, no en cookies); `ALLOWED_ORIGINS` lo limita. TLS por Supabase. Secretos solo en Edge Function Secrets.
- El webhook usa verificación criptográfica del cuerpo original y protección contra repetición.
- El prompt declara que la entrada de la persona es dato, no instrucción. El agente solo recibe candidatos recuperados y no tiene herramientas de escritura ni acceso a pagos.

## Esquema cerrado (migración `20261107030000_cerrar_schema.sql`)

- **compradores:** `sujeto_auth` (FK a `auth.users`, `on delete set null`: borrar la cuenta conserva pedidos), `nombre`, `telefono` (10 dígitos, para el push CoDi), `zona` (alcaldía), `colonia`, `latitud/longitud` (ambas o ninguna), `actualizado`.
- **negocios:** `sujeto_auth` (dueño en la app), `nombre`, `descripcion`, `imagen_url` (https), `zona` (alcaldía; validada para filas nuevas), `colonia`, `direccion`, `latitud/longitud`, `categoria`, `productos`, `auto_aceptar`, `abierto`, `verificado` + `verificado_en`, `pey_bank_account_id`. `verificado` ya no es un trámite: `POST /businesses` lo marca `true` porque la cuenta es el dueño. Un trigger lo deja en `false` si el negocio no tiene dueño (`sujeto_auth` o `wa_jid` heredado), también al borrar la cuenta. El alta pública directa (anon) sigue naciendo sin dueño y sin activar.
- Corrige un fallo del RAG: el trigger del documento de catálogo ahora es `security definer`; sin eso el registro público (anon) fallaba por permisos.
- Índices de catálogo, pedidos por negocio/estado, cobros vigentes y avisos sin leer; `limpiar_efimeros()` (webhooks > 30 días, cotizaciones vencidas) corre en el barrido.
- Pruebas: `supabase/tests/schema_smoke.sql` (invariantes y RLS) se ejecuta en CI con `supabase/tests/run.sh` sobre un Postgres con pgvector.

## Automatización en Supabase (`20261107040000_automatizacion_supabase.sql`)

- Trigger en `auth.users`: cada cuenta nueva crea su `comprador` (nombre desde `raw_user_meta_data.nombre`). El negocio se liga después con `negocios.sujeto_auth`.
- `barrido_sql()` + `pg_cron` cada minuto: vence cobros, marca pedidos vencidos, expira pedidos sin respuesta a 8 min y devuelve sus cupones. La reconciliación con pey sigue en el backend.
- `notificaciones` con RLS por persona y Realtime (avisos de cupones). Pedidos y cobros siguen solo por API.
- Bucket público `negocios` (2 MB, jpeg/png/webp); escribe solo el dueño en la carpeta con el id de su negocio.

## Cupones e insignias

- **Cupón:** `cupones` (negocio) → `cupon_canjes` por comprador (`ofrecido → aceptado → usado`, una vez por persona) + `notificaciones`. Al publicarlo se ofrece solo a compradores con un pedido `pagada`/`lista` en ese negocio. `POST /orders/quotes` elige el mejor cupón **aceptado** del negocio y lo resta en el servidor (`descuento_minor`, total mínimo $1); `POST /orders` lo marca `usado` con compare-and-set y vuelve a `aceptado` si el pedido se cancela, rechaza o expira. El cobro usa el total ya descontado.
- **Insignias:** derivadas de pedidos pagados, sin tabla: 3 en la misma colonia, 5 en la misma alcaldía o 3 en el mismo negocio (`REGLAS_INSIGNIAS` en `backend/src/pedidos.js`). `GET /me/profile` devuelve también las que van en progreso. Requiere `negocios.colonia`.
- `negocios.sujeto_auth` liga la sesión de Supabase Auth con el negocio (rol negocio); `compradores.sujeto_auth`, con el comprador.

## Decisiones tomadas

- **Sesión y roles:** Supabase Auth (correo y contraseña); comprador automático, negocio por `POST /businesses`. Sin verificación manual.
- **Ubicación:** zona (alcaldía) y colonia obligatorias para negocios; coordenadas opcionales (ambas o ninguna). El ranking aún no las usa.
- **Ranking:** pesos en `backend/src/search.js` (abierto +30, zona +20, categoría +25, texto +18 por término, afinidad ×2); desempate por id.
- **Modelo de IA:** opcional; OpenRouter u OpenAI con el mismo código. La búsqueda nunca depende de él.
- **Hosting:** API y base en Supabase; la web estática la publica otro integrante.

## Estado desplegado y pendientes

- **API:** corre como Supabase Edge Function `api` (`https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api`, JWT de la función apagado: la API autentica sola). Se empaqueta con `npm run build:edge` en `backend/` y se despliega pegando `supabase/functions/api/index.ts` (no versionado) en el editor del panel. Cubre Descubrir, búsqueda (con o sin modelo), cotización, pedidos, cobros con pey (`intentos_cobro`), webhook `/webhooks/pey`, reconciliación puntual al consultar el cobro, cupones, insignias y gestión del negocio.
- **Base:** migraciones hasta `20261107060000` aplicadas en producción; `pg_cron` ejecuta `barrido_sql()`. Datos de demo: negocio 7 (Tacos Doña Lupe) y un cupón. Prueba de punta a punta contra la base real: `npm run e2e:live` (pey en mock; 23 pasos). Cobro real de $0.01 por push CoDi verificado.
- **Web:** `web/app.html` + `app.js` (comprador y negocio) consumen la API. La publicación de la web (GitHub Pages) la hace otro integrante; no desplegarla desde aquí. Auth: Site URL y redirects de Supabase apuntan a `https://gpancardo.github.io/proyectoCoDi/`; si la URL cambia, actualizar ambos en Authentication → URL Configuration.
- **Sin verificación manual de negocios:** un negocio queda activo al registrarse con su cuenta.
- **Modelo de IA:** OpenRouter u OpenAI con el mismo código (ver `backend/README.md`); falta cargar `OPENAI_API_KEY` en los secretos de la función y correr `npm run index:catalog`.

### Pendiente

1. Registrar el webhook de pey en `https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api/webhooks/pey` y guardar su secreto como `PEY_WEBHOOK_SECRET`. Existe una Edge Function `pey-webhook` anterior con el esquema viejo; retirarla o repuntar pey.
2. Cargar `OPENAI_API_KEY` (OpenRouter o OpenAI) en Edge Function Secrets y ejecutar `index:catalog`.
3. Registrar una CLABE de [`PEY.md`](PEY.md) en el portal de pey y guardar su `bankAccountId` en `negocios.pey_bank_account_id`.
4. Publicar `web/` (otro integrante) y confirmar que la URL coincide con la de Auth.
5. Acordar ubicación (coordenadas) y pesos del ranking; la app Flutter (`barrio_app_pey/`) aún no consume la API.
6. Entrega: **domingo 8 nov, 1:00 PM**, a hola@aibuilders.lat. Pruebas de pago solo de $0.01 (no se devuelve).
