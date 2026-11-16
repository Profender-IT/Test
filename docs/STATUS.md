# STATUS — ความคืบหน้า (อัปเดตทุก PR)
> โหลดทุก session ผ่าน CLAUDE.md → สั้นเสมอ ≤ 80 บรรทัด · ข้อตัดสินเก่าย้ายไป `docs/DECISIONS.md`
> Claude Code: แก้แถวงานของตัวเอง + ตัดสินแล้ว/ค้าง · คน: แก้ส่วน Infrastructure
> อัปเดตล่าสุด: 2026-11-16

## งาน
| งาน | ชื่อ | สถานะ | PR | หมายเหตุ |
|---|---|---|---|---|
| ROOM-1 | bootstrap: Flutter + Supabase + CI (Playwright) | 🔄 รอรีวิว | | profiles + RLS + pgTAP · ไม่มี deploy · MANUAL_MERGE |
| ROOM-2 | spec → SYSTEM_DESIGN + DESIGN + ADR + แตกงาน (rooms/bookings) | ⏭ ถัดไป | | ส่งแผนให้เจ้าของโปรเจคก่อน |
| ROOM-3 | docker-compose ทั้งระบบ (dev/demo) | 🔄 รอรีวิว | | ต่อจาก ROOM-1 · MANUAL_MERGE |
สัญลักษณ์: ✅ เสร็จ · 🔄 กำลังทำ · ⏭ ถัดไป · ⬜ ยังไม่เริ่ม · ⛔ ติด

## ตัดสินแล้ว (ล่าสุดก่อน)
- 2026-11-16 ADR 0001 (เสนอใน ROOM-1): Flutter (Android) + Supabase · staging/production แยก project · ห้าม service_role ในแอป · config ผ่าน --dart-define · CI บน ubuntu-latest ไม่มี deploy อัตโนมัติ · ADR 0003 (on-prem) ถูกแทนที่
- 2026-11-16 กติกาการทำงาน GitHub Flow + กติกา v2 ตาม template · MANUAL_MERGE ใน scripts/ci/risk.sh

## ค้างตัดสิน (ดู docs/adr/0002)
- region + DPA ของ Supabase production (PDPA)
- วิธีล็อกอิน (อีเมล+รหัสผ่าน / Microsoft Entra / magic link)
- กติกาการจอง: อนุมัติหรือไม่, จองล่วงหน้าได้นานเท่าไร, จองซ้ำ, ปล่อยห้องเมื่อไม่มาเช็กอิน
- แจ้งเตือน (ในแอป / push FCM / อีเมล-ปฏิทิน)

## Infrastructure (คนอัปเดต)
- ⏳ repo `Profender-IT/Test` · ruleset main (required checks: risk, guard, ci / flutter, ci / supabase)
- ⏳ Supabase project staging + production · GitHub Environments `staging`/`production` (vars SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY) · production: required reviewers + secrets ANDROID_KEYSTORE_*
