# Barrio — Cobro por voz o texto con CoDi para el comercio de barrio

> Documento de producto · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Equipo: 4 personas · Stack: OpenAI + CoDi vía API de pey
> Estado: **borrador para discusión** (las decisiones abiertas están marcadas con 🟡)

---

## 1. Resumen

**Barrio** es una app web móvil para que el dueño de una tiendita, un puesto de comida, un taller casero o una estética cobre con CoDi **hablando o escribiendo como habla**, sin calcular totales ni tener terminal.

El dueño dice o escribe *"dos cocas de seiscientos y unas sabritas"*. La IA arma la cuenta con los precios de su negocio, muestra el total y genera un **QR CoDi**. El cliente lo escanea con la app de su banco, paga, y el dinero llega **al instante, sin comisión**, directo a la cuenta del negocio. La venta queda registrada sola.

## 2. Problema

La economía de barrio está formada por unidades económicas pequeñas, creadas por y para los habitantes de una misma localidad: tiendas de abarrotes, misceláneas, puestos de comida callejera, talleres mecánicos caseros, estéticas.

Comparten varios problemas:

- **Viven del efectivo.** Las terminales cobran comisión (≈3–4% más IVA), piden renta o equipo, y el depósito tarda días.
- **No llevan registro.** No saben cuánto vendieron en el día ni qué les deja más.
- **Tienen poco tiempo y poca paciencia para apps.** Atienden con las manos ocupadas y no van a capturar productos ni montos en un formulario.

CoDi ya resuelve el pago (gratis, instantáneo, cualquier banco), pero **nunca despegó en el comercio pequeño** porque generar un cobro sigue dando más trabajo que recibir un billete. Ese es el hueco.

## 3. Por qué ahora

- La **Ley de Economía Digital para Pagos Digitales y Electrónicos** entró en vigor el 5 de nov de 2026.
- La **Circular 9/2026 de Banxico** obliga a los bancos a homologar las transferencias móviles antes del **14 de dic de 2026**.
- **pey** abrió una API de CoDi gratuita, agnóstica al banco, que deposita directo en la cuenta del comercio.

Del lado del cliente pagar con el celular ya está resuelto. Falta que **cobrar** sea igual de fácil para quien vende.

## 4. Usuarios

| Persona | Contexto | Qué necesita |
|---|---|---|
| **Don Beto**, tiendita de abarrotes | Atiende solo, manos ocupadas, celular Android de gama media | Cobrar rápido sin calcular, saber cuánto vendió |
| **Mari**, puesto de quesadillas | Fila en la hora pico, mucho ruido, cambio siempre escaso | QR al momento, sin dar cambio; escribir cuando no se oye |
| **Chuy**, taller mecánico en su cochera | Cobros grandes (refacciones + mano de obra), ruido de herramientas | Cobro desglosado y claro para el cliente |
| **Cliente del barrio** | Tiene app de banco, no quiere bajar otra app | Escanear y pagar, nada más |

El cliente final **no instala nada**: paga desde la app de su banco.

## 5. Alcance

### MVP para el hackathon (lo que se muestra en la demo)

1. **Cobro por voz o por texto → QR CoDi.** El dueño elige cómo capturar: dicta o escribe en lenguaje natural. Ambos caminos llegan al mismo intérprete, a la misma cuenta desglosada y al mismo QR.
2. **Confirmación de pago en vivo** vía webhook de pey ("✅ Pagado $47").
3. **Catálogo mínimo** del negocio (10–20 productos con precio) que la IA usa para armar la cuenta.
4. **Resumen del día**: total cobrado, número de ventas, producto más vendido.

### Si alcanza el tiempo

5. **Alta de catálogo por foto**: el dueño toma foto de su lista de precios o de su anaquel y la IA crea el catálogo.

### Fuera de alcance

- Fiado o cuentas por cobrar a clientes.
- Inventario, facturación (CFDI), devoluciones, multiusuario, app nativa.
- Pagos con tarjeta o efectivo.
- Producción real con dinero de terceros (la demo usa el entorno de desarrollo de pey).

