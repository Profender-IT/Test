# OPS COMMANDS — คำสั่งที่ใช้กับเครื่อง dev และ server (สรุปจากที่แก้จริงในโปรเจค SCADA)

> ใช้กับทุกโปรเจคที่สร้างจาก template นี้ · ตั้งตัวแปรด้านล่างก่อน แล้วคัดลอกคำสั่งได้ตรงๆ
> ดูให้แน่ว่าอยู่เครื่องไหน: `picad@t480` = dev (git, gh, pnpm) · `sysadmin@ops` = .177 (docker, runner, staging) · .176 = ฐานข้อมูลจริง (Claude ห้ามเข้า)

```bash
# ── ค่าของโปรเจค (โปรเจคนี้ / SCADA เดิม) ──
SLUG=roombooking                       # SCADA: scada
REPO_DIR=~/Job/Profender/Project/Test
STG=/opt/staging-roombooking           # SCADA: /opt/staging
NET=roombooking-staging_backend        # SCADA: staging_backend   (ดู: sudo docker network ls)
FRONT=roombooking-staging_frontend     # SCADA: staging_frontend
PORT=8089                   # SCADA: 8088
BASE=/roombooking                      # SCADA: /mainprofender
DBU=roombooking                        # ผู้ดูแล DB บน staging (POSTGRES_USER ใน compose) · SCADA: scada
RUNNER=$(systemctl list-units 'actions.runner.*' --no-legend | awk '{print $1}' | head -1)
```

---

## 1. เครื่อง dev (T480)

### ครั้งแรก
```bash
corepack enable                                   # ได้ pnpm
sudo apt install -y postgresql-client-18 gh       # psql + GitHub CLI (gh ควรรุ่นใหม่ ดู gh --version)
git config --global core.pager "less -FRX"        # git log/show ไม่ค้างที่ (END)
gh auth login                                     # บัญชีเดียวของเจ้าของโปรเจค
cd $REPO_DIR && pnpm i
pnpm dev:db && pnpm dev:seed                      # ฐาน dev + ข้อมูลสังเคราะห์ (รันซ้ำได้)
```
ล้างฐาน dev ใหม่ทั้งหมด (ข้อมูลสังเคราะห์เท่านั้น): `docker compose -f dev/docker-compose.yml down -v && pnpm dev:db && pnpm dev:seed`

### งานประจำวัน (ไม่ต้องส่งผลให้ใครดู ถ้าเขียว)
```bash
git switch main && git pull
gh pr list --state open
gh pr checks <n> --watch                          # CI merge ให้เอง (กติกา v2) ยกเว้นชื่อ PR มี [manual]
gh pr merge <n> --squash --delete-branch          # ใช้เฉพาะ PR [manual] หรือ PR chore ของคุณ
gh run list --branch main -L 5                    # main ต้องเขียวเสมอ
gh run watch $(gh run list --branch main -L 1 --json databaseId -q '.[0].databaseId')
```

### ดูว่าทำไม CI ล้ม
```bash
RUN=<id>   # หรือ: RUN=$(gh run list --branch <branch> -L 1 --json databaseId -q '.[0].databaseId')
gh run view "$RUN" --log-failed | grep -iE "error|failed|lookup|timeout|ใหญ่เกิน|denied" | head -20
gh run rerun "$RUN" --failed                      # rerun ได้เฉพาะ run ที่จบแล้ว · workflow retry ทำให้เองสูงสุด 2 รอบ
```
| เจอ | หมายถึง |
|---|---|
| `lookup … i/o timeout`, `fetch failed`, `exit code 6` | DNS/เครือข่ายของ .177 → ข้อ 2.3 |
| `PR ใหญ่เกิน (N > limit)` | ให้ Claude Code ลด/แตก PR · ห้าม [large-ok] ถ้าไม่จำเป็น |
| `agent แตะไฟล์ที่ต้องให้คนแก้` | งานนั้นต้องให้คนทำ chore PR |
| ค้าง queued นาน | runner หลุด → ข้อ 2.2 |

### แก้ไฟล์ที่ agent ห้ามแตะ (.github, scripts/ci, AGENTS.md, settings.json) — ทำใน worktree แยก
```bash
cd $REPO_DIR && git fetch
git worktree add ../chore -b chore/<KEY-n>-<ชื่อ> origin/main && cd ../chore
# … แก้ไฟล์ …
git diff                                          # อ่านก่อน commit เสมอ
git commit -am "<KEY-n> อธิบาย" && git push -u origin HEAD && gh pr create --fill
sleep 15; gh pr checks --watch && gh pr merge --squash --delete-branch
cd $REPO_DIR && git worktree remove ../chore && git pull
```
ห้าม `git switch` ในโฟลเดอร์ที่ Claude Code ทำงานอยู่ · ห้าม push ตรงเข้า main (ruleset บล็อก) · ใช้ terminal เดียวสำหรับคำสั่ง merge

