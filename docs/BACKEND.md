# Backend de Barrio

> Estado: contrato inicial para el backend y la app standalone. Aún no hay API HTTP desplegada. Antes de programar rutas, el responsable de la app y el del backend deben cerrar este contrato en una feature branch.

## Responsabilidades

- La app habla únicamente con la API HTTPS de Barrio. No consulta tablas de negocio directamente ni contiene llaves de servidor.
- El backend autentica sesiones, valida entradas y permisos, ejecuta reglas de pedidos, entrega Descubrir y Buscar con Barrio (RAG), consulta Supabase y crea/consulta cobros con pey.
- Postgres es la fuente de verdad de catálogo, disponibilidad, pedidos y pagos. El backend impone autorización por comprador o negocio.
- El webhook de pey valida firma, idempotencia y monto; puede actualizar el pedido una sola vez. La app observa el estado por consulta o canal en tiempo real autenticado.

```text
App ──HTTPS + sesión──► API Barrio ──service credential──► Postgres
                               ├──► OpenAI (solo interpretación asistida)
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

## Contrato HTTP inicial (v1)

Prefijo `/api/v1`; JSON UTF-8; errores con `{ "error": { "code": "...", "message": "...", "field": "..." } }`. IDs opacos, timestamps ISO 8601, importes enteros en centavos (`amount_minor`) para evitar redondeo. Paginación por cursor. Todas las escrituras sensibles requieren sesión y autorización del recurso.

| Método y ruta | Uso |
|---|---|
| `GET /discovery` | Inicio tipo marketplace: categorías y carruseles deterministas, con afinidad ligera si hay sesión |
| `GET /catalog/search?q=&zone=&open_now=&category=&cursor=` | Buscar comercios/productos; filtros, orden, motivos de coincidencia |
| `POST /search/agent` | Buscar con Barrio: consulta libre + filtros opcionales; devuelve candidatos recuperados, matches y explicación |
| `POST /discovery/events` | Registrar señal explícita `search`, `view`, `save` u `order` de la sesión; nunca acepta precio/estado |
| `GET /businesses/{business_id}` | Perfil público y catálogo disponible |
| `POST /orders/quotes` | Validar artículos/cantidades contra precios vigentes y devolver cotización con caducidad |
| `POST /orders` | Crear pedido desde `quote_id` e idempotency key; exige confirmación explícita del resumen |
| `GET /orders`, `GET /orders/{order_id}` | Pedidos propios (comprador) o del negocio; el código de recogida solo se ve al comprador desde `pagada` |
| `POST /me`, `GET /me/profile` | Alta del comprador de la sesión (nombre, 10 dígitos para el push); perfil con insignias y avance |
| `GET /me/notifications`, `POST /coupons/{id}/accept\|decline` | Avisos de cupones; al aceptar, se autoaplica en las cotizaciones de ese negocio |
| `GET/POST /business/coupons`, `DELETE /business/coupons/{id}` | El negocio publica cupones (porcentaje o monto, mínimo, vencimiento); se avisa solo a quien ya pagó un pedido ahí |
| `POST /orders/{order_id}/reject` | Rechazo del negocio asignado |
| `POST /webhooks/pey` | Webhook de pey (firma Standard Webhooks, dedupe por `webhook-id`) |
| `POST /internal/sweep` | Barrido con `CRON_SECRET`: reconciliación con pey, vencimientos, cancelación a 8 min |
| `POST /orders/{order_id}/cancel` | Cancelar solo en estados permitidos, mediante transición atómica |
| `POST /orders/{order_id}/accept` | Aceptación autenticada del negocio asignado |
| `POST /orders/{order_id}/ready` | Marcar listo por el negocio asignado |
| `POST /orders/{order_id}/payments` | Iniciar intento de cobro si no hay otro vigente; devolver instrucciones/link/QR |
| `GET /orders/{order_id}/payments/current` | Consultar estado de cobro autorizado |

El endpoint de cotización calcula precios y total desde catálogo del servidor. La creación conserva una copia del nombre/precio/cantidad para auditoría. `POST /orders` nunca acepta como autoridad un total calculado por el cliente o el modelo. Las operaciones repetibles usan `Idempotency-Key` y devuelven el resultado original para la misma clave.

### Estados y pagos

Conservar y formalizar la máquina de estados existente en migraciones/código. Toda transición usa compare-and-set (estado anterior esperado); solo se crea otro intento de cobro cuando el anterior vence. Un webhook firmado es idempotente y solo confirma si la referencia corresponde y el monto pagado cubre el pedido. Un proceso de reconciliación consulta a pey como respaldo. La respuesta al cliente no revela datos bancarios ni secretos.

Implementado en `20261107020000_pedidos_pagos_promos.sql`: `intentos_cobro` y `eventos_webhook`; no reutiliza `ordenes.pey_ref` como historial. Un intento guarda vía, referencia de pey, monto en centavos, vencimiento, estado e idempotency key. Una restricción parcial impide dos intentos vigentes por pedido. El webhook persiste primero su identificador para deduplicar, localiza el intento por referencia, valida monto y actualiza con condición de estado. Un pago tardío de un intento vencido requiere revisión; nunca confirma automáticamente un intento nuevo.

### Seguridad mínima

- Elegir proveedor de identidad antes de implementar login; almacenar sujetos externos como ID de aplicación, no como teléfono implícitamente confiable.
- Roles comprador/negocio y autorización por objeto en cada ruta.
- Límites de tamaño, validación de esquema, rate limits y logs sin credenciales ni datos de pago sensibles.
- CORS limitado a los orígenes de la app/web publicados; TLS obligatorio; secretos solo en el entorno del servidor.
- El webhook usa verificación criptográfica del cuerpo original y protección contra repetición.
- El prompt declara que la entrada de la persona es dato, no instrucción. El agente solo recibe candidatos recuperados y no tiene herramientas de escritura ni acceso a pagos.

## Esquema cerrado (migración `20261107030000_cerrar_schema.sql`)

- **compradores:** `sujeto_auth` (FK a `auth.users`, `on delete set null`: borrar la cuenta conserva pedidos), `nombre`, `telefono` (10 dígitos, para el push CoDi), `zona` (alcaldía), `colonia`, `latitud/longitud` (ambas o ninguna), `actualizado`.
- **negocios:** `sujeto_auth` (dueño en la app), `nombre`, `descripcion`, `imagen_url` (https), `zona` (alcaldía; validada para filas nuevas), `colonia`, `direccion`, `latitud/longitud`, `categoria`, `productos`, `auto_aceptar`, `abierto`, `verificado` + `verificado_en`, `pey_bank_account_id`. Un trigger deja `verificado = false` si no hay dueño (`sujeto_auth` o `wa_jid` heredado), también al borrar la cuenta. El alta pública (anon) sigue naciendo sin verificar ni dueño.
- Corrige un fallo del RAG: el trigger del documento de catálogo ahora es `security definer`; sin eso el registro público (anon) fallaba por permisos.
- Índices de catálogo, pedidos por negocio/estado, cobros vigentes y avisos sin leer; `limpiar_efimeros()` (webhooks > 30 días, cotizaciones vencidas) corre en el barrido.
- Pruebas: `supabase/tests/schema_smoke.sql` (invariantes y RLS) se ejecuta en CI con `supabase/tests/run.sh` sobre un Postgres con pgvector.

## Cupones e insignias

- **Cupón:** `cupones` (negocio) → `cupon_canjes` por comprador (`ofrecido → aceptado → usado`, una vez por persona) + `notificaciones`. Al publicarlo se ofrece solo a compradores con un pedido `pagada`/`lista` en ese negocio. `POST /orders/quotes` elige el mejor cupón **aceptado** del negocio y lo resta en el servidor (`descuento_minor`, total mínimo $1); `POST /orders` lo marca `usado` con compare-and-set y vuelve a `aceptado` si el pedido se cancela, rechaza o expira. El cobro usa el total ya descontado.
- **Insignias:** derivadas de pedidos pagados, sin tabla: 3 en la misma colonia, 5 en la misma alcaldía o 3 en el mismo negocio (`REGLAS_INSIGNIAS` en `backend/src/pedidos.js`). `GET /me/profile` devuelve también las que van en progreso. Requiere `negocios.colonia`.
- `negocios.sujeto_auth` liga la sesión de Supabase Auth con el negocio (rol negocio); `compradores.sujeto_auth`, con el comprador.

## Entrega por etapas

1. Acordar proveedor de sesión, forma de ubicación, estados visibles y payloads con el responsable de la app.
2. Crear `backend/` como servicio separado y mover/adaptar la lógica de dominio reutilizable fuera del adaptador WhatsApp.
3. Implementar primero Descubrir, búsqueda determinista, perfil y catálogo; después RAG/agente, cotización/pedido; luego aceptación del negocio y pagos.
4. Migrar registro web a llamadas al backend, sin insertar directamente desde navegador con la llave pública.
5. Agregar OpenAI como modo asistido y fallback probado; nunca bloquear búsqueda por el modelo.
6. Desplegar `dev`, validar integración en `stg` y promover a `main` mediante PR.

La primera versión del contrato no decide aún autenticación, geolocalización ni pesos del ranking. Esos acuerdos son bloqueos explícitos de implementación; no introducir decisiones silenciosas en la app.
