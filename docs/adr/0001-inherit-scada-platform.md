# ADR 0001 — ใช้แพลตฟอร์มเดียวกับ Profender Modern SCADA
- สถานะ: อนุมัติ · 2026-11-16
## ตัดสิน
- GitHub (org Profender-IT) + Jira key `ROOM` · GitHub Flow + กติกา v2 · runner ในโรงงาน (.177)
- Stack: React/Vite/TS · Fastify · PostgreSQL 18 · Redis · Docker Compose · pnpm workspace
- Design system พื้นฐาน Profender (`docs/design/ds/tokens.json`) · ฟอนต์ self-host
- ข้อมูลอยู่ในองค์กร · ห้าม LLM คลาวด์ในแอป · Claude ใช้ช่วยเขียนโค้ดเท่านั้น ไม่เห็นข้อมูลจริง
## ผลที่ตามมา
- ใช้ runner, PostgreSQL cluster, backup, Grafana ร่วมกับ SCADA → ต้องแยก database/role/พอร์ต/โฟลเดอร์ staging ชัดเจน
- .177 ต้องเพิ่ม RAM ก่อนรับโปรเจคที่ 2
