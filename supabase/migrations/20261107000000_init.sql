-- Pegar en Supabase > SQL Editor y ejecutar una vez (o: supabase db push).
create extension if not exists vector with schema extensions;

create table compradores (
  id bigint generated always as identity primary key,
  telefono text unique check (telefono ~ '^[0-9]{10}$'),  -- 10 dígitos, formato que pide pey /codi/pn
  wa_jid text unique not null,
  nombre text check (length(nombre) <= 80),               -- sale del perfil de WhatsApp; no se pregunta
  zona text,
  ultima_respuesta text,                                  -- previous_response_id de OpenAI = memoria de la conversación
  creado timestamptz not null default now()
);

create table negocios (
  id bigint generated always as identity primary key,
  nombre text not null check (length(nombre) between 2 and 60),
  telefono text unique not null check (telefono ~ '^[0-9]{10}$'),
  wa_jid text unique,                           -- se llena cuando el negocio le escribe al bot
  verificado boolean not null default false,    -- true cuando ese WhatsApp saludó al bot: nadie recibe pedidos con un número ajeno
  zona text not null,
  direccion text not null check (length(direccion) between 5 and 200),
  categoria text not null check (length(categoria) between 2 and 60),
  -- [{"nombre": "Taco de canasta", "precio": 12}] ; el total del pedido se calcula de aquí, nunca lo inventa el modelo
  productos jsonb not null check (
    jsonb_typeof(productos) = 'array' and jsonb_array_length(productos) between 1 and 60
    and not jsonb_path_exists(productos, '$[*] ? (@.nombre.type() != "string" || @.precio.type() != "number" || @.precio <= 0 || @.precio > 100000)')),
  auto_aceptar boolean not null default false,  -- true: el pedido pasa directo al cobro
  abierto boolean not null default true,        -- el negocio escribe "cerrar" / "abrir"
  -- ponytail: la demo cobra todo a la cuenta CoDi de la API key; con cuentas por negocio registradas en pey
  -- (Register Bank Account, ~5 días hábiles) se guarda aquí su bankAccountId.
  pey_bank_account_id text,
  embedding vector(1536),                       -- lo calcula el bot (text-embedding-3-small)
  creado timestamptz not null default now()
);

create table ordenes (
  id bigint generated always as identity primary key,
  comprador_id bigint not null references compradores,
  negocio_id bigint not null references negocios,
  items jsonb not null,                 -- [{"nombre", "precio", "cantidad"}] copiados del catálogo al cotizar
  notas text check (length(notas) <= 300),
  monto numeric(12,2) not null check (monto <> 'NaN' and monto > 0 and monto <= 1000000),
  codigo text not null check (codigo ~ '^[0-9]{4}$'),  -- 4 dígitos que el cliente dice al recoger
  estado text not null default 'pendiente' check (estado in
    ('pendiente','aceptada','cobrada','pagada','lista','rechazada','expirada','vencida','cancelada')),
  wa_msgs text[] not null default '{}', -- mensajes sobre esta orden en el chat del negocio (para respuestas citadas y 👍)
  pey_ref text unique,                  -- transactionId (push) o id (QR) de pey
  rastreo text,                         -- clave de rastreo, para que el negocio verifique en el CEP de Banxico
  recordado boolean not null default false,
  avisado_pago boolean not null default false,  -- se avisó a ambos del pago (Realtime o, si se perdió, el barrido)
  creado timestamptz not null default now(),
  actualizado timestamptz not null default now(),
  pagada_en timestamptz                 -- métrica de la demo: pagada_en - creado
);
create index on ordenes (estado, actualizado);
create index on ordenes using gin (wa_msgs);
create index on ordenes (comprador_id, id desc);

-- Búsqueda: filtro determinista (verificado, abierto, zona) + similitud semántica.
create function match_negocios(q vector(1536), p_zona text default null, n int default 3)
returns table (id bigint, nombre text, zona text, direccion text, categoria text, productos jsonb, similitud float)
language sql stable as $$
  select id, nombre, zona, direccion, categoria, productos, 1 - (embedding <=> q)
  from negocios
  where embedding is not null and verificado and abierto and (p_zona is null or zona = p_zona)
  order by embedding <=> q
  limit n
$$;

-- El bot escucha cuando una orden pasa a 'pagada' (lo marca el webhook de pey).
alter publication supabase_realtime add table ordenes;

-- RLS: la página pública solo puede dar de alta negocios, no leer nada.
-- El bot y la función usan la service_role key, que se salta RLS.
alter table compradores enable row level security;
alter table negocios enable row level security;
alter table ordenes enable row level security;
create policy alta_publica on negocios for insert to anon
  with check (not verificado and wa_jid is null and embedding is null and pey_bank_account_id is null and abierto);

-- Supabase da permisos amplios por defecto a anon y authenticated: aquí se quitan y solo se deja lo necesario.
revoke all on compradores, negocios, ordenes from anon, authenticated;
grant insert on negocios to anon;

-- Agrega un id de mensaje a la orden sin carreras (lectura-modificación-escritura en una sola sentencia).
create function agregar_msg(p_id bigint, p_msg text) returns void language sql as $$
  update ordenes set wa_msgs = array_append(wa_msgs, p_msg) where id = p_id
$$;

-- Las funciones solo las usa el bot (service_role); la API pública no debe poder llamarlas.
revoke all on function match_negocios(vector, text, int) from public, anon, authenticated;
revoke all on function agregar_msg(bigint, text) from public, anon, authenticated;

-- Proyectos nuevos de Supabase ya no dan permisos por defecto, y BYPASSRLS no salta los GRANT:
-- el bot (service_role) necesita permisos explícitos.
grant usage on schema public to anon, service_role;
grant all on compradores, negocios, ordenes to service_role;
grant usage, select on all sequences in schema public to service_role;
grant execute on function match_negocios(vector, text, int), agregar_msg(bigint, text) to service_role;
