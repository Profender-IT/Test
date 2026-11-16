import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/strings.dart';
import '../../router.dart';
import '../../supabase/providers.dart';
import '../../widgets/ui.dart';
import '../my_bookings/my_bookings_page.dart';
import '../rooms/rooms_page.dart';

/// โครงหน้าหลัก (ตามภาพอ้างอิง): แถบประกาศสีเข้ม → header ขาวมุมโค้ง
/// จอกว้าง: เมนูกลาง header · มือถือ: แถบนำทางล่าง (ui-ux-pro-max: bottom-nav-limit ≤ 5)
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, this.tab = 0});

  final int tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goTab(int i) => context.go(i == 0 ? Routes.home : Routes.myBookings);

    return LayoutBuilder(
      builder: (context, c) {
        final compact = screenSizeOf(c.maxWidth) == ScreenSize.compact;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const AnnounceStrip(S.announce),
                PillHeader(
                  title: tab == 0 || !compact ? S.appTitle : S.tabMine,
                  nav: compact
                      ? const []
                      : [
                          HeaderNavLink(
                            label: S.tabRooms,
                            selected: tab == 0,
                            onTap: () => goTab(0),
                          ),
                          HeaderNavLink(
                            label: S.tabMine,
                            selected: tab == 1,
                            onTap: () => goTab(1),
                          ),
                        ],
                  actions: [
                    IconButton(
                      tooltip: S.logout,
                      icon: const Icon(Icons.logout),
                      onPressed: () =>
                          ref.read(supabaseClientProvider).auth.signOut(),
                    ),
                  ],
                ),
                Expanded(
                  child: IndexedStack(
                    index: tab,
                    children: [
                      RoomsPage(
                        onBook: (room, day) =>
                            context.push(Routes.book(room.id, day)),
                        onMyBookings: () => goTab(1),
                      ),
                      MyBookingsPage(onBrowseRooms: () => goTab(0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: tab,
                  onDestinationSelected: goTab,
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
                )
              : null,
        );
      },
    );
  }
}
