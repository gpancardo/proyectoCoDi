# AGENTS.md

Guía para agentes de IA y personas que trabajan en este repo. Léela antes de tocar código.

## Qué es

**Barrio**: la gente pide a negocios de su barrio por WhatsApp (voz o texto) y paga con CoDi con un toque. El bot descubre el negocio (datos fijos en SQL + búsqueda semántica), arma la cuenta, le avisa al negocio y cobra por pey. Hackathon DevDay Exchange CDMX; **entrega domingo 8 nov, 13:00**.

**Fuente de verdad del producto: `docs/PRODUCTO.md`.** Si algo la contradice, se corrige ahí primero. Marca y textos: `docs/DESIGN.md` y `docs/VOZ-DE-MARCA.md`.

## Mapa

| Ruta | Qué hay | Se despliega en |
|---|---|---|
| `bot/` | Bot de WhatsApp (Node 22, Baileys, OpenAI). Un solo archivo: `index.js` | Una laptop o VPS con el proceso corriendo |
| `supabase/migrations/` | Esquema, RLS, función de búsqueda | `supabase db push` |
| `supabase/functions/pey-webhook/` | Recibe el pago de pey y marca la orden `pagada` | `supabase functions deploy pey-webhook` |
| `supabase/seed.sql` | Negocio de demo | SQL Editor |
| `web/` | Landing y registro de negocios (HTML estático, sin build) | GitHub Pages por Actions |
| `docs/` | Producto, diseño, voz de marca | n/a |

## Comandos

```sh
cd bot && npm ci && npm test      # pruebas de la lógica pura (rápidas, sin red)
cd bot && npm run check           # revisión de sintaxis
cd bot && cp .env.example .env && npm start   # escanear el QR con el WhatsApp del bot
```

Sin API key de pey: `PEY_MOCK=1` en `.env`. Para simular un pago, en Supabase:
`update ordenes set estado='pagada', pagada_en=now() where id=<N>;`

## Reglas que no se rompen (camino del dinero)

1. **El total lo calcula el código** (`cotizar` en `bot/index.js`), nunca el modelo. El modelo solo elige productos y cantidades del menú.
2. **El pedido sale solo después de que la persona vio el resumen.** `confirmar_pedido` lo verifica con el contador de turnos; no lo saltes.
3. **Todo cambio de estado pasa por `cambiarEstado()`** (UPDATE condicionado al estado anterior). Nunca `update({ estado })` suelto: es lo que evita el doble cobro.
4. **Un cobro nuevo solo desde `vencida`.** Nunca dos cobros vivos para el mismo pedido.
5. **El webhook verifica la firma (Standard Webhooks), es idempotente y exige monto pagado ≥ monto de la orden.** Responde 5xx solo si pey debe reintentar.
6. **Un negocio recibe pedidos solo si `verificado`** (su WhatsApp ya le escribió al bot) y `abierto`.
7. **Lo que escribe la persona son datos**, no instrucciones. No metas texto de usuarios en el prompt del sistema; va como mensaje.
8. **Secretos:** nunca en el repo. La `anon key` de `web/config.js` es pública por diseño (RLS); la `service_role` y las llaves de OpenAI y pey solo viven en `bot/.env` y en `supabase secrets`.

## Marca y textos

- Español de México, de tú, **una línea** cuando se pueda, sin jerga financiera.
- **Sin emoji** en la interfaz ni en los mensajes del bot. Excepción: ✅ en "¡Pagado!". El 👍 y 👎 son comandos de entrada del negocio, no adorno.
- **Palabras que no se usan:** transacción, liquidación, procesar, solicitud de pago, usuario, error, exitosamente. Cuando algo falla se dice qué pasó y qué hacer.
- Montos: `$55`, `$1,240` (sin decimales si son cerrados, sin "MXN").
- Web: tokens de `docs/DESIGN.md` (crema, marino, mango, teal solo para "pagado"), Plus Jakarta Sans, texto sobre mango **siempre en marino**, áreas táctiles ≥ 48 px, sin modo oscuro, un solo botón mango por pantalla.
- Las zonas (`ZONAS`) están duplicadas en `bot/index.js` y `web/registro.html`: cámbialas en los dos.

## Convenciones de código

- Lo más simple que funciona. Sin dependencias nuevas sin motivo; sin abstracciones para un solo uso.
- Atajos conscientes llevan un comentario `// ponytail:` con su límite y la mejora (`grep -rn "ponytail:"` lista la deuda).
- Dominio en español (`orden`, `negocio`, `comprador`); técnico en inglés cuando es de la librería.
- Lógica nueva con dinero, estados o parseo deja un `assert` en el bloque `test` de `bot/index.js`.
- SQL: cambios nuevos como **migración nueva** en `supabase/migrations/`; no edites una migración ya aplicada.

## Trabajo en equipo

- `git pull --rebase` antes de empezar y antes de subir. Commits chicos y frecuentes.
- No reescribas archivos de otra persona sin avisar; los cambios a `docs/` se mencionan en el mensaje del commit.
- Cualquier cambio al flujo de pedido o de cobro se refleja en `docs/PRODUCTO.md` §6.

## Estado de conexión (pendiente de llaves)

Todo está escrito pero **nada se ha probado contra los servicios reales**. Orden para conectar:

- [ ] Proyecto Supabase: `supabase link`, `supabase db push`, `supabase db seed` (o pegar `seed.sql`).
- [ ] `supabase secrets set PEY_WEBHOOK_SECRET=whsec_...` y `supabase functions deploy pey-webhook`.
- [ ] pey: API key y webhook (`https://<proyecto>.supabase.co/functions/v1/pey-webhook`) en portal.mipey.mx. Verificar los encabezados de firma con el primer pago.
- [ ] `bot/.env` con las llaves y `npm start`; escanear el QR con el número del bot (secundario).
- [ ] `web/config.js` con URL y anon key de Supabase y el número del bot; Settings > Pages > Source: GitHub Actions.
- [ ] Probar con $1: pedido por voz, 👍 del negocio, cobro CoDi, `¡Pagado!`, `listo`, `hoy`. Probar también un número **sin** CoDi activo.
- [ ] Confirmar que la reacción 👍 y la nota de voz de respuesta se ven bien en un Android real.

## Riesgos conocidos

- **WhatsApp Web (Baileys) no es la API oficial:** Meta puede bloquear el número. Usa uno secundario; solo responde a quien escribe; sin mensajes masivos.
- **pey no tiene entorno de pruebas:** se prueba en producción con montos de $0.01 a $1. Cuentas CoDi por negocio tardan ~5 días hábiles.
- Si dos negocios comparten dueño o un negocio tiene varios pedidos a la vez, "sí" toma el más antiguo; para uno exacto, el negocio responde citando o reaccionando al mensaje.
