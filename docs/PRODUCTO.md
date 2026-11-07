# Barrio — Encuentra negocios de tu barrio y paga con CoDi

> Documento de producto · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Equipo: 4 personas · Stack: app standalone + API propia + Supabase + CoDi vía API de pey
> Identidad visual: `DESIGN.md` · Voz: `VOZ-DE-MARCA.md` · Guía para agentes: `../AGENTS.md`
> **Este archivo es la fuente de verdad del producto.** Si el código o cualquier otro documento lo contradice, se corrige aquí primero.
> Estado: definición vigente (decisiones abiertas marcadas con 🟡)

---

## 1. Resumen

**Barrio** conecta a la gente con negocios cercanos desde una **aplicación standalone**. La app consulta una API propia para explorar, cotizar y pedir; pey permite cobrar con CoDi. WhatsApp deja de ser canal del producto.

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

La app requiere una sesión de comprador. El mecanismo de identidad y los datos mínimos de perfil se definirán en el contrato de backend antes de implementarlos.

## 5. Alcance

### MVP para el hackathon (lo que se muestra en la demo)

1. **Explorar en la app:** búsqueda, categorías, zona/distancia, disponibilidad, apertura y rango de precio; resultados comparables inspirados en apps de reparto.
2. **Búsqueda híbrida:** filtros y coincidencias deterministas siempre disponibles; el agente opcional interpreta consultas libres, y su salida estructurada se valida en servidor.
3. **Cuenta con total calculado por el sistema** a partir del menú del negocio. Un solo "¿Lo pido?".
4. **El negocio gestiona el pedido** desde una superficie autenticada y actualiza aceptación, preparación y disponibilidad. Opcional: aceptación automática.
5. **Cobro CoDi** al comprador (respaldos: link de pago de pey y después QR), confirmación por webhook y reconciliación consultando a pey, y código de recogida.
6. **Recordatorios y cancelación automática** (el negocio no contesta, la persona no aprueba el cobro).
7. **Landing y registro de negocios** (GitHub Pages) con menú y precios.
8. **Resumen del día** para el negocio: total, número de cobros y productos más vendidos en su panel.

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
- **Un negocio solo recibe pedidos si está verificado y abierto**, y cada acción se autoriza contra su sesión.
- Lo que escribe la persona son datos, no instrucciones para el modelo.

### 6.3 Tiempos

| Situación | Qué pasa |
|---|---|
| Negocio sin responder, 3 min | Aviso en la app al negocio |
| Negocio sin responder, 8 min | Se cancela el pedido y se le ofrecen otras opciones a la persona |
| Cobro sin aprobar, 5 min | Recordatorio en la app |
| Cobro sin aprobar, 20 min | Cobro vencido; opción para generar otro intento |
| Falla el push (p. ej. sin CoDi activo) | Se manda un link de pago (CoDi o tarjeta); si también falla, un QR; si todo falla, se avisa y se ofrece reintentar |

### 6.4 Búsqueda clara y accesible

La búsqueda ofrece categorías y filtros deterministas además de texto libre. El agente puede traducir lenguaje natural a filtros tipados, pero su indisponibilidad nunca bloquea explorar o comprar. La app comunica apertura, distancia, disponibilidad y coincidencias sin esconder el criterio del orden.

## 7. Arquitectura

```
App standalone ──HTTPS──► Backend Barrio [backend/]
                                    ├─ búsqueda determinista SQL (siempre)
                                    ├─ agente OpenAI opcional → filtros tipados validados
                                    ├─ pedidos y pagos: reglas de dominio + SQL
                                    └─ cobro ──► pey POST /codi/pn (respaldos: /payment-link/create, /codi/qr)
                                                          │
                       banco del comprador: aprobar ◄─────┘
                                │
              pey ──webhook firmado──► Backend / Edge Function             [supabase/functions/]
                                         └─ ordenes.estado = 'pagada'
                                                    │ API / canal autenticado
                              App ◄─────────────────┘  muestra el estado

Supabase: Postgres + funciones de búsqueda/webhook                           [supabase/]
Landing y registro de negocios: GitHub Pages (HTML estático)                [web/]
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
- **pey no tiene entorno de pruebas** ("próximamente"). Los organizadores piden probar con **un centavo ($0.01)**; se hace en producción. Pey publica una CLABE de prueba en sus docs.
- Dar de alta una cuenta CoDi propia por negocio tarda ~5 días hábiles. Para la demo, todos los cobros caen en la cuenta ligada a la API key.
- 🟡 **Confirmar con los mentores de pey:** si existe un entorno de desarrollo para el hackathon, cómo simular un pago, y si el push falla de forma explícita cuando el número no tiene CoDi activo.

> **Riesgo #1.** Si no hay API key a tiempo, el backend debe usar un adaptador de pagos simulado en desarrollo; nunca presentar una simulación como pago real. Para pruebas locales, aislar esos datos del proyecto de producción.

### 7.2 Uso de OpenAI

| Tarea | Modelo | Entrada → salida |
|---|---|---|
| Interpretación asistida de búsqueda | Modelo del backend, por configurar | consulta libre → filtros/categorías tipados para validar en servidor |

El agente no confirma pedidos, accede a secretos, altera estados ni calcula importes. El backend ejecuta toda consulta validada y las operaciones de dominio.

## 8. Modelo de datos

Definido en `supabase/migrations/`. Resumen:

```
compradores (id, sujeto_auth, nombre, zona)
negocios    (id, nombre, contacto, verificado, zona, direccion, categoria,
             productos[{nombre, precio}], auto_aceptar, abierto, pey_bank_account_id, embedding)
ordenes     (id, comprador_id, negocio_id, items[], notas, monto, codigo,
             estado[pendiente|aceptada|cobrada|pagada|lista|rechazada|expirada|vencida|cancelada],
             pey_ref, rastreo, creado, pagada_en)
```

El modelo actual de Supabase conserva campos heredados de WhatsApp. La migración al contrato nuevo debe sustituirlos por identidad de aplicación y permisos por rol sin debilitar las restricciones de precio, monto o verificación del negocio.

## 9. Superficies

1. **App standalone:** búsqueda, catálogo, cotización, pedidos y estado de pago; gestión para negocios.
2. **Landing** (`web/index.html`): prototipo legado; requiere actualización para explicar y enlazar la app.
3. **Registro de negocios** (`web/registro.html`): prototipo legado; debe enviar el alta al backend antes de volver a usarse.

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
- Búsqueda: filtros deterministas y coincidencia explicable, más agente opcional para lenguaje libre.
- Datos: Supabase/Postgres; pey para cobros. El servidor es dueño de las credenciales y reglas de pedidos.
- App y backend son tareas separadas que se coordinan mediante `BACKEND.md`.
- Fuera del MVP: alta de menú por foto.

**Abiertas** 🟡
1. Proveedor de identidad y modelo de sesión/roles para comprador y negocio.
2. Ubicación: zona, coordenadas, permiso y fallback manual.
3. Pesos y explicación del orden de resultados; campos disponibles del catálogo.
4. API key de pey, cuenta CoDi de demo y responsable de probar $0.01.
5. Responsable de migrar el registro web legado al backend.