## 6. Flujos

### 6.1 Cobro (flujo principal de la demo)

```
Dueño elige cómo capturar el pedido
        │
        ├── 🎙️ Voz: toca el micrófono y dicta
        │         │
        │         ▼
        │   [Transcripción] OpenAI speech-to-text
        │         │
        └── ⌨️ Texto: escribe como habla ("2 cocas 600 y sabritas")
                  │
                  ▼
        "dos cocas de seiscientos y unas sabritas"
                  │
                  ▼
[Interpretación] OpenAI con structured output + catálogo del negocio
        │  [{Coca 600ml ×2 = $36}, {Sabritas ×1 = $19}]  total $55
        ▼
Pantalla de confirmación (el dueño puede corregir con un toque, volver a dictar o reescribir)
        │  "Cobrar $55"
        ▼
[Backend] → API pey: crear cobro CoDi (monto, concepto, referencia)
        │
        ▼
QR en pantalla grande  ──►  Cliente escanea con su app bancaria y autoriza
                                     │
[Webhook pey] ◄──────────────────────┘
        │  valida firma, marca venta como pagada
        ▼
Pantalla "✅ Pagado $55" + sonido
```

**Reglas:**
- **Voz y texto son entradas de primer nivel.** Los dos están siempre visibles en la pantalla principal; ninguno está escondido en un menú. En lugares con ruido (puesto en hora pico, taller) el dueño escribe; con las manos ocupadas, dicta.
- El texto acepta la misma forma de hablar que la voz: abreviaturas, números en dígitos o en letra, sin acentos ni ortografía cuidada ("2 cocas 600", "una sabrita", "cobrame 120").
- Si la transcripción sale con baja confianza o vacía (por ruido), la app lo dice y pone el texto transcrito en la caja editable para que el dueño lo corrija escribiendo, en lugar de interpretar algo equivocado.
- Si la IA no reconoce un producto, lo marca como *"sin precio"* y pide el monto en vez de inventarlo.
- El dueño **siempre confirma** el total antes de generar el QR. La IA propone, el humano decide.
- Si la entrada es solo un monto ("cóbrame 120"), se salta el catálogo y genera el QR directo.

### 6.2 Resumen del día

Tarjeta fija con total cobrado, número de ventas y top 3 productos. Si alcanza el tiempo, preguntas en lenguaje natural (por voz o texto): *"¿cuánto vendí hoy?"*, *"¿qué se vendió más?"*.

## 7. Arquitectura

```
┌──────────────────────┐        ┌──────────────────────────┐        ┌───────────┐
│  Web app móvil (PWA) │ HTTPS  │  Backend (Node/Express)  │  REST  │  API pey  │
│  - grabar audio      │──────► │  - /transcribe           │──────► │  CoDi     │
│  - caja de texto     │        │  - /parse-order          │        └─────┬─────┘
│  - confirmar cuenta  │        │  - /charges              │              │
│  - mostrar QR        │ ◄──────│  - /webhooks/pey  ◄──────┼──────────────┘
│  - estado del pago   │  SSE / │  - /summary              │   webhook firmado
└──────────────────────┘ polling└──────────┬───────────────┘
                                           │
                              ┌────────────┴────────────┐
                              │  OpenAI API             │   DB: SQLite o Supabase
                              │  - speech-to-text       │
                              │  - structured outputs   │
                              └─────────────────────────┘
```

`/transcribe` solo se usa en el camino de voz. El texto escrito va directo a `/parse-order`. Así el intérprete es uno solo y se prueba una vez.

