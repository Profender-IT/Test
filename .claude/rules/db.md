---
paths:
  - "supabase/**"
---
# งานฐานข้อมูล (Supabase)
- migration ใหม่ด้วย `supabase migration new <name>` เท่านั้น · ห้ามแก้ไฟล์เดิม · expand → contract (`-- contract: <เหตุผล>`)
- ตารางใหม่ใน public: `enable row level security` + revoke สิทธิ์ค่าเริ่มต้นจาก anon/authenticated แล้ว grant เท่าที่ใช้ + policy แยก select/insert/update/delete · ใช้ `(select auth.uid())`
- function `security definer` ต้อง `set search_path = ''` และ revoke execute จาก public/anon/authenticated ถ้าไม่ได้ให้เรียกตรง
- ทุกตาราง/policy ใหม่ต้องมี pgTAP ใน `supabase/tests/database/` ทดสอบทั้ง "เห็นของตัวเอง" และ "ไม่เห็นของคนอื่น" + Playwright API ใน `e2e/tests/api` ถ้าแอปเรียกผ่าน REST
- ทดสอบในเครื่อง: `supabase db reset && supabase test db && supabase db lint` · ใช้ subagent db-schema-guard ทุกครั้ง
- **ห้าม** `supabase link`, `db push`, `functions deploy`, `secrets`, หรือ flag `--linked/--remote/--db-url` (settings.json deny) · deploy เป็นงานของคน
- งาน migration = MANUAL_MERGE (คนรีวิวและ merge)
