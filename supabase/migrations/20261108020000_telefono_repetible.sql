-- El celular ya no es único: en la demo todas las cuentas cobran y reciben en el mismo número.
-- Sin tablas nuevas, así que no hay GRANT/REVOKE que agregar.
alter table compradores drop constraint if exists compradores_telefono_key;
alter table negocios drop constraint if exists negocios_telefono_key;
