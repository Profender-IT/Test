# ADR 0003 — เริ่มบน server ในโรงงาน (on-premise) แต่ออกแบบให้ย้ายขึ้น cloud ได้โดยไม่แก้โค้ด
- สถานะ: อนุมัติ · 2026-11-16
## บริบท
ระยะแรกใช้ server ทดสอบในโรงงาน (.177 staging, .176 PostgreSQL) · อนาคตอาจย้ายไป VPS หรือ AWS (region Bangkok ap-southeast-7)
## ตัดสิน: ทุกอย่างที่ต่างกันระหว่าง on-prem กับ cloud ต้องเปลี่ยนได้ด้วย **env/config เท่านั้น**
| เรื่อง | on-prem (ตอนนี้) | cloud (อนาคต) | สิ่งที่โค้ดต้องทำตั้งแต่วันแรก |
|---|---|---|---|
| ฐานข้อมูล | PostgreSQL 18 บน .176 | Amazon RDS for PostgreSQL / managed PG ของ VPS | ใช้ฟีเจอร์ PostgreSQL มาตรฐานเท่านั้น (ห้าม extension ที่ RDS ไม่มี เช่นต้องเช็ก pgvector) · `DATABASE_URL` + TLS (`PGSSLMODE`) |
| ไฟล์แนบ | MinIO หรือ volume | Amazon S3 | เข้าถึงผ่าน storage adapter ที่ใช้ S3 API เสมอ (`STORAGE_ENDPOINT`, `STORAGE_BUCKET`, presigned URL) · ห้าม `fs.writeFile` เก็บข้อมูลถาวร |
| cache / คิว | Redis container | ElastiCache / Redis managed | `REDIS_URL` · คิวทนการ restart (ใช้ PostgreSQL `SKIP LOCKED` หรือ BullMQ) |
| ล็อกอิน | OIDC: Keycloak ในโรงงาน หรือ AD ผ่าน Keycloak | Entra ID / Cognito / Keycloak บน cloud | ใช้มาตรฐาน OIDC อย่างเดียว (`OIDC_ISSUER`, `OIDC_CLIENT_ID`) · ห้ามผูกกับ LDAP ตรงๆ ในแอป |
| image | build บน runner .177 เก็บในเครื่อง | GHCR → ดึงไปรันบน VPS/ECS | tag = commit SHA · workflow `publish` push ไป GHCR เมื่อเปิด `PUBLISH_IMAGES=1` |
| TLS / โดเมน | HTTP ใน LAN (staging) | HTTPS ด้วย Traefik + Let's Encrypt หรือ ALB + ACM | แอปเชื่อ `X-Forwarded-*` จาก proxy ที่กำหนด · base path จาก env |
| secret | `.env` บนเครื่อง (chmod 600) | AWS Secrets Manager / SSM / secret ของ VPS | อ่านจาก env เท่านั้น · ห้ามอ่านไฟล์ secret ด้วย path ตายตัว |
| log / metric | stdout → docker logs + Grafana | CloudWatch / Grafana Cloud | log JSON บรรทัดเดียวออก stdout · `/health` (มีชีวิต) และ `/ready` (DB+Redis+storage พร้อม) |
| migration | main.yml รันก่อน deploy | job ก่อน deploy (ECS task / CI) | migration idempotent · expand → contract · แอปรุ่นเก่าทำงานกับ schema ใหม่ได้ |
| backup | pgBackRest บน .176 | snapshot อัตโนมัติของ RDS + S3 versioning | ทดสอบ restore ทุกไตรมาส |
## ผลที่ตามมา
- ย้ายได้ด้วย: ตั้ง managed DB → `pg_dump`/logical replication → sync ไฟล์ด้วย `rclone`/`aws s3 sync` → เปลี่ยน env → เปลี่ยน DNS (ขั้นตอนเต็มใน `docs/setup/CLOUD_MIGRATION.md`)
- ข้อมูลส่วนบุคคล: ถ้าย้ายขึ้น cloud ต้องอัปเดต ADR เรื่องที่ตั้งข้อมูล (region ไทย) และสัญญาประมวลผลข้อมูล (DPA) ผ่านฝ่ายกฎหมาย/DPO ก่อน
- ห้ามพึ่งของที่มีแค่ในโรงงาน: IP 192.168.x ใน config แอป, ไฟล์บน host path ตายตัว, LDAP ตรง, cron บน host (ใช้ worker แทน)
