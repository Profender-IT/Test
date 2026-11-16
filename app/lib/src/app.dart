import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/env.dart';
import 'l10n/strings.dart';
import 'router.dart';

ThemeData _theme(Brightness b) => ThemeData(
  colorSchemeSeed: const Color(
    0xFF1F4E79,
  ), // TODO(ROOM-2): สร้าง theme จาก docs/design/ds/tokens.json
  brightness: b,
  useMaterial3: true,
);

class RoomBookingApp extends ConsumerWidget {
  const RoomBookingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: S.appTitle,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Env.appEnv == 'production'
          ? child!
          : Banner(
              message: Env.appEnv.toUpperCase(),
              location: BannerLocation.topEnd,
              child: child!,
            ),
    );
  }
}

/// แสดงเมื่อ build โดยไม่ได้ส่ง --dart-define ครบ หรือส่งกุญแจที่ห้ามใช้
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.problems});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appTitle,
      home: Scaffold(
        appBar: AppBar(title: const Text(S.configError)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final p in problems)
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(p),
              ),
          ],
        ),
      ),
    );
  }
}
