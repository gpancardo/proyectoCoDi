<div align="center">

**Español** · [English](ENTREGA.en.md)

# Barrio · Expediente de entrega

**DevDay Exchange Community Hackathon · CDMX · 7–8 de noviembre de 2026**

Búsqueda con IA sobre un catálogo real, totales calculados por el servidor y cobros CoDi reales con pey.

![Android](https://img.shields.io/badge/Android-app-0B2545?style=flat-square) ![CoDi](https://img.shields.io/badge/CoDi-cobro_real-0F7C75?style=flat-square) ![pey](https://img.shields.io/badge/pey-webhook_firmado-F5A524?style=flat-square) ![IA](https://img.shields.io/badge/IA-RAG_h%C3%ADbrido-0B2545?style=flat-square)

</div>

---

## Enlaces

| | |
|---|---|
| **Sitio** | https://jade-paprenjak-a98b06.netlify.app |
| **App Android** | [Página de descarga](https://jade-paprenjak-a98b06.netlify.app/descargar/) |
| **Repositorio** | https://github.com/gpancardo/proyectoCoDi |
| **Pitch** | [`PITCH.md`](PITCH.md) |
| **Pantallas** | [Las 23 pantallas de la app](capturas/README.md) |
<!-- | **Video de demo** | ENLACE | -->
<!-- | **Video de pitch** | ENLACE | -->

## Pruébalo en 5 minutos

Necesitas un teléfono Android y un celular con CoDi activo en tu banco.

| Paso | Qué hacer |
|:---:|---|
| 1 | Instala el APK y permite instalar desde esa fuente |
| 2 | Crea una cuenta con tu correo y acepta las notificaciones |
| 3 | Escribe tu celular de 10 dígitos y tu alcaldía |
| 4 | En **Buscar con Barrio**, escribe `algo para una fiesta` y contesta la pregunta |
| 5 | Abre **Tacos Doña Lupe**, agrega el **Taco de prueba** y confirma $0.01 |
| 6 | En unos 5 segundos llega el cobro: apruébalo en tu banco |
| 7 | Mira **¡Pagado!** y tu código para recoger |

> El centavo es dinero real y no se devuelve. Para probar con otra cuenta en el mismo teléfono, borra antes los datos de la app.

## Evidencia del cobro real

| Hora (UTC, 8 nov 2026) | Evento |
|---|---|
| 17:20:08 | Se crea el pedido 21 por un Taco de prueba de $0.01 |
| 17:20:13 | La demo acepta el pedido y pey envía el cobro CoDi por push |
| 17:20:40 | El banco confirma, llega el webhook firmado y el pedido queda `pagada` |

**32 segundos** del pedido al pago, sin intervención manual en el servidor.

<!-- Capturas reales: agrega aquí las imágenes de docs/capturas/reales/
<p align="center">
  <img src="capturas/reales/01-cobro-banco.png" width="220" alt="Cobro en el banco">
  <img src="capturas/reales/02-pagado.png" width="220" alt="Pagado">
  <img src="capturas/reales/04-sello-primera-compra.png" width="220" alt="Sello ganado">
</p>
-->

## Qué mirar, según quien evalúa

| Jurado | Qué demostramos | Dónde verlo |
|---|---|---|
| **pey** | CoDi por push de punta a punta, webhook con firma, idempotencia, comprobación de monto y consulta de respaldo | [`pagos.js`](../backend/src/pagos.js) |
| **OpenAI** | Salidas con esquema JSON estricto, embeddings y selección limitada al catálogo recuperado | [`agent.js`](../backend/src/agent.js) |
| **AI Builders** | Búsqueda híbrida, conversación con memoria acotada y respaldo sin modelo | [`search.js`](../backend/src/search.js), [`chat_screen.dart`](../barrio_app_pey/lib/components/sections/chat_screen.dart) |
| **SEDECO** | Una herramienta en español de México para que el comercio local venda en digital | [Pantallas](capturas/README.md), [Sellos](LOGROS.md) |

## Cómo funciona

### Arquitectura

```mermaid
flowchart TB
    APP["App Flutter · Android"]:::app -->|"HTTPS + sesión"| API["API Barrio<br/>Supabase Edge Function"]:::api
    API --> DB[("Postgres + pgvector")]:::dato
    API -->|"filtros tipados<br/>y embeddings"| IA["Modelo de IA<br/>(opcional)"]:::ext
    API -->|"cobro CoDi"| PEY["pey"]:::ext
    PEY -->|"push"| BANCO["App del banco"]:::ext
    PEY -->|"webhook firmado"| API
    classDef app fill:#F5A524,stroke:#0B2545,stroke-width:2px,color:#0B2545
    classDef api fill:#0B2545,stroke:#0B2545,color:#FFF8EC
    classDef dato fill:#0F7C75,stroke:#0B2545,color:#FFF8EC
    classDef ext fill:#FFF8EC,stroke:#0B2545,stroke-width:2px,color:#0B2545
```

La app no toca tablas ni contiene llaves de servidor.

### Búsqueda: la IA ayuda, el servidor decide

```mermaid
flowchart LR
    Q["Frase de la persona<br/>+ últimos 6 turnos"]:::in --> F["Modelo:<br/>filtros tipados"]:::ia
    Q --> E["Embeddings:<br/>vecinos del catálogo"]:::ia
    F --> V{"El servidor<br/>valida filtros"}:::srv
    E --> R["Fusión con<br/>reglas exactas"]:::srv
    V --> R
    R --> S["Negocios reales<br/>del catálogo"]:::out
    R --> P["Pregunta de seguimiento<br/>máx. 3, sin repetir"]:::out
    classDef in fill:#FFF8EC,stroke:#0B2545,stroke-width:2px,color:#0B2545
    classDef ia fill:#F5A524,stroke:#0B2545,stroke-width:2px,color:#0B2545
    classDef srv fill:#0B2545,stroke:#0B2545,color:#FFF8EC
    classDef out fill:#0F7C75,stroke:#0B2545,color:#FFF8EC
```

Si no hay modelo disponible, la búsqueda sigue con las reglas exactas. Lo que escribe la persona entra como dato, nunca como instrucción.

### Del pedido al pago

```mermaid
sequenceDiagram
    actor C as Comprador
    participant B as API Barrio
    participant N as Negocio
    participant P as pey
    participant F as Banco
    C->>B: Pide la cuenta
    B-->>C: Total calculado desde el menú
    C->>B: Confirma ese total
    B->>N: Pedido nuevo
    N->>B: Acepta
    B->>P: Crea el cobro CoDi
    P->>F: Cobro por push
    C->>F: Aprueba
    P->>B: Webhook firmado
    B-->>C: ¡Pagado! y código para recoger
```

### Estados del pedido

```mermaid
stateDiagram-v2
    direction LR
    [*] --> pendiente
    pendiente --> aceptada
    pendiente --> rechazada
    pendiente --> expirada
    aceptada --> cobrada
    cobrada --> pagada
    pagada --> lista
    lista --> entregada
    entregada --> [*]
```

Cada cambio exige el estado anterior, así que un reintento no puede avanzar un pedido dos veces. Las rutas de cancelación y vencimiento del cobro están en [`pedidos.js`](../backend/src/pedidos.js).

## Protecciones

| Riesgo | Protección |
|---|---|
| Precio alterado por la app o por la IA | El total se calcula en el servidor desde el menú vigente |
| Confirmar un total distinto | El pedido exige una cotización vigente y el total que vio la persona |
| Pedido duplicado | Llave de idempotencia y una cotización por pedido |
| Doble cobro | Una restricción en la base permite un solo cobro vigente |
| Webhook falso o repetido | Firma, ventana de tiempo, deduplicación y monto mínimo |
| Webhook perdido | Consulta de respaldo a pey al revisar el cobro |
| Instrucciones escondidas en un mensaje | Las entradas de las personas son datos; el historial va acotado |
| Secretos expuestos | Las llaves viven solo en el servidor; la app no las contiene |

## Calidad

| Comprobación | Resultado |
|---|---|
| Pruebas de backend | 24 en verde: dinero, estados, firma, búsqueda y conversación |
| Pruebas de la app | 8 en verde y análisis estático limpio |
| Esquema | Migraciones y permisos probados en Postgres con pgvector |
| CI | `backend`, `supabase` y `web` en cada PR |
| Recorrido real | Cobro real de $0.01 en producción |

## Real y demo

| Real, en producción | De demo o pendiente |
|---|---|
| API, base de datos y autenticación | Los 14 negocios del catálogo son de demostración |
| Modelo y búsqueda semántica | Los cobros llegan a una cuenta de prueba preautorizada; registrar la cuenta de cada negocio ante Banxico tarda unos 5 días hábiles |
| Cobro CoDi por push y webhook firmado | Doña Lupe acepta sola el Taco de prueba a los 5 s, para probar sin un segundo teléfono |
| Alta de negocios, menú y promociones | Avisos solo mientras Android mantenga viva la app |
| | APK con firma de depuración, fuera de Google Play |
| | Faltan aviso de privacidad, términos, recuperar contraseña, borrar cuenta y límite de uso |

<div align="center">

[Pitch](PITCH.md) · [Repositorio](../README.md) · [Producto](PRODUCTO.md) · [API](BACKEND.md)

</div>
