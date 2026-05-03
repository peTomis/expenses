import 'dart:ui';

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
const _balanceCarouselHeight = 210.0;
const _balanceCarouselCardGap = 4.0;

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
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: _BalanceCardCarousel(),
      ),
    );
  }
}

class _BalanceCardCarousel extends ConsumerStatefulWidget {
  const _BalanceCardCarousel();

  @override
  ConsumerState<_BalanceCardCarousel> createState() =>
      _BalanceCardCarouselState();
}

class _BalanceCardCarouselState extends ConsumerState<_BalanceCardCarousel> {
  late final PageController _pageController;
  _MonthKey? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1, viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financialData = ref.watch(financialDataProvider);
    final availableMonths = _availableMonths(financialData.monthlyData);
    final availableYears = _availableYears(financialData.monthlyData);
    final selectedMonth = _effectiveSelectedMonth(
      financialData.monthlyData,
      _selectedMonth,
    );
    final selectedYear = _effectiveSelectedYear(
      financialData.monthlyData,
      _selectedYear,
    );
    final pages = _balanceCardPages(
      financialData.monthlyData,
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
    );
    final cardColors = [
      ref.watch(appPrimary300ColorProvider),
      ref.watch(appPrimary200ColorProvider),
      ref.watch(appPrimary400ColorProvider),
    ];
    final accentColors = [
      ref.watch(appPrimary400ColorProvider),
      ref.watch(appPrimary400ColorProvider),
      ref.watch(appPrimary200ColorProvider),
    ];
    const textColors = [Colors.white, Colors.black, Colors.white];

    return SizedBox(
      height: _balanceCarouselHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _balanceCarouselCardGap,
              ),
              child: _BalanceCard(
                title: page.title,
                monthlyData: page.monthlyData,
                currencySymbol: financialData.accountData.currency.symbol,
                backgroundColor: cardColors[index],
                accentColor: accentColors[index],
                textColor: textColors[index],
                titleAction: switch (index) {
                  0 => _PeriodChangeButton<_MonthKey>(
                    value: selectedMonth,
                    values: availableMonths,
                    labelFor: _monthLabel,
                    tooltip: 'Change month',
                    backgroundColor: accentColors[index],
                    textColor: textColors[index],
                    onSelected: (month) {
                      setState(() {
                        _selectedMonth = month;
                      });
                    },
                  ),
                  2 => _PeriodChangeButton<int>(
                    value: selectedYear,
                    values: availableYears,
                    labelFor: (year) => year.toString(),
                    tooltip: 'Change year',
                    backgroundColor: accentColors[index],
                    textColor: textColors[index],
                    onSelected: (year) {
                      setState(() {
                        _selectedYear = year;
                      });
                    },
                  ),
                  _ => null,
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({
    required this.title,
    required this.monthlyData,
    required this.currencySymbol,
    required this.backgroundColor,
    required this.accentColor,
    required this.textColor,
    this.titleAction,
  });

  final String title;
  final List<MonthlyFinancialData> monthlyData;
  final String currencySymbol;
  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;
  final Widget? titleAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = _totalBalance(monthlyData);

    return AppCard(
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCardHeader(
            title: title,
            titleAction: titleAction,
            changePercentage: _monthlyBalanceChangePercentage(monthlyData),
            iconColor: accentColor,
            textColor: textColor,
            percentageTextColor: backgroundColor,
          ),
          const SizedBox(height: 8),
          _BalanceAmount(
            amount: balance,
            currencySymbol: currencySymbol,
            textColor: textColor,
          ),
          const SizedBox(height: 8),
          _BalanceChart(
            values: _dailyBalanceValues(monthlyData),
            color: accentColor,
          ),
        ],
      ),
    );
  }
}

class _BalanceCardHeader extends StatelessWidget {
  const _BalanceCardHeader({
    required this.title,
    required this.changePercentage,
    required this.iconColor,
    required this.textColor,
    required this.percentageTextColor,
    this.titleAction,
  });

  final String title;
  final double changePercentage;
  final Color iconColor;
  final Color textColor;
  final Color percentageTextColor;
  final Widget? titleAction;

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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (titleAction != null) ...[
              const SizedBox(width: 8),
              titleAction!,
            ],
          ],
        ),
        _BalanceChangePill(
          percentage: changePercentage,
          backgroundColor: iconColor,
          textColor: percentageTextColor,
        ),
      ],
    );
  }
}

class _BalanceChangePill extends StatelessWidget {
  const _BalanceChangePill({
    required this.percentage,
    required this.backgroundColor,
    required this.textColor,
  });

  final double percentage;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final prefix = percentage >= 0 ? '+ ' : '- ';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha(128),
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

class _PeriodChangeButton<T> extends ConsumerWidget {
  const _PeriodChangeButton({
    required this.value,
    required this.values,
    required this.labelFor,
    required this.tooltip,
    required this.backgroundColor,
    required this.textColor,
    required this.onSelected,
  });

