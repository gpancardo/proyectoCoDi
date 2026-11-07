# Barrio — Identidad visual

> Guía de diseño · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Producto y alcance: ver `PRODUCTO.md` · Voz de marca: ver `VOZ-DE-MARCA.md`
> Estado: **propuesta para discusión** (decisiones abiertas marcadas con 🟡)
>
> **Alcance:** Barrio se muestra hoy en tres superficies: la landing y el registro (`web/`), los mensajes de WhatsApp del bot y, en una fase 2, la app de mostrador. Los componentes de pantalla de §7 (Cobrar, QR, Pagado) son de esa fase 2; la landing usa los mismos tokens, tipografía y reglas.

---

## 1. Nombre

**Barrio** — cobra en tu barrio, sin comisión.

La palabra *barrio* nombra exactamente a quien sirve: unidades económicas pequeñas, creadas por y para los habitantes de una misma localidad (tiendas de abarrotes, misceláneas, puestos de comida, talleres caseros, estéticas). Es cercana, mexicana y no suena a banco.

**Escritura:** `Barrio` con B mayúscula cuando es el nombre de la marca. En la versión corta del logo puede ir en minúsculas (`barrio`). Nunca "BARRIO" en texto corrido.

## 2. Personalidad

Barrio es **el vecino que sabe de tecnología**: confiable porque el dinero llega, cercano porque habla como la gente del barrio.

| Es | No es |
|---|---|
| Cercano, de barrio | Corporativo, bancario |
| Claro y directo | Técnico o financiero |
| Confiable (el dinero llega) | Juguetón al grado de no tomarse en serio |
| Orgulloso de lo local | Folclórico de souvenir (nada de papel picado ni sombreros) |

## 3. Color

La base es un **azul marino** que da seriedad y confianza (se trata de dinero). El color de marca es **mango**, un amarillo-naranja cálido que remite a los toldos, las fachadas pintadas y los letreros de las tienditas. El **teal** se reserva para el estado de "pagado".

### 3.1 Paleta

| Token | Hex | Uso |
|---|---|---|
| `--marino` | `#0B2545` | Texto principal, encabezados, fondo de la pantalla QR |
| `--mango` | `#F5A524` | Color de marca: botón "Cobrar", micrófono, acentos |
| `--crema` | `#FFF8EC` | Fondo general de la app (más cálido que el blanco) |
| `--teal` | `#0F7C75` | Éxito: "✅ Pagado", confirmaciones |
| `--tinta` | `#1A1F2B` | Texto de cuerpo largo |
| `--gris` | `#5B6472` | Texto secundario, etiquetas, ayudas |
| `--rojo` | `#C2392B` | Errores, "sin precio", cobro expirado |
| `--blanco` | `#FFFFFF` | Tarjetas sobre el fondo crema, fondo del QR |

### 3.2 Proporción

- **60%** crema (fondo)
- **25%** marino (texto, encabezados)
- **10%** mango (acción principal)
- **5%** teal y rojo (solo estados)

El mango se reserva para **lo que se toca**. Si todo es mango, nada destaca.

### 3.3 Contraste (WCAG)

Verificado. Todos los pares de uso pasan AA para texto normal (≥ 4.5:1).

| Texto | Fondo | Contraste | Resultado |
|---|---|---|---|
| Marino | Crema | 14.6 : 1 | AAA |
| Marino | Mango | 7.5 : 1 | AAA |
| Tinta | Crema | 15.6 : 1 | AAA |
| Gris | Crema | 5.7 : 1 | AA |
| Blanco | Teal | 5.1 : 1 | AA |
| Blanco | Rojo | 5.4 : 1 | AA |
| Crema | Marino | 14.6 : 1 | AAA |
| Mango | Marino | 7.5 : 1 | AAA |

**Reglas importantes:**
- Sobre el botón mango el texto va en **marino, nunca en blanco** (blanco sobre mango no pasa contraste). Esto también ayuda a leer bajo el sol.
- **Texto mango solo sobre fondo marino.** Sobre crema o blanco no se lee.

### 3.4 Tokens CSS

