# ADR 0003 — เริ่มบน server ในโรงงาน แต่ออกแบบให้ย้ายขึ้น cloud ได้
- สถานะ: **ถูกแทนที่** โดย ADR 0001 (Flutter + Supabase) · 2026-11-16
- เหตุผล: โปรเจคนี้ใช้ Supabase (managed) ตั้งแต่วันแรก จึงไม่มี on-prem stack (.176/.177, Compose, MinIO, Redis) ให้ย้าย
- หลักที่ยังใช้ต่อ: config จากภายนอกเท่านั้น (`--dart-define`) · PostgreSQL มาตรฐาน + migration add-only · ไม่ผูกกับเครื่อง/IP ในโรงงาน · ข้อมูลส่วนบุคคลต้องผ่าน DPO ก่อนขึ้น cloud (ADR 0002 ข้อ 1)
