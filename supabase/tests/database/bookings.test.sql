-- ROOM-4 · pgTAP: ห้อง + การจอง (กันจองซ้อน, กติกาเวลา, RLS, ช่วงไม่ว่างแบบไม่เปิดเผยผู้จอง)
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

-- ── ข้อมูลสังเคราะห์ ──
insert into auth.users (id, instance_id, aud, role, email) values
  ('aaaaaaaa-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'alice@example.test'),
  ('aaaaaaaa-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bob@example.test');
insert into public.rooms (id, name, capacity, is_active) values
  ('bbbbbbbb-0000-4000-8000-000000000001', 'tap ห้อง 1', 6, true),
  ('bbbbbbbb-0000-4000-8000-000000000002', 'tap ห้องปิด', 6, false);

-- t0 = พรุ่งนี้ 10:00 (ตรงชั่วโมง → ลงตัว 15 นาที)
create temp table t as select date_trunc('hour', now()) + interval '1 day' as t0;
grant select on t to authenticated, anon;

select ok((select relrowsecurity from pg_class where oid = 'public.rooms'::regclass), 'rooms เปิด RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.bookings'::regclass), 'bookings เปิด RLS');

-- ── alice ──
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}', true);

select ok(
  exists (select 1 from public.rooms where id = 'bbbbbbbb-0000-4000-8000-000000000001')
  and not exists (select 1 from public.rooms where id = 'bbbbbbbb-0000-4000-8000-000000000002'),
  'เห็นเฉพาะห้องที่เปิดใช้งาน'
);

select lives_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'ประชุมทีม', t0, t0 + interval '1 hour' from t$$,
  'alice จองห้องได้'
);
select is(
  (select user_id from public.bookings where title = 'ประชุมทีม'),
  'aaaaaaaa-0000-4000-8000-000000000001'::uuid,
  'user_id ถูกตั้งเป็นผู้ล็อกอินอัตโนมัติ'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'ซ้อน', t0 + interval '30 minutes', t0 + interval '90 minutes' from t$$,
  '23P01', null, 'จองเวลาซ้อนในห้องเดียวกันไม่ได้'
);
select lives_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'ต่อกันพอดี', t0 + interval '1 hour', t0 + interval '2 hours' from t$$,
  'จองต่อท้ายพอดี (ไม่ซ้อน) ได้'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'อดีต', date_trunc('hour', now()) - interval '1 hour', date_trunc('hour', now()) from t$$,
  '23514', 'booking_in_past', 'จองย้อนหลังไม่ได้'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'ไกล', t0 + interval '31 days', t0 + interval '31 days 1 hour' from t$$,
  '23514', 'booking_too_far', 'จองล่วงหน้าเกิน 30 วันไม่ได้'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'ยาว', t0 + interval '3 hours', t0 + interval '7 hours 15 minutes' from t$$,
  '23514', null, 'จองยาวเกิน 4 ชั่วโมงไม่ได้'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'ไม่ลงตัว', t0 + interval '3 hours 10 minutes', t0 + interval '4 hours' from t$$,
  '23514', null, 'เวลาต้องลงตัวทีละ 15 นาที'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'กลับด้าน', t0 + interval '4 hours', t0 + interval '3 hours' from t$$,
  '23514', null, 'เวลาจบต้องหลังเวลาเริ่ม'
);
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000002', 'ห้องปิด', t0, t0 + interval '1 hour' from t$$,
  '42501', null, 'จองห้องที่ปิดใช้งานไม่ได้'
);
select throws_ok(
  $$insert into public.bookings (room_id, user_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000002', 'แทน bob', t0 + interval '5 hours', t0 + interval '6 hours' from t$$,
  '42501', null, 'จองในนามคนอื่นไม่ได้'
);

-- ── bob ──
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-4000-8000-000000000002","role":"authenticated"}', true);

select is_empty($$select 1 from public.bookings$$, 'bob ไม่เห็นรายละเอียดการจองของ alice');
select results_eq(
  $$select count(*)::int, bool_or(is_mine), bool_and(booking_id is null)
      from public.room_busy_slots((select t0 from t), (select t0 + interval '1 day' from t))$$,
  $$values (2, false, true)$$,
  'bob เห็นช่วงไม่ว่าง 2 ช่วง แต่ไม่เห็นว่าเป็นของใคร'
);
update public.bookings set status = 'cancelled' where title = 'ประชุมทีม';
select throws_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'bob ซ้อน', t0, t0 + interval '1 hour' from t$$,
  '23P01', null, 'bob จองทับช่วงของ alice ไม่ได้ และยกเลิกของ alice ไม่ได้'
);
select throws_ok(
  $$select * from public.room_busy_slots((select t0 from t), (select t0 + interval '40 days' from t))$$,
  '23514', 'invalid_range', 'ค้นหาช่วงเกิน 31 วันไม่ได้'
);

-- ── alice ยกเลิก ──
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}', true);
update public.bookings set status = 'cancelled' where title = 'ประชุมทีม';
select ok(
  (select status = 'cancelled' and cancelled_at is not null from public.bookings where title = 'ประชุมทีม'),
  'alice ยกเลิกการจองของตัวเองได้ และบันทึกเวลายกเลิก'
);
select throws_ok(
  $$update public.bookings set status = 'confirmed' where title = 'ประชุมทีม'$$,
  '23514', 'booking_already_cancelled', 'ยกเลิกแล้วกลับมายืนยันไม่ได้'
);
select throws_ok(
  $$update public.bookings set starts_at = starts_at + interval '1 day' where title = 'ต่อกันพอดี'$$,
  '42501', null, 'แก้เวลาการจองตรงๆ ไม่ได้ (ยกเลิกแล้วจองใหม่)'
);
select throws_ok(
  $$delete from public.bookings where title = 'ต่อกันพอดี'$$,
  '42501', null, 'ลบการจองไม่ได้ (เก็บประวัติ)'
);

-- ── bob จองช่วงที่ถูกยกเลิกแล้ว ──
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-4000-8000-000000000002","role":"authenticated"}', true);
select lives_ok(
  $$insert into public.bookings (room_id, title, starts_at, ends_at)
    select 'bbbbbbbb-0000-4000-8000-000000000001', 'bob ประชุม', t0, t0 + interval '1 hour' from t$$,
  'หลังยกเลิก ช่วงเวลานั้นจองใหม่ได้'
);

-- ── anon ──
reset role;
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select throws_ok('select * from public.bookings', '42501', null, 'anon อ่านการจองไม่ได้');

select * from finish();
rollback;
