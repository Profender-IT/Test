# ADR 0001 — แอปมือถือ Flutter (Android) + Supabase · staging/production แยก project · ไม่มี service_role ในแอป
- สถานะ: เสนอ (รอเจ้าของโปรเจคอนุมัติใน PR ROOM-1) · 2026-11-16
- แทนที่: ADR 0001 เดิม (inherit SCADA platform: React/Fastify/PostgreSQL บน .176/.177) และ ADR 0003 (cloud-ready on-prem)

## บริบท
ระบบจองห้องประชุมใช้งานบนมือถือเป็นหลัก (ดูห้องว่าง จอง ยกเลิก เช็กอิน) · ทีมเล็ก ไม่อยากดูแล API server/DB/backup เอง
template เดิมเป็นเว็บแอป on-prem (React + Fastify + PostgreSQL บน .176/.177 + Docker Compose) ซึ่งเกินความจำเป็นสำหรับงานนี้

## ตัดสิน
1. **แอป: Flutter, ส่งมอบเป็น Android** (`app/`, package `com.profender.room_booking`)
   - Riverpod (state) · go_router (route) · supabase_flutter (auth + data)
   - platform `web` เปิดไว้ **เพื่อทดสอบ e2e ด้วย Playwright ใน CI เท่านั้น** ไม่ deploy เป็นเว็บ
2. **Backend: Supabase** (Postgres + Auth + PostgREST · Storage/Edge Functions เมื่อจำเป็น)
   - schema อยู่ใน `supabase/migrations/` (add-only) · ทดสอบ RLS ด้วย pgTAP (`supabase/tests/database/`) และ Playwright API (`e2e/tests/api/`)
   - **กติกาสิทธิ์และกติกาธุรกิจที่ต้องเชื่อถือได้อยู่ใน DB** (RLS, constraint เช่น exclusion constraint กันจองเวลาซ้อน, function) ไม่ใช่ในแอป
3. **staging และ production เป็น Supabase project แยกกัน** (คนละ URL/key/ผู้ใช้/ข้อมูล)
   - dev ใช้ `supabase start` (local, ข้อมูลสังเคราะห์) · CI ใช้ local stack ใน runner
   - GitHub Environments `staging` / `production` เก็บ `vars.SUPABASE_URL`, `vars.SUPABASE_PUBLISHABLE_KEY` · production มี required reviewers
4. **ห้าม service_role / secret key ในแอปและใน repo**
   - แอปใช้ publishable (หรือ anon) key + JWT ของผู้ใช้เท่านั้น · `app/lib/src/config/env.dart` ปฏิเสธกุญแจสิทธิ์สูงตอนเริ่มแอป · guard.sh ตรวจทุก PR
   - งานที่ต้องสิทธิ์สูงทำใน Edge Function / SQL function (`security definer`) ที่ตรวจสิทธิ์เอง
5. **config ผ่าน `--dart-define` เท่านั้น** (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `APP_ENV`) · ห้าม .env / asset / hardcode
6. **CI/CD บน GitHub-hosted runner (`ubuntu-latest`)** · ไม่มีขั้น deploy อัตโนมัติไป Supabase
   - `pr.yml` ทดสอบ · `main.yml` ทดสอบ + APK staging (artifact) · `release.yml` tag `vX.Y.Z` → AAB/APK เซ็นแล้ว → GitHub Release
   - migration ไป staging/production: **คนรัน `supabase db push` เอง** หลังรีวิว · Claude Code ถูก deny `supabase link/db push/functions deploy/secrets`

## ผลที่ตามมา
- ไม่ใช้ .176/.177 · ไม่มี Docker Compose / pnpm / staging บน VM ในโรงงาน
- ข้อมูลผู้ใช้อยู่บน cloud ของ Supabase → **ต้องตัดสิน region และ DPA (PDPA) ก่อนขึ้น production** (ADR 0002 ข้อ 1)
- ถ้าวันหน้าต้องย้ายกลับ on-prem: Supabase self-host ได้ (Postgres มาตรฐาน + migration ชุดเดิม) แต่ต้องวางแผน auth/backup ใหม่
- iOS เพิ่มทีหลังได้ด้วย `flutter create --platforms ios .` (ต้องมี Apple Developer account + macOS runner)
