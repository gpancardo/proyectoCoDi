-- Negocio de demo. Cambia el teléfono por el WhatsApp con el que vas a hacer de negocio.
-- Queda sin verificar: se activa solo cuando ese WhatsApp le escribe al bot.
insert into negocios (nombre, telefono, zona, direccion, categoria, productos, auto_aceptar) values (
  'Tacos Doña Lupe', '5500000000', 'Coyoacán', 'Av. Miguel Hidalgo 128, San Lucas', 'Taquería',
  '[{"nombre":"Taco de canasta","precio":12},{"nombre":"Quesadilla","precio":35},{"nombre":"Agua de horchata","precio":25},{"nombre":"Refresco","precio":20}]',
  false
) on conflict (telefono) do nothing;
