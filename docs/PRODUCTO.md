# Barrio — Pide en tu barrio y paga con CoDi, por WhatsApp

> Documento de producto · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Equipo: 4 personas · Stack: OpenAI + Supabase + CoDi vía API de pey
> Identidad visual: `DESIGN.md` · Voz: `VOZ-DE-MARCA.md` · Guía para agentes: `../AGENTS.md`
> **Este archivo es la fuente de verdad del producto.** Si el código o cualquier otro documento lo contradice, se corrige aquí primero.
> Estado: definición vigente (decisiones abiertas marcadas con 🟡)

---

## 1. Resumen

**Barrio** conecta a la gente con los negocios de su barrio por **WhatsApp**, con **voz o texto**, y reduce a lo mínimo el uso de **CoDi**.

La persona le dice a Barrio qué quiere ("10 tacos de canasta, por Coyoacán"). Barrio encuentra el negocio, le muestra la cuenta con el total y, con un solo "sí", le avisa al negocio. El negocio responde "sí" (o 👍, o ni eso si activó la aceptación automática) y a la persona le llega un **cobro CoDi directo a la app de su banco**. Lo aprueba, le llega un código para recoger, y el dinero llega al negocio **al instante y sin comisión**.

Nadie instala nada: todo ocurre en el WhatsApp que ya usan.

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
| **Lupita**, compradora | Quiere comer o resolver algo cerca, ya tiene app de banco, no quiere bajar otra app | Pedir hablando, ver el total antes, pagar con un toque |
| **Don Beto**, tiendita de abarrotes | Atiende solo, manos ocupadas, celular Android de gama media | Que el pedido llegue con la cuenta hecha y responder "sí" |
| **Mari**, puesto de quesadillas | Fila en la hora pico, mucho ruido | Aceptación automática; cobro sin dar cambio |
| **Chuy**, taller mecánico en su cochera | Cobros grandes, ruido de herramientas | Responder por nota de voz; cuenta desglosada y clara |

Quien compra **no instala nada y no se registra**: su nombre sale de su perfil de WhatsApp y su teléfono, del número desde el que escribe.

## 5. Alcance

### MVP para el hackathon (lo que se muestra en la demo)

1. **Pedir por WhatsApp con voz o texto.** Las notas de voz se transcriben y entran al mismo agente que el texto. Si la persona mandó voz, la respuesta llega en texto y en nota de voz.
2. **Descubrimiento:** datos fijos (alcaldía, abierto/cerrado) filtran en SQL; la búsqueda semántica (RAG con pgvector) ordena. Una sola recomendación a la vez.
3. **Cuenta con total calculado por el sistema** a partir del menú del negocio. Un solo "¿Lo pido?".
4. **Negocio responde con 5 palabras** (`sí`, `no`, `listo`, `hoy`, `cerrar`/`abrir`), escritas o por voz, o con un 👍 al mensaje del pedido. Opcional: aceptación automática.
5. **Cobro CoDi por push** al número del comprador (respaldos: link de pago de pey y después QR), confirmación de pago por webhook de pey y, si falla, consultando a pey cada 30 s, y código de recogida.
6. **Recordatorios y cancelación automática** (el negocio no contesta, la persona no aprueba el cobro).
7. **Landing y registro de negocios** (GitHub Pages) con menú y precios.
8. **Resumen del día** para el negocio: escribe `hoy` y recibe total, número de cobros y lo que más salió.

### Después del hackathon

- **Barrio Mostrador:** la idea original del equipo. El dueño dicta o escribe lo que le pidieron en su local y sale un QR CoDi. Reutiliza todo lo construido: el catálogo, el cálculo de la cuenta, `/codi/qr` y el webhook.
- Alta de menú por foto (descartada para el MVP: poco confiable hoy).
- Cuentas CoDi propias por negocio (`pey_bank_account_id`): el registro con Banxico tarda ~5 días hábiles.
- Envíos a domicilio, pedidos en grupo, varios empleados por negocio, fiado, inventario, facturación.

## 6. Flujos

### 6.1 Pedido y pago

```
Lupita (texto o nota de voz)
   │  "10 tacos de canasta, por Coyoacán"
   ▼
Barrio busca (SQL: abierto + alcaldía → pgvector: lo más parecido)
   │  recomienda UNA opción
   ▼
Resumen (el total lo calcula el código, no el modelo)
   │  *Tacos Doña Lupe* · 10 × Taco de canasta — $120 · *Total: $120*
   │  "¿Lo pido?"  →  "sí"
   ▼
Negocio recibe el pedido por WhatsApp ── "sí" / 👍 / (automático)
   ▼
pey: cobro CoDi por push al teléfono de Lupita  (respaldos: link de pago, QR)
   ▼
Lupita aprueba en la app de su banco
   ▼
Webhook de pey → Supabase → "¡Pagado!" a los dos + código de 4 dígitos
   ▼
Negocio escribe "listo" → Lupita recibe "Tu pedido ya está listo"
```

