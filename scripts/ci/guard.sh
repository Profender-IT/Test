#!/usr/bin/env bash
# Guardrails: ตรวจกฎใน AGENTS.md ที่ lint ทั่วไปจับไม่ได้ · รันในเครื่องได้ก่อน push
# ใช้: bash scripts/ci/guard.sh <base-ref> [head-branch] [pr-title]
set -uo pipefail
BASE=${1:-origin/main}; HEAD_BRANCH=${2:-$(git rev-parse --abbrev-ref HEAD)}; TITLE=${3:-}
JIRA_KEY_RE='ROOM-[0-9]+'
fail=0; err(){ echo "::error::$*"; fail=1; }
changed=$(git diff --name-status "$BASE"...HEAD)
added_lines(){ git diff -U0 "$BASE"...HEAD -- "$@" | grep '^+' | grep -v '^+++' || true; }
added_files(){ echo "$changed" | awk '$1=="A"{print $NF}'; }

# 1) migration เพิ่มไฟล์ใหม่เท่านั้น · ชื่อ <timestamp 14 หลัก>_name.sql (supabase migration new)
while read -r st f; do
  [[ $f == supabase/migrations/* ]] || continue
  [[ $st == A ]] || err "ห้ามแก้/ลบ migration เดิม: $f"
  [[ $(basename "$f") =~ ^[0-9]{14}_[a-z0-9_]+\.sql$ ]] || err "ชื่อ migration ต้องเป็น YYYYMMDDHHMMSS_name.sql: $f"
done <<< "$(echo "$changed" | awk 'NF{print substr($1,1,1), $NF}')"
for f in $(added_files | grep '^supabase/migrations/.*\.sql$' || true); do
  # 2) migration ทำลายข้อมูลต้องมี -- contract:
  if grep -Eiq 'drop[[:space:]]+(table|column)|truncate|alter[[:space:]].*[[:space:]]type[[:space:]]|rename[[:space:]]+(column|to)' "$f" && ! grep -q -- '-- contract:' "$f"; then
    err "$f ทำลาย/เปลี่ยนโครงสร้าง ต้อง expand→contract และใส่ '-- contract: <เหตุผล>'"; fi
  # 3) ตารางใหม่ใน schema public ต้องเปิด RLS ในไฟล์เดียวกัน
  for t in $(grep -Eio 'create[[:space:]]+table[[:space:]]+(if[[:space:]]+not[[:space:]]+exists[[:space:]]+)?(public\.)?[a-z_][a-z0-9_]*' "$f" | awk '{print $NF}' | sed 's/^public\.//' | grep -v '^exists$' || true); do
    grep -Eiq "alter[[:space:]]+table[[:space:]]+(public\.)?$t[[:space:]]+enable[[:space:]]+row[[:space:]]+level[[:space:]]+security" "$f" \
      || err "$f: ตาราง $t ต้อง 'enable row level security' ในไฟล์เดียวกัน"
  done
done
# 4) secret / IP / รหัสผ่าน / JWT
hits=$(added_lines ':!*.md' ':!docs/*' ':!*.example' ':!scripts/ci/*' ':!app/lib/src/l10n/*' ':!*.lock' ':!*package-lock.json' \
  | grep -Ein '(password|passwd|secret|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$\{]{6,}|postgres(ql)?://[^:@/]+:[^@$\{]+@|192\.168\.[0-9]+\.[0-9]+|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}|sb_secret_[A-Za-z0-9_-]{8,}' \
  | grep -Ev '_placeholder|example\.(com|test)|"env\(' || true)
[ -n "$hits" ] && err "พบ secret / JWT / IP hardcode (ส่งผ่าน --dart-define หรือ GitHub secrets/vars):"$'\n'"$hits"
# 5) ห้าม service_role ในแอป (ADR 0001)
[ -n "$(git diff -U0 "$BASE"...HEAD -- 'app/*' ':!app/lib/src/config/env.dart' ':!app/test/*' | grep '^+' | grep -v '^+++' | grep -Ei 'service_?role|sb_secret_' || true)" ] \
  && err "ห้ามอ้าง service_role / secret key ในแอป (ตรวจกุญแจได้ที่ app/lib/src/config/env.dart เท่านั้น)"
# 6) config ผ่าน --dart-define เท่านั้น
hits=$(added_lines 'app/lib/*' | grep -En 'flutter_dotenv|dotenv|Platform\.environment|https?://[a-z0-9-]+\.supabase\.(co|in)|loadString\([^)]*\.env' || true)
[ -n "$hits" ] && err "config ของแอปต้องมาจาก String.fromEnvironment (--dart-define) เท่านั้น:"$'\n'"$hits"
hits=$(added_lines 'app/pubspec.yaml' | grep -En 'flutter_dotenv|envied|^\+[[:space:]]*-[[:space:]]*\.env' || true)
[ -n "$hits" ] && err "ห้ามแพ็กเกจ/asset .env ใน pubspec (ใช้ --dart-define):"$'\n'"$hits"
# 7) LLM คลาวด์ห้าม (ข้อมูลห้ามออกนอกองค์กร)
hits=$(added_lines 'app/pubspec.yaml' 'e2e/package.json' | grep -Eio '(google_generative_ai|firebase_vertexai|firebase_ai|dart_openai|openai_dart|anthropic_sdk_dart|langchain[a-z_]*|"openai"|"@anthropic-ai/sdk"|"@google/genai")' || true)
[ -n "$hits" ] && err "ห้ามเพิ่ม SDK ของ LLM คลาวด์: $hits"
# 8) ต้องผูก Jira key
if [[ ! $HEAD_BRANCH =~ $JIRA_KEY_RE ]] && [[ ! $TITLE =~ $JIRA_KEY_RE ]]; then
  err "ไม่พบ Jira key (ROOM-123) ในชื่อ branch หรือ PR"; fi
# 9) agent ห้ามแตะไฟล์ที่สงวนไว้ให้คน
if [[ $HEAD_BRANCH == agent/* ]]; then
  hits=$(echo "$changed" | awk '{print $NF}' | grep -E '^(docker-compose\.ya?ml$|\.github/|scripts/ci/|\.claude/settings\.json$|AGENTS\.md$|supabase/config\.toml$|app/android/app/build\.gradle(\.kts)?$)' || true)
  [ -n "$hits" ] && err "agent แตะไฟล์ที่ต้องให้คนแก้:"$'\n'"$hits"; fi
# 10) ข้อมูลจริง/secret/keystore ห้ามขึ้น repo
hits=$(echo "$changed" | awk '$1!~/^D/{print $NF}' | grep -Ei '(^|/)\.env($|\.)|(^|/)key\.properties$|google-services\.json$|\.(jks|keystore|p12|pem|key|dump|backup|bak|sql\.gz|csv|xlsx|xls|parquet|jpg|jpeg|heic|mp4|mov)$' \
  | grep -Ev '\.env\.example$|^docs/|^app/assets/' || true)
[ -n "$hits" ] && err "ห้าม commit ข้อมูลจริง/secret/keystore:"$'\n'"$hits"
# 11) ข้อมูลส่วนบุคคลห้ามลง log (PDPA)
hits=$(added_lines 'app/lib/*' | grep -Ein '(print|debugPrint|log|logger\.[a-z]+)\(.*(phone|tel|email|address|id_?card|citizen|display_?name|password)' || true)
[ -n "$hits" ] && err "สงสัยว่า log ข้อมูลส่วนบุคคล (PDPA) ให้ log แค่ id:"$'\n'"$hits"
[ $fail -eq 0 ] && echo "guard: ผ่านทุกข้อ"; exit $fail
