import { expect, test } from '@playwright/test';
import { rest, signUp, TestUser } from '../../lib/supabase';

// ทดสอบ RLS ของ profiles ผ่าน REST จริง (PostgREST) ด้วยสิทธิ์เดียวกับแอป
test.describe('profiles RLS', () => {
  let alice: TestUser;
  let bob: TestUser;

  test.beforeAll(async ({ request }) => {
    alice = await signUp(request, 'alice');
    bob = await signUp(request, 'bob');
  });

  test('ผู้ใช้อ่านได้แค่ profile ของตัวเอง', async ({ request }) => {
    const r = rest(alice);
    const res = await request.get(`${r.url}/profiles?select=id,display_name`, { headers: r.headers });
    expect(res.status()).toBe(200);
    const rows = await res.json();
    expect(rows).toEqual([{ id: alice.id, display_name: 'ผู้ทดสอบ alice' }]);
  });

  test('ระบุ id ของคนอื่นตรงๆ ก็ไม่เห็น', async ({ request }) => {
    const r = rest(alice);
    const res = await request.get(`${r.url}/profiles?id=eq.${bob.id}`, { headers: r.headers });
    expect(res.status()).toBe(200);
    expect(await res.json()).toEqual([]);
  });

  test('แก้ profile ของคนอื่นไม่ได้ แต่แก้ของตัวเองได้', async ({ request }) => {
    const r = rest(alice);
    const headers = { ...r.headers, Prefer: 'return=representation' };

    const other = await request.patch(`${r.url}/profiles?id=eq.${bob.id}`, {
      headers,
      data: { display_name: 'hacked' },
    });
    expect(other.status()).toBe(200);
    expect(await other.json()).toEqual([]);

    const own = await request.patch(`${r.url}/profiles?id=eq.${alice.id}`, {
      headers,
      data: { display_name: 'Alice (แก้แล้ว)' },
    });
    expect(own.status()).toBe(200);
    expect((await own.json())[0].display_name).toBe('Alice (แก้แล้ว)');

    const b = rest(bob);
    const check = await request.get(`${b.url}/profiles?select=display_name`, { headers: b.headers });
    expect(await check.json()).toEqual([{ display_name: 'ผู้ทดสอบ bob' }]);
  });

  test('สร้าง profile เองไม่ได้', async ({ request }) => {
    const r = rest(alice);
    const res = await request.post(`${r.url}/profiles`, {
      headers: r.headers,
      data: { id: crypto.randomUUID() },
    });
    expect([401, 403]).toContain(res.status());
  });

  test('ไม่ล็อกอิน (anon) อ่านไม่ได้', async ({ request }) => {
    const r = rest();
    const res = await request.get(`${r.url}/profiles`, { headers: r.headers });
    expect([401, 403]).toContain(res.status());
  });
});
