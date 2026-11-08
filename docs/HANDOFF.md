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
- **API:** corre como Supabase Edge Function `api` (`https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api`, JWT de la función apagado: la API autentica sola). Se empaqueta con `npm run build:edge` en `backend/` y se despliega pegando `supabase/functions/api/index.ts` (no versionado) en el editor del panel. Cubre Descubrir, búsqueda (con o sin modelo), cotización, pedidos, cobros con pey (`intentos_cobro`), webhook `/webhooks/pey`, reconciliación puntual al consultar el cobro, cupones, insignias y gestión del negocio. `render.yaml`/`Dockerfile` quedan como alternativa.
- **Base:** migraciones hasta `20261107050000` aplicadas en producción; `pg_cron` ejecuta `barrido_sql()`. Datos de demo: negocio 7 (Tacos Doña Lupe) y un cupón. Prueba de punta a punta contra la base real: `npm run e2e:live` (pey en mock; 23 pasos). Cobro real de $0.01 por push CoDi verificado.
- **Web:** `web/app.html` + `app.js` (comprador y negocio) consumen la API. La publicación de la web (GitHub Pages) la hace otro integrante; no desplegarla desde aquí. Auth: Site URL y redirects de Supabase apuntan a `https://gpancardo.github.io/proyectoCoDi/`; si la URL cambia, actualizar ambos en Authentication → URL Configuration.
- **Sin verificación manual de negocios:** un negocio queda activo al registrarse con su cuenta.
- **Modelo de IA:** OpenRouter u OpenAI con el mismo código (ver `backend/README.md`); falta cargar `OPENAI_API_KEY` en los secretos de la función y correr `npm run index:catalog`.

## Pendiente

1. Registrar el webhook de pey en `https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api/webhooks/pey` y guardar su secreto como `PEY_WEBHOOK_SECRET`. Existe una Edge Function `pey-webhook` anterior con el esquema viejo; retirarla o repuntar pey.
2. Cargar `OPENAI_API_KEY` (OpenRouter o OpenAI) en Edge Function Secrets y ejecutar `index:catalog`.
3. Registrar una CLABE de [`PEY.md`](PEY.md) en el portal de pey y guardar su `bankAccountId` en `negocios.pey_bank_account_id`.
4. Publicar `web/` (otro integrante) y confirmar que la URL coincide con la de Auth.
5. Acordar ubicación (coordenadas) y pesos del ranking; la app Flutter (`barrio_app_pey/`) aún no consume la API.
6. Entrega: **domingo 8 nov, 1:00 PM**, a hola@aibuilders.lat. Pruebas de pago solo de $0.01 (no se devuelve).

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
