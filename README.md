# Profender Room Booking
แอปมือถือ (Android) จองห้องประชุม · Flutter + Supabase

- เริ่มต้น: `docs/setup/NEW_PROJECT_SETUP.md` → `docs/setup/KICKOFF_PROMPTS.md`
- กติกา: `AGENTS.md` · ความคืบหน้า: `docs/STATUS.md` · สถาปัตยกรรม: `docs/SYSTEM_DESIGN.md`, `docs/adr/0001-flutter-supabase.md` · หน้าตา: `DESIGN.md`

## โครงสร้าง
| โฟลเดอร์ | คืออะไร |
|---|---|
| `app/` | Flutter app (Riverpod, go_router, supabase_flutter) |
| `supabase/` | config local, migrations, pgTAP tests |
| `e2e/` | Playwright: API (RLS ผ่าน REST) + web smoke ของ Flutter web build |
| `.github/workflows/` | `ci` (reusable) · `pr` · `main` · `release` · `retry` |

## เริ่มพัฒนาในเครื่อง
ต้องมี: Flutter 3.47, Docker, Supabase CLI 3.x, Node 22
```bash
supabase start                       # Supabase local (ข้อมูลสังเคราะห์)
bash scripts/dev/run_local.sh        # flutter run ด้วย --dart-define จาก supabase status
cd app && flutter test               # unit/widget
supabase test db                     # pgTAP
cd e2e && npm ci && npx playwright test   # ดู e2e/README.md
```

## ทั้งระบบด้วย Docker Compose (dev/demo)
```bash
bash scripts/dev/compose_env.sh          # ครั้งแรก: สร้าง .env (สุ่มรหัสผ่าน/JWT secret · ไม่ขึ้น git)
docker compose up -d --build             # Postgres + Auth + PostgREST + migrate + เว็บ Flutter
docker compose --profile studio up -d    # + Supabase Studio
```
| URL | อะไร |
|---|---|
| http://localhost:8000 | แอป (Flutter web) + `/auth/v1`, `/rest/v1` |
| http://localhost:3000 | Supabase Studio (profile `studio`) |
| `localhost:54332` | Postgres (`postgres` / `POSTGRES_PASSWORD` ใน .env) |

config ทั้งหมดอยู่ใน `docker-compose.yml` (nginx, init SQL, ตัวรัน migration แบบ inline) · ค่าลับอยู่ใน `.env` · ใช้ในเครื่องเท่านั้น ไม่ใช่ staging/production

## CI/CD (GitHub Actions · ubuntu-latest)
| workflow | เมื่อ | ทำอะไร |
|---|---|---|
| `pr` | PR → main | risk/MANUAL_MERGE · guard + gitleaks · `ci` · automerge (agent, ไม่แตะ MANUAL_MERGE) |
| `ci` | ถูกเรียก | flutter format/analyze/test/build APK · supabase start → db reset → lint → pgTAP → Playwright |
| `main` | push main | `ci` + APK staging เป็น artifact (Environment `staging`) |
| `release` | tag `vX.Y.Z` | `ci` + AAB/APK production เซ็นด้วย keystore → GitHub Release (Environment `production`) |

ไม่มีขั้นไหน deploy ขึ้น Supabase · migration ไป staging/production คนรัน `supabase db push` เอง