### 6.2 Reglas que no dependen del modelo

- **El total sale del menú del negocio**, calculado por código. El modelo solo elige productos y cantidades; si no existen en el menú, se rechaza.
- **El pedido solo sale después de que la persona vio la cuenta y respondió.** El código lo verifica.
- **Los cambios de estado son atómicos:** dos "sí" seguidos no generan dos cobros.
- **Un cobro nuevo solo se genera cuando el anterior ya venció**, nunca dos vivos para el mismo pedido.
- **El webhook verifica la firma, es idempotente y exige que el monto pagado alcance.**
- **Un negocio solo recibe pedidos después de que su WhatsApp le escribe al bot** (prueba de que el número es suyo).
- Lo que escribe la persona son datos, no instrucciones para el modelo.

### 6.3 Tiempos

| Situación | Qué pasa |
|---|---|
| Negocio sin responder, 3 min | Recordatorio al negocio |
| Negocio sin responder, 8 min | Se cancela el pedido y se le ofrece otra opción a la persona |
| Cobro sin aprobar, 5 min | Recordatorio a la persona |
| Cobro sin aprobar, 20 min | Cobro vencido; "¿Te lo mando otra vez?" |
| Falla el push (p. ej. sin CoDi activo) | Se manda un link de pago (CoDi o tarjeta); si también falla, un QR; si todo falla, se avisa y se ofrece reintentar |

### 6.4 Texto y voz son de primer nivel

Las dos entradas llegan al mismo agente. El texto acepta la forma de hablar de la voz (abreviaturas, sin acentos, números en dígitos o letra). Las respuestas siempre llegan también en texto, que se puede releer y lo leen los lectores de pantalla.

## 7. Arquitectura

```
Comprador / Negocio ──WhatsApp──► Bot (Node + Baileys, WhatsApp Web)         [bot/]
                                    ├─ voz → OpenAI transcripción
                                    ├─ agente OpenAI (Responses API + herramientas)
                                    │    perfil y pedidos: SQL  ·  búsqueda: pgvector
                                    └─ cobro ──► pey  POST /codi/pn  (respaldos: /payment-link/create, /codi/qr)
                                                          │
                       banco del comprador: aprobar ◄─────┘
                                │
              pey ──webhook firmado──► Edge Function pey-webhook          [supabase/functions/]
                                         └─ ordenes.estado = 'pagada'
                                                    │ Realtime
                              Bot ◄─────────────────┘  avisa a los dos

Supabase: Postgres + pgvector + Realtime + Edge Functions                   [supabase/]
Landing y registro de negocios: GitHub Pages (HTML estático)                [web/]
```

El bot **no necesita URL pública**: pey avisa a Supabase y Supabase avisa al bot por Realtime. Un barrido cada 30 s recupera avisos perdidos.

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

> **Riesgo #1.** Si no hay API key a tiempo, el bot corre con `PEY_MOCK=1`: cobros falsos con la misma interfaz. Para simular el pago se marca la orden como `pagada` en Supabase. La API key real se conecta después.

### 7.2 Uso de OpenAI

| Tarea | Modelo | Entrada → salida |
|---|---|---|
| Agente (conversación y herramientas) | `gpt-5.4-mini`, razonamiento bajo (`OPENAI_MODEL=gpt-5-mini` si la cuenta no lo tiene) | texto + perfil + pedidos recientes → respuesta o llamada a herramienta |
| Transcripción | `gpt-4o-mini-transcribe` | audio OGG de WhatsApp → texto |
| Voz de respuesta | `gpt-4o-mini-tts` (Opus) | texto → nota de voz |
| Embeddings | `text-embedding-3-small` | descripción del negocio y consulta → vector de 1536 |

Herramientas del agente: `guardar_perfil`, `buscar_negocios`, `cotizar`, `confirmar_pedido`, `cancelar_pedido`, `reintentar_pago`.

## 8. Modelo de datos

Definido en `supabase/migrations/`. Resumen:

