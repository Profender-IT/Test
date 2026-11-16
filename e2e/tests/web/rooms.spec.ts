import { expect, test } from '@playwright/test';
import { cancelAllBookings, rest, signUp, TestUser } from '../../lib/supabase';
import { bkkTime, bookTomorrowFreeSlot, loginAs, scrollUntilVisible, textOrLabel } from '../../lib/web';


const created: TestUser[] = [];
const track = async (p: Promise<TestUser>) => {
  const u = await p;
  created.push(u);
  return u;
};
test.afterEach(async ({ request }) => cancelAllBookings(request, created));

test('หน้าแรกแสดงห้องทั้งหมด สถานะ และสรุปห้องว่าง', async ({ page, request }) => {
  const user = await track(signUp(request, 'rooms'));
  await loginAs(page, user);

  await expect(page.getByText(/ว่างตอนนี้ \d+ จาก \d+ ห้อง/)).toBeVisible();
  // ทุกห้องที่เปิดใช้งานมีการ์ด + ปุ่มจองของตัวเอง (หาเมื่อเลื่อนลง เพราะ Flutter วาดเฉพาะส่วนที่เห็น)
  for (const name of ['ห้องประชุมใหญ่', 'ห้องประชุม A', 'ห้องประชุม B', 'ห้องประชุม C']) {
    await scrollUntilVisible(page, page.getByRole('button', { name: `จอง${name} · วันนี้` }));
  }
  await scrollUntilVisible(page, page.getByText('ไม่มีจองซ้อน'));
  await expect(page.getByText('ห้องปิดปรับปรุง')).toHaveCount(0);
});

test('การจองของตัวเองแสดงเป็น "ของคุณ" เมื่อเลือกวันนั้น', async ({ page, request }) => {
  const user = await track(signUp(request, 'rooms-mine'));
  const r = rest(user);
  const rooms = await (await request.get(`${r.url}/rooms?select=id,name&name=eq.ห้องประชุม A`, { headers: r.headers })).json();
  const { start, end } = await bookTomorrowFreeSlot(request, user, rooms[0].id, 30, 'web e2e');

  await loginAs(page, user);
  await page.getByRole('checkbox', { name: 'พรุ่งนี้' }).click();
  await expect(page.getByRole('checkbox', { name: 'พรุ่งนี้' })).toBeChecked();
  await scrollUntilVisible(page, textOrLabel(page, `ของคุณ ${bkkTime(start)}–${bkkTime(end)}`));
});
