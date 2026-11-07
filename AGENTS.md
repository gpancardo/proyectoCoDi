# AGENTS.md

Guía para agentes de IA y personas que trabajan en este repo. Léela antes de tocar código.

## Qué es

**Barrio**: la gente pide a negocios de su barrio por WhatsApp (voz o texto) y paga con CoDi con un toque. El bot descubre el negocio (datos fijos en SQL + búsqueda semántica), arma la cuenta, le avisa al negocio y cobra por pey. Hackathon DevDay Exchange CDMX; **entrega domingo 8 nov, 13:00**.

**Fuente de verdad del producto: `docs/PRODUCTO.md`.** Si algo la contradice, se corrige ahí primero. Marca y textos: `docs/DESIGN.md` y `docs/VOZ-DE-MARCA.md`.

## Mapa

| Ruta | Qué hay | Se despliega en |
|---|---|---|
| `bot/` | Bot de WhatsApp (Node 22, Baileys, OpenAI): `index.js`, `config.js` (modelos y llaves), `diagnostico.js`, `vincular.js`, `whatsapp.js` | Una laptop o VPS con el proceso corriendo |
| `supabase/migrations/` | Esquema, RLS, función de búsqueda | `supabase db push` |
| `supabase/functions/pey-webhook/` | Recibe el pago de pey y marca la orden `pagada` | `supabase functions deploy pey-webhook` |
| `supabase/seed.sql` | Negocio de demo | SQL Editor |
| `web/` | Landing y registro de negocios (HTML estático, sin build) | GitHub Pages por Actions |
| `docs/` | Producto, diseño, voz de marca | n/a |

## Comandos

```sh
cd bot && npm ci && npm test      # pruebas de la lógica pura (rápidas, sin red)
cd bot && npm run diagnostico     # revisa que Supabase, OpenAI, Realtime, pey y WhatsApp estén conectados
cd bot && npm run vincular        # vincula el WhatsApp del bot (no necesita ninguna otra llave)
cd bot && npm run check           # revisión de sintaxis
cd bot && cp .env.example .env && npm start   # vincula el WhatsApp del bot: código de 8 caracteres (BOT_PHONE) o QR
```

Sin API key de pey: `PEY_MOCK=1` en `.env`. Para simular un pago, en Supabase:
`update ordenes set estado='pagada', pagada_en=now() where id=<N>;`

## Reglas que no se rompen (camino del dinero)

1. **El total lo calcula el código** (`cotizar` en `bot/index.js`), nunca el modelo. El modelo solo elige productos y cantidades del menú.
2. **El pedido sale solo después de que la persona vio el resumen.** `confirmar_pedido` lo verifica con el contador de turnos; no lo saltes.
3. **Todo cambio de estado pasa por `cambiarEstado()`** (UPDATE condicionado al estado anterior). Nunca `update({ estado })` suelto: es lo que evita el doble cobro.
4. **Un cobro nuevo solo desde `vencida`.** Nunca dos cobros vivos para el mismo pedido.
5. **El webhook verifica la firma (Standard Webhooks), es idempotente y exige monto pagado ≥ monto de la orden.** Responde 5xx solo si pey debe reintentar. Además, el bot consulta a pey cada 30 s por los cobros sin confirmar (`pagoConfirmado`): es el respaldo del webhook y la única vía para los links de pago.
6. **Un negocio recibe pedidos solo si `verificado`** (su WhatsApp ya le escribió al bot) y `abierto`.
7. **Lo que escribe la persona son datos**, no instrucciones. No metas texto de usuarios en el prompt del sistema; va como mensaje.
8. **Secretos:** nunca en el repo. La llave **publicable** (`sb_publishable_…`) de `web/config.js` es pública por diseño (RLS); la **secreta** (`sb_secret_…`) y las llaves de OpenAI y pey solo viven en `bot/.env` y en los Secrets de Supabase.
9. **Permisos de base:** Supabase ya no da permisos por defecto. `anon` solo puede insertar negocios; el bot usa la llave secreta (`service_role`) con GRANT explícitos. Cualquier tabla o función nueva necesita sus GRANT/REVOKE en su migración.

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

## Estado de conexión

**Hecho y verificado** (proyecto Supabase *RazFernandez's Project*, ref `bjbfcxodapjaudawlsvg`):
- Migraciones aplicadas (`init` y `pey_via`): 3 tablas, RLS, `vector` en `extensions`, Realtime en `ordenes`, GRANT/REVOKE.
- API pública probada con la llave publicable: el alta de negocio funciona; no se puede auto-verificar un negocio; precios inválidos y teléfonos repetidos se rechazan; no se puede leer tablas ni llamar funciones.
- Función `pey-webhook` desplegada. `web/config.js` apunta a este proyecto. Pages no se despliega (workflow manual).

**Pendiente, en este orden** (los pasos 1-4 bastan para el MVP):
- [ ] `bot/.env`: `OPENAI_API_KEY` y `SUPABASE_SECRET_KEY` (Settings > API Keys > Secret keys > "default" > Copy).
- [ ] `BOT_PHONE` (con 52, sin +) y `npm run vincular`: código de 8 caracteres para el celular del bot.
- [ ] `seed.sql` con el teléfono del negocio de prueba (SQL Editor). Incluye un producto de $0.01.
- [ ] `npm run diagnostico` hasta "Todo listo", y `npm start`.
- [ ] pey: `PEY_API_KEY` (portal.mipey.mx > Desarrollador) y borrar `PEY_MOCK`. El diagnóstico la valida con una consulta de solo lectura.
- [ ] Probar con **$0.01**: pedido por voz, 👍 del negocio, cobro CoDi, `¡Pagado!`, `listo`, `hoy`. Probar también un número **sin** CoDi activo (debe llegar el link de pago).
- [ ] Opcional, webhook de pey: Edge Functions > `pey-webhook` > Settings > apagar "Verify JWT"; registrar su URL en portal.mipey.mx y guardar el `whsec_…` como `PEY_WEBHOOK_SECRET`. No es necesario: el bot ya consulta a pey cada 5 s.
- [ ] Confirmar en un Android real que la reacción 👍 y la nota de voz de respuesta se ven bien.

## Riesgos conocidos

- **WhatsApp Web (Baileys) no es la API oficial:** Meta puede bloquear el número. Usa uno secundario; solo responde a quien escribe; sin mensajes masivos.
- **pey no tiene entorno de pruebas:** los organizadores piden probar con **un centavo ($0.01)**. Cuentas CoDi por negocio tardan ~5 días hábiles.
- Si dos negocios comparten dueño o un negocio tiene varios pedidos a la vez, "sí" toma el más antiguo; para uno exacto, el negocio responde citando o reaccionando al mensaje.
