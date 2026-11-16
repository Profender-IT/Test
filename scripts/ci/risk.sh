#!/usr/bin/env bash
# กติกา v2 (Flutter + Supabase): จัดระดับความเสี่ยง + เพดานขนาด + MANUAL_MERGE
# ใช้: bash scripts/ci/risk.sh <base-ref> [head-branch] [pr-title]
# ผลลัพธ์: tier=low|medium|high, lines=N, limit=N, manual=true|false, automerge=true|false · เขียน $GITHUB_OUTPUT ถ้ามี · exit 1 ถ้าเกินเพดาน
set -euo pipefail
BASE=${1:-origin/main}; HEAD_BRANCH=${2:-$(git rev-parse --abbrev-ref HEAD)}; TITLE=${3:-}

# MANUAL_MERGE: แตะไฟล์เหล่านี้ = คนต้องรีวิวและ merge เองเสมอ (CI ไม่ merge ให้แม้เป็น PR ของ agent)
#   docker-compose (ทั้งระบบ dev) · schema/RLS ของฐานข้อมูล · ค่า Supabase · edge functions · CI/สคริปต์ตรวจ · สิทธิ์ของ Claude · กฎ agent · การเซ็น/สิทธิ์ของแอป Android · โค้ด auth ของแอป
MANUAL_MERGE='^(docker-compose\.ya?ml$|supabase/migrations/|supabase/config\.toml$|supabase/functions/|\.github/|scripts/ci/|\.claude/settings\.json$|AGENTS\.md$|app/android/app/build\.gradle(\.kts)?$|app/android/app/src/main/AndroidManifest\.xml$|app/lib/src/(config|supabase)/|app/lib/src/features/auth/)'
# high = ข้อมูล/สิทธิ์/โครงสร้างพื้นฐาน (รวม MANUAL_MERGE ทั้งหมด)
HIGH="$MANUAL_MERGE|^(supabase/seed\.sql$|scripts/|app/android/|app/pubspec\.yaml$)"
LOW='^(docs/|.*\.md$|app/assets/|app/lib/src/l10n/|.*\.arb$)'
# ไม่นับบรรทัด: test, e2e, เอกสาร, ภาพ, lockfile, ไฟล์ generate/scaffold ของ flutter create และ supabase init
NOCOUNT='(pubspec\.lock$|package-lock\.json$|\.g\.dart$|\.freezed\.dart$|^app/test/|^app/integration_test/|^e2e/|^supabase/tests/|_test\.dart$|\.spec\.ts$|^docs/|\.md$|\.(png|jpe?g|svg|webp|ico)$|^app/web/|^app/android/(gradle|app/src/main/(res|kotlin))/|^app/android/[^/]+$|^app/(\.metadata|\.gitignore|analysis_options\.yaml)$|^supabase/config\.toml$|^supabase/\.gitignore$)'

files=$(git diff --name-only "$BASE"...HEAD)
if [ -z "$files" ]; then
  { echo "tier=low"; echo "lines=0"; echo "limit=0"; echo "manual=false"; echo "automerge=false"; } | tee -a "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

tier=low; manual=false; high_files=(); manual_files=()
while IFS= read -r f; do
  if [[ $f =~ $MANUAL_MERGE ]]; then manual=true; manual_files+=("$f"); fi
  if [[ $f =~ $HIGH ]]; then tier=high; high_files+=("$f")
  elif [[ ! $f =~ $LOW ]] && [ "$tier" = low ]; then tier=medium; fi
done <<< "$files"

lines=$(git diff --numstat "$BASE"...HEAD | awk -v re="$NOCOUNT" '$3 !~ re {a+=$1; d+=$2} END {print a+d+0}')

case $tier in low) limit=100000;; medium) limit=600;; high) limit=250;; esac
case "$HEAD_BRANCH" in agent/*) agent=1;; *) agent=0; limit=$(( limit * 3 / 2 ));; esac
automerge=false
[ "$agent" = 1 ] && [ "$manual" = false ] && [[ "$TITLE" != *"[manual]"* ]] && automerge=true

{ echo "tier=$tier"; echo "lines=$lines"; echo "limit=$limit"; echo "manual=$manual"; echo "automerge=$automerge"; } | tee -a "${GITHUB_OUTPUT:-/dev/null}"
echo "--- ระดับ: $tier · โค้ด $lines บรรทัด (ไม่นับ test/e2e/เอกสาร/ภาพ/scaffold) · เพดาน $limit · merge อัตโนมัติ: $automerge"
[ ${#high_files[@]} -gt 0 ] && printf '    ไฟล์เสี่ยงสูง: %s\n' "${high_files[@]}"
[ ${#manual_files[@]} -gt 0 ] && printf '    MANUAL_MERGE (คน merge เอง): %s\n' "${manual_files[@]}"
if [ "$lines" -gt "$limit" ] && [[ "$TITLE" != *"[large-ok]"* ]]; then
  echo "::error::PR ใหญ่เกิน ($lines > $limit บรรทัดโค้ด ระดับ $tier) ให้แตกตามฟีเจอร์ หรือใส่ [large-ok] ในชื่อ PR พร้อมเหตุผล"
  exit 1
fi
exit 0
