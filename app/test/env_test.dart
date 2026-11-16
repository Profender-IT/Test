import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/config/env.dart';

String _jwt(Map<String, Object> payload) {
  String seg(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(payload)}.signature';
}

void main() {
  group('validateConfig', () {
    test('ว่างทั้งคู่ = แจ้ง 2 ข้อ', () {
      expect(validateConfig(url: '', key: ''), hasLength(2));
    });

    test('URL + anon JWT ถูกต้อง = ผ่าน', () {
      expect(
        validateConfig(
          url: 'http://127.0.0.1:54321',
          key: _jwt({'role': 'anon'}),
        ),
        isEmpty,
      );
    });

    test('publishable key ผ่าน', () {
      expect(
        validateConfig(url: 'https://x.supabase.co', key: 'sb_publishable_abc'),
        isEmpty,
      );
    });

    test('URL ผิดรูปแบบ', () {
      expect(
        validateConfig(url: 'not a url', key: 'sb_publishable_abc'),
        hasLength(1),
      );
    });
  });

  group('isPrivilegedKey (ห้าม service_role ในแอป)', () {
    test('service_role JWT ถูกปฏิเสธ', () {
      final key = _jwt({'role': 'service_role'});
      expect(isPrivilegedKey(key), isTrue);
      expect(
        validateConfig(url: 'https://x.supabase.co', key: key),
        hasLength(1),
      );
    });

    test('sb_secret_ ถูกปฏิเสธ', () {
      expect(isPrivilegedKey('sb_secret_abc'), isTrue);
    });

    test('anon JWT / ข้อความที่ไม่ใช่ JWT ไม่ถือว่าเป็นกุญแจสิทธิ์สูง', () {
      expect(isPrivilegedKey(_jwt({'role': 'anon'})), isFalse);
      expect(isPrivilegedKey('a.b.c'), isFalse);
    });
  });
}
