# Barrio — Voz de marca

> Guía de voz y tono · DevDay Exchange Community Hackathon CDMX (7–8 nov 2026)
> Identidad visual: ver `DESIGN.md` · Producto: ver `PRODUCTO.md`

---

## 1. Quiénes somos al hablar

**Barrio habla como el vecino que sabe de tecnología.** Te habla de tú, va al grano y te resuelve. No suena a banco ni a startup: suena a alguien del barrio que ya probó la herramienta y te la recomienda mientras le despachas.

| Le habla a | Tono | Trato |
|---|---|---|
| Dueños de comercios de barrio | Cercano, confiable, directo | De tú, siempre |
| Quienes piden en el barrio | Amable, claro, sin tecnicismos | De tú, siempre |

## 2. Principios

### 2.1 De tú, siempre
"Cobra", "te llegó", "vendiste". Nunca "usted", nunca "el usuario".

### 2.2 Corto, porque no hay tiempo
El dueño está atendiendo con las manos ocupadas. **Ningún mensaje de la interfaz pasa de una línea.** Si necesita dos, sobra una.

### 2.3 Se habla de dinero, no de finanzas
Decimos lo que le pasa a su dinero, no cómo se llama el proceso.

| ✅ Así | ❌ No así |
|---|---|
| Te llega completo | 0% de tasa de descuento |
| Al instante | Liquidación en tiempo real |
| Cobros | Transacciones |

### 2.4 Orgullo local, sin folclor
El barrio se respeta como lo que es: un motor económico. Nada de papel picado, sombreros, "¡órale!" forzado ni caricaturas. Lo mexicano está en cómo hablamos, no en adornos.

### 2.5 Si algo falla, decimos qué hacer
Nunca un mensaje que solo diga que algo salió mal. Siempre: qué pasó, en palabras simples, y el siguiente paso.

## 3. Tono según el momento

La voz es siempre la misma; el tono se ajusta a lo que está pasando.

| Momento | Tono | Ejemplo |
|---|---|---|
| Cobrando | Directo, sin adornos | "Cobrar $55" |
| Esperando el pago | Tranquilo | "Esperando que te paguen…" |
| Pago recibido | Celebración breve | "¡Pagado! Ya te llegaron $55" |
| No se entendió la voz | Calmado, ofrece alternativa | "No te escuché bien, ¿me lo escribes?" |
| Falta un precio | Pregunta concreta | "No tengo precio para chicles, ¿cuánto es?" |
| El cobro expiró | Sin culpa, con salida | "Este cobro ya venció. ¿Lo generamos otra vez?" |
| Sin internet | Claro y práctico | "Sin señal. Revisa tu conexión e inténtalo de nuevo." |
| Fin del día | Reconocimiento | "Hoy vendiste $1,240 en 38 cobros" |
| Primera vez | Con calma, sin tecnicismos | "Dime qué te pidieron y yo armo la cuenta" |

## 4. Vocabulario

### Palabras que sí usamos
cobrar · te llegó · completo · al instante · tu negocio · vendiste · escanea · cuenta · pagado · hoy · sin comisión

### Palabras que no usamos

| ❌ Evitar | ✅ Usar |
|---|---|
| Transacción | Cobro, venta |
| Liquidación | Te llegó |
| Procesar | Cobrar |
| Solicitud de pago | Cobro |
| Usuario | Tú / tu cliente |
| Comercio afiliado | Tu negocio |
| Fintech, API, webhook (en la interfaz) | No se mencionan |
| Error | Qué pasó + qué hacer |
| Exitosamente | (se omite) |

### Nombres de cosas en la app

| Elemento | Se llama |
|---|---|
| Inicio de la app | Descubrir |
| Búsqueda con el agente | Buscar con Barrio |
| Lista de lo que se va a pagar | La cuenta |
| Pedido en curso | Tu pedido |
| Clave para recoger | Tu código |
| Resumen del negocio | Hoy |
| Lista de productos del negocio | Tus precios |
| Persona que compra | Tu cliente (para el negocio) |

## 5. Textos de interfaz (listos para copiar)

La app standalone (comprador y negocio) va primero. Los textos de Barrio Mostrador, el cobro por dictado en el local, son posteriores al hackathon y quedan al final.

### App standalone

Frases breves, acción siguiente clara y estados que no dependan solo del color. El recorrido principal funciona con búsqueda y filtros tocables; el dictado, si llega, es una opción de entrada.

