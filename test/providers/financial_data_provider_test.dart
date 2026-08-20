import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expenses/providers/category_provider.dart';
import 'package:expenses/providers/financial_data_provider.dart';
import 'package:expenses/providers/shared_preferences_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
  });

  test('build falls back to the mocked demo data', () {
    final state = container.read(financialDataProvider);
    expect(state.monthlyData, mockedMonthlyFinancialData);
    expect(state.accountData.currency, CurrencyData.euro);
  });

  test('addEntry creates a new month bucket and recomputes totals', () {
    final notifier = container.read(financialDataProvider.notifier);
    notifier.addEntry(
      FinancialDataEntry(
        timestamp: DateTime(2030, 1, 5),
        amount: -50,
        account: 1,
        merchant: 'Test Merchant',
        category: defaultCategories.first.uuid,
      ),
    );

    final state = container.read(financialDataProvider);
    final month = state.monthlyData.firstWhere(
      (data) => data.month == 1 && data.year == 2030,
    );
    expect(month.expenses, 50);
    expect(month.income, 0);
    expect(month.data.single.merchant, 'Test Merchant');
  });

  test('addEntry merges into an existing month bucket', () {
    final notifier = container.read(financialDataProvider.notifier);
    final before = container
        .read(financialDataProvider)
        .monthlyData
        .firstWhere((data) => data.month == 3 && data.year == 2026);

    notifier.addEntry(
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 15),
        amount: -30,
        account: 1,
        merchant: 'Extra Purchase',
        category: null,
      ),
    );

    final after = container
        .read(financialDataProvider)
        .monthlyData
        .firstWhere((data) => data.month == 3 && data.year == 2026);
    expect(after.data.length, before.data.length + 1);
    expect(after.expenses, before.expenses + 30);
  });

  test('replaceCategory reassigns matching entries only', () {
    final notifier = container.read(financialDataProvider.notifier);
    const fromUuid = 'c4f7a05b-b3f0-4613-9e8a-4be7d35d7e0c';
    const toUuid = 'replacement-uuid';

    notifier.replaceCategory(fromUuid, toUuid);

    final state = container.read(financialDataProvider);
    final categoriesUsed = state.monthlyData
        .expand((month) => month.data)
        .map((entry) => entry.category)
        .toSet();
    expect(categoriesUsed.contains(fromUuid), isFalse);
    expect(categoriesUsed.contains(toUuid), isTrue);
  });

  test('FinancialDataEntry.copyWith preserves the new fields', () {
    final entry = FinancialDataEntry(
      timestamp: DateTime(2026, 1, 1),
      amount: -20,
      account: 1,
      merchant: 'Coffee',
      category: defaultCategories.first.uuid,
      paymentMethod: PaymentMethodData.cash.key,
      items: const [ReceiptItem(qty: 2, name: 'Espresso', price: 1.5)],
      scanned: true,
    );

    final recategorized = entry.copyWith(category: defaultCategories.last.uuid);

    expect(recategorized.id, entry.id);
    expect(recategorized.category, defaultCategories.last.uuid);
    expect(recategorized.paymentMethod, PaymentMethodData.cash.key);
    expect(recategorized.items, entry.items);
    expect(recategorized.scanned, isTrue);
  });

  test('FinancialDataEntry JSON round-trip preserves the new fields', () {
    final entry = FinancialDataEntry(
      timestamp: DateTime(2026, 1, 1),
      amount: -74.32,
      account: 1,
      merchant: 'Conad',
      category: defaultCategories.first.uuid,
      paymentMethod: PaymentMethodData.visa.key,
      items: const [
        ReceiptItem(qty: 1, name: 'Pasta', brand: 'Rummo', size: '500g', price: 1.49),
      ],
      scanned: true,
    );

    final restored = FinancialDataEntry.fromJson(entry.toJson());

    expect(restored, isNotNull);
    expect(restored!.id, entry.id);
    expect(restored.paymentMethod, PaymentMethodData.visa.key);
    expect(restored.scanned, isTrue);
    expect(restored.items, hasLength(1));
    expect(restored.items!.single.name, 'Pasta');
    expect(restored.items!.single.brandSize, 'Rummo 500g');
  });

  test('replaceCategory keeps payment method, items and scanned flag', () {
    final notifier = container.read(financialDataProvider.notifier);
    notifier.addEntry(
      FinancialDataEntry(
        timestamp: DateTime(2030, 4, 1),
        amount: -10,
        account: 1,
        merchant: 'Kept fields',
        category: defaultCategories.first.uuid,
        paymentMethod: PaymentMethodData.satispay.key,
        scanned: true,
      ),
    );

    notifier.replaceCategory(defaultCategories.first.uuid, defaultCategories.last.uuid);

    final entry = container
        .read(financialDataProvider)
        .monthlyData
        .expand((m) => m.data)
        .firstWhere((e) => e.merchant == 'Kept fields');

    expect(entry.category, defaultCategories.last.uuid);
    expect(entry.paymentMethod, PaymentMethodData.satispay.key);
    expect(entry.scanned, isTrue);
  });

  test('state persists to SharedPreferences and survives a rebuild', () async {
    container.read(financialDataProvider.notifier).addEntry(
      FinancialDataEntry(
        timestamp: DateTime(2030, 6, 1),
        amount: 1000,
        account: 1,
        merchant: 'Persisted Income',
        category: null,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final preferences = container.read(sharedPreferencesProvider);
    final restoredContainer = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restoredContainer.dispose);

    final restoredState = restoredContainer.read(financialDataProvider);
    final merchants = restoredState.monthlyData
        .expand((month) => month.data)
        .map((entry) => entry.merchant);
    expect(merchants, contains('Persisted Income'));
  });
}
