# Después del hackatón

## Dinero

- CLABE propia por negocio: registrar en pey y guardar `negocios.pey_bank_account_id`. Hoy un negocio nuevo cobra a la cuenta por defecto de pey.
- Quitar el celular de prueba de los negocios demo antes de abrir a público.
- Porcentaje de descuento por artículo: requiere soporte en `POST /business/coupons`.

## App

- Quitar el auto-aceptado de la demo de Doña Lupe.
- Salir de la cuenta debe limpiar el perfil local, y una cuenta sin celular debe pasar por el registro inicial.
- Recuperar contraseña y eliminar cuenta.
- Límite de uso en `POST /search/agent`, que hoy no pide sesión y llama al modelo.
- Firma de publicación del APK y salida en Google Play. Hoy va con firma de depuración.
- Avisos push reales (FCM): el comprador ya recibe avisos locales mientras la app siga viva; el panel del negocio pregunta cada 8 segundos.
- Avisos del comprador en la app (`/me/notifications`): promociones que publica un negocio donde ya compró.
- Pantalla de reporte de problema: hoy abre un correo.
- Registro de ubicación para ordenar por distancia real.

## Marca y cuidado cultural

- Revisión y crédito de los sellos por una persona especialista nahua, con pago por su trabajo.
- Confirmar con fuente especializada la interpretación de cada topónimo en `docs/LOGROS.md`.
- Aviso de privacidad y términos reales.

## Datos

- Tablero del negocio: pasar a vista agregada en SQL si un negocio rebasa 1000 pedidos en 30 días.
