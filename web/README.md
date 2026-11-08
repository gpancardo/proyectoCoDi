# Landing de Barrio

La carpeta `web/` es una publicación estática: la landing, el blog, la descarga de Android y la superficie web de la app. No requiere compilación ni contiene secretos. La fuente de verdad de producto y de la API está en [`../docs/PRODUCTO.md`](../docs/PRODUCTO.md) y [`../docs/BACKEND.md`](../docs/BACKEND.md); este archivo solo describe cómo publicar y comprobar la web.

## Qué se publica

| Ruta | Uso |
|---|---|
| `index.html` | Landing pública de Barrio. |
| `app.html` | Cliente web de compra y gestión de negocio; habla con la API HTTPS. |
| `descargar/` | Página de descarga de Android. |
| `blog/` | Contenido editorial para negocios. |
| `config.js` | URLs públicas de Supabase y de la API; nunca secretos. |

La landing es explicativa y puede cargarse sin la API. `app.html` sí requiere que la API Barrio esté disponible y que la URL publicada esté permitida en Supabase Auth.

## Publicación en Netlify

La landing actual responde en `https://jade-paprenjak-a98b06.netlify.app/`. Netlify puede servir esta carpeta tal cual. Configura el sitio así:

- **Base directory:** vacío.
- **Publish directory:** `web`.
- **Build command:** vacío.
- **Node:** no es necesario para publicar; la web no tiene paso de build.

Si se cambia ese dominio, define la URL final, con `https`, sin adivinarla, y reemplaza el origen actual en estos archivos:

```text
web/index.html
web/descargar/index.html
web/blog/*.html
web/robots.txt
web/sitemap.xml
```

Actualiza tanto `canonical` como `og:url`; los enlaces del sitemap y `robots.txt` deben usar el mismo origen. Si se publica en GitHub Pages u otro host, el procedimiento es igual: cambia el origen final, no las rutas relativas.

## Conexión con Auth y la API

1. Conserva en `config.js` únicamente valores públicos: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `API_URL` y `APP_URL`.
2. En Supabase Auth → URL Configuration, establece la URL publicada como **Site URL** e inclúyela en **Redirect URLs**. Para pruebas de preview, agrega solo el preview puntual que se vaya a usar y retíralo después.
3. Si cambia el dominio, limita `ALLOWED_ORIGINS` del backend a ese origen publicado; evita dejar una lista abierta cuando ya haya un dominio definitivo.
4. Comprueba `GET /health` de la API desde el navegador publicado antes de anunciar la app.

No pongas `SUPABASE_SECRET_KEY`, `PEY_API_KEY`, `OPENAI_API_KEY`, secretos de webhook ni credenciales de Netlify en `config.js`, HTML o commits. Una llave publicable de Supabase es pública por diseño; los permisos y toda lógica de dinero siguen en la API.

## Comprobación antes de entregar

```bash
node --test web/cuenta.test.mjs
```

En el sitio publicado, recorre como mínimo:

1. Landing en móvil y escritorio: navegación, `Saltar al contenido`, enlaces de blog y descarga.
2. Registro e inicio de sesión en `app.html` con la URL final de Auth.
3. Descubrir, cotización y pedido con una sesión real de prueba; el total debe venir de la API.
4. El enlace de CoDi de Banxico y todos los enlaces externos con `target="_blank"`.
5. Metadatos al compartir: título, descripción y URL canónica apuntan al mismo dominio publicado.

## Límites deliberados

- Esta carpeta no despliega ni sustituye la API, las migraciones o los secretos de Supabase.
- La landing no promete un flujo que la API no exponga. Las decisiones de alcance se actualizan primero en `docs/PRODUCTO.md`.
- Los importes de los tickets de la landing son demostrativos; en `app.html`, precios, descuentos y totales siempre los calcula el servidor.

Para el estado de lo que queda por conectar en producción —webhook de pey, llave del modelo, cuenta CoDi del negocio y validación física de voz— consulta la sección **Estado desplegado y pendientes** de [`../docs/BACKEND.md`](../docs/BACKEND.md).
