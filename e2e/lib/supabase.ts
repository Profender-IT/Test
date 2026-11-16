import { APIRequestContext, expect } from '@playwright/test';

/** env ที่ต้องมี: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY (local: ได้จาก `supabase status -o env`) */
export function supabaseEnv() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) throw new Error('ต้องตั้ง SUPABASE_URL และ SUPABASE_PUBLISHABLE_KEY (ดู e2e/README.md)');
  return { url: url.replace(/\/$/, ''), key };
}

export type TestUser = { id: string; email: string; password: string; accessToken: string };

/** สมัครผู้ใช้สังเคราะห์ผ่าน Auth API ด้วย publishable key (ไม่ใช้ service_role) · local ปิด email confirmation */
export async function signUp(request: APIRequestContext, label: string): Promise<TestUser> {
  const { url, key } = supabaseEnv();
  const email = `e2e-${label}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@example.com`;
  const password = `pw-${Math.random().toString(36).slice(2)}-A1!`;
  const res = await request.post(`${url}/auth/v1/signup`, {
    headers: { apikey: key },
    data: { email, password, data: { display_name: `ผู้ทดสอบ ${label}` } },
  });
  expect(res.ok(), `signup ${label}: ${res.status()}`).toBeTruthy();
  const body = await res.json();
  expect(body.access_token, 'local Supabase ต้องปิด enable_confirmations').toBeTruthy();
  return { id: body.user.id, email, password, accessToken: body.access_token };
}

export function rest(user?: TestUser) {
  const { url, key } = supabaseEnv();
  return {
    url: `${url}/rest/v1`,
    headers: {
      apikey: key,
      ...(user ? { Authorization: `Bearer ${user.accessToken}` } : {}),
    },
  };
}
