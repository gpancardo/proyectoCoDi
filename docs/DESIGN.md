# Barrio: identidad visual

DevDay Exchange Community Hackathon CDMX, 7 y 8 de noviembre de 2026.
Producto y alcance en `PRODUCTO.md`. Voz en `VOZ-DE-MARCA.md`.

Estado: propuesta. Lo que sigue abierto lleva la etiqueta *(abierto)*.

Alcance: la app standalone de comprador y negocio, más la landing de `web/`. Pantallas del MVP: Descubrir, Buscar con Barrio, ficha del negocio, cuenta, cobro, pagado, y el panel del negocio. El dictado por voz y el cobro en mostrador (Barrio Mostrador) son posteriores al hackathon y no definen el diseño actual.

---

## 1. Nombre

**Barrio**. Cobra en tu barrio, sin comisión.

Nombra a quien servimos: tiendas, fondas, puestos y talleres de una misma colonia. Es mexicano, cercano y no suena a banco.

Se escribe `Barrio`, con mayúscula inicial. En la versión corta del logo puede ir `barrio`. Nunca BARRIO en texto corrido.

"Sin comisión" se refiere al cobro con CoDi. Si el pago cae en el respaldo con tarjeta, no se promete.

## 2. Carácter

Barrio es el vecino que sabe de tecnología. Confiable porque el dinero llega, cercano porque habla como la gente de la colonia.

No es corporativo ni bancario, ni técnico, ni infantil. Tampoco folclórico: nada de papel picado ni sombreros. Lo mexicano está en cómo hablamos y en los objetos reales del barrio (el toldo, el letrero pintado, el ticket de la tienda), no en adornos.

## 3. Reglas anti-plantilla

El diseño se reconoce por lo que elige, no por los defaults de una librería. Estas reglas se revisan en cada pantalla.

- **Una forma por función.** Radios distintos según el objeto (ver §10). Si todo mide 16 px, parece plantilla.
- **Sin sombras en reposo.** En la app separamos con líneas de 2 px en marino; en la landing, con paneles de color plano que se tocan. La única sombra es la de un diálogo abierto.
- **Sin tarjetas por reflejo.** Listas y pasos van como renglones con regla, como una cuenta escrita a mano. La tarjeta se reserva para un objeto real: el ticket, la ficha de un negocio en un listado.
- **Sin ilustración genérica ni íconos en cajitas.** Un ícono repetido tres veces con el mismo dibujo se quita.
- **Sin degradados, brillos ni vidrio esmerilado.** La interfaz se usa a pleno sol y con prisa.
- **Movimiento con motivo** (ver §8): solo transform y opacidad, ligado al scroll o a una acción, y siempre con versión quieta.
- **Ejemplos con contenido real.** Placeholders distintos en cada fila, montos plausibles, negocios que existen en una colonia. Nunca "Lorem", "Producto 1" ni tres campos con el mismo ejemplo.
- **Ningún texto repetido en cada fila.** Las etiquetas de columna van una vez arriba; cada campo lleva `aria-label`.
- **Cada recurso decorativo significa algo.** El toldo aparece porque es la fachada de la tienda, no para llenar espacio.
- **Copy concreto.** Nada de "así de fácil", "sin complicaciones" ni dos frases paralelas tipo eslogan. Se dice qué pasa y cuánto tarda.
- **Jerarquía real.** El peso 800 va solo en ancho expandido: titulares, monto y código. El resto, 400 a 700 en ancho normal.
- **Ninguna promesa sin respaldo.** Si el producto no lo hace hoy, la landing no lo dice.

## 4. Color

Base en azul marino, que da seriedad porque se trata de dinero. El color de marca es el mango, un amarillo naranja de toldo y letrero de tienda. El teal queda para "pagado".

| Token | Hex | Uso |
|---|---|---|
| `--marino` | `#0B2545` | Texto principal, títulos, líneas, banda del negocio |
| `--mango` | `#F5A524` | Botón principal, franjas del toldo, código de recoger |
| `--crema` | `#FFF8EC` | Fondo general |
| `--teal` | `#0F7C75` | Solo "Pagado" y confirmaciones |
| `--tinta` | `#1A1F2B` | Texto de lectura larga |
| `--gris` | `#5B6472` | Texto secundario, ayudas y placeholders |
| `--rojo` | `#C2392B` | Errores, sin precio, cobro vencido |
| `--blanco` | `#FFFFFF` | Campos, ticket, franjas blancas del toldo |
| `--borde` | `#E8DFCF` | Separadores suaves, nunca bordes de campos |
| `--trazo` | `#7D7666` | Borde de campos y de botones secundarios |
| `--niebla` | `#E8EDF4` | Estado presionado de botones secundarios |

