-- Cierre del esquema: perfiles de comprador y negocio, ubicación, identidad, integridad e índices.
-- Las restricciones nuevas sobre tablas con datos van NOT VALID: se exigen en filas nuevas sin romper las existentes.

create function tocar_actualizado() returns trigger language plpgsql as $$
begin new.actualizado = now(); return new; end $$;
revoke all on function tocar_actualizado() from public, anon, authenticated;

-- ---------- compradores ----------
alter table compradores
  add column colonia text check (length(colonia) <= 80),
  add column latitud numeric(9,6) check (latitud between -90 and 90),
  add column longitud numeric(9,6) check (longitud between -180 and 180),
  add column actualizado timestamptz not null default now(),
  add constraint compradores_auth_fk foreign key (sujeto_auth) references auth.users(id) on delete set null,
  add constraint compradores_ubicacion check ((latitud is null) = (longitud is null));
create trigger compradores_actualizado before update on compradores for each row execute function tocar_actualizado();

-- ---------- negocios ----------
alter table negocios
  add column descripcion text check (length(descripcion) <= 300),
  add column imagen_url text check (imagen_url ~ '^https://' and length(imagen_url) <= 500),
  add column latitud numeric(9,6) check (latitud between -90 and 90),
  add column longitud numeric(9,6) check (longitud between -180 and 180),
  add column verificado_en timestamptz,
  add column actualizado timestamptz not null default now(),
  add constraint negocios_auth_fk foreign key (sujeto_auth) references auth.users(id) on delete set null,
  add constraint negocios_ubicacion check ((latitud is null) = (longitud is null)),
  add constraint negocios_zona_alcaldia check (zona in ('Álvaro Obregón','Azcapotzalco','Benito Juárez','Coyoacán','Cuajimalpa','Cuauhtémoc','Gustavo A. Madero','Iztacalco','Iztapalapa','Magdalena Contreras','Miguel Hidalgo','Milpa Alta','Tláhuac','Tlalpan','Venustiano Carranza','Xochimilco')) not valid;
update negocios set verificado_en = creado where verificado and verificado_en is null;

create function negocio_verificado_en() returns trigger language plpgsql as $$
begin
  -- nadie recibe pedidos sin un dueño identificado (sesión de la app o negocio de demo); también al borrar la cuenta de auth
  if new.sujeto_auth is null and new.wa_jid is null then new.verificado = false; end if;
  if new.verificado and (tg_op = 'INSERT' or not old.verificado) then new.verificado_en = now(); end if;
  if not new.verificado then new.verificado_en = null; end if;
  return new;
end $$;
revoke all on function negocio_verificado_en() from public, anon, authenticated;
create trigger negocios_actualizado before update on negocios for each row execute function tocar_actualizado();
create trigger negocios_verificado before insert or update on negocios for each row execute function negocio_verificado_en();

-- El alta pública sigue cerrada: nace sin verificar, sin dueño, sin cuenta de cobro.
drop policy alta_publica on negocios;
create policy alta_publica on negocios for insert to anon
  with check (not verificado and verificado_en is null and wa_jid is null and sujeto_auth is null
    and embedding is null and pey_bank_account_id is null and abierto);

-- El documento recuperable del catálogo incluye colonia y descripción.
-- SECURITY DEFINER: el alta pública (anon) dispara este trigger y no tiene permiso sobre catalogo_documentos.
create or replace function actualizar_documento_catalogo() returns trigger language plpgsql security definer set search_path = public, extensions as $$
begin
  insert into catalogo_documentos (negocio_id, contenido, embedding, actualizado)
  values (new.id, concat_ws('. ', new.nombre, new.descripcion, new.categoria, new.colonia, new.zona, new.direccion,
    'Productos: ' || coalesce((select string_agg(x->>'nombre', ', ') from jsonb_array_elements(new.productos) x), '')), null, now())
  on conflict (negocio_id) do update set contenido = excluded.contenido, embedding = null, actualizado = now();
  return new;
end $$;
revoke all on function actualizar_documento_catalogo() from public, anon, authenticated;
drop trigger negocios_documento_catalogo on negocios;
create trigger negocios_documento_catalogo after insert or update of nombre, descripcion, categoria, colonia, zona, direccion, productos on negocios
  for each row execute function actualizar_documento_catalogo();

-- ---------- pedidos, cotizaciones y cobros ----------
alter table cotizaciones add constraint cotizaciones_canje_fk foreign key (canje_id) references cupon_canjes(id) on delete set null;
alter table ordenes
  add constraint ordenes_descuento check (descuento_minor >= 0),
  add constraint ordenes_pagada_con_fecha check (estado not in ('pagada', 'lista') or pagada_en is not null) not valid;

-- ---------- índices ----------
create index negocios_catalogo on negocios (zona, categoria) where verificado and abierto;
create index negocios_sujeto on negocios (sujeto_auth) where sujeto_auth is not null;
create index ordenes_negocio_estado on ordenes (negocio_id, estado, id desc);
create index ordenes_canje on ordenes (canje_id) where canje_id is not null;
create index cotizaciones_comprador on cotizaciones (comprador_id, creado desc);
create index cotizaciones_expira on cotizaciones (expira);
create index intentos_por_orden on intentos_cobro (orden_id, id desc);
create index intentos_vigentes on intentos_cobro (vence) where estado = 'vigente';
create index notificaciones_sin_leer on notificaciones (comprador_id) where not leida;
create index eventos_webhook_creado on eventos_webhook (creado);

-- ---------- mantenimiento ----------
-- Lo llama el barrido del backend: webhooks viejos (ya no hay reintentos) y cotizaciones vencidas sin pedido.
create function limpiar_efimeros() returns void language sql as $$
  delete from eventos_webhook where creado < now() - interval '30 days';
  delete from cotizaciones c where c.expira < now() - interval '1 day' and not exists (select 1 from ordenes o where o.cotizacion_id = c.id);
$$;
revoke all on function limpiar_efimeros() from public, anon, authenticated;
grant execute on function limpiar_efimeros() to service_role;
