# Antes de entregar

Fecha límite: domingo 8 de noviembre, 1:00 PM, por correo a hola@aibuilders.lat (confirmar la dirección: `docs/PEY.md`). El reparto por persona está en [`por-persona.md`](por-persona.md).

## Ya hecho

- API desplegada el 8 nov 2026 (tablero del negocio, sellos de ciudad, promociones sin código). Comprobado: `/health` 200, `/business/dashboard` 401 sin sesión.
- Migraciones hasta `20261108030000` aplicadas en producción.
- Negocios demo con el celular de prueba; las cuentas nuevas usan el suyo.

## Sin esto no hay demo

1. **Subir `barrio-demo.apk`** (se genera con `flutter build apk --release` en `barrio_app_pey/`) a la carpeta de Drive que abre `/descargar`, con acceso público.
2. **Publicar la web** y revisarla en un teléfono (`web/`; la publica quien la tenga a cargo).
3. **Probar un cobro real de $0.01** cuando el banco esté disponible. Los pedidos 10 y 11 de prueba quedaron en «cobrada»; vencen solos.
4. **Probar el dictado** en un teléfono real: permiso del micrófono, español de México, y que busque al terminar.
5. **Recorrer la demo completa** con una cuenta nueva de comprador y otra de negocio, de punta a punta, antes de grabar.
6. **Grabar los videos** (`docs/VIDEOS.md`).

## Si hay tiempo

7. Comprobar que el webhook de pey llega a `.../functions/v1/api/webhooks/pey` con `PEY_WEBHOOK_SECRET`; si no, el cobro se confirma por la consulta de respaldo.
8. Cargar `OPENAI_API_KEY` y correr `npm run index:catalog`. Sin llave, la búsqueda sigue funcionando sin modelo.
9. Verificar las cifras marcadas con 🟡 en `docs/PRODUCTO.md` antes de decirlas en el pitch.
