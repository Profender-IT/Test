-- ROOM-1 · pgTAP: ผู้ใช้อ่าน/แก้ profile ได้แค่ของตัวเอง · รัน: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

-- ผู้ใช้สังเคราะห์ 2 คน (trigger สร้าง profile ให้)
insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-4111-8111-111111111111', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'alice@example.test', '{"display_name":"Alice"}'),
  ('22222222-2222-4222-8222-222222222222', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'bob@example.test', '{"display_name":"Bob"}');

select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'profiles เปิด RLS'
);
select is(
  (select count(*)::int from public.profiles
    where id in ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222')),
  2,
  'trigger สร้าง profile ให้ผู้ใช้ใหม่'
);

-- ── ในฐานะ alice ──
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);

select results_eq(
  'select id from public.profiles',
  $$values ('11111111-1111-4111-8111-111111111111'::uuid)$$,
  'alice เห็นเฉพาะ profile ของตัวเอง'
);
select is_empty(
  $$select 1 from public.profiles where id = '22222222-2222-4222-8222-222222222222'$$,
  'alice อ่าน profile ของ bob ไม่ได้'
);

update public.profiles set display_name = 'hacked'
  where id = '22222222-2222-4222-8222-222222222222';
update public.profiles set display_name = 'Alice A.'
  where id = '11111111-1111-4111-8111-111111111111';
select is(
  (select display_name from public.profiles where id = '11111111-1111-4111-8111-111111111111'),
  'Alice A.',
  'alice แก้ชื่อของตัวเองได้'
);

select throws_ok(
  $$insert into public.profiles (id) values ('33333333-3333-4333-8333-333333333333')$$,
  '42501', null,
  'แอปสร้าง profile เองไม่ได้ (มาจาก trigger เท่านั้น)'
);
select throws_ok(
  $$update public.profiles set id = '22222222-2222-4222-8222-222222222222'
      where id = '11111111-1111-4111-8111-111111111111'$$,
  '42501', null,
  'แก้คอลัมน์ id ไม่ได้'
);
select throws_ok(
  $$delete from public.profiles where id = '11111111-1111-4111-8111-111111111111'$$,
  '42501', null,
  'ลบ profile จากแอปไม่ได้'
);

-- ── ในฐานะ anon ──
reset role;
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select throws_ok('select * from public.profiles', '42501', null, 'anon อ่าน profiles ไม่ได้');

-- ── ตรวจผลด้วยสิทธิ์ผู้ดูแล ──
reset role;
select is(
  (select display_name from public.profiles where id = '22222222-2222-4222-8222-222222222222'),
  'Bob',
  'profile ของ bob ไม่ถูกแก้โดย alice'
);

select * from finish();
rollback;
