# Guía de trabajo

Lee primero [`docs/PRODUCTO.md`](docs/PRODUCTO.md) y luego [`docs/BACKEND.md`](docs/BACKEND.md) (incluye estado desplegado y pendientes). Producto es la fuente de verdad; arquitectura concreta del servidor está en BACKEND.

## Producto y arquitectura

Barrio será una app standalone que consume una API HTTPS propia. WhatsApp/Baileys ya no es canal del producto. El cliente no accede a tablas directamente ni contiene secretos. El backend mantiene catálogo, identidad/autorización, pedidos y pagos; OpenAI es opcional para interpretar búsquedas y nunca determina precios, disponibilidad ni totales.

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
| `backend/` | API standalone pendiente de crear |
| `supabase/` | esquema, webhook de pey, seed y migraciones |
| `web/` | landing/registro existentes; requieren adaptación al nuevo backend |
| `bot/` | código heredado acoplado a WhatsApp; referencia temporal para reglas e integración, no interfaz del producto |
| `docs/` | producto, contrato y estado del backend, pey, diseño y voz |

## Comprobaciones existentes

El CI actual revisa el paquete heredado `bot/`. No agregues rutas al README como si la API ya existiera. Cuando se cree `backend/`, añade scripts de comprobación del servicio y ajústalos en `.github/workflows/ci.yml`.
