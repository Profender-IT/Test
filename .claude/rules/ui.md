---
paths:
  - "apps/web/**"
---
# งานหน้าเว็บ
- อ่าน DESIGN.md + docs/design/ds/tokens.json + docs/ux/SCREENS.md ก่อน · token เท่านั้น ห้าม hex
- ข้อความผ่าน i18n · 390px ไม่มี scroll แนวนอน · AA · hit target ≥ 44px · self-host ทุกอย่าง
- ข้อมูลส่วนบุคคลซ่อนบางส่วนเป็นค่าเริ่มต้น · ฟอร์มใช้ schema zod จาก packages/shared
- e2e บน staging (.177 ไม่มี GPU, RAM น้อย) ห้ามรอแอนิเมชัน · ตรวจ DOM/URL
