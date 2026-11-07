# Backend de Barrio

> Estado: contrato inicial para el backend y la app standalone. Aún no hay API HTTP desplegada. Antes de programar rutas, el responsable de la app y el del backend deben cerrar este contrato en una feature branch.

## Responsabilidades

- La app habla únicamente con la API HTTPS de Barrio. No consulta tablas de negocio directamente ni contiene llaves de servidor.
- El backend autentica sesiones, valida entradas y permisos, ejecuta reglas de pedidos, integra OpenAI como ayuda opcional, consulta Supabase y crea/consulta cobros con pey.
- Postgres es la fuente de verdad de catálogo, disponibilidad, pedidos y pagos. El backend impone autorización por comprador o negocio.
- El webhook de pey valida firma, idempotencia y monto; puede actualizar el pedido una sola vez. La app observa el estado por consulta o canal en tiempo real autenticado.

```text
App ──HTTPS + sesión──► API Barrio ──service credential──► Postgres
                               ├──► OpenAI (solo interpretación asistida)
                               └──► pey ──webhook firmado──► estado del pedido
```

No se debe exponer `SUPABASE_SECRET_KEY`, `PEY_API_KEY` ni `OPENAI_API_KEY` al cliente. No se debe autorizar al cliente a cambiar estados de orden directamente.

## Búsqueda del catálogo

La búsqueda devuelve comercios y productos publicables cercanos, combinando métodos deterministas con la búsqueda asistida. Las rutas deterministas son la ruta normal y funcionan sin OpenAI.

1. **Filtros exactos en SQL:** texto/categoría, zona o coordenadas, abierto ahora, disponibilidad, rango de precio y restricciones del usuario. Estos filtros siempre se aplican antes de ordenar resultados.
2. **Orden estable inspirado en marketplaces:** disponibilidad, distancia, coincidencia de texto/categoría, calidad/completitud del catálogo y señales operativas. Definir pesos con producto; desempate estable por `negocio_id` y producto. No usar pagos ni datos sensibles para ranking.
3. **Búsqueda textual determinista:** normalización de acentos/caso, alias explícitos y `tsvector`/trigramas en nombre, categoría y producto. Retornar por qué coincide.
4. **Agente como complemento:** interpreta frases libres y puede proponer términos, categorías o filtros estructurados. Su salida es solo una consulta tipada; el backend valida, limita y ejecuta. El agente no inventa artículos, disponibilidad ni precios y no calcula totales.
5. **Fallback:** ante timeout o indisponibilidad del modelo, mostrar resultados deterministas, categorías y filtros navegables.

Cada resultado incluye `match_reasons`, distancia si existe, estado de apertura/disponibilidad y datos necesarios para decidir. Evitar personalización opaca en el MVP; hacer el orden explicable y reproducible.

## Contrato HTTP inicial (v1)

Prefijo `/api/v1`; JSON UTF-8; errores con `{ "error": { "code": "...", "message": "...", "field": "..." } }`. IDs opacos, timestamps ISO 8601, importes enteros en centavos (`amount_minor`) para evitar redondeo. Paginación por cursor. Todas las escrituras sensibles requieren sesión y autorización del recurso.

| Método y ruta | Uso |
|---|---|
| `GET /catalog/search?q=&zone=&open_now=&category=&cursor=` | Buscar comercios/productos; filtros, orden, motivos de coincidencia |
| `GET /businesses/{business_id}` | Perfil público y catálogo disponible |
| `POST /orders/quotes` | Validar artículos/cantidades contra precios vigentes y devolver cotización con caducidad |
| `POST /orders` | Crear pedido desde `quote_id` e idempotency key; exige confirmación explícita del resumen |
| `GET /orders/{order_id}` | Leer pedido si la sesión tiene acceso |
| `POST /orders/{order_id}/cancel` | Cancelar solo en estados permitidos, mediante transición atómica |
| `POST /orders/{order_id}/accept` | Aceptación autenticada del negocio asignado |
| `POST /orders/{order_id}/ready` | Marcar listo por el negocio asignado |
| `POST /orders/{order_id}/payments` | Iniciar intento de cobro si no hay otro vigente; devolver instrucciones/link/QR |
| `GET /orders/{order_id}/payments/current` | Consultar estado de cobro autorizado |

El endpoint de cotización calcula precios y total desde catálogo del servidor. La creación conserva una copia del nombre/precio/cantidad para auditoría. `POST /orders` nunca acepta como autoridad un total calculado por el cliente o el modelo. Las operaciones repetibles usan `Idempotency-Key` y devuelven el resultado original para la misma clave.

### Estados y pagos

Conservar y formalizar la máquina de estados existente en migraciones/código. Toda transición usa compare-and-set (estado anterior esperado); solo se crea otro intento de cobro cuando el anterior vence. Un webhook firmado es idempotente y solo confirma si la referencia corresponde y el monto pagado cubre el pedido. Un proceso de reconciliación consulta a pey como respaldo. La respuesta al cliente no revela datos bancarios ni secretos.

### Seguridad mínima

- Elegir proveedor de identidad antes de implementar login; almacenar sujetos externos como ID de aplicación, no como teléfono implícitamente confiable.
- Roles comprador/negocio y autorización por objeto en cada ruta.
- Límites de tamaño, validación de esquema, rate limits y logs sin credenciales ni datos de pago sensibles.
- CORS limitado a los orígenes de la app/web publicados; TLS obligatorio; secretos solo en el entorno del servidor.
- El webhook usa verificación criptográfica del cuerpo original y protección contra repetición.

## Entrega por etapas

1. Acordar proveedor de sesión, forma de ubicación, estados visibles y payloads con el responsable de la app.
2. Crear `backend/` como servicio separado y mover/adaptar la lógica de dominio reutilizable fuera del adaptador WhatsApp.
3. Implementar primero búsqueda determinista, perfil y catálogo; después cotización/pedido; luego aceptación del negocio y pagos.
4. Migrar registro web a llamadas al backend, sin insertar directamente desde navegador con la llave pública.
5. Agregar OpenAI como modo asistido y fallback probado; nunca bloquear búsqueda por el modelo.
6. Desplegar `dev`, validar integración en `stg` y promover a `main` mediante PR.

La primera versión del contrato no decide aún autenticación, geolocalización ni pesos del ranking. Esos acuerdos son bloqueos explícitos de implementación; no introducir decisiones silenciosas en la app.