El mango es para lo que se toca y para el toldo. Texto sobre mango siempre en marino. Texto en mango solo sobre marino. Crema, blanco y marino llevan casi todo; teal y rojo aparecen solo cuando hay un estado que comunicar.

### Contraste

Calculado con la fórmula de luminancia de WCAG 2.

| Par | Contraste |
|---|---|
| Marino sobre crema | 14.6 |
| Marino sobre mango | 7.5 |
| Mango sobre marino | 7.5 |
| Tinta sobre crema | 15.6 |
| Gris sobre crema | 5.7 |
| Gris sobre blanco (placeholders) | 6.0 |
| Blanco sobre teal | 5.0 |
| Blanco sobre rojo | 5.4 |
| `--trazo` sobre blanco | 4.5 |
| `--trazo` sobre crema | 4.3 |

Todos pasan AA para texto. Los bordes de campos pasan el 3:1 de componentes de interfaz; por eso no usan `--borde`, que da 1.3:1 y no se ve al sol.

No hay modo oscuro en el MVP: la app se usa en la calle y el fondo claro se lee mejor.

## 5. Tipografía

Una sola familia variable: **Archivo**, de Omnibus-Type, con eje de ancho, servida desde Google Fonts con `display=swap` y solo en los cortes que se usan.

| Rol | Corte | Tamaño en móvil |
|---|---|---|
| Titular de portada | 800, ancho 125 | 32 a 54 px, fluido |
| Título de sección | 800, ancho 112 | 24 a 34 px |
| Total, código de recoger | 800, ancho 112 a 125 | 26 px (ticket), 38 px (código); 56 px en la pantalla de cobro |
| Títulos de pasos y botones | 700, ancho normal | 19 a 20 px |
| Texto | 400, ancho normal | 17 px |
| Etiquetas y ayudas | 500, ancho normal | 14 px |

Por qué Archivo: viene de la tradición de rotulación y señalización, y su eje de ancho deja que los titulares se vean como letrero (expandidos) sin cambiar de familia. Sus números tabulares son claros, que es lo que más importa en una cuenta.

```css
body { font: 400 17px/1.55 'Archivo', system-ui, sans-serif; }
h1   { font-weight: 800; font-stretch: 125%; letter-spacing: -0.01em; }
.monto { font-variant-numeric: tabular-nums; }
```

Reglas:
- Texto mínimo de 14 px. Tamaños en `rem` o `clamp()` donde escalan, para respetar el zoom del sistema.
- Tracking: nunca por debajo de −0.02em.
- Montos con signo y sin decimales cuando son cerrados: `$55`, no `$55.00 MXN`.
- Sin mayúsculas sostenidas salvo etiquetas muy cortas.

## 6. Logotipo

Un toldo de tienda visto de frente, con franjas mango y crema, sobre una fachada que lleva un pequeño QR. Junto al símbolo, la palabra `Barrio` en Archivo 800, ancho 112, tracking −0.02em.

Variantes:
- **Principal, fondo claro:** símbolo en mango, crema y marino; palabra en marino.
- **Invertida, fondo marino:** símbolo con contorno crema; palabra en crema o mango.
- **Corta (stickers, playeras, sellos):** `barrio` en minúsculas, marino sobre mango.
- **Ícono de app:** solo el toldo con QR sobre fondo marino.

Área de respeto: la altura de la B alrededor de todo el logo. El símbolo actual es definitivo para el hackathon.

## 7. Componentes

### El toldo

Franja de 14 px con rayas de 32 px y una línea de 2 px en marino debajo. En fondo claro alterna mango y blanco; sobre marino, mango y crema. En la landing aparece en el toldo del changarrito y en el pie, donde las letras de `barrio` se construyen sobre franjas mango y blanco. En la app, solo en la cabecera de la ficha de un negocio. No se usa de relleno en otros lugares.

### Botones