| Momento | Texto |
|---|---|
| Cotización | Revisa los productos y el total antes de confirmar. |
| Espera de pago | Abre la app de tu banco para aprobar el cobro de $120. |
| Pagado | ✅ ¡Pagado! Tu código para recoger: 4821 |
| Pedido listo | Tu pedido ya está listo. Pasa a {dirección}. |
| Negocio cerrado | Este negocio está cerrado. Mira otras opciones cercanas. |
| Resumen al negocio | Hoy vendiste $1,240 en 38 cobros. Lo que más salió: {producto}. |

En la app, el negocio usa acciones visibles para aceptar, rechazar, marcar listo, consultar el resumen y cambiar disponibilidad.

### Barrio Mostrador (posterior al hackathon)

#### Pantalla Cobrar
- Título: **Cobrar**
- Botón de micrófono (aria-label): **Dictar pedido**
- Mientras graba: **Te escucho…**
- Placeholder de la caja de texto: **Escribe el pedido, ej. 2 cocas 600 y unas sabritas**
- Botón junto a la caja: **Armar cuenta**
- Arriba, total del día: **Hoy: $1,240**

#### Pantalla La cuenta
- Título: **La cuenta**
- Item sin precio: **No tengo precio para {producto}, ¿cuánto es?**
- Enlace para corregir: **Cambiar**
- Volver a capturar: **Dictar otra vez** · **Escribir otra vez**
- Botón principal: **Cobrar ${total}**

#### Cobro CoDi por push
- Encabezado: **Aprueba el cobro en tu banco**
- Instrucción: **Te mandamos un cobro por ${total}.**
- Estado: **Esperando la confirmación…**
- Al vencer: **Este cobro ya venció. Manda otro cuando estés listo.**

#### Pagado
- **¡Pagado!**
- **Ya te llegaron ${total}**

#### Hoy
- Título: **Hoy**
- Total: **Vendiste ${total}**
- Conteo: **en {n} cobros**
- Más vendido: **Lo que más salió: {producto}**
- Vacío: **Todavía no hay cobros hoy. El primero es el bueno.**

#### Mensajes de problema

| Situación | Texto |
|---|---|
| Voz no entendida | No te escuché bien, ¿me lo escribes? |
| Sin micrófono | Activa el micrófono para dictar, o escribe el pedido. |
| No se entendió el pedido | No entendí el pedido. ¿Me lo dices de otra forma? |
| Cobro expirado | Este cobro ya venció. ¿Lo generamos otra vez? |
| Sin internet | Sin señal. Revisa tu conexión e inténtalo de nuevo. |
| No se pudo iniciar el cobro | No pudimos mandar el cobro. Inténtalo de nuevo en un momento. |

## 6. Mensajes de marca

### Tagline principal
**Cobra en tu barrio, sin comisión.**

### Alternativas
- *Dímelo y te lo cobro.* (Barrio Mostrador)
- *Tú dices, ellos escanean, te llega completo.*
- *Lo de tu barrio, cobrado al instante.*
- *Pide en tu barrio. Paga con un toque.* (para quien compra)

### En una frase, según a quién

| Audiencia | Mensaje |
|---|---|
| Dueño de tiendita | "Te llega el pedido con la cuenta hecha, lo aceptas y el dinero te llega completo, sin comisión." |
| Cliente que paga | "Ve el total antes de pedir y aprueba el cobro en la app de tu banco." |
| Jurado del hackathon | "Una app para encontrar y pedir en negocios de barrio: el servidor calcula el total, el negocio acepta y pey cobra con CoDi, sin comisión." |
| pey | "Una vertical nueva de comercios generando volumen en su API, empezando por el comercio de barrio." |

## 7. Reglas de escritura

- **Montos:** `$55`, `$1,240`. Sin decimales si son cerrados, sin "MXN", sin "pesos" en la interfaz.
- **Números:** en dígitos siempre (`38 cobros`, no "treinta y ocho cobros").
- **Signos:** usamos `¿` y `¡` de apertura. Máximo un `!` por mensaje y solo para celebrar.
- **Mayúsculas:** solo al inicio de la frase y en nombres propios. Nada en MAYÚSCULAS SOSTENIDAS.
- **Emoji:** no en la interfaz. La única excepción es el ✅ de "¡Pagado!", que funciona como ícono.
- **Nombre de la marca:** `Barrio`, con B mayúscula. En la versión corta del logo puede ir en minúsculas.
- **Género:** neutro cuando se pueda ("tu cliente", "quien paga").

## 8. Prueba rápida antes de publicar un texto

1. ¿Se entiende leyéndolo en 2 segundos con la mano ocupada?
2. ¿Lo diría así alguien del barrio en voz alta?
3. ¿Usa alguna palabra de la lista "no usamos"?
4. Si es un problema, ¿dice qué hacer?
5. ¿Cabe en una línea en un celular?

Si alguna respuesta falla, se reescribe.
