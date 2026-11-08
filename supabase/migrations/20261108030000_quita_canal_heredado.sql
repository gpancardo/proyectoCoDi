-- Fuera lo heredado de un canal anterior. En negocios, la columna se conserva con otro nombre: marca
-- a los negocios de demo (sin cuenta de app) para que sigan verificados. Sin tablas nuevas: no hay GRANT/REVOKE.
-- renombrar actualiza solo las políticas; la función del trigger se recrea abajo.
alter table negocios rename column wa_jid to semilla;
alter table negocios rename constraint negocios_wa_jid_key to negocios_semilla_key;
alter table compradores drop column if exists wa_jid;
create or replace function negocio_verificado_en() returns trigger language plpgsql as $$
begin
  -- nadie recibe pedidos sin un dueño identificado (cuenta de la app) o sin ser negocio de demo; también al borrar la cuenta de auth
  if new.sujeto_auth is null and new.semilla is null then new.verificado = false; end if;
  if new.verificado and (tg_op = 'INSERT' or not old.verificado) then new.verificado_en = now(); end if;
  if not new.verificado then new.verificado_en = null; end if;
  return new;
end $$;
revoke all on function negocio_verificado_en() from public, anon, authenticated;
-- en la demo, todos los negocios cobran y reciben avisos en el mismo celular
update negocios set telefono = '5615156164' where semilla like 'demo-seed%';
