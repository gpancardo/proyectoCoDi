-- Link de pago y QR del intento, para que el comprador los recupere desde la app (solo el backend los lee).
alter table intentos_cobro add column instrucciones jsonb check (instrucciones is null or jsonb_typeof(instrucciones) = 'object');
