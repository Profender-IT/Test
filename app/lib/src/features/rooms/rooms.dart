import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../supabase/providers.dart';
import 'availability.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.capacity,
    this.floor,
    this.equipment = const [],
  });

  final String id;
  final String name;
  final int capacity;
  final String? floor;
  final List<String> equipment;

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    name: j['name'] as String,
    capacity: j['capacity'] as int,
    floor: j['floor'] as String?,
    equipment: (j['equipment'] as List?)?.cast<String>() ?? const [],
  );
}

/// ห้องที่เปิดใช้งาน (RLS ซ่อนห้องที่ปิดให้อยู่แล้ว)
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('rooms')
      .select('id, name, capacity, floor, equipment')
      .order('name');
  return rows.map(Room.fromJson).toList();
});

/// เวลาปัจจุบัน (override ได้ใน test)
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => dayStart(ref.read(clockProvider)());

  void select(DateTime day) => state = dayStart(day);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

/// ช่วงไม่ว่างของทุกห้องในวันหนึ่ง (ไม่เปิดเผยผู้จองคนอื่น · room_busy_slots ใน DB)
final busySlotsProvider = FutureProvider.family<List<BusySlot>, DateTime>((
  ref,
  day,
) async {
  final from = dayStart(day);
  final to = DateTime(from.year, from.month, from.day + 1);
  final rows = await ref
      .watch(supabaseClientProvider)
      .rpc(
        'room_busy_slots',
        params: {
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
        },
      );
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(BusySlot.fromJson)
      .toList();
});
