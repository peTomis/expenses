import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryProvider =
    NotifierProvider<CategoryNotifier, List<FinancialCategory>>(
      CategoryNotifier.new,
    );

const defaultCategories = [
  FinancialCategory(
    uuid: 'c4f7a05b-b3f0-4613-9e8a-4be7d35d7e0c',
    name: 'Bar/Restaurant',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFFF7043),
  ),
  FinancialCategory(
    uuid: 'c8500242-e52b-4b39-948d-1559b671d157',
    name: 'Bill',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF78909C),
  ),
  FinancialCategory(
    uuid: '9c8f7164-6af0-4310-b7e1-c26676eadf20',
    name: 'Bureaucracy',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF8D6E63),
  ),
  FinancialCategory(
    uuid: '28ab1c89-088a-4214-a831-c50fb915a5f0',
    name: 'Grocery',
    icon: Icons.local_grocery_store_outlined,
    color: Color(0xFF66BB6A),
  ),
  FinancialCategory(
    uuid: 'fd682f89-89d6-47d5-a6e4-e628df0f5c0a',
    name: 'House',
    icon: Icons.home_outlined,
    color: Color(0xFFFFCA28),
  ),
  FinancialCategory(
    uuid: '2574f7a3-68f9-4567-9340-6e0a6d6bf6c2',
    name: 'Loan',
    icon: Icons.request_quote_outlined,
    color: Color(0xFFEF5350),
  ),
  FinancialCategory(
    uuid: 'cddbf4f2-43c0-4785-a57f-20f895a284f1',
    name: 'Operation',
    icon: Icons.sync_alt_outlined,
    color: Color(0xFF5C6BC0),
  ),
  FinancialCategory(
    uuid: 'f1e9381f-94e4-49fa-94c9-5d28a5c09f6b',
    name: 'Salary',
    icon: Icons.work_outline,
    color: Color(0xFF26A69A),
  ),
  FinancialCategory(
    uuid: 'a6ac97a9-808e-46ba-a220-d42bb2f0a8c2',
    name: 'Saving',
    icon: Icons.savings_outlined,
    color: Color(0xFF9CCC65),
  ),
  FinancialCategory(
    uuid: '5f731849-955c-4eb1-a0dd-9dcd67f3196a',
    name: 'Software',
    icon: Icons.apps_outlined,
    color: Color(0xFFAB47BC),
  ),
  FinancialCategory(
    uuid: 'bb68251e-5f8d-4e06-9554-431c83d4f8f7',
    name: 'Tech',
    icon: Icons.devices_outlined,
    color: Color(0xFF29B6F6),
  ),
  FinancialCategory(
    uuid: '808ee51b-e0dc-4a7f-8ff7-c5a236f23fac',
    name: 'Travel & Fun',
    icon: Icons.flight_takeoff_outlined,
    color: Color(0xFFFFA726),
  ),
];

const uncategorizedCategory = FinancialCategory(
  uuid: '',
  name: 'Uncategorized',
  icon: Icons.label_off_outlined,
  color: Colors.transparent,
);

const List<IconData> categoryIcons = [
  Icons.restaurant_outlined,
  Icons.receipt_long_outlined,
  Icons.account_balance_outlined,
  Icons.checkroom_outlined,
  Icons.collections_bookmark_outlined,
  Icons.pets_outlined,
  Icons.local_gas_station_outlined,
  Icons.card_giftcard_outlined,
  Icons.local_grocery_store_outlined,
  Icons.home_outlined,
  Icons.request_quote_outlined,
  Icons.sync_alt_outlined,
  Icons.work_outline,
  Icons.savings_outlined,
  Icons.apps_outlined,
  Icons.devices_outlined,
  Icons.flight_takeoff_outlined,
  Icons.live_tv_outlined,
  Icons.sports_esports_outlined,
];

class FinancialCategory {
  const FinancialCategory({
    required this.uuid,
    required this.name,
    required this.icon,
    this.color = const Color(0xFF607D8B),
  });

  final String uuid;
  final String name;
  final IconData icon;
  final Color color;

  String get label => name;

  FinancialCategory copyWith({
    String? uuid,
    String? name,
    IconData? icon,
    Color? color,
  }) {
    return FinancialCategory(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'color': color.toARGB32(),
      'icon': {
        'codePoint': icon.codePoint,
        'fontFamily': icon.fontFamily,
        'fontPackage': icon.fontPackage,
        'matchTextDirection': icon.matchTextDirection,
      },
    };
  }

  static FinancialCategory? fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['name'] as String?;
    final iconJson = json['icon'] as Map<String, dynamic>?;
    final codePoint = iconJson?['codePoint'] as int?;

    if (uuid == null || name == null || codePoint == null) {
      return null;
    }

    final icon = categoryIcons.firstWhere(
      (icon) => icon.codePoint == codePoint,
      orElse: () => Icons.label_outline,
    );

    final colorValue = json['color'] as int?;
    final color = colorValue != null
        ? Color(colorValue)
        : const Color(0xFF607D8B);

    return FinancialCategory(uuid: uuid, name: name, icon: icon, color: color);
  }
}

class CategoryNotifier extends Notifier<List<FinancialCategory>> {
  final _random = Random.secure();

  @override
  List<FinancialCategory> build() {
    return _sortCategories(defaultCategories);
  }

  void addCategory({required String name, IconData? icon, Color? color}) {
    final trimmedName = name.trim();
    final category = FinancialCategory(
      uuid: _uuidV4(),
      name: trimmedName,
      icon: icon ?? iconForCategoryName(trimmedName),
      color: color ?? const Color(0xFF607D8B),
    );

    state = _sortCategories([...state, category]);
  }

  IconData iconForCategoryName(String name) {
    return Icons.label_outline;
  }

  void updateCategory(FinancialCategory category) {
    state = _sortCategories([
      for (final existingCategory in state)
        existingCategory.uuid == category.uuid ? category : existingCategory,
    ]);
  }

  void removeCategory(String uuid) {
    if (state.length <= 1) {
      return;
    }

    state = _sortCategories([
      for (final category in state)
        if (category.uuid != uuid) category,
    ]);
  }

  void replaceCategories(List<FinancialCategory> categories) {
    if (categories.isEmpty) {
      return;
    }

    state = _sortCategories(categories);
  }

  List<FinancialCategory> _sortCategories(List<FinancialCategory> categories) {
    return [...categories]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }
}
