-- Negocio de demo. Cambia el teléfono por el WhatsApp con el que vas a hacer de negocio (10 dígitos).
-- Queda sin verificar: se activa solo cuando ese WhatsApp le escribe al bot.
-- "Taco de prueba" cuesta un centavo: los organizadores piden probar los cobros reales con $0.01.
insert into negocios (nombre, telefono, zona, direccion, categoria, productos, auto_aceptar) values (
  'Tacos Doña Lupe', '5500000000', 'Coyoacán', 'Av. Miguel Hidalgo 128, San Lucas', 'Taquería',
  '[{"nombre":"Taco de prueba","precio":0.01},{"nombre":"Taco de canasta","precio":12},{"nombre":"Quesadilla","precio":35},{"nombre":"Agua de horchata","precio":25}]',
  false
) on conflict (telefono) do nothing;