🟡 **Decisiones abiertas de stack** (definir con el equipo según quién programa qué):
- Frontend: Next.js vs. HTML + JS simple. *Propuesta: Next.js si alguien lo domina; si no, Vite + React.*
- Backend: rutas API de Next.js vs. Express separado. *Propuesta: rutas de Next.js, un solo repo y un solo deploy.*
- DB: SQLite local vs. Supabase. *Propuesta: Supabase si necesitamos deploy público para la demo.*
- Deploy: Vercel / Railway. El webhook necesita URL pública (para desarrollo local, usar un túnel tipo ngrok).
- Estado del pago en el front: polling cada 2 s (simple) vs. SSE. *Propuesta: polling.*

### 7.1 Integración con pey

Referencia: **docs.pey.mx**. Pasos según pey:
1. Crear una API key del entorno de desarrollo en el portal.
2. Implementar la solicitud de cobro (genera QR con monto y concepto).
3. Registrar la URL del webhook y validar la firma con el secreto del webhook.

🟡 **Por confirmar con los mentores de pey hoy mismo:**
- Nombres exactos de endpoints, payload y formato del QR (¿imagen, string EMV o liga?).
- Límites del entorno de desarrollo y si se puede simular un pago para la demo.
- Formato y eventos del webhook.

> **Riesgo #1 del proyecto.** Si a las 14:00 no hay credenciales, se implementa un **mock de pey** con la misma interfaz y se conecta el real el domingo en la mañana.

### 7.2 Uso de OpenAI

| Tarea | Entrada | Salida |
|---|---|---|
| Transcripción (solo voz) | Audio (webm/m4a), español MX | Texto |
| Interpretar pedido (voz y texto) | Texto + catálogo JSON | JSON con esquema estricto (structured outputs) |
| Catálogo por foto *(opcional)* | Imagen | Lista de `{nombre, precio}` |

Esquema de salida de "interpretar pedido":

```json
{
  "tipo": "venta | monto_directo",
  "items": [
    { "producto_id": "coca-600", "nombre": "Coca-Cola 600 ml", "cantidad": 2, "precio_unitario": 18, "subtotal": 36, "confianza": "alta" }
  ],
  "sin_precio": ["chicles de menta"],
  "total": 55
}
```

**Principios del prompt:**
- Usar solo precios del catálogo. Nunca inventar un precio.
- Entender modismos ("una de seis", "un cuarto de queso", "la de vidrio", "dos de a diez").
- Tolerar texto escrito con prisa: abreviaturas, faltas de ortografía, números en dígitos.
- El total se calcula en el **backend** a partir de los items, no se confía en el número que dé el modelo.

## 8. Modelo de datos

```
negocio      (id, nombre, giro, cuenta_pey, creado)
producto     (id, negocio_id, nombre, alias[], precio, unidad)
venta        (id, negocio_id, items_json, total, estado[pendiente|pagada|expirada],
              pey_charge_id, entrada[voz|texto], texto_original, creada, pagada_en)
```

`entrada` y `texto_original` sirven para medir qué tanto se usa cada camino y para depurar errores de interpretación.

Para la demo: un solo negocio precargado con su catálogo (seed).

## 9. Pantallas

1. **Cobrar** (pantalla principal): botón grande de micrófono **y** caja de texto con botón "Armar cuenta", los dos visibles al mismo tiempo. Total del día arriba.
2. **Confirmar cuenta**: lista de items editable, total grande, botón "Cobrar $X".
3. **QR**: QR a pantalla completa (para voltear el celular hacia el cliente), monto, estado "Esperando pago…" → "✅ Pagado".
4. **Hoy**: resumen del día.

**Criterios de diseño:**
- Botones grandes, se usa con una mano.
- Teclado numérico/texto que no tape el botón de cobrar.
- Alto contraste, legible bajo el sol.
- Cero jerga financiera: "Cobrar", "Pagado", "Vendiste hoy", nunca "transacción" ni "liquidación".
- Funciona bien en Android de gama media y con señal débil.

## 10. Plan de trabajo

🟡 Asignar nombres cuando se reparta el equipo.

