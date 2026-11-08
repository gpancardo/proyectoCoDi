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

1. **Filtros deterministas:** texto/categoría, zona, apertura, disponibilidad y rango de precio. Estos filtros se validan antes de ordenar resultados.
2. **Orden estable inspirado en marketplaces:** disponibilidad, zona, coincidencia de texto/categoría y afinidad explícita. El desempate es estable por `negocio_id`; no usa pagos ni datos sensibles.
3. **Búsqueda textual determinista:** normalización de acentos/caso y alias explícitos en nombre, categoría y producto. Cada resultado explica por qué coincide. `tsvector` y trigramas no están implementados aún.
4. **RAG híbrido y acotado:** cada negocio tiene un documento de catálogo (nombre, descripción, categoría, colonia, alcaldía, dirección y productos) con su vector. La consulta se vectoriza y se buscan sus vecinos en `catalogo_documentos` (búsqueda exacta, sin índice aproximado). Ese ranking semántico se **fusiona con las reglas exactas** (texto, categoría, zona, precio) mediante Reciprocal Rank Fusion, así "taco" sigue encontrando "Tacos Doña Lupe" y "algo para desayunar" encuentra la fonda sin compartir palabras. Los vecinos pasan un umbral (0.22) y un corte relativo (70 % del mejor) para no traer ruido. Los filtros duros (negocio activo, abierto, zona, precio y la categoría que manda la app) aplican a ambos lados; la categoría que infiere el modelo es solo una pista.
5. **Agente:** interpreta frases libres y devuelve filtros tipados y una explicación breve bajo JSON Schema estricto. Su salida se valida y los filtros explícitos de la app tienen prioridad. Solo recibe los candidatos ya recuperados; no inventa negocios, artículos, disponibilidad ni precios y no calcula totales. `meta.mode` indica `agent_rag`, `agent`, `rag` o `deterministic_fallback`, y `meta.retrieved` cuántos vecinos entraron.
6. **Perfil:** el backend registra `search`, `view`, `save` y `order`, y agrega afinidad por categoría. Se usa como señal leve, reproducible y visible; nunca para precio, elegibilidad, pago o datos sensibles.
7. **Fallback:** ante timeout o indisponibilidad de embeddings/modelo, buscar sobre el catálogo completo con texto, categorías y filtros navegables.

El trigger invalida el vector al cambiar un catálogo y la API lo regenera sola (hasta 3 negocios por búsqueda); `npm run index:catalog` lo hace en lote con credenciales de servidor. La calidad se mide con `npm run eval:rag` (13 consultas contra el catálogo de demo, acierto en top 3).

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
| `PATCH /business` | negocio | Abrir/cerrar, aceptar en automático, descripción y menú |
| `GET/POST /business/coupons`, `DELETE /business/coupons/{id}` | negocio | Cupones por porcentaje, monto o producto gratis; pueden llevar un código único, mínimo y vencimiento |
| `GET /business/dashboard` | negocio | Tablero de los últimos 30 días: ventas de hoy y ayer, 7 días, por atender, lo que más sale, clientes que regresan; días en hora de CDMX |
| `POST /orders/quotes` | comprador | Cotiza desde el catálogo del servidor; autoaplica el mejor cupón aceptado o valida `coupon_code`; caduca a los 10 min |
| `POST /orders` | comprador | Crea el pedido desde `quote_id` con `Idempotency-Key` y `confirmed_total_minor` igual al total cotizado |
| `GET /orders`, `GET /orders/{id}` | sesión | Pedidos propios o del negocio (`?as=comprador` para ver los propios si la cuenta también tiene negocio); `codigo` de recogida solo al comprador desde `pagada` hasta `entregada` |
| `POST /orders/{id}/cancel` | comprador | Solo en `pendiente`, `aceptada` o `vencida` |
| `POST /orders/{id}/accept\|reject\|ready` | negocio | Aceptar (genera el cobro), rechazar, marcar listo |
| `POST /orders/{id}/received` | comprador | Confirma entrega con transición atómica `lista → entregada` |
| `POST /orders/{id}/payments` | comprador | Nuevo intento de cobro; si hay uno vigente devuelve ese |
| `GET /orders/{id}/payments/current` | sesión | Estado del cobro push y reconciliación con pey si sigue vigente |
| `POST /webhooks/pey` | firma | Webhook de pey (Standard Webhooks, dedupe por `webhook-id`) |
| `POST /internal/sweep` | `CRON_SECRET` | Barrido manual (reconciliación con pey, vencimientos); en producción lo cubren `pg_cron` y la reconciliación al consultar el cobro |

