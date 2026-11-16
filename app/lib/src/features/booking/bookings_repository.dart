import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/providers.dart';

/// ข้อผิดพลาดจาก DB ที่แอปแปลเป็นข้อความได้
enum BookingFailure { overlap, inPast, tooFar, invalid, alreadyEnded, network }

class BookingException implements Exception {
  const BookingException(this.failure);
  final BookingFailure failure;
}

class MyBooking {
  const MyBooking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.title,
    required this.start,
    required this.end,
    required this.cancelled,
  });

  final String id;
  final String roomId;
  final String roomName;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool cancelled;

  factory MyBooking.fromJson(Map<String, dynamic> j) => MyBooking(
    id: j['id'] as String,
    roomId: j['room_id'] as String,
    roomName: (j['rooms'] as Map?)?['name'] as String? ?? '',
    title: j['title'] as String,
    start: DateTime.parse(j['starts_at'] as String).toLocal(),
    end: DateTime.parse(j['ends_at'] as String).toLocal(),
    cancelled: j['status'] == 'cancelled',
  );
}

BookingFailure _map(PostgrestException e) {
  if (e.code == '23P01') return BookingFailure.overlap;
  final msg = e.message;
  if (msg.contains('booking_in_past')) return BookingFailure.inPast;
  if (msg.contains('booking_too_far')) return BookingFailure.tooFar;
  if (msg.contains('booking_already_ended')) return BookingFailure.alreadyEnded;
  return BookingFailure.invalid;
}

/// การเขียน/อ่านการจองผ่าน RLS ด้วย JWT ของผู้ใช้เท่านั้น (ไม่ใช้กุญแจสิทธิ์สูง)
class BookingsRepository {
  BookingsRepository(this._client);
  final SupabaseClient _client;

  Future<void> create({
    required String roomId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      await _client.from('bookings').insert({
        'room_id': roomId,
        'title': title.trim(),
        'starts_at': start.toUtc().toIso8601String(),
        'ends_at': end.toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw BookingException(_map(e));
    } on Exception {
      throw const BookingException(BookingFailure.network);
    }
  }

  Future<List<MyBooking>> mine() async {
    final rows = await _client
        .from('bookings')
        .select('id, room_id, title, starts_at, ends_at, status, rooms(name)')
        .order('starts_at', ascending: false)
        .limit(200);
    return rows.map(MyBooking.fromJson).toList();
  }

  Future<void> cancel(String id) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw BookingException(_map(e));
    } on Exception {
      throw const BookingException(BookingFailure.network);
    }
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>(
  (ref) => BookingsRepository(ref.watch(supabaseClientProvider)),
);
