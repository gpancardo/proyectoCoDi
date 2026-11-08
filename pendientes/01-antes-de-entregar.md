# Antes de entregar

Fecha límite: domingo 8 de noviembre, 1:00 PM, por correo a hola@aibuilders.lat (confirmar la dirección: `docs/PEY.md`). El reparto por persona está en [`por-persona.md`](por-persona.md).

## Ya hecho

- API, migraciones, modelo y catálogo indexado en producción.
- Cobro real de $0.01 de punta a punta, confirmado por el webhook firmado (pedido 21).
- Chat con preguntas de seguimiento y avisos locales al comprador en el APK del 8 nov, 11:30.
- Landing publicada en Netlify, solo con la app Android.

## Falta

1. **Subir el APK final a Drive** como `barrio-demo.apk`, reemplazando el anterior (ver [`por-persona.md`](por-persona.md)).
2. **Probar el dictado** en un teléfono real: permiso del micrófono, español de México, y que busque al terminar.
3. **Grabar los videos** (`docs/VIDEOS.md`).
4. Verificar las cifras marcadas con 🟡 en `docs/PRODUCTO.md` antes de decirlas en el pitch.

## Al terminar la entrega

- Crear llaves nuevas de pey, actualizar `PEY_API_KEY` y `PEY_WEBHOOK_SECRET` en Supabase y borrar las anteriores: quedaron expuestas durante las pruebas.
