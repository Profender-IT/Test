#!/usr/bin/env bash
# สรุป PR ด้วย LLM ในโรงงาน (Ollama บน ops) เพื่อช่วยคนรีวิวอ่านเร็วขึ้น · ไม่ใช่การอนุมัติ · ล้มได้โดยไม่บล็อก PR
# ใช้: bash scripts/ci/pr_summary.sh <base-ref> > summary.md
set -uo pipefail
BASE=${1:-origin/main}
URL=${LLM_BASE_URL:-http://192.168.110.177:11434}
MODEL=${REVIEW_MODEL:-qwen3:1.7b}     # RAM 32 GB: qwen3:4b หรือ qwen2.5-coder:7b จะสรุปโค้ดได้ดีกว่า

diff=$(git diff --stat "$BASE"...HEAD; echo; git diff -U2 "$BASE"...HEAD -- . ':!*lock*' ':!docs/diagrams/*' | head -c 12000)
prompt="สรุป PR นี้เป็นภาษาไทยสำหรับผู้รีวิว ไม่เกิน 8 บรรทัด: 1) เปลี่ยนอะไร 2) จุดที่ควรดูเป็นพิเศษ (logic, SQL, ความปลอดภัย) 3) test ที่ควรมีแต่ยังไม่เห็น ห้ามเดา ถ้าไม่แน่ใจให้บอกว่าไม่แน่ใจ /no_think

$diff"
body=$(jq -n --arg m "$MODEL" --arg p "$prompt" '{model:$m, prompt:$p, stream:false, options:{num_ctx:8192, temperature:0.2}}')
out=$(curl -s --max-time 300 "$URL/api/generate" -d "$body" | jq -r '.response // empty' | sed '/<think>/,/<\/think>/d')
if [ -z "$out" ]; then echo "_(ข้ามสรุปด้วย AI: เรียก $URL ไม่ได้ หรือ AI ปิดอยู่)_"; exit 0; fi
printf '### สรุปโดย AI ในโรงงาน (%s) — ใช้ช่วยอ่าน ไม่ใช่การอนุมัติ\n\n%s\n' "$MODEL" "$out"
