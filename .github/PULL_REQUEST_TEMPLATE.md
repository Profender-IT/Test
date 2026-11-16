<!-- ชื่อ PR ขึ้นต้นด้วย Jira key เช่น "ROOM-12 หน้ารายการห้อง" -->
## Jira
ROOM-

## ทำอะไร
<!-- 1–3 บรรทัด -->

## ทดสอบอย่างไร
- [ ] `flutter test` (unit/widget) ใหม่หรือแก้:
- [ ] pgTAP (`supabase test db`) ครอบ RLS/constraint ใหม่ ทั้งทางบวกและลบ
- [ ] Playwright (`e2e/`) API หรือ web ถ้าแตะ flow หลัก
- [ ] migration รันบนฐานว่างได้ (`supabase db reset`) และแอปรุ่นเดิมยังทำงานกับ schema ใหม่ (expand → contract)
- [ ] ภาพหน้าจอ Android (ถ้าแก้ UI)

## ขั้นตอนที่คนต้องทำบน Supabase staging/production (ถ้ามี = ใส่ [manual] ในชื่อ PR)
<!-- เช่น supabase db push ไป staging, ตั้งค่า Auth provider -->

## ความเสี่ยงและการย้อนกลับ

## ข้อมูลส่วนบุคคล (PDPA)
- [ ] ไม่มีการเก็บ/แสดง/ส่งออกข้อมูลส่วนบุคคลเพิ่ม · ถ้ามี ระบุฟิลด์ เหตุผล และ RLS ที่คุม

## เอกสาร
- [ ] อัปเดต `docs/STATUS.md` · ข้อตัดสินย่อยลง `docs/DECISIONS.md`
