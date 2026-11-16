# SYSTEM DESIGN — Profender Room Booking (ร่างตั้งต้น · งาน ROOM-2 จะเติมจาก docs/spec/)

> ส่วน "ตัดสินแล้ว" สืบทอดจาก Profender Modern SCADA · ส่วน "รอเติม" ทำในงาน ROOM-2 จาก `docs/spec/` แล้วส่งให้เจ้าของโปรเจคอนุมัติ

## 1. ภาพรวม (รอเติม)
- ปัญหาที่แก้ · ผู้ใช้แต่ละบทบาท · ปริมาณงาน (รายการ/วัน, ไฟล์แนบ/รายการ, ผู้ใช้พร้อมกัน) · KPI ที่วัดความสำเร็จ

## 2. สถาปัตยกรรม (ตัดสินแล้ว)
```
ผู้ใช้ (เว็บ/มือถือ) ─▶ Traefik ─▶ web (nginx static)  /roombooking/
                                  └▶ api (Fastify)       /roombooking/api
api ─▶ PostgreSQL 18 (.176 · DB roombooking) · Redis (cache/คิว) · ที่เก็บไฟล์แนบ (ดู ADR 0002)
worker ◀─ คิวใน Redis/PostgreSQL ─ งานเบื้องหลัง (แจ้งเตือน, PDF, ย่อรูป)
```
- **stateless app**: api/worker ไม่เก็บ state ในเครื่อง → เพิ่ม instance ได้โดยไม่แก้โค้ด
- **สัญญาเดียว**: type และ validation (zod) อยู่ `packages/shared` ใช้ทั้ง web, api, worker
- **ไฟล์แนบ**: object storage ผ่าน S3 API เสมอ (MinIO on-prem → S3 บน cloud) · DB เก็บแค่ metadata + checksum · อัปโหลด/ดาวน์โหลดด้วย presigned URL

## 3. ขยายตามขั้น (หลักเดียวกับ SCADA)
| ขั้น | เมื่อไร | รูปแบบ |
|---|---|---|
| 1 | เริ่มต้น | server เดียว · Docker Compose · PostgreSQL ร่วม cluster กับ SCADA บน .176 (คนละ database/role) |
| 2 | ผู้ใช้หลักร้อยพร้อมกัน / ต้องมีระบบสำรอง | api หลาย instance + load balancer · PostgreSQL replica · object storage แยก |
| 3 | หลายบริษัท/ทั่วประเทศ | Kubernetes · ฐานข้อมูลเฉพาะทาง · CDN ภายในสำหรับไฟล์ |
หลักที่ใส่ตั้งแต่ขั้น 1: idempotency key ทุกคำสั่งเขียน · pagination ฝั่ง server · index ตาม query จริง · งานหนักเข้าคิว · ทดสอบโหลด 5 เท่าก่อนใช้จริง

## 4. Server และการ deploy (ตัดสินแล้ว)
| เครื่อง | ใช้ทำอะไรในโปรเจคนี้ |
|---|---|
| .177 ops | GitHub Actions runner (ระดับ organization ใช้ร่วมกับ SCADA) · staging `/opt/staging-roombooking` พอร์ต 8089 · Grafana |
| .176 scada | PostgreSQL 18: database `roombooking` + role `roombooking_admin/_api/_worker/_report` · backup ผ่าน pgBackRest ชุดเดียวกับ cluster |
| production | VM ตาม ADR 0002 (ถ้ามีผู้ใช้ภายนอก ต้องอยู่ DMZ หรือแยก) |
- merge → build image tag = SHA → staging + migration + e2e อัตโนมัติ · production = tag `vX.Y.Z` ด้วยมือ
- ⚠ RAM ของ .177 ตอนนี้ 4.8 GB รับ 2 โปรเจคไม่ไหว ต้องขยายก่อนเปิด staging ของโปรเจคนี้

### เป้าหมาย deploy (ADR 0003 · เปลี่ยนด้วย env อย่างเดียว)
| | on-prem (ตอนนี้) | VPS | AWS (Bangkok ap-southeast-7) |
|---|---|---|---|
| แอป | Compose บน server ในโรงงาน | `ops/production/compose.prod.yml` | ECS Fargate หรือ EC2 + compose |
| DB | PostgreSQL 18 (.176) | managed PostgreSQL | RDS for PostgreSQL (Multi-AZ) |
| ไฟล์ | MinIO | object storage S3 API | S3 |
| auth | Keycloak/IdP บริษัท (OIDC) | เหมือนเดิม | Entra/Cognito/Keycloak (OIDC) |
| image | build บน .177 | GHCR | GHCR/ECR |
ขั้นตอนย้าย: `docs/setup/CLOUD_MIGRATION.md`

## 5. ข้อมูลและความปลอดภัย (ตัดสินแล้ว + รอเติม)
- PDPA: ข้อมูลส่วนบุคคลแยกตาราง/คอลัมน์ชัด · เข้ารหัสระหว่างทาง (TLS) · สิทธิ์ตามบทบาท · audit log ทุกการดู/แก้/ส่งออก · กำหนดระยะเก็บและการลบ (รอเติม)
- ไฟล์แนบ: ตรวจชนิดจากเนื้อไฟล์ ไม่ใช่นามสกุล · จำกัดขนาด · ลบ EXIF ตำแหน่ง GPS ถ้าไม่ต้องใช้ · สแกนไวรัส (รอเติม)
- auth: ดู ADR 0002 · ห้ามเปิดฟีเจอร์เขียนบน production ก่อนมี auth

## 6. โดเมน (รอเติมจาก docs/spec/)
- entity หลัก + ER · state machine ของงาน (สถานะ, ใครเปลี่ยนได้, เงื่อนไข) · กติกาเงิน · การแจ้งเตือน · รายงาน
