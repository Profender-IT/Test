import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/strings.dart';
import '../../router.dart';
import '../../supabase/providers.dart';
import '../my_bookings/my_bookings_page.dart';
import '../rooms/rooms_page.dart';

/// โครงหน้าหลักหลังล็อกอิน: แถบบน + แท็บล่าง 2 แท็บ (ห้อง / การจองของฉัน)
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, this.tab = 0});

  final int tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tab == 0 ? S.appTitle : S.tabMine),
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
        child: IndexedStack(
          index: tab,
          children: [
            RoomsPage(
              onBook: (room, day) => context.push(Routes.book(room.id, day)),
            ),
            MyBookingsPage(onBrowseRooms: () => context.go(Routes.home)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) =>
            context.go(i == 0 ? Routes.home : Routes.myBookings),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: S.tabRooms,
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: S.tabMine,
          ),
        ],
      ),
    );
  }
}
