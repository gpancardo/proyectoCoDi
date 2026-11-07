# Barrio

Pide en tu barrio por WhatsApp (voz o texto) y paga con CoDi con un toque. Sin comisión. Hecho para el DevDay Exchange Community Hackathon CDMX con OpenAI, Supabase y [pey](https://pey.mx).

```
persona ──WhatsApp──► bot ──► OpenAI (voz, agente, búsqueda) ──► negocio: "sí" / 👍
                        └──► pey: cobro CoDi al banco de la persona
pey ──webhook──► Supabase (Edge Function) ──Realtime──► bot: "¡Pagado!" a los dos
```

| | |
|---|---|
| `bot/` | Bot de WhatsApp (Node 22 + Baileys) |
| `supabase/` | Migraciones, función del webhook de pey, datos de demo |
| `web/` | Landing y registro de negocios (GitHub Pages) |
| `docs/` | [Producto](docs/PRODUCTO.md) · [Diseño](docs/DESIGN.md) · [Voz de marca](docs/VOZ-DE-MARCA.md) |
| [`AGENTS.md`](AGENTS.md) | Reglas del repo, comandos y checklist para conectar |

## Arrancar

1. **Supabase:** `supabase link --project-ref <ref>` → `supabase db push` → ejecutar `supabase/seed.sql` con tu teléfono de negocio de prueba.
2. **Webhook de pey:** `supabase functions deploy pey-webhook`, registrar su URL en portal.mipey.mx y `supabase secrets set PEY_WEBHOOK_SECRET=whsec_...`.
3. **Bot:** `cd bot && cp .env.example .env` (llenar) → `npm ci && npm test && npm start` → escanear el QR con el WhatsApp del bot. Sin API key de pey, usa `PEY_MOCK=1`.
4. **Web:** editar `web/config.js` y activar Settings → Pages → Source: *GitHub Actions*.

Para simular un pago con `PEY_MOCK=1`: `update ordenes set estado='pagada', pagada_en=now() where id=<N>;`

## Cómo se usa

- **Quien pide:** escribe o manda nota de voz. Ve la cuenta con el total, dice "sí", aprueba el cobro en su banco y recibe un código para recoger.
- **El negocio:** se registra una vez en la web y después usa 6 palabras (`sí`/👍, `no`, `listo`, `hoy`, `cerrar`, `abrir`), escritas o por voz.

> WhatsApp Web no es la API oficial: usa un número secundario. pey no tiene entorno de pruebas: prueba con $1.
