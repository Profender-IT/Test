// ฟังก์ชันล้วนเรื่องเวลา/ช่วงไม่ว่าง (ทดสอบง่าย ไม่พึ่ง Flutter) · กติกาจริงอยู่ที่ DB (ADR 0001)

class BusySlot {
  const BusySlot({
    required this.roomId,
    required this.start,
    required this.end,
    required this.isMine,
    this.bookingId,
  });

  final String roomId;
  final DateTime start; // local time
  final DateTime end;
  final bool isMine;
  final String? bookingId;

  factory BusySlot.fromJson(Map<String, dynamic> j) => BusySlot(
    roomId: j['room_id'] as String,
    start: DateTime.parse(j['starts_at'] as String).toLocal(),
    end: DateTime.parse(j['ends_at'] as String).toLocal(),
    isMine: j['is_mine'] as bool? ?? false,
    bookingId: j['booking_id'] as String?,
  );

  bool covers(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

/// วันที่เลือกได้: วันนี้ + 6 วันถัดไป
List<DateTime> selectableDays(DateTime now, {int count = 7}) => [
  for (var i = 0; i < count; i++) DateTime(now.year, now.month, now.day + i),
];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _weekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
const _months = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

String dayLabel(DateTime day, DateTime today) {
  final d = dayStart(day);
  final t = dayStart(today);
  if (d == t) return 'วันนี้';
  if (d == DateTime(t.year, t.month, t.day + 1)) return 'พรุ่งนี้';
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

String fullDateLabel(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year + 543}';

String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String timeRange(DateTime a, DateTime b) => '${hhmm(a)}–${hhmm(b)}';

/// ช่วงไม่ว่างของห้องหนึ่ง เรียงตามเวลา
List<BusySlot> slotsForRoom(Iterable<BusySlot> all, String roomId) =>
    all.where((s) => s.roomId == roomId).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

/// ช่วงที่ครอบเวลา [now] (ห้องไม่ว่างตอนนี้) หรือ null
BusySlot? busyAt(Iterable<BusySlot> slots, DateTime now) {
  for (final s in slots) {
    if (s.covers(now)) return s;
  }
  return null;
}

/// ถ้าไม่ว่างตอนนี้ ว่างอีกครั้งเมื่อไร (รวมช่วงที่ต่อกัน)
DateTime freeAgainAt(List<BusySlot> sortedSlots, DateTime now) {
  var t = now;
  for (final s in sortedSlots) {
    if (s.covers(t)) t = s.end;
  }
  return t;
}
