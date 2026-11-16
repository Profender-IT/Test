# ตั้งค่าโปรเจค (คนทำ ~1 ชั่วโมง) — Flutter + Supabase + GitHub Actions

## 1. Repo และ ruleset
- repo: `Profender-IT/Test` (private) · main = template · PR แรก `ROOM-1 bootstrap`
- ruleset ของ main: บังคับ PR · required checks: `risk`, `guard`, `ci / flutter`, `ci / supabase` · ห้าม force push
- Settings → Actions → General → Workflow permissions: Read and write (ให้ job automerge / summary ทำงาน)

## 2. Supabase (คนทำเท่านั้น · Claude Code ถูก deny)
1. สร้าง 2 project: `roombooking-staging`, `roombooking-prod` (region ตาม ADR 0002 ข้อ 1)
2. Auth: ปิด signup สาธารณะบน production (หรือจำกัดโดเมน) · ตั้ง Site URL / redirect ตามวิธีล็อกอินที่เลือก
3. migration (ทำหลัง PR ที่มี migration merge แล้ว):
```bash
supabase login
supabase link --project-ref <staging-ref> && supabase db push      # staging ก่อนเสมอ
supabase link --project-ref <prod-ref>    && supabase db push      # production ก่อน tag release
```
4. **ห้าม** นำ service_role / secret key ไปใส่ใน GitHub vars ของแอป หรือส่งให้ Claude

## 3. GitHub Environments
| Environment | vars | secrets | protection |
|---|---|---|---|
| `staging` | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (ของ staging) | – | – |
| `production` | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (ของ prod) | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | required reviewers · deployment tags `v*` |

สร้าง upload keystore (เก็บสำรองนอก repo):
```bash
keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -i upload.jks | gh secret set ANDROID_KEYSTORE_BASE64 --env production
```

## 4. Release
```bash
git switch main && git pull && git tag v0.1.0 && git push origin v0.1.0
```
→ `release.yml` รอคนอนุมัติ Environment production → AAB/APK ใน GitHub Release → อัปโหลด Play Console ด้วยมือ

## 5. เครื่อง dev
Flutter 3.47 · Android Studio/SDK · Docker · Supabase CLI 3.x · Node 22 · gh
```bash
supabase start && bash scripts/dev/run_local.sh
```
แล้ววาง prompt จาก `docs/setup/KICKOFF_PROMPTS.md`
