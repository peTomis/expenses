import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 2),
        amount: -1200,
        account: 1,
        merchant: 'Rent',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 4),
        amount: -185,
        account: 1,
        merchant: 'Market Lane',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 8),
        amount: -140,
        account: 1,
        merchant: 'Electric Company',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 12),
        amount: -75,
        account: 1,
        merchant: 'Metro Pass',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 18),
        amount: -95,
        account: 1,
        merchant: 'Caffe Roma',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 22),
        amount: -210,
        account: 1,
        merchant: 'Insurance',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 26),
        amount: -45,
        account: 1,
        merchant: 'Streaming',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 3, 29),
        amount: -200,
        account: 1,
        merchant: 'Trainline',
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
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 2),
        amount: -1200,
        account: 1,
        merchant: 'Rent',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 5),
        amount: -205,
        account: 1,
        merchant: 'Market Lane',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 9),
        amount: -130,
        account: 1,
        merchant: 'Electric Company',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 13),
        amount: -70,
        account: 1,
        merchant: 'Metro Pass',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 16),
        amount: -18,
        account: 1,
        merchant: 'Coffee Bar',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 19),
        amount: -125,
        account: 1,
        merchant: 'Osteria Verde',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 21),
        amount: 220,
        account: 1,
        merchant: 'Freelance Client',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 24),
        amount: -210,
        account: 1,
        merchant: 'Insurance',
      ),
      FinancialDataEntry(
        timestamp: DateTime(2026, 4, 27),
        amount: -37,
        account: 1,
        merchant: 'Books',
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
}

class FinancialDataEntry {
  const FinancialDataEntry({
    required this.timestamp,
    required this.amount,
    required this.account,
    required this.merchant,
  });

  final DateTime timestamp;
  final double amount;
  final int account;
  final String merchant;
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
}

class FinancialDataNotifier extends Notifier<FinancialDataState> {
  @override
  FinancialDataState build() {
    return FinancialDataState(
      monthlyData: mockedMonthlyFinancialData,
      accountData: const FinancialAccountData(
        account: [1],
        currency: CurrencyData.euro,
      ),
    );
  }

  void setCurrency(CurrencyData currency) {
    state = state.copyWith(
      accountData: state.accountData.copyWith(currency: currency),
    );
  }
}
