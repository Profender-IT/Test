import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../supabase/providers.dart';
import '../profile/profile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(myProfileProvider);

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(S.myProfile, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: profile.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const ListTile(title: Text(S.loadFailed)),
              data: (p) => ListTile(
                key: const Key('my-profile'),
                title: Text(user?.email ?? ''),
                subtitle: Text(
                  '${S.displayName}: ${p?.displayName ?? S.notSet}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(S.roomsComingSoon),
        ],
      ),
    );
  }
}
