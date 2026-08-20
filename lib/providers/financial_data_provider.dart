import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'category_provider.dart';
import 'last_mutation_provider.dart';
import 'shared_preferences_provider.dart';

final financialDataProvider =
    NotifierProvider<FinancialDataNotifier, FinancialDataState>(
      FinancialDataNotifier.new,
    );

final mockedMonthlyFinancialData = [
  MonthlyFinancialData(
    month: 3,
    year: 2026,
    expenses: 2150,
    income: 3200,
    data: [
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 1),
        amount: 3200,
        account: 1,
        merchant: 'Acme Payroll',
        category: defaultCategories[7].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 2),
        amount: -1200,
        account: 1,
        merchant: 'Rent',
        category: defaultCategories[4].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 4),
        amount: -185,
        account: 1,
        merchant: 'Market Lane',
        category: defaultCategories[3].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 8),
        amount: -140,
        account: 1,
        merchant: 'Electric Company',
        category: defaultCategories[1].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 12),
        amount: -75,
        account: 1,
        merchant: 'Metro Pass',
        category: defaultCategories[11].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 18),
        amount: -95,
        account: 1,
        merchant: 'Caffe Roma',
        category: defaultCategories[0].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 22),
        amount: -210,
        account: 1,
        merchant: 'Insurance',
        category: null,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 26),
        amount: -45,
        account: 1,
        merchant: 'Streaming',
        category: defaultCategories[9].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 29),
        amount: -200,
        account: 1,
        merchant: 'Trainline',
        category: defaultCategories[11].uuid,
      ),
    ],
  ),
  MonthlyFinancialData(
    month: 4,
    year: 2026,
    expenses: 1995,
    income: 3420,
    data: [
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 1),
        amount: 3200,
        account: 1,
        merchant: 'Acme Payroll',
        category: defaultCategories[7].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 2),
        amount: -1200,
        account: 1,
        merchant: 'Rent',
        category: defaultCategories[4].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 5),
        amount: -205,
        account: 1,
        merchant: 'Market Lane',
        category: defaultCategories[3].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 9),
        amount: -130,
        account: 1,
        merchant: 'Electric Company',
        category: defaultCategories[1].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 13),
        amount: -70,
        account: 1,
        merchant: 'Metro Pass',
        category: defaultCategories[11].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 16),
        amount: -18,
        account: 1,
        merchant: 'Coffee Bar',
        category: defaultCategories[0].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 19),
        amount: -125,
        account: 1,
        merchant: 'Osteria Verde',
        category: defaultCategories[0].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 21),
        amount: 220,
        account: 1,
        merchant: 'Freelance Client',
        category: defaultCategories[7].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 24),
        amount: -210,
        account: 1,
        merchant: 'Insurance',
        category: defaultCategories[1].uuid,
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 27),
        amount: -37,
        account: 1,
        merchant: 'Books',
        category: defaultCategories[11].uuid,
      ),
    ],
  ),
];

class FinancialDataState {
  const FinancialDataState({
    required this.monthlyData,
    required this.accountData,
  });

  final List<MonthlyFinancialData> monthlyData;
  final FinancialAccountData accountData;

  double get totalIncome {
    return monthlyData.fold<double>(
      0,
      (total, monthData) => total + monthData.income,
    );
  }

  double get totalExpenses {
    return monthlyData.fold<double>(
      0,
      (total, monthData) => total + monthData.expenses,
    );
  }

  double get totalBalance {
    return totalIncome - totalExpenses;
  }

  FinancialDataState copyWith({
    List<MonthlyFinancialData>? monthlyData,
    FinancialAccountData? accountData,
  }) {
    return FinancialDataState(
      monthlyData: monthlyData ?? this.monthlyData,
      accountData: accountData ?? this.accountData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyData': monthlyData
          .map((monthData) => monthData.toJson())
          .toList(),
      'accountData': accountData.toJson(),
    };
  }

