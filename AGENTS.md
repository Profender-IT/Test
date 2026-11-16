# AGENTS.md — Profender Room Booking (อ่านก่อนแก้โค้ดทุกครั้ง)

ไฟล์นี้คือ context ให้ทั้งคนและ AI coding agent อ่านก่อนเริ่มงาน · Claude Code อ่านผ่าน `CLAUDE.md`
กติกาการทำงาน (GitHub + Jira + กติกา v2) สืบทอดจาก profender_project_template · stack เปลี่ยนเป็น **Flutter (Android) + Supabase** (ADR 0001)

## ระบบคืออะไร
Profender Room Booking — แอปมือถือจองห้องประชุม (ดูห้องว่าง จอง ยกเลิก) · ธุรกิจ: `docs/spec/` · สถาปัตยกรรม: `docs/SYSTEM_DESIGN.md` · หน้าตา: `DESIGN.md` · ข้อตัดสินใหญ่: `docs/adr/`

## โครงสร้าง repo
```
app/                       Flutter (Android · web ไว้ทดสอบ e2e ใน CI เท่านั้น) · package com.profender.room_booking
  lib/src/config/env.dart  ค่า config จาก --dart-define (แหล่งเดียว)
  lib/src/supabase/        provider ของ SupabaseClient / auth state
  lib/src/features/        หน้าจอตามฟีเจอร์ · lib/src/l10n/ ข้อความ UI
supabase/migrations/       YYYYMMDDHHMMSS_name.sql เพิ่มไฟล์ใหม่เท่านั้น (supabase migration new)
supabase/tests/database/   pgTAP (RLS / constraint)
e2e/                       Playwright: tests/api (Supabase REST + RLS) · tests/web (Flutter web smoke)
scripts/ci/                guard.sh, risk.sh (คนดูแล) · scripts/dev/ สคริปต์ช่วย dev
.github/workflows/         ci (reusable) · pr · main · release · retry
```

## กฎที่ห้ามละเมิด (CI ตรวจ)
1. **ไม่ hardcode secret / JWT / URL ของ project จริง / IP** · config ของแอปผ่าน `--dart-define` เท่านั้น (`Env` ใน `app/lib/src/config/env.dart`) · ห้าม flutter_dotenv/.env asset
2. **ห้าม service_role / secret key ในแอปและใน repo** · แอปใช้ publishable (anon) key + JWT ผู้ใช้ · งานสิทธิ์สูงทำใน DB function/Edge Function ที่ตรวจสิทธิ์เอง
3. **สิทธิ์ข้อมูลบังคับด้วย RLS** · ตารางใหม่ใน public ต้อง `enable row level security` ในไฟล์เดียวกัน + revoke สิทธิ์ค่าเริ่มต้น + grant เท่าที่ใช้ + pgTAP ครอบทั้งทางบวกและลบ
4. **Migration เพิ่มไฟล์ใหม่เท่านั้น** · DROP/เปลี่ยน type ทำแบบ expand → contract พร้อม `-- contract: <เหตุผล>`
5. **กติกาธุรกิจที่ต้องเชื่อถือได้อยู่ใน DB** (เช่นห้ามจองเวลาซ้อนด้วย exclusion constraint, สถานะการจอง) · แอปตรวจซ้ำเพื่อ UX ได้แต่ห้ามเป็นตัวกันเดียว
6. **ข้อมูลไม่ออกนอกองค์กรเกินจำเป็น**: ห้าม SDK LLM คลาวด์ · ห้าม analytics/crash SDK ภายนอกจนกว่าจะมี ADR
7. **ข้อมูลส่วนบุคคล (PDPA)**: เก็บเท่าที่จำเป็น · คอลัมน์ระบุ `COMMENT ... 'PDPA: ...'` · ห้าม print/log (log แค่ id) · ข้อมูลทดสอบสังเคราะห์เท่านั้น (`@example.com/.test`)
8. เวลาเก็บ `timestamptz` (UTC) แสดง Asia/Bangkok · ห้ามคำนวณช่วงเวลาจองด้วยเวลาเครื่อง ให้ DB ตัดสิน
9. ข้อความ UI ผ่าน `app/lib/src/l10n/` · ไทยเป็นหลัก

