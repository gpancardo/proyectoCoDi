# Preparación del equipo para la entrega

Documento interno. Lo que leen los jueces está en `docs/PITCH.md`, `docs/ENTREGA.md` y sus versiones en inglés.

## Paquete

| Pieza | Estado | Enlace o acción |
|---|---|---|
| Sitio | Publicado | https://jade-paprenjak-a98b06.netlify.app |
| Repositorio | En `main` | https://github.com/gpancardo/proyectoCoDi |
| APK | Falta subirlo a Drive | `barrio_app_pey/build/app/outputs/flutter-apk/app-release.apk`, como `barrio-demo.apk` en la [carpeta](https://drive.google.com/drive/folders/1RAgBuqzbd0g0TX7koZZ1upO7kzWBrnji) |
| Video de demo (2 min) | Falta | Guion en [`VIDEOS.md`](../docs/VIDEOS.md), sin listar en YouTube |
| Video de pitch (3 min) | Falta | Guion más abajo, sin listar en YouTube |
| Capturas reales | Falta | [`capturas/reales/`](../docs/capturas/reales/README.md) |

## Antes de enviar

- [ ] Instalar el APK nuevo desde el enlace público en un teléfono limpio.
- [ ] Hacer un pedido del Taco de prueba y ver ¡Pagado!.
- [ ] Abrir sitio, descarga, videos y repositorio en una ventana privada.
- [ ] Revisar que videos y capturas no muestren celular completo, saldo ni datos del banco.

## Cómo se envía

1. Sube el APK nuevo a Drive como `barrio-demo.apk`.
2. Sube los dos videos a YouTube como «sin listar».
3. Copia el correo de abajo y llena lo que está entre corchetes.
4. Abre cada enlace en una ventana privada.
5. Envíalo a hola@aibuilders.lat antes de la 1:00 PM, después de confirmar esa dirección con los organizadores.

## Correo listo para pegar

```text
Asunto: Entrega Barrio · DevDay Exchange Community Hackathon

Hola:

Les compartimos la entrega de Barrio, una app Android para encontrar negocios
de tu colonia con tus palabras, ver el total antes de pedir y pagar con CoDi
desde la app de tu banco.

Equipo: [nombre del equipo]
Integrantes: [nombres]

VIDEOS
Demo: [enlace]
Pitch: [enlace]

PRODUCTO
Sitio: https://jade-paprenjak-a98b06.netlify.app
App Android (APK): https://jade-paprenjak-a98b06.netlify.app/descargar/

DOCUMENTOS EN ESPAÑOL
Repositorio: https://github.com/gpancardo/proyectoCoDi/blob/main/README.md
Pitch: https://github.com/gpancardo/proyectoCoDi/blob/main/docs/PITCH.md
Expediente de entrega: https://github.com/gpancardo/proyectoCoDi/blob/main/docs/ENTREGA.md
Por qué ahora (Ley de Economía Digital): https://github.com/gpancardo/proyectoCoDi/blob/main/docs/LEY-ECONOMIA-DIGITAL.md

DOCUMENTS IN ENGLISH
Repository: https://github.com/gpancardo/proyectoCoDi/blob/main/README.en.md
Pitch: https://github.com/gpancardo/proyectoCoDi/blob/main/docs/PITCH.en.md
Submission dossier: https://github.com/gpancardo/proyectoCoDi/blob/main/docs/ENTREGA.en.md
Why now (Digital Economy Law): https://github.com/gpancardo/proyectoCoDi/blob/main/docs/LEY-ECONOMIA-DIGITAL.en.md

Todas las pantallas: https://github.com/gpancardo/proyectoCoDi/blob/main/docs/capturas/README.md

Para probarla en 5 minutos, los pasos están en el README. El producto de prueba
cuesta $0.01 reales y requiere CoDi activo en el banco.

Gracias,
[nombre]
```

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

## Cuidado al presentar

- Que hay negocios reales usando Barrio: los 14 son de demo.
- Que el dinero ya llega a la cuenta de cada negocio: en la demo cae en una cuenta de prueba.
- Que funciona en navegador: es solo Android.
- Que la ley obliga a los comercios o prohíbe el efectivo: no lo hace. Ver `docs/LEY-ECONOMIA-DIGITAL.md`.
- Otra cifra marcada con 🟡 en `docs/PRODUCTO.md`, hasta verificarla.
- «Sin comisión» para algo distinto al cobro con CoDi.

## Preguntas difíciles

**¿A dónde va el dinero?**
En la demo, a una cuenta de prueba preautorizada que dieron los organizadores. Para operar, cada negocio registra su propia cuenta ante Banxico, unos 5 días hábiles. El backend ya envía `bankAccountId` cuando el negocio lo tiene; falta pedir esa cuenta en el alta.

**¿La IA puede inventar precios o negocios?**
No. Devuelve filtros con un esquema fijo y solo puede elegir negocios ya recuperados del catálogo. Los precios y totales salen del servidor.

**¿Y si se cae el modelo?**
La búsqueda sigue con reglas exactas por texto, zona, categoría y precio.

**¿Se puede cobrar dos veces?**
La base solo permite un cobro vigente por pedido y cada cambio de estado exige el estado anterior.

**¿Y si se pierde el webhook?**
La app consulta a pey mientras el pedido está abierto. El webhook está firmado y no se procesa dos veces.

**¿Quién acepta los pedidos en la demo?**
Doña Lupe acepta sola el Taco de prueba a los 5 segundos, para probar sin un segundo teléfono. Los demás negocios aceptan desde su panel, o en automático si lo activan.

**¿Cómo gana dinero?**
El cobro con CoDi no tiene comisión. A futuro, un plan bajo para funciones extra.

**¿Qué falta para salir?**
Cuenta por negocio, aviso de privacidad y términos, recuperar contraseña, push con la app cerrada, límite de uso y publicar en Google Play. Está en [`pendientes/`](README.md).

## Si algo falla en vivo

| Pasa | Haz |
|---|---|
| La app del banco se traba | Ciérrala y ábrela desde su ícono. El cobro dura 15 minutos; no hagas otro pedido |
| No llega el cobro | Revisa que CoDi esté activo y el celular del perfil. Si sigue, muestra el video |
| Se pagó y sigue sin cambiar | Abre ese pedido en la app: consulta a pey |
| Falla el internet | Pasa al video de demo y a las [capturas reales](../docs/capturas/reales/README.md) |
| Quieren probar con otra cuenta | Borra los datos de la app antes de entrar |

