#!/usr/bin/env bash
# Uso: PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=x bash supabase/tests/run.sh
set -euo pipefail
cd "$(dirname "$0")/.."
P="psql -v ON_ERROR_STOP=1 -q"
$P -d postgres -c "drop database if exists barrio_test" -c "create database barrio_test"
P="$P -d barrio_test"
$P -f tests/stub_supabase.sql
$P -c "alter database barrio_test set search_path = public, extensions"
for f in migrations/*.sql seed.sql tests/schema_smoke.sql; do echo "== $f"; $P -f "$f"; done
