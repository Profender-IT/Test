import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

/// หัวข้อ section แบบตัวเล็กเว้นระยะ + ขีดเส้นใต้
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

/// ป้ายสถานะทรงแคปซูล (ไอคอน + ข้อความ · ไม่พึ่งสีอย่างเดียว)
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
        color: p.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
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
        padding: const EdgeInsets.all(20),
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

/// ส่วนท้ายสีเข้ม
class DarkFooter extends StatelessWidget {
  const DarkFooter(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      color: p.strip,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: p.onStrip),
      ),
    );
  }
}
