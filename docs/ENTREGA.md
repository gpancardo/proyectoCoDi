# Guía de entrega

Todo lo necesario para mandar Barrio y responder a los jueces. Límite: **domingo 8 de noviembre, 1:00 PM**.

> **Confirmen el canal.** `PEY.md` dice que se entrega por correo a hola@aibuilders.lat y `PRODUCTO.md` habla de un portal. Revisen las instrucciones de los organizadores.

## Paquete

| Pieza | Estado | Enlace o acción |
|---|---|---|
| Sitio | Publicado | https://jade-paprenjak-a98b06.netlify.app |
| Repositorio | En `main` | https://github.com/gpancardo/proyectoCoDi |
| APK | Falta subirlo a Drive | `barrio_app_pey/build/app/outputs/flutter-apk/app-release.apk`, como `barrio-demo.apk` en la [carpeta](https://drive.google.com/drive/folders/1RAgBuqzbd0g0TX7koZZ1upO7kzWBrnji) |
| Video de demo (2 min) | Falta | Guion en [`VIDEOS.md`](VIDEOS.md), sin listar en YouTube |
| Video de pitch (3 min) | Falta | Guion en [`PITCH.md`](PITCH.md), sin listar en YouTube |
| Capturas reales | Falta | [`capturas/reales/`](capturas/reales/README.md) |

## Antes de enviar

- [ ] Instalar el APK nuevo desde el enlace público en un teléfono limpio.
- [ ] Hacer un pedido del Taco de prueba y ver ¡Pagado!.
- [ ] Abrir sitio, descarga, videos y repositorio en una ventana privada.
- [ ] Revisar que videos y capturas no muestren celular completo, saldo ni datos del banco.
- [ ] Decidir si se corrige el texto del sitio sobre el depósito directo al negocio (ver preguntas).

## Correo listo para pegar

```text
Asunto: Entrega Barrio · DevDay Exchange Community Hackathon

Equipo: [nombre del equipo]
Integrantes: [nombres]

Barrio es una app Android para encontrar negocios de tu colonia con tus palabras,
ver el total antes de pedir y pagar con CoDi desde la app de tu banco.

Video de demo: [enlace]
Video de pitch: [enlace]
Sitio: https://jade-paprenjak-a98b06.netlify.app
APK: https://jade-paprenjak-a98b06.netlify.app/descargar/
Repositorio: https://github.com/gpancardo/proyectoCoDi

Para probarlo en 5 minutos, el README trae los pasos.
El producto de prueba cuesta $0.01 reales y requiere CoDi activo en el banco.
```

## Qué busca cada jurado

| Jurado | Tiene que ver |
|---|---|
| pey | El cobro CoDi real, de punta a punta, y el webhook firmado |
| OpenAI / AI Builders | La IA pregunta y encuentra, pero no toca precios ni pagos |
| SEDECO | Un negocio de barrio que vende mejor sin aprender nada difícil |

## Preguntas difíciles

**¿A dónde va el dinero?**
En la demo, a una cuenta de prueba preautorizada para el hackathon. Para operar, cada negocio registra su propia cuenta ante Banxico, unos 5 días hábiles. El backend ya envía `bankAccountId` cuando el negocio lo tiene; falta pedir esa cuenta en el alta.

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
Cuenta por negocio, aviso de privacidad y términos, recuperar contraseña, push con la app cerrada, límite de uso y publicar en Google Play. Está en [`pendientes/`](../pendientes/README.md).

## Si algo falla en vivo

| Pasa | Haz |
|---|---|
| La app del banco se traba | Ciérrala y ábrela desde su ícono. El cobro dura 15 minutos; no hagas otro pedido |
| No llega el cobro | Revisa que CoDi esté activo y el celular del perfil. Si sigue, muestra el video |
| Se pagó y sigue sin cambiar | Abre ese pedido en la app: consulta a pey |
| Falla el internet | Pasa al video de demo y a las [capturas reales](capturas/reales/README.md) |
| Quieren probar con otra cuenta | Borra los datos de la app antes de entrar |
