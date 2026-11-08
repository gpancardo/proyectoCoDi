# Barrio — Encuentra negocios de tu barrio y paga con CoDi

> Documento de producto · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Equipo: 4 personas · Stack: app standalone + API propia + Supabase + CoDi vía API de pey
> Identidad visual: `DESIGN.md` · Voz: `VOZ-DE-MARCA.md` · Guía para agentes: `../AGENTS.md`
> **Este archivo es la fuente de verdad del producto.** Si el código o cualquier otro documento lo contradice, se corrige aquí primero.
> Estado: definición vigente (decisiones abiertas marcadas con 🟡)

---

## 1. Resumen

**Barrio** conecta a la gente con negocios cercanos desde una **aplicación standalone**. La app ofrece dos puertas: **Descubrir**, un recorrido tradicional tipo Uber Eats, y **Buscar con Barrio**, un agente con RAG que encuentra coincidencias del catálogo real y las explica. La API propia cotiza y pide; pey permite cobrar con CoDi. WhatsApp deja de ser canal del producto.

La persona busca "10 tacos de canasta, por Coyoacán", compara opciones y elige un negocio. Barrio muestra una cotización calculada por el servidor; al confirmar, el negocio recibe el pedido en su superficie de gestión. Al aceptar, llega un **cobro CoDi a la app del banco**. La persona lo aprueba, recibe un código para recoger y el negocio ve el pago confirmado.

La persona usa una app dedicada, diseñada para buscar y comprar de forma directa. La app y el backend se desarrollan como componentes separados por integrantes distintos del equipo.

## 2. Problema

La economía de barrio está formada por unidades económicas pequeñas, creadas por y para los habitantes de una misma localidad: tiendas de abarrotes, misceláneas, puestos de comida, talleres caseros, estéticas.

- **Viven del efectivo.** Las terminales cobran comisión (≈3–4% más IVA), piden renta o equipo, y el depósito tarda días.
- **Sus clientes no los encuentran fuera de la cuadra**, y los pedidos por WhatsApp se anotan a mano, sin total claro y sin forma ágil de cobrar.
- **CoDi ya resuelve el pago** (gratis, instantáneo, cualquier banco), pero nunca despegó en el comercio pequeño porque pedir y cobrar con CoDi sigue dando más trabajo que dar o recibir un billete. Ese es el hueco.

## 3. Por qué ahora

- La **Ley de Economía Digital para Pagos Digitales y Electrónicos** entró en vigor el 5 de nov de 2026.
- La **Circular 9/2026 de Banxico** obliga a los bancos a homologar las transferencias móviles antes del **14 de dic de 2026**.
- **pey** abrió una API de CoDi gratuita, agnóstica al banco, que deposita directo en la cuenta del comercio.

🟡 Las dos primeras cifras vienen de la investigación inicial del equipo. Verificar la fuente antes del pitch.

## 4. Usuarios

| Persona | Contexto | Qué necesita |
|---|---|---|
| **Lupita**, compradora | Quiere comer o resolver algo cerca y pagar desde su banco | Encontrar opciones, comparar, ver el total antes y pagar con un toque |
| **Don Beto**, tiendita de abarrotes | Atiende solo, manos ocupadas, celular Android de gama media | Recibir pedidos claros y actualizar su disponibilidad |
| **Mari**, puesto de quesadillas | Fila en la hora pico, mucho ruido | Aceptación automática; cobro sin dar cambio |
| **Chuy**, taller mecánico en su cochera | Cobros grandes, varias cotizaciones | Revisar pedidos y mostrar una cuenta desglosada y clara |

La app requiere una sesión de comprador. Su perfil de descubrimiento aprende solo de señales explícitas: búsquedas, vistas, guardados y pedidos. No usa datos de pago ni deja que el agente infiera atributos sensibles.

## 5. Alcance

### MVP para el hackathon (lo que se muestra en la demo)