- **Principal:** fondo `--mango`, texto `--marino` 700, borde de 2 px en marino, esquinas de 8 px, alto mínimo 64 px. Presionado: `--mango-presionado` y baja 1 px, con vibración corta en la app. Uno por bloque visible.
- **Secundario:** mismo tamaño y borde, fondo transparente.
- **De texto:** subrayado, para acciones menores ("Agregar otro producto").
- Los botones llevan siempre un verbo ("Confirmar pedido", "Aprobar en mi banco"). Nunca "Continuar" ni "Enviar" a secas.

### Campos

- Fondo blanco, borde de 1.5 px en `--trazo`, esquinas de 6 px, texto de 18 px.
- Foco: borde y anillo de 1.5 px en marino, más el contorno de foco visible de 3 px.
- Error: borde y anillo en rojo, con el mensaje en texto que dice qué hacer.
- Etiqueta arriba, en negrita, siempre visible (no solo placeholder). Ayuda abajo, en 14 px.
- Los placeholders son ejemplos reales y no se repiten entre filas.

### Filtros y búsqueda (Descubrir y Buscar con Barrio)

- Filtros como fichas conmutables de 48 px de alto con texto y estado (`aria-pressed`): activo se ve con relleno marino y texto crema, además de un ✓ en texto, no solo por color.
- Buscar con Barrio es una caja de texto visible. Cada resultado muestra por qué aparece ("Vende taco de canasta, abre ahora, a 400 m"), y los filtros se pueden corregir a mano.
- Carruseles con desplazamiento nativo, la siguiente tarjeta asomando para indicar que hay más, sin autoplay ni puntos.

### Ficha de negocio

Es un objeto real, así que lleva marco: borde de 2 px en marino, esquinas de 6 px, sin sombra, con el toldo en la cabecera. Muestra nombre, categoría, distancia o zona, si está abierto, disponibilidad y desde cuánto salen los precios. Una sola acción principal por ficha.

### Cuenta (ticket)

Fondo blanco, borde de 2 px en marino, esquinas de 6 px, sin sombra.
- Cabecera con nombre y dirección del negocio, separada por una línea punteada.
- Renglones: nombre a la izquierda con `cantidad × precio` en gris debajo, subtotal a la derecha.
- Total en 800 expandido.
- Muestra negocio, productos, cantidad, subtotal, total y forma de entrega antes de confirmar.
- Producto sin precio: fondo rojo claro, ícono de alerta y mensaje con texto.

### Pasos y listas

Renglones separados por reglas de 2 px en marino, con el número en 800 expandido a la izquierda. Sin tarjetas, sin círculos, sin sombra.

### Estado del pedido

Cada estado lleva texto y una forma distinta, nunca solo color:

| Estado | Texto | Marca |
|---|---|---|
| Pendiente | Esperando al negocio | reloj |
| Aceptada | Aprueba el cobro en tu banco | billete |
| Pagada | ¡Pagado! | ✅ y teal |
| Lista | Ya puedes pasar | bolsa |
| Entregada | Pedido recibido | marca de confirmación y teal |
| Rechazada, vencida o cancelada | Pedido cancelado, con el motivo | tache y rojo |

### Pagado

Pantalla en `--teal` con ✅, el monto, "¡Pagado!" y el código de recoger en 800 expandido, grande. **No se cierra sola:** el código tiene que seguir visible hasta que la persona lo descarte. Vibración corta; el sonido es opcional y apagado por defecto.

### Confirmación de entrega

Cuando el negocio marca **Listo**, la persona ve el código de recogida y una acción principal: **Confirmar que lo recibí**. La pantalla conserva el fondo teal y el código legible; debajo va el enlace discreto **Reportar un problema**, que abre un correo prellenado con pedido, negocio y total. No se culpa a la persona ni se cierra la pantalla sola.

### Panel del negocio

Acciones visibles y de un solo toque: aceptar, rechazar, marcar listo, abrir o cerrar, publicar cupón y ver el resumen del día. Un pedido nuevo muestra cuánto falta para que se cancele por falta de respuesta (8 minutos). El interruptor de abierto o cerrado lleva texto ("Abierto", "Cerrado"), no solo posición.

### Dictado por voz

El micrófono vive junto a la caja de búsqueda de **Buscar con Barrio**, nunca como sustituto de texto. En escucha muestra un estado visible y detiene la animación con `prefers-reduced-motion`; si no hay permiso o reconocimiento, explica cómo activarlo y permite escribir sin fricción.

## 8. Landing y movimiento

La landing (`web/index.html`, `landing.css`, `landing.js`) es un cartel de calle: paneles de color plano que se tocan, titulares en minúsculas a todo volumen y el changarrito montado sobre la costura entre el campo mango y la banda marino.

