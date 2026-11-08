# Antes de entregar

Fecha límite: domingo 8 de noviembre, 1:00 PM, por correo a hola@aibuilders.lat (confirmar la dirección: `docs/PEY.md`).

## Sin esto no funciona la app nueva

1. **Desplegar la API.** En `backend/`: `npm run build:edge`, pegar `supabase/functions/api/index.ts` en Supabase → Edge Functions → `api` → Code y *Deploy updates*. Sin esto no hay panel del negocio ni sellos de ciudad, y los sellos personales salen incompletos.
2. **Comprobar el webhook de pey** apuntando a `.../functions/v1/api/webhooks/pey`, con `PEY_WEBHOOK_SECRET` en los secretos. Si no llega, el cobro se confirma por la consulta de respaldo, cada vez que la pantalla del pedido pregunta.

## Para la demo

3. **Subir `barrio-demo.apk`** a la carpeta de Drive que abre `/descargar` y confirmar que tenga acceso público.
4. **Publicar la web** y revisar la landing en un teléfono.
5. **Probar un cobro real de $0.01** cuando BBVA salga de mantenimiento. Los pedidos 10 y 11 de prueba quedaron en «cobrada»; vencen solos.
6. **Probar el dictado** en un teléfono real: permiso del micrófono, español de México, y que busque al terminar.
7. **Cargar `OPENAI_API_KEY`** y correr `npm run index:catalog`. Sin llave, la búsqueda sigue funcionando sin modelo.
8. **Cifras del problema:** verificar las fuentes marcadas con 🟡 en `docs/PRODUCTO.md` antes de decirlas en el pitch.
9. **Grabar los videos** (`docs/VIDEOS.md`).