1. **Descubrir en la app:** inicio navegable tipo Uber Eats con categorías, carruseles y negocios abiertos; zona, disponibilidad, apertura y rango de precio.
2. **Buscar con Barrio:** un agente interpreta la consulta, recupera candidatos del catálogo (RAG) y devuelve matches explicables. Los filtros deterministas siguen siendo la autoridad y siempre están disponibles.
3. **Cuenta con total calculado por el sistema** a partir del menú del negocio. Un solo "¿Lo pido?".
4. **El negocio gestiona el pedido** desde una superficie autenticada y actualiza aceptación, preparación y disponibilidad. Opcional: aceptación automática.
5. **Cobro CoDi** al comprador (respaldos: link de pago de pey y después QR), confirmación por webhook y reconciliación consultando a pey, y código de recogida.
6. **Recordatorios y cancelación automática** (el negocio no contesta, la persona no aprueba el cobro).
7. **Landing y registro de negocios** (GitHub Pages) con menú y precios.
8. **Promociones:** el negocio publica cupones; la app avisa a quien ya compró ahí y, si los acepta, se descuentan solos al cobrar. **Insignias** en el perfil por comprar varias veces en la misma colonia, alcaldía o negocio.
9. **Resumen del día** para el negocio: total, número de cobros y productos más vendidos en su panel.

### Después del hackathon

- **Barrio Mostrador:** la idea original del equipo. El dueño dicta o escribe lo que le pidieron en su local y sale un QR CoDi. Reutiliza todo lo construido: el catálogo, el cálculo de la cuenta, `/codi/qr` y el webhook.
- Alta de menú por foto (descartada para el MVP: poco confiable hoy).
- Cuentas CoDi propias por negocio (`pey_bank_account_id`): el registro con Banxico tarda ~5 días hábiles.
- Envíos a domicilio, pedidos en grupo, varios empleados por negocio, fiado, inventario, facturación.

## 6. Flujos

### 6.1 Pedido y pago

```
Lupita (app)
   │  busca "tacos de canasta", filtra por Coyoacán y compara
   ▼
La API busca (filtros deterministas + relevancia textual; agente opcional)
   │  recomienda UNA opción
   ▼
Resumen (el total lo calcula el código, no el modelo)
   │  *Tacos Doña Lupe* · 10 × Taco de canasta — $120 · *Total: $120*
   │  total visible → confirmar pedido
   ▼
Negocio recibe el pedido en su superficie de gestión ── acepta / rechaza
   ▼
pey: cobro CoDi por push al teléfono de Lupita  (respaldos: link de pago, QR)
   ▼
Lupita aprueba en la app de su banco
   ▼
Webhook firmado de pey → estado guardado → la app muestra "¡Pagado!" + código de recogida
   ▼
Negocio marca "Listo" → la app muestra el estado a Lupita
```

### 6.2 Reglas que no dependen del modelo

- **El total sale del menú del negocio**, calculado por código. El modelo solo elige productos y cantidades; si no existen en el menú, se rechaza.
- **El pedido solo sale después de que la persona vio la cuenta y respondió.** El código lo verifica.
- **Los cambios de estado son atómicos:** dos "sí" seguidos no generan dos cobros.
- **Un cobro nuevo solo se genera cuando el anterior ya venció**, nunca dos vivos para el mismo pedido.
- **El webhook verifica la firma, es idempotente y exige que el monto pagado alcance.**
- **Un negocio solo recibe pedidos si tiene dueño con sesión y está abierto** (sin verificación manual), y cada acción se autoriza contra su sesión.
- Lo que escribe la persona son datos, no instrucciones para el modelo.

### 6.3 Tiempos

| Situación | Qué pasa |
|---|---|
| Negocio sin responder, 3 min | Aviso en la app al negocio |
| Negocio sin responder, 8 min | Se cancela el pedido y se le ofrecen otras opciones a la persona |
| Cobro sin aprobar, 5 min | Recordatorio en la app |
| Cobro sin aprobar, 20 min | Cobro vencido; opción para generar otro intento |
| Falla el push (p. ej. sin CoDi activo) | Se manda un link de pago (CoDi o tarjeta); si también falla, un QR; si todo falla, se avisa y se ofrece reintentar |

### 6.4 Descubrimiento, perfil y búsqueda con Barrio

**Descubrir** permite navegar aunque no se escriba nada: categorías y carruseles de negocios abiertos. El orden base es estable y visible; el perfil solo da un impulso leve a categorías que la persona buscó, vio, guardó o pidió antes.

