-- ROOM-4 · ห้องประชุม + การจอง
-- กติกาที่ต้องเชื่อถือได้อยู่ใน DB (ADR 0001): กันจองซ้อนด้วย exclusion constraint, ช่วงเวลา/ความยาว/ล่วงหน้า, สิทธิ์ด้วย RLS
-- ความเป็นส่วนตัว (PDPA): ผู้ใช้เห็นรายละเอียดเฉพาะการจองของตัวเอง · ของคนอื่นเห็นแค่ช่วงไม่ว่างผ่าน room_busy_slots()

create extension if not exists btree_gist with schema extensions;

-- ───────────── rooms ─────────────
create table public.rooms (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique check (char_length(name) between 1 and 100),
  capacity   integer not null check (capacity between 1 and 500),
  floor      text check (char_length(floor) <= 50),
  equipment  text[] not null default '{}',
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.rooms is 'ห้องประชุม · จัดการโดยผู้ดูแลผ่าน Studio (ยังไม่มีหน้าแอดมินในแอป)';

alter table public.rooms enable row level security;

revoke all on table public.rooms from anon, authenticated;
grant select on table public.rooms to authenticated;

create policy rooms_select_active on public.rooms
  for select to authenticated
  using (is_active);

-- ───────────── bookings ─────────────
create type public.booking_status as enum ('confirmed', 'cancelled');

create table public.bookings (
  id           uuid primary key default gen_random_uuid(),
  room_id      uuid not null references public.rooms (id) on delete restrict,
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title        text not null check (char_length(btrim(title)) between 1 and 200),
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
  status       public.booking_status not null default 'confirmed',
  cancelled_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint bookings_time_order check (ends_at > starts_at),
  constraint bookings_quarter_hour check (
    extract(epoch from starts_at)::bigint % 900 = 0
    and extract(epoch from ends_at)::bigint % 900 = 0
  ),
  constraint bookings_duration check (ends_at - starts_at between interval '15 minutes' and interval '4 hours'),
  -- ห้องเดียวกันห้ามมีการจองที่ยืนยันแล้วซ้อนกัน · ยกเลิกแล้วไม่นับ
  constraint bookings_no_overlap exclude using gist (
    room_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status = 'confirmed')
);

comment on table  public.bookings is 'การจองห้อง · รายละเอียดเห็นได้เฉพาะเจ้าของ (RLS)';
comment on column public.bookings.user_id is 'PDPA: ผู้จอง';
comment on column public.bookings.title   is 'PDPA: หัวข้อประชุม (อาจมีชื่อคน/ลูกค้า) · ไม่แสดงให้ผู้อื่น';

create index bookings_room_time_idx on public.bookings (room_id, starts_at) where status = 'confirmed';
create index bookings_user_time_idx on public.bookings (user_id, starts_at desc);

alter table public.bookings enable row level security;

revoke all on table public.bookings from anon, authenticated;
grant select on table public.bookings to authenticated;
grant insert (room_id, title, starts_at, ends_at) on table public.bookings to authenticated;
grant update (status) on table public.bookings to authenticated;
-- ไม่มี delete: ใช้การยกเลิก (status) เพื่อเก็บประวัติ

create policy bookings_select_own on public.bookings
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy bookings_insert_own on public.bookings
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.rooms r where r.id = room_id and r.is_active)
  );

create policy bookings_update_own on public.bookings
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- กติกาที่อิงเวลาปัจจุบัน (ใช้ CHECK ไม่ได้) + การเปลี่ยนสถานะ
create function public.bookings_enforce_rules() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.starts_at < now() then
      raise exception 'booking_in_past' using errcode = 'check_violation';
    end if;
    if new.starts_at > now() + interval '30 days' then
      raise exception 'booking_too_far' using errcode = 'check_violation';
    end if;
    new.status := 'confirmed';
    new.cancelled_at := null;
  elsif tg_op = 'UPDATE' then
    if old.status = 'cancelled' and new.status <> 'cancelled' then
      raise exception 'booking_already_cancelled' using errcode = 'check_violation';
    end if;
    if old.status = 'confirmed' and new.status = 'cancelled' then
      if old.ends_at <= now() then
        raise exception 'booking_already_ended' using errcode = 'check_violation';
      end if;
      new.cancelled_at := now();
    end if;
    new.updated_at := now();
  end if;
  return new;
end;
$$;

revoke execute on function public.bookings_enforce_rules() from public, anon, authenticated;

create trigger bookings_enforce_rules
  before insert or update on public.bookings
  for each row execute function public.bookings_enforce_rules();

-- ช่วงไม่ว่างของทุกห้อง (ไม่เปิดเผยผู้จอง/หัวข้อของคนอื่น) · จำกัดช่วงค้นหา ≤ 31 วัน
create function public.room_busy_slots(p_from timestamptz, p_to timestamptz)
returns table (booking_id uuid, room_id uuid, starts_at timestamptz, ends_at timestamptz, is_mine boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'not_authenticated' using errcode = 'insufficient_privilege';
  end if;
  if p_to <= p_from or p_to - p_from > interval '31 days' then
    raise exception 'invalid_range' using errcode = 'check_violation';
  end if;
  return query
    select case when b.user_id = (select auth.uid()) then b.id end,
           b.room_id, b.starts_at, b.ends_at,
           b.user_id = (select auth.uid())
      from public.bookings b
      join public.rooms r on r.id = b.room_id and r.is_active
     where b.status = 'confirmed'
       and b.starts_at < p_to
       and b.ends_at > p_from
     order by b.room_id, b.starts_at;
end;
$$;

revoke execute on function public.room_busy_slots(timestamptz, timestamptz) from public, anon;
grant execute on function public.room_busy_slots(timestamptz, timestamptz) to authenticated;
