import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../booking/book_page.dart' show failureText;
import '../booking/bookings_repository.dart';
import '../rooms/availability.dart';
import '../rooms/rooms.dart';

/// การจองของฉัน (RLS คืนเฉพาะของผู้ใช้)
final myBookingsProvider = FutureProvider<List<MyBooking>>(
  (ref) => ref.watch(bookingsRepositoryProvider).mine(),
);

enum MyBookingState { upcoming, inProgress, ended, cancelled }

MyBookingState stateOf(MyBooking b, DateTime now) {
  if (b.cancelled) return MyBookingState.cancelled;
  if (!b.end.isAfter(now)) return MyBookingState.ended;
  if (!b.start.isAfter(now)) return MyBookingState.inProgress;
  return MyBookingState.upcoming;
}

/// แบ่ง "กำลังจะถึง" (เรียงใกล้สุดก่อน) กับ "ประวัติ" (ล่าสุดก่อน)
(List<MyBooking>, List<MyBooking>) splitBookings(
  List<MyBooking> all,
  DateTime now,
) {
  final active = <MyBooking>[];
  final history = <MyBooking>[];
  for (final b in all) {
    switch (stateOf(b, now)) {
      case MyBookingState.upcoming || MyBookingState.inProgress:
        active.add(b);
      case MyBookingState.ended || MyBookingState.cancelled:
        history.add(b);
    }
  }
  active.sort((a, b) => a.start.compareTo(b.start));
  history.sort((a, b) => b.start.compareTo(a.start));
  return (active, history);
}

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key, this.onBrowseRooms});

  final VoidCallback? onBrowseRooms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final bookings = ref.watch(myBookingsProvider);
    final t = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myBookingsProvider.future),
      child: switch (bookings) {
        AsyncData(:final value) => _List(
          all: value,
          now: now,
          onBrowseRooms: onBrowseRooms,
        ),
        AsyncError() => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(S.loadFailed, style: t.bodyLarge),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => ref.invalidate(myBookingsProvider),
                child: const Text(S.retry),
              ),
            ),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.all, required this.now, this.onBrowseRooms});
  final List<MyBooking> all;
  final DateTime now;
  final VoidCallback? onBrowseRooms;

  @override
  Widget build(BuildContext context) {
    final (active, history) = splitBookings(all, now);
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const SectionLabel(S.upcoming),
        const SizedBox(height: 12),
        if (active.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.noUpcoming, style: t.bodyLarge),
                  if (onBrowseRooms != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onBrowseRooms,
                      child: const Text(S.noUpcomingAction),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          for (final b in active) ...[
            BookingCard(booking: b, now: now),
            const SizedBox(height: 12),
          ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel(S.history),
          const SizedBox(height: 12),
          for (final b in history) ...[
            BookingCard(booking: b, now: now),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class BookingCard extends ConsumerStatefulWidget {
  const BookingCard({super.key, required this.booking, required this.now});
  final MyBooking booking;
  final DateTime now;

  @override
  ConsumerState<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<BookingCard> {
  bool _busy = false;
  String? _error;

  Future<void> _cancel() async {
    final b = widget.booking;
    // จับ messenger ก่อน await · การ์ดนี้อาจถูกย้ายไป "ประวัติ" และ dispose หลังยกเลิก
    final messenger = ScaffoldMessenger.of(context);
    final when = '${fullDateLabel(b.start)} ${timeRange(b.start, b.end)}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.cancelConfirmTitle(b.roomName)),
        content: Text(S.cancelConfirmBody(when)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.keepBooking),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.busy,
              foregroundColor: context.palette.card,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(S.confirmCancel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(bookingsRepositoryProvider).cancel(b.id);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(busySlotsProvider);
      messenger.showSnackBar(const SnackBar(content: Text(S.cancelled)));
    } on BookingException catch (e) {
      if (mounted) setState(() => _error = failureText(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final state = stateOf(b, widget.now);
    final faded =
        state == MyBookingState.cancelled || state == MyBookingState.ended;

    final pill = switch (state) {
      MyBookingState.upcoming => StatusPill(
        label: S.statusConfirmed,
        icon: Icons.check_circle_outline,
        color: p.free,
      ),
      MyBookingState.inProgress => StatusPill(
        label: S.statusNow,
        icon: Icons.meeting_room_outlined,
        color: p.free,
      ),
      MyBookingState.ended => StatusPill(
        label: S.statusEnded,
        icon: Icons.history,
        color: p.muted,
      ),
      MyBookingState.cancelled => StatusPill(
        label: S.statusCancelled,
        icon: Icons.cancel_outlined,
        color: p.busy,
      ),
    };

    return Card(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              color: faded ? p.line : p.tileFor(b.roomName.hashCode.abs()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(b.roomName, style: t.titleMedium)),
                        pill,
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${fullDateLabel(b.start)} · ${timeRange(b.start, b.end)}',
                      style: t.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(b.title, style: t.bodySmall),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: t.bodySmall?.copyWith(color: p.busy),
                      ),
                    ],
                    if (state == MyBookingState.upcoming ||
                        state == MyBookingState.inProgress) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        // ข้อความสั้นบนจอ · ชื่อสำหรับ screen reader บอกครบว่ายกเลิกอันไหน
                        child: Semantics(
                          container: true,
                          button: true,
                          onTap: _busy ? null : _cancel,
                          label:
                              '${S.cancelBooking} ${b.roomName} ${timeRange(b.start, b.end)}',
                          excludeSemantics: true,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: p.busy,
                              side: BorderSide(color: p.busy),
                            ),
                            onPressed: _busy ? null : _cancel,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text(S.cancelBooking),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
