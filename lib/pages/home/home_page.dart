import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/navigation/app_tab_bar.dart';
import '../../providers/username_provider.dart';
import '../auth/auth_providers.dart';
import '../settings/settings_page.dart';
import 'home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final username = ref
        .watch(usernameProvider)
        .whenOrNull(data: (username) => username);
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 112),
          child: IndexedStack(
            index: selectedTabIndex,
            children: [
              const Center(child: Text('Transactions')),
              const Center(child: Text('Analytics')),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Signed in as ${username ?? user?.email ?? 'unknown user'}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const Center(child: Text('Cards')),
              const SettingsContent(showBackButton: false),
            ],
          ),
        ),
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
            icon: Icons.query_stats_outlined,
            selectedIcon: Icons.query_stats,
            label: 'Analytics',
          ),
          AppTabBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          AppTabBarItem(
            icon: Icons.credit_card_outlined,
            selectedIcon: Icons.credit_card,
            label: 'Cards',
          ),
          AppTabBarItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
