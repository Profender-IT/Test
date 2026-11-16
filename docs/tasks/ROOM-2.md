# ROOM-2 — ออกแบบระบบจองห้องจาก spec
> ระดับ: high (ต้องให้เจ้าของโปรเจคตัดสิน) · PR เอกสารอย่างเดียว · ดู KICKOFF_PROMPTS ข้อ 1
## เกณฑ์รับงาน
- [ ] คำถามที่ spec ไม่ตอบถูกถามและตอบครบ (ADR 0002)
- [ ] SYSTEM_DESIGN §1, §5, §6 ครบ · ER (profiles, rooms, bookings, …) + state machine ของการจองเป็น mermaid
- [ ] ออกแบบ RLS ต่อตาราง (ใครเห็น/สร้าง/แก้/ยกเลิกอะไร) + constraint กันจองซ้อน (exclusion constraint)
- [ ] สีสถานะห้อง/การจองใน tokens.json + DESIGN.md §3 (AA ทั้งสองธีม)
- [ ] docs/ux/SCREENS.md (หน้าจอ, route ของ go_router, บทบาท) + task ระยะ 1 ทุกงาน + ลำดับใน docs/tasks/README.md
