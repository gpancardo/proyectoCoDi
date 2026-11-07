# BarrioPass — Identidad visual

> Guía de diseño · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Producto y alcance: ver `PRODUCTO.md`
> Estado: **propuesta para discusión** (decisiones abiertas marcadas con 🟡)

---

## 1. Nombre

**BarrioPass** — cobra en tu barrio, sin comisión.

Sigue la misma fórmula que **DocPass**: *[a quién sirve] + Pass*.

- **DocPass** → el pase del doctor a un consultorio.
- **BarrioPass** → el pase del comercio de barrio a los pagos digitales.

La palabra *barrio* nombra exactamente al usuario: unidades económicas pequeñas, creadas por y para los habitantes de una misma localidad (tiendas de abarrotes, misceláneas, puestos de comida, talleres caseros, estéticas). Es cercana, mexicana y no suena a banco.

🟡 Alternativas si el equipo quiere otra: **TienditaPass** (más concreto, pero deja fuera talleres y estéticas), **CobroPass** (más funcional, menos cálido).

**Escritura:** siempre `BarrioPass`, una palabra, B y P mayúsculas. Nunca "Barrio Pass", "barriopass" ni "BP".

## 2. Personalidad

DocPass es **confiable, clínico y profesional**. BarrioPass toma esa confianza y le quita la bata: es **el vecino que sabe de tecnología**.

| Es | No es |
|---|---|
| Cercano, de barrio | Corporativo, bancario |
| Claro y directo | Técnico o financiero |
| Confiable (el dinero llega) | Juguetón al grado de no tomarse en serio |
| Orgulloso de lo local | Folclórico de souvenir (nada de papel picado ni sombreros) |

## 3. Color

La paleta **comparte la base azul marino de DocPass** para que se lean como familia, y cambia el acento: donde DocPass usa teal como color principal, BarrioPass usa **mango**, un amarillo-naranja cálido que remite a los toldos, las fachadas pintadas y los letreros de las tienditas. El teal se conserva, pero solo para el estado de "pagado".

🟡 **Ajuste pendiente:** los valores de marino y teal son aproximados. Si se tienen los hex oficiales de DocPass, se reemplazan aquí para que la familia sea exacta.

### 3.1 Paleta

| Token | Hex | Uso | Relación con DocPass |
|---|---|---|---|
| `--marino` | `#0B2545` | Texto principal, encabezados, fondo de la pantalla QR | **Compartido** |
| `--mango` | `#F5A524` | Color de marca: botón "Cobrar", micrófono, acentos | Nuevo, propio de BarrioPass |
| `--crema` | `#FFF8EC` | Fondo general de la app | Nuevo (más cálido que el blanco clínico) |
| `--teal` | `#0F7C75` | Éxito: "✅ Pagado", confirmaciones | **Compartido**, pero en rol secundario |
| `--tinta` | `#1A1F2B` | Texto de cuerpo largo | — |
| `--gris` | `#5B6472` | Texto secundario, etiquetas, ayudas | — |
| `--rojo` | `#C2392B` | Errores, "sin precio", cobro expirado | — |
| `--blanco` | `#FFFFFF` | Tarjetas sobre el fondo crema, fondo del QR | — |

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

**Regla importante:** sobre el botón mango el texto va en **marino, nunca en blanco** (blanco sobre mango no pasa contraste). Esto también ayuda a leer bajo el sol.

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

**Por qué Plus Jakarta Sans:** es geométrica y moderna (se siente de la misma familia que una marca tech como DocPass) pero con terminaciones redondas que la hacen amable. Sus números son muy legibles, que es lo que más importa aquí.

🟡 Si DocPass ya usa una fuente definida, se puede usar esa misma para los títulos y dejar Plus Jakarta Sans para los números.

**Reglas:**
- Tamaño mínimo de texto: **14 px**. El usuario lee con prisa y a un brazo de distancia.
- Montos siempre con signo y sin decimales cuando son cerrados: `$55`, no `$55.00 MXN`.
- Nada en MAYÚSCULAS SOSTENIDAS salvo etiquetas muy cortas.

## 5. Logotipo

