import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/card/app_card.dart';
import '../../components/navigation/app_tab_bar.dart';
import '../../providers/color_provider.dart';
import '../../providers/financial_data_provider.dart';
import '../settings/settings_page.dart';
import 'home_providers.dart';

const _bottomNavigationHeight = 112.0;
const _balanceChartHeight = 64.0;
const _balanceChartStrokeWidth = 2.0;

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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _HomeTab(),
              _PlaceholderTab(label: 'Cards'),
              SettingsContent(showBackButton: false),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppTabBar(
        selectedIndex: selectedTabIndex,
        onSelected: ref.read(homeTabIndexProvider.notifier).setIndex,
        items: _homeTabItems,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Align(alignment: Alignment.topCenter, child: _BalanceCard()),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialData = ref.watch(financialDataProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final balanceCardColor = ref.watch(appPrimary300ColorProvider);
    final balanceIconColor = ref.watch(appPrimary400ColorProvider);
    final chartColor = ref.watch(appPrimary400ColorProvider);

    return AppCard(
      backgroundColor: balanceCardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCardHeader(
            changePercentage: _monthlyBalanceChangePercentage(
              financialData.monthlyData,
            ),
            iconColor: balanceIconColor,
            textColor: textColor,
            percentageTextColor: balanceCardColor,
          ),
          const SizedBox(height: 8),
          _BalanceAmount(
            amount: financialData.totalBalance,
            currencySymbol: financialData.accountData.currency.symbol,
            textColor: textColor,
          ),
          const SizedBox(height: 8),
          _BalanceChart(
            values: _dailyBalanceValues(financialData.monthlyData),
            color: chartColor,
          ),
        ],
      ),
    );
  }
}

class _BalanceCardHeader extends StatelessWidget {
  const _BalanceCardHeader({
    required this.changePercentage,
    required this.iconColor,
    required this.textColor,
    required this.percentageTextColor,
  });

  final double changePercentage;
  final Color iconColor;
  final Color textColor;
  final Color percentageTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        _BalanceChangePill(
          percentage: changePercentage,
          textColor: percentageTextColor,
        ),
      ],
    );
  }
}

class _BalanceChangePill extends StatelessWidget {
  const _BalanceChangePill({required this.percentage, required this.textColor});

  final double percentage;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final prefix = percentage >= 0 ? '+ ' : '- ';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.33),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$prefix${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BalanceAmount extends StatelessWidget {
  const _BalanceAmount({
    required this.amount,
    required this.currencySymbol,
    required this.textColor,
  });

  final double amount;
  final String currencySymbol;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$currencySymbol ${amount.toStringAsFixed(2)}',
      textAlign: TextAlign.start,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BalanceChart extends StatelessWidget {
  const _BalanceChart({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _balanceChartHeight,
      child: CustomPaint(
        painter: _BalanceChartPainter(values: values, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  const _BalanceChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _balanceChartStrokeWidth;

    if (values.length < 2) {
      _drawHorizontalLine(canvas, size, paint);
      return;
    }

    final minValue = values.reduce((min, value) => value < min ? value : min);
    final maxValue = values.reduce((max, value) => value > max ? value : max);
    if (minValue == maxValue) {
      _drawHorizontalLine(canvas, size, paint);
      return;
    }

    final chartHeight = size.height - paint.strokeWidth;
    final yOffset = paint.strokeWidth / 2;
    final xStep = size.width / (values.length - 1);
    final valueRange = maxValue - minValue;
    final path = Path();

    for (final point in values.indexed) {
      final x = point.$1 * xStep;
      final normalizedValue = (point.$2 - minValue) / valueRange;
      final y = yOffset + chartHeight - normalizedValue * chartHeight;

      if (point.$1 == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawHorizontalLine(Canvas canvas, Size size, Paint paint) {
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}

double _monthlyBalanceChangePercentage(List<MonthlyFinancialData> monthlyData) {
  if (monthlyData.isEmpty) {
    return 0;
  }

  final latestMonth = monthlyData.reduce((latest, monthData) {
    if (monthData.year != latest.year) {
      return monthData.year > latest.year ? monthData : latest;
    }

    return monthData.month > latest.month ? monthData : latest;
  });

  final previousMonthNumber = latestMonth.month == 1
      ? 12
      : latestMonth.month - 1;
  final previousMonthYear = latestMonth.month == 1
      ? latestMonth.year - 1
      : latestMonth.year;

  final previousMonth = monthlyData
      .where(
        (monthData) =>
            monthData.month == previousMonthNumber &&
            monthData.year == previousMonthYear,
      )
      .firstOrNull;

  if (previousMonth == null) {
    return 0;
  }

  final latestBalance = latestMonth.income - latestMonth.expenses;
  final previousBalance = previousMonth.income - previousMonth.expenses;
  if (previousBalance == 0) {
    return 0;
  }

  return ((latestBalance - previousBalance) / previousBalance.abs()) * 100;
}

List<double> _dailyBalanceValues(List<MonthlyFinancialData> monthlyData) {
  final entries = [for (final monthData in monthlyData) ...monthData.data]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final valuesByDay = <DateTime, double>{};

  for (final entry in entries) {
    final day = DateTime(
      entry.timestamp.year,
      entry.timestamp.month,
      entry.timestamp.day,
    );

    valuesByDay.update(
      day,
      (balance) => balance + entry.amount,
      ifAbsent: () => entry.amount,
    );
  }

  return valuesByDay.values.toList();
}
