import { expect, Page } from '@playwright/test';
import { TestUser } from './supabase';

/** ล็อกอินผ่านหน้าจอจริงของแอป (Flutter web + semantics) */
export async function loginAs(page: Page, user: TestUser) {
  await page.goto('/');
  await flutterFill(page, 'อีเมล', user.email);
  await flutterFill(page, 'รหัสผ่าน', user.password);
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

/** ข้อความที่ Flutter อาจวางเป็นข้อความหรือเป็น aria-label (เช่น Chip) */
export function textOrLabel(page: Page, text: string) {
  return page.getByText(text).or(page.getByLabel(text));
}

/** กรอกช่องของ Flutter web ให้แทนค่าเดิมเสมอ (fill ตรงๆ บางครั้งไม่เข้า controller) */
export async function flutterFill(page: Page, name: RegExp | string, value: string) {
  const box = page.getByRole('textbox', { name });
  await scrollUntilVisible(page, box);
  // Flutter web สร้างช่องกรอกจริงหลังโฟกัส → รอให้พร้อม แล้วลบค่าเดิมทีละตัวก่อนพิมพ์ (ลองซ้ำได้ถ้ายังไม่ตรง)
  await expect(async () => {
    await box.click();
    await expect(box).toBeFocused();
    await page.waitForTimeout(150);
    await page.keyboard.press('End');
    const current = (await box.inputValue()).length;
    for (let i = 0; i < current + 2; i++) await page.keyboard.press('Backspace');
    await page.keyboard.type(value, { delay: 15 });
    await expect(box).toHaveValue(value, { timeout: 1_000 });
  }).toPass({ timeout: 15_000 });
}

/** จองห้องพรุ่งนี้ในช่วงสุ่มที่ยังว่าง (ฐาน local ที่รันซ้ำอาจมีการจองค้าง) · คืนช่วงที่จองได้ */
export async function bookTomorrowFreeSlot(
  request: import('@playwright/test').APIRequestContext,
  user: TestUser,
  roomId: string,
  minutes: number,
  title: string,
) {
  const { rest } = await import('./supabase');
  const r = rest(user);
  for (let attempt = 0; attempt < 10; attempt++) {
    const start = tomorrowBkk(Math.floor(Math.random() * 22), [0, 15, 30, 45][Math.floor(Math.random() * 4)]);
    const end = new Date(start.getTime() + minutes * 60_000);
    const res = await request.post(`${r.url}/bookings`, {
      headers: r.headers,
      data: { room_id: roomId, title, starts_at: start.toISOString(), ends_at: end.toISOString() },
    });
    if (res.status() === 201) return { start, end };
    expect((await res.json()).code, 'ล้มได้เฉพาะเพราะชนช่วงเดิม').toBe('23P01');
  }
  throw new Error('หาช่วงว่างไม่ได้ใน 10 ครั้ง');
}

/** หาช่วงพรุ่งนี้ที่ห้องยังว่างจริง (ถาม room_busy_slots ก่อน) สำหรับ test ที่จองผ่านหน้าจอ */
export async function freeTomorrowSlot(
  request: import('@playwright/test').APIRequestContext,
  user: TestUser,
  roomId: string,
  minutes: number,
) {
  const { rest } = await import('./supabase');
  const r = rest(user);
  const dayStart = tomorrowBkk(0);
  const dayEnd = new Date(dayStart.getTime() + 24 * 3600_000);
  const res = await request.post(`${r.url}/rpc/room_busy_slots`, {
    headers: r.headers,
    data: { p_from: dayStart.toISOString(), p_to: dayEnd.toISOString() },
  });
  const busy = ((await res.json()) as { room_id: string; starts_at: string; ends_at: string }[])
    .filter((b) => b.room_id === roomId)
    .map((b) => [new Date(b.starts_at).getTime(), new Date(b.ends_at).getTime()]);
  for (let attempt = 0; attempt < 200; attempt++) {
    const start = tomorrowBkk(Math.floor(Math.random() * 22), [0, 15, 30, 45][Math.floor(Math.random() * 4)]);
    const end = new Date(start.getTime() + minutes * 60_000);
    if (busy.every(([s, e]) => end.getTime() <= s || start.getTime() >= e)) return { start, end };
  }
  throw new Error('ไม่มีช่วงว่างพรุ่งนี้');
}
