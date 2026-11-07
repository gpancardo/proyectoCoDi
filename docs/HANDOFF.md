# Handoff

Actualizado: 7 nov 2026. Fuente de producto: [`PRODUCTO.md`](PRODUCTO.md). Arquitectura y contrato de API: [`BACKEND.md`](BACKEND.md).

## Decisión vigente

El producto cambia de WhatsApp a una app standalone desarrollada por otro integrante. La app consume una API HTTPS propia. WhatsApp/Baileys es legado y no debe ampliarse como canal del producto. La búsqueda ofrecerá filtros y coincidencia determinista estilo marketplace; el agente será una ayuda opcional para consultas libres.

## Estado de este checkout

- GitHub está operativo. Las ramas oficiales son `main`, `dev` y `stg`. Producto y reglas Git están en `main`; cada cambio se promueve con PR y CI.
- Usa merge commits en las promociones para conservar la relación de historial, sobre todo cuando una rama agrega archivos que también se agregaron en otra.
- `develop` y `staging` son aliases retirados; si un workspace viejo los vuelve a publicar, verifica que no tengan commits propios antes de borrarlos. `landing` y `Diseño/-Landing-alex` conservan código exclusivo de un prototipo Astro; confirmar con sus responsables antes de integrarlas o borrarlas.
- Hay cambios locales sin commit en `bot/index.js`, `bot/package.json`, `bot/package-lock.json` y `bot/vincular.js`. Consérvalos; el ajuste de vinculación QR de WhatsApp quedó obsoleto.
- Se actualizaron README, AGENTS, PRODUCTO, DESIGN, VOZ-DE-MARCA y este handoff; se agregó `docs/BACKEND.md`.
- `backend/` contiene el primer corte HTTP de Descubrir y Buscar con Barrio: catálogo determinista, perfil por señales explícitas, RAG acotado y fallback sin OpenAI. Rama `feature/backend-orders-payments-promos` agrega cotización/pedidos, gestión del negocio, cobros con pey (`intentos_cobro`), webhook propio, barrido, cupones e insignias; la Edge Function `pey-webhook` se retiró porque el backend la reemplaza. **Probado solo con pruebas unitarias y un import de arranque, no contra Supabase/pey reales.** Faltan despliegue, aplicar la migración, apuntar el webhook de pey a `/webhooks/pey` e integrar la app.

## Bloqueos que debe cerrar el equipo

1. Backend y app acuerdan autenticación/sesión y roles. Hoy: Supabase Auth; comprador se da de alta con `POST /me`; el negocio se liga con `negocios.sujeto_auth` (falta el flujo de alta/verificación sin WhatsApp).
2. Acordar forma de ubicación (zona, coordenadas o ambas), datos visibles del negocio y criterios/pesos del ranking.
3. Mantener el índice de catálogo al día: ejecutar `backend` `index:catalog` tras cambios de menú desde un entorno con secretos.
4. Probar de punta a punta en `dev` el flujo pedido → aceptación → cobro → webhook → "¡Pagado!" con `PEY_MOCK=1` y luego con pey real ($0.01).
5. Adaptar `web/` para que altas y consultas pasen por backend; no dejar llave de servidor en cliente.
6. Definir actualización de estado para app (polling autenticado inicialmente o canal en tiempo real autorizado).

Contrato propuesto y rutas: [`BACKEND.md`](BACKEND.md). Ninguna ruta se debe presentar como implementada hasta que exista y esté integrada.

## Reglas que se conservan

- El servidor calcula importes desde catálogo/precios vigentes; el modelo y el cliente no deciden totales.
- Confirmación explícita del resumen antes de crear el pedido.
- Transiciones atómicas con estado previo esperado. Nunca dos cobros vigentes por pedido.
- Webhook de pey con firma verificada, idempotencia, referencia válida y monto suficiente; reconciliar con consulta a pey.
- Acceso por sesión y dueño del recurso; secretos solo en servidor.
- Migraciones nuevas con GRANT/REVOKE explícitos. No modificar migraciones ya aplicadas.

## Git y ramas

Usar `feature/<área>-<cambio>` atómicas desde `dev`; abrir PR `feature/* → dev → stg → main`. No trabajar directo en ramas compartidas. La PR se autoaprueba y puede promoverse si fue rebaseada contra su destino, no tiene conflictos, el árbol está limpio y CI/pruebas relevantes pasan; cualquier falla exige intervención humana. Antes de empezar y de subir, revisar `git status`, actualizar con `git pull --rebase` y resolver cualquier trabajo local sin borrarlo. Conserva primero los cuatro cambios locales en `bot/` o pide a su responsable que los guarde en una rama propia.

## Próximo corte recomendado

El siguiente cambio técnico debe ser una feature branch acordada para **API de catálogo y búsqueda determinista**, con filtros validados y ranking explicable. Incluir contrato concreto, esquema/índices si hacen falta, endpoint y datos de ejemplo. Después conectar agente opcional sin hacerlo requisito de búsqueda. El pago se integra cuando autenticación y ciclo de pedido estén definidos.

Las promociones documentales pasaron CI. No se ejecutaron pruebas locales adicionales. El repo aún no tiene la API nueva.
