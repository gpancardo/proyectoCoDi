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
| Pantalla principal | Cobrar |
| Lista de lo que se va a cobrar | La cuenta |
| Resumen | Hoy |
| Lista de productos | Tus precios |
| Cliente que paga | Tu cliente |

## 5. Textos de interfaz (listos para copiar)

### Pantalla Cobrar
- Título: **Cobrar**
- Botón de micrófono (aria-label): **Dictar pedido**
- Mientras graba: **Te escucho…**
- Placeholder de la caja de texto: **Escribe el pedido, ej. 2 cocas 600 y unas sabritas**
- Botón junto a la caja: **Armar cuenta**
- Arriba, total del día: **Hoy: $1,240**

### Pantalla La cuenta
- Título: **La cuenta**
- Item sin precio: **No tengo precio para {producto}, ¿cuánto es?**
- Enlace para corregir: **Cambiar**
- Volver a capturar: **Dictar otra vez** · **Escribir otra vez**
- Botón principal: **Cobrar ${total}**

### Pantalla QR
- Encabezado: **{Nombre del negocio}**
- Instrucción para el cliente: **Escanea con la app de tu banco**
- Estado: **Esperando que te paguen…**
- Cancelar: **Cancelar cobro**

### Pagado
- **¡Pagado!**
- **Ya te llegaron ${total}**

### Hoy
- Título: **Hoy**
- Total: **Vendiste ${total}**
- Conteo: **en {n} cobros**
- Más vendido: **Lo que más salió: {producto}**
- Vacío: **Todavía no hay cobros hoy. El primero es el bueno.**

### Mensajes de problema

| Situación | Texto |
|---|---|
| Voz no entendida | No te escuché bien, ¿me lo escribes? |
| Sin micrófono | Activa el micrófono para dictar, o escribe el pedido. |
| No se entendió el pedido | No entendí el pedido. ¿Me lo dices de otra forma? |
| Cobro expirado | Este cobro ya venció. ¿Lo generamos otra vez? |
| Sin internet | Sin señal. Revisa tu conexión e inténtalo de nuevo. |
| No se pudo generar el QR | No pudimos generar el cobro. Inténtalo de nuevo en un momento. |

### WhatsApp (el bot)

Mismas reglas de voz. Si la persona escribe con dificultad, el bot le recuerda que también puede mandar nota de voz.

| Momento | Texto |
|---|---|
| La cuenta | **{Negocio}** · lista de productos · **Total: $120** · Recoges en: {dirección} |
| Pregunta de confirmación | ¿Lo pido? |
| El negocio aceptó | {Negocio} aceptó tu pedido 12. Te llegó un cobro de $120 a la app de tu banco. Ábrela y apruébalo. |
| Recordatorio de cobro | Tu cobro de $120 sigue esperando en la app de tu banco. |
| Pagado (a quien pidió) | ✅ ¡Pagado! Ya le llegaron $120 a {Negocio}. Tu código para recoger: 4821 |
| Pagado (al negocio) | ✅ ¡Pagado! Ya te llegaron $120 (pedido 12). |
| Pedido listo | Tu pedido 12 ya está listo. Pasa a: {dirección}. Tu código: 4821 |
| El negocio no contestó | {Negocio} no contestó a tiempo. ¿Te busco otra opción? |
| Cobro vencido | El cobro del pedido 12 ya venció. ¿Te lo mando otra vez? Responde *sí*. |
| Algo falló | Algo falló de mi lado. ¿Me lo repites? |
| Resumen al negocio | Hoy vendiste $1,240 en 38 cobros. Lo que más salió: {producto}. |

El negocio solo necesita estas palabras, escritas o por nota de voz: *sí* (o 👍), *no*, *listo*, *hoy*, *cerrar* y *abrir*.

## 6. Mensajes de marca

### Tagline principal
**Cobra en tu barrio, sin comisión.**

### Alternativas
- *Dímelo y te lo cobro.*
- *Tú dices, ellos escanean, te llega completo.*
- *Lo de tu barrio, cobrado al instante.*
- *Pide en tu barrio. Paga con un toque.* (para quien compra)

### En una frase, según a quién

| Audiencia | Mensaje |
|---|---|
| Dueño de tiendita | "Le dices lo que te compraron, sale un QR, tu cliente lo escanea con su banco y el dinero te llega completo, al momento." |
| Cliente que paga | "Escanea con la app de tu banco y listo. No tienes que bajar nada." |
| Jurado del hackathon | "Convertimos a cualquier tiendita en comercio CoDi en 5 segundos: el dueño habla o escribe, la IA arma la cuenta y pey cobra sin comisión." |
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
