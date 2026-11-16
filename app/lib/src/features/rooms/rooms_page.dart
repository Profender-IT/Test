import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../supabase/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../profile/profile.dart';
import 'availability.dart';
import 'rooms.dart';

/// หน้าแรก: ห้องทั้งหมด + สถานะว่างตอนนี้ + ช่วงไม่ว่างตามวันที่เลือก
class RoomsPage extends ConsumerWidget {
  const RoomsPage({super.key, this.onBook});

  /// เปิดฟอร์มจอง (ROOM-6) · null = ยังไม่แสดงปุ่มจอง
  final void Function(Room room, DateTime day)? onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final day = ref.watch(selectedDayProvider);
    final rooms = ref.watch(roomsProvider);
    final slots = ref.watch(busySlotsProvider(day));
    final today = ref.watch(busySlotsProvider(dayStart(now)));
    final t = Theme.of(context).textTheme;

    Future<void> refresh() async {
      ref.invalidate(roomsProvider);
      ref.invalidate(busySlotsProvider);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AnnounceStrip(S.announce)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList.list(
              children: [
                const _Greeting(),
                const SizedBox(height: 16),
                _Hero(
                  freeNow: switch ((rooms, today)) {
                    (AsyncData(value: final r), AsyncData(value: final s)) =>
                      r
                          .where(
                            (room) =>
                                busyAt(slotsForRoom(s, room.id), now) == null,
                          )
                          .length,
                    _ => null,
                  },
                  total: rooms.value?.length,
                ),
                const SizedBox(height: 28),
                const SectionLabel(S.chooseDay),
                const SizedBox(height: 12),
                _DayChips(now: now, selected: day),
                const SizedBox(height: 28),
                const SectionLabel(S.rooms),
                const SizedBox(height: 12),
              ],
            ),
          ),
          switch ((rooms, slots)) {
            (AsyncData(value: final r), AsyncData()) when r.isEmpty =>
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(S.noRooms, style: t.bodyLarge),
                ),
              ),
            (AsyncData(value: final r), AsyncData(value: final s)) =>
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: r.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => RoomCard(
                    room: r[i],
                    index: i,
                    slots: slotsForRoom(s, r[i].id),
                    day: day,
                    now: now,
                    onBook: onBook == null ? null : () => onBook!(r[i], day),
                  ),
                ),
              ),
            (AsyncError(), _) || (_, AsyncError()) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(S.loadFailed, style: t.bodyLarge),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: refresh,
                      child: const Text(S.retry),
                    ),
                  ],
                ),
              ),
            ),
            _ => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          },
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
            sliver: SliverList.list(
              children: const [
                InfoCard(
                  title: S.infoNoOverlapTitle,
                  body: S.infoNoOverlapBody,
                ),
                SizedBox(height: 12),
                InfoCard(title: S.infoCancelTitle, body: S.infoCancelBody),
                SizedBox(height: 12),
                InfoCard(title: S.infoPrivacyTitle, body: S.infoPrivacyBody),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: DarkFooter(S.footer)),
        ],
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = ref.watch(myProfileProvider).value?.displayName;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${S.greeting}${name == null ? '' : ' $name'}',
          style: t.titleMedium,
        ),
        if (user?.email != null) Text(user!.email!, style: t.bodySmall),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.freeNow, required this.total});
  final int? freeNow;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: p.tileFor(0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.heroTitle, style: t.displaySmall?.copyWith(color: p.onTile)),
          const SizedBox(height: 20),
          if (freeNow != null && total != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: p.onTile),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                S.heroFreeNow(freeNow!, total!),
                style: t.labelLarge?.copyWith(color: p.onTile),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChips extends ConsumerWidget {
  const _DayChips({required this.now, required this.selected});
  final DateTime now;
  final DateTime selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    // Wrap แทนเลื่อนแนวนอน (ui-ux-pro-max: gesture-conflicts / horizontal-scroll)
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in selectableDays(now))
          ChoiceChip(
            label: Text(dayLabel(d, now)),
            selected: isSameDay(d, selected),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSameDay(d, selected) ? p.background : p.ink,
            ),
            onSelected: (_) => ref.read(selectedDayProvider.notifier).select(d),
          ),
      ],
    );
  }
}

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.index,
    required this.slots,
    required this.day,
    required this.now,
    this.onBook,
  });

  final Room room;
  final int index;
  final List<BusySlot> slots;
  final DateTime day;
  final DateTime now;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final isToday = isSameDay(day, now);
    final current = isToday ? busyAt(slots, now) : null;

    final status = switch ((isToday, current, slots.isEmpty)) {
      (true, null, _) => StatusPill(
        label: S.freeNow,
        icon: Icons.check_circle_outline,
        color: p.free,
      ),
      (true, _, _) => StatusPill(
        label: S.busyUntil(hhmm(freeAgainAt(slots, now))),
        icon: Icons.schedule,
        color: p.busy,
      ),
      (false, _, true) => StatusPill(
        label: S.freeAllDay,
        icon: Icons.check_circle_outline,
        color: p.free,
      ),
      (false, _, false) => StatusPill(
        label: S.bookedCount(slots.length),
        icon: Icons.event_busy_outlined,
        color: p.busy,
      ),
    };

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 132,
            color: p.tileFor(index),
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Align(alignment: Alignment.topLeft, child: status),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: p.onTile),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      room.name,
                      style: t.labelLarge?.copyWith(color: p.onTile),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(
                  [
                    S.capacity(room.capacity),
                    ?room.floor,
                    ...room.equipment,
                  ].join(' · '),
                  style: t.bodySmall,
                ),
                const SizedBox(height: 12),
                if (slots.isEmpty)
                  Text(
                    S.freeAllDay,
                    style: t.bodyMedium?.copyWith(color: p.free),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in slots)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: p.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${s.isMine ? S.mine : S.busyLabel} ${timeRange(s.start, s.end)}',
                            style: t.bodySmall?.copyWith(
                              color: p.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                if (onBook != null) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: onBook,
                      child: Text('${S.bookThisRoom} · ${dayLabel(day, now)}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
