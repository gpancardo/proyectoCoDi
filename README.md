# Barrio

Barrio conecta a personas con negocios cercanos: exploran el catálogo, arman un pedido y pagan con CoDi. El cliente será una aplicación standalone construida por otro integrante; se comunicará con un backend HTTP propio. WhatsApp deja de ser canal del producto.

```text
App standalone ──HTTPS/API──► Backend Barrio ──► Supabase/Postgres
                                      ├────────► OpenAI (asistencia opcional)
                                      └────────► pey (cobros CoDi)
pey ──webhook firmado──► Backend/Supabase ──► estado del pedido en la app
```

## Repositorio

| Ruta | Contenido |
|---|---|
| `backend/` | API y casos de uso del servidor (en construcción) |
| `supabase/` | Migraciones, función de webhook y datos de demo |
| `web/` | Landing y registro existentes; pendientes de adaptar al backend |
| `docs/PRODUCTO.md` | Fuente de verdad del producto |
| `docs/BACKEND.md` | Arquitectura y contrato inicial para la app |
| `docs/DESIGN.md`, `docs/VOZ-DE-MARCA.md` | Diseño y textos |
| `AGENTS.md` | Reglas de trabajo y Git |

## Estado

El esquema de Supabase y la integración existente de pey son base reutilizable, pero el servicio actual está acoplado a WhatsApp y no constituye todavía una API para la app. El contrato y el plan están en [docs/BACKEND.md](docs/BACKEND.md). La app y el backend deben acordar ese contrato antes de implementar clientes.

## Desarrollo

Las migraciones nuevas van en `supabase/migrations/`. No pongas llaves en el repo; el servidor usa secretos y la app solo recibe datos autorizados para la sesión. Consulta [AGENTS.md](AGENTS.md) antes de trabajar y sigue el flujo `feature/* → dev → stg → main`.
