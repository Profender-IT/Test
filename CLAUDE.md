# CLAUDE.md — Profender Room Booking

@AGENTS.md
@docs/STATUS.md

## อ่านเพิ่มเมื่อจำเป็น
| เมื่อ | อ่าน |
|---|---|
| เริ่มงานใหม่ | `docs/tasks/ROOM-n.md` + ไฟล์ที่ task อ้าง |
| ภาพรวมธุรกิจ / กติกา | `docs/spec/` |
| สถาปัตยกรรม / scale / server | `docs/SYSTEM_DESIGN.md`, `docs/adr/` |
| งานหน้าเว็บ | `.claude/rules/ui.md` (โหลดเอง) → `DESIGN.md`, `docs/design/ds/tokens.json`, `docs/ux/SCREENS.md` |
| งาน schema | `.claude/rules/db.md` (โหลดเอง) · subagent `db-schema-guard` |
| วิธี prompt ต่องาน | `docs/setup/KICKOFF_PROMPTS.md` |

## ปิดงานทุกครั้ง (ก่อนเปิด PR)
1. subagent `guardrail-reviewer` + `/code-review` → แก้ข้อ "บล็อก"
2. `pnpm check` · `bash scripts/ci/guard.sh origin/main` · `bash scripts/ci/risk.sh origin/main` (รันซ้ำหลัง commit สุดท้าย)
3. อัปเดต `docs/STATUS.md` แถวของงานนี้ · ข้อตัดสินย่อยลง `docs/DECISIONS.md`

## จังหวะทำงาน (กติกา v2)
- ทุกระดับ: เปิด PR → `gh pr checks <n> --watch` → merge อัตโนมัติแล้ว `git fetch` ทำงานถัดไปต่อ
- ต้องให้คนทำอะไรบน staging ก่อน: ใส่ [manual] ในชื่อ PR + ขั้นตอน แล้วหยุด
- CI ล้ม: รอ retry อัตโนมัติ ไม่ต้องหยุดถาม · ล้มครบ 3 รอบหรือ main แดงค่อยรายงาน
- จบวัน: สรุป 5 บรรทัดใน STATUS (เสร็จ, ค้าง, ต้องให้คนตัดสิน)
