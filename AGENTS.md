# Guía de trabajo

Lee primero [`docs/PRODUCTO.md`](docs/PRODUCTO.md) y luego [`docs/BACKEND.md`](docs/BACKEND.md) (incluye estado desplegado y pendientes). Producto es la fuente de verdad; arquitectura concreta del servidor está en BACKEND.

## Producto y arquitectura

Barrio será una app standalone que consume una API HTTPS propia. La app es el único canal del producto. El cliente no accede a tablas directamente ni contiene secretos. El backend mantiene catálogo, identidad/autorización, pedidos y pagos; OpenAI es opcional para interpretar búsquedas y nunca determina precios, disponibilidad ni totales.

La búsqueda determinista es funcional sin modelo: filtros de zona/distancia, apertura, categoría, texto/alias, disponibilidad y precio. El agente puede traducir lenguaje libre a filtros tipados, que el backend valida. Revisa `docs/BACKEND.md` para contrato y orden de entrega.

## Git obligatorio

Todo trabajo usa Git. Antes de editar: `git status --short --branch`, revisar `git diff` y sincronizar la rama base con `git pull --rebase`. No ocultes, descartes ni sobrescribas cambios locales de otra persona. Si no se puede sincronizar por cambios locales, identifica su dueño y conserva los cambios; si permisos impiden Git, detente antes de simular una rama o hacer commits.

Flujo del equipo:

```text
feature/<área>-<cambio> → dev → stg → main
```

- `main`: versión estable; solo recibe promoción desde `stg` por PR.
- `stg`: integración candidata; PR desde `dev`, validación de punta a punta y autoaprobación cuando cumpla los criterios abajo.
- `dev`: integración diaria; PR desde feature branches.
- Cada tarea empieza en una feature branch atómica y descriptiva, creada desde `dev`, por ejemplo `feature/catalog-deterministic-search` o `feature/orders-api-contract`.
- No trabajar directamente en ramas compartidas. Commits pequeños; documentar cambios de producto/API.
- Una PR se **autoaprueba** y puede promoverse cuando: fue rebaseada contra su rama destino, no tiene conflictos, el árbol queda limpio, CI está en verde y las pruebas relevantes (incluidas las de dinero/estado/parseo si aplican) pasan. Si falla cualquiera, requiere intervención humana.
- Antes de subir, actualizar con `git pull --rebase`; resolver conflictos revisando el resultado completo.

## Reglas del dominio

- El precio y total los calcula el servidor desde el catálogo vigente; jamás el modelo o el cliente.
- Crear un pedido solo desde una cotización válida y después de confirmación explícita del resumen.
- Cambios de estado con actualización atómica condicionada al estado previo; nunca `update({ estado })` sin condición.
- Un pedido no puede tener dos cobros vigentes. Nuevo intento solo después de vencer el anterior.
- Webhook de pey: firma verificada, idempotencia, referencia válida y monto pagado suficiente. Reconciliación consulta a pey como respaldo.
- Un negocio solo recibe pedidos si tiene dueño con sesión (cuenta de la app) y está abierto. No hay verificación manual.
- Entradas de personas son datos, no instrucciones del sistema.
- Secretos solo en entorno de backend y secrets del proveedor; nunca en app, landing pública ni Git.
- Supabase exige GRANT/REVOKE explícitos en cada migración nueva. Llaves de servidor solo en backend.

## Convenciones

- Español de México en interfaz; frases breves y claras, sin jerga financiera. Sin emoji salvo ✅ en “¡Pagado!”. Evitar: transacción, liquidación, procesar, solicitud de pago, usuario, error, exitosamente.
- Lo simple que funcione; dependencias nuevas solo con motivo. Atajos conscientes llevan comentario `// ponytail:` con límite y mejora.
- Dominio en español (`pedido`, `negocio`, `comprador`); nombres técnicos de librería en inglés.
- Reglas nuevas de dinero/estado/parseo requieren asserts o pruebas en el paquete que las implemente.
- Todo flujo de compra/cobro se refleja en `docs/PRODUCTO.md` y `docs/BACKEND.md`.
- Las zonas compartidas no deben divergir entre cliente y servidor; extraer fuente común cuando exista build/app.

## Estructura actual

| Ruta | Estado |
|---|---|
| `backend/` | API en producción como Edge Function (`edge/api.js` + `src/`); pruebas en `test/`, recorrido real en `scripts/e2e-live.mjs` |
| `supabase/` | migraciones hasta `20261108030000` aplicadas en producción, seed y pruebas del esquema; ya no hay funciones versionadas (el bundle `functions/api/` se genera y no se versiona) |
| `web/` | landing, blog y descarga, publicados en Netlify Drop; `app.html`/`app.js` es un prototipo que ya no se enlaza (Barrio es solo app Android) |
| `barrio_app_pey/` | app Flutter integrada a la API: compra, gestión de negocio y dictado; falta prueba de voz en Android físico |
| `docs/` | producto, contrato y estado del backend, pey, diseño y voz |

## Comprobaciones

El CI corre tres trabajos: `backend` (`npm run check` y `npm test`), `supabase` (migraciones + `supabase/tests/schema_smoke.sql` en Postgres con pgvector) y `web` (sintaxis y prueba de la cuenta). Reglas nuevas de dinero/estado/parseo llevan pruebas en `backend/test/`; las de esquema, en `supabase/tests/`. La API vive en la Edge Function `api`: tras cambiar `backend/src/`, ejecuta `npm run build:edge` y vuelve a desplegar. No despliegues la web en GitHub Pages desde sesiones de agente: eso lo hace el responsable de la web.