**No implementado todavía:** paginación por cursor, rate limits propios, `tsvector`/trigramas (la búsqueda normaliza acentos y compara texto en memoria), ubicación por distancia en el ranking (las coordenadas se guardan, aún no ordenan).

La cotización calcula precios y total desde el catálogo del servidor y conserva copia de nombre/precio/cantidad. `POST /orders` nunca acepta un total del cliente o del modelo como autoridad; la misma `Idempotency-Key` devuelve el pedido original.

### Estados y pagos

Toda transición usa compare-and-set (estado anterior esperado): `pendiente → aceptada → cobrada → pagada → lista → entregada`, con rutas de rechazo, cancelación y vencimiento según el estado. Solo se crea otro intento de cobro cuando el anterior vence. Un webhook firmado es idempotente y solo confirma si la referencia corresponde y el monto pagado cubre el pedido. Un proceso de reconciliación consulta pey como respaldo. La respuesta al cliente no revela datos bancarios ni secretos.

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
- **negocios:** `sujeto_auth` (dueño en la app), `nombre`, `descripcion`, `imagen_url` (https), `zona` (alcaldía; validada para filas nuevas), `colonia`, `direccion`, `latitud/longitud`, `categoria`, `productos`, `auto_aceptar`, `abierto`, `verificado` + `verificado_en`, `pey_bank_account_id`. `verificado` ya no es un trámite: `POST /businesses` lo marca `true` porque la cuenta es el dueño. Un trigger lo deja en `false` si el negocio no tiene dueño (`sujeto_auth` o `semilla` de demo), también al borrar la cuenta. El alta pública directa (anon) sigue naciendo sin dueño y sin activar.
- Corrige un fallo del RAG: el trigger del documento de catálogo ahora es `security definer`; sin eso el registro público (anon) fallaba por permisos.
- Índices de catálogo, pedidos por negocio/estado, cobros vigentes y avisos sin leer; `limpiar_efimeros()` (webhooks > 30 días, cotizaciones vencidas) corre en el barrido.
- Pruebas: `supabase/tests/schema_smoke.sql` (invariantes y RLS) se ejecuta en CI con `supabase/tests/run.sh` sobre un Postgres con pgvector.

## Automatización en Supabase (`20261107040000_automatizacion_supabase.sql`)

- Trigger en `auth.users`: cada cuenta nueva crea su `comprador` (nombre desde `raw_user_meta_data.nombre`). El negocio se liga después con `negocios.sujeto_auth`.
- `barrido_sql()` + `pg_cron` cada minuto: vence cobros, marca pedidos vencidos, expira pedidos sin respuesta a 8 min y devuelve sus cupones. La reconciliación con pey sigue en el backend.
- `notificaciones` con RLS por persona y Realtime (avisos de cupones). Pedidos y cobros siguen solo por API.
- Bucket público `negocios` (2 MB, jpeg/png/webp); escribe solo el dueño en la carpeta con el id de su negocio.

## Cupones e insignias

- **Cupón:** `cupones` (negocio) → `cupon_canjes` por comprador (`ofrecido → aceptado → usado`, una vez por persona) + `notificaciones`. Puede ser porcentaje, monto o un producto gratis y tener un `codigo` único. Al publicarlo se ofrece solo a compradores con un pedido `pagada`/`lista` en ese negocio. `POST /orders/quotes` elige el mejor cupón **aceptado** o valida un código de ese negocio y lo resta en el servidor (total mínimo $1); `POST /orders` lo marca `usado` con compare-and-set y vuelve a `aceptado` si el pedido se cancela, rechaza o expira. El cobro usa el total ya descontado.
- **Sellos:** derivados de pedidos pagados, sin tabla; reglas y catálogo en [`LOGROS.md`](LOGROS.md). `GET /me/profile` devuelve `insignias` (cuatro, con `nivel`, `nombre` y `detalle` personalizados, `avance`, `meta` y `obtenida`), `alcaldias` (16), `cdmx` y `premio` (la promoción sin código del negocio de la primera compra, si sigue disponible). El negocio solo ve el nombre genérico del sello, nunca dónde más compra su cliente.
- **Promociones sin código:** quien ya pagó en un negocio las recibe aceptadas al cotizar ahí (`cuponesPorOfrecer`), una vez por persona y por cupón.
- `negocios.sujeto_auth` liga la sesión de Supabase Auth con el negocio (rol negocio); `compradores.sujeto_auth`, con el comprador.

