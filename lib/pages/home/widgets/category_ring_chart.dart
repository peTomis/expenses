import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/category_provider.dart';
import '../../../providers/financial_data_provider.dart';

class _CategoryExpenseData {
  const _CategoryExpenseData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final FinancialCategory category;
  final double amount;
  final double percentage;
  final Color color;
}

class _RingSegmentData {
  const _RingSegmentData({
    required this.item,
    required this.startAngle,
    required this.sweepAngle,
    required this.midAngle,
  });

  final _CategoryExpenseData item;
  final double startAngle;
  final double sweepAngle;
  final double midAngle;
}

class CategoryRingChart extends ConsumerWidget {
  const CategoryRingChart({super.key, required this.monthlyData});

  final List<MonthlyFinancialData> monthlyData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final categoryMap = {for (final c in categories) c.uuid: c};
    final expensesByCategory = <String, double>{};

    for (final monthData in monthlyData) {
      for (final entry in monthData.data) {
        if (entry.amount < 0) {
          final key =
              entry.category != null && categoryMap.containsKey(entry.category)
              ? entry.category!
              : uncategorizedCategory.uuid;
          expensesByCategory.update(
            key,
            (v) => v + entry.amount.abs(),
            ifAbsent: () => entry.amount.abs(),
          );
        }
      }
    }

    if (expensesByCategory.isEmpty) return const SizedBox.shrink();

    final total = expensesByCategory.values.fold<double>(0, (a, b) => a + b);

    final sorted = expensesByCategory.entries.toList()
      ..sort((a, b) {
        if (a.key == uncategorizedCategory.uuid) return 1;
        if (b.key == uncategorizedCategory.uuid) return -1;
        return b.value.compareTo(a.value);
      });

    final data = [
      for (final entry in sorted)
        _CategoryExpenseData(
          category: entry.key == uncategorizedCategory.uuid
              ? uncategorizedCategory
              : categoryMap[entry.key]!,
          amount: entry.value,
          percentage: entry.value / total * 100,
          color: entry.key == uncategorizedCategory.uuid
              ? Colors.transparent
              : categoryMap[entry.key]!.color,
        ),
    ];

    if (data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(height: 280, child: _RingChartWidget(data: data)),
    );
  }
}

class _RingChartWidget extends StatelessWidget {
  const _RingChartWidget({required this.data});

  final List<_CategoryExpenseData> data;

  List<_RingSegmentData> _buildSegments(List<_CategoryExpenseData> items) {
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
            midAngle: startAngle + sweep / 2,
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
        final iconRadius = (outerRadius + innerRadius) / 2;
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
            for (final seg in segments)
              if (seg.item.percentage >= 5)
                Positioned(
                  left: center.dx + iconRadius * math.cos(seg.midAngle) - 20,
                  top: center.dy + iconRadius * math.sin(seg.midAngle) - 20,
                  width: 40,
                  height: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        seg.item.category.icon,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${seg.item.percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
