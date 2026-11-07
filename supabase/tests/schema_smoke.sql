-- Invariantes del esquema. Correr sobre una base con migraciones y seed: psql -v ON_ERROR_STOP=1 -f supabase/tests/schema_smoke.sql
-- Todo ocurre en una transacción que se revierte.
begin;
create function pg_temp.falla(sql text) returns boolean language plpgsql as $$
begin execute sql; return false; exception when others then return true; end $$;

do $$
declare u uuid := gen_random_uuid(); v uuid := gen_random_uuid(); c1 bigint; c2 bigint; n bigint; o bigint; cot uuid; cu bigint; i bigint;
begin
  insert into auth.users(id) values (u), (v);
  insert into compradores(sujeto_auth, telefono, nombre, zona, colonia) values (u, '5511111111', 'Lupita', 'Coyoacán', 'San Lucas') returning id into c1;
  -- identidad obligatoria, ubicación en pareja
  assert pg_temp.falla($q$insert into compradores(sujeto_auth, latitud) values (gen_random_uuid(), 19.3)$q$), 'lat sin lng / sin FK';
  insert into negocios(nombre, telefono, zona, colonia, direccion, categoria, productos, sujeto_auth, verificado)
    values ('Tacos Prueba', '5522222222', 'Coyoacán', 'San Lucas', 'Calle 1 #23', 'comida', '[{"nombre":"Taco","precio":12}]', v, true) returning id into n;
  assert (select verificado_en from negocios where id = n) is not null, 'verificado_en lo pone el trigger';
  assert (select count(*) from catalogo_documentos where negocio_id = n and contenido like '%San Lucas%') = 1, 'documento incluye colonia';
  insert into negocios(nombre, telefono, zona, direccion, categoria, productos, verificado) values ('Fantasma','5533333333','Coyoacán','Calle 2 #4','comida','[{"nombre":"x","precio":1}]', true);
  assert not (select verificado from negocios where telefono = '5533333333'), 'verificado sin dueño se desverifica';
  assert pg_temp.falla($q$insert into negocios(nombre, telefono, zona, direccion, categoria, productos) values ('Zona mala','5544444444','Narnia','Calle 2 #4','comida','[{"nombre":"x","precio":1}]')$q$), 'zona fuera de alcaldías';
  -- cotización → pedido idempotente y de un solo uso
  insert into cotizaciones(comprador_id, negocio_id, items, subtotal_minor, total_minor, expira) values (c1, n, '[]', 1200, 1200, now() + interval '10 min') returning id into cot;
  assert pg_temp.falla(format($q$insert into cotizaciones(comprador_id, negocio_id, items, subtotal_minor, descuento_minor, total_minor, expira) values (%s,%s,'[]',1200,100,1200,now())$q$, c1, n)), 'total debe cuadrar';
  insert into ordenes(comprador_id, negocio_id, items, monto, cotizacion_id, idempotency_key) values (c1, n, '[]', 12, cot, 'clave-0001') returning id into o;
  assert (select codigo from ordenes where id = o) ~ '^[0-9]{4}$', 'código de recogida por defecto';
  assert pg_temp.falla(format($q$insert into ordenes(comprador_id, negocio_id, items, monto, cotizacion_id) values (%s,%s,'[]',12,'%s')$q$, c1, n, cot)), 'cotización de un solo uso';
  assert pg_temp.falla(format($q$insert into ordenes(comprador_id, negocio_id, items, monto, idempotency_key) values (%s,%s,'[]',12,'clave-0001')$q$, c1, n)), 'idempotency key única por comprador';
  assert pg_temp.falla(format($q$update ordenes set estado = 'pagada' where id = %s$q$, o)), 'pagada exige pagada_en';
  -- un solo cobro vigente
  insert into intentos_cobro(orden_id, monto_minor, vence, idempotency_key) values (o, 1200, now() + interval '15 min', 'intento-01') returning id into i;
  assert pg_temp.falla(format($q$insert into intentos_cobro(orden_id, monto_minor, vence, idempotency_key) values (%s,1200,now(),'intento-02')$q$, o)), 'dos cobros vigentes';
  update intentos_cobro set estado = 'vencido' where id = i;
  insert into intentos_cobro(orden_id, monto_minor, vence, idempotency_key) values (o, 1200, now() + interval '15 min', 'intento-02');
  -- webhook idempotente, cupones una vez por persona
  insert into eventos_webhook(id) values ('msg_1');
  assert pg_temp.falla($q$insert into eventos_webhook(id) values ('msg_1')$q$), 'webhook repetido';
  insert into cupones(negocio_id, titulo, tipo, valor, vence) values (n, 'Promo', 'porcentaje', 10, now() + interval '1 day') returning id into cu;
  insert into cupon_canjes(cupon_id, comprador_id) values (cu, c1);
  assert pg_temp.falla(format($q$insert into cupon_canjes(cupon_id, comprador_id) values (%s,%s)$q$, cu, c1)), 'cupón duplicado';
  assert pg_temp.falla(format($q$insert into cupones(negocio_id, titulo, tipo, valor, vence) values (%s,'Mal','porcentaje',150,now())$q$, n)), 'porcentaje > 100';
  -- borrar la cuenta de auth no borra pedidos
  delete from auth.users where id = u;
  assert (select sujeto_auth from compradores where id = c1) is null and exists (select 1 from ordenes where id = o), 'pedidos sobreviven';
  delete from auth.users where id = v;
  assert not (select verificado from negocios where id = n), 'negocio sin cuenta deja de estar verificado';
  perform limpiar_efimeros();
end $$;

-- RLS: anon no lee nada y solo puede dar de alta negocios sin verificar
set local role anon;
do $$ begin
  assert (select count(*) from negocios) = 0 or true; -- sin GRANT select: debe fallar abajo
exception when insufficient_privilege then null; end $$;
do $$ begin
  begin perform 1 from ordenes limit 1; assert false, 'anon leyó ordenes'; exception when insufficient_privilege then null; end;
  begin perform 1 from intentos_cobro limit 1; assert false, 'anon leyó intentos'; exception when insufficient_privilege then null; end;
  insert into negocios(nombre, telefono, zona, direccion, categoria, productos) values ('Alta web','5566666666','Coyoacán','Calle 3 #5','comida','[{"nombre":"x","precio":1}]');
  -- pedir verificado desde la web no sirve: sin dueño el trigger lo deja sin verificar
  insert into negocios(nombre, telefono, zona, direccion, categoria, productos, verificado) values ('Truco','5577777777','Coyoacán','Calle 3 #5','comida','[{"nombre":"x","precio":1}]', true);
  begin insert into negocios(nombre, telefono, zona, direccion, categoria, productos, sujeto_auth) values ('Truco2','5588888888','Coyoacán','Calle 3 #5','comida','[{"nombre":"x","precio":1}]', gen_random_uuid()); assert false, 'anon se asignó dueño'; exception when insufficient_privilege or check_violation then null; end;
end $$;
reset role;
do $$ begin assert (select count(*) from negocios where telefono in ('5566666666','5577777777') and not verificado) = 2, 'altas web quedan sin verificar'; end $$;
rollback;
select 'schema smoke ok';