- **Titulares de la landing** en Archivo 800, ancho 125, en minúsculas, como la versión corta del logo. Dos líneas como máximo en cualquier ancho. La interfaz de la app sigue en mayúscula inicial.
- **Secciones**, en orden: portada; la barra de etapas del pedido, con anchos que siguen el tiempo real (la espera del negocio, hasta 8 minutos, es la más larga); "arma tu cuenta", donde el titular es un campo de texto que se vuelve ticket con total; el mosaico para negocios; las preguntas como fichas de archivero (una abierta a la vez, `<details name>`); el cierre con los tres pasos para registrar el negocio, que lleva a la app (`app.html`, con una sola cuenta para comprar o vender); y el pie con `barrio` construido como toldo.
- **Sin fotos ni videos.** Todo lo visual se dibuja o se construye en código: el changarrito en 3D, el dibujo SVG de respaldo y fragmentos de interfaz (`data-ui`) con números que cuadran.
- **Precios de muestra** en "arma tu cuenta" (`web/cuenta.mjs`), marcados como tales en la página. En la app el total lo calcula el backend.

### Changarrito 3D

`web/changarrito.js`, Three.js 0.170 desde jsDelivr con `importmap`, geometría procedural (sin modelos descargados).
- Sombreado tipo cartel (`MeshToonMaterial` con tres tonos) y contorno marino de calcomanía; solo colores de §4.
- Toldo de franjas mango y blanco con faldón ondulado, rótulo "doña lupe" pintado con Archivo, canasta, jarra de horchata, refrescos y un letrero tipo QR genérico (no es un código real).
- Se carga después de pintar, solo si hay WebGL; si no, queda el SVG plano. Dibuja solo cuando está a la vista y algo cambió; densidad de píxeles tope 2.

### Movimiento

- **Firma:** el changarrito entra con una cortina (clip-path) y se asienta de 1.12 a 1 en escala.
- **Parallax:** el changarrito gira y la cámara baja con el scroll de la portada; el titular se queda atrás (`animation-timeline: scroll()`); el panel de pedido flota en su loseta.
- **Entradas:** titulares, losetas, fichas y diálogo suben 28 px con opacidad al entrar (`animation-timeline: view()`), escalonados. La barra de etapas crece de izquierda a derecha.
- Todo es CSS ligado al scroll (corre en el compositor, bien en teléfono) dentro de `@supports (animation-timeline: view())`. Sin soporte, el contenido se ve completo y quieto.
- `prefers-reduced-motion: reduce` apaga todo: el changarrito queda en una pose fija y no sigue al cursor.

## 9. Accesibilidad

Objetivo: WCAG 2.2 AA. Reglas que ya cumple la landing y que la app debe mantener:

- **Contraste** según §4, incluidos placeholders y bordes de campos.
- **Teclado:** todo funciona sin ratón, con orden lógico y contorno de foco de 3 px en marino (crema sobre marino). Enlace "Saltar al contenido" al inicio.
- **Objetivos táctiles** de al menos 48 × 48 px, también el logo enlazado.
- **Estructura:** un `h1` por página, encabezados en orden, `lang="es-MX"`, `nav` y `main` etiquetados.
- **Formularios:** etiqueta visible, `autocomplete` correcto, `inputmode` numérico en teléfono y precios, errores con texto y `aria-invalid`, y el foco pasa al primer campo con problema. Los campos obligatorios se anuncian una vez, arriba.
- **Color:** nunca solo color para comunicar estado (§7, Estado del pedido).
- **Movimiento:** respeta `prefers-reduced-motion` (§8). Nada se esconde si el navegador no soporta animaciones ligadas al scroll.
- **Zoom:** usable a 200% sin desplazamiento horizontal; texto en `rem` o `clamp()`.
- **Imágenes decorativas** con `aria-hidden`. Los ejemplos de ticket son texto real, no una imagen con descripción.
- *(abierto)* Pasar la app por un lector de pantalla real (TalkBack) antes de la entrega.

## 10. Espaciado y forma

