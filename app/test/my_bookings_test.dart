import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/features/booking/bookings_repository.dart';
import 'package:room_booking/src/features/my_bookings/my_bookings_page.dart';
import 'package:room_booking/src/features/rooms/rooms.dart';
import 'package:room_booking/src/l10n/strings.dart';
import 'package:room_booking/src/theme/app_theme.dart';

final now = DateTime(2026, 11, 16, 10, 30);

MyBooking b(
  String id,
  DateTime s,
  DateTime e, {
  bool cancelled = false,
  String room = 'ห้อง A',
}) => MyBooking(
  id: id,
  roomId: 'r',
  roomName: room,
  title: 'หัวข้อ $id',
  start: s,
  end: e,
  cancelled: cancelled,
);

final upcoming = b('up', DateTime(2026, 11, 17, 9), DateTime(2026, 11, 17, 10));
final soon = b('soon', DateTime(2026, 11, 16, 13), DateTime(2026, 11, 16, 14));
final inProgress = b(
  'now',
  DateTime(2026, 11, 16, 10),
  DateTime(2026, 11, 16, 11),
);
final ended = b('ended', DateTime(2026, 11, 15, 9), DateTime(2026, 11, 15, 10));
final cancelled = b(
  'cxl',
  DateTime(2026, 11, 18, 9),
  DateTime(2026, 11, 18, 10),
  cancelled: true,
);

class FakeRepo implements BookingsRepository {
  FakeRepo(this.items);
  List<MyBooking> items;
  final cancelledIds = <String>[];
  BookingFailure? failWith;

  @override
  Future<List<MyBooking>> mine() async => items;

  @override
  Future<void> cancel(String id) async {
    if (failWith != null) throw BookingException(failWith!);
    cancelledIds.add(id);
    items = [
      for (final x in items)
        x.id == id
            ? b(x.id, x.start, x.end, cancelled: true, room: x.roomName)
            : x,
    ];
  }

  @override
  Future<void> create({
    required String roomId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {}
}

Future<FakeRepo> pump(
  WidgetTester tester,
  List<MyBooking> items, {
  VoidCallback? onBrowse,
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeRepo(items);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        bookingsRepositoryProvider.overrideWithValue(repo),
        busySlotsProvider.overrideWith((ref, day) async => const []),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: MyBookingsPage(onBrowseRooms: onBrowse)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('stateOf ครบทุกสถานะ', () {
    expect(stateOf(upcoming, now), MyBookingState.upcoming);
    expect(stateOf(inProgress, now), MyBookingState.inProgress);
    expect(stateOf(ended, now), MyBookingState.ended);
    expect(stateOf(cancelled, now), MyBookingState.cancelled);
  });

  test('splitBookings: กำลังจะถึงเรียงใกล้สุดก่อน · ประวัติล่าสุดก่อน', () {
    final (active, history) = splitBookings([
      upcoming,
      ended,
      inProgress,
      cancelled,
      soon,
    ], now);
    expect(active.map((x) => x.id), ['now', 'soon', 'up']);
    expect(history.map((x) => x.id), ['cxl', 'ended']);
  });

  testWidgets('แสดงสถานะและปุ่มยกเลิกเฉพาะที่ยังไม่จบ', (tester) async {
    await pump(tester, [upcoming, inProgress, ended, cancelled]);
    expect(find.text(S.statusConfirmed), findsOneWidget);
    expect(find.text(S.statusNow), findsOneWidget);
    expect(find.text(S.statusEnded), findsOneWidget);
    expect(find.text(S.statusCancelled), findsOneWidget);
    expect(find.text(S.cancelBooking), findsNWidgets(2));
    expect(find.text('อ. 17 พ.ย. 2569 · 09:00–10:00'), findsOneWidget);
    expect(find.text('หัวข้อ up'), findsOneWidget);
  });

  testWidgets('ยกเลิก → ถามยืนยัน → ยกเลิกจริง ย้ายไปประวัติ และแจ้งผล', (
    tester,
  ) async {
    final repo = await pump(tester, [upcoming]);
    await tester.tap(find.text(S.cancelBooking));
    await tester.pumpAndSettle();
    expect(find.text(S.cancelConfirmTitle('ห้อง A')), findsOneWidget);

    await tester.tap(find.text(S.confirmCancel));
    await tester.pumpAndSettle();
    expect(repo.cancelledIds, ['up']);
    expect(find.text(S.cancelled), findsOneWidget);
    expect(find.text(S.statusCancelled), findsOneWidget);
    expect(find.text(S.cancelBooking), findsNothing);
    expect(find.text(S.noUpcoming), findsOneWidget);
  });

  testWidgets('กด "เก็บไว้" → ไม่ยกเลิก', (tester) async {
    final repo = await pump(tester, [upcoming]);
    await tester.tap(find.text(S.cancelBooking));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.keepBooking));
    await tester.pumpAndSettle();
    expect(repo.cancelledIds, isEmpty);
    expect(find.text(S.statusConfirmed), findsOneWidget);
  });

  testWidgets('DB ปฏิเสธ (จบไปแล้ว) → แสดงข้อความบนการ์ด', (tester) async {
    final repo = await pump(tester, [upcoming]);
    repo.failWith = BookingFailure.alreadyEnded;
    await tester.tap(find.text(S.cancelBooking));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.confirmCancel));
    await tester.pumpAndSettle();
    expect(find.text(S.errEnded), findsOneWidget);
  });

  testWidgets('ไม่มีการจอง → ข้อความว่าง + ปุ่มไปดูห้อง', (tester) async {
    var browsed = false;
    await pump(tester, [ended], onBrowse: () => browsed = true);
    expect(find.text(S.noUpcoming), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, S.noUpcomingAction));
    expect(browsed, isTrue);
  });
}
