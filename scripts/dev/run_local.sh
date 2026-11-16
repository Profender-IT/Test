#!/usr/bin/env bash
# รันแอปกับ Supabase local (supabase start ก่อน) · ค่าส่งผ่าน --dart-define เท่านั้น
# ใช้: bash scripts/dev/run_local.sh [-d <device>]   (Android emulator เข้าถึงเครื่องเราผ่าน 10.0.2.2)
set -euo pipefail
cd "$(dirname "$0")/../.."
s=$(supabase status -o json)
url=$(echo "$s" | jq -r '.API_URL')
key=$(echo "$s" | jq -r '.PUBLISHABLE_KEY // .ANON_KEY')
[ "${ANDROID_EMULATOR:-1}" = 1 ] && url=${url/127.0.0.1/10.0.2.2}
cd app && exec flutter run \
  --dart-define=SUPABASE_URL="$url" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$key" \
  --dart-define=APP_ENV=local "$@"