### ส่งไฟล์ไป server
```bash
scp ~/Downloads/<file> sysadmin@192.168.110.177:/tmp/<file>
```

### ตั้ง ruleset / ค่าของ repo
```bash
gh api -X PATCH repos/<org>/<repo> -F allow_auto_merge=false        # ใช้ job automerge ของเราแทน
# required checks: pr / risk, pr / guard, pr / test, pr / build (ห้ามใส่ summary)
# Settings → Actions → Workflow permissions = Read and write
```

---

## 2. server ops (.177) — runner, staging, เครือข่าย

### 2.1 เช็กสุขภาพรวม (หลังเปิดเครื่อง / เมื่อมีอะไรแปลก)
```bash
uptime; free -h | head -3; df -h / | tail -1
systemctl is-active docker $RUNNER runner-watchdog.timer
sudo docker compose -f $STG/docker-compose.yml --profile app ps --format '{{.Service}}\t{{.Status}}'
curl -s -o /dev/null -w "web %{http_code}\n" http://127.0.0.1:$PORT$BASE/
curl -s http://127.0.0.1:$PORT$BASE/api/health; echo
```

### 2.2 runner
```bash
sudo systemctl restart $RUNNER                                       # ปลอดภัยเมื่อไม่มีงานรัน: pgrep -af Runner.Worker
sudo journalctl -u $RUNNER --since "-1h" --no-pager | tail -20
D=/opt/actions-runner/_diag; sudo ls -t $D/Runner_*.log | head -1 | xargs sudo grep -iE "ERR|broker|session" | tail
journalctl -t runner-watchdog --no-pager | tail                       # ประวัติ restart อัตโนมัติ
```
ตั้งครั้งเดียว (ทำแล้วบน SCADA):
```bash
# runner กลับมาเองเมื่อถูก OOM/ล้ม
sudo mkdir -p /etc/systemd/system/$RUNNER.d
printf '[Service]\nRestart=always\nRestartSec=15\n' | sudo tee /etc/systemd/system/$RUNNER.d/restart.conf
sudo systemctl daemon-reload
# ตัวเฝ้า: restart เมื่อขาดการติดต่อ GitHub (BrokerServer error) และไม่ได้รันงาน — สคริปต์ /usr/local/bin/runner-watchdog.sh + timer ทุก 5 นาที
sudo systemctl enable --now runner-watchdog.timer
# Playwright สำหรับ e2e บน staging (เลขรุ่นตาม package.json) — ต้องทำใหม่เมื่ออัปเดตรุ่น
sudo -u deploy -H npx -y playwright@<รุ่น> install chromium
sudo npx -y playwright@<รุ่น> install-deps chromium
```
runner ระดับ organization (ใช้ร่วมหลาย repo): ดู `docs/setup/NEW_PROJECT_SETUP.md` ข้อ 2

### 2.3 DNS และเครือข่าย (ต้นเหตุ CI ล้มบ่อยที่สุด)
```bash
for i in $(seq 10); do curl -sS -o /dev/null -m 10 -w "%{http_code} " https://registry.npmjs.org/pnpm || echo -n "FAIL "; done; echo
sudo docker run --rm busybox nslookup github.com | tail -2
```
แก้ถาวร (ข้าม systemd-resolved ที่หมดเวลาเป็นพักๆ · ถาม IT ก่อนใช้ DNS สาธารณะ):
```bash
sudo rm /etc/resolv.conf
printf 'nameserver 192.168.110.1\nnameserver 1.1.1.1\nnameserver 8.8.8.8\noptions timeout:2 attempts:2 rotate\n' | sudo tee /etc/resolv.conf
sudo systemctl disable --now systemd-resolved
echo '{ "dns": ["192.168.110.1", "1.1.1.1", "8.8.8.8"] }' | sudo tee /etc/docker/daemon.json   # ถ้ามีไฟล์อยู่แล้ว อย่าเขียนทับ
pgrep -af Runner.Worker || sudo systemctl restart docker
```
ย้อนกลับ: `sudo systemctl enable --now systemd-resolved && sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`