**Buscar con Barrio** sigue esta secuencia: consulta libre → filtros tipados → recuperación de fragmentos del catálogo → ranking determinista → explicación breve. El agente recibe únicamente esos candidatos; no puede inventar un negocio, precio, producto, disponibilidad ni total. Si el modelo, embeddings o recuperación fallan, la API usa búsqueda textual y filtros sobre el catálogo completo. La app comunica por qué aparece cada match y permite corregir filtros.

## 7. Arquitectura

```
Web (web/app.html) y app Flutter ──HTTPS──► API Barrio = Supabase Edge Function `api`   [backend/]
                                    ├─ Descubrir: categorías/ranking determinista (siempre)
                                    ├─ Buscar con Barrio: modelo opcional → filtros tipados validados (+ RAG si hay llave)
                                    ├─ pedidos, cupones, insignias: reglas de dominio + Postgres
                                    └─ cobro ──► pey POST /codi/pn (respaldos: /payment-link/create, /codi/qr)
                                                          │
                       banco del comprador: aprobar ◄─────┘
                                │
              pey ──webhook firmado──► POST /webhooks/pey (misma función)
                                         └─ intentos_cobro 'pagado' → ordenes.estado = 'pagada'
                                                    │ la app consulta el pedido (polling)
                              Web/App ◄─────────────┘  muestra "¡Pagado!" y el código

Supabase: Postgres + Auth + pg_cron (barrido_sql) + Realtime de avisos + bucket de imágenes   [supabase/]
Web estática: publicada por otro integrante                                                    [web/]
```

El backend expone una API HTTPS autenticada. El cliente no usa credenciales de servidor ni escribe directamente en tablas. El webhook y la reconciliación mantienen el estado de pago; la app consulta el pedido o recibe cambios por un canal autenticado.

Contrato de rutas y responsabilidades: [`BACKEND.md`](BACKEND.md).

### 7.1 Integración con pey

Referencia: **docs.pey.mx** (OpenAPI en `docs.pey.mx/openapi.json`, versión 2026-10-20). Base: `https://api.pey.mx`, autenticación `Authorization: Bearer <api-key>`.

| Qué | Endpoint | Campos clave |
|---|---|---|
| Cobro por push | `POST /codi/pn` | `amount` (pesos), `phoneNumber` (10 dígitos), `concept`, `expiration` (s, mín. 360), `numRef` (1–7 dígitos), `metadata` → `{transactionId, codiId}` |
| Cobro por QR | `POST /codi/qr` | `amount`, `generateImage: true` → `{id, qrString, qrImage (PNG base64)}` |
| Link de pago | `POST /payment-link/create` | `amount`, `successUrl`, `backUrl`, `clientReferenceId`, `metadata` → `{id, url}`; acepta CoDi y tarjeta |
| Estado del cobro | `GET /transaction/{id}`, `GET /transaction/codi/qr/{id}`, `GET /payment-link/{id}` | `status` `PENDING`/`PAID` (link: `pending`/`processing`/`paid`/`partial`) |
| Webhook | `codi.pn.payment_received`, `codi.qr.payment_received` | `amount`, `transactionId`, `codiQrId` (solo QR), `datePaid`, `metadata.trackingKey` |

- Los webhooks usan **Standard Webhooks** (`webhook-id`, `webhook-timestamp`, `webhook-signature`). El secreto `whsec_…` se ve al crear el webhook en portal.mipey.mx → Desarrollador. Un webhook por API key.
- **pey no tiene entorno de pruebas** ("próximamente"). Los organizadores piden probar con **un centavo ($0.01)**; se hace en producción. Pey habilitó CLABEs pre-autorizadas para el hackathon; instrucciones, reglas de prueba y entrega en [`PEY.md`](PEY.md).
- Dar de alta una cuenta CoDi propia por negocio tarda ~5 días hábiles. Para la demo, todos los cobros caen en la cuenta ligada a la API key.
- 🟡 **Confirmar con los mentores de pey:** si existe un entorno de desarrollo para el hackathon, cómo simular un pago, y si el push falla de forma explícita cuando el número no tiene CoDi activo.