  final T? value;
  final List<T> values;
  final String Function(T value) labelFor;
  final String tooltip;
  final Color backgroundColor;
  final Color textColor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuColor = ref.watch(appPrimary500ColorProvider);
    final tapColor = ref.watch(appPrimary300ColorProvider);
    final selectedColor = ref.watch(appPrimary400ColorProvider);
    final selectedTextColor = ref.watch(appPrimary50ColorProvider);
    final menuTextColor = ref.watch(appPrimaryTextColorProvider);

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomStart,
        backgroundColor: WidgetStatePropertyAll(menuColor),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(4),
        fixedSize: const WidgetStatePropertyAll(Size.fromWidth(148)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: [
        for (final itemValue in values)
          SizedBox(
            width: 148,
            height: 44,
            child: MenuItemButton(
              onPressed: () => onSelected(itemValue),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  itemValue == value ? selectedColor : menuColor,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  itemValue == value ? selectedTextColor : menuTextColor,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12),
                ),
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: itemValue == value
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                overlayColor: WidgetStatePropertyAll(
                  tapColor.withValues(alpha: 0.72),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labelFor(itemValue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
      builder: (context, controller, child) {
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: values.isEmpty
                  ? null
                  : controller.isOpen
                  ? controller.close
                  : controller.open,
              borderRadius: BorderRadius.circular(8),
              overlayColor: WidgetStatePropertyAll(
                tapColor.withValues(alpha: 0.72),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    controller.isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textColor,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

typedef _MonthKey = ({int month, int year});

class _BalanceCardPageData {
  const _BalanceCardPageData({required this.title, required this.monthlyData});

  final String title;
  final List<MonthlyFinancialData> monthlyData;
}

List<_BalanceCardPageData> _balanceCardPages(
  List<MonthlyFinancialData> monthlyData, {
  required _MonthKey? selectedMonth,
  required int? selectedYear,
}) {
  final lastMonth = _lastMonthKey(monthlyData);
  final latestYear = monthlyData.isEmpty
      ? null
      : _latestMonth(monthlyData).year;

  return [
    _BalanceCardPageData(
      title: selectedMonth == null || selectedMonth == lastMonth
          ? 'Last month'
          : _monthLabel(selectedMonth),
      monthlyData: selectedMonth == null
          ? const []
          : _monthData(monthlyData, selectedMonth),
    ),
    _BalanceCardPageData(title: 'Balance', monthlyData: monthlyData),
    _BalanceCardPageData(
      title: selectedYear == null || selectedYear == latestYear
          ? 'This year'
          : selectedYear.toString(),
      monthlyData: selectedYear == null
          ? const []
          : _yearData(monthlyData, selectedYear),
    ),
  ];
}

_MonthKey? _lastMonthKey(List<MonthlyFinancialData> monthlyData) {
  if (monthlyData.isEmpty) {
    return null;
  }

  final now = DateTime.now();
  final lastMonthNumber = now.month == 1 ? 12 : now.month - 1;
  final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

  return (month: lastMonthNumber, year: lastMonthYear);
}

_MonthKey? _effectiveSelectedMonth(
  List<MonthlyFinancialData> monthlyData,
  _MonthKey? selectedMonth,
) {
  if (monthlyData.isEmpty) {
    return null;
  }

  final availableMonths = _availableMonths(monthlyData);
  if (selectedMonth != null && availableMonths.contains(selectedMonth)) {
    return selectedMonth;
  }

  final lastMonth = _lastMonthKey(monthlyData);
  if (lastMonth != null && availableMonths.contains(lastMonth)) {
    return lastMonth;
  }

  return availableMonths.firstOrNull;
}

int? _effectiveSelectedYear(List<MonthlyFinancialData> monthlyData, int? year) {
  if (monthlyData.isEmpty) {
    return null;
  }

  final availableYears = _availableYears(monthlyData);
  if (year != null && availableYears.contains(year)) {
    return year;
  }

  final currentYear = DateTime.now().year;
  if (availableYears.contains(currentYear)) {
    return currentYear;
  }

  return _latestMonth(monthlyData).year;
}

List<MonthlyFinancialData> _monthData(
  List<MonthlyFinancialData> monthlyData,
  _MonthKey month,
) {
  return monthlyData
      .where(
        (monthData) =>
            monthData.month == month.month && monthData.year == month.year,
      )
      .toList();
}

List<MonthlyFinancialData> _yearData(
  List<MonthlyFinancialData> monthlyData,
  int year,
) {
  return monthlyData.where((monthData) => monthData.year == year).toList();
}

List<_MonthKey> _availableMonths(List<MonthlyFinancialData> monthlyData) {
  return [
    for (final monthData in monthlyData)
      (month: monthData.month, year: monthData.year),
  ]..sort((a, b) {
    final yearComparison = b.year.compareTo(a.year);
    if (yearComparison != 0) {
      return yearComparison;
    }

    return b.month.compareTo(a.month);
  });
}

List<int> _availableYears(List<MonthlyFinancialData> monthlyData) {
  return {for (final monthData in monthlyData) monthData.year}.toList()
    ..sort((a, b) => b.compareTo(a));
}

String _monthLabel(_MonthKey month) {
  const monthNames = [
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

  return '${monthNames[month.month - 1]} ${month.year}';
}

MonthlyFinancialData _latestMonth(List<MonthlyFinancialData> monthlyData) {
  return monthlyData.reduce((latest, monthData) {
    if (monthData.year != latest.year) {
      return monthData.year > latest.year ? monthData : latest;
    }

    return monthData.month > latest.month ? monthData : latest;
  });
}

double _totalBalance(List<MonthlyFinancialData> monthlyData) {
  return monthlyData.fold<double>(
    0,
    (total, monthData) => total + monthData.income - monthData.expenses,
  );
}

double _monthlyBalanceChangePercentage(List<MonthlyFinancialData> monthlyData) {
  if (monthlyData.isEmpty) {
    return 0;
  }

  final latestMonth = _latestMonth(monthlyData);
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
