import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../rooms/availability.dart';
import '../rooms/rooms.dart';
import 'booking_rules.dart';
import 'bookings_repository.dart';

String problemText(BookingProblem p) => switch (p) {
  BookingProblem.badStart => S.errBadStart,
  BookingProblem.badEnd => S.errBadEnd,
  BookingProblem.notQuarter => S.errNotQuarter,
  BookingProblem.endBeforeStart => S.errEndBeforeStart,
  BookingProblem.tooShort => S.errTooShort,
  BookingProblem.tooLong => S.errTooLong,
  BookingProblem.inPast => S.errInPast,
  BookingProblem.tooFar => S.errTooFar,
  BookingProblem.titleRequired => S.errTitle,
};

String failureText(BookingFailure f) => switch (f) {
  BookingFailure.overlap => S.errOverlap,
  BookingFailure.inPast => S.errInPast,
  BookingFailure.tooFar => S.errTooFar,
  BookingFailure.alreadyEnded => S.errEnded,
  BookingFailure.invalid => S.errInvalid,
  BookingFailure.network => S.errNetwork,
};

/// ฟอร์มจองห้อง · ตรวจทันทีในแอป แล้ว DB ตรวจซ้ำ (กันจองซ้อนจริงที่ exclusion constraint)
class BookPage extends ConsumerStatefulWidget {
  const BookPage({
    super.key,
    required this.roomId,
    required this.initialDay,
    this.onDone,
  });

  final String roomId;
  final DateTime initialDay;

  /// เรียกหลังจองสำเร็จ (router พากลับหน้าแรก)
  final VoidCallback? onDone;

  @override
  ConsumerState<BookPage> createState() => _BookPageState();
}

class _BookPageState extends ConsumerState<BookPage> {
  late DateTime _day = dayStart(widget.initialDay);
  late final TextEditingController _start;
  late final TextEditingController _end;
  final _title = TextEditingController();
  BookingProblem? _problem;
  String? _serverError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final s = suggestedStart(_day, now);
    final from = at(_day, s);
    final to = from.add(const Duration(hours: 1));
    _start = TextEditingController(text: hhmm(from));
    _end = TextEditingController(
      text: isSameDay(to, from) ? hhmm(to) : '23:59',
    );
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final now = ref.read(clockProvider)();
    final problem = validateBooking(
      day: _day,
      start: _start.text,
      end: _end.text,
      title: _title.text,
      now: now,
    );
    setState(() {
      _problem = problem;
      _serverError = null;
    });
    if (problem != null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(bookingsRepositoryProvider)
          .create(
            roomId: widget.roomId,
            title: _title.text,
            start: at(_day, parseHhmm(_start.text)!),
            end: at(_day, parseHhmm(_end.text)!),
          );
      ref.invalidate(busySlotsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.booked)));
      widget.onDone?.call();
    } on BookingException catch (e) {
      if (mounted) setState(() => _serverError = failureText(e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final rooms = ref.watch(roomsProvider);

    final idx = rooms.value?.indexWhere((r) => r.id == widget.roomId) ?? -1;
    final room = idx >= 0 ? rooms.value![idx] : null;
    final slots = ref.watch(busySlotsProvider(_day)).value;
    final roomSlots = slots == null ? null : slotsForRoom(slots, widget.roomId);

    String? fieldError(Set<BookingProblem> mine) =>
        _problem != null && mine.contains(_problem)
        ? problemText(_problem!)
        : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AnnounceStrip(S.announce),
            PillHeader(
              title: S.bookTitle,
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: _body(
                context,
                rooms,
                room,
                idx,
                roomSlots,
                now,
                fieldError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AsyncValue<List<Room>> rooms,
    Room? room,
    int idx,
    List<BusySlot>? roomSlots,
    DateTime now,
    String? Function(Set<BookingProblem>) fieldError,
  ) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return rooms.isLoading
        ? const Center(child: CircularProgressIndicator())
        : room == null
        ? Center(child: Text(S.roomNotFound, style: t.bodyLarge))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: p.tileFor(idx),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: t.headlineMedium?.copyWith(color: p.onTile),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [S.capacity(room.capacity), ?room.floor].join(' · '),
                      style: t.bodyMedium?.copyWith(color: p.onTile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionLabel(S.date),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in selectableDays(now))
                    ChoiceChip(
                      label: Text(dayLabel(d, now)),
                      selected: isSameDay(d, _day),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSameDay(d, _day) ? p.background : p.ink,
                      ),
                      onSelected: (_) => setState(() => _day = d),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(fullDateLabel(_day), style: t.bodySmall),
              const SizedBox(height: 20),
              const SectionLabel(S.busyThatDay),
              const SizedBox(height: 12),
              if (roomSlots == null)
                const LinearProgressIndicator()
              else if (roomSlots.isEmpty)
                Text(S.freeAllDay, style: t.bodyMedium?.copyWith(color: p.free))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in roomSlots)
                      Chip(
                        label: Text(
                          '${s.isMine ? S.mine : S.busyLabel} ${timeRange(s.start, s.end)}',
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _start,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: S.startTime,
                        hintText: S.timeHint,
                        errorText: fieldError({
                          BookingProblem.badStart,
                          BookingProblem.notQuarter,
                          BookingProblem.inPast,
                          BookingProblem.tooFar,
                        }),
                        errorMaxLines: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _end,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: S.endTime,
                        hintText: S.timeHint,
                        errorText: fieldError({
                          BookingProblem.badEnd,
                          BookingProblem.endBeforeStart,
                          BookingProblem.tooShort,
                          BookingProblem.tooLong,
                        }),
                        errorMaxLines: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: S.meetingTitle,
                  helperText: S.meetingTitleHelper,
                  errorText: fieldError({BookingProblem.titleRequired}),
                ),
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: p.busy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: t.bodyMedium?.copyWith(color: p.busy),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(S.confirmBooking),
              ),
              const SizedBox(height: 24),
            ],
          );
  }
}