## Decisiones tomadas

- **Sesión y roles:** Supabase Auth (correo y contraseña); comprador automático, negocio por `POST /businesses`. Sin verificación manual.
- **Ubicación:** zona (alcaldía) y colonia obligatorias para negocios; coordenadas opcionales (ambas o ninguna). El ranking aún no las usa.
- **Ranking:** pesos en `backend/src/search.js` (abierto +30, zona +20, categoría +25, texto +18 por término, afinidad ×2); desempate por id.
- **Modelo de IA:** opcional; OpenRouter u OpenAI con el mismo código. La búsqueda nunca depende de él.
- **Hosting:** API y base en Supabase; la web estática la publica otro integrante.

## Estado desplegado y pendientes

- **API:** corre como Supabase Edge Function `api` (`https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api`, JWT de la función apagado: la API autentica sola). Se empaqueta con `npm run build:edge` en `backend/` y se despliega pegando `supabase/functions/api/index.ts` (no versionado) en el editor del panel. Cubre Descubrir, búsqueda (con o sin modelo), cotización, pedidos, cobros con pey (`intentos_cobro`), webhook `/webhooks/pey`, reconciliación puntual al consultar el cobro, cupones, insignias y gestión del negocio.
- **Base:** migraciones hasta `20261108030000` aplicadas en producción (la última por SQL Editor: celular repetible y `negocios.semilla`); los negocios demo cobran y avisan a 5615156164, las cuentas nuevas usan el número que registran; `pg_cron` ejecuta `barrido_sql()`. Datos de demo: negocio 7 (Tacos Doña Lupe) y un cupón. Prueba de punta a punta contra la base real: `npm run e2e:live` (pey en mock; 23 pasos). Cobro real de $0.01 por push CoDi verificado.
- **Entrega y códigos:** `20261108010000_entrega_y_codigos.sql` ya habilitó `entregada`, códigos únicos y producto gratis. El bundle de backend correspondiente ya está publicado en la Edge Function `api`; el 8 nov 2026 respondió `200 {"ok":true}` en producción después del despliegue.
- **Web:** `web/app.html` + `app.js` (comprador y negocio) consumen la API. La publicación de la web (GitHub Pages) la hace otro integrante; no desplegarla desde aquí. Auth: Site URL y redirects de Supabase apuntan a `https://gpancardo.github.io/proyectoCoDi/`; si la URL cambia, actualizar ambos en Authentication → URL Configuration.
- **Sin verificación manual de negocios:** un negocio queda activo al registrarse con su cuenta.
- **Modelo de IA:** OpenRouter u OpenAI con el mismo código (ver `backend/README.md`); falta cargar `OPENAI_API_KEY` en los secretos de la función y correr `npm run index:catalog`.

### Pendiente

1. Registrar el webhook de pey en `https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api/webhooks/pey` y guardar su secreto como `PEY_WEBHOOK_SECRET`. Existe una Edge Function `pey-webhook` anterior con el esquema viejo; retirarla o repuntar pey.
2. Cargar `OPENAI_API_KEY` (OpenRouter o OpenAI) en Edge Function Secrets y ejecutar `index:catalog`.
3. Registrar una CLABE de [`PEY.md`](PEY.md) en el portal de pey y guardar su `bankAccountId` en `negocios.pey_bank_account_id`.
4. Publicar `web/` (otro integrante) y confirmar que la URL coincide con la de Auth.
5. Acordar ubicación (coordenadas) y pesos del ranking. La app Flutter ya consume la API; falta validar voz en Android físico.

## App Flutter: estado de validación (8 nov 2026)

- Cliente: errores de red/API con mensaje y reintento en todas las pantallas; dictado con `speech_to_text` en es_MX (con respaldo a otro español), permiso `RECORD_AUDIO` declarado, errores por código y búsqueda automática al terminar el dictado.
- El negocio se da de alta y se administra en la app: resumen, pedidos, menú y promociones.
- Vendedor puede crear códigos de descuento: porcentaje en toda la compra o un producto gratis. No hay descuento de monto fijo en la app; porcentaje por artículo requiere soporte nuevo en `POST /business/coupons`.
- El esquema de entrega/códigos y el backend que expone `/orders/:id/received` ya están publicados; falta validación de punta a punta autenticada en producción.
- Sin emulador Android en esta máquina: la voz solo se validó por código y análisis; falta probarla en un teléfono. Archivo ya va empaquetada en la app. Lo que falta está en [`../pendientes/`](../pendientes/README.md).
