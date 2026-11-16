#!/usr/bin/env bash
# สร้าง .env สำหรับ docker-compose.yml (dev/demo ในเครื่องเท่านั้น) · สุ่มค่าใหม่ทุกครั้ง · ไม่เขียนทับถ้ามีอยู่แล้ว
# ใช้: bash scripts/dev/compose_env.sh [--force]
set -euo pipefail
cd "$(dirname "$0")/../.."
ENV_FILE=.env
if [ -e "$ENV_FILE" ] && [ "${1:-}" != --force ]; then
  echo "$ENV_FILE มีอยู่แล้ว (ใช้ --force เพื่อสร้างใหม่ · ต้อง docker compose down -v ด้วยเพราะรหัสผ่าน DB เปลี่ยน)"; exit 0
fi

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
jwt() {  # jwt <role> <secret>
  local now exp header payload sig
  now=$(date +%s); exp=$((now + 5 * 365 * 24 * 3600))
  header=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
  payload=$(printf '{"role":"%s","iss":"supabase","iat":%d,"exp":%d}' "$1" "$now" "$exp" | b64url)
  sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$2" -binary | b64url)
  printf '%s.%s.%s' "$header" "$payload" "$sig"
}

pg_pass=$(openssl rand -hex 24)
jwt_secret=$(openssl rand -hex 32)
umask 077
cat > "$ENV_FILE" <<ENV
# สร้างโดย scripts/dev/compose_env.sh $(date +%F) · dev/demo ในเครื่องเท่านั้น · ห้าม commit / ห้ามใช้กับ staging-production
PUBLIC_URL=http://localhost:8000
POSTGRES_PASSWORD=$pg_pass
JWT_SECRET=$jwt_secret
JWT_EXP=3600
# anon = public key ที่แอปใช้ · service_role ใช้ใน Studio เท่านั้น ห้ามใส่ในแอป
ANON_KEY=$(jwt anon "$jwt_secret")
SERVICE_ROLE_KEY=$(jwt service_role "$jwt_secret")
ENV
echo "สร้าง $ENV_FILE แล้ว → docker compose up -d --build"
