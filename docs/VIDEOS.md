# Guiones de video

Quién evalúa: AI Builders, pey, SEDECO y OpenAI (`README.md`). Lo que cada quien quiere ver:

| Jurado | Tiene que salir de pantalla con esto |
|---|---|
| pey | Un cobro CoDi real, de punta a punta, que llega a un banco real |
| OpenAI / AI Builders | La IA ayuda a encontrar, pero no toca precios ni pagos |
| SEDECO | Un negocio de barrio que vende mejor sin aprender nada difícil |

**La regla para ganar:** una historia, una persona, un cobro real. Si el video parece un recorrido de funciones, se pierde.

## Antes de grabar

- [ ] API desplegada y migraciones aplicadas (`pendientes/01-antes-de-entregar.md`).
- [ ] Hacer el recorrido completo una vez entera, sin grabar.
- [ ] Banco funcionando. **Si el banco sigue en mantenimiento, usa otro** o graba el cobro aparte: el cobro real es la escena más valiosa y no se simula.
- [ ] Teléfono en No Molestar, brillo alto, batería arriba de 50%, sin datos personales ni saldo visible.
- [ ] Una cuenta de comprador con 1 compra ya pagada, para que se vea el sello y el descuento.
- [ ] Una cuenta de negocio con pedidos: el panel vacío no convence.
- [ ] Grabar con la pantalla del teléfono y, si se puede, una toma de manos.
- [ ] Audio en un lugar callado. El audio malo mata más videos que la imagen mala.

## Video de demo (2 minutos)

Graba la pantalla real. Sin transiciones de adorno. Cortes rápidos.

| Tiempo | En pantalla | Voz |
|---|---|---|
| 0:00–0:10 | Toma de una calle o un mostrador de barrio | «La papelería de tu colonia no aparece en ninguna app, y si cobra con terminal le quita una parte de cada venta.» |
| 0:10–0:30 | Abrir la app. Tocar el micrófono y decir: «un cuaderno cerca de aquí». Aparecen resultados con la razón de cada uno. | «Con Barrio le dices lo que buscas. La IA entiende tu frase, pero los resultados y los precios salen del catálogo real.» |
| 0:30–0:45 | Abrir el negocio, agregar productos, «Ver mi cuenta». Se ve el 10% aplicado. | «El total lo calcula el servidor, y el descuento por haber comprado antes se aplica solo.» |
| 0:45–1:05 | Confirmar. Cambiar al teléfono del negocio: aceptar. | «El negocio acepta con un toque.» |
| 1:05–1:25 | **La notificación del banco. Aprobar. Pasa a ¡Pagado! con el código.** Sin cortar esta toma. | «Y aquí está lo importante: esto es un cobro CoDi real. Llegó a mi banco, lo aprobé, y el dinero ya está. Sin comisión.» |
| 1:25–1:45 | Panel: ventas de hoy, 7 días, lo que más sale. Marcar listo. | «El negocio ve cuánto vendió, qué sale más y quién regresa. Es la primera vez que tiene esos números.» |
| 1:45–2:00 | Sellos: la primera compra y la cuadrícula de alcaldías. | «Y quien compra en su barrio gana sellos de su ciudad, uno por cada alcaldía. Barrio: lo bueno del barrio, a un toque.» |

## Video de pitch (3 minutos)

A cámara, con una o dos personas. Que se vea quién lo hizo.

| Tiempo | Bloque | Qué decir |
|---|---|---|
| 0:00–0:20 | Gancho | Una historia concreta de un negocio real de su colonia. Un nombre y un número. No empezar con «somos» ni con «el problema es». |
| 0:20–0:50 | El problema | El comercio de barrio vive del efectivo o paga comisión, y no aparece en ningún lado. CoDi ya existe y es gratis, pero nadie lo usa para comprar en la esquina. Decir solo cifras verificadas. |
| 0:50–1:20 | La idea | Barrio junta las tres cosas que faltan: **que te encuentren, cobrar simple y que te vuelvan a comprar**. |
| 1:20–1:50 | Demo corta | 30 segundos del cobro real y el panel, tomados del video de demo. |
| 1:50–2:15 | Por qué se puede confiar | La IA interpreta; el servidor decide precios y totales. Cobro con pey, webhook firmado, sin guardar datos del banco. Si el modelo se cae, la búsqueda sigue. |
| 2:15–2:40 | Impacto y negocio | Cada negocio empieza a tener registro de ventas, primer paso hacia un crédito. Se replica por colonia. Modelo de ingresos según `docs/PRODUCTO.md` §12. |
| 2:40–3:00 | Cierre | Qué sigue y qué pides. Terminar con la frase de la marca, no con «gracias». |

## Qué evitar

- Decir «revolucionario», «disruptivo» o «solución integral».
- Enseñar código o arquitectura más de 10 segundos.
- Prometer lo que no hay: voz probada solo si ya se probó, número de negocios reales solo si son reales.
- Usar «sin comisión» para algo que no sea el cobro con CoDi.
- Datos personales en pantalla, incluido el celular real.
- Pasar de 3 minutos.

## Cómo entregar

Subir los dos videos sin listar, probar los enlaces en una ventana privada y mandar el correo con: nombre del equipo, enlaces a los videos, landing, APK y repositorio.
