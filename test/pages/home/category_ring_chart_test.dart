import 'package:flutter_test/flutter_test.dart';

import 'package:expenses/pages/home/widgets/category_ring_chart.dart';
import 'package:expenses/providers/category_provider.dart';
import 'package:expenses/providers/financial_data_provider.dart';

void main() {
  test('computeCategoryExpenseTotals aggregates expenses per category', () {
    final groceryUuid = defaultCategories[3].uuid;
    final billUuid = defaultCategories[1].uuid;
    final monthlyData = [
      MonthlyFinancialData(
        month: 1,
        year: 2026,
        expenses: 90,
        income: 0,
        data: [
          FinancialDataEntry(
            timestamp: DateTime(2026, 1, 1),
            amount: -60,
            account: 1,
            merchant: 'Market',
            category: groceryUuid,
          ),
          FinancialDataEntry(
            timestamp: DateTime(2026, 1, 2),
            amount: -30,
            account: 1,
            merchant: 'Electric',
            category: billUuid,
          ),
          FinancialDataEntry(
            timestamp: DateTime(2026, 1, 3),
            amount: 500,
            account: 1,
            merchant: 'Payroll',
            category: null,
          ),
        ],
      ),
    ];

    final totals = computeCategoryExpenseTotals(monthlyData, defaultCategories);

    expect(totals, hasLength(2));
    expect(totals.first.category.uuid, groceryUuid);
    expect(totals.first.amount, 60);
    expect(totals.first.percentage, closeTo(66.7, 0.1));
    expect(totals.first.count, 1);
    expect(totals.last.category.uuid, billUuid);
    expect(totals.last.amount, 30);
  });

  test('computeCategoryExpenseTotals returns nothing when there are no expenses', () {
    final totals = computeCategoryExpenseTotals(const [], defaultCategories);
    expect(totals, isEmpty);
  });
}
