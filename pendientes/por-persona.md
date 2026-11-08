# Pendientes por persona

Roles de `docs/PRODUCTO.md` §10. Donde no hay nombre, la persona que lo tome lo anota aquí. Antes de empezar: `git pull --rebase` y rama `feature/<área>-<cambio>` desde `dev`.

## Producto y pitch (Alejandro)

- [ ] Verificar las cifras 🟡 de `docs/PRODUCTO.md` y quedarse solo con las que tengan fuente.
- [ ] Guion final de los dos videos y grabarlos con `docs/VIDEOS.md`.
- [ ] Revisar la landing completa en un teléfono: textos, enlaces y que no prometa nada que la app no haga.
- [ ] Enviar la entrega antes de la 1:00 PM del domingo 8: nombre del equipo, videos sin listar, landing, APK y repositorio.

## Web (quien publica `web/`)

- [ ] Publicar la landing en Netlify desde `main` y confirmar que la URL coincide con `jade-paprenjak-a98b06.netlify.app` (canonical y sitemap la usan). Si es otra, cambiarla en `web/index.html`, `web/blog/`, `web/descargar/`, `web/sitemap.xml` y `web/robots.txt`.
- [ ] Verificar en Supabase → Auth que Site URL y redirects apunten a esa URL.
- [ ] Confirmar que la carpeta de Drive del APK tiene acceso público.

## Backend

- [ ] Registrar el webhook de pey y su secreto (`PEY_WEBHOOK_SECRET`); retirar la función anterior `pey-webhook`.
- [ ] Registrar una CLABE en pey y guardar su `bankAccountId` en `negocios.pey_bank_account_id`. Mientras tanto, los negocios nuevos cobran a la cuenta por defecto.
- [ ] Probar un cobro real de $0.01 de punta a punta y ver el pedido pasar a «pagada» por el webhook.
- [ ] Después del hackatón: porcentaje por artículo en `POST /business/coupons`; vista SQL agregada para el tablero si un negocio rebasa 1000 pedidos en 30 días.

## IA y búsqueda

- [ ] Cargar `OPENAI_API_KEY` (o la de OpenRouter) en los secretos de la función y correr `npm run index:catalog` en `backend/`.
- [ ] Probar 10 frases reales («tacos baratos en Coyoacán», «una papelería abierta») y confirmar que cada resultado explica por qué aparece.
- [ ] Confirmar que sin llave la búsqueda sigue funcionando.
- [ ] Pesos del ranking y ubicación por coordenadas: decidir si entra hoy o después.

## App Flutter

- [ ] Probar en un teléfono real: dictado, permisos, el recorrido completo de comprador y el de negocio. No hay emulador en la máquina de desarrollo.
- [ ] Generar el APK final: `cd barrio_app_pey && flutter build apk --release`. Va firmado con llave de depuración (`ponytail:` en `android/app/build.gradle`).
- [ ] Después del hackatón: llave de publicación y Google Play; avisos push; pantalla propia para reportar un problema; avisos de promociones en la app.

## Diseño y marca

- [ ] Revisión de los sellos por una persona especialista nahua, con crédito y pago, antes de salir de la demo (`docs/LOGROS.md`).
- [ ] Confirmar con fuente especializada la interpretación de cada topónimo de `docs/LOGROS.md`.
- [ ] Decidir si hay aviso de privacidad y términos reales; hoy no hay ninguno publicado.

## Cuando termines algo

Bórralo de aquí en la misma PR. El flujo es `feature/*` → `dev` → `stg` → `main`, con CI en verde en cada paso (`AGENTS.md`).
