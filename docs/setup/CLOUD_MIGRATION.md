# ย้ายจาก on-premise ขึ้น VPS / AWS (runbook · ใช้เมื่อตัดสินใจย้าย)
> หลักการตาม ADR 0003: เปลี่ยนแค่ config ไม่แก้โค้ด · ทำ staging บน cloud ก่อน production เสมอ

## 0. ก่อนย้าย (ตัดสินใจ/อนุมัติ)
- [ ] ADR ที่ตั้งข้อมูล + DPA (PDPA) ผ่านฝ่ายกฎหมาย/DPO · เลือก region (AWS Bangkok `ap-southeast-7` ถ้าต้องอยู่ในไทย)
- [ ] เลือกเป้าหมาย: **VPS** (Docker Compose เดิม + managed PostgreSQL) หรือ **AWS** (ECS Fargate/EC2 + RDS + S3)
- [ ] งบประมาณ, ผู้ดูแล, เวลาหยุดระบบที่ยอมรับได้ (downtime window)

## 1. เตรียมปลายทาง
| ส่วน | VPS | AWS |
|---|---|---|
| ฐานข้อมูล | managed PostgreSQL ของผู้ให้บริการ (เวอร์ชันเดียวกัน 18) | RDS for PostgreSQL 18 · Multi-AZ สำหรับ production |
| ไฟล์ | object storage แบบ S3 ของผู้ให้บริการ | S3 + versioning + lifecycle |
| แอป | `ops/production/compose.prod.yml` + Traefik + Let's Encrypt | ECS service ต่อแอป หรือ EC2 + compose เดิม |
| image | ดึงจาก GHCR | ดึงจาก GHCR หรือ ECR |
| auth | Keycloak บน VPS หรือ IdP ของบริษัท | Entra ID / Cognito / Keycloak |
| secret | ไฟล์ env บน VPS (600) | Secrets Manager / SSM |
| monitor | Grafana + Uptime check | CloudWatch alarms |

## 2. ทดสอบบน staging ปลายทาง
1. เปิด `PUBLISH_IMAGES=1` (repo variable) ให้ CI push image ไป GHCR
2. deploy image เดียวกับ on-prem ด้วย env ของ cloud → รัน migration → `pnpm e2e --base-url https://<staging-cloud>/...`
3. ทดสอบ restore backup และ load test (5 เท่าของโหลดจริง)

## 3. ย้ายข้อมูลจริง (cutover)
- เล็ก (≤ 10 GB, หยุดระบบได้ 30–60 นาที): โหมดอ่านอย่างเดียว → `pg_dump -Fc` → `pg_restore` → sync ไฟล์ (`rclone sync` / `aws s3 sync`) → ตรวจจำนวนแถว/checksum
- ใหญ่หรือหยุดนานไม่ได้: logical replication (publication/subscription) จาก .176 ไปปลายทาง → รอ lag = 0 → สลับ
- เปลี่ยน DNS (TTL ต่ำล่วงหน้า 1 วัน) → เฝ้าดู 24 ชม.

## 4. ย้อนกลับ
- เก็บระบบเดิมแบบอ่านอย่างเดียว 7 วัน · ถ้ามีปัญหาสลับ DNS กลับ (ข้อมูลที่เกิดหลัง cutover ต้อง export กลับ ให้วางแผนไว้ก่อน)

## 5. หลังย้าย
- ปิดการเข้าถึง DB on-prem ของแอปนี้ · ลบสำเนาข้อมูลส่วนบุคคลบน server เดิมตามนโยบาย · อัปเดต STATUS/ADR
