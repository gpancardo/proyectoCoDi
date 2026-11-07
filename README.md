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

1. **Supabase:** la migración `supabase/migrations/…_init.sql` ya está aplicada en el proyecto del equipo. Para otro proyecto: pegarla en el SQL Editor (o `supabase link` + `supabase db push`). Después, `supabase/seed.sql` con tu teléfono de prueba.
2. **Webhook de pey:** la función `pey-webhook` ya está desplegada; falta apagar *Verify JWT* en su Settings, registrar su URL en portal.mipey.mx y guardar el `whsec_…` como secret `PEY_WEBHOOK_SECRET`.
3. **Bot:** `cd bot && cp .env.example .env`, llenar las llaves, y `npm ci && npm run diagnostico`. Cuando diga "Todo listo": `npm start`. Con `BOT_PHONE` en `.env` se vincula con un código de 8 caracteres; si no, con un QR. Sin API key de pey, deja `PEY_MOCK=1`.
4. **Web:** poner el número del bot en `web/config.js` y activar Settings → Pages → Source: *GitHub Actions*.

Para simular un pago con `PEY_MOCK=1`: `update ordenes set estado='pagada', pagada_en=now() where id=<N>;`

## Cómo se usa

- **Quien pide:** escribe o manda nota de voz. Ve la cuenta con el total, dice "sí", aprueba el cobro en su banco y recibe un código para recoger.
- **El negocio:** se registra una vez en la web y después usa 6 palabras (`sí`/👍, `no`, `listo`, `hoy`, `cerrar`, `abrir`), escritas o por voz.

> WhatsApp Web no es la API oficial: usa un número secundario. pey no tiene entorno de pruebas: prueba con $0.01 (un centavo).
