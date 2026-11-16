# ROOM-1 — ตั้งค่า repo + scaffold + CI + staging
> ระดับความเสี่ยง: high (CI, compose, migration) · ทำหลัง ROOM-2 merge
## เกณฑ์รับงาน
- [ ] pnpm workspace: apps/web, apps/api, packages/shared · `pnpm check` = lint + typecheck + test
- [ ] apps/web: base `/roombooking/`, token จาก docs/design/ds/tokens.json, ฟอนต์ self-host, i18n th/en, `pnpm e2e --base-url`
- [ ] apps/api: Fastify, `/roombooking/api/health` + `/ready` (DB + Redis + storage), ไม่ start ถ้า DB user ผิดหรือเป็น superuser, log JSON stdout, ปิดนุ่มนวลเมื่อ SIGTERM
- [ ] storage adapter (S3 API) + MinIO ใน dev · ตั้งค่าทุกอย่างจาก env ตาม ops/production/api.env.example
- [ ] Dockerfile ต่อแอป (non-root) · dev/docker-compose.yml + `pnpm dev:db`, `pnpm dev:seed`
- [ ] db/migrations/0001: roles + ตารางเริ่มต้นตาม SYSTEM_DESIGN §6 · ผ่าน db-schema-guard
- [ ] staging ขึ้นที่ :8089 หลัง merge (ขั้นตอนที่คนต้องทำอยู่ใน PR)
