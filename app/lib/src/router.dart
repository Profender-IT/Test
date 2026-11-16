import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_page.dart';
import 'features/booking/book_page.dart';
import 'features/home/home_shell.dart';
import 'supabase/providers.dart';

abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static String book(String roomId, DateTime day) =>
      '/rooms/$roomId/book?day=${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

/// หน้าไหนต้องล็อกอิน: ทุกหน้ายกเว้น /login
String? authRedirect({required bool loggedIn, required String location}) {
  final atLogin = location == Routes.login;
  if (!loggedIn) return atLogin ? null : Routes.login;
  return atLogin ? Routes.home : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      loggedIn: ref.read(supabaseClientProvider).auth.currentSession != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.home, builder: (_, _) => const HomeShell()),
      GoRoute(
        path: '/rooms/:id/book',
        builder: (context, state) => BookPage(
          roomId: state.pathParameters['id']!,
          initialDay:
              DateTime.tryParse(state.uri.queryParameters['day'] ?? '') ??
              DateTime.now(),
          onDone: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
    ],
  );
});
