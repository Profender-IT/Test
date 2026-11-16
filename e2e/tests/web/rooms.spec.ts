import { expect, test } from '@playwright/test';
import { rest, signUp } from '../../lib/supabase';
import { bkkTime, loginAs, scrollUntilVisible, tomorrowBkk } from '../../lib/web';

test('หน้าแรกแสดงห้องทั้งหมด สถานะ และสรุปห้องว่าง', async ({ page, request }) => {
  const user = await signUp(request, 'rooms');
  await loginAs(page, user);

  await expect(page.getByText(/ว่างตอนนี้ \d+ จาก \d+ ห้อง/)).toBeVisible();
  // ทุกห้องที่เปิดใช้งานต้องเจอเมื่อเลื่อนลง (ข้อความในการ์ดรวมเป็นโหนดเดียว จึงหาแบบ substring)
  for (const name of ['ห้องประชุมใหญ่', 'ห้องประชุม A', 'ห้องประชุม B', 'ห้องประชุม C']) {
    await scrollUntilVisible(page, page.getByText(`${name} ${name}`));
  }
  await scrollUntilVisible(page, page.getByText('ไม่มีจองซ้อน'));
  await expect(page.getByText('ห้องปิดปรับปรุง')).toHaveCount(0);
});

test('การจองของตัวเองแสดงเป็น "ของคุณ" เมื่อเลือกวันนั้น', async ({ page, request }) => {
  const user = await signUp(request, 'rooms-mine');
  const r = rest(user);
  const rooms = await (await request.get(`${r.url}/rooms?select=id,name&name=eq.ห้องประชุม C`, { headers: r.headers })).json();
  const start = tomorrowBkk(6 + Math.floor(Math.random() * 14), [0, 15, 30, 45][Math.floor(Math.random() * 4)]);
  const end = new Date(start.getTime() + 30 * 60_000);
  const res = await request.post(`${r.url}/bookings`, {
    headers: r.headers,
    data: { room_id: rooms[0].id, title: 'web e2e', starts_at: start.toISOString(), ends_at: end.toISOString() },
  });
  expect(res.status(), await res.text()).toBe(201);

  await loginAs(page, user);
  await page.getByRole('checkbox', { name: 'พรุ่งนี้' }).click();
  await expect(page.getByRole('checkbox', { name: 'พรุ่งนี้' })).toBeChecked();
  await scrollUntilVisible(page, page.getByText(`ของคุณ ${bkkTime(start)}–${bkkTime(end)}`));
});
