# Handoff

Actualizado: 7 nov 2026. Fuente de producto: [`PRODUCTO.md`](PRODUCTO.md). Arquitectura y contrato de API: [`BACKEND.md`](BACKEND.md).

## Decisión vigente

El producto cambia de WhatsApp a una app standalone desarrollada por otro integrante. La app consume una API HTTPS propia. WhatsApp/Baileys es legado y no debe ampliarse como canal del producto. La búsqueda ofrecerá filtros y coincidencia determinista estilo marketplace; el agente será una ayuda opcional para consultas libres.

## Estado de este checkout

- HEAD local y `origin/main` conocidos: `92798e2`; no pude actualizar referencias remotas.
- `git pull --rebase` no corrió porque hay cambios locales preexistentes. `git fetch` y `git switch -c` tampoco pudieron escribir `.git/FETCH_HEAD`/refs porque `.git` está montado de solo lectura en este entorno.
- Hay modificaciones locales preexistentes en `bot/index.js`, `bot/package.json`, `bot/package-lock.json` y `bot/vincular.js`. Consérvalas, pero no les dediques trabajo de producto: la guía de vinculación QR de WhatsApp quedó obsoleta.
- En esta sesión se actualizaron README, AGENTS, PRODUCTO, DESIGN, VOZ-DE-MARCA y este handoff; se agregó `docs/BACKEND.md`.
- Aún no existe servicio HTTP en `backend/`; no hay contrato implementado ni integración con la app. El backend anterior vive dentro de `bot/index.js` y acopla negocio/pagos a WhatsApp.

## Bloqueos que debe cerrar el equipo

1. Backend y app acuerdan autenticación/sesión y roles comprador/negocio.
2. Acordar forma de ubicación (zona, coordenadas o ambas), datos visibles del negocio y criterios/pesos del ranking.
3. El responsable de backend crea `backend/` y separa reglas de dominio de adaptadores de canal heredados.
4. Implementar API por etapas: búsqueda/catálogo → cotización/creación de pedido → aceptación/estado del negocio → cobros y reconciliación.
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

Usar `feature/<área>-<cambio>` atómicas desde `dev`; abrir PR `feature/* → dev → stg → main`. No trabajar directo en ramas compartidas ni promover sin revisión. Antes de empezar y de subir, revisar `git status`, actualizar con `git pull --rebase` y resolver cualquier trabajo local sin borrarlo. En este checkout, primero se necesita un entorno con `.git` escribible y resolver los cambios locales listados arriba; no intentar commits o ramas aquí.

## Próximo corte recomendado

El siguiente cambio técnico debe ser una feature branch acordada para **API de catálogo y búsqueda determinista**, con filtros validados y ranking explicable. Incluir contrato concreto, esquema/índices si hacen falta, endpoint y datos de ejemplo. Después conectar agente opcional sin hacerlo requisito de búsqueda. El pago se integra cuando autenticación y ciclo de pedido estén definidos.

No se ejecutaron pruebas: este cambio fue documentación y el repo aún no tiene la API nueva.