  static FinancialDataState? fromJson(Map<String, dynamic> json) {
    final monthlyDataJson = json['monthlyData'];
    final accountDataJson = json['accountData'];
    if (monthlyDataJson is! List || accountDataJson is! Map) {
      return null;
    }

    final accountData = FinancialAccountData.fromJson(
      Map<String, dynamic>.from(accountDataJson),
    );
    if (accountData == null) {
      return null;
    }

    final monthlyData = <MonthlyFinancialData>[];
    for (final item in monthlyDataJson) {
      if (item is! Map) {
        continue;
      }
      final monthData = MonthlyFinancialData.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (monthData != null) {
        monthlyData.add(monthData);
      }
    }

    return FinancialDataState(monthlyData: monthlyData, accountData: accountData);
  }
}

class MonthlyFinancialData {
  const MonthlyFinancialData({
    required this.month,
    required this.year,
    required this.expenses,
    required this.income,
    this.data = const [],
  });

  final int month;
  final int year;
  final double expenses;
  final double income;
  final List<FinancialDataEntry> data;

  MonthlyFinancialData copyWith({
    int? month,
    int? year,
    double? expenses,
    double? income,
    List<FinancialDataEntry>? data,
  }) {
    return MonthlyFinancialData(
      month: month ?? this.month,
      year: year ?? this.year,
      expenses: expenses ?? this.expenses,
      income: income ?? this.income,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'expenses': expenses,
      'income': income,
      'data': data.map((entry) => entry.toJson()).toList(),
    };
  }

  static MonthlyFinancialData? fromJson(Map<String, dynamic> json) {
    final month = json['month'] as int?;
    final year = json['year'] as int?;
    final expenses = (json['expenses'] as num?)?.toDouble();
    final income = (json['income'] as num?)?.toDouble();
    final dataJson = json['data'];
    if (month == null ||
        year == null ||
        expenses == null ||
        income == null ||
        dataJson is! List) {
      return null;
    }

    final data = <FinancialDataEntry>[];
    for (final item in dataJson) {
      if (item is! Map) {
        continue;
      }
      final entry = FinancialDataEntry.fromJson(Map<String, dynamic>.from(item));
      if (entry != null) {
        data.add(entry);
      }
    }

    return MonthlyFinancialData(
      month: month,
      year: year,
      expenses: expenses,
      income: income,
      data: data,
    );
  }
}

class FinancialDataEntry {
  FinancialDataEntry({
    required this.timestamp,
    required this.amount,
    required this.account,
    required this.merchant,
    this.category,
    this.paymentMethod,
    this.items,
    this.scanned = false,
    String? id,
  }) : id = id ?? _generateEntryId();

  final String id;
  final DateTime timestamp;
  final double amount;
  final int account;
  final String merchant;
  final String? category;
  final String? paymentMethod;
  final List<ReceiptItem>? items;
  final bool scanned;

  FinancialDataEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? amount,
    int? account,
    String? merchant,
    String? category,
    bool clearCategory = false,
    String? paymentMethod,
    List<ReceiptItem>? items,
    bool? scanned,
  }) {
    return FinancialDataEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      account: account ?? this.account,
      merchant: merchant ?? this.merchant,
      category: clearCategory ? null : (category ?? this.category),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      scanned: scanned ?? this.scanned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'amount': amount,
      'account': account,
      'merchant': merchant,
      'category': category,
      'paymentMethod': paymentMethod,
      'items': items?.map((item) => item.toJson()).toList(),
      'scanned': scanned,
    };
  }

  static FinancialDataEntry? fromJson(Map<String, dynamic> json) {
    final timestampString = json['timestamp'] as String?;
    final timestamp = timestampString == null
        ? null
        : DateTime.tryParse(timestampString);
    final amount = (json['amount'] as num?)?.toDouble();
    final account = json['account'] as int?;
    final merchant = json['merchant'] as String?;
    if (timestamp == null || amount == null || account == null || merchant == null) {
      return null;
    }

    final itemsJson = json['items'];
    final items = itemsJson is! List
        ? null
        : [
            for (final item in itemsJson)
              if (item is Map)
                ReceiptItem.fromJson(Map<String, dynamic>.from(item)),
          ].whereType<ReceiptItem>().toList();

    return FinancialDataEntry(
      id: json['id'] as String?,
      timestamp: timestamp,
      amount: amount,
      account: account,
      merchant: merchant,
      category: json['category'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      items: items == null || items.isEmpty ? null : items,
      scanned: json['scanned'] as bool? ?? false,
    );
  }
}

