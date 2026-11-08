<div align="center">

<br />

# <span style="color:#0B2545">barrio</span>

### <span style="color:#0F7C75">lo bueno del barrio, a un toque.</span>

**Descubre negocios cercanos, pide con una cuenta clara y paga con CoDi desde tu banco.**

[Producto](docs/PRODUCTO.md) · [Demo técnica](docs/BACKEND.md) · [Diseño](docs/DESIGN.md) · [Reglas para agentes](AGENTS.md)

</div>

---

## La idea

Barrio hace que pagar digitalmente en el comercio local sea tan sencillo como pedir en la esquina. La persona conversa o explora, elige un negocio real de su zona y ve un total que el servidor calcula desde el menú vigente. El negocio acepta el pedido; el banco recibe un cobro CoDi por *push* mediante pey. Sin efectivo, sin terminal y sin que una IA invente precios.

```text
Comprador ── busca / descubre ──► catálogo real ──► cotización protegida
    ▲                                                     │
    │                                           negocio acepta
    │                                                     ▼
confirmación de entrega ◄── código ◄── CoDi push ◄── pey + webhook firmado
```

## Por qué importa

| Para AI Builders | Para pey | Para SEDECO | Para OpenAI |
|---|---|---|---|
| IA acotada a una tarea útil: convertir lenguaje natural en filtros verificables de catálogo. | Una experiencia de cobro CoDi por push integrada en un flujo comercial completo. | Más visibilidad y ventas para changarros; infraestructura digital pensada para el barrio. | Un agente que ayuda a encontrar, pero no gobierna dinero, disponibilidad ni estados. |
| Fallback determinista si el modelo no está disponible. | Webhook firmado, idempotencia y reconciliación del pago. | Diseño Android-first, español de México y operación de un toque. | RAG sobre catálogo propio, salida tipada y validada en el servidor. |

## Lo que está construido

- **Dos puertas de compra:** Buscar con Barrio, con dictado en español México, y Descubrir con categorías, buscador y carruseles.
- **Pedido seguro:** cotización con vencimiento, confirmación explícita, idempotencia y total calculado exclusivamente en la API.
- **Cobro realista:** CoDi por push con pey, webhook firmado, reconciliación y reintentos solo cuando el anterior vence.
- **Operación para negocio:** abrir/cerrar, aceptar, rechazar, marcar listo, menú y códigos de descuento por porcentaje, monto o producto gratis.
- **Cierre humano:** código de recogida, confirmación de entrega y reporte de problema con contexto del pedido.
- **IA responsable:** el modelo es opcional; la búsqueda determinista sigue funcionando sin llave ni modelo.

> **Estado honesto, 8 nov 2026:** la API desplegada y el catálogo de demo ya funcionan. La migración `20261108010000_entrega_y_codigos.sql` y su bundle de Edge Function están preparados en esta rama, pero todavía requieren aplicación/despliegue controlado en Supabase. No se presenta como funcionalidad ya publicada.

## Arquitectura

```text
Flutter / web estática
        │ HTTPS + sesión de Supabase Auth
        ▼
API Barrio · Edge Function `api`
        ├── Postgres / Auth / almacenamiento · Supabase
        ├── pey · CoDi push + webhook firmado
        └── OpenAI · interpretación opcional de búsqueda
```

El cliente **no** toca tablas de Supabase ni contiene llaves de servidor. La API valida permisos, calcula precios y totales, controla transiciones de pedido y es la única que habla con pey y OpenAI.

## Recorrido de demo

1. Di o escribe: “quiero tacos baratos en Coyoacán”.
2. Compara opciones reales en **Descubrir** o abre la recomendación del agente.
3. Elige productos, aplica un código si tienes uno y confirma la cuenta.
4. El negocio acepta; llega el cobro CoDi por push a tu banco.
5. Aprueba, recoge con el código y confirma que recibiste tu pedido.

## Estructura

| Ruta | Propósito |
|---|---|
| [`barrio_app_pey/`](barrio_app_pey) | App Flutter: compra, gestión de negocio y dictado. |
| [`backend/`](backend) | API Node adaptada a Supabase Edge Functions; reglas de pedidos, pagos y búsqueda. |
| [`supabase/`](supabase) | Migraciones, seed y prueba de humo del esquema. |
| [`web/`](web) | Landing y superficie web heredada; su publicación la controla el responsable web. |
| [`docs/`](docs) | Producto, contrato de API, diseño, tono y operación. |

## Para correrlo

### API

```bash
cd backend
npm run check && npm test
npm start
```

Requiere `backend/.env` basado en `.env.example`. Los secretos viven solo en el backend o en Edge Function Secrets.

### App Flutter

```bash
cd barrio_app_pey
flutter pub get
flutter analyze
flutter run
```

La app usa valores públicos de `.env.example`; no agregues secretos. Consulta su [README](barrio_app_pey/README.md) para Android, permisos y voz.

### Esquema

```bash
bash supabase/tests/run.sh
```

Las migraciones nuevas requieren `GRANT`/`REVOKE` explícitos. Antes de desplegar backend: `cd backend && npm run build:edge`. No publiques `web/` desde una sesión de agente.

## Principios no negociables

- El precio, la disponibilidad y el total nacen en el servidor.
- Un pedido solo se crea desde una cotización vigente que la persona confirmó.
- Cada cambio de estado es atómico y condicionado a su estado anterior.
- Un pedido no puede tener dos cobros vigentes.
- La IA interpreta intención; nunca decide hechos de negocio.

## Documentación que manda

- [Producto](docs/PRODUCTO.md): alcance y decisiones vigentes.
- [Backend](docs/BACKEND.md): contrato de la API, datos, despliegue y pendientes verificables.
- [Diseño](docs/DESIGN.md) y [voz](docs/VOZ-DE-MARCA.md): identidad visual y lenguaje.
- [AGENTS.md](AGENTS.md): seguridad, Git y reglas operativas.

---

<div align="center"><sub>Hecho para que el comercio de barrio venda más lejos sin dejar de sentirse cerca.</sub></div>
