import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/navigation/app_tab_bar.dart';
import '../../providers/financial_data_provider.dart';
import '../settings/settings_page.dart';
import 'home_providers.dart';
import 'widgets/add_entry_sheet.dart';
import 'widgets/balance_carousel.dart';

const _bottomNavigationHeight = AppTabBar.totalHeight;

const _homeTabItems = [
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
              _PlaceholderTab(label: 'Transactions'),
              _PlaceholderTab(label: 'Analytics'),
              HomeTab(),
              _PlaceholderTab(label: 'Cards'),
              SettingsContent(showBackButton: false),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppTabBar(
        selectedIndex: selectedTabIndex,
        onSelected: ref.read(homeTabIndexProvider.notifier).setIndex,
        onDoubleSelected: (index) {
          if (index == 4) {
            return;
          }

          _showAddEntrySheet(context, ref);
        },
        items: _homeTabItems,
      ),
    );
  }
}

Future<void> _showAddEntrySheet(BuildContext context, WidgetRef ref) {
  final accountData = ref.read(financialDataProvider).accountData;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddFinancialDataEntrySheet(
      account: accountData.account.first,
      currencySymbol: accountData.currency.symbol,
    ),
  );
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}
