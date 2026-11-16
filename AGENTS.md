# AGENTS.md — Profender Room Booking (อ่านก่อนแก้โค้ดทุกครั้ง)

ไฟล์นี้คือ context ให้ทั้งคนและ AI coding agent อ่านก่อนเริ่มงาน · Claude Code อ่านผ่าน `CLAUDE.md`
โครงสร้างการทำงานสืบทอดจากโปรเจค Profender Modern SCADA (repo, CI, กติกา, server) แต่ **โดเมนไม่เกี่ยวกับ SCADA**

## ระบบคืออะไร
Profender Room Booking — ระบบ จองห้องประชุมผ่านแอปมือถือ · รายละเอียดธุรกิจ: `docs/spec/` · สถาปัตยกรรม: `docs/SYSTEM_DESIGN.md` · หน้าตา: `DESIGN.md` · ข้อตัดสินใหญ่: `docs/adr/`

## โครงสร้าง repo
```
apps/web          React + TS + Vite · base path /roombooking/
apps/api          Fastify (REST) · /roombooking/api · health /roombooking/api/health
apps/worker       งานเบื้องหลัง (แจ้งเตือน, สร้างเอกสาร, ย่อรูป) · เพิ่มเมื่อจำเป็น
ops/production    compose.prod.yml (VPS/on-prem) + api.env.example · cloud ใช้ env ชุดเดียวกัน
packages/shared   type, สถานะ/กติกาธุรกิจ (แหล่งเดียว), validation (zod)
db/migrations     NNNN_name.sql เพิ่มไฟล์ใหม่เท่านั้น
test/fixtures/synthetic   ข้อมูลทดสอบสังเคราะห์เท่านั้น
ops/              compose ของ staging / SQL ของ production (คนดูแล)
```

## กฎที่ห้ามละเมิด (CI ตรวจ)
1. **ไม่ hardcode secret / IP / รหัสผ่าน** อ่านจาก env เท่านั้น
2. **ไม่ hardcode path `/`** ในเว็บ ใช้ `import.meta.env.BASE_URL` และ `apiUrl()`
3. **Migration เพิ่มไฟล์ใหม่เท่านั้น** · DROP/เปลี่ยน type ทำแบบ expand → contract พร้อม `-- contract: <เหตุผล>`
4. **DB user ตามหน้าที่**: api=`roombooking_api`, worker=`roombooking_worker`, รายงาน=`roombooking_report` (อ่านอย่างเดียว) · ห้ามใช้ `roombooking_admin` ในแอป · แอปไม่ start ถ้าเป็น superuser
5. **ข้อมูลไม่ออกนอกองค์กร**: ห้าม SDK LLM คลาวด์ ห้าม CDN ตอน runtime (self-host ฟอนต์/ไอคอน/ไลบรารี)
6. **ข้อมูลส่วนบุคคล (PDPA)**: เก็บเท่าที่จำเป็น · ห้ามลง log (log แค่ id) · แสดงตามสิทธิ์ · ทุกการดู/ส่งออกข้อมูลส่วนบุคคลบันทึก audit · ข้อมูลทดสอบสังเคราะห์เท่านั้น ห้ามรูป/เอกสารจริงของลูกค้าใน repo
7. **กติกาธุรกิจอยู่ที่ `packages/shared` ที่เดียว** (สถานะงาน, การเปลี่ยนสถานะ, การคำนวณเงิน) ห้ามเขียนซ้ำในเว็บหรือ SQL
8. เวลาเก็บ `timestamptz` (UTC) แสดง Asia/Bangkok · เงินเก็บเป็น `numeric(12,2)` ห้าม float

