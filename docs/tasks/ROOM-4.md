# ROOM-4 — schema ห้อง + การจอง (รวม ROOM-2 ออกแบบ)
> ระดับ: high · MANUAL_MERGE (migration)
## เกณฑ์รับงาน
- [x] rooms, bookings + exclusion constraint กันจองซ้อน + กติกาเวลา (CHECK + trigger) + RLS + column grant
- [x] room_busy_slots() ให้คนอื่นเห็นแค่ช่วงไม่ว่าง
- [x] pgTAP 24 ข้อ · Playwright API 5 test · seed ห้องสังเคราะห์
- [x] SYSTEM_DESIGN §6 (ER + state machine), ADR 0002 ข้อ 3-4
