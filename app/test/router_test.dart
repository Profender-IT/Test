import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/router.dart';

void main() {
  test('ยังไม่ล็อกอิน → ไป /login', () {
    expect(authRedirect(loggedIn: false, location: Routes.home), Routes.login);
    expect(authRedirect(loggedIn: false, location: Routes.login), isNull);
  });

  test('ล็อกอินแล้ว → ออกจาก /login ไปหน้าหลัก', () {
    expect(authRedirect(loggedIn: true, location: Routes.login), Routes.home);
    expect(authRedirect(loggedIn: true, location: Routes.home), isNull);
  });
}
