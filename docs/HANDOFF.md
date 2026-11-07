# Handoff — backend de Barrio

Actualizado: 7 nov 2026. Fuente de producto: [`PRODUCTO.md`](PRODUCTO.md). Contrato y arquitectura: [`BACKEND.md`](BACKEND.md).

## Estado en una frase

Ya existe un primer backend HTTP para Descubrir y Buscar con Barrio: la búsqueda combina RAG y agente para encontrar y explicar matches, con filtros/ranking deterministas como autoridad y fallback sin modelo. **Aún no está listo el backend de la app para operar pedidos ni cobros por API**: faltan identidad/roles y autorización, cotización/pedido, superficie de negocio, integración de pey, webhook robusto y despliegue conectado a la app.

## Qué está hecho

- `backend/` es un servicio Node HTTP con `GET /health`, `GET /api/v1/discovery`, `GET /api/v1/catalog/search`, `POST /api/v1/search/agent` y `POST /api/v1/discovery/events`.
- Descubrir y búsqueda determinista funcionan sin OpenAI. El agente interpreta consultas a filtros estructurados, intenta recuperar negocios por embeddings y ordena/explica candidatos; ante falla usa búsqueda determinista.
- La migración `20261107011000_app_discovery_rag.sql` agrega los datos y funciones iniciales de descubrimiento/RAG. `backend/src/index-catalog.js` indexa documentos de catálogo.
- Existe la app Flutter en `barrio_app_pey/` y una Edge Function heredada para webhook de pey. **Su existencia no significa que estén integradas o listas para producción**.
- `docs/BACKEND.md` describe rutas de cotización, pedidos, gestión del negocio y pagos como contrato; esas rutas no están implementadas en `backend/src/server.js`.

## Qué falta, en orden de impacto

### P0 — Completar el flujo vertical de compra y pey

1. **Identidad y permisos:** validar sesión del proveedor elegido en todas las rutas, mapearla a comprador o negocio y autorizar por recurso. Hoy `persona()` resuelve comprador para señales, pero el resto de rutas de lectura es público y no hay roles ni sesión de negocio.
2. **Cotización y pedido:** implementar `POST /orders/quotes`, `POST /orders`, `GET /orders/{id}` y cancelación. Cotizar siempre desde catálogo vigente; la app presenta el resumen y envía confirmación explícita; crear desde cotización no vencida e idempotency key. Guardar snapshot de artículos y total en centavos.
3. **Gestión del negocio y estados:** alta/verificación y rutas autenticadas para aceptar/rechazar/marcar listo; validar negocio abierto y verificado. Aplicar cada transición atómicamente condicionada al estado previo. Definir expiración, autoaceptación y lectura/actualización del pedido por la app.
4. **Cobro con pey:** crear adaptador real en backend (push CoDi → link → QR como respaldos), persistir `intentos_cobro` y `eventos_webhook`, y evitar más de un intento vigente por pedido. Guardar referencia, monto menor, vencimiento, vía e idempotency key. No declarar pagado desde una respuesta del cliente.
5. **Webhook y reconciliación:** verificar firma sobre cuerpo original, deduplicar evento, validar referencia e importe suficiente, y confirmar con transición atómica e idempotente. No buscar/actualizar directamente por `ordenes.pey_ref` como historial único. Añadir consulta periódica a pey para reparar eventos perdidos y política para pagos tardíos.
6. **Código de recogida y estados de cara a la app:** emitir/mostrar código solo después de pago confirmado; definir polling autenticado inicial (o canal realtime con autorización), cancelación por tiempo y mensajes de fallo/reintento.

### P1 — Hacer utilizable el backend existente

