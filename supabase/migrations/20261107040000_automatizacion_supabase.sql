-- Automatización dentro de Supabase: alta de comprador al registrarse, barrido con pg_cron, avisos en tiempo real y bucket de imágenes.
-- Las partes que dependen de extensiones/esquemas de Supabase (pg_cron, storage) se omiten sin error donde no existen.

-- ---------- alta automática del comprador ----------
-- Cada cuenta nueva nace comprador. El negocio se liga después (negocios.sujeto_auth) desde el backend/equipo.
create function crear_comprador_al_registrarse() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into compradores (sujeto_auth, nombre)
  values (new.id, nullif(left(trim(new.raw_user_meta_data ->> 'nombre'), 80), ''))
  on conflict (sujeto_auth) do nothing;
  return new;
end $$;
revoke all on function crear_comprador_al_registrarse() from public, anon, authenticated;
create trigger auth_crear_comprador after insert on auth.users for each row execute function crear_comprador_al_registrarse();
-- Cuentas que ya existían
insert into compradores (sujeto_auth) select id from auth.users u where not exists (select 1 from compradores c where c.sujeto_auth = u.id) on conflict do nothing;

-- ---------- barrido en SQL ----------
-- Vence cobros, marca pedidos vencidos, cancela pedidos sin respuesta del negocio (8 min) y devuelve sus cupones.
-- No consulta a pey: esa reconciliación sigue en el backend (POST /internal/sweep).
create function barrido_sql() returns void language plpgsql as $$
begin
  with v as (update intentos_cobro set estado = 'vencido' where estado = 'vigente' and vence < now() returning orden_id)
  update ordenes set estado = 'vencida', actualizado = now() where estado = 'cobrada' and id in (select orden_id from v);
  with e as (update ordenes set estado = 'expirada', actualizado = now()
    where estado = 'pendiente' and creado < now() - interval '8 minutes' returning canje_id)
  update cupon_canjes set estado = 'aceptado', actualizado = now() where estado = 'usado' and id in (select canje_id from e where canje_id is not null);
  perform limpiar_efimeros();
end $$;
revoke all on function barrido_sql() from public, anon, authenticated;
grant execute on function barrido_sql() to service_role;

do $$ begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.unschedule(jobid) from cron.job where jobname = 'barrio-barrido';
    perform cron.schedule('barrio-barrido', '* * * * *', 'select public.barrido_sql()');
  else
    raise notice 'pg_cron no disponible: el barrido corre solo desde el backend';
  end if;
exception when others then raise notice 'pg_cron no se pudo configurar (%): activa la extensión en el panel', sqlerrm;
end $$;

-- ---------- avisos en tiempo real ----------
-- La persona solo ve sus propias notificaciones (la app puede suscribirse); pedidos y cobros siguen solo por API.
-- Ayudantes SECURITY DEFINER: authenticated no tiene SELECT sobre compradores/negocios.
create function mi_comprador_id() returns bigint language sql stable security definer set search_path = public as $$
  select id from compradores where sujeto_auth = auth.uid() $$;
create function mis_negocios_ids() returns setof text language sql stable security definer set search_path = public as $$
  select id::text from negocios where sujeto_auth = auth.uid() $$;
revoke all on function mi_comprador_id(), mis_negocios_ids() from public, anon;
grant execute on function mi_comprador_id(), mis_negocios_ids() to authenticated;
create policy notificaciones_propias on notificaciones for select to authenticated using (comprador_id = mi_comprador_id());
grant select on notificaciones to authenticated;
do $$ begin
  alter publication supabase_realtime add table notificaciones;
exception when duplicate_object then null; end $$;

-- ---------- imágenes de negocios ----------
do $$ begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    values ('negocios', 'negocios', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
    on conflict (id) do nothing;
    -- Lectura pública; escribe solo el dueño, dentro de la carpeta con el id de su negocio.
    drop policy if exists negocios_imagenes_escritura on storage.objects;
    create policy negocios_imagenes_escritura on storage.objects for all to authenticated
      using (bucket_id = 'negocios' and (storage.foldername(name))[1] in (select public.mis_negocios_ids()))
      with check (bucket_id = 'negocios' and (storage.foldername(name))[1] in (select public.mis_negocios_ids()));
  end if;
end $$;
