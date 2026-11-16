import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/features/rooms/availability.dart';

BusySlot slot(String room, DateTime s, DateTime e, {bool mine = false}) =>
    BusySlot(roomId: room, start: s, end: e, isMine: mine);

void main() {
  final now = DateTime(2026, 11, 16, 10, 30); // จันทร์

  test('selectableDays: วันนี้ + 6 วัน เริ่มเที่ยงคืน', () {
    final days = selectableDays(now);
    expect(days, hasLength(7));
    expect(days.first, DateTime(2026, 11, 16));
    expect(days.last, DateTime(2026, 11, 22));
  });

  test('dayLabel: วันนี้ / พรุ่งนี้ / วันในสัปดาห์', () {
    expect(dayLabel(DateTime(2026, 11, 16, 23), now), 'วันนี้');
    expect(dayLabel(DateTime(2026, 11, 17), now), 'พรุ่งนี้');
    expect(dayLabel(DateTime(2026, 11, 18), now), 'พ. 18 พ.ย.');
    expect(
      dayLabel(DateTime(2026, 12, 31), DateTime(2026, 12, 30)),
      'พรุ่งนี้',
    );
  });

  test('fullDateLabel ใช้ปี พ.ศ.', () {
    expect(fullDateLabel(DateTime(2026, 11, 16)), 'จ. 16 พ.ย. 2569');
  });

  test('hhmm / timeRange เติมศูนย์', () {
    expect(hhmm(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(
      timeRange(DateTime(2026, 1, 1, 9), DateTime(2026, 1, 1, 10, 30)),
      '09:00–10:30',
    );
  });

  test('slotsForRoom กรองตามห้องและเรียงเวลา', () {
    final all = [
      slot('b', DateTime(2026, 11, 16, 9), DateTime(2026, 11, 16, 10)),
      slot('a', DateTime(2026, 11, 16, 14), DateTime(2026, 11, 16, 15)),
      slot('a', DateTime(2026, 11, 16, 9), DateTime(2026, 11, 16, 10)),
    ];
    final a = slotsForRoom(all, 'a');
    expect(a.map((s) => s.start.hour), [9, 14]);
  });

  test('busyAt: ช่วงเปิดปิด [start, end)', () {
    final s = [
      slot('a', DateTime(2026, 11, 16, 10), DateTime(2026, 11, 16, 11)),
    ];
    expect(busyAt(s, DateTime(2026, 11, 16, 10)), isNotNull);
    expect(busyAt(s, DateTime(2026, 11, 16, 10, 59)), isNotNull);
    expect(busyAt(s, DateTime(2026, 11, 16, 11)), isNull);
    expect(busyAt(s, DateTime(2026, 11, 16, 9, 59)), isNull);
  });

  test('freeAgainAt รวมช่วงที่ต่อกัน', () {
    final s = [
      slot('a', DateTime(2026, 11, 16, 10), DateTime(2026, 11, 16, 11)),
      slot('a', DateTime(2026, 11, 16, 11), DateTime(2026, 11, 16, 12)),
      slot('a', DateTime(2026, 11, 16, 13), DateTime(2026, 11, 16, 14)),
    ];
    expect(freeAgainAt(s, now), DateTime(2026, 11, 16, 12));
    expect(
      freeAgainAt(s, DateTime(2026, 11, 16, 12, 30)),
      DateTime(2026, 11, 16, 12, 30),
    );
  });

  test('BusySlot.fromJson แปลง UTC เป็นเวลาเครื่อง', () {
    final s = BusySlot.fromJson({
      'room_id': 'r',
      'starts_at': '2026-11-16T03:00:00+00:00',
      'ends_at': '2026-11-16T04:00:00+00:00',
      'is_mine': true,
      'booking_id': 'b1',
    });
    expect(s.start, DateTime.utc(2026, 11, 16, 3).toLocal());
    expect(s.isMine, isTrue);
    expect(s.bookingId, 'b1');
  });
}
