import { defineConfig, devices } from '@playwright/test';

// ค่าทั้งหมดมาจาก env (CI ตั้งจาก `supabase status -o env`) · ห้าม hardcode URL/key ของ staging/production
const webPort = Number(process.env.E2E_WEB_PORT ?? 4173);
const runsWeb = !process.argv.includes('--project=api');

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'list',
  use: { trace: 'retain-on-failure', screenshot: 'only-on-failure' },
  projects: [
    { name: 'api', testDir: './tests/api' },
    {
      name: 'web',
      testDir: './tests/web',
      use: { ...devices['Pixel 7'], baseURL: `http://127.0.0.1:${webPort}` },
    },
  ],
  // Flutter web build (สร้างก่อนด้วย flutter build web ใน CI) เสิร์ฟแบบ static
  webServer: runsWeb
    ? {
        command: `npx http-server ../app/build/web -p ${webPort} -a 127.0.0.1 -s -c-1`,
        url: `http://127.0.0.1:${webPort}`,
        reuseExistingServer: !process.env.CI,
        timeout: 60_000,
      }
    : undefined,
});
