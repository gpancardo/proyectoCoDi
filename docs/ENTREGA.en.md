<div align="center">

[Español](ENTREGA.md) · **English**

# Barrio · Submission dossier

**DevDay Exchange Community Hackathon · Mexico City · November 7–8, 2026**

AI search over a real catalog, server-calculated totals and real CoDi payments through pey.

![Android](https://img.shields.io/badge/Android-app-0B2545?style=flat-square) ![CoDi](https://img.shields.io/badge/CoDi-real_payment-0F7C75?style=flat-square) ![pey](https://img.shields.io/badge/pey-signed_webhook-F5A524?style=flat-square) ![AI](https://img.shields.io/badge/AI-hybrid_RAG-0B2545?style=flat-square)

</div>

---

## Links

| | |
|---|---|
| **Website** (Spanish) | https://jade-paprenjak-a98b06.netlify.app |
| **Android app** | [Download page](https://jade-paprenjak-a98b06.netlify.app/descargar/) |
| **Repository** | https://github.com/gpancardo/proyectoCoDi |
| **Pitch** | [`PITCH.en.md`](PITCH.en.md) |
| **Screens** | [All 23 app screens](capturas/README.md) |
<!-- | **Demo video** | LINK | -->
<!-- | **Pitch video** | LINK | -->

## Try it in 5 minutes

You need an Android phone and a mobile number with CoDi active at a Mexican bank. The app is in Spanish.

| Step | What to do |
|:---:|---|
| 1 | Install the APK and allow installs from that source |
| 2 | Create an account with your email and accept notifications |
| 3 | Enter your 10-digit mobile number and your borough |
| 4 | In **Buscar con Barrio**, type `algo para una fiesta` ("something for a party") and answer the question |
| 5 | Open **Tacos Doña Lupe**, add the **Taco de prueba** and confirm MX$0.01 |
| 6 | In about 5 seconds the charge arrives: approve it in your bank |
| 7 | See **¡Pagado!** ("Paid!") and your pickup code |

> The cent is real money and is not refunded. To try another account on the same phone, clear the app's data first.

## Evidence of the real payment

| Time (UTC, Nov 8, 2026) | Event |
|---|---|
| 17:20:08 | Order 21 is created for a MX$0.01 test taco |
| 17:20:13 | The demo accepts the order and pey sends the CoDi push charge |
| 17:20:40 | The bank confirms, the signed webhook arrives and the order becomes `pagada` (paid) |

**32 seconds** from order to payment, with no manual step on the server.

<!-- Real screenshots: add the images from docs/capturas/reales/ here
<p align="center">
  <img src="capturas/reales/01-cobro-banco.png" width="220" alt="Charge in the bank">
  <img src="capturas/reales/02-pagado.png" width="220" alt="Paid">
  <img src="capturas/reales/04-sello-primera-compra.png" width="220" alt="Badge earned">
</p>
-->

## What to look at, by judge

| Judge | What we show | Where to see it |
|---|---|---|
| **pey** | End-to-end CoDi push, signed webhook, idempotency, amount check and fallback lookup | [`pagos.js`](../backend/src/pagos.js) |
| **OpenAI** | Strict JSON schema outputs, embeddings and selection limited to the retrieved catalog | [`agent.js`](../backend/src/agent.js) |
| **AI Builders** | Hybrid search, conversation with bounded memory and a no-model fallback | [`search.js`](../backend/src/search.js), [`chat_screen.dart`](../barrio_app_pey/lib/components/sections/chat_screen.dart) |
| **SEDECO** | A tool in Mexican Spanish that helps local commerce sell digitally | [Screens](capturas/README.md), [Badges](LOGROS.md) |

## How it works

### Architecture

```mermaid
flowchart TB
    APP["Flutter app · Android"]:::app -->|"HTTPS + session"| API["Barrio API<br/>Supabase Edge Function"]:::api
    API --> DB[("Postgres + pgvector")]:::data
    API -->|"typed filters<br/>and embeddings"| AI["AI model<br/>(optional)"]:::ext
    API -->|"CoDi charge"| PEY["pey"]:::ext
    PEY -->|"push"| BANK["Banking app"]:::ext
    PEY -->|"signed webhook"| API
    classDef app fill:#F5A524,stroke:#0B2545,stroke-width:2px,color:#0B2545
    classDef api fill:#0B2545,stroke:#0B2545,color:#FFF8EC
    classDef data fill:#0F7C75,stroke:#0B2545,color:#FFF8EC
    classDef ext fill:#FFF8EC,stroke:#0B2545,stroke-width:2px,color:#0B2545
```

The app never touches database tables and holds no server keys.

### Search: AI helps, the server decides

```mermaid
flowchart LR
    Q["User's words<br/>+ last 6 turns"]:::in --> F["Model:<br/>typed filters"]:::ai
    Q --> E["Embeddings:<br/>catalog neighbors"]:::ai
    F --> V{"Server<br/>validates filters"}:::srv
    E --> R["Fusion with<br/>exact rules"]:::srv
    V --> R
    R --> S["Real shops<br/>from the catalog"]:::out
    R --> P["Follow-up question<br/>max 3, never repeated"]:::out
    classDef in fill:#FFF8EC,stroke:#0B2545,stroke-width:2px,color:#0B2545
    classDef ai fill:#F5A524,stroke:#0B2545,stroke-width:2px,color:#0B2545
    classDef srv fill:#0B2545,stroke:#0B2545,color:#FFF8EC
    classDef out fill:#0F7C75,stroke:#0B2545,color:#FFF8EC
```

If no model is available, search continues with exact rules. Whatever a person types is treated as data, never as instructions.

### From order to payment

```mermaid
sequenceDiagram
    actor C as Buyer
    participant B as Barrio API
    participant N as Shop
    participant P as pey
    participant F as Bank
    C->>B: Requests the total
    B-->>C: Total calculated from the menu
    C->>B: Confirms that total
    B->>N: New order
    N->>B: Accepts
    B->>P: Creates the CoDi charge
    P->>F: Push charge
    C->>F: Approves
    P->>B: Signed webhook
    B-->>C: Paid! and pickup code
```

### Order states

```mermaid
stateDiagram-v2
    direction LR
    pendiente: pending
    aceptada: accepted
    rechazada: rejected
    expirada: expired
    cobrada: charged
    pagada: paid
    lista: ready
    entregada: delivered
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

Each change requires the previous state, so a retry cannot advance an order twice. Cancellation and charge-expiry paths are in [`pedidos.js`](../backend/src/pedidos.js).

## Safeguards

| Risk | Safeguard |
|---|---|
| Price altered by the app or the AI | The total is calculated on the server from the current menu |
| Confirming a different total | The order requires a valid quote and the total the person saw |
| Duplicate order | Idempotency key and one quote per order |
| Double charge | A database constraint allows only one active charge |
| Fake or repeated webhook | Signature, time window, deduplication and minimum amount |
| Lost webhook | Fallback lookup at pey when the charge is checked |
| Instructions hidden in a message | People's input is data; history is bounded |
| Exposed secrets | Keys live only on the server; the app contains none |

## Quality

| Check | Result |
|---|---|
| Backend tests | 24 passing: money, states, signature, search and conversation |
| App tests | 8 passing, with clean static analysis |
| Schema | Migrations and permissions tested on Postgres with pgvector |
| CI | `backend`, `supabase` and `web` on every PR |
| Real journey | Real MX$0.01 payment in production |

## Real and demo

| Real, in production | Demo or pending |
|---|---|
| API, database and authentication | The 14 catalog shops are demo data |
| Model and semantic search | Charges go to a pre-authorized test account; registering each shop's account with Banxico takes about 5 business days |
| CoDi push charge and signed webhook | Doña Lupe auto-accepts the test taco after 5 s, so it can be tried without a second phone |
| Shop sign-up, menu and promotions | Alerts only while Android keeps the app alive |
| | APK signed with a debug key, not on Google Play |
| | Still missing: privacy notice, terms, password recovery, account deletion and rate limiting |

<div align="center">

[Pitch](PITCH.en.md) · [Repository](../README.en.md) · [Product (Spanish)](PRODUCTO.md) · [API (Spanish)](BACKEND.md)

</div>
