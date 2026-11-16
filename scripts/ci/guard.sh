#!/usr/bin/env bash
# Guardrails: ตรวจกฎใน AGENTS.md ที่ lint ทั่วไปจับไม่ได้ · รันในเครื่องได้ก่อน push
# ใช้: bash scripts/ci/guard.sh <base-ref> [head-branch] [pr-title]
set -uo pipefail
BASE=${1:-origin/main}; HEAD_BRANCH=${2:-$(git rev-parse --abbrev-ref HEAD)}; TITLE=${3:-}
JIRA_KEY_RE='ROOM-[0-9]+'
fail=0; err(){ echo "::error::$*"; fail=1; }
changed=$(git diff --name-status "$BASE"...HEAD)
added_lines(){ git diff -U0 "$BASE"...HEAD -- "$@" | grep '^+' | grep -v '^+++' || true; }

# 1) migration เพิ่มไฟล์ใหม่เท่านั้น · ชื่อ NNNN_name.sql
while read -r st f; do
  [[ $f == db/migrations/* ]] || continue
  [[ $st == A ]] || err "ห้ามแก้/ลบ migration เดิม: $f"
  [[ $(basename "$f") =~ ^[0-9]{4}_[a-z0-9_]+\.sql$ ]] || err "ชื่อ migration ต้องเป็น NNNN_name.sql: $f"
done <<< "$(echo "$changed" | awk '{print $1, $NF}')"
# 2) migration ทำลายข้อมูลต้องมี -- contract:
for f in $(echo "$changed" | awk '$1=="A"{print $NF}' | grep '^db/migrations/' || true); do
  if grep -Eiq 'drop[[:space:]]+(table|column)|truncate|alter[[:space:]].*[[:space:]]type[[:space:]]|rename[[:space:]]+(column|to)' "$f" && ! grep -q -- '-- contract:' "$f"; then
    err "$f ทำลาย/เปลี่ยนโครงสร้าง ต้อง expand→contract และใส่ '-- contract: <เหตุผล>'"; fi
done
# 3) secret / IP / รหัสผ่าน
hits=$(added_lines ':!*.md' ':!docs/*' ':!db/migrations/*' ':!*.example' ':!scripts/ci/*' \
  | grep -Ein '(password|passwd|secret|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$\{]{6,}|postgres(ql)?://[^:@/]+:[^@$\{]+@|192\.168\.[0-9]+\.[0-9]+' || true)
[ -n "$hits" ] && err "พบ secret หรือ IP hardcode (ย้ายไป env):"$'\n'"$hits"
# 4) เว็บห้าม hardcode path ราก
hits=$(added_lines 'apps/web/src/*' | grep -En "(fetch|axios\.[a-z]+|new WebSocket)\([[:space:]]*['\"\`]/|href=[\"']/[a-z]" | grep -v 'BASE_URL' || true)
[ -n "$hits" ] && err "เว็บ hardcode path '/' ใช้ apiUrl() / import.meta.env.BASE_URL:"$'\n'"$hits"
# 5) LLM คลาวด์ห้าม (ข้อมูลห้ามออกนอกองค์กร)
hits=$(added_lines '*package.json' | grep -Eio '"(openai|@anthropic-ai/sdk|@google/generative-ai|@google/genai|cohere-ai|@mistralai/[a-z-]+|groq-sdk)"' || true)
[ -n "$hits" ] && err "ห้ามเพิ่ม SDK ของ LLM คลาวด์: $hits"
# 6) แอปห้ามใช้ user admin ของฐานข้อมูล
hits=$(added_lines 'apps/*' | grep -n 'roombooking_admin' || true)
[ -n "$hits" ] && err "แอปห้ามใช้ roombooking_admin:"$'\n'"$hits"
# 7) ต้องผูก Jira key
if [[ ! $HEAD_BRANCH =~ $JIRA_KEY_RE ]] && [[ ! $TITLE =~ $JIRA_KEY_RE ]]; then
  err "ไม่พบ Jira key (ROOM-123) ในชื่อ branch หรือ PR"; fi
# 8) agent ห้ามแตะไฟล์ที่สงวนไว้ให้คน
if [[ $HEAD_BRANCH == agent/* ]]; then
  hits=$(echo "$changed" | awk '{print $NF}' | grep -E '^(deploy/|ops/|scripts/ci/|\.github/|\.claude/settings\.json$|apps/api/src/auth/)|docker-compose.*\.ya?ml$|^AGENTS\.md$' || true)
  [ -n "$hits" ] && err "agent แตะไฟล์ที่ต้องให้คนแก้:"$'\n'"$hits"; fi
# 9) ข้อมูลจริง/secret ห้ามขึ้น repo (รวมข้อมูลส่วนบุคคลของลูกค้า)
hits=$(echo "$changed" | awk '$1!="D"{print $NF}' | grep -Ei '(^|/)\.env($|\.)|\.(dump|backup|bak|sql\.gz|csv|xlsx|xls|parquet|pcap|pem|key|jpg|jpeg|heic|mp4|mov)$' \
  | grep -Ev '\.env\.example$|^test/fixtures/synthetic/|^docs/|^apps/web/public/|^assets/' || true)
[ -n "$hits" ] && err "ห้าม commit ข้อมูลจริง/secret/รูปถ่ายงานเคลม (ใช้ข้อมูลสังเคราะห์ใน test/fixtures/synthetic/):"$'\n'"$hits"
# 10) ข้อมูลส่วนบุคคลห้ามลง log (PDPA)
hits=$(added_lines 'apps/*/src/*' | grep -Ein '(console\.log|logger\.(info|debug|warn)|log\.(info|debug))\(.*(phone|tel|email|address|id_?card|citizen|plate|name)' || true)
[ -n "$hits" ] && err "สงสัยว่า log ข้อมูลส่วนบุคคล (PDPA) ให้ log แค่ id:"$'\n'"$hits"
# 11) cloud-ready (ADR 0003): ห้ามเขียนไฟล์ถาวรนอก storage adapter
hits=$(git diff -U0 "$BASE"...HEAD -- 'apps/*/src/*' ':!apps/*/src/storage/*' ':!*.test.*' | grep '^+' | grep -v '^+++' | grep -En 'fs(/promises)?\.(writeFile|appendFile|mkdir)|createWriteStream\(' || true)
[ -n "$hits" ] && err "เขียนไฟล์นอก storage adapter (ย้ายขึ้น cloud ไม่ได้) ให้ใช้ apps/*/src/storage/ (S3 API):"$'\n'"$hits"
[ $fail -eq 0 ] && echo "guard: ผ่านทุกข้อ"; exit $fail