### 2.4 หน่วยความจำ
```bash
sudo journalctl -k --since "-2h" --no-pager | grep -i "killed process"     # มี = RAM เต็ม (OOM)
# swap 4 GB (ทำแล้วบน SCADA)
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
# ถาวร: Proxmox (.175) → ปิด VM ops → Hardware → Memory ≥ 8 GB · Options → Start at boot = Yes
sudo docker image prune -af --filter "until=72h" && sudo docker builder prune -af   # ดิสก์เต็มจาก image สะสม
```

### 2.5 staging: compose และ .env
```bash
cd $STG
sudo cp docker-compose.yml docker-compose.yml.bak-$(date +%F)          # backup ก่อนแก้ทุกครั้ง
sudo mv /tmp/<compose ใหม่>.yml docker-compose.yml && sudo chown deploy: docker-compose.yml
sudo docker compose config -q && echo compose-ok
sudo docker compose --profile app up -d                                # สร้าง container ใหม่ตาม compose (ใช้ image ตาม TAG ใน .env)
sudo docker compose exec -T api printenv <ชื่อตัวแปร> </dev/null        # ตรวจว่า env เข้า container แล้ว
```
- `.env` เป็นของผู้ใช้ `deploy` (chmod 600) → อ่านด้วย `sudo` เสมอ · เพิ่มค่าแบบไม่ซ้ำ:
  `sudo grep -q '^KEY=' .env || echo "KEY=$(openssl rand -hex 16)" | sudo tee -a .env >/dev/null`
- ทุก service ต้องมี `restart: unless-stopped` (ไม่งั้นเปิดเครื่องแล้วหน้าเว็บไม่ขึ้น):
  `sudo docker inspect -f '{{.Name}} restart={{.HostConfig.RestartPolicy.Name}}' $(sudo docker compose --profile app ps -aq)`
- โฟลเดอร์ที่ container เขียน (uid 1000): `sudo mkdir -p layouts models && sudo chown -R 1000:1000 layouts models`

### 2.6 staging: ฐานข้อมูล
```bash
cd $STG
# คำสั่ง SQL (ใส่ </dev/null เสมอ ไม่งั้น exec กิน stdin)
sudo docker compose exec -T db psql -U $DBU -d $SLUG -c "SELECT version FROM schema_migrations ORDER BY 1 DESC LIMIT 3;" </dev/null
# รัน migration / seed ด้วย psql ใน image ของ PG (ไม่ต้องติดตั้งอะไรบน .177) · main.yml รัน migration ให้เองทุก deploy
sudo bash -c "cd $STG; set -a; . ./.env; set +a; REPO=\$(ls -d /opt/actions-runner/_work/*/* | head -1)
docker run --rm --network $NET -v \"\$REPO\":/repo:ro -w /repo -e PGPASSWORD=\"\$STG_DB_PASS\" \
  -e DATABASE_URL=\"postgres://$DBU@db:5432/$SLUG\" pgvector/pgvector:0.8.2-pg18 bash scripts/db/seed_demo.sh </dev/null"
# รหัสผ่าน role ของแอป (ต้องตรงกับ .env)
sudo bash -c "cd $STG; set -a; . ./.env; set +a
docker compose exec -T db psql -U $DBU -d $SLUG -q -c \"ALTER ROLE ${SLUG}_api PASSWORD '\$STG_API_PASS'\" </dev/null"
# ทดสอบล็อกอินด้วย role ของแอป
sudo bash -c "cd $STG; set -a; . ./.env; set +a
docker compose exec -T -e PGPASSWORD=\"\$STG_API_PASS\" db psql -h 127.0.0.1 -U ${SLUG}_api -d $SLUG -c 'select current_user' </dev/null"
```
backup / restore (ห้ามกด Ctrl+C ระหว่าง dump · ไฟล์ต้องไม่ใช่ 0 หรือ 20 bytes):
```bash
sudo docker compose exec -T db pg_dump -U $DBU -d $SLUG </dev/null | gzip > ~/stg-$SLUG-$(date +%F-%H%M).sql.gz && ls -lh ~/stg-$SLUG-*.sql.gz
gunzip -c ~/stg-<ไฟล์>.sql.gz | sudo docker compose exec -T db psql -U $DBU -d $SLUG
```

