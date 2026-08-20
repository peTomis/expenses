import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/financial_data_provider.dart';
import 'transaction_detail_page.dart';
import 'transactions_providers.dart';
import 'widgets/transaction_row.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _filter;
  bool _consumedInitialFilter = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_consumedInitialFilter) {
      _consumedInitialFilter = true;
      final incoming = ref.read(transactionsFilterProvider);
      if (incoming != null) {
        _filter = incoming;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(transactionsFilterProvider.notifier).setFilter(null);
          }
        });
      }
    }

    final textColor = ref.watch(appPrimaryTextColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);
    final accent = ref.watch(appPrimary300ColorProvider);
    final financialData = ref.watch(financialDataProvider);
    final currencySymbol = financialData.accountData.currency.symbol;
    final categories = ref.watch(categoryProvider);
    final categoryMap = {for (final c in categories) c.uuid: c};
    final now = DateTime.now();

    var entries = [for (final m in financialData.monthlyData) ...m.data];
    if (_filter != null) {
      entries = entries.where((e) => e.category == _filter).toList();
    }
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      entries = entries.where((e) => e.merchant.toLowerCase().contains(query)).toList();
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final groups = <DateTime, List<FinancialDataEntry>>{};
    for (final entry in entries) {
      final day = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      groups.putIfAbsent(day, () => []).add(entry);
    }
    final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: textColor.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_monthAbbrev[now.month - 1]} ${now.year}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: textColor.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: textColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textColor, fontSize: 13.5),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Search merchant or item',
                            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == null,
                        color: accent,
                        textColor: textColor,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final category in categories) ...[
                        const SizedBox(width: 7),
                        _FilterChip(
                          label: category.name,
                          icon: category.icon,
                          selected: _filter == category.uuid,
                          color: accent,
                          textColor: textColor,
                          onTap: () => setState(() => _filter = category.uuid),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                    itemCount: sortedDays.length,
                    itemBuilder: (context, index) {
                      final day = sortedDays[index];
                      final dayEntries = groups[day]!;
                      final net = dayEntries.fold<double>(0, (a, e) => a + e.amount);
                      final isToday =
                          day.year == now.year && day.month == now.month && day.day == now.day;

                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${isToday ? 'TODAY · ' : ''}${day.day} '
                                      '${_monthNames[day.month - 1].toUpperCase()}',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: textColor.withValues(alpha: 0.42),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${net < 0 ? '− ' : '+ '}$currencySymbol '
                                    '${net.abs().toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: textColor.withValues(alpha: 0.42),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: textColor.withValues(alpha: 0.08)),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                children: [
                                  for (final entry in dayEntries)
                                    TransactionRow(
                                      dense: true,
                                      category:
                                          categoryMap[entry.category] ?? uncategorizedCategory,
                                      merchant: entry.merchant,
                                      subtitle:
                                          (categoryMap[entry.category] ?? uncategorizedCategory)
                                              .name +
                                          (entry.items != null && entry.items!.isNotEmpty
                                              ? ' · ${entry.items!.length} items'
                                              : ''),
                                      amountLabel:
                                          '${entry.amount < 0 ? '− ' : '+ '}$currencySymbol '
                                          '${entry.amount.abs().toStringAsFixed(2)}',
                                      amountColor: entry.amount < 0
                                          ? Colors.white
                                          : const Color(0xFF9CCC65),
                                      scanned: entry.scanned,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransactionDetailPage(entry: entry),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.black,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : textColor.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
