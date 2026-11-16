import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/features/profile/profile.dart';
import 'package:room_booking/src/features/rooms/availability.dart';
import 'package:room_booking/src/features/rooms/rooms.dart';
import 'package:room_booking/src/features/rooms/rooms_page.dart';
import 'package:room_booking/src/l10n/strings.dart';
import 'package:room_booking/src/supabase/providers.dart';
import 'package:room_booking/src/theme/app_theme.dart';

final now = DateTime(2026, 11, 16, 10, 30);
const roomA = Room(
  id: 'a',
  name: 'ห้อง A',
  capacity: 6,
  floor: 'ชั้น 2',
  equipment: ['ทีวี'],
);
const roomB = Room(id: 'b', name: 'ห้อง B', capacity: 10);

Future<List<DateTime>> pump(
  WidgetTester tester, {
  Future<List<Room>> Function()? rooms,
  Map<DateTime, List<BusySlot>> slots = const {},
  void Function(Room, DateTime)? onBook,
}) async {
  tester.view.physicalSize = const Size(420, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final requested = <DateTime>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        currentUserProvider.overrideWithValue(null),
        myProfileProvider.overrideWith(
          (ref) async => const Profile(id: 'u', displayName: 'ผู้ทดสอบ'),
        ),
        roomsProvider.overrideWith(
          (ref) => (rooms ?? () async => [roomA, roomB])(),
        ),
        busySlotsProvider.overrideWith((ref, day) async {
          requested.add(day);
          return slots[day] ?? const [];
        }),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: RoomsPage(onBook: onBook)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requested;
}

void main() {
  final today = DateTime(2026, 11, 16);
  final tomorrow = DateTime(2026, 11, 17);
  final busyA = [
    BusySlot(
      roomId: 'a',
      start: DateTime(2026, 11, 16, 10),
      end: DateTime(2026, 11, 16, 11),
      isMine: false,
    ),
    BusySlot(
      roomId: 'a',
      start: DateTime(2026, 11, 16, 14),
      end: DateTime(2026, 11, 16, 15),
      isMine: true,
    ),
  ];

  testWidgets('แสดงห้อง สถานะตอนนี้ และช่วงไม่ว่าง', (tester) async {
    await pump(tester, slots: {today: busyA});

    expect(find.text('สวัสดี ผู้ทดสอบ'), findsOneWidget);
    expect(find.text(S.heroFreeNow(1, 2)), findsOneWidget);
    expect(find.text(S.busyUntil('11:00')), findsOneWidget);
    expect(find.text(S.freeNow), findsOneWidget);
    expect(find.text('${S.busyLabel} 10:00–11:00'), findsOneWidget);
    expect(find.text('${S.mine} 14:00–15:00'), findsOneWidget);
    expect(find.text('6 คน · ชั้น 2 · ทีวี'), findsOneWidget);
    expect(find.text(S.freeAllDay), findsWidgets);
    expect(
      find.textContaining('จองห้อง A'),
      findsNothing,
      reason: 'ROOM-5 ยังไม่มีปุ่มจองถ้าไม่ส่ง onBook',
    );
  });

  testWidgets('เลือกวันพรุ่งนี้ → โหลดช่วงไม่ว่างของวันนั้น', (tester) async {
    final requested = await pump(
      tester,
      slots: {
        today: busyA,
        tomorrow: [
          BusySlot(
            roomId: 'b',
            start: DateTime(2026, 11, 17, 9),
            end: DateTime(2026, 11, 17, 10),
            isMine: false,
          ),
        ],
      },
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'พรุ่งนี้'));
    await tester.pumpAndSettle();

    expect(requested, contains(tomorrow));
    expect(find.text(S.bookedCount(1)), findsOneWidget);
    expect(find.text('${S.busyLabel} 09:00–10:00'), findsOneWidget);
    expect(
      find.text(S.freeNow),
      findsNothing,
      reason: 'วันอื่นไม่แสดง "ว่างตอนนี้"',
    );
  });

  testWidgets('ปุ่มจองส่งห้องและวันที่เลือก', (tester) async {
    Room? booked;
    DateTime? bookedDay;
    await pump(
      tester,
      onBook: (r, d) {
        booked = r;
        bookedDay = d;
      },
    );
    await tester.tap(
      find
          .widgetWithText(FilledButton, '${S.bookRoom('ห้อง A')} · วันนี้')
          .first,
    );
    expect(booked?.id, 'a');
    expect(bookedDay, today);
  });

  testWidgets('ไม่มีห้อง → ข้อความว่าง', (tester) async {
    await pump(tester, rooms: () async => []);
    expect(find.text(S.noRooms), findsOneWidget);
  });

  testWidgets('โหลดไม่สำเร็จ → ปุ่มลองอีกครั้ง', (tester) async {
    await pump(tester, rooms: () async => throw Exception('network'));
    expect(find.text(S.loadFailed), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, S.retry), findsOneWidget);
  });
}
