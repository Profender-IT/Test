# KICKOFF PROMPTS — วางทีละข้อใน Claude Code (session ใหม่ของ repo นี้)

## 0. Session แรก: ตรวจ repo + สรุปความเข้าใจ (ยังไม่เขียนโค้ด)
```
อ่าน CLAUDE.md, AGENTS.md, docs/STATUS.md, docs/SYSTEM_DESIGN.md, DESIGN.md, docs/adr/, docs/spec/ ทั้งหมด
สรุปให้ผม ≤ 20 บรรทัด: ระบบนี้ทำอะไร, ผู้ใช้, กติกาที่ต้องทำตาม, สิ่งที่ยังไม่ชัดใน spec
ยังไม่เขียนโค้ด ยังไม่สร้าง branch
```

## 1. ROOM-2 ออกแบบระบบจาก spec (high · ส่งแผนก่อน)
```
ทำ docs/tasks/ROOM-2.md · ถามผมเฉพาะเรื่องที่ spec ไม่ตอบ (≤ 10 ข้อ, มีตัวเลือก + ค่าแนะนำ)
ผลลัพธ์ (PR เอกสารอย่างเดียว):
- docs/SYSTEM_DESIGN.md เติม §1, §5, §6: บทบาท, ER (mermaid), state machine ของการจอง, RLS ต่อตาราง, constraint กันจองซ้อน, แจ้งเตือน, รายงาน
- docs/adr/0002 ตัดสินตามคำตอบผม · ADR ใหม่ถ้าจำเป็น
- DESIGN.md §3: สีสถานะห้อง/การจอง → tokens.json (AA ทั้งสองธีม)
- docs/ux/SCREENS.md: หน้าจอ, route (go_router), บทบาท
- docs/tasks/ROOM-n.md ทุกงานระยะ 1 (เกณฑ์รับงาน, ระดับความเสี่ยง, ลำดับ) + docs/tasks/README.md
เปิด PR แล้วหยุด
```

## 2. งานถัดไปทุกงาน
```
/clear แล้ว: ทำ docs/tasks/ROOM-n.md ตามกติกา v2 · ส่งแผนก่อนเฉพาะงาน high/ต้องตัดสินใจ/แตะ Supabase staging
migration ใหม่: supabase migration new + pgTAP + db-schema-guard · ห้าม supabase link/db push
```
