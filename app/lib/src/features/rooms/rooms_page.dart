import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../supabase/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../profile/profile.dart';
import 'availability.dart';
import 'rooms.dart';

/// หน้าแรก (โครงตามภาพอ้างอิง): hero → บล็อกสีกรองขนาดห้อง → เลือกวัน → การ์ดห้อง → การ์ดทางลัด → การ์ดข้อมูล → footer
class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key, this.onBook, this.onMyBookings});

  /// เปิดฟอร์มจอง · null = ไม่แสดงปุ่มจอง
  final void Function(Room room, DateTime day)? onBook;

  /// ไปแท็บการจองของฉัน (ปุ่มรองใน hero)
  final VoidCallback? onMyBookings;

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  final _roomsKey = GlobalKey();

  void _scrollToRooms() {
    final ctx = _roomsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _quick({DateTime? day, RoomSize? size}) {
    if (day != null) ref.read(selectedDayProvider.notifier).select(day);
    if (size != null) ref.read(sizeFilterProvider.notifier).select(size);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRooms());
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final day = ref.watch(selectedDayProvider);
    final size = ref.watch(sizeFilterProvider);
    final rooms = ref.watch(roomsProvider);
    final slots = ref.watch(busySlotsProvider(day));
    final today = ref.watch(busySlotsProvider(dayStart(now)));
    final t = Theme.of(context).textTheme;

    Future<void> refresh() async {
      ref.invalidate(roomsProvider);
      ref.invalidate(busySlotsProvider);
    }

    final freeNow = switch ((rooms, today)) {
      (AsyncData(value: final r), AsyncData(value: final s)) =>
        r.where((room) => busyAt(slotsForRoom(s, room.id), now) == null).length,
      _ => null,
    };

    return LayoutBuilder(
      builder: (context, c) {
        final g = gutterFor(c.maxWidth);
        final screen = screenSizeOf(c.maxWidth);
        final pad = EdgeInsets.symmetric(horizontal: g);

        Widget box(Widget child) => SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(child: child),
        );
        const gap = SliverToBoxAdapter(child: SizedBox(height: 32));

        final filtered = rooms.value?.where((r) => fitsSize(r, size)).toList();
        final perRow = screen == ScreenSize.expanded ? 3 : 2;

        return RefreshIndicator(
          onRefresh: refresh,
          child: CustomScrollView(
            slivers: [
              box(const _Greeting()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              box(
                _Hero(
                  freeNow: freeNow,
                  total: rooms.value?.length,
                  onBookNow: () => _quick(day: now, size: RoomSize.all),
                  onMyBookings: widget.onMyBookings,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // บล็อกสี 4 ช่อง = กรองขนาดห้อง (แบบ category tiles ในภาพอ้างอิง)
              SliverPadding(
                padding: pad,
                sliver: SliverGrid.count(
                  crossAxisCount: screen == ScreenSize.compact ? 2 : 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: screen == ScreenSize.compact ? 0.95 : 0.8,
                  children: [
                    for (final (i, s) in RoomSize.values.indexed)
                      _SizeTile(
                        size: s,
                        index: i,
                        selected: s == size,
                        count: rooms.value?.where((r) => fitsSize(r, s)).length,
                        onTap: () => _quick(size: s),
                      ),
                  ],
                ),
              ),
              gap,
              box(const SectionLabel(S.chooseDay)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              box(_DayChips(now: now, selected: day)),
              gap,
              box(
                KeyedSubtree(
                  key: _roomsKey,
                  child: SectionLabel(
                    S.rooms,
                    trailing: filtered == null
                        ? null
                        : Text(
                            S.roomsCount(filtered.length),
                            style: t.bodySmall,
                          ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              switch ((rooms, slots)) {
                (AsyncData(value: final r), AsyncData()) when r.isEmpty => box(
                  Text(S.noRooms, style: t.bodyLarge),
                ),
                (AsyncData(), AsyncData()) when filtered!.isEmpty => box(
                  Text(S.noRoomsForFilter, style: t.bodyLarge),
                ),
                (AsyncData(value: final r), AsyncData(value: final s)) =>
                  screen == ScreenSize.compact
                      ? SliverPadding(
                          padding: pad,
                          sliver: SliverList.separated(
                            itemCount: filtered!.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (_, i) => _card(
                              filtered[i],
                              r.indexOf(filtered[i]),
                              s,
                              day,
                              now,
                            ),
                          ),
                        )
                      : box(
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final room in filtered!)
                                SizedBox(
                                  width:
                                      (c.maxWidth - 2 * g - 16 * (perRow - 1)) /
                                      perRow,
                                  child: _card(
                                    room,
                                    r.indexOf(room),
                                    s,
                                    day,
                                    now,
                                  ),
                                ),
                            ],
                          ),
                        ),
                (AsyncError(), _) || (_, AsyncError()) => box(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                _ => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              },
              gap,
              // การ์ดทางลัด 3 ใบ (แบบ lifestyle cards ในภาพอ้างอิง)
              box(
                _ResponsiveRow(
                  wide: screen != ScreenSize.compact,
                  children: [
                    _QuickCard(
                      index: 3,
                      title: S.quickNowTitle,
                      action: S.quickNowAction,
                      onTap: () => _quick(day: now, size: RoomSize.all),
                    ),
                    _QuickCard(
                      index: 2,
                      title: S.quickTomorrowTitle,
                      action: S.quickTomorrowAction,
                      onTap: () => _quick(
                        day: DateTime(now.year, now.month, now.day + 1),
                        size: RoomSize.all,
                      ),
                    ),
                    _QuickCard(
                      index: 0,
                      title: S.quickLargeTitle,
                      action: S.quickLargeAction,
                      onTap: () => _quick(size: RoomSize.large),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              box(
                _ResponsiveRow(
                  wide: screen != ScreenSize.compact,
                  children: const [
                    InfoCard(
                      title: S.infoNoOverlapTitle,
                      body: S.infoNoOverlapBody,
                    ),
                    InfoCard(title: S.infoCancelTitle, body: S.infoCancelBody),
                    InfoCard(
                      title: S.infoPrivacyTitle,
                      body: S.infoPrivacyBody,
                    ),
                  ],
                ),
              ),
              gap,
              const SliverToBoxAdapter(
                child: DarkFooter(
                  columns: [
                    FooterColumn(S.footerRulesTitle, S.footerRules),
                    FooterColumn(S.footerPrivacyTitle, S.footerPrivacy),
                    FooterColumn(S.footerHelpTitle, S.footerHelp),
                  ],
                  bottom: S.footerBottom,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(
    Room room,
    int index,
    List<BusySlot> all,
    DateTime day,
    DateTime now,
  ) => RoomCard(
    room: room,
    index: index,
    slots: slotsForRoom(all, room.id),
    day: day,
    now: now,
    onBook: widget.onBook == null ? null : () => widget.onBook!(room, day),
  );
}

/// เรียงแนวนอนบนจอกว้าง · ซ้อนแนวตั้งบนมือถือ (ความสูงเท่ากันในแถว)
class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.wide, required this.children});
  final bool wide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            w,
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: w),
          ],
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
  const _Hero({
    required this.freeNow,
    required this.total,
    required this.onBookNow,
    this.onMyBookings,
  });
  final int? freeNow;
  final int? total;
  final VoidCallback onBookNow;
  final VoidCallback? onMyBookings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        color: p.tileFor(0),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // แถบตัวอักษรแนวตั้งแบบภาพอ้างอิง (ตกแต่ง)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ExcludeSemantics(
              child: Container(
                width: 36,
                color: p.tileFor(3),
                alignment: Alignment.center,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    List.filled(3, S.brand.toUpperCase()).join('  ·  '),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: t.labelSmall?.copyWith(
                      color: p.onTile,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 60, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.heroEyebrow,
                  style: t.labelSmall?.copyWith(color: p.onTile),
                ),
                const SizedBox(height: 48),
                Text(
                  S.heroTitle,
                  style: t.displaySmall?.copyWith(color: p.onTile),
                ),
                const SizedBox(height: 12),
                if (freeNow != null && total != null)
                  Text(
                    S.heroFreeNow(freeNow!, total!),
                    style: t.bodyLarge?.copyWith(color: p.onTile),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LightPillButton(label: S.heroBookNow, onPressed: onBookNow),
                    if (onMyBookings != null)
                      LightPillButton(
                        label: S.tabMine,
                        onPressed: onMyBookings,
                        outlined: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeTile extends StatelessWidget {
  const _SizeTile({
    required this.size,
    required this.index,
    required this.selected,
    required this.count,
    required this.onTap,
  });
  final RoomSize size;
  final int index;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final label = switch (size) {
      RoomSize.all => S.sizeAll,
      RoomSize.small => S.sizeSmall,
      RoomSize.medium => S.sizeMedium,
      RoomSize.large => S.sizeLarge,
    };
    final icon = switch (size) {
      RoomSize.all => Icons.apps_rounded,
      RoomSize.small => Icons.person_outline,
      RoomSize.medium => Icons.groups_outlined,
      RoomSize.large => Icons.co_present_outlined,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: S.filterBy(label),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: p.tileFor(index),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    count == null ? '' : S.roomsCount(count!),
                    style: t.bodySmall?.copyWith(color: p.onTile),
                  ),
                ),
                Expanded(
                  child: Icon(
                    icon,
                    size: 56,
                    color: p.onTile.withValues(alpha: 0.9),
                  ),
                ),
                OutlinePill(label, filled: selected),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.index,
    required this.title,
    required this.action,
    required this.onTap,
  });
  final int index;
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: p.tileFor(index),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.headlineMedium?.copyWith(color: p.onTile),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: LightPillButton(
              label: action,
              onPressed: onTap,
              outlined: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดห้องแบบการ์ดสินค้าในภาพอ้างอิง: ป้าย beige · บล็อกสีห้อง · ชื่อตัวหนา · แถบเวลา (แทนจุดสี) · จำนวนคนชิดขวา (ตำแหน่งราคา)
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
    const tabular = [FontFeature.tabularFigures()];

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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: p.tileFor(index),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  Align(alignment: Alignment.topLeft, child: status),
                  Center(child: OutlinePill(room.name)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(room.name, style: t.titleMedium)),
                      const SizedBox(width: 8),
                      Text(
                        S.capacity(room.capacity),
                        style: t.titleMedium?.copyWith(fontFeatures: tabular),
                      ),
                    ],
                  ),
                  if (room.floor != null || room.equipment.isNotEmpty)
                    Text(
                      [?room.floor, ...room.equipment].join(' · '),
                      style: t.bodySmall,
                    ),
                  const SizedBox(height: 14),
                  DayTimeline(
                    day: day,
                    now: isToday ? now : null,
                    busy: [
                      for (final s in slots.where((s) => !s.isMine))
                        (s.start, s.end),
                    ],
                    mine: [
                      for (final s in slots.where((s) => s.isMine))
                        (s.start, s.end),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                              color: p.badge,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${s.isMine ? S.mine : S.busyLabel} ${timeRange(s.start, s.end)}',
                              style: t.bodySmall?.copyWith(
                                color: p.onBadge,
                                fontFeatures: tabular,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (onBook != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onBook,
                        child: Text(
                          '${S.bookRoom(room.name)} · ${dayLabel(day, now)}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
