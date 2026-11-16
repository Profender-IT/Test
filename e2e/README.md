# e2e — Playwright

| project | ทดสอบอะไร | ต้องมี |
|---|---|---|
| `api` | Supabase REST/Auth จริง: RLS ของ `profiles` (เห็น/แก้ได้แค่ของตัวเอง, anon อ่านไม่ได้) | Supabase local |
| `web` | Flutter web build: หน้าเข้าสู่ระบบ → ล็อกอิน → เห็นโปรไฟล์ตัวเอง | Supabase local + `app/build/web` |

แอปจริงคือ Android · Flutter web build ด้วย `--dart-define=E2E_SEMANTICS=true` เพื่อเปิด semantics tree ให้ Playwright หา element ด้วย role/label

## รันในเครื่อง
```bash
supabase start
eval "$(supabase status -o json | jq -r '"export SUPABASE_URL=\(.API_URL) SUPABASE_PUBLISHABLE_KEY=\(.PUBLISHABLE_KEY // .ANON_KEY)"')"
(cd ../app && flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY --dart-define=E2E_SEMANTICS=true)
npm ci && npx playwright install chromium
npx playwright test                 # ทั้งหมด · --project=api หรือ --project=web
```
ผู้ใช้ทดสอบสมัครผ่าน Auth API ด้วย publishable key (ไม่ใช้ service_role) อีเมล `e2e-*@example.com` · ห้ามชี้ไป project staging/production

## รันกับ docker compose (ทั้งระบบ · ROOM-3)
```bash
bash scripts/dev/compose_env.sh && E2E_SEMANTICS=true docker compose up -d --build
set -a; . ../.env; set +a
SUPABASE_URL=http://localhost:8000 SUPABASE_PUBLISHABLE_KEY=$ANON_KEY E2E_WEB_PORT=8000 npx playwright test
```
