import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ขนาดจอ (ui-ux-pro-max: breakpoint-consistency / container-width)
enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(double width) => width >= 1024
    ? ScreenSize.expanded
    : width >= 600
    ? ScreenSize.medium
    : ScreenSize.compact;

/// ระยะขอบซ้ายขวาให้เนื้อหากว้างไม่เกิน 1200
double gutterFor(double width) => width > 1232 ? (width - 1200) / 2 : 16;

/// แถบประกาศสีเข้มด้านบนสุด
class AnnounceStrip extends StatelessWidget {
  const AnnounceStrip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      color: p.strip,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: p.onStrip),
      ),
    );
  }
}

/// header สีขาวมุมโค้งลอยบนพื้นครีม: โลโก้ซ้าย · เมนูกลาง (จอกว้าง) · ไอคอนขวา
class PillHeader extends StatelessWidget {
  const PillHeader({
    super.key,
    required this.title,
    this.nav = const [],
    this.actions = const [],
    this.leading,
  });

  final String title;
  final List<Widget> nav;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) => Padding(
        padding: EdgeInsets.fromLTRB(
          gutterFor(c.maxWidth),
          12,
          gutterFor(c.maxWidth),
          8,
        ),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ?leading,
              Padding(
                padding: EdgeInsets.only(left: leading == null ? 12 : 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: t.titleLarge?.copyWith(
                      fontFamily: 'NotoSerifThai',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ...nav,
              if (nav.isNotEmpty) const Spacer(),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// ลิงก์เมนูกลาง header (จอกว้าง) · ตัวหนาเมื่ออยู่หน้านั้น
class HeaderNavLink extends StatelessWidget {
  const HeaderNavLink({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? p.ink : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(label, style: t.labelLarge?.copyWith(color: p.ink)),
        ),
      ),
    );
  }
}

/// หัวข้อ section แบบตัวเล็ก + ขีดเส้นใต้ (เช่น "BEST SELLERS" ในภาพอ้างอิง)
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.ink, width: 1.5)),
            ),
            child: Text(text, style: Theme.of(context).textTheme.labelSmall),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// ป้ายสถานะ beige ทรงแคปซูล (ไอคอน + ข้อความ · ไม่พึ่งสีอย่างเดียว)
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.badge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// ป้ายขอบขาวทรงแคปซูลบนบล็อกสี (แบบ "NEW ARRIVALS" ในภาพอ้างอิง)
class OutlinePill extends StatelessWidget {
  const OutlinePill(this.label, {super.key, this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? p.onTile : Colors.transparent,
        border: Border.all(color: p.onTile),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: filled ? p.ink : p.onTile),
      ),
    );
  }
}

/// ปุ่มขาวทรงแคปซูลบนพื้นสี (แบบ "SHOP MEN" ในภาพอ้างอิง)
class LightPillButton extends StatelessWidget {
  const LightPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: p.onTile,
              side: BorderSide(color: p.onTile),
            ),
            child: Text(label),
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: p.onTile,
              foregroundColor: p.ink,
            ),
            child: Text(label),
          );
  }
}

/// แถบเวลาทั้งวัน 07:00–21:00 แสดงช่วงไม่ว่าง (ภาพประกอบ · ข้อความช่วงเวลาอยู่ในชิปใต้แถบ)
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.day,
    required this.busy,
    required this.mine,
    this.now,
    this.startHour = 7,
    this.endHour = 21,
  });

  final DateTime day;

  /// ช่วงไม่ว่าง (start, end) ของคนอื่น และของเรา
  final List<(DateTime, DateTime)> busy;
  final List<(DateTime, DateTime)> mine;
  final DateTime? now;
  final int startHour;
  final int endHour;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final from = DateTime(day.year, day.month, day.day, startHour);
    final to = DateTime(day.year, day.month, day.day, endHour);
    final total = to.difference(from).inMinutes.toDouble();
    double frac(DateTime x) =>
        (x.difference(from).inMinutes / total).clamp(0.0, 1.0);

    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              Widget seg((DateTime, DateTime) r, Color color) {
                final l = frac(r.$1) * w;
                final r2 = frac(r.$2) * w;
                return Positioned(
                  left: l,
                  width: (r2 - l).clamp(2.0, w),
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(color: color),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.badge)),
                      for (final r in busy) seg(r, p.ink),
                      for (final r in mine) seg(r, p.free),
                      if (now != null &&
                          now!.isAfter(from) &&
                          now!.isBefore(to))
                        Positioned(
                          left: frac(now!) * w - 1,
                          width: 2,
                          top: 0,
                          bottom: 0,
                          child: ColoredBox(color: p.busy),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in [startHour, (startHour + endHour) ~/ 2, endHour])
                Text(
                  '${h.toString().padLeft(2, '0')}:00',
                  style: t.bodySmall?.copyWith(fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// การ์ดข้อมูลสั้นแบบหัวข้อเล็ก + เนื้อหา
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.labelSmall),
            const SizedBox(height: 12),
            Text(body, style: t.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// คอลัมน์ข้อความของ footer
class FooterColumn {
  const FooterColumn(this.title, this.lines);
  final String title;
  final List<String> lines;
}

/// ส่วนท้ายสีเข้มหลายคอลัมน์ + แถวล่าง (แบบภาพอ้างอิง) · ข้อความล้วน ไม่มีลิงก์ปลอม
class DarkFooter extends StatelessWidget {
  const DarkFooter({
    super.key,
    required this.columns,
    required this.bottom,
    this.action,
  });
  final List<FooterColumn> columns;
  final String bottom;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final head = t.labelSmall?.copyWith(color: p.onStrip);
    final body = t.bodySmall?.copyWith(
      color: p.onStrip.withValues(alpha: 0.85),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final g = gutterFor(c.maxWidth);
        final wide = screenSizeOf(c.maxWidth) != ScreenSize.compact;
        final cols = [
          for (final col in columns)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(col.title, style: head),
                  const SizedBox(height: 12),
                  for (final l in col.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l, style: body),
                    ),
                ],
              ),
            ),
        ];
        return Container(
          width: double.infinity,
          color: p.strip,
          padding: EdgeInsets.fromLTRB(g + 8, 40, g + 8, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final c in cols) Expanded(child: c)],
                )
              else
                ...cols,
              if (action != null) ...[action!, const SizedBox(height: 24)],
              Divider(color: p.onStrip.withValues(alpha: 0.25)),
              const SizedBox(height: 16),
              Text(bottom, style: body),
            ],
          ),
        );
      },
    );
  }
}
