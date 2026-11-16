import { APIRequestContext, expect, test } from '@playwright/test';
import { randomSlot } from '../../lib/slots';
import { cancelAllBookings, rest, signUp, TestUser } from '../../lib/supabase';

// การจองผ่าน REST จริง (PostgREST) ด้วยสิทธิ์เดียวกับแอป · ครอบกติกาใน migration rooms_bookings
async function rooms(request: APIRequestContext, user: TestUser) {
  const r = rest(user);
  const res = await request.get(`${r.url}/rooms?select=id,name,is_active&order=name`, { headers: r.headers });
  expect(res.status()).toBe(200);
  return (await res.json()) as { id: string; name: string; is_active: boolean }[];
}

async function book(request: APIRequestContext, user: TestUser, body: Record<string, unknown>) {
  const r = rest(user);
  return request.post(`${r.url}/bookings`, {
    headers: { ...r.headers, Prefer: 'return=representation' },
    data: body,
  });
}

async function busy(request: APIRequestContext, user: TestUser, from: Date, to: Date) {
  const r = rest(user);
  const res = await request.post(`${r.url}/rpc/room_busy_slots`, {
    headers: r.headers,
    data: { p_from: from.toISOString(), p_to: to.toISOString() },
  });
  expect(res.status()).toBe(200);
  return (await res.json()) as { booking_id: string | null; room_id: string; is_mine: boolean }[];
}


const created: TestUser[] = [];
const track = async (p: Promise<TestUser>) => {
  const u = await p;
  created.push(u);
  return u;
};
test.afterAll(async ({ request }) => cancelAllBookings(request, created)); // ผู้ใช้สร้างใน beforeAll ใช้ร่วมทุก test

test.describe('bookings', () => {
  let alice: TestUser;
  let bob: TestUser;
  let roomId: string;

  test.beforeAll(async ({ request }) => {
    alice = await track(signUp(request, 'b-alice'));
    bob = await track(signUp(request, 'b-bob'));
    const list = await rooms(request, alice);
    expect(list.length).toBeGreaterThanOrEqual(4);
    expect(list.every((r) => r.is_active)).toBe(true);
    roomId = list[Math.floor(Math.random() * list.length)].id;
  });

  test('จองได้ จองซ้อนไม่ได้ และคนอื่นเห็นแค่ช่วงไม่ว่าง', async ({ request }) => {
    const s = randomSlot(60);
    const ok = await book(request, alice, { room_id: roomId, title: 'ประชุม e2e', starts_at: s.starts_at, ends_at: s.ends_at });
    expect(ok.status()).toBe(201);
    const [created] = await ok.json();
    expect(created.user_id).toBe(alice.id);
    expect(created.status).toBe('confirmed');

    const overlap = randomSlot(60, new Date(s.start.getTime() + 30 * 60_000));
    const clash = await book(request, bob, { room_id: roomId, title: 'ชน', starts_at: overlap.starts_at, ends_at: overlap.ends_at });
    expect([400, 409]).toContain(clash.status());
    expect((await clash.json()).code).toBe('23P01');

    const r = rest(bob);
    const peek = await request.get(`${r.url}/bookings?id=eq.${created.id}`, { headers: r.headers });
    expect(await peek.json()).toEqual([]);

    const slotsForBob = (await busy(request, bob, s.start, s.end)).filter((x) => x.room_id === roomId);
    expect(slotsForBob).toEqual([expect.objectContaining({ booking_id: null, is_mine: false })]);
    const slotsForAlice = (await busy(request, alice, s.start, s.end)).filter((x) => x.room_id === roomId);
    expect(slotsForAlice).toEqual([expect.objectContaining({ booking_id: created.id, is_mine: true })]);
  });

  test('ยกเลิกของตัวเองได้ ของคนอื่นไม่ได้ และยกเลิกแล้วจองช่วงเดิมได้', async ({ request }) => {
    const s = randomSlot(30);
    const [mine] = await (await book(request, alice, { room_id: roomId, title: 'จะยกเลิก', starts_at: s.starts_at, ends_at: s.ends_at })).json();

    const rb = rest(bob);
    const hijack = await request.patch(`${rb.url}/bookings?id=eq.${mine.id}`, {
      headers: { ...rb.headers, Prefer: 'return=representation' },
      data: { status: 'cancelled' },
    });
    expect(await hijack.json()).toEqual([]);

    const ra = rest(alice);
    const cancel = await request.patch(`${ra.url}/bookings?id=eq.${mine.id}`, {
      headers: { ...ra.headers, Prefer: 'return=representation' },
      data: { status: 'cancelled' },
    });
    expect(cancel.status()).toBe(200);
    const [cancelled] = await cancel.json();
    expect(cancelled.status).toBe('cancelled');
    expect(cancelled.cancelled_at).toBeTruthy();

    const rebook = await book(request, bob, { room_id: roomId, title: 'bob ได้ห้อง', starts_at: s.starts_at, ends_at: s.ends_at });
    expect(rebook.status()).toBe(201);
  });

  test('กติกาเวลา: ย้อนหลัง, เกิน 30 วัน, เกิน 4 ชม., ไม่ลงตัว 15 นาที', async ({ request }) => {
    const past = new Date();
    past.setUTCHours(past.getUTCHours() - 2, 0, 0, 0);
    const far = new Date();
    far.setUTCDate(far.getUTCDate() + 35);
    far.setUTCHours(3, 0, 0, 0);
    const s = randomSlot(60);
    const cases: [string, string, string][] = [
      ['ย้อนหลัง', randomSlot(60, past).starts_at, randomSlot(60, past).ends_at],
      ['ไกล', randomSlot(60, far).starts_at, randomSlot(60, far).ends_at],
      ['ยาว', s.starts_at, new Date(s.start.getTime() + 5 * 3600_000).toISOString()],
      ['ไม่ลงตัว', new Date(s.start.getTime() + 10 * 60_000).toISOString(), s.ends_at],
    ];
    for (const [title, starts_at, ends_at] of cases) {
      const res = await book(request, alice, { room_id: roomId, title, starts_at, ends_at });
      expect(res.status(), title).toBe(400);
      expect((await res.json()).code, title).toBe('23514');
    }
  });

  test('จองในนามคนอื่นไม่ได้', async ({ request }) => {
    const s = randomSlot(30);
    const res = await book(request, alice, { room_id: roomId, user_id: bob.id, title: 'แทน', starts_at: s.starts_at, ends_at: s.ends_at });
    expect([401, 403]).toContain(res.status());
  });

  test('ไม่ล็อกอิน (anon) ดูห้อง/การจอง/ช่วงไม่ว่างไม่ได้', async ({ request }) => {
    const r = rest();
    for (const path of ['rooms', 'bookings']) {
      const res = await request.get(`${r.url}/${path}`, { headers: r.headers });
      expect([401, 403], path).toContain(res.status());
    }
    const s = randomSlot(60);
    const rpc = await request.post(`${r.url}/rpc/room_busy_slots`, {
      headers: r.headers,
      data: { p_from: s.starts_at, p_to: s.ends_at },
    });
    expect([401, 403, 404]).toContain(rpc.status());
  });
});
