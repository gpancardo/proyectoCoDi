-- Imita lo que Supabase ya trae (roles, auth.users, realtime) para probar migraciones en un Postgres con pgvector.
do $$ begin create role anon nologin; exception when duplicate_object then null; end $$; do $$ begin create role authenticated nologin; exception when duplicate_object then null; end $$; do $$ begin create role service_role nologin bypassrls; exception when duplicate_object then null; end $$;
create schema extensions; create schema auth; create table auth.users (id uuid primary key default gen_random_uuid());
create publication supabase_realtime;
alter database postgres set search_path = public, extensions;
alter table auth.users add column raw_user_meta_data jsonb not null default '{}'::jsonb;
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to authenticated, service_role;
