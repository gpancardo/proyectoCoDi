# Barrio

Barrio conecta a personas con negocios cercanos: exploran el catálogo, arman un pedido, el negocio lo acepta y pagan con CoDi (cobro por pey). Hay una web para comprador y negocio (`web/app.html`) y una app Flutter en construcción; ambas hablan con una API HTTPS propia. WhatsApp ya no es canal del producto.

```text
Web / App ──HTTPS──► API Barrio (Supabase Edge Function) ──► Postgres (Supabase)
                          ├──► OpenRouter u OpenAI (opcional: interpretar búsquedas)
                          └──► pey (cobros CoDi) ──webhook firmado──► estado del pedido
```

## Repositorio

| Ruta | Contenido |
|---|---|
| `backend/` | API (Node 22, sin dependencias): Descubrir, búsqueda, pedidos, cobros, cupones, insignias, gestión del negocio. `edge/api.js` la adapta a Edge Functions |
| `supabase/` | Migraciones, datos de demo y pruebas del esquema (`tests/`) |
| `web/` | Landing, redirección del registro y la app web (`app.html`, `app.js`) |
| `barrio_app_pey/` | App Flutter (en construcción, aún sin integrar a la API) |
| `bot/` | Código heredado de WhatsApp; referencia, no producto |
| `docs/PRODUCTO.md` | Fuente de verdad del producto |
| `docs/BACKEND.md` | Contrato de la API, esquema, estado desplegado y pendientes |
| `docs/PEY.md` | Cuentas de prueba, reglas de pago y entrega del hackathon |
| `docs/DESIGN.md`, `docs/VOZ-DE-MARCA.md` | Diseño y textos |
| `AGENTS.md` | Reglas de trabajo y Git |

## Estado

API desplegada como Edge Function `api` en el proyecto de Supabase del equipo; migraciones aplicadas hasta `20261107050000`. Funciona de punta a punta contra la base real (cotizar → pedir → aceptar → cobro → pagado, cupones, insignias). Un cobro real de $0.01 por push CoDi se probó contra pey. Pendientes y detalles: [docs/BACKEND.md](docs/BACKEND.md#estado-desplegado-y-pendientes).

## Desarrollo

```bash
cd backend
npm run check && npm test           # sintaxis y pruebas unitarias (Node >= 22)
npm start                           # API local en :3000 (necesita backend/.env, ver .env.example)
npm run build:edge                  # empaqueta supabase/functions/api/index.ts para desplegar
E2E_CONFIRM=1 npm run e2e:live      # recorrido completo contra la base real, pey en mock (borra sus datos)
```

Esquema: `bash supabase/tests/run.sh` aplica migraciones, seed y la prueba de humo en un Postgres con pgvector (el CI hace lo mismo). Las migraciones nuevas van en `supabase/migrations/`, con GRANT/REVOKE explícitos.

No pongas llaves en el repo: el backend usa secretos de entorno (`backend/.env` en local, Edge Function Secrets en Supabase) y los clientes solo reciben datos autorizados para su sesión. Lee [AGENTS.md](AGENTS.md) y sigue el flujo `feature/* → dev → stg → main`.