## วิธีทำงาน (GitHub + Jira)
- งานเริ่มจาก Jira (`ROOM-n`) → `docs/tasks/ROOM-n.md` · branch `agent/ROOM-n-short` (Claude) · `feature/…` หรือ `chore/…` (คน) · commit `ROOM-n อธิบาย`
- PR ไป `main` เท่านั้น ห้าม push ตรง · ทุก PR อัปเดต `docs/STATUS.md` · ข้อตัดสินย่อยลง `docs/DECISIONS.md`
- ต้องมี test ทุกครั้งที่เปลี่ยน logic · ก่อนเปิด PR รันคำสั่งในหัวข้อ "คำสั่ง" ให้ผ่าน
- agent ห้ามแตะ: `.github/`, `scripts/ci/`, `.claude/settings.json`, `AGENTS.md`, `supabase/config.toml`, `app/android/app/build.gradle.kts`, migration แบบ contract
- **ห้ามรัน** `supabase link`, `supabase db push`, `supabase functions deploy`, `supabase secrets`, หรือคำสั่งที่มี `--linked/--remote/--db-url` · deploy เป็นงานของคน

## กติกา v2 — ขนาด PR และการ merge ตามความเสี่ยง (risk.sh)
| ระดับ | ตัวอย่าง | เพดาน agent (นับเฉพาะโค้ด ไม่นับ test/e2e/เอกสาร/ภาพ/lockfile/scaffold) | merge |
|---|---|---|---|
| low | เอกสาร, ข้อความ l10n, asset | ไม่จำกัด | CI ผ่าน → อัตโนมัติ |
| medium | หน้าจอ, feature ในแอป | 600 · 1 ฟีเจอร์ = 1 PR | CI ผ่าน → อัตโนมัติ |
| high | migration, auth, config, android, scripts, .github | 250 | ดู MANUAL_MERGE |
- **MANUAL_MERGE** (คนรีวิวและ merge เองเสมอ): `supabase/migrations/`, `supabase/config.toml`, `supabase/functions/`, `.github/`, `scripts/ci/`, `.claude/settings.json`, `AGENTS.md`, `app/android/app/build.gradle(.kts)`, `AndroidManifest.xml` หลัก, `app/lib/src/config/`, `app/lib/src/supabase/`, `app/lib/src/features/auth/`
- agent ห้าม merge เอง · job `automerge` merge ให้เฉพาะ PR ของ agent ที่ไม่แตะ MANUAL_MERGE และไม่มี `[manual]` ในชื่อ
- งานที่ต้องให้คนทำบน Supabase staging (db push, ตั้งค่า Auth) → ใส่ `[manual]` ในชื่อ PR + ขั้นตอนไว้ต้น PR แล้วหยุด
- CI ล้ม: workflow `retry` รันใหม่เองสูงสุด 2 รอบ · ล้มครบ 3 รอบค่อยรายงาน · main แดง = งานด่วนที่สุด
- PR ที่พึ่งกัน: รอ merge แล้วค่อยแตก branch ใหม่จาก origin/main · PR อิสระเปิดคู่ขนานได้ไม่เกิน 3

## MCP และข้อมูล
- ใช้ได้: filesystem ของ repo, `git`/`gh`, Supabase local (`supabase start`, ข้อมูลสังเคราะห์)
- ห้าม: ต่อ Supabase project staging/production (dashboard, MCP, psql, REST ด้วยกุญแจจริง) · ห้ามวางข้อมูลพนักงานจริงลง prompt

## คำสั่ง
```bash
cd app && flutter pub get && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
supabase start && supabase db reset && supabase test db && supabase db lint     # ต้องมี Docker
cd e2e && npm ci && SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… npx playwright test   # ดู e2e/README.md
bash scripts/dev/run_local.sh                  # รันแอปบน emulator กับ Supabase local
bash scripts/ci/guard.sh origin/main           # ตรวจกฎก่อน push
bash scripts/ci/risk.sh origin/main            # ระดับความเสี่ยง/ขนาด/MANUAL_MERGE
```
