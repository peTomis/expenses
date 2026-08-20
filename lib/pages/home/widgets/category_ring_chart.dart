import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/category_provider.dart';
import '../../../providers/color_provider.dart';
import '../../../providers/financial_data_provider.dart';

class CategoryExpenseData {
  const CategoryExpenseData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.count,
  });

  final FinancialCategory category;
  final double amount;
  final double percentage;
  final Color color;
  final int count;
}

/// Shared category-expense aggregation, used by [CategoryRingChart] (ring +
/// legend) and the Categories tab (rows + segmented bar) so both read the
/// exact same numbers.
List<CategoryExpenseData> computeCategoryExpenseTotals(
  List<MonthlyFinancialData> monthlyData,
  List<FinancialCategory> categories,
) {
  final categoryMap = {for (final c in categories) c.uuid: c};
  final totals = <String, double>{};
  final counts = <String, int>{};

  for (final monthData in monthlyData) {
    for (final entry in monthData.data) {
      if (entry.amount < 0) {
        final key =
            entry.category != null && categoryMap.containsKey(entry.category)
            ? entry.category!
            : uncategorizedCategory.uuid;
        totals.update(
          key,
          (v) => v + entry.amount.abs(),
          ifAbsent: () => entry.amount.abs(),
        );
        counts.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    }
  }

  if (totals.isEmpty) {
    return const [];
  }

  final sum = totals.values.fold<double>(0, (a, b) => a + b);
  final sorted = totals.entries.toList()
    ..sort((a, b) {
      if (a.key == uncategorizedCategory.uuid) return 1;
      if (b.key == uncategorizedCategory.uuid) return -1;
      return b.value.compareTo(a.value);
    });

  return [
    for (final entry in sorted)
      CategoryExpenseData(
        category: entry.key == uncategorizedCategory.uuid
            ? uncategorizedCategory
            : categoryMap[entry.key]!,
        amount: entry.value,
        percentage: entry.value / sum * 100,
        color: entry.key == uncategorizedCategory.uuid
            ? Colors.transparent
            : categoryMap[entry.key]!.color,
        count: counts[entry.key] ?? 0,
      ),
  ];
}

class _RingSegmentData {
  const _RingSegmentData({
    required this.item,
    required this.startAngle,
    required this.sweepAngle,
  });

  final CategoryExpenseData item;
  final double startAngle;
  final double sweepAngle;
}

/// The Home tab's "Where it went" card body: a donut ring with the total
/// spent in its center, plus a readable legend of the top categories next
/// to it (the design replaces per-arc icon overlays with this legend).
class CategoryRingChart extends ConsumerWidget {
  const CategoryRingChart({
    super.key,
    required this.monthlyData,
    required this.currencySymbol,
    this.legendCount = 4,
    this.onLegendTap,
  });

  final List<MonthlyFinancialData> monthlyData;
  final String currencySymbol;
  final int legendCount;
  final ValueChanged<String>? onLegendTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final data = computeCategoryExpenseTotals(monthlyData, categories);

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = data.fold<double>(0, (a, item) => a + item.amount);
    final textColor = ref.watch(appPrimaryTextColorProvider);

    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: _RingChartWidget(
              data: data,
              total: total,
              currencySymbol: currencySymbol,
              textColor: textColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in data.take(legendCount))
                  _LegendRow(
                    item: item,
                    textColor: textColor,
                    onTap: onLegendTap == null
                        ? null
                        : () => onLegendTap!(item.category.uuid),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.item, required this.textColor, this.onTap});

  final CategoryExpenseData item;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                item.category.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${item.percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingChartWidget extends StatelessWidget {
  const _RingChartWidget({
    required this.data,
    required this.total,
    required this.currencySymbol,
    required this.textColor,
  });

  final List<CategoryExpenseData> data;
  final double total;
  final String currencySymbol;
  final Color textColor;

  List<_RingSegmentData> _buildSegments(List<CategoryExpenseData> items) {
    final segments = <_RingSegmentData>[];
    var startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final item in items) {
      final sweep = (item.percentage / 100) * 2 * math.pi;
      final effectiveSweep = (sweep - gap).clamp(0.0, 2 * math.pi);
      if (effectiveSweep > 0) {
        segments.add(
          _RingSegmentData(
            item: item,
            startAngle: startAngle + gap / 2,
            sweepAngle: effectiveSweep,
          ),
        );
      }
      startAngle += sweep;
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size = math.min(w, h);
        final center = Offset(w / 2, h / 2);
        final outerRadius = size / 2 - 8;
        final innerRadius = outerRadius * 0.62;
        final segments = _buildSegments(data);

        return Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _RingChartPainter(
                segments: segments,
                center: center,
                outerRadius: outerRadius,
                innerRadius: innerRadius,
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$currencySymbol ${total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SPENT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RingChartPainter extends CustomPainter {
  const _RingChartPainter({
    required this.segments,
    required this.center,
    required this.outerRadius,
    required this.innerRadius,
  });

  final List<_RingSegmentData> segments;
  final Offset center;
  final double outerRadius;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final arcRadius = (outerRadius + innerRadius) / 2;
    final strokeWidth = outerRadius - innerRadius;

    for (final seg in segments) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        seg.startAngle,
        seg.sweepAngle,
        false,
        Paint()
          ..color = seg.item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter old) =>
      old.segments != segments ||
      old.center != center ||
      old.outerRadius != outerRadius ||
      old.innerRadius != innerRadius;
}