### 2.7 staging: ทดสอบ API / WS / simulator
```bash
B=http://127.0.0.1:$PORT$BASE/api
curl -s $B/health; echo
curl -s -o /dev/null -w "%{http_code}\n" "$B/models/..%2f..%2fetc%2fpasswd"    # ต้อง 400/404
# WS (จาก T480): node -e "const ws=new WebSocket('ws://192.168.110.177:$PORT$BASE/ws');ws.onopen=()=>ws.send(JSON.stringify({type:'subscribe',topic:'<topic>'}));ws.onmessage=e=>{console.log(e.data.slice(0,120));process.exit(0)};setTimeout(()=>process.exit(1),5000)"
```
simulator หรือสคริปต์ node อื่นบน staging (เปิดเองหลังรีบูต):
```bash
cd /opt/actions-runner/_work/*/* && sudo docker rm -f sim 2>/dev/null
sudo docker run -d --init --restart unless-stopped --name sim --network $NET -v "$PWD":/repo:ro -e MQTT_URL="mqtt://mosquitto:1883" \
  node:22.12-bookworm bash -c 'rm -rf /work && mkdir /work && tar -C /repo --exclude=node_modules --exclude=.git --exclude=dist -cf - . | tar -C /work -xf - \
  && cd /work && npm i -g corepack@latest && corepack enable && pnpm i --frozen-lockfile --filter <pkg>... && pnpm <script>'
sudo docker logs --tail 10 sim
```
(`npm i -g corepack@latest` จำเป็น: corepack ใน Node 22.12 มีกุญแจของ npm รุ่นเก่า)

### 2.8 auth rollout บน staging
```bash
SUBNET=$(sudo docker network inspect $FRONT -f '{{(index .IPAM.Config 0).Subnet}}')     # Traefik คุยกับ api ผ่าน frontend
# compose api: COOKIE_SECURE "0" (staging http เท่านั้น) · TRUST_PROXY ${STG_PROXY_SUBNET} · AUTH_MODE ${STG_AUTH_MODE:-legacy}
sudo docker compose exec -it api node dist/cli/users.js create-admin admin                 # รหัสผ่านทดสอบเท่านั้น
sudo sed -i 's/^STG_AUTH_MODE=.*/STG_AUTH_MODE=enforce/' $STG/.env && sudo docker compose --profile app up -d api
```
production ต้องมี HTTPS ก่อน `AUTH_MODE=enforce`

---

## 3. ฐานข้อมูลจริง (.176) — คนทำเท่านั้น
```bash
sudo -u postgres psql -f ops/production/create_db.sql        # database + role แยกต่อโปรเจค
sudo -u postgres psql -c '\password <role>'                  # ตั้งรหัสผ่านทีละ role
# pg_hba.conf: อนุญาตเฉพาะ IP ของ VM แอปไปยัง database ของโปรเจค · แล้ว sudo systemctl reload postgresql
sudo -u postgres pgbackrest --stanza=<stanza> info           # backup ทั้ง cluster (ครอบทุก database)
```

---

## 4. กับดักที่เจอมาแล้ว
| อาการ | สาเหตุ | ทางแก้ |
|---|---|---|
| คำสั่งท้ายๆ ใน `sudo bash -s <<EOF` หายไป | `docker compose exec` กิน stdin | ใส่ `</dev/null` ทุก `exec` ใน script |
| `pg_dump` ค้าง ไฟล์ 0 bytes | exec รอ stdin | ใส่ `</dev/null` |
| `Permission denied` อ่าน `.env` | ไฟล์เป็นของ deploy | `sudo bash -c '… . ./.env …'` |
| ค่า `.env` ซ้ำ 2 บรรทัด | `tee -a` รันซ้ำ | ใช้ `grep -q '^KEY=' || …` |
| `<ชื่อ>` ใน README ทำให้ bash error | `<` คือ redirect | แทนค่าจริงก่อนรัน |
| `gh pr merge 27--squash` | พิมพ์ติดกัน | เว้นวรรค · ไม่มี `~` ท้ายคำสั่ง |
| "already merged" | คำสั่ง merge ที่รอ CI (อีก terminal) merge ไปแล้ว | ใช้ terminal เดียว |
| `gh pr edit` ล้ม GraphQL Projects classic | gh รุ่นเก่า | `gh api -X PATCH repos/<o>/<r>/pulls/<n> -f title=…` หรืออัปเดต gh |
| git ค้างที่ `:`/`(END)` | pager | กด `q` · ตั้ง `core.pager "less -FRX"` |
| เปิดเครื่องแล้วเว็บไม่ขึ้น | service ไม่มี `restart` / VM ไม่ start at boot | ข้อ 2.5 + Proxmox Options |
| CI ค้าง queued ทั้งคืน | runner หลุด/เครื่องปิด | ข้อ 2.2 · ปิดเครื่องเมื่อไม่มีงาน: `gh run list --status in_progress` |
| main แดงหลัง merge แต่ PR เขียว | e2e บน staging เจอข้อมูลจริง/สด | test ห้ามพึ่งข้อมูลสด · mock WS ใน e2e |
