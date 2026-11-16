# ตั้งค่าโปรเจคใหม่บนโครงสร้างเดิม (.176 / .177) — คนทำ ~1–2 ชั่วโมง

> คำสั่งทั้งหมดของ dev / .177 / .176 พร้อมกับดักที่เจอมาแล้ว: `docs/setup/OPS_COMMANDS.md`

## 0. ก่อนเริ่ม
- **DNS ของ .177**: ใช้ `/etc/resolv.conf` แบบกำหนดเอง (nameserver เราเตอร์ + สำรอง, `options timeout:2 attempts:2 rotate`) แทน systemd-resolved ที่หมดเวลาเป็นพักๆ
- **ขยาย RAM ของ VM ops (.177) เป็น ≥ 8 GB** (Proxmox .175 → ปิด VM ops → Hardware → Memory) · 4.8 GB ไม่พอ 2 โปรเจค
- ตั้ง DNS สำรองของ Docker บน .177 แล้ว (`/etc/docker/daemon.json`) · ตัวเฝ้า runner (`runner-watchdog.timer`) ทำงานอยู่

## 1. Repo
```bash
mkdir -p ~/Job/Profender/Project/Test && cd $_
unzip ~/Downloads/profender_project_template.zip -d .
bash scripts/setup/init_project.sh      # ถามชื่อโปรเจค/key/slug/พอร์ต แล้วแทนค่าทุกไฟล์
git init -b main && git add -A && git commit -m "ROOM-1 โครงโปรเจคจาก template"
gh repo create Profender-IT/Test --private --source . --push
```
ruleset ของ main: บังคับ PR + required checks `pr / risk`, `pr / guard`, `pr / test`, `pr / build` · ไม่บังคับ approval (โหมดคนเดียว)
Settings → Actions → General → Workflow permissions: อนุญาต read/write (ให้ job automerge ทำงาน)

## 2. Runner ใช้ร่วมกับ SCADA (ระดับ organization)
runner ตอนนี้ลงทะเบียนกับ repo Modern-SCADA อย่างเดียว · ให้ย้ายเป็นระดับ organization ครั้งเดียว:
1. GitHub → Organization Profender-IT → Settings → Actions → Runners → New runner → ได้ token
2. บน .177 (ผู้ใช้ที่ติดตั้ง runner):
```bash
cd /opt/actions-runner
sudo ./svc.sh stop && sudo ./svc.sh uninstall
sudo -u deploy ./config.sh remove --token <token จากหน้า runner ของ repo SCADA>
sudo -u deploy ./config.sh --url https://github.com/Profender-IT --token <token ระดับ org> --name ops --labels self-hosted,ops --unattended
sudo ./svc.sh install deploy && sudo ./svc.sh start
```
3. แก้ชื่อ service ใน `/usr/local/bin/runner-watchdog.sh` และ override `Restart=always` ให้ตรงชื่อ service ใหม่ (`systemctl list-units 'actions.runner.*'`)
- runner ตัวเดียวรับงานทีละงาน 2 repo จะต่อคิวกัน · ถ้าคิวยาวให้เพิ่ม runner ตัวที่ 2 (หลังเพิ่ม RAM)

## 3. Staging บน .177
```bash
sudo mkdir -p /opt/staging-roombooking && cd /opt/staging-roombooking
sudo cp <repo>/ops/staging/docker-compose.yml .
printf 'TAG=init\nBASE_PATH=/roombooking\nSTG_DB_PASS=%s\nSTG_API_PASS=%s\n' "$(openssl rand -hex 16)" "$(openssl rand -hex 16)" | sudo tee .env >/dev/null
sudo chown -R deploy: . && sudo chmod 600 .env
sudo docker compose up -d db redis traefik --wait
```
เปิดดูได้ที่ `http://192.168.110.177:8089/roombooking/` หลัง merge แรก

## 4. Production DB บน .176 (ทำเมื่อพร้อมขึ้นจริง)
```bash
sudo -u postgres psql -f ops/production/create_db.sql      # แก้รหัสผ่านใน psql ด้วย \password ทีหลัง
```
- pg_hba.conf: อนุญาตเฉพาะ IP ของ VM production ไปที่ database `roombooking`
- pgBackRest backup ทั้ง cluster อยู่แล้ว · ตรวจ restore ทดสอบ database นี้ 1 ครั้ง

## 5. Claude Code
ติดตั้ง skill ชุดเดียวกับ SCADA (ดู docs/SKILLS.md ของ repo SCADA) เช่น `npx skills add mattpocock/skills` แล้ว
```bash
cd ~/Job/Profender/Project/Test && claude
```
แล้ววาง prompt แรกจาก `docs/setup/KICKOFF_PROMPTS.md`
