-- Perfil de aplicación, señales explícitas y corpus recuperable del catálogo.
-- No modifica precios ni estados de pedidos; todos los datos sensibles siguen detrás del backend.
alter table compradores add column sujeto_auth uuid unique;
alter table compradores alter column wa_jid drop not null;

create table perfiles_descubrimiento (
  comprador_id bigint primary key references compradores(id) on delete cascade,
  categorias jsonb not null default '{}'::jsonb,
  actualizado timestamptz not null default now(),
  check (jsonb_typeof(categorias) = 'object')
);

create table eventos_descubrimiento (
  id bigint generated always as identity primary key,
  comprador_id bigint not null references compradores(id) on delete cascade,
  negocio_id bigint references negocios(id) on delete set null,
  tipo text not null check (tipo in ('search', 'view', 'save', 'order')),
  categoria text,
  consulta text check (length(consulta) <= 160),
  creado timestamptz not null default now()
);
create index eventos_descubrimiento_comprador_creado on eventos_descubrimiento(comprador_id, creado desc);

create table catalogo_documentos (
  negocio_id bigint primary key references negocios(id) on delete cascade,
  contenido text not null,
  embedding vector(1536),
  actualizado timestamptz not null default now()
);
create index catalogo_documentos_embedding_idx on catalogo_documentos using ivfflat (embedding vector_cosine_ops) with (lists = 10);

create or replace function actualizar_documento_catalogo() returns trigger language plpgsql as $$
begin
  insert into catalogo_documentos (negocio_id, contenido, embedding, actualizado)
  values (new.id, concat_ws('. ', new.nombre, new.categoria, new.zona, new.direccion,
    'Productos: ' || coalesce((select string_agg(x->>'nombre', ', ') from jsonb_array_elements(new.productos) x), '')), null, now())
  on conflict (negocio_id) do update set contenido = excluded.contenido, embedding = null, actualizado = now();
  return new;
end $$;
create trigger negocios_documento_catalogo after insert or update of nombre, categoria, zona, direccion, productos on negocios for each row execute function actualizar_documento_catalogo();
insert into catalogo_documentos (negocio_id, contenido)
select id, concat_ws('. ', nombre, categoria, zona, direccion, 'Productos: ' || coalesce((select string_agg(x->>'nombre', ', ') from jsonb_array_elements(productos) x), '')) from negocios
on conflict (negocio_id) do nothing;

create function match_catalogo_documentos(p_embedding vector(1536), p_limite int default 40)
returns table (negocio_id bigint, similitud float) language sql stable as $$
  select d.negocio_id, 1 - (d.embedding <=> p_embedding)
  from catalogo_documentos d join negocios n on n.id = d.negocio_id
  where d.embedding is not null and n.verificado and n.abierto
  order by d.embedding <=> p_embedding, d.negocio_id limit least(greatest(p_limite, 1), 60)
$$;

create function registrar_evento_descubrimiento(p_comprador_id bigint, p_tipo text, p_categoria text, p_consulta text, p_negocio_id bigint)
returns void language plpgsql as $$
declare peso int; clave text;
begin
  if p_tipo not in ('search', 'view', 'save', 'order') then raise exception 'tipo inválido'; end if;
  insert into eventos_descubrimiento(comprador_id, negocio_id, tipo, categoria, consulta)
  values (p_comprador_id, p_negocio_id, p_tipo, nullif(lower(trim(p_categoria)), ''), nullif(left(trim(p_consulta), 160), ''));
  clave := nullif(lower(trim(p_categoria)), '');
  if clave is null then return; end if;
  peso := case p_tipo when 'search' then 1 when 'view' then 1 when 'save' then 3 else 5 end;
  insert into perfiles_descubrimiento(comprador_id) values (p_comprador_id) on conflict do nothing;
  update perfiles_descubrimiento set categorias = jsonb_set(categorias, array[clave], to_jsonb(coalesce((categorias ->> clave)::int, 0) + peso), true), actualizado = now()
  where comprador_id = p_comprador_id;
end $$;

alter table perfiles_descubrimiento enable row level security;
alter table eventos_descubrimiento enable row level security;
alter table catalogo_documentos enable row level security;
revoke all on perfiles_descubrimiento, eventos_descubrimiento, catalogo_documentos from anon, authenticated;
revoke all on function match_catalogo_documentos(vector, int), registrar_evento_descubrimiento(bigint, text, text, text, bigint) from public, anon, authenticated;
grant all on perfiles_descubrimiento, eventos_descubrimiento, catalogo_documentos to service_role;
grant usage, select on all sequences in schema public to service_role;
grant execute on function match_catalogo_documentos(vector, int), registrar_evento_descubrimiento(bigint, text, text, text, bigint) to service_role;
