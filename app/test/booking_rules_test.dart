import 'package:flutter_test/flutter_test.dart';
import 'package:room_booking/src/features/booking/booking_rules.dart';

void main() {
  final now = DateTime(2026, 11, 16, 10, 20);
  final today = DateTime(2026, 11, 16);
  final tomorrow = DateTime(2026, 11, 17);

  BookingProblem? v(
    DateTime day,
    String s,
    String e, [
    String title = 'ประชุม',
  ]) => validateBooking(day: day, start: s, end: e, title: title, now: now);

  test('parseHhmm รับหลายรูปแบบ และปฏิเสธเวลาที่ไม่มีจริง', () {
    expect(parseHhmm('09:30'), (9, 30));
    expect(parseHhmm('9:30'), (9, 30));
    expect(parseHhmm('0930'), (9, 30));
    expect(parseHhmm(' 14.45 '), (14, 45));
    expect(parseHhmm('24:00'), isNull);
    expect(parseHhmm('10:60'), isNull);
    expect(parseHhmm('abc'), isNull);
  });

  test('ผ่านเมื่อถูกทุกข้อ', () {
    expect(v(tomorrow, '09:00', '10:30'), isNull);
    expect(v(today, '10:30', '10:45'), isNull);
  });

  test('ตรวจรูปแบบเวลา', () {
    expect(v(tomorrow, 'x', '10:00'), BookingProblem.badStart);
    expect(v(tomorrow, '09:00', ''), BookingProblem.badEnd);
  });

  test('ทีละ 15 นาที', () {
    expect(v(tomorrow, '09:10', '10:00'), BookingProblem.notQuarter);
    expect(v(tomorrow, '09:00', '10:05'), BookingProblem.notQuarter);
  });

  test('ลำดับและความยาว', () {
    expect(v(tomorrow, '10:00', '10:00'), BookingProblem.endBeforeStart);
    expect(v(tomorrow, '11:00', '10:00'), BookingProblem.endBeforeStart);
    expect(v(tomorrow, '09:00', '13:00'), isNull, reason: '4 ชม. พอดีได้');
    expect(v(tomorrow, '09:00', '13:15'), BookingProblem.tooLong);
  });

  test('ย้อนหลังและไกลเกิน 30 วัน', () {
    expect(v(today, '10:00', '11:00'), BookingProblem.inPast);
    expect(v(DateTime(2026, 12, 17), '09:00', '10:00'), BookingProblem.tooFar);
    expect(v(DateTime(2026, 12, 15), '09:00', '10:00'), isNull);
  });

  test('ต้องมีหัวข้อ', () {
    expect(v(tomorrow, '09:00', '10:00', '   '), BookingProblem.titleRequired);
  });

  test('suggestedStart: วันนี้ = ช่วง 15 นาทีถัดไป · วันอื่น = 09:00', () {
    expect(suggestedStart(today, now), (10, 30));
    expect(suggestedStart(today, DateTime(2026, 11, 16, 10, 30)), (10, 45));
    expect(suggestedStart(tomorrow, now), (9, 0));
    expect(suggestedStart(today, DateTime(2026, 11, 16, 23, 50)), (23, 45));
  });
}
