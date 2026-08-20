import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/navigation/app_tab_bar.dart';
import '../categories/categories_page.dart';
import '../settings/settings_page.dart';
import '../transactions/transactions_page.dart';
import 'home_providers.dart';
import 'widgets/add_action_sheet.dart';
import 'widgets/home_overview.dart';

const _addTabIndex = 2;

const _homeTabItems = [
  AppTabBarItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  AppTabBarItem(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Transactions',
  ),
  AppTabBarItem(
    icon: Icons.add,
    selectedIcon: Icons.add,
    label: 'Add',
    isAccent: true,
  ),
  AppTabBarItem(
    icon: Icons.donut_small_outlined,
    selectedIcon: Icons.donut_small,
    label: 'Categories',
  ),
  AppTabBarItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      // Content scrolls all the way behind the floating, translucent tab
      // bar (each page carries its own generous bottom padding so its
      // last item can still be scrolled clear of the bar's icons) rather
      // than stopping short at a fixed reserved gap.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: selectedTabIndex,
          children: const [
            HomeOverview(),
            TransactionsPage(),
            SizedBox.shrink(),
            CategoriesPage(),
            SettingsContent(showBackButton: false),
          ],
        ),
      ),
      bottomNavigationBar: AppTabBar(
        selectedIndex: selectedTabIndex,
        onSelected: (index) {
          if (index == _addTabIndex) {
            showAddActionSheet(context);
            return;
          }
          ref.read(homeTabIndexProvider.notifier).setIndex(index);
        },
        items: _homeTabItems,
      ),
    );
  }
}
