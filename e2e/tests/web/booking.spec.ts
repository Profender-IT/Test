import { expect, Page, test } from '@playwright/test';
import { cancelAllBookings, rest, signUp, TestUser } from '../../lib/supabase';
import { bkkTime, bookTomorrowFreeSlot, flutterFill, freeTomorrowSlot, loginAs, scrollUntilVisible, textOrLabel } from '../../lib/web';

// แต่ละ test ใช้ห้องของตัวเอง กันชนกันเมื่อรันขนาน (rooms.spec ใช้ห้อง A)
const ROOM_OK = 'ห้องประชุม C';
const ROOM_CLASH = 'ห้องประชุม B';

async function openBookForm(page: Page, room: string) {
  await page.getByRole('checkbox', { name: 'พรุ่งนี้' }).click();
  const btn = page.getByRole('button', { name: `จอง${room} · พรุ่งนี้` });
  await scrollUntilVisible(page, btn);
  await btn.click();
  await expect(page.getByRole('heading', { name: 'จองห้อง', exact: true })).toBeVisible();
  await expect(page.getByText('ช่วงที่ไม่ว่างในวันนี้')).toBeVisible();
}

async function submit(page: Page) {
  const btn = page.getByRole('button', { name: 'ยืนยันการจอง' });
  await scrollUntilVisible(page, btn);
  await btn.click();
}

async function fillAndSubmit(page: Page, start: Date, end: Date, title: string) {
  await flutterFill(page, /เวลาเริ่ม/, bkkTime(start));
  await flutterFill(page, /เวลาจบ/, bkkTime(end));
  await flutterFill(page, /หัวข้อประชุม/, title);
  await submit(page);
}

async function roomId(request: import('@playwright/test').APIRequestContext, user: TestUser, room: string) {
  const r = rest(user);
  const rows = await (await request.get(`${r.url}/rooms?select=id&name=eq.${encodeURIComponent(room)}`, { headers: r.headers })).json();
  return rows[0].id as string;
}


const created: TestUser[] = [];
const track = async (p: Promise<TestUser>) => {
  const u = await p;
  created.push(u);
  return u;
};
test.afterEach(async ({ request }) => cancelAllBookings(request, created));

test('จองห้องผ่านฟอร์ม → สำเร็จ กลับหน้าแรก และเห็นเป็น "ของคุณ"', async ({ page, request }) => {
  const user = await track(signUp(request, 'book-ok'));
  const { start, end } = await freeTomorrowSlot(request, user, await roomId(request, user, ROOM_OK), 45);
  await loginAs(page, user);
  await openBookForm(page, ROOM_OK);
  await fillAndSubmit(page, start, end, 'ประชุมจาก e2e');

  await expect(page.getByText('จองสำเร็จ').first()).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole('heading', { name: 'จองห้อง', exact: true })).toHaveCount(0);
  await scrollUntilVisible(page, textOrLabel(page, `ของคุณ ${bkkTime(start)}–${bkkTime(end)}`));

  // ยืนยันจาก DB ด้วยสิทธิ์ของผู้ใช้เอง
  const r = rest(user);
  const mine = await (await request.get(`${r.url}/bookings?select=title,starts_at,status`, { headers: r.headers })).json();
  expect(mine).toEqual([{ title: 'ประชุมจาก e2e', starts_at: expect.any(String), status: 'confirmed' }]);
  expect(new Date(mine[0].starts_at).getTime()).toBe(start.getTime());
});

test('จองทับเวลาที่คนอื่นจองแล้ว → DB ปฏิเสธ และแอปแจ้งเป็นภาษาไทย', async ({ page, request }) => {
  const other = await track(signUp(request, 'book-other'));
  const user = await track(signUp(request, 'book-clash'));
  const { start, end } = await bookTomorrowFreeSlot(request, other, await roomId(request, other, ROOM_CLASH), 60, 'ของคนอื่น');

  await loginAs(page, user);
  await openBookForm(page, ROOM_CLASH);
  // ฟอร์มแสดงช่วงไม่ว่างของคนอื่น (ไม่บอกว่าเป็นใคร)
  await expect(textOrLabel(page, `ไม่ว่าง ${bkkTime(start)}–${bkkTime(end)}`).first()).toBeVisible();
  const overlapStart = new Date(start.getTime() + 15 * 60_000);
  await fillAndSubmit(page, overlapStart, new Date(overlapStart.getTime() + 60 * 60_000), 'ชน');
  await expect(page.getByText('ช่วงเวลานี้มีคนจองแล้ว ลองเวลาอื่นหรือห้องอื่น').first()).toBeVisible({ timeout: 15_000 });
  await expect(page.getByText('ของคนอื่น')).toHaveCount(0);
});

test('กรอกไม่ครบ/ผิดรูปแบบ → แจ้งที่ช่องทันที ไม่ส่งไป DB', async ({ page, request }) => {
  const user = await track(signUp(request, 'book-invalid'));
  await loginAs(page, user);
  await openBookForm(page, ROOM_OK);
  await flutterFill(page, /เวลาเริ่ม/, '09:10');
  await submit(page);
  await expect(page.getByText('เวลาต้องลงท้าย :00 :15 :30 หรือ :45')).toBeVisible();

  await flutterFill(page, /เวลาเริ่ม/, '09:00');
  await flutterFill(page, /เวลาจบ/, '14:00');
  await submit(page);
  await expect(page.getByText('จองได้ไม่เกิน 4 ชั่วโมงต่อครั้ง')).toBeVisible();

  const r = rest(user);
  expect(await (await request.get(`${r.url}/bookings?select=id`, { headers: r.headers })).json()).toEqual([]);
});
