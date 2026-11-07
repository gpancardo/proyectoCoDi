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

## Arrancar (ruta mínima al MVP)

Todo el código y la base de datos ya están listos. Faltan solo tus llaves y vincular el WhatsApp:

1. **Llaves** en `bot/.env` (`cp .env.example .env`): `OPENAI_API_KEY` y `SUPABASE_SECRET_KEY` (Supabase → Settings → API Keys → Secret keys → *default* → Copy). Sin API key de pey, deja `PEY_MOCK=1`; con ella, pon `PEY_API_KEY` y borra `PEY_MOCK`.
2. **Vincular el WhatsApp del bot:** pon `BOT_PHONE=52XXXXXXXXXX` en `.env` y corre `npm run vincular`. Sale un código de 8 caracteres: en el celular del bot, WhatsApp → Dispositivos vinculados → Vincular con el número de teléfono.
3. **Negocio de prueba:** en el SQL Editor de Supabase, pega `supabase/seed.sql` con el teléfono (10 dígitos) del WhatsApp que va a hacer de negocio. Tiene un "Taco de prueba" de **$0.01**.
4. `npm ci && npm run diagnostico`; cuando diga "Todo listo", `npm start`.
5. **Probar:** desde otro WhatsApp (el comprador) escribe "quiero un taco de prueba". El negocio responde 👍 o "sí" y el cobro de un centavo llega al banco del comprador.

El webhook de pey es **opcional**: el bot confirma los pagos consultando a pey cada 5 s. Si lo quieres: registra `…/functions/v1/pey-webhook` en portal.mipey.mx, guarda el `whsec_…` como secret `PEY_WEBHOOK_SECRET` y apaga *Verify JWT* en la función.

La web no necesita desplegarse para probar: abre `web/registro.html` en tu navegador. GitHub Pages no se despliega por ahora (el workflow es manual).

Para simular un pago con `PEY_MOCK=1`: `update ordenes set estado='pagada', pagada_en=now() where id=<N>;`

## Cómo se usa

- **Quien pide:** escribe o manda nota de voz. Ve la cuenta con el total, dice "sí", aprueba el cobro en su banco y recibe un código para recoger.
- **El negocio:** se registra una vez en la web y después usa 6 palabras (`sí`/👍, `no`, `listo`, `hoy`, `cerrar`, `abrir`), escritas o por voz.

> WhatsApp Web no es la API oficial: usa un número secundario. pey no tiene entorno de pruebas: prueba con $0.01 (un centavo).
