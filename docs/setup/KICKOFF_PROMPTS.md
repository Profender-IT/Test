# KICKOFF PROMPTS — วางทีละข้อใน Claude Code (session ใหม่ของ repo นี้)

## 0. Session แรก: ตรวจ repo + สรุปความเข้าใจ (ยังไม่เขียนโค้ด)
```
อ่าน CLAUDE.md, AGENTS.md, docs/STATUS.md, docs/SYSTEM_DESIGN.md, DESIGN.md, docs/adr/, docs/spec/ ทั้งหมด
สรุปให้ผม ≤ 20 บรรทัด: ระบบนี้ทำอะไร, ผู้ใช้, กติกาที่ต้องทำตาม, สิ่งที่ยังไม่ชัดใน spec
ยังไม่เขียนโค้ด ยังไม่สร้าง branch
```

## 1. ROOM-2 ออกแบบระบบจาก spec (high · ส่งแผนก่อน)
```
ทำ docs/tasks/ROOM-2.md · ใช้ /grill-with-docs ถามผมเฉพาะเรื่องที่ spec ไม่ตอบ (≤ 10 ข้อ, มีตัวเลือก + ค่าแนะนำ)
ผลลัพธ์ (PR เอกสารอย่างเดียว):
- docs/SYSTEM_DESIGN.md เติม §1, §5, §6: บทบาท, entity + ER (mermaid), state machine ของงาน, กติกาเงิน, แจ้งเตือน, รายงาน, ปริมาณงาน
- docs/adr/0002 ตัดสินตามคำตอบผม · ADR ใหม่ถ้าจำเป็น
- DESIGN.md §3: สีสถานะของงาน → เพิ่มใน docs/design/ds/tokens.json (AA ทั้งสองธีม)
- docs/ux/SCREENS.md: รายการหน้า, route, บทบาท, งานที่รับผิดชอบ
- docs/tasks/ROOM-n.md ทุกงานระยะ 1 (เกณฑ์รับงาน, ระดับความเสี่ยง, ลำดับ) + docs/tasks/README.md
เปิด PR แล้วหยุด
```

## 2. ROOM-1 scaffold (หลัง ROOM-2 merge · ทำต่อเนื่องตามกติกา v2)
```
ทำ docs/tasks/ROOM-1.md: pnpm workspace (apps/web, apps/api, packages/shared), Dockerfile ต่อแอป, health endpoint,
dev/docker-compose + pnpm dev:db/dev:seed (ข้อมูลสังเคราะห์), migration 0001 (roles + ตารางเริ่มต้นจาก SYSTEM_DESIGN), e2e smoke (pnpm e2e --base-url)
งานที่แตะ staging/compose ให้เขียนขั้นตอนให้ผมไว้ใน PR · เปิด PR ตามกติกา v2
```

## 3. งานถัดไปทุกงาน
```
/clear แล้ว: ทำ docs/tasks/ROOM-n.md ตามกติกา v2 · ส่งแผนก่อนเฉพาะงาน high/ต้องตัดสินใจ/แตะ staging
```

## สลับไปทำงานใน repo SCADA
ปิด Claude Code แล้ว `cd` ไปโฟลเดอร์ SCADA ก่อนเปิดใหม่ · อย่าเปิดสองโปรเจคใน session เดียว (กติกาและ STATUS คนละชุด)
