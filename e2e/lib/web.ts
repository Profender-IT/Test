import { expect, Page } from '@playwright/test';
import { TestUser } from './supabase';

/** ล็อกอินผ่านหน้าจอจริงของแอป (Flutter web + semantics) */
export async function loginAs(page: Page, user: TestUser) {
  await page.goto('/');
  await page.getByRole('textbox', { name: 'อีเมล' }).fill(user.email);
  await page.getByRole('textbox', { name: 'รหัสผ่าน' }).fill(user.password);
  await page.getByRole('button', { name: 'เข้าสู่ระบบ' }).click();
  await expect(page.getByText(user.email)).toBeVisible({ timeout: 30_000 });
}

/** เวลา HH:MM ใน Asia/Bangkok (ตรงกับ timezoneId ของ project web) */
export function bkkTime(d: Date) {
  return d.toLocaleTimeString('en-GB', { timeZone: 'Asia/Bangkok', hour: '2-digit', minute: '2-digit', hour12: false });
}

/** พรุ่งนี้ตามเวลาไทย เวลา hh:mm → Date (UTC) */
export function tomorrowBkk(hour: number, minute = 0) {
  const nowBkk = new Date(Date.now() + 7 * 3600_000);
  return new Date(Date.UTC(nowBkk.getUTCFullYear(), nowBkk.getUTCMonth(), nowBkk.getUTCDate() + 1, hour - 7, minute));
}

/** เลื่อนหน้าจอ (Flutter web วาดเฉพาะส่วนที่เห็น) จนกว่า locator จะปรากฏ */
export async function scrollUntilVisible(page: Page, locator: import('@playwright/test').Locator, maxSteps = 25) {
  await page.mouse.move(200, 400);
  for (let i = 0; i < maxSteps; i++) {
    if (await locator.first().isVisible().catch(() => false)) return;
    await page.mouse.wheel(0, 350);
    await page.waitForTimeout(150);
  }
  await expect(locator.first()).toBeVisible();
}
