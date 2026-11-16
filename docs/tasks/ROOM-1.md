# ROOM-1 — bootstrap: Flutter + Supabase + CI/CD (Playwright)
> ระดับความเสี่ยง: high · MANUAL_MERGE (CI, migration, signing, settings) · branch `chore/ROOM-1-bootstrap` · ห้าม supabase link / deploy
## เกณฑ์รับงาน
- [x] ลบ apps/, docker-compose*, pnpm, ops/ (.176/.177), scripts/db, pr_summary (Ollama .177)
- [x] `app/` = `flutter create --org com.profender --platforms android,web` · supabase_flutter, go_router, flutter_riverpod · config ผ่าน `--dart-define` เท่านั้น · ปฏิเสธ service_role key ตอนเริ่มแอป
- [x] `supabase/` = `supabase init` · migration แรก `profiles` + RLS + trigger สร้าง profile · pgTAP: อ่าน/แก้ได้แค่ของตัวเอง, anon อ่านไม่ได้
- [x] `e2e/` Playwright: API (RLS ผ่าน REST) + web smoke (login → เห็นโปรไฟล์)
- [x] workflows: ci (reusable) / pr / main / release / retry · runs-on ubuntu-latest ทั้งหมด · ไม่มี deploy
- [x] risk.sh MANUAL_MERGE · guard.sh กฎ Flutter/Supabase · `.claude/settings.json` deny supabase link/db push/functions deploy/secrets
- [x] ADR 0001 Flutter + Supabase · AGENTS/CLAUDE/README/DESIGN/SYSTEM_DESIGN อัปเดต
- [ ] CI เขียวบน PR · เจ้าของโปรเจครีวิวและ merge เอง
