// ตรวจฟอร์มจองฝั่งแอปเพื่อ UX (ข้อความทันที) · กติกาจริงบังคับซ้ำที่ DB (ROOM-4)

enum BookingProblem {
  badStart,
  badEnd,
  notQuarter,
  endBeforeStart,
  tooShort,
  tooLong,
  inPast,
  tooFar,
  titleRequired,
}

const maxDuration = Duration(hours: 4);
const minDuration = Duration(minutes: 15);
const maxAdvance = Duration(days: 30);

/// "9:00" / "09:00" / "0900" → (h, m) หรือ null
(int, int)? parseHhmm(String input) {
  final m = RegExp(r'^\s*(\d{1,2})[:.]?(\d{2})\s*$').firstMatch(input);
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  if (h > 23 || min > 59) return null;
  return (h, min);
}

DateTime at(DateTime day, (int, int) hm) =>
    DateTime(day.year, day.month, day.day, hm.$1, hm.$2);

/// ปัญหาแรกที่เจอ (null = ผ่าน)
BookingProblem? validateBooking({
  required DateTime day,
  required String start,
  required String end,
  required String title,
  required DateTime now,
}) {
  final s = parseHhmm(start);
  if (s == null) return BookingProblem.badStart;
  final e = parseHhmm(end);
  if (e == null) return BookingProblem.badEnd;
  if (s.$2 % 15 != 0 || e.$2 % 15 != 0) return BookingProblem.notQuarter;
  final from = at(day, s);
  final to = at(day, e);
  if (!to.isAfter(from)) return BookingProblem.endBeforeStart;
  final d = to.difference(from);
  if (d < minDuration) return BookingProblem.tooShort;
  if (d > maxDuration) return BookingProblem.tooLong;
  if (from.isBefore(now)) return BookingProblem.inPast;
  if (from.isAfter(now.add(maxAdvance))) return BookingProblem.tooFar;
  if (title.trim().isEmpty) return BookingProblem.titleRequired;
  return null;
}

/// เวลาเริ่มที่แนะนำ: ช่วง 15 นาทีถัดไป (ถ้าเป็นวันนี้) หรือ 09:00
(int, int) suggestedStart(DateTime day, DateTime now) {
  final isToday =
      day.year == now.year && day.month == now.month && day.day == now.day;
  if (!isToday) return (9, 0);
  final next = now.add(Duration(minutes: 15 - now.minute % 15));
  if (next.day != now.day) return (23, 45);
  return (next.hour, next.minute);
}
