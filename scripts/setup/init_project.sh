#!/usr/bin/env bash
# แทนค่า placeholder ทุกไฟล์ของ template · รันครั้งเดียวที่ root ของ repo ใหม่
set -euo pipefail
ask(){ local v; read -rp "$1 [$2]: " v; echo "${v:-$2}"; }
PROJECT=$(ask "ชื่อระบบ (แสดงผล)" "Profender Claims")
ONE_LINE=$(ask "อธิบาย 1 บรรทัด" "จัดการงานเคลมสินค้าตั้งแต่รับเรื่องจนปิดงาน")
KEY=$(ask "Jira project key (ตัวพิมพ์ใหญ่)" "CLAIM")
SLUG=$(ask "slug (a-z, ใช้เป็นชื่อ DB/role/image/โฟลเดอร์)" "claims")
BASE=$(ask "base path ของเว็บ (ไม่มี /)" "$SLUG")
PORT=$(ask "พอร์ต staging บน .177 (SCADA ใช้ 8088)" "8089")
ORG=$(ask "GitHub organization" "Profender-IT")
REPO=$(ask "ชื่อ repo" "$(printf '%s' "$PROJECT" | tr ' ' '-')")
OWNER=$(ask "GitHub user ของเจ้าของโปรเจค (CODEOWNERS)" "suwaphib-pfd")
DATE=$(date +%F)
[[ $KEY =~ ^[A-Z][A-Z0-9]+$ ]] || { echo "KEY ต้องเป็นตัวพิมพ์ใหญ่/ตัวเลข"; exit 1; }
[[ $SLUG =~ ^[a-z][a-z0-9]*$ ]] || { echo "slug ต้องเป็น a-z/ตัวเลข ไม่มีขีด"; exit 1; }
[ "$PORT" = 8088 ] && { echo "8088 เป็นของ SCADA"; exit 1; }
esc(){ printf '%s' "$1" | sed 's/[&|\\]/\\&/g'; }
grep -rlZ --exclude-dir=.git --exclude=init_project.sh -e '__[A-Z_]*__' . | while IFS= read -r -d '' f; do
  sed -i -e "s|__PROJECT__|$(esc "$PROJECT")|g" -e "s|__ONE_LINE__|$(esc "$ONE_LINE")|g" -e "s|__KEY__|$KEY|g" \
         -e "s|__SLUG__|$SLUG|g" -e "s|__BASE__|$BASE|g" -e "s|__STG_PORT__|$PORT|g" -e "s|__GH_ORG__|$ORG|g" \
         -e "s|__REPO__|$REPO|g" -e "s|__GH_OWNER__|$OWNER|g" -e "s|__DATE__|$DATE|g" "$f"
done
for f in docs/tasks/__KEY__-*.md; do [ -e "$f" ] && mv "$f" "${f/__KEY__/$KEY}"; done
left=$(grep -rn --exclude-dir=.git --exclude=init_project.sh -E '__(PROJECT|ONE_LINE|KEY|SLUG|BASE|STG_PORT|GH_ORG|REPO|GH_OWNER|DATE)__' . || true)
[ -n "$left" ] && { echo "ยังมี placeholder เหลือ:"; echo "$left"; exit 1; }
echo "เสร็จ: $PROJECT · key $KEY · /$BASE/ · staging :$PORT · ต่อไปทำตาม docs/setup/NEW_PROJECT_SETUP.md ข้อ 1"
