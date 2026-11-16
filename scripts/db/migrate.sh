#!/usr/bin/env bash
# รัน db/migrations/NNNN_*.sql ตามลำดับ ครั้งเดียวต่อไฟล์ · ใช้: DATABASE_URL=postgres://... bash scripts/db/migrate.sh
# CI: ตั้ง CREATE_ROLES=1 เพื่อสร้าง role ของแอป (ฐานทดสอบว่างเปล่า)
set -euo pipefail
: "${DATABASE_URL:?ต้องตั้ง DATABASE_URL (user ที่มีสิทธิ์สร้างตาราง)}"
DIR=$(cd "$(dirname "$0")/../../db/migrations" && pwd)
export PGOPTIONS="-c client_min_messages=warning"
psql() { command psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q "$@"; }

if [ "${CREATE_ROLES:-0}" = 1 ]; then
  for r in roombooking_api roombooking_worker roombooking_report; do
    psql -c "DO \$\$BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='$r') THEN CREATE ROLE $r LOGIN; END IF; END\$\$;"
  done
fi
psql -c "CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())"

for f in "$DIR"/[0-9][0-9][0-9][0-9]_*.sql; do
  v=$(basename "$f" .sql)
  if [ -n "$(psql -tAc "SELECT 1 FROM schema_migrations WHERE version='$v'")" ]; then continue; fi
  echo "apply $v"
  psql -1 -f "$f" -c "INSERT INTO schema_migrations(version) VALUES ('$v')"
done
echo "migrations ok"