- Escala de espaciado: 4, 8, 12, 16, 24, 32, 48, 72 px.
- Margen lateral de pantalla: 16 px.
- Esquinas por objeto: botones 8 px, campos 6 px, ticket 6 px, ficha de negocio 6 px, círculo solo para el micrófono. Una forma por función.
- Líneas: 2 px en marino para estructura, 1.5 px en `--trazo` para campos, 1 px en `--borde` para separadores suaves.
- Ritmo vertical variable: en la landing cada panel tiene su altura (portada a pantalla completa, secciones de 96 a 180 px de aire arriba y abajo) y un solo margen lateral `clamp(16px, 2.2vw, 28px)`.

## 11. Voz, resumen

La guía completa está en `VOZ-DE-MARCA.md`.

| Situación | Decimos | No decimos |
|---|---|---|
| Confirmar | "Confirmar pedido" | "Generar solicitud de pago" |
| Pago recibido | "¡Pagado! Tu código para recoger: 4821" | "Transacción liquidada exitosamente" |
| Negocio cerrado | "Este negocio está cerrado. Mira otras opciones cercanas." | "Establecimiento no disponible" |
| Sin resultados | "No encontré eso por tu zona. Prueba con otra palabra." | "Sin coincidencias" |
| Resumen | "Hoy vendiste $1,240 en 38 cobros" | "Volumen transaccional diario" |
| Sin comisión | "CoDi no cobra comisión" | "0% de tasa de descuento" |

## 12. Antes de entregar una pantalla

- Tokens de §4 y Archivo cargada en 400, 500, 700 y 800.
- Texto sobre mango en marino; texto mango solo sobre marino.
- Máximo un botón mango por bloque visible.
- Ninguna tarjeta con sombra, ningún círculo numerado, ningún ícono repetido en cajita.
- Placeholders y ejemplos distintos y con sentido.
- Ninguna promesa que el producto no cumpla hoy.
- Ninguna palabra de la lista de `VOZ-DE-MARCA.md` ni emoji fuera de ✅.
- Revisada en 390 px y en 1280 px, sin desbordes ni texto cortado, y navegada solo con teclado.
- Probada en un Android real, a pleno sol.

## 13. Sellos de logros (imágenes por hacer)

Hoy la app usa medallas provisionales. Faltan cuatro sellos definitivos. Se dibujan una vez y sustituyen estos archivos sin tocar código.

| Archivo en `barrio_app_pey/assets/icons/` | Logro | Color único | Motivo central |
|---|---|---|---|
| `medal-first.svg` | Primera compra | Grana `#9B1B4B` | Huellas de pie en camino: en los códices, las huellas indican un trayecto |
| `medal-bronze.svg` | Ya te conocen en (negocio) | Bronce `#8A4F24` | Casa con voluta de palabra: un lugar donde ya platican contigo |
| `medal-silver.svg` | Conoces (colonia) | Plata `#5F6B78` | Cerro de topónimo, el signo con que los códices nombran un lugar |
| `medal-gold.svg` | De todo en tu barrio | Oro `#8F6A00` | Cuatro cuadrantes con oficios: herramienta, libro, flor, canasta |

Los cuatro colores pasan 4.5:1 sobre crema y blanco. La grana viene de la cochinilla, el tinte americano; no se confunde con `--rojo`, que sigue siendo solo para errores.

**Estilo.** La mezcla de dos referencias:

- **Del sello universitario:** círculo con borde dentado, doble anillo y composición simétrica. Se ve como un sello estampado, no como una medalla de videojuego.
- **De los signos de códice:** figura plana, contorno grueso de grosor parejo, formas cerradas y geométricas, sin perspectiva ni sombras.

**Reglas técnicas.**

- SVG con `viewBox="0 0 64 64"`, fondo transparente y **una sola tinta**. Blanco y detalle se resuelven con huecos.
- Tiene que leerse a 72 px en la lista. Sin texto dentro del sello: el nombre lo pone la app, porque cambia con cada persona.
- El estado "por lograr" lo pinta la app en gris; no se dibuja aparte.

**Cuidado cultural.** Es inspiración gráfica en formas de escritura vivas en la memoria de pueblos originarios, no adorno.

- Nada de deidades, escenas rituales, calendario sagrado, tocados ni personajes "aztecas".
- No copiar signos de un códice ni de ilustraciones existentes: se dibujan de nuevo. Los códices solo enseñan la forma de dibujar.
- Los nombres de los logros van en español. Si algún día se usa náhuatl, lo revisa una persona hablante.
- Antes de publicarlos fuera de la demo, los revisa y acredita una persona diseñadora o especialista nahua, con pago por su trabajo.
- Motivos de todos los oficios, no solo comida.
