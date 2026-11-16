-- รันบน .176 ด้วย superuser (sudo -u postgres psql -f create_db.sql) · ตั้งรหัสผ่านทีหลังด้วย \password
-- แยก database และ role จาก SCADA ทั้งหมด · ห้ามให้ role ของโปรเจคนี้เข้า database scada
CREATE ROLE roombooking_admin LOGIN;
CREATE ROLE roombooking_api LOGIN;
CREATE ROLE roombooking_worker LOGIN;
CREATE ROLE roombooking_report LOGIN;
CREATE DATABASE roombooking OWNER roombooking_admin;
REVOKE ALL ON DATABASE roombooking FROM PUBLIC;
GRANT CONNECT ON DATABASE roombooking TO roombooking_api, roombooking_worker, roombooking_report;
\c roombooking
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO roombooking_api, roombooking_worker, roombooking_report;
-- สิทธิ์ตารางให้ migration กำหนดเอง (ALTER DEFAULT PRIVILEGES ใน 0001)
