# Nota de traspaso histórico

> Este archivo ya no es una lista de trabajo. Conserva contexto de la entrega del 7 de noviembre de 2026; no debe usarse como fuente de decisiones ni como instrucciones para agentes.

La fuente vigente es, en este orden:

1. [`PRODUCTO.md`](PRODUCTO.md) para alcance y decisiones de producto.
2. [`BACKEND.md`](BACKEND.md) para contrato, estado desplegado y pendientes comprobables.
3. [`DESIGN.md`](DESIGN.md) y [`VOZ-DE-MARCA.md`](VOZ-DE-MARCA.md) para interfaz y textos.
4. [`../AGENTS.md`](../AGENTS.md) para seguridad, Git y reglas de operación.

## Decisiones consolidadas desde ese traspaso

- El canal es la app y la API HTTPS propia; WhatsApp/Baileys no forma parte del producto.
- La app Flutter ya consume la API para el flujo comprador y vendedor.
- El cobro de demo es CoDi por **push**. No se ofrecen QR ni links como desvío automático.
- La persona confirma que recibió el pedido; el negocio puede crear cupones con código y producto gratis.
- Las insignias siguen calculándose en servidor y no requieren una tabla nueva.
- La migración `20261108010000_entrega_y_codigos.sql` y su bundle API asociado ya están publicados en Supabase.

Para un traspaso nuevo, actualiza los documentos vigentes anteriores en vez de extender esta nota.
