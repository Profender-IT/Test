import { expect, test } from '@playwright/test';
import { signUp } from '../../lib/supabase';
import { loginAs } from '../../lib/web';

// Flutter web build ด้วย --dart-define=E2E_SEMANTICS=true เพื่อให้มี semantics tree (role/label) ให้ Playwright หา
// ใช้ตรวจ flow หลักใน CI เท่านั้น · แอปจริงคือ Android (ADR 0001)

test('เปิดแอปแล้วเห็นหน้าเข้าสู่ระบบ', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('button', { name: 'เข้าสู่ระบบ' })).toBeVisible({ timeout: 30_000 });
});

test('เข้าสู่ระบบแล้วเห็นโปรไฟล์ของตัวเอง', async ({ page, request }) => {
  const user = await signUp(request, 'web');

  await loginAs(page, user);
  await expect(page.getByText('สวัสดี ผู้ทดสอบ web')).toBeVisible();
});
