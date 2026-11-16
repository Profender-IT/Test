---
paths:
  - "db/**"
  - "scripts/db/**"
---
# งานฐานข้อมูล
- migration เพิ่มไฟล์ใหม่เท่านั้น · expand → contract · ใช้ subagent db-schema-guard ทุกครั้ง
- GRANT ทุกตารางใหม่ให้ role ตามหน้าที่ (ดู AGENTS.md ข้อ 4) · seed ใช้ข้อมูลสังเคราะห์ใน test/fixtures/synthetic/ เท่านั้น
- งาน migration = high (คน merge) · ถ้าต้องทำอะไรบน staging ให้เขียนขั้นตอนไว้ต้น PR
