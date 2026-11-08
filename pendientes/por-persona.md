# Pendientes por persona

Roles de `docs/PRODUCTO.md` §10. Donde no hay nombre, la persona que lo tome lo anota aquí. Antes de empezar: `git pull --rebase` y rama `feature/<área>-<cambio>` desde `dev`.

## APK final y enlace de descarga (Raz)

APK generado el 8 nov a las 11:30 desde `main`: `barrio_app_pey/build/app/outputs/flutter-apk/app-release.apk`.

- [ ] Instalarlo en un teléfono Android y recorrer la demo completa (comprador y negocio) antes de compartirlo.
- [ ] Subirlo a la carpeta de Drive con el nombre `barrio-demo.apk`, reemplazando el anterior, con acceso «cualquiera con el enlace».


## Producto y pitch (Alejandro)

- [ ] Verificar las cifras 🟡 de `docs/PRODUCTO.md` y quedarse solo con las que tengan fuente.
- [ ] Guion final de los dos videos y grabarlos con `docs/VIDEOS.md`.
- [ ] Revisar la landing completa en un teléfono: textos, enlaces y que no prometa nada que la app no haga.
- [ ] Enviar la entrega antes de la 1:00 PM del domingo 8: nombre del equipo, videos sin listar, landing, APK y repositorio.

## Web (quien publica `web/`)

- [x] Landing publicada el 8 nov 2026 en `https://jade-paprenjak-a98b06.netlify.app`. El sitio es de arrastrar y soltar (Netlify Drop) y **no se publica solo desde `main`**: cada cambio en `web/` se vuelve a subir en Netlify → Deploys, con un zip de `web/` (`git ls-files web | grep -v test | zip landing.zip -@` desde `web/`).
- [ ] Si algún día la URL cambia, actualizarla en `web/index.html`, `web/blog/`, `web/descargar/`, `web/sitemap.xml` y `web/robots.txt`.
- [ ] Confirmar que el enlace de `/descargar/` abre sin pedir permiso.

## Backend

- [ ] Registrar una CLABE en pey y guardar su `bankAccountId` en `negocios.pey_bank_account_id`. Mientras tanto, los negocios nuevos cobran a la cuenta por defecto.
- [ ] Después del hackatón: porcentaje por artículo en `POST /business/coupons`; vista SQL agregada para el tablero si un negocio rebasa 1000 pedidos en 30 días.

## IA y búsqueda

- [ ] Probar 10 frases reales («tacos baratos en Coyoacán», «una papelería abierta») y confirmar que cada resultado explica por qué aparece.
- [ ] Confirmar que sin llave la búsqueda sigue funcionando.
- [ ] Pesos del ranking y ubicación por coordenadas: decidir si entra hoy o después.

## App Flutter

- [ ] Probar en un teléfono real: dictado, permisos, el recorrido completo de comprador y el de negocio. No hay emulador en la máquina de desarrollo.
- [ ] Después del hackatón: llave de publicación y Google Play; avisos push; pantalla propia para reportar un problema; avisos de promociones en la app.

## Diseño y marca

- [ ] Revisión de los sellos por una persona especialista nahua, con crédito y pago, antes de salir de la demo (`docs/LOGROS.md`).
- [ ] Confirmar con fuente especializada la interpretación de cada topónimo de `docs/LOGROS.md`.
- [ ] Decidir si hay aviso de privacidad y términos reales; hoy no hay ninguno publicado.

## Cuando termines algo

Bórralo de aquí en la misma PR. El flujo es `feature/*` → `dev` → `stg` → `main`, con CI en verde en cada paso (`AGENTS.md`).
