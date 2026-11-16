-- ROOM-1 · profiles: ข้อมูลผู้ใช้ 1:1 กับ auth.users · ผู้ใช้เห็น/แก้ได้เฉพาะแถวของตัวเอง (RLS)
-- แอปใช้ publishable/anon key + JWT ของผู้ใช้เท่านั้น · service_role ไม่อยู่ในแอป (ADR 0001)

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) <= 100),
  department   text check (char_length(department) <= 100),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table  public.profiles is 'โปรไฟล์ผู้ใช้ (1:1 กับ auth.users)';
comment on column public.profiles.display_name is 'PDPA: ชื่อที่แสดงของผู้ใช้';
comment on column public.profiles.department   is 'แผนก (ใช้กรอง/รายงานการจองห้อง)';

alter table public.profiles enable row level security;

-- Supabase ให้สิทธิ์ทุกอย่างกับ anon/authenticated เป็นค่าเริ่มต้น → เอาออกแล้วให้เฉพาะที่ใช้
revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (display_name, department) on table public.profiles to authenticated;
-- ไม่มี insert/delete จากแอป: แถวถูกสร้างโดย trigger ตอนสมัคร และลบตาม auth.users (cascade)

create policy profiles_select_own on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- updated_at อัตโนมัติ
create function public.set_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- สร้าง profile ให้ผู้ใช้ใหม่ทุกคน
create function public.handle_new_user() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, left(new.raw_user_meta_data ->> 'display_name', 100));
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