```
compradores (id, telefono, wa_jid, nombre, zona, ultima_respuesta)
negocios    (id, nombre, telefono, wa_jid, verificado, zona, direccion, categoria,
             productos[{nombre, precio}], auto_aceptar, abierto, pey_bank_account_id, embedding)
ordenes     (id, comprador_id, negocio_id, items[], notas, monto, codigo,
             estado[pendiente|aceptada|cobrada|pagada|lista|rechazada|expirada|vencida|cancelada],
             wa_msgs[], pey_ref, rastreo, creado, pagada_en)
```

La base garantiza lo importante: precios válidos, montos entre 0 y 1,000,000, teléfonos de 10 dígitos y que la página pública solo pueda registrar negocios sin verificar.

## 9. Superficies

1. **WhatsApp (el producto).** Un solo número para compradores y negocios. El bot distingue a un negocio por su teléfono registrado.
2. **Landing** (`web/index.html`): explica en 10 segundos y lleva a WhatsApp o al registro.
3. **Registro de negocios** (`web/registro.html`): datos, menú con precios y aceptación automática. Al terminar entrega un link para compartir con clientes.

**Criterios de diseño:** botones grandes, una sola acción principal por pantalla, alto contraste, cero jerga financiera (ver `VOZ-DE-MARCA.md`), funciona en Android de gama media y con señal débil.

## 10. Plan de trabajo

🟡 Asignar nombres cuando se reparta el equipo.

| Rol | Responsable | Entregables |
|---|---|---|
| **Pagos / backend** | _ | Integración pey real (push, QR, webhook), Supabase desplegado, número del bot vinculado |
| **IA** | _ | Prompt del agente, búsqueda, set de 20 pedidos de prueba (voz y texto), afinar transcripción |
| **Frontend** | _ | Landing y registro, QR y link por negocio, pruebas en Android real |
| **Producto / pitch** (Alejandro) | Alejandro | Este documento, guion de demo, video, datos del problema |

| Hora | Hito |
|---|---|
| Sáb 14:00 | Proyecto Supabase creado y migración aplicada; bot conectado a WhatsApp y a OpenAI con `PEY_MOCK=1` |
| Sáb 15:30 | **Flujo completo de punta a punta**, aunque sea feo: voz o texto → cuenta → negocio acepta → cobro → pagado |
| Sáb 16:00 | Fin del día presencial; lista de pendientes priorizada |
| Dom 10:00 | pey real conectado y probado con $0.01; landing publicada; pulido |
| Dom 11:30 | Grabación del video demo |
| Dom 13:00 | **Entrega en el portal** |

## 11. Demo (≈2 min)

1. **Problema (20 s):** "Don Beto pierde 4% con terminal o vive del efectivo. CoDi es gratis, pero pedir y cobrar con CoDi cuesta más trabajo que un billete."
2. **Pedido por voz (50 s):** nota de voz → cuenta con total → "sí" → el negocio responde 👍 → cobro en el celular → se aprueba con $0.01 reales → "¡Pagado!" y código.
3. **El negocio (20 s):** escribe `listo`, luego `hoy`: "Hoy vendiste $0.01 en 1 cobro".
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
| WhatsApp Web no es la API oficial; Meta puede bloquear el número | Número secundario, solo responder a quien escribe, sin mensajes masivos; video de respaldo |
| El comprador no tiene CoDi activo en su banco | Link de pago de pey (CoDi o tarjeta) en el mismo celular. Ojo: la comisión de tarjeta no está documentada; no se promete "sin comisión" en ese caso |
| El modelo inventa precios | Total calculado por código y solo productos del menú |
| La nota de voz de respuesta no suena en algún celular | La respuesta siempre llega también en texto |
| Ruido de fondo afecta la transcripción | El texto siempre funciona igual; transcripción dudosa se pide de nuevo |
| Webhook de pey no llega | El bot consulta a pey cada 30 s (`GET /transaction/{id}`) y marca la orden pagada; también se puede marcar a mano en la demo |

## 15. Decisiones

**Tomadas**
- Producto: Barrio por WhatsApp (descubrimiento + pedido + cobro CoDi). Barrio Mostrador queda para después.
- Backend: Supabase (Postgres, pgvector, Realtime, Edge Functions). Landing y registro en GitHub Pages.
- Canal: WhatsApp Web (Baileys), no la API oficial de Meta.
- Modelos: ver §7.2.
- Fuera del MVP: alta de menú por foto.

**Abiertas** 🟡
1. Número de WhatsApp del bot y quién lo escanea.
2. API key de pey, cuenta CoDi de la demo y quién habla con los mentores.
3. Giro estrella para la demo: tiendita, quesadillas o taller. *Propuesta: tiendita, y quesadillas para mostrar la aceptación automática.*
4. Quién prueba con un CoDi real y con un número sin CoDi.