## พร้อมย้ายขึ้น cloud (ADR 0003) — on-prem วันนี้ cloud วันหน้า แก้แค่ config
9. **config จาก env เท่านั้น** · ห้าม IP/hostname ของโรงงาน, path ของ host, ชื่อเครื่อง ในโค้ดหรือ config ของแอป
10. **ไฟล์ถาวรผ่าน storage adapter (S3 API) เท่านั้น** (`packages/shared` หรือ `apps/api/src/storage/`) · on-prem = MinIO, cloud = S3 · ดาวน์โหลด/อัปโหลดด้วย presigned URL · ห้าม `fs.writeFile` เก็บข้อมูลถาวรนอก adapter
11. **แอป stateless** · session/คิว/ล็อกอยู่ใน PostgreSQL/Redis · รับ SIGTERM แล้วปิดอย่างนุ่มนวล · `/health` (มีชีวิต) + `/ready` (DB/Redis/storage พร้อม)
12. **auth มาตรฐาน OIDC** (Keycloak/Entra/Cognito สลับได้ด้วย env) · ห้ามผูก LDAP ตรงในแอป
13. **PostgreSQL มาตรฐาน** ใช้ได้กับ RDS/managed PG · extension ใหม่ต้องเช็กว่า RDS รองรับ แล้วบันทึกใน DECISIONS.md · รองรับ `PGSSLMODE`
14. **log JSON บรรทัดเดียวออก stdout** (ไม่มีข้อมูลส่วนบุคคล) · ห้ามเขียน log ลงไฟล์

## วิธีทำงาน (GitHub + Jira)
- งานเริ่มจาก Jira (`ROOM-n`) → `docs/tasks/ROOM-n.md` · branch `agent/ROOM-n-short` (Claude) หรือ `feature/…` (คน) · commit `ROOM-n อธิบาย`
- PR ไป `main` เท่านั้น ห้าม push ตรง · ทุก PR อัปเดต `docs/STATUS.md` · ข้อตัดสินย่อยลง `docs/DECISIONS.md`
- ต้องมี test ทุกครั้งที่เปลี่ยน logic · รัน `pnpm check` + `bash scripts/ci/guard.sh origin/main` + `bash scripts/ci/risk.sh origin/main` ก่อนเปิด PR
- agent ห้ามแตะ: `.github/`, `scripts/ci/`, `ops/`, `deploy/`, ไฟล์ compose, `.claude/settings.json`, `apps/api/src/auth/`, `AGENTS.md`, migration แบบ contract

## กติกา v2 — ขนาด PR และการ merge ตามความเสี่ยง
| ระดับ (risk.sh) | ตัวอย่าง | เพดาน agent (นับเฉพาะโค้ด ไม่นับ test/e2e/เอกสาร/ภาพ/lockfile) | merge |
|---|---|---|---|
| low | เอกสาร, i18n, CSS | ไม่จำกัด | CI ผ่าน → อัตโนมัติ |
| medium | หน้าเว็บ, API, ฟีเจอร์ทั่วไป | 600 · 1 ฟีเจอร์ = 1 PR | CI ผ่าน → อัตโนมัติ |
| high | migration, auth, กติกาเงิน/สถานะ, scripts/db, .github, compose | 250 | CI ผ่าน → อัตโนมัติ (ระวังเป็นพิเศษ) |
- agent ห้าม merge เอง · job `automerge` ใน CI merge แล้วสั่ง deploy staging
- งานที่ต้องให้คนเตรียม staging → ใส่ `[manual]` ในชื่อ PR + ขั้นตอนไว้ต้น PR แล้วหยุด (CI ไม่ merge ให้)
- CI ล้ม: workflow `retry` รันใหม่เองสูงสุด 2 รอบ · ล้มครบ 3 รอบค่อยรายงาน
- แผนรออนุมัติเฉพาะ: งาน high, ต้องตัดสินใจ, แตะ staging · อื่นๆ ทำตามเกณฑ์ใน task ได้เลย
- PR ที่พึ่งกัน: รอ merge แล้วค่อยแตก branch ใหม่จาก origin/main · PR อิสระเปิดคู่ขนานได้ไม่เกิน 3
- main แดงหลัง merge = งานด่วนที่สุด

## MCP และข้อมูล
- ใช้ได้: filesystem ของ repo, `git`/`gh`, ฐานข้อมูล dev ในเครื่อง (ข้อมูลสังเคราะห์)
- ห้าม: ต่อ MCP/อ่าน DB/Redis ของ .176 (production) · ห้าม curl/ssh/psql ไป 192.168.110.* · ห้ามวางข้อมูลลูกค้าจริงลง prompt

## คำสั่ง
```bash
pnpm i && pnpm check                    # lint + typecheck + test
pnpm dev:db && pnpm dev:seed            # ฐาน dev + ข้อมูลสังเคราะห์
bash scripts/ci/guard.sh origin/main    # ตรวจกฎก่อน push
bash scripts/ci/risk.sh origin/main     # ระดับความเสี่ยง/ขนาด
```