> **Riesgo #1.** Si no hay API key a tiempo, el backend debe usar un adaptador de pagos simulado en desarrollo; nunca presentar una simulación como pago real. Para pruebas locales, aislar esos datos del proyecto de producción.

### 7.2 Uso del modelo (OpenAI u OpenRouter)

| Tarea | Modelo | Entrada → salida |
|---|---|---|
| Interpretación y explicación de búsqueda | `OPENAI_MODEL` (por defecto `gpt-4o-mini`; en OpenRouter `openai/gpt-4o-mini`) | consulta libre + candidatos recuperados → filtros/categorías tipados y explicación breve |
| Recuperación semántica | `OPENAI_EMBEDDING_MODEL` (`text-embedding-3-small`, 1536 dimensiones) | documento de catálogo → vector; consulta → candidatos de catálogo |

El agente no confirma pedidos, accede a secretos, altera estados ni calcula importes. Tampoco escribe el perfil: el backend registra señales tipadas y construye afinidades por categoría. El backend ejecuta toda consulta validada y las operaciones de dominio.

## 8. Modelo de datos

Definido en `supabase/migrations/` (detalle de columnas y restricciones en [`BACKEND.md`](BACKEND.md)). Resumen:

```
compradores (id, sujeto_auth→auth.users, nombre, telefono, zona, colonia, latitud, longitud)
negocios    (id, sujeto_auth, nombre, descripcion, imagen_url, zona, colonia, direccion, latitud, longitud, categoria,
             productos[{nombre, precio}], auto_aceptar, abierto, verificado, pey_bank_account_id)
catalogo_documentos (negocio_id, contenido, embedding)      perfiles_descubrimiento / eventos_descubrimiento
cotizaciones (id, comprador_id, negocio_id, items[], subtotal_minor, descuento_minor, total_minor, canje_id, expira)
ordenes     (id, comprador_id, negocio_id, items[], monto, descuento_minor, codigo, cotizacion_id, idempotency_key, canje_id,
             estado[pendiente|aceptada|cobrada|pagada|lista|rechazada|expirada|vencida|cancelada], pagada_en)
intentos_cobro (id, orden_id, via[push|link|qr], pey_ref, monto_minor, vence, estado[vigente|pagado|vencido|fallido|revision], instrucciones)
eventos_webhook (id)                                         cupones / cupon_canjes / notificaciones
```

Las insignias no tienen tabla: se calculan de los pedidos pagados. `ordenes.pey_ref`/`pey_via` y `wa_*` son heredados del bot y ya no se usan.

## 9. Superficies

1. **Web de la app** (`web/app.html`): comprador (descubrir, buscar, cuenta, pedido, pago, avisos, perfil con insignias) y negocio (pedidos, promociones, menú, abrir/cerrar). Un solo archivo JS sin build.
2. **App Flutter** (`barrio_app_pey/`): en construcción por otro integrante; aún no consume la API.
3. **Landing** (`web/index.html`): cartel de calle con changarrito 3D que explica el producto y lleva a `app.html`. `web/registro.html` solo redirige a la app, donde se registra el negocio con cuenta.

**Criterios de diseño:** botones grandes, una sola acción principal por pantalla, alto contraste, cero jerga financiera (ver `VOZ-DE-MARCA.md`), funciona en Android de gama media y con señal débil.

## 10. Plan de trabajo

🟡 Asignar nombres cuando se reparta el equipo.

| Rol | Responsable | Entregables |
|---|---|---|
| **Backend** | _ | API autenticada, catálogo/búsqueda, pedidos y pagos con pey; estados y permisos |
| **IA / búsqueda** | _ | Filtros deterministas, ranking explicable y agente opcional con fallback |
| **App** | _ | App standalone de comprador y gestión de negocio; integración por contrato |
| **Producto / pitch** (Alejandro) | Alejandro | Este documento, guion de demo, video, datos del problema |

| Hora | Hito |
|---|---|
| Sáb 14:00 | Contrato app/API y autenticación acordados; backend conectado a Supabase |
| Sáb 15:30 | **Flujo completo de punta a punta**: búsqueda → cotización → aceptación → cobro → pagado |
| Sáb 16:00 | Fin del día presencial; lista de pendientes priorizada |
| Dom 10:00 | pey real conectado y probado con $0.01; landing publicada; pulido |
| Dom 11:30 | Grabación del video demo |
| Dom 13:00 | **Entrega en el portal** |

