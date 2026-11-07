-- Pedidos desde cotización, intentos de cobro, webhook idempotente, cupones y colonia para insignias.
-- Solo el backend (service_role) toca estas tablas.
alter table negocios add column sujeto_auth uuid unique;
alter table negocios add column colonia text check (length(colonia) <= 80);

create table cotizaciones (
  id uuid primary key default gen_random_uuid(),
  comprador_id bigint not null references compradores(id),
  negocio_id bigint not null references negocios(id),
  items jsonb not null,                       -- [{"nombre","precio_minor","cantidad"}] copiados del catálogo
  subtotal_minor int not null check (subtotal_minor > 0),
  descuento_minor int not null default 0 check (descuento_minor >= 0 and descuento_minor < subtotal_minor),
  total_minor int not null check (total_minor > 0 and total_minor = subtotal_minor - descuento_minor),
  canje_id bigint,                            -- cupón autoaplicado, si lo hay
  expira timestamptz not null,
  creado timestamptz not null default now()
);

create table cupones (
  id bigint generated always as identity primary key,
  negocio_id bigint not null references negocios(id) on delete cascade,
  titulo text not null check (length(titulo) between 3 and 80),
  tipo text not null check (tipo in ('porcentaje', 'monto')),
  valor int not null check (valor > 0 and (tipo = 'monto' or valor <= 100)),  -- porcentaje 1-100 o centavos
  min_compra_minor int not null default 0 check (min_compra_minor >= 0),
  vence timestamptz not null,
  activo boolean not null default true,
  creado timestamptz not null default now()
);
create index on cupones (negocio_id, activo);

-- Un cupón se ofrece una vez por comprador: ofrecido → aceptado → usado.
create table cupon_canjes (
  id bigint generated always as identity primary key,
  cupon_id bigint not null references cupones(id) on delete cascade,
  comprador_id bigint not null references compradores(id) on delete cascade,
  estado text not null default 'ofrecido' check (estado in ('ofrecido', 'aceptado', 'usado', 'rechazado')),
  actualizado timestamptz not null default now(),
  unique (cupon_id, comprador_id)
);
create index on cupon_canjes (comprador_id, estado);

create table notificaciones (
  id bigint generated always as identity primary key,
  comprador_id bigint not null references compradores(id) on delete cascade,
  tipo text not null check (tipo in ('cupon')),
  titulo text not null,
  cupon_id bigint references cupones(id) on delete cascade,
  leida boolean not null default false,
  creado timestamptz not null default now()
);
create index on notificaciones (comprador_id, creado desc);

alter table ordenes add column cotizacion_id uuid unique references cotizaciones(id);
alter table ordenes add column idempotency_key text check (length(idempotency_key) between 8 and 80);
alter table ordenes add column canje_id bigint references cupon_canjes(id);
alter table ordenes add column descuento_minor int not null default 0;
alter table ordenes alter column codigo set default lpad(floor(random() * 10000)::int::text, 4, '0');
create unique index ordenes_idempotencia on ordenes (comprador_id, idempotency_key);

create table intentos_cobro (
  id bigint generated always as identity primary key,
  orden_id bigint not null references ordenes(id),
  via text check (via in ('push', 'link', 'qr')),
  pey_ref text unique,
  monto_minor int not null check (monto_minor > 0),
  vence timestamptz not null,
  estado text not null default 'vigente' check (estado in ('vigente', 'pagado', 'vencido', 'fallido', 'revision')),
  idempotency_key text not null check (length(idempotency_key) between 8 and 80),
  rastreo text,
  creado timestamptz not null default now(),
  unique (orden_id, idempotency_key)
);
-- Un pedido no puede tener dos cobros vigentes.
create unique index un_intento_vigente_por_orden on intentos_cobro (orden_id) where estado = 'vigente';

create table eventos_webhook (
  id text primary key,                        -- webhook-id de pey: deduplica reintentos
  creado timestamptz not null default now()
);

alter table cotizaciones enable row level security;
alter table cupones enable row level security;
alter table cupon_canjes enable row level security;
alter table notificaciones enable row level security;
alter table intentos_cobro enable row level security;
alter table eventos_webhook enable row level security;
revoke all on cotizaciones, cupones, cupon_canjes, notificaciones, intentos_cobro, eventos_webhook from anon, authenticated;
grant all on cotizaciones, cupones, cupon_canjes, notificaciones, intentos_cobro, eventos_webhook to service_role;
grant usage, select on all sequences in schema public to service_role;
