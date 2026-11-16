import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/features/booking/book_page.dart';
import 'package:room_booking/src/features/booking/bookings_repository.dart';
import 'package:room_booking/src/features/rooms/availability.dart';
import 'package:room_booking/src/features/rooms/rooms.dart';
import 'package:room_booking/src/l10n/strings.dart';
import 'package:room_booking/src/theme/app_theme.dart';

class FakeRepo implements BookingsRepository {
  final created = <Map<String, Object>>[];
  BookingFailure? failWith;

  @override
  Future<void> create({
    required String roomId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    if (failWith != null) throw BookingException(failWith!);
    created.add({'room': roomId, 'title': title, 'start': start, 'end': end});
  }

  @override
  Future<void> cancel(String id) async {}

  @override
  Future<List<MyBooking>> mine() async => const [];
}

final now = DateTime(2026, 11, 16, 10, 20);
const room = Room(id: 'a', name: 'ห้อง A', capacity: 6, floor: 'ชั้น 2');

Future<(FakeRepo, List<bool>)> pump(
  WidgetTester tester, {
  List<BusySlot> busy = const [],
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeRepo();
  final done = <bool>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        roomsProvider.overrideWith((ref) async => [room]),
        busySlotsProvider.overrideWith((ref, day) async => busy),
        bookingsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: BookPage(
          roomId: 'a',
          initialDay: DateTime(2026, 11, 17),
          onDone: () => done.add(true),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (repo, done);
}

Finder field(String label) => find.widgetWithText(TextField, label);

void main() {
  testWidgets('ค่าเริ่มต้น: พรุ่งนี้ 09:00–10:00 และแสดงข้อมูลห้อง', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('ห้อง A'), findsOneWidget);
    expect(find.text('6 คน · ชั้น 2'), findsOneWidget);
    expect(find.text('อ. 17 พ.ย. 2569'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text(S.freeAllDay), findsOneWidget);
  });

  testWidgets('ไม่กรอกหัวข้อ → แจ้งที่ช่อง และไม่ส่งไป DB', (tester) async {
    final (repo, _) = await pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, S.confirmBooking));
    await tester.pumpAndSettle();
    expect(find.text(S.errTitle), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('เวลาไม่ลงตัว 15 นาที → แจ้งที่ช่องเวลาเริ่ม', (tester) async {
    final (repo, _) = await pump(tester);
    await tester.enterText(field(S.startTime), '09:10');
    await tester.enterText(field(S.meetingTitle), 'ทดสอบ');
    await tester.tap(find.widgetWithText(FilledButton, S.confirmBooking));
    await tester.pumpAndSettle();
    expect(find.text(S.errNotQuarter), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('จองสำเร็จ → ส่งเวลาตามวันที่เลือก แจ้งสำเร็จ และกลับหน้าเดิม', (
    tester,
  ) async {
    final (repo, done) = await pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'พ. 18 พ.ย.'));
    await tester.enterText(field(S.startTime), '13:30');
    await tester.enterText(field(S.endTime), '15:00');
    await tester.enterText(field(S.meetingTitle), '  วางแผนไตรมาส  ');
    await tester.tap(find.widgetWithText(FilledButton, S.confirmBooking));
    await tester.pumpAndSettle();

    expect(repo.created, [
      {
        'room': 'a',
        'title': '  วางแผนไตรมาส  ',
        'start': DateTime(2026, 11, 18, 13, 30),
        'end': DateTime(2026, 11, 18, 15),
      },
    ]);
    expect(find.text(S.booked), findsOneWidget);
    expect(done, [true]);
  });

  testWidgets('DB ปฏิเสธเพราะจองซ้อน → แสดงข้อความ ไม่ปิดหน้า', (tester) async {
    final (repo, done) = await pump(tester);
    repo.failWith = BookingFailure.overlap;
    await tester.enterText(field(S.meetingTitle), 'ชน');
    await tester.tap(find.widgetWithText(FilledButton, S.confirmBooking));
    await tester.pumpAndSettle();
    expect(find.text(S.errOverlap), findsOneWidget);
    expect(done, isEmpty);
  });

  testWidgets('แสดงช่วงไม่ว่างของห้องในวันนั้น', (tester) async {
    await pump(
      tester,
      busy: [
        BusySlot(
          roomId: 'a',
          start: DateTime(2026, 11, 17, 9),
          end: DateTime(2026, 11, 17, 10),
          isMine: false,
        ),
        BusySlot(
          roomId: 'other',
          start: DateTime(2026, 11, 17, 11),
          end: DateTime(2026, 11, 17, 12),
          isMine: false,
        ),
      ],
    );
    expect(find.text('${S.busyLabel} 09:00–10:00'), findsOneWidget);
    expect(
      find.textContaining('11:00–12:00'),
      findsNothing,
      reason: 'ไม่แสดงของห้องอื่น',
    );
  });
}