## 11. Demo (≈2 min)

1. **Problema (20 s):** "Don Beto pierde 4% con terminal o vive del efectivo. CoDi es gratis, pero pedir y cobrar con CoDi cuesta más trabajo que un billete."
2. **Descubrimiento y pedido (50 s):** buscar, filtrar por zona, comparar negocios → cuenta con total → confirmar → el negocio acepta → cobro en el celular → aprobar $0.01 → "¡Pagado!" y código.
3. **El negocio (20 s):** acepta el pedido, lo marca listo y ve el resumen del día.
4. **Cierre (30 s):** sin comisión, sin instalar nada, replicable a cada barrio.

## 12. Impacto y modelo

- **Bien público:** el comercio de barrio vende más allá de su cuadra, cobra digital sin comisión, recibe su dinero al instante y empieza a tener registro de ventas (primer paso hacia crédito formal).
- **Para pey:** cada negocio que usa Barrio es un comercio nuevo generando volumen en su API.
- **Sostenibilidad:** el cobro es gratis siempre. A futuro, un plan de pago bajo para funciones extra (reportes, varios empleados, envíos).

## 13. Métricas de éxito (de la demo)

- **Del pedido al pago: menos de 90 s** (se mide con `ordenes.creado` y `ordenes.pagada_en`).
- Mensajes de la persona hasta pagar: **2** (pedir y "sí").
- Pedidos de prueba interpretados correctamente: **≥ 9 de 10**, dictados y escritos.
- Un pago real confirmado en pantalla durante la demo.

## 14. Riesgos

| Riesgo | Mitigación |
|---|---|
| No hay API key de pey a tiempo, y pey no tiene sandbox | `PEY_MOCK=1`; conectar el real el domingo y probar con $0.01 |
| API y app aún no están implementadas | Reducir alcance a contrato v1, búsqueda, pedido y pago; priorizar un flujo vertical funcional |
| El comprador no tiene CoDi activo en su banco | Link de pago de pey (CoDi o tarjeta) en el mismo celular. Ojo: la comisión de tarjeta no está documentada; no se promete "sin comisión" en ese caso |
| El modelo inventa precios | El agente solo propone filtros; total calculado por backend y productos del menú |
| El agente no interpreta una consulta | Mantener filtros deterministas, búsqueda textual y categorías como fallback |
| Webhook de pey no llega | Backend reconcilia con pey (`GET /transaction/{id}`) y actualiza el pedido idempotentemente |

## 15. Decisiones

**Tomadas**
- Producto: app standalone para descubrir, pedir y pagar con CoDi.
- Canal: app → API HTTPS propia. WhatsApp deja de ser canal del producto.
- Descubrimiento: navegación estilo marketplace con personalización ligera, explicable y basada en señales explícitas.
- Búsqueda: RAG y agente para encontrar y explicar matches del catálogo; filtros deterministas como autoridad y fallback.
- Datos: Supabase/Postgres; pey para cobros. El servidor es dueño de las credenciales y reglas de pedidos.
- App y backend son tareas separadas que se coordinan mediante `BACKEND.md`.
- Sesión y roles: Supabase Auth; comprador automático, negocio por registro. Sin verificación manual de negocios.
- Promociones: cupones del negocio autoaplicados al cobro tras aceptarlos; insignias por colonia, alcaldía o negocio.
- Hosting: API y base en Supabase (Edge Function); web estática publicada por otro integrante.
- Fuera del MVP: alta de menú por foto.

**Abiertas** 🟡
1. Ubicación por distancia en el ranking (las coordenadas ya se guardan) y pesos finales.
2. Cuenta CoDi propia por negocio (`pey_bank_account_id`) y registro de una CLABE de prueba en el portal de pey.
3. Webhook de pey registrado en `/webhooks/pey` y retiro de la función `pey-webhook` anterior.
4. Llave de modelo (OpenRouter u OpenAI) y primer `index:catalog`.
5. Integración de la app Flutter y publicación de la web.