```css
:root {
  /* Marca */
  --marino: #0B2545;
  --mango:  #F5A524;
  --mango-presionado: #DB8E12;

  /* Fondos */
  --crema:  #FFF8EC;
  --blanco: #FFFFFF;

  /* Texto */
  --tinta:  #1A1F2B;
  --gris:   #5B6472;

  /* Estados */
  --teal:   #0F7C75;   /* pagado */
  --rojo:   #C2392B;   /* error / sin precio */

  /* Superficies */
  --borde:  #E8DFCF;
  --sombra: 0 2px 8px rgba(11, 37, 69, 0.08);
  --niebla: #E8EDF4;   /* burbuja de la persona en el chat de ejemplo */
}
```

No hay modo oscuro en el MVP: la app se usa en la calle y a pleno sol, donde el fondo claro se lee mejor. La única pantalla oscura es la del QR (ver §7).

## 4. Tipografía

Una sola familia para todo, para cargar rápido en celulares de gama media y con señal débil.

| Rol | Fuente | Peso | Tamaño (móvil) |
|---|---|---|---|
| Total a cobrar | Plus Jakarta Sans | 800 | 56 px |
| Títulos de pantalla | Plus Jakarta Sans | 700 | 24 px |
| Botones | Plus Jakarta Sans | 700 | 20 px |
| Items de la cuenta | Plus Jakarta Sans | 500 | 18 px |
| Texto normal | Plus Jakarta Sans | 400 | 17 px |
| Ayudas y etiquetas | Plus Jakarta Sans | 500 | 14 px |

```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;700;800&display=swap');

body {
  font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
  font-size: 17px;
  line-height: 1.5;
  color: var(--tinta);
  background: var(--crema);
}

.monto { font-variant-numeric: tabular-nums; } /* los números no "bailan" al cambiar */
```

**Por qué Plus Jakarta Sans:** es geométrica y moderna, pero con terminaciones redondas que la hacen amable. Sus números son muy legibles, que es lo que más importa aquí.

**Reglas:**
- Tamaño mínimo de texto: **14 px**. El usuario lee con prisa y a un brazo de distancia.
- Montos siempre con signo y sin decimales cuando son cerrados: `$55`, no `$55.00 MXN`.
- Nada en MAYÚSCULAS SOSTENIDAS salvo etiquetas muy cortas.

## 5. Logotipo

**Concepto:** un toldo de tiendita visto de frente, con sus franjas, sobre una fachada que lleva un pequeño código QR. Junto al símbolo, la palabra **Barrio** en Plus Jakarta Sans 800 con tracking de −2 px.

```
   ▄▀▄▀▄▀▄▀▄        ← toldo (franjas mango / crema)
   █ ▪ ▫ ▪ █        ← fachada con QR estilizado (marino)
     Barrio
```

**Variantes:**
- **Principal (fondo claro):** símbolo en mango, crema y marino; `Barrio` en marino.
- **Invertida (fondo marino):** símbolo con contorno crema; `Barrio` en crema o en mango.
- **Corta (stickers, playeras, sellos):** `barrio` en minúsculas, marino sobre mango.
- **Ícono de app:** solo el toldo con QR sobre fondo marino.

**Área de respeto:** la altura de la "B" alrededor de todo el logo.

🟡 Para el hackathon basta con la versión tipográfica. El símbolo se integra si queda tiempo el domingo.

## 6. Iconos e ilustración

- **Iconos:** Lucide (gratis, línea de 2 px, redondeados). Tamaño mínimo 24 px; en botones principales, 32 px.
- **Iconos clave:** `mic` (dictar), `keyboard` (escribir), `qr-code` (cobrar), `check-circle` (pagado), `store` (negocio), `bar-chart-3` (hoy).
- **Ilustración:** no se usa en el MVP. Si se agrega después: formas planas, paleta propia, personas reales del barrio; nada de clip art ni estereotipos.
- **Fotos:** no se usan en la app. En el pitch, solo fotos propias de comercios reales (con permiso del dueño).

## 7. Componentes

