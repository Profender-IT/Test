# STATUS — ความคืบหน้า (อัปเดตทุก PR)
> โหลดทุก session ผ่าน CLAUDE.md → สั้นเสมอ ≤ 80 บรรทัด · ข้อตัดสินเก่าย้ายไป `docs/DECISIONS.md`
> Claude Code: แก้แถวงานของตัวเอง + ตัดสินแล้ว/ค้าง · คน: แก้ส่วน Infrastructure
> อัปเดตล่าสุด: 2026-11-16

## งาน
| งาน | ชื่อ | สถานะ | PR | หมายเหตุ |
|---|---|---|---|---|
| ROOM-1 | ตั้งค่า repo + scaffold + CI + staging | ⏭ ถัดไป | | ทำตาม docs/tasks/ROOM-1.md |
| ROOM-2 | spec → SYSTEM_DESIGN + DESIGN + ADR + แตกงาน | ⬜ | | ส่งแผนให้เจ้าของโปรเจคก่อน |
สัญลักษณ์: ✅ เสร็จ · 🔄 กำลังทำ · ⏭ ถัดไป · ⬜ ยังไม่เริ่ม · ⛔ ติด

## ตัดสินแล้ว (ล่าสุดก่อน)
- 2026-11-16 ADR 0003 เริ่ม on-prem แต่ cloud-ready: config จาก env, ไฟล์ผ่าน S3 API, OIDC, PostgreSQL มาตรฐาน · ย้ายตาม docs/setup/CLOUD_MIGRATION.md
- 2026-11-16 ใช้โครงสร้างเดียวกับ Profender Modern SCADA: GitHub Flow + กติกา v2 (merge อัตโนมัติ low/medium) + runner ในโรงงาน (.177) + PostgreSQL 18 (.176) · โดเมนแยกจาก SCADA

## ค้างตัดสิน (ดู docs/adr/0002)
- ผู้ใช้ภายนอก (ตัวแทน/ลูกค้า) เข้าระบบจากอินเทอร์เน็ตไหม → กำหนดที่ตั้ง server, auth, PDPA
- ระบบ auth (AD/LDAP ของ IT, Microsoft Entra, หรือของระบบเอง)
- ที่เก็บไฟล์แนบ (รูป/วิดีโอ) และระยะเวลาเก็บ

## Infrastructure (คนอัปเดต)
- ⏳ repo `Profender-IT/Test` · runner ระดับ organization (ใช้ร่วมกับ SCADA) · staging `/opt/staging-roombooking` :8089 บน .177 · DB `roombooking` บน .176
