-- Negocio de demo. Cambia el teléfono por el WhatsApp con el que vas a hacer de negocio (10 dígitos).
-- Queda verificado para poder probar la app; en producción la verificación la hace el backend/equipo.
-- "Taco de prueba" cuesta un centavo: los organizadores piden probar los cobros reales con $0.01.
insert into negocios (nombre, telefono, zona, colonia, direccion, categoria, descripcion, productos, auto_aceptar, verificado, wa_jid) values (
  'Tacos Doña Lupe', '5500000000', 'Coyoacán', 'San Lucas', 'Av. Miguel Hidalgo 128, San Lucas', 'Taquería', 'Tacos de canasta y quesadillas de siempre.',
  '[{"nombre":"Taco de prueba","precio":0.01},{"nombre":"Taco de canasta","precio":12},{"nombre":"Quesadilla","precio":35},{"nombre":"Agua de horchata","precio":25}]',
  false, true, 'demo-seed'
) on conflict (telefono) do nothing;

-- Cupón de demo (se ofrece solo a quien ya pagó un pedido aquí; publicarlo por la API para generar los avisos).
insert into cupones (negocio_id, titulo, tipo, valor, min_compra_minor, vence)
select id, '10% en tu siguiente pedido', 'porcentaje', 10, 5000, now() + interval '30 days' from negocios where telefono = '5500000000'
and not exists (select 1 from cupones c where c.negocio_id = negocios.id);
