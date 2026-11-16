import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../supabase/providers.dart';

import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../rooms/rooms_page.dart';

/// โครงหน้าหลักหลังล็อกอิน: แถบบน + เนื้อหา (ROOM-7 เพิ่มแท็บ "การจองของฉัน")
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.appTitle),
        actions: [
          IconButton(
            tooltip: S.logout,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RoomsPage(
          onBook: (room, day) => context.push(Routes.book(room.id, day)),
        ),
      ),
    );
  }
}