final _entryIdRandom = Random.secure();

String _generateEntryId() {
  final bytes = List<int>.generate(16, (_) => _entryIdRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
}

class ReceiptItem {
  const ReceiptItem({
    required this.qty,
    required this.name,
    required this.price,
    this.brand = '',
    this.size = '',
  });

  final int qty;
  final String name;
  final String brand;
  final String size;
  final double price;

  String get brandSize => [brand, size].where((s) => s.isNotEmpty).join(' ');

  Map<String, dynamic> toJson() {
    return {
      'qty': qty,
      'name': name,
      'brand': brand,
      'size': size,
      'price': price,
    };
  }

  static ReceiptItem? fromJson(Map<String, dynamic> json) {
    final qty = json['qty'] as int?;
    final name = json['name'] as String?;
    final price = (json['price'] as num?)?.toDouble();
    if (qty == null || name == null || price == null) {
      return null;
    }

    return ReceiptItem(
      qty: qty,
      name: name,
      price: price,
      brand: json['brand'] as String? ?? '',
      size: json['size'] as String? ?? '',
    );
  }
}

class PaymentMethodData {
  const PaymentMethodData({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;

  static const amex = PaymentMethodData(
    key: 'amex',
    label: 'Amex Gold',
    icon: Icons.credit_card,
  );
  static const visa = PaymentMethodData(
    key: 'visa',
    label: 'Visa ·· 4412',
    icon: Icons.credit_card,
  );
  static const revolut = PaymentMethodData(
    key: 'revolut',
    label: 'Revolut',
    icon: Icons.account_balance_wallet_outlined,
  );
  static const satispay = PaymentMethodData(
    key: 'satispay',
    label: 'Satispay',
    icon: Icons.smartphone_outlined,
  );
  static const cash = PaymentMethodData(
    key: 'cash',
    label: 'Cash',
    icon: Icons.payments_outlined,
  );
  static const bank = PaymentMethodData(
    key: 'bank',
    label: 'Bank transfer',
    icon: Icons.account_balance_outlined,
  );

  static const values = [amex, visa, revolut, satispay, cash, bank];

  static PaymentMethodData? byKey(String? key) {
    if (key == null) {
      return null;
    }

    for (final method in values) {
      if (method.key == key) {
        return method;
      }
    }

    return null;
  }
}

class FinancialAccountData {
  const FinancialAccountData({required this.account, required this.currency});

  final List<int> account;
  final CurrencyData currency;

  FinancialAccountData copyWith({List<int>? account, CurrencyData? currency}) {
    return FinancialAccountData(
      account: account ?? this.account,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {'account': account, 'currency': currency.toJson()};
  }

  static FinancialAccountData? fromJson(Map<String, dynamic> json) {
    final accountJson = json['account'];
    final currencyJson = json['currency'];
    if (accountJson is! List || currencyJson is! Map) {
      return null;
    }

    final currency = CurrencyData.fromJson(
      Map<String, dynamic>.from(currencyJson),
    );
    if (currency == null) {
      return null;
    }

    return FinancialAccountData(
      account: accountJson.cast<int>(),
      currency: currency,
    );
  }
}

class CurrencyData {
  const CurrencyData({required this.name, required this.symbol});

  static const euro = CurrencyData(name: 'Euro', symbol: '€');
  static const dollar = CurrencyData(name: 'Dollar', symbol: r'$');
  static const supportedCurrencies = [euro, dollar];

  final String name;
  final String symbol;

  String get label {
    return '$symbol $name';
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'symbol': symbol};
  }

  static CurrencyData? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final symbol = json['symbol'] as String?;
    if (name == null || symbol == null) {
      return null;
    }

    return supportedCurrencies.firstWhere(
      (currency) => currency.name == name && currency.symbol == symbol,
      orElse: () => CurrencyData(name: name, symbol: symbol),
    );
  }
}

class FinancialDataNotifier extends Notifier<FinancialDataState> {
  static const _key = 'financialData';

  @override
  FinancialDataState build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_key);
    final storedState = stored == null ? null : _decodeState(stored);
    if (storedState != null) {
      return storedState;
    }

    return FinancialDataState(
      monthlyData: mockedMonthlyFinancialData,
      accountData: const FinancialAccountData(
        account: [1],
        currency: CurrencyData.euro,
      ),
    );
  }

  void setCurrency(CurrencyData currency) {
    _setState(
      state.copyWith(
        accountData: state.accountData.copyWith(currency: currency),
      ),
    );
  }

  void addEntry(FinancialDataEntry entry) {
    final entryMonth = entry.timestamp.month;
    final entryYear = entry.timestamp.year;
    final monthlyData = [...state.monthlyData];
    final monthIndex = monthlyData.indexWhere(
      (monthData) =>
          monthData.month == entryMonth && monthData.year == entryYear,
    );

    if (monthIndex == -1) {
      monthlyData.add(_monthlyDataFromEntries(entryMonth, entryYear, [entry]));
    } else {
      final existingMonth = monthlyData[monthIndex];
      monthlyData[monthIndex] = _monthlyDataFromEntries(entryMonth, entryYear, [
        ...existingMonth.data,
        entry,
      ]);
    }

    monthlyData.sort((a, b) {
      final yearComparison = a.year.compareTo(b.year);
      if (yearComparison != 0) {
        return yearComparison;
      }

      return a.month.compareTo(b.month);
    });

    _setState(state.copyWith(monthlyData: monthlyData));
  }

  int entryCountForCategory(String categoryUuid) {
    return state.monthlyData.fold<int>(
      0,
      (total, monthData) =>
          total +
          monthData.data
              .where((entry) => entry.category == categoryUuid)
              .length,
    );
  }

  void replaceCategory(String categoryUuid, String? replacementCategoryUuid) {
    final monthlyData = [
      for (final monthData in state.monthlyData)
        _monthlyDataFromEntries(monthData.month, monthData.year, [
          for (final entry in monthData.data)
            if (entry.category == categoryUuid)
              entry.copyWith(
                category: replacementCategoryUuid,
                clearCategory: replacementCategoryUuid == null,
              )
            else
              entry,
        ]),
    ];

    _setState(state.copyWith(monthlyData: monthlyData));
  }

  void replaceAll(FinancialDataState newState) {
    _setState(newState);
  }

  void _setState(FinancialDataState newState) {
    state = newState;
    unawaited(_persist(newState));
    ref.read(lastMutationProvider.notifier).touch();
  }

  Future<void> _persist(FinancialDataState newState) async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_key, jsonEncode(newState.toJson()));
  }

  FinancialDataState? _decodeState(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return null;
      }
      return FinancialDataState.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  MonthlyFinancialData _monthlyDataFromEntries(
    int month,
    int year,
    List<FinancialDataEntry> entries,
  ) {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return MonthlyFinancialData(
      month: month,
      year: year,
      income: sortedEntries
          .where((entry) => entry.amount > 0)
          .fold<double>(0, (total, entry) => total + entry.amount),
      expenses: sortedEntries
          .where((entry) => entry.amount < 0)
          .fold<double>(0, (total, entry) => total + entry.amount.abs()),
      data: sortedEntries,
    );
  }
}
