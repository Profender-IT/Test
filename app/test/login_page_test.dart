import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/features/auth/login_page.dart';
import 'package:room_booking/src/l10n/strings.dart';
import 'package:room_booking/src/supabase/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('ฟอร์มว่าง → แสดงข้อความให้กรอก และไม่เรียก auth', (
    tester,
  ) async {
    // client ปลอมที่ชี้ไป host ที่ไม่มีอยู่ · ถ้า validation ไม่กันไว้ test จะเห็น error จากเครือข่าย
    final client = SupabaseClient(
      'http://127.0.0.1:9',
      'sb_publishable_test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, S.login));
    await tester.pump();

    expect(find.text(S.emailRequired), findsOneWidget);
    expect(find.text(S.passwordRequired), findsOneWidget);
    expect(find.text(S.loginFailed), findsNothing);
  });
}
