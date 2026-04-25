import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/navigation/app_tab_bar.dart';
import '../auth/auth_providers.dart';
import 'home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AuthException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedTabIndex,
        children: [
          const Center(child: Text('Transactions')),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Signed in as ${user?.email ?? 'unknown user'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Center(
            child: IconButton(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        selectedIndex: selectedTabIndex,
        onSelected: ref.read(homeTabIndexProvider.notifier).setIndex,
        items: const [
          AppTabBarItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Transactions',
          ),
          AppTabBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          AppTabBarItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
