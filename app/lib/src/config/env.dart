import 'dart:convert';

/// ค่า config ทั้งหมดมาจาก `--dart-define` เท่านั้น (ADR 0001)
/// ห้ามอ่านจากไฟล์ .env, asset หรือ hardcode ในโค้ด
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// local | staging | production (แสดงป้ายบนหน้าจอเมื่อไม่ใช่ production)
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  /// เปิด semantics tree บน Flutter web เพื่อให้ Playwright หา element ได้ (ใช้ใน CI เท่านั้น)
  static const e2eSemantics = bool.fromEnvironment('E2E_SEMANTICS');

  static List<String> get problems =>
      validateConfig(url: supabaseUrl, key: supabasePublishableKey);
}

/// ตรวจค่า config ก่อนเริ่มแอป · คืนรายการปัญหา (ว่าง = ใช้ได้)
List<String> validateConfig({required String url, required String key}) {
  final problems = <String>[];
  if (url.isEmpty) {
    problems.add('ไม่ได้ตั้ง --dart-define=SUPABASE_URL');
  } else {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.isScheme('https') || uri.isScheme('http')) ||
        uri.host.isEmpty) {
      problems.add('SUPABASE_URL ไม่ใช่ URL ที่ถูกต้อง');
    }
  }
  if (key.isEmpty) {
    problems.add('ไม่ได้ตั้ง --dart-define=SUPABASE_PUBLISHABLE_KEY');
  } else if (isPrivilegedKey(key)) {
    problems.add(
      'ห้ามใช้ service_role / secret key ในแอป ใช้ publishable (หรือ anon) key เท่านั้น',
    );
  }
  return problems;
}

/// true ถ้าเป็นกุญแจที่ข้าม RLS ได้ (service_role JWT หรือ sb_secret_…)
bool isPrivilegedKey(String key) {
  if (key.startsWith('sb_secret_')) return true;
  final parts = key.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return payload is Map && payload['role'] == 'service_role';
  } on FormatException {
    return false;
  }
}
