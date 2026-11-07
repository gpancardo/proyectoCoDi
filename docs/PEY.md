# pey: activación, pruebas y entrega del hackathon

Resumen de las instrucciones que dieron los organizadores (7 nov 2026). Documentación oficial: <https://docs.pey.mx>. Portal: <https://portal.pey.mx>.

## Cuentas de prueba

- Dar de alta una cuenta bancaria ante Banxico tarda ~5 días. Para probar hoy, los organizadores habilitaron **CLABEs pre-autorizadas** a nombre de cinco personas (Ramón Orraca, Santiago Tena, Adrian Soto, Miriam Nava, David Perez).

| Titular | CLABE |
|---|---|
| Ramón Orraca | 012180015826225713 |
| Santiago Tena | 012180015913466252 |
| Adrian Soto | 014180606004536217 |
| Miriam Nava | 012180015355682429 |
| David Perez | 127180016558860385 |

Son cuentas de prueba publicadas por los organizadores del hackathon; el equipo decidió documentarlas aquí.
- Hay que **registrar la CLABE en el portal de pey** y usar la API desde ese momento. El identificador que devuelve pey es el `bankAccountId` que va en `negocios.pey_bank_account_id`; sin él, el cobro cae en la cuenta de la API key.
- Recomendación de pey: registrar CLABEs propias para publicar el proyecto cuando estén activas (~5 días hábiles). Está en "Después del hackathon" de [`PRODUCTO.md`](PRODUCTO.md).

## Cómo probar

- **Solo cobros de $0.01.** Los pagos de prueba **no se devuelven**. El "Taco de prueba" del seed cuesta un centavo por esto.
- pey no tiene entorno de pruebas: se prueba en producción con la API key real.
- Sin `PEY_API_KEY` el backend usa `PEY_MOCK=1` y no llama a pey. Para un cobro real: `PEY_API_KEY` y `PEY_MOCK=0` en `backend/.env` (nunca en Git ni en el chat).
- Para ver "¡Pagado!" completo, el webhook de pey necesita llegar al backend: `POST /webhooks/pey` con `PEY_WEBHOOK_SECRET`. Sin backend público, el barrido consulta a pey como respaldo (ver [`BACKEND.md`](BACKEND.md)).

## Por qué pey

La API nativa de CoDi requiere un trámite de ~12 meses; con la API de pey se reduce a minutos, y permite dar de alta cuentas de cualquier institución participante en CoDi.

## Entrega y premios

- **Entrega:** a más tardar el **domingo 8 de noviembre, 1:00 PM**, por correo a hola@aibuilders.lat.
- **Ganadores:** lunes 9 de noviembre, por correo a los participantes.
- **Premios (OpenAI):** US$500, US$300 y US$200 en créditos.
