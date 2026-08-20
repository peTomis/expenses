import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/card/app_card.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/color_provider.dart';
import '../../../providers/financial_data_provider.dart';
import '../../../providers/username_provider.dart';
import '../../transactions/transaction_detail_page.dart';
import '../../transactions/transactions_providers.dart';
import '../../transactions/widgets/transaction_row.dart';
import '../home_providers.dart';
import 'category_ring_chart.dart';

enum _Period { month, lastMonth, year }

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

class HomeOverview extends ConsumerStatefulWidget {
  const HomeOverview({super.key});

  @override
  ConsumerState<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends ConsumerState<HomeOverview> {
  _Period _period = _Period.month;

  void _goToTab(int index) {
    ref.read(homeTabIndexProvider.notifier).setIndex(index);
  }

  void _goToTransactions({String? filter}) {
    ref.read(transactionsFilterProvider.notifier).setFilter(filter);
    _goToTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final financialData = ref.watch(financialDataProvider);
    final allMonthlyData = financialData.monthlyData;
    final currencySymbol = financialData.accountData.currency.symbol;
    final username = ref
        .watch(usernameProvider)
        .whenOrNull(data: (username) => username);
    final now = DateTime.now();

    final latestMonth = _latestMonth(allMonthlyData);
    final periodData = switch (_period) {
      _Period.month =>
        latestMonth == null
            ? const <MonthlyFinancialData>[]
            : _monthData(allMonthlyData, latestMonth),
      _Period.lastMonth =>
        latestMonth == null
            ? const <MonthlyFinancialData>[]
            : _monthData(allMonthlyData, _previousMonth(latestMonth)),
      _Period.year =>
        latestMonth == null
            ? const <MonthlyFinancialData>[]
            : _yearData(allMonthlyData, latestMonth.year),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_monthNames[now.month - 1].toUpperCase()} ${now.year}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username == null ? 'Hey there' : 'Hey $username',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              _AvatarButton(onTap: () => _goToTab(4)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NetBalanceCard(
                  period: _period,
                  onPeriodChanged: (p) => setState(() => _period = p),
                  periodData: periodData,
                  allMonthlyData: allMonthlyData,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 14),
                AppCard(
                  maxWidth: double.infinity,
                  padding: const EdgeInsets.all(20),
                  title: 'Where it went',
                  titleColor: textColor,
                  titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  titleTrailing: GestureDetector(
                    onTap: () => _goToTab(3),
                    child: Text(
                      'All categories',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ref.watch(appPrimary50ColorProvider),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: CategoryRingChart(
                    monthlyData: allMonthlyData,
                    currencySymbol: currencySymbol,
                    onLegendTap: (uuid) => _goToTransactions(filter: uuid),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _goToTransactions(),
                      child: Text(
                        'See all',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ref.watch(appPrimary50ColorProvider),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RecentTransactionsCard(
                  monthlyData: allMonthlyData,
                  currencySymbol: currencySymbol,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarButton extends ConsumerWidget {
  const _AvatarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: textColor.withValues(alpha: 0.14)),
        ),
        child: Icon(Icons.person_outline, color: textColor, size: 20),
      ),
    );
  }
}

class _NetBalanceCard extends ConsumerWidget {
  const _NetBalanceCard({
    required this.period,
    required this.onPeriodChanged,
    required this.periodData,
    required this.allMonthlyData,
    required this.currencySymbol,
  });

  final _Period period;
  final ValueChanged<_Period> onPeriodChanged;
  final List<MonthlyFinancialData> periodData;
  final List<MonthlyFinancialData> allMonthlyData;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final accent = ref.watch(appPrimary300ColorProvider);

    final income = periodData.fold<double>(0, (a, m) => a + m.income);
    final expense = periodData.fold<double>(0, (a, m) => a + m.expenses);
    final net = income - expense;
    final changePct = _monthlyBalanceChangePercentage(allMonthlyData);

    return AppCard(
      maxWidth: double.infinity,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NET THIS MONTH',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              _ChangePill(percentage: changePct, accent: accent),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencySymbol,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                net.toStringAsFixed(2),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InOutColumn(
                label: 'IN',
                amount: income,
                color: const Color(0xFF9CCC65),
              ),
              Container(
                width: 1,
                height: 30,
                color: textColor.withValues(alpha: 0.12),
                margin: const EdgeInsets.symmetric(horizontal: 26),
              ),
              _InOutColumn(
                label: 'OUT',
                amount: expense,
                color: const Color(0xFFFF7043),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: _dailyBalanceValues(periodData),
                color: accent,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PeriodChip(
                label: 'This month',
                selected: period == _Period.month,
                accent: accent,
                textColor: textColor,
                onTap: () => onPeriodChanged(_Period.month),
              ),
              const SizedBox(width: 6),
              _PeriodChip(
                label: 'Last month',
                selected: period == _Period.lastMonth,
                accent: accent,
                textColor: textColor,
                onTap: () => onPeriodChanged(_Period.lastMonth),
              ),
              const SizedBox(width: 6),
              _PeriodChip(
                label:
                    (_latestMonth(allMonthlyData)?.year ?? DateTime.now().year)
                        .toString(),
                selected: period == _Period.year,
                accent: accent,
                textColor: textColor,
                onTap: () => onPeriodChanged(_Period.year),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InOutColumn extends StatelessWidget {
  const _InOutColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '€ ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChangePill extends ConsumerWidget {
  const _ChangePill({required this.percentage, required this.accent});

  final double percentage;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefix = percentage >= 0 ? '+ ' : '- ';
    final foreground = ref.watch(appPrimary50ColorProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: foreground,
            ),
            const SizedBox(width: 5),
            Text(
              '$prefix${percentage.abs().toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent : textColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends ConsumerWidget {
  const _RecentTransactionsCard({
    required this.monthlyData,
    required this.currencySymbol,
  });

  final List<MonthlyFinancialData> monthlyData;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryMap = {
      for (final c in ref.watch(categoryProvider)) c.uuid: c,
    };
    final entries = [for (final m in monthlyData) ...m.data]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = entries.take(4).toList();

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      maxWidth: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final entry in recent)
            TransactionRow(
              category: categoryMap[entry.category] ?? uncategorizedCategory,
              merchant: entry.merchant,
              subtitle:
                  '${(categoryMap[entry.category] ?? uncategorizedCategory).name} · '
                  '${entry.timestamp.day} ${_monthAbbrev[entry.timestamp.month - 1]}',
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
              dense: false,
            ),
        ],
      ),
    );
  }
}

_MonthKey? _latestMonth(List<MonthlyFinancialData> monthlyData) {
  if (monthlyData.isEmpty) {
    return null;
  }

  return monthlyData.map((m) => (month: m.month, year: m.year)).reduce((
    latest,
    current,
  ) {
    if (current.year != latest.year) {
      return current.year > latest.year ? current : latest;
    }
    return current.month > latest.month ? current : latest;
  });
}

typedef _MonthKey = ({int month, int year});

_MonthKey _previousMonth(_MonthKey month) {
  return month.month == 1
      ? (month: 12, year: month.year - 1)
      : (month: month.month - 1, year: month.year);
}

List<MonthlyFinancialData> _monthData(
  List<MonthlyFinancialData> monthlyData,
  _MonthKey month,
) {
  return monthlyData
      .where((m) => m.month == month.month && m.year == month.year)
      .toList();
}

List<MonthlyFinancialData> _yearData(
  List<MonthlyFinancialData> monthlyData,
  int year,
) {
  return monthlyData.where((m) => m.year == year).toList();
}

double _monthlyBalanceChangePercentage(List<MonthlyFinancialData> monthlyData) {
  final latest = _latestMonth(monthlyData);
  if (latest == null) {
    return 0;
  }

  final previous = _monthData(monthlyData, _previousMonth(latest)).firstOrNull;
  if (previous == null) {
    return 0;
  }

  final latestMonthData = _monthData(monthlyData, latest).firstOrNull;
  if (latestMonthData == null) {
    return 0;
  }

  final latestBalance = latestMonthData.income - latestMonthData.expenses;
  final previousBalance = previous.income - previous.expenses;
  if (previousBalance == 0) {
    return 0;
  }

  return ((latestBalance - previousBalance) / previousBalance.abs()) * 100;
}

List<double> _dailyBalanceValues(List<MonthlyFinancialData> monthlyData) {
  final entries = [for (final m in monthlyData) ...m.data]
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

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2;

    if (values.length < 2) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }

    final minValue = values.reduce((min, value) => value < min ? value : min);
    final maxValue = values.reduce((max, value) => value > max ? value : max);
    if (minValue == maxValue) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
