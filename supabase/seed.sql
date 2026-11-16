-- ข้อมูลสังเคราะห์สำหรับ local dev / CI เท่านั้น (supabase db reset) · ห้ามข้อมูลจริง (PDPA)
-- ผู้ใช้ทดสอบสร้างผ่าน Auth API ใน e2e/ · ห้องตัวอย่าง 4 ห้อง (+1 ห้องปิดใช้งาน ไว้ทดสอบว่าไม่แสดง)
insert into public.rooms (name, capacity, floor, equipment, is_active) values
  ('ห้องประชุม A', 6,  'ชั้น 2', array['ทีวี', 'ไวท์บอร์ด'], true),
  ('ห้องประชุม B', 10, 'ชั้น 2', array['โปรเจกเตอร์', 'ไวท์บอร์ด'], true),
  ('ห้องประชุม C', 4,  'ชั้น 3', array['ทีวี'], true),
  ('ห้องประชุมใหญ่', 30, 'ชั้น 5', array['โปรเจกเตอร์', 'ไมโครโฟน', 'วิดีโอคอล'], true),
  ('ห้องปิดปรับปรุง', 8, 'ชั้น 4', array[]::text[], false)
on conflict (name) do nothing;