### Botón principal ("Cobrar $55")
- Fondo `--mango`, texto `--marino` 700, 20 px.
- Alto mínimo **64 px**, ancho completo, esquinas de 16 px.
- Al presionar: `--mango-presionado` + vibración corta.
- Uno solo por pantalla.

### Botón de micrófono
- Círculo de **96 px**, fondo `--mango`, icono `mic` en marino.
- Grabando: anillo pulsante mango y texto "Te escucho…" debajo.

### Caja de texto
- Fondo blanco, borde `--borde` 2 px, esquinas de 12 px, 18 px de texto.
- Placeholder: *"Escribe el pedido, ej. 2 cocas 600 y unas sabritas"*.
- Al enfocarla, el borde cambia a marino.
- **Siempre visible junto al micrófono**, nunca escondida.

### Tarjeta de cuenta
- Fondo blanco sobre crema, sombra suave.
- Cada item: nombre a la izquierda, `cantidad × precio` en gris, subtotal a la derecha en marino.
- Item "sin precio": fondo rojo muy claro, icono de alerta y campo para escribir el monto.
- Total al pie en 56 px, 800.

### Pantalla QR (la que ve el cliente)
- Es la **única pantalla oscura**: fondo `--marino`, para que el QR blanco resalte y el cliente sepa que esa pantalla es para él.
- QR sobre cuadro blanco con margen amplio, lo más grande posible.
- Arriba: nombre del negocio en crema. Abajo: monto en mango, 56 px.
- Estado "Esperando que te paguen…" en crema con animación suave.

### Pagado
- Toda la pantalla cambia a `--teal` con ✅ grande, monto y "¡Pagado!" en blanco.
- Sonido corto de caja registradora y vibración.
- Regresa sola a la pantalla de cobro a los 3 s.

### Mensajes de WhatsApp (el bot)
- Mismas reglas que la interfaz: de tú, corto, sin emoji. La única excepción es el ✅ de "¡Pagado!". El 👍 no es adorno: es la forma en que el negocio acepta un pedido.
- Negritas con *asteriscos* para el negocio, el total y el código. Montos como `$55` y `$1,240`.
- En charla, máximo 2 líneas. La cuenta va como tarjeta de texto: negocio, productos, total, dónde recoger.
- Siempre texto; si la persona mandó voz, también va una nota de voz.

## 8. Espaciado y forma

- Escala de espaciado: **4, 8, 12, 16, 24, 32, 48 px**.
- Margen lateral de pantalla: **16 px**.
- Esquinas: 12 px (campos), 16 px (botones y tarjetas), círculo (micrófono).
- Áreas táctiles mínimas de **48 × 48 px** (se usa con una mano y a veces con prisa).

## 9. Voz y tono

Resumen; la guía completa está en `VOZ-DE-MARCA.md`.

| Situación | ✅ Sí | ❌ No |
|---|---|---|
| Botón principal | "Cobrar $55" | "Generar solicitud de pago" |
| Pago recibido | "¡Pagado! Ya te llegaron $55" | "Transacción liquidada exitosamente" |
| Ruido | "No te escuché bien, ¿me lo escribes?" | "Error de reconocimiento de voz" |
| Producto desconocido | "No tengo precio para *chicles*, ¿cuánto es?" | "Producto no encontrado en catálogo" |
| Resumen | "Hoy vendiste $1,240 en 38 cobros" | "Volumen transaccional diario" |
| Sin comisión | "Te llega completo, sin comisión" | "0% de tasa de descuento" |

## 10. Checklist rápido para el equipo

- [ ] Tokens CSS de §3.4 copiados al proyecto.
- [ ] Plus Jakarta Sans cargada (400, 500, 700, 800).
- [ ] Texto sobre mango siempre en marino; texto mango solo sobre marino.
- [ ] Un solo botón mango por pantalla.
- [ ] Micrófono y caja de texto visibles al mismo tiempo.
- [ ] Pantalla QR en marino; pantalla "Pagado" en teal.
- [ ] Ninguna palabra de la lista prohibida en la interfaz (ver `VOZ-DE-MARCA.md`).
- [ ] Probar en un Android real, a pleno sol.
