import { expect, test } from '@playwright/test';
import { cancelAllBookings, rest, signUp, TestUser } from '../../lib/supabase';
import { bkkTime, bookTomorrowFreeSlot, loginAs, scrollUntilVisible, textOrLabel } from '../../lib/web';

// ใช้ห้องประชุมใหญ่ (test อื่นใช้ A/B/C) กันชนเมื่อรันขนาน
const ROOM = 'ห้องประชุมใหญ่';

const created: TestUser[] = [];
const track = async (p: Promise<TestUser>) => {
  const u = await p;
  created.push(u);
  return u;
};
test.afterEach(async ({ request }) => cancelAllBookings(request, created));

test('การจองของฉัน → ยกเลิก → ห้องว่างให้คนอื่นจองช่วงเดิมได้', async ({ page, request }) => {
  const user = await track(signUp(request, 'mine'));
  const other = await track(signUp(request, 'mine-other'));
  const r = rest(user);
  const [room] = await (await request.get(`${r.url}/rooms?select=id&name=eq.${encodeURIComponent(ROOM)}`, { headers: r.headers })).json();
  const { start, end } = await bookTomorrowFreeSlot(request, user, room.id, 60, 'ประชุมที่จะยกเลิก');
  const range = `${bkkTime(start)}–${bkkTime(end)}`;

  await loginAs(page, user);
  await page.getByRole('tab', { name: 'การจองของฉัน' }).or(page.getByRole('button', { name: 'การจองของฉัน' })).first().click();
  await expect(textOrLabel(page, 'ประชุมที่จะยกเลิก').first()).toBeVisible();
  await expect(textOrLabel(page, 'ยืนยันแล้ว').first()).toBeVisible();

  const cancelBtn = page.getByRole('button', { name: `ยกเลิกการจอง ${ROOM} ${range}` });
  await scrollUntilVisible(page, cancelBtn);
  await cancelBtn.click();
  await page.getByRole('button', { name: 'ยืนยันยกเลิก' }).click();

  await expect(page.getByText('ยกเลิกการจองแล้ว').first()).toBeVisible();
  await expect(textOrLabel(page, 'ยกเลิกแล้ว').first()).toBeVisible();
  await expect(page.getByRole('button', { name: `ยกเลิกการจอง ${ROOM} ${range}` })).toHaveCount(0);

  // สถานะใน DB + ช่วงเดิมว่างจริง: อีกคนจองได้
  const [row] = await (await request.get(`${r.url}/bookings?select=status,cancelled_at`, { headers: r.headers })).json();
  expect(row.status).toBe('cancelled');
  expect(row.cancelled_at).toBeTruthy();
  const ro = rest(other);
  const rebook = await request.post(`${ro.url}/bookings`, {
    headers: ro.headers,
    data: { room_id: room.id, title: 'ได้ห้องต่อ', starts_at: start.toISOString(), ends_at: end.toISOString() },
  });
  expect(rebook.status(), await rebook.text()).toBe(201);
});

test('ยังไม่มีการจอง → ข้อความว่างและปุ่มกลับไปดูห้อง', async ({ page, request }) => {
  const user = await track(signUp(request, 'mine-empty'));
  await loginAs(page, user);
  await page.getByRole('tab', { name: 'การจองของฉัน' }).or(page.getByRole('button', { name: 'การจองของฉัน' })).first().click();
  await expect(textOrLabel(page, 'ยังไม่มีการจองที่กำลังจะถึง').first()).toBeVisible();
  await page.getByRole('button', { name: 'ดูห้องว่าง' }).click();
  await expect(page.getByText(/ว่างตอนนี้ \d+ จาก \d+ ห้อง/)).toBeVisible();
});
