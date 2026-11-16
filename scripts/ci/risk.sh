#!/usr/bin/env bash
# กติกา v2 (30 ต.ค. 2026): จัดระดับความเสี่ยง + เพดานขนาดตามระดับ
# ใช้: bash scripts/ci/risk.sh <base-ref> [head-branch] [pr-title]
# ผลลัพธ์: tier=low|medium|high, lines=N, limit=N, automerge=true|false · เขียน $GITHUB_OUTPUT ถ้ามี · exit 1 ถ้าเกินเพดาน
set -euo pipefail
BASE=${1:-origin/main}; HEAD_BRANCH=${2:-$(git rev-parse --abbrev-ref HEAD)}; TITLE=${3:-}

# high = ข้อมูล/เงิน/สิทธิ์/โครงสร้างพื้นฐาน · ปรับ path ของกติกาธุรกิจ (packages/shared/src/rules) ตาม SYSTEM_DESIGN
HIGH='^(db/migrations/|packages/shared/src/(rules|money|state)|apps/api/src/auth/|deploy/|ops/|scripts/ci/|scripts/db/|\.github/|\.claude/settings\.json$|AGENTS\.md$|.*docker-compose.*\.ya?ml$|.*Dockerfile$)'
LOW='^(docs/|.*\.md$|apps/web/public/|apps/web/src/i18n/|.*\.css$)'
# ไม่นับบรรทัด: test, e2e, เอกสาร, ภาพ, lockfile, ไฟล์ generate
NOCOUNT='(pnpm-lock\.yaml|package-lock\.json|\.snap$|\.generated\.|\.(test|spec|int\.test|e2e)\.tsx?$|/e2e/|^docs/|\.md$|\.(png|jpe?g|svg|glb|bin)$|^test/fixtures/)'

files=$(git diff --name-only "$BASE"...HEAD)
[ -z "$files" ] && { echo "tier=low"; echo "lines=0"; exit 0; }

tier=low; high_files=()
while IFS= read -r f; do
  if [[ $f =~ $HIGH ]]; then tier=high; high_files+=("$f")
  elif [[ ! $f =~ $LOW ]] && [ "$tier" = low ]; then tier=medium; fi
done <<< "$files"

lines=$(git diff --numstat "$BASE"...HEAD | awk -v re="$NOCOUNT" '$3 !~ re {a+=$1; d+=$2} END {print a+d+0}')

case $tier in low) limit=100000;; medium) limit=600;; high) limit=250;; esac
case "$HEAD_BRANCH" in agent/*) agent=1;; *) agent=0; limit=$(( limit * 3 / 2 ));; esac
automerge=false; [ "$agent" = 1 ] && [[ "$TITLE" != *"[manual]"* ]] && automerge=true

{ echo "tier=$tier"; echo "lines=$lines"; echo "limit=$limit"; echo "automerge=$automerge"; } | tee -a "${GITHUB_OUTPUT:-/dev/null}"
echo "--- ระดับ: $tier · โค้ด $lines บรรทัด (ไม่นับ test/เอกสาร/ภาพ) · เพดาน $limit · merge อัตโนมัติ: $automerge"
[ ${#high_files[@]} -gt 0 ] && printf '    ไฟล์เสี่ยงสูง: %s\n' "${high_files[@]}"
case $tier in
  high)   echo "    CI ผ่าน → merge อัตโนมัติ เว้นแต่ชื่อ PR มี [manual]";;
  medium) echo "    CI ผ่านครบ → merge อัตโนมัติ (PR ของ agent) · ตรวจย้อนหลังจาก STATUS/staging";;
  low)    echo "    CI ผ่านครบ → merge อัตโนมัติ (PR ของ agent)";;
esac
if [ "$lines" -gt "$limit" ] && [[ "$TITLE" != *"[large-ok]"* ]]; then
  echo "::error::PR ใหญ่เกิน ($lines > $limit บรรทัดโค้ด ระดับ $tier) ให้แตกตามฟีเจอร์ หรือใส่ [large-ok] ในชื่อ PR พร้อมเหตุผล"
  exit 1
fi
