---
paths:
  - "apps/api/**"
  - "apps/worker/**"
  - "packages/shared/**"
---
# งาน backend
- env เท่านั้น · DB user ตามหน้าที่ · ไม่ start ถ้าเป็น superuser · statement_timeout ใน pool
- ทุก endpoint เขียน: ตรวจสิทธิ์ + validation zod + idempotency key + audit log · ปิดไว้ด้วย env จนกว่าจะมี auth บน production
- กติกาธุรกิจ (state machine, เงิน) อยู่ packages/shared · test ครอบทุกการเปลี่ยนสถานะ
- cloud-ready (ADR 0003): ไฟล์ผ่าน storage adapter (S3 API) · OIDC · stateless · SIGTERM · `/ready` · PGSSLMODE
- ห้าม log ข้อมูลส่วนบุคคล · response ส่งเฉพาะฟิลด์ที่บทบาทนั้นเห็นได้ · ไม่ส่ง path ภายใน
