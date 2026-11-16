---
paths:
  - "app/**"
---
# งานแอป Flutter
- อ่าน DESIGN.md + docs/design/ds/tokens.json + docs/ux/SCREENS.md ก่อน · สี/ระยะจาก theme ที่สร้างจาก tokens เท่านั้น ห้าม hex ในหน้าจอ
- ข้อความผ่าน `lib/src/l10n/` · จอ 360dp ใช้ได้ ไม่ล้น · hit target ≥ 48dp · AA ทั้ง light/dark
- state ด้วย Riverpod · route ด้วย go_router (`lib/src/router.dart`) · เรียก Supabase ผ่าน `supabaseClientProvider` เท่านั้น
- config จาก `--dart-define` (`lib/src/config/env.dart`) เท่านั้น · ห้าม service_role/secret key · ห้าม .env/asset config
- สิทธิ์ข้อมูลบังคับที่ RLS ฝั่ง DB · แอปซ่อนปุ่มได้แต่ห้ามพึ่งแอปเป็นตัวกันสิทธิ์
- ห้าม print/log ข้อมูลส่วนบุคคล · test: `flutter test` (unit/widget) + Playwright web smoke ใน `e2e/tests/web` ถ้าเพิ่ม flow หลัก
