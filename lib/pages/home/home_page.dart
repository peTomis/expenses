import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/navigation/app_tab_bar.dart';
import '../categories/categories_page.dart';
import '../settings/settings_page.dart';
import '../transactions/transactions_page.dart';
import 'home_providers.dart';
import 'widgets/add_action_sheet.dart';
import 'widgets/home_overview.dart';

const _bottomNavigationHeight = AppTabBar.totalHeight;
const _addTabIndex = 2;

const _homeTabItems = [
  AppTabBarItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  AppTabBarItem(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Transactions',
  ),
  AppTabBarItem(
    icon: Icons.add_circle_outline,
    selectedIcon: Icons.add_circle,
    label: 'Add',
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
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: _bottomNavigationHeight),
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
