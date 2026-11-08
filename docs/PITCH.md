# Pitch de Barrio

Guion para presentar en vivo o a cámara. Para el video completo, ver [`VIDEOS.md`](VIDEOS.md). Para preparar la entrega, ver [`ENTREGA.md`](ENTREGA.md).

## En una frase

Barrio hace que comprarle a un negocio de tu colonia y pagarle con CoDi sea tan fácil como pedir en la esquina.

## En 30 segundos

> La tienda de tu colonia no aparece en ninguna app, y si cobra con terminal le quita una parte de cada venta. CoDi ya es gratis, pero pedir y cobrar con él da más trabajo que dar un billete.
>
> En Barrio dices lo que buscas con tus palabras, ves el total antes de pedir y te llega el cobro a la app de tu banco. Ya lo hicimos con dinero real: del pedido al pago, 32 segundos.

## Las tres ideas que deben quedar

1. **Que te encuentren.** La gente busca con sus palabras, y Barrio le pregunta lo que falta.
2. **Cobrar simple.** El total lo calcula el sistema y el cobro llega solo al banco.
3. **Que te vuelvan a comprar.** Promociones para quien ya compró y sellos por las 16 alcaldías.

## Guion de 3 minutos

| Tiempo | Bloque | Qué decir |
|---|---|---|
| 0:00–0:20 | Gancho | «Imagina a Don Beto, que tiene una tiendita. Si cobra con una terminal al 3.5% y vende $15,000 al mes con tarjeta, se le van $525. Si no la usa, vive del efectivo.» |
| 0:20–0:50 | Problema | «CoDi es gratis y el dinero llega en segundos, pero nadie lo usa para comprar en la esquina. Pedir es por mensaje, la cuenta se hace a mano y el negocio sigue sin aparecer en ningún lado.» |
| 0:50–1:20 | La idea | «Barrio junta lo que falta: que te encuentren, cobrar simple y que te vuelvan a comprar. Es una app Android para quien compra y para quien vende.» |
| 1:20–2:00 | Demo | Buscar con la voz o con texto. Mostrar la pregunta de Barrio. Pedir el Taco de prueba. **Llega el cobro al banco. Aprobar. ¡Pagado!** No cortes esta parte. |
| 2:00–2:25 | Confianza | «La IA entiende lo que pides, pero nunca decide un precio. El total sale del menú del negocio. Cada cobro se confirma con un webhook firmado y un pedido no puede cobrarse dos veces. Si el modelo se cae, la búsqueda sigue.» |
| 2:25–2:45 | Impacto | «El negocio ve por primera vez cuánto vendió y cuántos clientes regresan. Y cobrar con CoDi no le cuesta comisión.» |
| 2:45–3:00 | Cierre | «Lo siguiente es conectar la cuenta de cada negocio y salir a una primera colonia. Barrio: lo bueno del barrio, a un toque.» |

Don Beto es un personaje de ejemplo y el 3.5% es una comisión de ejemplo. Si tienen un negocio real con sus números, úsenlo en su lugar.

## Datos que sí podemos decir

| Dato | Respaldo |
|---|---|
| 32 segundos del pedido al pago | Pedido 21, 8 nov 2026, con aceptación automática de la demo |
| Cobro real de $0.01 confirmado por webhook | Pedido 21, aprobado en la app del banco |
| CoDi no genera comisiones adicionales y opera en segundos | [Banxico](https://www.banxico.org.mx/sistemas-de-pago/codi-cobro-digital-banco-me.html) |
| La API de pey no tiene costo por ahora y CoDi no genera comisión | [pey](https://pey.mx/api-codi) |
| 14 negocios de demo y 16 alcaldías con sello | Catálogo de producción y `docs/LOGROS.md` |
| 24 pruebas de backend y 8 de la app | `backend/test/`, `barrio_app_pey/test/` |

## No lo digas

- Que hay negocios reales usando Barrio: los 14 son de demo.
- Que el dinero ya llega a la cuenta de cada negocio: en la demo cae en una cuenta de prueba.
- Que funciona en navegador: es solo Android.
- La ley de pagos digitales o la Circular 9/2026, ni otra cifra marcada con 🟡 en `PRODUCTO.md`, hasta verificarlas.
- «Sin comisión» para algo distinto al cobro con CoDi.

## Modelo y siguiente paso

- **Hoy:** cobrar con CoDi no tiene comisión.
- **A futuro:** un plan de pago bajo para funciones extra, como reportes, varios empleados o envíos.
- **Siguiente:** cuenta propia por negocio (unos 5 días hábiles ante Banxico), avisos push reales y una primera colonia piloto.
