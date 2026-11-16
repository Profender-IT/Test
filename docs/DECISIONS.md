# DECISIONS — ข้อตัดสินย่อยที่ agent ตัดสินเองระหว่างทำงาน (กติกา v2)
> เจ้าของโปรเจคอ่านย้อนหลังวันละครั้ง · ข้อไหนไม่เห็นด้วยให้เปิดงานแก้ · ข้อตัดสินใหญ่ยังอยู่ใน `docs/adr/` และ STATUS "ตัดสินแล้ว"
> รูปแบบ: `YYYY-MM-DD · ROOM-n · ตัดสินอะไร · เพราะอะไร · ย้อนกลับได้อย่างไร`

- 2026-11-16 · ROOM-1 · เปิด platform `web` เพิ่มจาก android · Playwright ขับแอป Android native ไม่ได้ จึงทดสอบ flow ผ่าน Flutter web build ใน CI (ไม่ deploy เว็บ) · ลบ `app/web/` และ project `web` ใน e2e ถ้าเปลี่ยนไปใช้ Patrol/Maestro บน emulator
- 2026-11-16 · ROOM-1 · ชื่อ define `SUPABASE_PUBLISHABLE_KEY` (รับได้ทั้ง `sb_publishable_…` และ anon JWT แบบเดิม) · supabase_flutter 2.18 deprecate `anonKey` แล้ว · ย้อนกลับ: เปลี่ยนชื่อใน env.dart + workflow
- 2026-11-16 · ROOM-1 · profiles: insert ผ่าน trigger `on_auth_user_created` เท่านั้น · แอป update ได้แค่ display_name/department (column grant) · ไม่มี delete (cascade จาก auth.users) · ย้อนกลับ: migration ใหม่เพิ่ม grant/policy
- 2026-11-16 · ROOM-1 · ผู้ใช้ทดสอบใน Playwright สมัครผ่าน Auth API ด้วย publishable key (ไม่ใช้ service_role แม้ใน CI) · local ปิด email confirmation ใน config.toml อยู่แล้ว
- 2026-11-16 · ROOM-1 · ลบ `scripts/ci/pr_summary.sh` (เรียก Ollama บน .177 ซึ่ง runner ของ GitHub เข้าไม่ถึง) · job summary เหลือแค่คอมเมนต์ระดับความเสี่ยง
- 2026-11-16 · ROOM-1 · release signing อ่าน `app/android/key.properties` ถ้ามี (release.yml สร้างจาก secrets) ไม่มีใช้ debug key · ใช้ได้เฉพาะ build ทดสอบ · release.yml ล้มถ้าไม่มี keystore
