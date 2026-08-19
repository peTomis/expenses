import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expenses/models/backup_payload.dart';
import 'package:expenses/providers/category_provider.dart';
import 'package:expenses/providers/financial_data_provider.dart';
import 'package:expenses/providers/last_mutation_provider.dart';
import 'package:expenses/providers/shared_preferences_provider.dart';

/// `BackupPayload` takes a `Ref`, not a `ProviderContainer` — this exposes
/// one bound to whichever container reads it.
final _refProvider = Provider<Ref>((ref) => ref);

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

  test('fromProviders bundles financial data, categories and updatedAt', () {
    container.read(financialDataProvider.notifier).addEntry(
      FinancialDataEntry(
        timestamp: DateTime(2030, 1, 5),
        amount: -50,
        account: 1,
        merchant: 'Test Merchant',
        category: null,
      ),
    );

    final payload = BackupPayload.fromProviders(container.read(_refProvider));

    expect(payload.financialData, container.read(financialDataProvider));
    expect(payload.categories, container.read(categoryProvider));
    expect(payload.updatedAt, container.read(lastMutationProvider));
  });

  test('toJson/fromJson round-trips financial data and categories', () {
    container.read(financialDataProvider.notifier).addEntry(
      FinancialDataEntry(
        timestamp: DateTime(2030, 2, 10),
        amount: -75,
        account: 1,
        merchant: 'Round Trip Merchant',
        category: defaultCategories.first.uuid,
      ),
    );

    final payload = BackupPayload.fromProviders(container.read(_refProvider));
    final jsonString = jsonEncode(payload.toJson());
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final restored = BackupPayload.fromJson(decoded);

    expect(restored, isNotNull);
    expect(restored!.updatedAt, payload.updatedAt);
    expect(restored.categories.length, payload.categories.length);
    final merchants = restored.financialData.monthlyData
        .expand((month) => month.data)
        .map((entry) => entry.merchant);
    expect(merchants, contains('Round Trip Merchant'));
  });

  test(
    'applyToProviders replaces a second device\'s state and sets lastMutation '
    'to the payload\'s updatedAt (not now)',
    () async {
      // "Device A": add data, export a payload.
      container.read(financialDataProvider.notifier).addEntry(
        FinancialDataEntry(
          timestamp: DateTime(2030, 3, 1),
          amount: 500,
          account: 1,
          merchant: 'Device A Income',
          category: null,
        ),
      );
      container.read(categoryProvider.notifier).addCategory(name: 'Device A Category');
      await Future<void>.delayed(Duration.zero);
      final payload = BackupPayload.fromProviders(container.read(_refProvider));

      // "Device B": fresh local state, applies the payload from Device A.
      SharedPreferences.setMockInitialValues({});
      final deviceBPreferences = await SharedPreferences.getInstance();
      final deviceB = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(deviceBPreferences),
        ],
      );
      addTearDown(deviceB.dispose);

      payload.applyToProviders(deviceB.read(_refProvider));

      final merchants = deviceB
          .read(financialDataProvider)
          .monthlyData
          .expand((month) => month.data)
          .map((entry) => entry.merchant);
      expect(merchants, contains('Device A Income'));
      expect(
        deviceB.read(categoryProvider).map((c) => c.name),
        contains('Device A Category'),
      );
      expect(deviceB.read(lastMutationProvider), payload.updatedAt);
    },
  );
}
