-- Limpieza del legado de WhatsApp: columnas y funciones que solo usaba bot/ (eliminado del repo).
-- El cobro vive en intentos_cobro; la búsqueda semántica en catalogo_documentos. wa_jid se conserva como dueño heredado.
drop function if exists agregar_msg(bigint, text);
drop function if exists match_negocios(vector, text, int);
alter table ordenes
  drop column if exists wa_msgs,
  drop column if exists recordado,
  drop column if exists avisado_pago,
  drop column if exists pey_ref,
  drop column if exists pey_via;
alter table compradores drop column if exists ultima_respuesta;
-- La política del alta pública mencionaba embedding: se recrea igual, sin esa columna.
drop policy alta_publica on negocios;
create policy alta_publica on negocios for insert to anon
  with check (not verificado and verificado_en is null and wa_jid is null and sujeto_auth is null
    and pey_bank_account_id is null and abierto);
alter table negocios drop column if exists embedding;