**Concepto:** un toldo de tiendita visto de frente, con sus franjas, que en la franja central forma un pequeño código QR de 3×3. Junto al símbolo, el nombre en Plus Jakarta Sans 800.

```
   ▄▀▄▀▄▀▄▀▄        ← toldo (franjas mango / crema)
   █ ▪ ▫ ▪ █        ← fachada con QR estilizado (marino)
   BarrioPass
```

- **Símbolo:** franjas en mango y crema; el QR en marino.
- **Palabra:** `Barrio` en marino, `Pass` en mango (eco de cómo DocPass separa visualmente sus dos partes).
- **Versión app icon:** solo el toldo con QR sobre fondo marino.
- **Área de respeto:** la altura de la "B" alrededor de todo el logo.

🟡 Para el hackathon basta con la versión tipográfica (`Barrio` marino + `Pass` mango). El símbolo se dibuja si queda tiempo el domingo.

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
- Item "sin precio": borde izquierdo rojo de 4 px y campo para escribir el monto.
- Total al pie en 56 px, 800.

### Pantalla QR (la que ve el cliente)
- Es la **única pantalla oscura**: fondo `--marino`, para que el QR blanco resalte y el cliente sepa que esa pantalla es para él.
- QR sobre cuadro blanco con margen amplio, lo más grande posible.
- Arriba: nombre del negocio en crema. Abajo: monto en mango, 56 px.
- Estado "Esperando pago…" en crema con animación suave.

### Pagado
- Toda la pantalla cambia a `--teal` con ✅ grande, monto y "¡Pagado!" en blanco.
- Sonido corto de caja registradora y vibración.
- Regresa sola a la pantalla de cobro a los 3 s.

## 8. Espaciado y forma

- Escala de espaciado: **4, 8, 12, 16, 24, 32, 48 px**.
- Margen lateral de pantalla: **16 px**.
- Esquinas: 12 px (campos), 16 px (botones y tarjetas), círculo (micrófono).
- Áreas táctiles mínimas de **48 × 48 px** (se usa con una mano y a veces con los dedos sucios o con prisa).

## 9. Voz y tono

Habla como el vecino que te explica algo en la tienda: de tú, corto y concreto.

| Situación | ✅ Sí | ❌ No |
|---|---|---|
| Botón principal | "Cobrar $55" | "Generar solicitud de pago" |
| Pago recibido | "¡Pagado! Ya te llegaron $55" | "Transacción liquidada exitosamente" |
| Ruido | "No te escuché bien, ¿me lo escribes?" | "Error de reconocimiento de voz" |
| Producto desconocido | "No tengo precio para *chicles*, ¿cuánto es?" | "Producto no encontrado en catálogo" |
| Resumen | "Hoy vendiste $1,240 en 38 cobros" | "Volumen transaccional diario" |
| Sin comisión | "Te llega completo, sin comisión" | "0% de tasa de descuento" |

**Palabras prohibidas en la interfaz:** transacción, liquidación, solicitud, procesar, usuario, error (se dice qué pasó y qué hacer).

## 10. Familia con DocPass

| Elemento | DocPass | BarrioPass |
|---|---|---|
| Fórmula del nombre | Doc + Pass | Barrio + Pass |
| Color base | Azul marino | **El mismo** azul marino |
| Color principal | Teal | Mango (teal pasa a "pagado") |
| Fondo | Blanco clínico | Crema cálido |
| Personalidad | Profesional, confiable | Cercano, confiable |
| Usuario | Profesional de la salud | Dueño de comercio de barrio |

Juntas se leen como dos productos de la misma casa: la misma seriedad de fondo, distinto público.

## 11. Checklist rápido para el equipo

- [ ] Tokens CSS de §3.4 copiados al proyecto.
- [ ] Plus Jakarta Sans cargada (400, 500, 700, 800).
- [ ] Texto sobre mango siempre en marino.
- [ ] Un solo botón mango por pantalla.
- [ ] Micrófono y caja de texto visibles al mismo tiempo.
- [ ] Pantalla QR en marino; pantalla "Pagado" en teal.
- [ ] Ninguna palabra de la lista prohibida en la interfaz.
- [ ] Probar en un Android real, a pleno sol.
