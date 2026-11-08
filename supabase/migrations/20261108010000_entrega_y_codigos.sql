-- Cierre de entrega y cupones canjeables por código. Solo el backend usa estas tablas.
alter table ordenes drop constraint if exists ordenes_estado_check;
alter table ordenes add constraint ordenes_estado_check check (estado in
  ('pendiente','aceptada','cobrada','pagada','lista','entregada','rechazada','expirada','vencida','cancelada'));
alter table ordenes drop constraint if exists ordenes_pagada_con_fecha;
alter table ordenes add constraint ordenes_pagada_con_fecha check (estado not in ('pagada','lista','entregada') or pagada_en is not null);

alter table cupones add column codigo text unique check (codigo is null or codigo ~ '^[A-Z0-9-]{3,24}$');
alter table cupones add column producto_regalo text check (producto_regalo is null or length(producto_regalo) between 1 and 60);
alter table cupones drop constraint if exists cupones_tipo_check;
alter table cupones add constraint cupones_tipo_check check (tipo in ('porcentaje','monto','producto_gratis'));
alter table cupones drop constraint if exists cupones_valor_check;
alter table cupones add constraint cupones_valor_check check (
  (tipo = 'porcentaje' and valor between 1 and 100) or
  (tipo = 'monto' and valor > 0) or
  (tipo = 'producto_gratis' and valor = 1 and producto_regalo is not null)
);
create index if not exists cupones_codigo_activo on cupones (codigo) where activo and codigo is not null;

revoke all on ordenes, cupones from anon, authenticated;
grant all on ordenes, cupones to service_role;