- **Integrar la app Flutter** con base URL configurable, token de sesión y DTOs acordados; conectar Descubrir, búsqueda, eventos, detalle público, cotización, pedido y estados. La app no debe consultar tablas de Supabase directamente ni llevar secretos.
- **Alinear y probar contrato:** actualmente hay contrato más amplio que las rutas implementadas. Mantener tabla de rutas con estado real y pruebas de integración para los flujos felices y denegados.
- **RAG y agente:** ejecutar el indexador después de publicar cambios de catálogo; probar frescura e invalidación. Agregar conjunto de consultas esperadas, evaluación de recall/matches y límites de latencia/costo. Actualmente se consulta vector store, se mezclan filtros y el orden final sigue basado en ranking determinista, pero hace falta validar calidad con catálogo representativo.
- **Búsqueda/descubrimiento de producción:** validar esquemas de filtros y límites, alias/fuzzy text, zona/distancia real, horario, disponibilidad, paginación/cursor y desempates estables. Verificar que perfil y eventos respeten sesión, privacidad y reglas de retención.
- **Operación del servicio:** incorporar scripts/CI para backend, pruebas de rutas, configuración CORS por origen, límites de solicitudes, logs estructurados sin datos sensibles, timeouts, métricas y manejo de errores sin exponer información interna.
- **Migraciones y RLS:** aplicar migraciones en proyecto Supabase de desarrollo, comprobar grants/revokes y políticas; probar con sesión real y credencial de servidor separada. No editar migraciones ya aplicadas: agregar una nueva.
- **Despliegue e integración continua:** desplegar API HTTPS por ambiente, gestionar secretos en el proveedor, configurar URL de webhook de pey y conectar la app al ambiente de staging antes de producción.
- **Landing/registro:** `web/` es prototipo; adaptar altas y catálogo para usar API/backend y no permitir escrituras directas desde navegador.

### P2 — Preparación de lanzamiento

- Prueba punta a punta en staging: búsqueda → cotización → confirmación → aceptación → intento pey → webhook/reconciliación → “¡Pagado!” → listo.
- Probar idempotencia, eventos duplicados, timeout de pey, intento vencido, importe insuficiente, usuario ajeno, negocio cerrado/no verificado, caída de OpenAI y caída de embeddings.
- Hacer una prueba real de importe mínimo únicamente con credenciales y cuenta habilitadas por el equipo; pey no ofrece sandbox según el documento de producto. Mantener cualquier simulación claramente identificada como simulación.

## Restricciones que no se negocian

- El servidor calcula precio y total desde el catálogo vigente; ni cliente ni agente son autoridad monetaria.
- Un pedido solo nace desde cotización válida después de que la persona confirma el resumen.
- Cambios de estado con compare-and-set; nunca actualizar estado sin condición previa.
- Un solo cobro vigente por pedido. Webhook firmado, idempotente, con referencia correcta y monto suficiente; reconciliar consultando a pey.
- Negocio no recibe pedidos si no está verificado y abierto. Toda acción de negocio requiere sesión y autorización del negocio asignado.
- Texto de búsqueda es dato, no instrucción. El agente solo recibe candidatos recuperados; no escribe ni opera pagos.
- Secretos solo en backend/secrets del proveedor. Cada migración Supabase nueva declara GRANT/REVOKE explícitos.

## Siguiente entrega recomendada

Crear desde `dev` una rama atómica `feature/backend-orders-pey` y entregar primero un flujo vertical mínimo, no más superficie aislada: autenticación/propiedad → cotización → pedido → aceptación del negocio → intento pey → webhook idempotente → consulta del estado en app. Si no caben todos los pasos, dejar contratos y pruebas para cada borde y no presentar pagos simulados como reales.

Antes de conectar pey real, el equipo necesita tener el proyecto Supabase de desarrollo, credenciales de API/webhook de pey y endpoint HTTPS configurado. Sin esos insumos se puede implementar y probar adaptador/mock local aislado, pero no certificar el flujo real.

## Estado Git y cuidado del checkout

- La rama `dev` incluye el PR #19 (`feature/backend-rag-ready`), que incorporó el primer corte de backend/RAG.
- En el checkout original había cambios locales sin commit en `bot/index.js`, `bot/package.json`, `bot/package-lock.json` y `bot/vincular.js`. Son ajenos a este handoff; conservarlos y no mezclarlos con trabajo de app/backend.
- Este documento reemplaza el handoff antiguo en su ruta canónica `docs/HANDOFF.md`; no se encontró otro archivo handoff. Se conserva este archivo porque `AGENTS.md` pide leerlo como punto de entrada.
- Flujo del equipo: `feature/* → dev → stg → main` mediante PR. Autoaprobar/promover solo con árbol limpio, rebase al destino, sin conflictos y CI/pruebas relevantes verdes; ante cualquier fallo, intervención humana.