| Rol | Responsable | Entregables |
|---|---|---|
| **Pagos / backend** | _ | Integración pey (cobro + webhook), mock de respaldo, endpoints |
| **IA** | _ | Transcripción, parser con structured outputs, prompt, catálogo seed, set de 20 pedidos de prueba (voz y texto) |
| **Frontend** | _ | 4 pantallas, grabación de audio, caja de texto, QR, polling de estado |
| **Producto / pitch** (Alejandro) | Alejandro | Este documento, guion de demo, video, datos del problema, README |

**Calendario:**

| Hora | Hito |
|---|---|
| Sáb 12:30 | Repo creado, stack acordado, credenciales pey solicitadas |
| Sáb 14:00 | Texto → JSON funcionando; cobro pey (real o mock) devuelve QR |
| Sáb 15:00 | Voz → texto conectado al mismo intérprete |
| Sáb 15:30 | **Flujo completo de punta a punta**, aunque sea feo: voz o texto → QR → pagado |
| Sáb 16:00 | Fin del día presencial; lista de pendientes priorizada |
| Dom 10:00 | Pulido de UI, catálogo por foto si alcanza, deploy público |
| Dom 11:30 | Grabación del video demo |
| Dom 13:00 | **Entrega en el portal** |

Se empieza por el camino de **texto** porque no depende del audio y desbloquea al resto del equipo; la voz se conecta encima.

## 11. Demo (≈2 min)

1. **Problema (20 s):** "Don Beto pierde 4% con terminal o vive del efectivo. CoDi es gratis, pero cobrar con CoDi le cuesta más trabajo que recibir un billete."
2. **Cobro por voz (50 s):** se dicta un pedido real → la cuenta aparece → QR → un juez o compañero paga $1 desde su app bancaria → "✅ Pagado".
3. **Cobro por texto (20 s):** "¿Y si hay ruido?" → se escribe "2 quesadillas y un agua" → misma cuenta, mismo QR.
4. **Cierre (30 s):** resumen del día, impacto y modelo de negocio.

## 12. Impacto y modelo

- **Bien público:** el comercio de barrio cobra digital sin comisión, recibe su dinero al instante y empieza a tener un registro de ventas (primer paso para acceder a crédito formal).
- **Para pey:** cada negocio que usa Barrio es un comercio nuevo generando volumen en su API. El comercio de barrio es una vertical replicable, igual que ya hacen con restaurantes.
- **Sostenibilidad:** la cobranza es gratis siempre. A futuro, un plan de pago bajo para funciones extra (reportes, varios empleados, catálogo avanzado), o distribución a través de proveedores y distribuidoras que ya visitan las tienditas.

## 13. Métricas de éxito (de la demo)

- Tiempo de la entrada al QR: **< 5 s** por voz, **< 3 s** por texto.
- Pedidos de prueba interpretados correctamente: **≥ 9 de 10**, tanto dictados como escritos.
- Un pago real (o simulado por pey) confirmado en pantalla durante la demo.

## 14. Riesgos

| Riesgo | Mitigación |
|---|---|
| No hay credenciales de pey a tiempo | Mock con la misma interfaz; conectar real el domingo |
| Ruido de fondo afecta la transcripción | Entrada por texto siempre visible; transcripción dudosa cae en la caja editable |
| La IA inventa precios | Esquema estricto, solo IDs del catálogo, total calculado en backend |
| Texto escrito con faltas o abreviado | Prompt tolerante + set de pruebas con ejemplos reales de cómo escribe la gente |
| Webhook no llega en la demo | Polling al estado del cobro en pey como respaldo |
| Mala señal en el recinto | Video grabado de respaldo |

## 15. Preguntas para platicar con el equipo

1. Nombre: **Barrio** (definido; ver identidad visual en DESIGN.md)
2. ¿Giro estrella para la demo: tiendita, quesadillas o taller? *Propuesta: tiendita, es el que todo el jurado reconoce; quesadillas para mostrar el caso de ruido.*
3. Stack final y quién toma cada rol.
4. ¿Quién habla con los mentores de pey para las credenciales, y a qué hora?
