# ROOM-3 — docker-compose ทั้งระบบในไฟล์เดียว (dev/demo)
> ระดับ: high · MANUAL_MERGE (docker-compose.yml, scripts/ci) · ต่อจาก ROOM-1 · ไม่ใช่ช่องทาง deploy
## เกณฑ์รับงาน
- [x] `docker-compose.yml`: Postgres (supabase/postgres), GoTrue, PostgREST, ตัวรัน migration + seed, เว็บ Flutter (build ใน container) + nginx gateway, profile `studio` (Studio + postgres-meta)
- [x] config ทั้งหมด inline ในไฟล์ (configs: content) · ค่าลับใน `.env` จาก `scripts/dev/compose_env.sh` · `.env.example`
- [x] พอร์ต bind 127.0.0.1 · แอปใช้ anon key เท่านั้น
- [x] `docker compose up` แล้ว: สมัคร/ล็อกอินได้, RLS ของ profiles ทำงาน (Playwright ชุดเดิมผ่านเมื่อชี้มาที่ :8000)
- [x] guard/risk: docker-compose.yml เป็น MANUAL_MERGE + agent ห้ามแตะ
