import 'package:flutter/material.dart';

/// Design system (ui-ux-pro-max: Minimalism & Swiss + serif display / sans body)
/// โทนสีจากภาพอ้างอิงของเจ้าของโปรเจค: พื้นครีมอุ่น, ตัวอักษรเกือบดำ, บล็อกสีโทนดิน, ปุ่มแคปซูล, การ์ดมุมโค้ง
/// ทุกคู่สีผ่าน WCAG AA ≥ 4.5:1 (ตรวจใน ROOM-5 · DESIGN.md §3) · ห้ามใช้สีตายตัวในหน้าจอ ให้อ่านจาก theme นี้
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.tiles,
    required this.onTile,
    required this.free,
    required this.busy,
    required this.strip,
    required this.onStrip,
  });

  final Color background;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;

  /// บล็อกสีของห้อง (วนตามลำดับห้อง) · ตัวอักษรบนบล็อกใช้ [onTile]
  final List<Color> tiles;
  final Color onTile;

  /// สถานะว่าง / ไม่ว่าง (ใช้คู่กับไอคอน + ข้อความเสมอ ไม่ใช้สีอย่างเดียว)
  final Color free;
  final Color busy;

  /// แถบประกาศด้านบน / ส่วนท้ายสีเข้ม
  final Color strip;
  final Color onStrip;

  static const light = AppPalette(
    background: Color(0xFFEDEAE4),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF1C1B19),
    muted: Color(0xFF5C5853),
    line: Color(0xFFD9D4CC),
    tiles: [
      Color(0xFF4F6A80),
      Color(0xFF584D49),
      Color(0xFF8A615B),
      Color(0xFF5D6F60),
    ],
    onTile: Color(0xFFFFFFFF),
    free: Color(0xFF2F6B3F),
    busy: Color(0xFFA23B2C),
    strip: Color(0xFF1C1B19),
    onStrip: Color(0xFFEDEAE4),
  );

  static const dark = AppPalette(
    background: Color(0xFF171615),
    card: Color(0xFF24221F),
    ink: Color(0xFFEDEAE4),
    muted: Color(0xFFB5AFA7),
    line: Color(0xFF3A3733),
    tiles: [
      Color(0xFF4F6A80),
      Color(0xFF584D49),
      Color(0xFF8A615B),
      Color(0xFF5D6F60),
    ],
    onTile: Color(0xFFFFFFFF),
    free: Color(0xFF8FD19E),
    busy: Color(0xFFF2A093),
    strip: Color(0xFF0E0D0C),
    onStrip: Color(0xFFEDEAE4),
  );

  Color tileFor(int index) => tiles[index % tiles.length];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      t < 0.5 ? this : (other as AppPalette? ?? this);
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

const _serif = 'NotoSerifThai';
const _sans = 'Sarabun';

ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? AppPalette.light : AppPalette.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.tiles.first,
        brightness: brightness,
      ).copyWith(
        primary: p.ink,
        onPrimary: p.background,
        surface: p.card,
        onSurface: p.ink,
        onSurfaceVariant: p.muted,
        outline: p.line,
        outlineVariant: p.line,
        error: p.busy,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _sans,
  );

  final text = base.textTheme
      .apply(bodyColor: p.ink, displayColor: p.ink)
      .copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontFamily: _serif,
          fontWeight: FontWeight.w400,
          height: 1.15,
          color: p.ink,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontFamily: _serif,
          fontWeight: FontWeight.w400,
          height: 1.2,
          color: p.ink,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontFamily: _serif,
          fontWeight: FontWeight.w400,
          color: p.ink,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.5,
          color: p.ink,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.5,
          color: p.ink,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.45,
          color: p.muted,
        ),
        // ป้ายเล็กหัวข้อ section · ภาษาไทยห้ามเว้นระยะมาก (สระ/วรรณยุกต์แยกจากพยัญชนะ)
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );

  const pill = StadiumBorder();
  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    textTheme: text,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.ink,
        foregroundColor: p.background,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: pill,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: p.ink),
        shape: pill,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(48, 48),
        shape: pill,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: pill,
      side: BorderSide(color: p.line),
      backgroundColor: p.card,
      selectedColor: p.ink,
      labelStyle: text.labelLarge?.copyWith(color: p.ink),
      secondaryLabelStyle: text.labelLarge?.copyWith(color: p.background),
      checkmarkColor: p.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.ink, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: p.background,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelMedium?.copyWith(color: p.ink),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.strip,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.onStrip),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
